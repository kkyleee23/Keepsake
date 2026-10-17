import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'motion.dart';

/// A small selectable text tag: library filters, reply reactions. Solid accent
/// when selected, hairline outline otherwise, same radius as buttons.
class ChoiceTag extends StatelessWidget {
  const ChoiceTag({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.short);
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        scale: 0.94,
        child: AnimatedScale(
          // A small pop when it becomes selected.
          scale: selected ? 1.0 : 0.98,
          duration: Motion.of(context, Motion.medium),
          curve: Motion.pop,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.button,
              child: AnimatedContainer(
                duration: d,
                curve: Motion.settle,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.surface,
                  borderRadius: AppRadius.button,
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.hairline,
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: d,
                  style: AppTypography.body.copyWith(
                    color: selected ? AppColors.onAccent : AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Text(label),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
