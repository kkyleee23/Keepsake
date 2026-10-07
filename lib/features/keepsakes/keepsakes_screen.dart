import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import 'application/keepsakes_controller.dart';
import 'widgets/keepsake_card.dart';
import '../../shared/widgets/empty_state.dart';

/// The library: a permanent place to revisit what was made and received.
/// Created / Received / Drafts tabs arrive with the recipient flow; for now it
/// lists everything newest-first.
class KeepsakesScreen extends ConsumerWidget {
  const KeepsakesScreen({super.key});

  void _open(BuildContext context, Keepsake k) {
    context.push(k.isDraft ? '/editor/${k.id}' : '/preview/${k.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recentKeepsakesProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.xl,
              AppSpacing.gutter,
              AppSpacing.md,
            ),
            child: Text('Keepsakes', style: AppTypography.displaySmall),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.bookmark_border,
                    title: 'No keepsakes yet',
                    message: "Make something they'll want to keep.",
                    actionLabel: 'Create a Keepsake',
                    onAction: () => context.go('/create'),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      0,
                      AppSpacing.gutter,
                      AppSpacing.xxl,
                    ),
                    children: [
                      for (final k in items)
                        KeepsakeCard(
                            keepsake: k, onTap: () => _open(context, k)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
