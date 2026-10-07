import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../../shared/widgets/primary_button.dart';

/// First step of the creation flow: choose what this is for (or start blank).
///
/// Progressive disclosure (design system 1.7): one focused choice at a time.
/// The recipient step and editor are built in the next stage; this screen holds
/// the selection so that flow can pick it up.
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  Occasion? _selected;

  void _continue() {
    final occasion = _selected;
    if (occasion == null) return;
    // Next stage wires this to recipient + editor. Kept honest for now.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting a ${occasion.label} keepsake — '
            'recipient & editor are up next.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.xl,
              AppSpacing.gutter,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What is this for?', style: AppTypography.displaySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pick an occasion to start from, or begin with a blank one.',
                  style: AppTypography.bodyLarge
                      .copyWith(color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              childAspectRatio: 2.6,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              children: [
                for (final occasion in Occasion.values)
                  _OccasionTile(
                    occasion: occasion,
                    selected: _selected == occasion,
                    onTap: () => setState(() => _selected = occasion),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: PrimaryButton(
              label: 'Continue',
              onPressed: _selected == null ? null : _continue,
            ),
          ),
        ],
      ),
    );
  }
}

class _OccasionTile extends StatelessWidget {
  const _OccasionTile({
    required this.occasion,
    required this.selected,
    required this.onTap,
  });

  final Occasion occasion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceAlt : AppColors.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            occasion.label,
            style: AppTypography.label.copyWith(
              color: selected ? AppColors.accent : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
