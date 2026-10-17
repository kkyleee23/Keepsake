import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../../data/providers.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/fill_scroll.dart';
import '../../shared/widgets/motion.dart';
import '../keepsakes/application/keepsakes_controller.dart';
import 'replies_section.dart';
import 'new_replies.dart';

/// Confirmation after publishing: the link and QR to give to the recipient.
class PublishedScreen extends ConsumerStatefulWidget {
  const PublishedScreen({
    super.key,
    required this.keepsakeId,
    this.justPublished = false,
  });

  final String keepsakeId;

  /// True right after publishing; otherwise this is the keepsake's detail page.
  final bool justPublished;

  @override
  ConsumerState<PublishedScreen> createState() => _PublishedScreenState();
}

class _PublishedScreenState extends ConsumerState<PublishedScreen>
    with MarksRepliesSeen {
  @override
  String get seenKeepsakeId => widget.keepsakeId;

  Keepsake? _keepsake;
  bool _loading = true;
  bool _stopping = false;

  /// Set once the link is turned off; the screen then says so.
  Keepsake? _stoppedDraft;

  Future<void> _stopSharing(Keepsake k) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop sharing this link?'),
        content: Text(
          'The link and QR code stop working right away, and the copy on '
          'our server is deleted. ${k.recipientName.isEmpty ? 'Anyone' : k.recipientName} '
          'will see that it can’t be found.\n\n'
          'Your keepsake stays on this phone as a draft. You can share it '
          'again later with a new link. Replies you already got stay here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Sharing'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop Sharing'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _stopping = true);
    try {
      final draft = await ref
          .read(keepsakesControllerProvider.notifier)
          .stopSharing(k);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _stoppedDraft = draft);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError
                ? e.message
                : 'Couldn’t reach the server, so the link is still on. '
                      'Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final k = await ref
        .read(keepsakeRepositoryProvider)
        .getById(widget.keepsakeId);
    if (!mounted) return;
    setState(() {
      _keepsake = k;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final k = _keepsake;
    final token = k?.shareToken;
    if (k == null || token == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Not published',
          message: 'This keepsake doesn’t have a link yet.',
          actionLabel: 'Go Home',
          onAction: () => context.go('/home'),
        ),
      );
    }

    final url = AppConfig.shareUrl(token);

    return Scaffold(
      appBar: AppBar(
        leading: widget.justPublished
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () => context.go('/keepsakes'),
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: Motion.of(context, Motion.long),
        switchInCurve: Motion.settle,
        switchOutCurve: Curves.easeIn,
        // The link view folds down and away; the "it's off" note rises in.
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(a),
            child: child,
          ),
        ),
        child: _stoppedDraft != null
            ? _StoppedView(
                key: const ValueKey('stopped'),
                draft: _stoppedDraft!,
              )
            : SafeArea(
                key: const ValueKey('live'),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    AppSpacing.xxl,
                  ),
                  children: [
                    if (widget.justPublished) ...[
                      const Center(
                        child: Mascot(
                          size: 136,
                          pose: MascotPose.celebrating,
                          animate: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      widget.justPublished
                          ? 'Ready to give'
                          : (k.recipientName.isEmpty
                                ? k.title
                                : 'For ${k.recipientName}'),
                      style: AppTypography.display,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      k.recipientName.isEmpty
                          ? 'Share this link, or let them scan the code.'
                          : 'Share this with ${k.recipientName}, '
                                'or let them scan the code.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.inkSoft,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.card,
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: QrImageView(
                          data: url,
                          size: 200,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.ink,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _LinkRow(url: url),
                    const SizedBox(height: AppSpacing.lg),

                    PrimaryButton(
                      label: 'Share',
                      icon: Icons.ios_share,
                      onPressed: () {
                        final subject = k.recipientName.isEmpty
                            ? 'A keepsake for you'
                            : 'A keepsake for ${k.recipientName}';
                        Share.share(url, subject: subject);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.push('/preview/${k.id}'),
                      child: const Text('See What They See'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    RepliesSection(tokens: k.allTokens),
                    const SizedBox(height: AppSpacing.xxl),
                    _LinkControls(
                      keepsake: k,
                      busy: _stopping,
                      onStop: () => _stopSharing(k),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// What protects this link, and the switch to turn it off.
class _LinkControls extends StatelessWidget {
  const _LinkControls({
    required this.keepsake,
    required this.busy,
    required this.onStop,
  });

  final Keepsake keepsake;
  final bool busy;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final expires = keepsake.privacy.expiresAt;
    final lines = [
      keepsake.privacy.hasPin
          ? 'Locked with a PIN. Five wrong tries locks it for a while.'
          : 'No PIN. Anyone with the link can open it.',
      if (expires != null)
        'Stops working on ${DateFormat.yMMMd().format(expires)}.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This link', style: AppTypography.heading),
        const SizedBox(height: AppSpacing.sm),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Text(l, style: AppTypography.body),
          ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: EdgeInsets.zero,
            ),
            onPressed: busy ? null : onStop,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link_off, size: 20),
            label: const Text('Stop Sharing'),
          ),
        ),
      ],
    );
  }
}

/// Shown once the link is off: what happened, and the way back to editing.
class _StoppedView extends StatelessWidget {
  const _StoppedView({super.key, required this.draft});

  final Keepsake draft;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FillScroll(
        child: Column(
          children: [
            const Spacer(),
            const Mascot(size: 150, pose: MascotPose.sleepy),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'The link is off',
              style: AppTypography.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'It stopped working just now, and the copy on our server is '
              'gone. Your keepsake is back in your drafts, ready to share '
              'again with a new link whenever you like.',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Back to Editing',
              onPressed: () => context.go('/editor/${draft.id}'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go('/keepsakes'),
              child: const Text('Go to My Keepsakes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(color: AppColors.ink),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copied')));
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
