import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../../data/remote/auth_service.dart';
import '../keepsakes/application/keepsakes_controller.dart';
import '../keepsakes/widgets/keepsake_card.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/paper.dart';
import '../../shared/widgets/gift_art.dart';

/// Home prioritizes meaningful actions over statistics (product brief).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Keepsake k) {
    context.push(keepsakeRoute(k));
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
          RiseIn(
            child: _Hero(
              name: ref.watch(authServiceProvider).displayName,
              onCreate: () => context.go('/create'),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          SectionHeader(
            title: 'Continue where you left off',
            actionLabel: drafts.length > 2 ? 'See All' : null,
            onAction: drafts.length > 2 ? () => context.go('/keepsakes') : null,
          ),
          if (drafts.isEmpty)
            const _QuietPlaceholder(
              message:
                  'Nothing in progress. When you start something, '
                  'it waits for you here.',
            )
          else
            for (final (i, k) in drafts.take(3).indexed)
              RiseIn(
                key: ValueKey('d${k.id}'),
                index: i,
                child: KeepsakeCard(
                  keepsake: k,
                  onTap: () => _open(context, k),
                ),
              ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Recently created'),
          if (created.isEmpty)
            const _QuietPlaceholder(
              message: 'Keepsakes you finish and share will show up here.',
            )
          else
            for (final (i, k) in created.take(3).indexed)
              RiseIn(
                key: ValueKey('c${k.id}'),
                index: i + 2,
                child: KeepsakeCard(
                  keepsake: k,
                  onTap: () => _open(context, k),
                ),
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
        image: paperImage(PaperTextures.cream),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(message, style: AppTypography.body),
    );
  }
}

/// A warm hello: a paper card with a greeting by name, the main action, and
/// the mascot waving from the corner.
class _Hero extends StatelessWidget {
  const _Hero({required this.name, required this.onCreate});

  final String? name;
  final VoidCallback onCreate;

  String get _greeting {
    final h = DateTime.now().hour;
    final part = h < 5
        ? 'Up late'
        : h < 12
        ? 'Good morning'
        : h < 18
        ? 'Good afternoon'
        : 'Good evening';
    final first = name?.trim().split(' ').first ?? '';
    return first.isEmpty ? part : '$part, $first';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.giftPaper,
            image: paperImage(PaperTextures.cream),
            borderRadius: AppRadius.sheet,
            border: Border.all(color: AppColors.giftEdge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting, style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.xs),
              FractionallySizedBox(
                widthFactor: 0.66,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Make something worth keeping.',
                  style: AppTypography.title.copyWith(height: 1.25),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              FractionallySizedBox(
                widthFactor: 0.62,
                alignment: Alignment.centerLeft,
                child: Text(
                  'A letter, a book, a few photos. Made by you, kept by them.',
                  style: AppTypography.body,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Create a Keepsake',
                icon: Icons.add,
                onPressed: onCreate,
                expand: false,
              ),
            ],
          ),
        ),
        const Positioned(
          right: -AppSpacing.xs,
          top: AppSpacing.md,
          child: Mascot(size: 132, pose: MascotPose.waving, animate: true),
        ),
      ],
    );
  }
}
