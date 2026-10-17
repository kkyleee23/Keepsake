import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

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
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.accent : AppColors.surface,
        borderRadius: AppRadius.button,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.button,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.button,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.hairline,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: selected ? AppColors.onAccent : AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
