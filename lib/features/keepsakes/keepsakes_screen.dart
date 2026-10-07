import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/empty_state.dart';

/// The library: a permanent place to revisit what was made and received.
/// Tabs (Created / Received / Drafts / Archived) arrive with real data; for now
/// it shows an honest, useful empty state.
class KeepsakesScreen extends StatelessWidget {
  const KeepsakesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: EmptyState(
              icon: Icons.bookmark_border,
              title: 'No keepsakes yet',
              message: "Make something they'll want to keep.",
              actionLabel: 'Create a Keepsake',
              onAction: () => context.go('/create'),
            ),
          ),
        ],
      ),
    );
  }
}
