import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/section_header.dart';

/// Home prioritizes meaningful actions over statistics (product brief).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xl,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        children: [
          Text('Keepsake', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.sm),
          // The one focal headline per screen (serif display).
          Text('Make something\nworth keeping.', style: AppTypography.display),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A letter, a memory, a small gift for someone — '
            'made by you, kept by them.',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Create a Keepsake',
            icon: Icons.add,
            onPressed: () => context.go('/create'),
          ),
          const SizedBox(height: AppSpacing.xxl),

          const SectionHeader(title: 'Continue where you left off'),
          const _QuietPlaceholder(
            message: 'Nothing in progress. When you start something, '
                'it waits for you here.',
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Recently created'),
          const _QuietPlaceholder(
            message: 'Keepsakes you make will show up here.',
          ),
        ],
      ),
    );
  }
}

class _QuietPlaceholder extends StatelessWidget {
  const _QuietPlaceholder({required this.message});

  final String message;

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
      child: Text(message, style: AppTypography.body),
    );
  }
}
