import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/keepsake.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/paper.dart';
import '../../publishing/new_replies.dart';

/// A library/home card for one Keepsake. Communicates the essentials only -
/// title, who it's for, occasion, and state - without overloading (brief).
class KeepsakeCard extends StatelessWidget {
  const KeepsakeCard({
    super.key,
    required this.keepsake,
    required this.onTap,
    this.onLongPress,
  });

  final Keepsake keepsake;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      keepsake.occasion.label,
      if (keepsake.recipientName.isNotEmpty) 'for ${keepsake.recipientName}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        scale: 0.985,
        child: PaperCard(
          onTap: onTap,
          onLongPress: onLongPress,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keepsake.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Wraps rather than squeezing: the replies tag drops to
                    // its own line on narrow screens or with large text.
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusTag(status: keepsake.status),
                        Text(
                          DateFormat.yMMMd().format(keepsake.updatedAt),
                          style: AppTypography.caption,
                        ),
                        NewRepliesTag(keepsake: keepsake),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final KeepsakeStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(status.label, style: AppTypography.caption),
    );
  }
}
