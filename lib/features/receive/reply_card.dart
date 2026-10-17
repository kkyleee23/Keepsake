import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake_response.dart';
import '../../data/providers.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/choice_tag.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/motion.dart';

/// Shown under an opened keepsake: one quiet way to send something back.
/// Only the person who made it can read the reply.
class ReplyCard extends ConsumerStatefulWidget {
  const ReplyCard({
    super.key,
    required this.token,
    this.pin,
    this.senderName,
  });

  final String token;
  final String? pin;
  final String? senderName;

  @override
  ConsumerState<ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends ConsumerState<ReplyCard> {
  final _message = TextEditingController();
  final _name = TextEditingController();
  Reaction? _reaction;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  static const _maxMessage = 1000;

  @override
  void dispose() {
    _message.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _reaction != null || _message.text.trim().isNotEmpty;

  String get _sender {
    final s = widget.senderName?.trim() ?? '';
    return s.isEmpty ? 'the person who made this' : s;
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final status = await ref.read(keepsakeBackendProvider).respond(
          widget.token,
          pin: widget.pin,
          reaction: _reaction,
          message: _message.text.trim(),
          name: _name.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _sending = false;
      switch (status) {
        case 'ok':
          _sent = true;
        case 'rate_limited':
          _error = 'Lots of replies came in just now. Try again a bit later.';
        case 'too_long':
          _error = 'That note is a little long. Keep it under '
              '$_maxMessage characters.';
        case 'empty':
          _error = 'Pick a reaction or write a few words first.';
        default:
          _error = "Couldn't send your reply. Check your connection and "
              'try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: AnimatedSize(
        duration: Motion.of(context, Motion.medium),
        curve: Motion.settle,
        alignment: Alignment.topCenter,
        // The form gives way to a little "Sent" moment that pops in.
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.medium),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1)
                  .animate(CurvedAnimation(parent: anim, curve: Motion.pop)),
              child: child,
            ),
          ),
          child: _sent
              ? KeyedSubtree(key: const ValueKey('sent'), child: _sentView())
              : KeyedSubtree(key: const ValueKey('form'), child: _form()),
        ),
      ),
    );
  }

  Widget _sentView() {
    return Column(
      children: [
        const Mascot(size: 96, pose: MascotPose.received),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Sent',
          style: AppTypography.heading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.senderName?.trim().isNotEmpty ?? false
              ? '${widget.senderName!.trim()} will see your reply.'
              : 'They will see your reply.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Send something back', style: AppTypography.heading),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Only $_sender will see this.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final r in Reaction.values)
              ChoiceTag(
                label: r.label,
                selected: _reaction == r,
                onTap: () => setState(
                  () => _reaction = _reaction == r ? null : r,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _message,
          minLines: 3,
          maxLines: 6,
          maxLength: _maxMessage,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Write a few words (optional)',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _name,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Your name (optional)',
            counterText: '',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: AppTypography.body.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Send Reply',
          loading: _sending,
          onPressed: _canSend ? _send : null,
        ),
      ],
    );
  }
}
