import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/paper.dart';

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
    context.push('/new/recipient', extra: occasion);
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What is this for?',
                        style: AppTypography.displaySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Pick an occasion to start from, or begin with a '
                        'blank one.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const Mascot(size: 104, pose: MascotPose.gift),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
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

  static IconData _icon(Occasion o) => switch (o) {
    Occasion.birthday => Icons.cake_outlined,
    Occasion.anniversary => Icons.favorite_border,
    Occasion.love => Icons.volunteer_activism_outlined,
    Occasion.longDistance => Icons.flight_takeoff,
    Occasion.friendship => Icons.diversity_1_outlined,
    Occasion.family => Icons.cottage_outlined,
    Occasion.graduation => Icons.school_outlined,
    Occasion.congratulations => Icons.celebration_outlined,
    Occasion.thankYou => Icons.redeem_outlined,
    Occasion.apology => Icons.spa_outlined,
    Occasion.encouragement => Icons.wb_sunny_outlined,
    Occasion.justBecause => Icons.local_florist_outlined,
    Occasion.custom => Icons.edit_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.short);
    return Pressable(
      child: AnimatedContainer(
        duration: d,
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: PaperCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          edge: selected ? AppColors.accent : AppColors.hairline,
          child: Row(
            children: [
              AnimatedContainer(
                duration: d,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.accent : AppColors.sageSoft,
                ),
                child: AnimatedScale(
                  scale: selected ? 1.1 : 1,
                  duration: Motion.of(context, Motion.medium),
                  curve: Motion.pop,
                  child: Icon(
                    _icon(occasion),
                    size: 18,
                    color: selected ? AppColors.onAccent : AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                // One line, never broken mid-word: long names shrink a little.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    occasion.label,
                    maxLines: 1,
                    style: AppTypography.label.copyWith(
                      fontSize: 15,
                      color: selected ? AppColors.accent : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
