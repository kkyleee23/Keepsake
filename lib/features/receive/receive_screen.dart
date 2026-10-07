import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../../data/providers.dart';
import '../../data/remote/auth_service.dart';
import '../../data/remote/keepsake_backend.dart';
import '../keepsakes/application/keepsakes_controller.dart';
import '../reader/keepsake_content_view.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';

enum _Phase { loading, cover, sealed, pin, opening, content, error }

/// The recipient experience. Opens a keepsake from a share token with no
/// account. Scheduled access, expiry, and PIN are all enforced on the server;
/// this screen just reflects what the server allows.
class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  _Phase _phase = _Phase.loading;
  CoverResult? _cover;
  Keepsake? _content;
  String _errorStatus = 'error';
  String? _pinError;

  KeepsakeBackend get _backend => ref.read(keepsakeBackendProvider);

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    if (!_backend.isAvailable) {
      setState(() {
        _phase = _Phase.error;
        _errorStatus = 'error';
      });
      return;
    }
    final cover = await _backend.fetchCover(widget.token);
    if (!mounted) return;
    setState(() {
      _cover = cover;
      switch (cover.status) {
        case 'available':
          _phase = _Phase.cover;
        case 'sealed':
          _phase = _Phase.sealed;
        default:
          _phase = _Phase.error;
          _errorStatus = cover.status;
      }
    });
  }

  Future<void> _open({String? pin}) async {
    setState(() {
      _phase = _Phase.opening;
      _pinError = null;
    });
    final result = await _backend.open(widget.token, pin: pin);
    if (!mounted) return;
    switch (result.status) {
      case 'ok':
        setState(() {
          _content = result.keepsake;
          _phase = _Phase.content;
        });
        _saveToLibrary(result.keepsake);
      case 'pin_required':
        setState(() => _phase = _Phase.pin);
      case 'wrong_pin':
        setState(() {
          _phase = _Phase.pin;
          _pinError = 'That PIN doesn’t match. Try again.';
        });
      case 'sealed':
        setState(() {
          _phase = _Phase.sealed;
          _cover = CoverResult(status: 'sealed', opensAt: result.opensAt);
        });
      default:
        setState(() {
          _phase = _Phase.error;
          _errorStatus = result.status;
        });
    }
  }

  /// If a signed-in creator opens someone else's keepsake, keep a copy in their
  /// library under "Received".
  void _saveToLibrary(Keepsake? k) {
    if (k == null) return;
    final auth = ref.read(authServiceProvider);
    if (!auth.isSignedIn) return;
    if (k.creatorId != null && k.creatorId == auth.currentUser?.id) return;
    ref
        .read(keepsakesControllerProvider.notifier)
        .saveReceived(k.copyWith(shareToken: widget.token));
  }

  void _onOpenPressed() {
    if (_cover?.requiresPin ?? false) {
      setState(() => _phase = _Phase.pin);
    } else {
      _open();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.loading:
      case _Phase.opening:
        return const Center(child: CircularProgressIndicator());
      case _Phase.content:
        return KeepsakeContentView(keepsake: _content!);
      case _Phase.cover:
        return _RecipientCover(cover: _cover!, onOpen: _onOpenPressed);
      case _Phase.sealed:
        return _SealedView(opensAt: _cover?.opensAt, cover: _cover);
      case _Phase.pin:
        return _PinGate(
          error: _pinError,
          onSubmit: (pin) => _open(pin: pin),
        );
      case _Phase.error:
        return _ErrorView(status: _errorStatus);
    }
  }
}

class _RecipientCover extends StatelessWidget {
  const _RecipientCover({required this.cover, required this.onOpen});

  final CoverResult cover;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          if ((cover.occasion ?? '').isNotEmpty)
            Text(cover.occasion!.toUpperCase(),
                style: AppTypography.caption, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(
            (cover.recipientName ?? '').isEmpty
                ? 'Something for you'
                : 'For ${cover.recipientName}',
            style: AppTypography.display,
            textAlign: TextAlign.center,
          ),
          if ((cover.coverNote ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(cover.coverNote!,
                style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
                textAlign: TextAlign.center),
          ],
          const Spacer(),
          if ((cover.senderName ?? '').isNotEmpty) ...[
            Text('Made for you by ${cover.senderName}',
                style: AppTypography.caption, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(label: 'Open', onPressed: onOpen, expand: false),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Calm sealed state with a readable countdown. No blinking indicators.
class _SealedView extends StatefulWidget {
  const _SealedView({required this.opensAt, required this.cover});

  final DateTime? opensAt;
  final CoverResult? cover;

  @override
  State<_SealedView> createState() => _SealedViewState();
}

class _SealedViewState extends State<_SealedView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.opensAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _remaining(DateTime opensAt) {
    final diff = opensAt.difference(DateTime.now());
    if (diff.isNegative) return 'Opening now…';
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (d > 0) return 'Opens in $d ${d == 1 ? 'day' : 'days'}, $h hr';
    if (h > 0) return 'Opens in $h hr $m min';
    if (m > 0) return 'Opens in $m min $s sec';
    return 'Opens in $s sec';
  }

  @override
  Widget build(BuildContext context) {
    final opensAt = widget.opensAt;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text('SEALED', style: AppTypography.caption, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(
            (widget.cover?.recipientName ?? '').isEmpty
                ? 'This keepsake is waiting for you.'
                : 'This keepsake is waiting for ${widget.cover!.recipientName}.',
            style: AppTypography.displaySmall,
            textAlign: TextAlign.center,
          ),
          if (opensAt != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Opens', style: AppTypography.caption),
            const SizedBox(height: AppSpacing.xs),
            Text(DateFormat.yMMMMd().format(opensAt),
                style: AppTypography.heading, textAlign: TextAlign.center),
            Text(DateFormat.jm().format(opensAt),
                style: AppTypography.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            Text(_remaining(opensAt),
                style: AppTypography.body, textAlign: TextAlign.center),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _PinGate extends StatefulWidget {
  const _PinGate({required this.onSubmit, this.error});

  final ValueChanged<String> onSubmit;
  final String? error;

  @override
  State<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<_PinGate> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enter the PIN', style: AppTypography.displaySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('This one was made just for you.',
              style: AppTypography.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '••••',
              counterText: '',
              errorText: widget.error,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Open',
            onPressed: _controller.text.trim().length >= 4
                ? () => widget.onSubmit(_controller.text.trim())
                : null,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (title, message, pose) = switch (status) {
      'expired' => (
          'This keepsake has expired',
          'The link is no longer active.',
          MascotPose.sad,
        ),
      'not_found' => (
          'Keepsake not found',
          'This link may be wrong or removed.',
          MascotPose.sad,
        ),
      _ => (
          'Something went wrong',
          'Please check the link and try again.',
          MascotPose.offline,
        ),
    };
    return EmptyState(
      illustration: Mascot(size: 140, pose: pose),
      title: title,
      message: message,
      actionLabel: 'Go home',
      onAction: () => context.go('/home'),
    );
  }
}
