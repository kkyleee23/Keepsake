import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/text/prompts.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/enums.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/gift_art.dart';
import '../../shared/widgets/gift_tag.dart';
import 'occasion_tags.dart';

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
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _pick(Occasion o) {
    setState(() => _selected = o);
    // Bring the preview of the first line into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: Motion.of(context, Motion.medium),
        curve: Motion.settle,
      );
    });
  }

  void _continue() {
    final occasion = _selected;
    if (occasion == null) return;
    context.push('/new/recipient', extra: occasion);
  }

  Widget _tag(Occasion o, int i, {String? label}) => GiftTag(
    label: label ?? tagLabelFor(o),
    look: tagLookFor(o),
    tilt: _tilts[i % _tilts.length],
    selected: _selected == o,
    onTap: () => _pick(o),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // Not a lazy list: the preview must be laid out so picking a tag
            // can scroll to it.
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.xl,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    // Scrolls with the tags, so short screens keep room for them.
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                  // Tags shelved by what they're for, two to a row, each
                  // printed for its occasion.
                  for (final (title, occasions) in occasionGroups) ...[
                    Text(title, style: AppTypography.eyebrow),
                    const SizedBox(height: AppSpacing.xs),
                    for (var r = 0; r < occasions.length; r += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        // Both tags in a row share one height.
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var c = r; c < r + 2; c++) ...[
                                if (c > r) const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: c < occasions.length
                                      ? _tag(occasions[c], c)
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _tag(Occasion.custom, 1),
                  const SizedBox(height: AppSpacing.xl),
                  _FirstLine(occasion: _selected),
                ],
              ),
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

/// Small fixed tilts (degrees) so the tags look hung by hand, not printed.
/// Small tilts (degrees): left tags lean one way, right tags the other, so
/// the shelf looks hung by hand but stays tidy.
const _tilts = [-0.9, 0.8, 0.6, -0.7];

/// A preview of how a letter for the chosen occasion might begin, on paper.
class _FirstLine extends StatelessWidget {
  const _FirstLine({required this.occasion});

  final Occasion? occasion;

  @override
  Widget build(BuildContext context) {
    final o = occasion;
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.medium),
      switchInCurve: Motion.settle,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: o == null
          ? Padding(
              key: const ValueKey('none'),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                'Pick a tag to see how it might start. You can change '
                'every word later.',
                style: AppTypography.body.copyWith(color: AppColors.inkFaint),
              ),
            )
          : PaperSheet(
              key: ValueKey(o),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o == Occasion.custom ? 'Your own occasion' : o.label,
                    style: AppTypography.eyebrow,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${Prompts.forOccasion(o).first}...',
                    style: LetterFont.hand.body.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
            ),
    );
  }
}
