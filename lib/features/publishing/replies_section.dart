import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake_response.dart';
import '../../data/providers.dart';

/// Replies to a keepsake across every link it has had, newest first. Only
/// its creator can load them (enforced by the server). Keyed by the links
/// joined with commas (share tokens never contain one).
final repliesProvider = FutureProvider.autoDispose
    .family<List<KeepsakeResponse>?, String>((ref, tokens) async {
      final backend = ref.read(keepsakeBackendProvider);
      final lists = await Future.wait([
        for (final t in tokens.split(','))
          if (t.isNotEmpty) backend.fetchResponses(t),
      ]);
      if (lists.isNotEmpty && lists.every((l) => l == null)) return null;
      return [for (final l in lists) ...?l]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

class RepliesSection extends ConsumerWidget {
  const RepliesSection({super.key, required this.tokens});

  /// Every link the keepsake has had.
  final List<String> tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = tokens.join(',');
    final replies = ref.watch(repliesProvider(token));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Replies', style: AppTypography.heading)),
            if (replies.hasValue && !replies.isLoading)
              TextButton(
                onPressed: () => ref.invalidate(repliesProvider(token)),
                child: const Text('Refresh'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        replies.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _Note(
            text: "Couldn't load replies.",
            onRetry: () => ref.invalidate(repliesProvider(token)),
          ),
          data: (list) {
            if (list == null) {
              return _Note(
                text: "Couldn't load replies. Check your connection.",
                onRetry: () => ref.invalidate(repliesProvider(token)),
              );
            }
            if (list.isEmpty) {
              return const _Note(
                text:
                    'No replies yet. When they send something back, '
                    'it shows up here.',
              );
            }
            return Column(
              children: [
                for (final r in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ReplyTile(reply: r),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply});

  final KeepsakeResponse reply;

  @override
  Widget build(BuildContext context) {
    final name = reply.responderName?.trim() ?? '';
    final message = reply.message?.trim() ?? '';
    final when = DateFormat.yMMMd().add_jm().format(reply.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reply.reaction != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: AppRadius.button,
              ),
              child: Text(
                reply.reaction!.label,
                style: AppTypography.body.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (message.isNotEmpty) ...[
            Text(message, style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            name.isEmpty ? when : '$name, $when',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTypography.body),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}
