import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../sections/section_view.dart';

/// The opened content of a keepsake: a quiet opening line, then each section.
/// Shared by Preview and the live recipient screen so there's one renderer.
class KeepsakeContentView extends StatelessWidget {
  const KeepsakeContentView({super.key, required this.keepsake});

  final Keepsake keepsake;

  @override
  Widget build(BuildContext context) {
    final sections = keepsake.orderedSections;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        AppSpacing.xxxl,
      ),
      itemCount: sections.length + 1,
      separatorBuilder: (_, index) => index == 0
          ? const SizedBox(height: AppSpacing.lg)
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Divider(color: AppColors.hairline),
            ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            keepsake.recipientName.isEmpty
                ? keepsake.title
                : 'For ${keepsake.recipientName}',
            style: AppTypography.displaySmall,
          );
        }
        return SectionView(section: sections[index - 1]);
      },
    );
  }
}
