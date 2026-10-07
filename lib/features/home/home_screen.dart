import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../keepsakes/application/keepsakes_controller.dart';
import '../keepsakes/widgets/keepsake_card.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/section_header.dart';

/// Home prioritizes meaningful actions over statistics (product brief).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Keepsake k) {
    context.push(k.isDraft ? '/editor/${k.id}' : '/preview/${k.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(draftsProvider);
    final created = ref
        .watch(recentKeepsakesProvider)
        .where((k) => !k.isDraft && !k.isReceived)
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xl,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Wordmark(height: 34),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Make something\nworth keeping.', style: AppTypography.display),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A letter, a memory, a small gift for someone. '
            'Made by you, kept by them.',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Create a Keepsake',
            icon: Icons.add,
            onPressed: () => context.go('/create'),
          ),
          const SizedBox(height: AppSpacing.xxl),

          SectionHeader(
            title: 'Continue where you left off',
            actionLabel: drafts.length > 2 ? 'See all' : null,
            onAction: drafts.length > 2 ? () => context.go('/keepsakes') : null,
          ),
          if (drafts.isEmpty)
            const _QuietPlaceholder(
              message: 'Nothing in progress. When you start something, '
                  'it waits for you here.',
            )
          else
            for (final k in drafts.take(3))
              KeepsakeCard(keepsake: k, onTap: () => _open(context, k)),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Recently created'),
          if (created.isEmpty)
            const _QuietPlaceholder(
              message: 'Keepsakes you finish and share will show up here.',
            )
          else
            for (final k in created.take(3))
              KeepsakeCard(keepsake: k, onTap: () => _open(context, k)),
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
