import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/gift_art.dart';
import '../sections/section_view.dart';

/// The opened gift: who it's for, each section as its own little object, a
/// sprig between them, and a closing note from the person who made it.
/// Shared by Preview and the live recipient screen so there's one renderer.
class KeepsakeContentView extends StatelessWidget {
  const KeepsakeContentView({super.key, required this.keepsake, this.footer});

  final Keepsake keepsake;

  /// Optional block after the closing note (the recipient's reply card).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final k = keepsake;
    final sections = k.orderedSections;
    final from = k.senderName.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        AppSpacing.xxxl,
      ),
      children: [
        _Header(keepsake: k),
        const SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const _Sprig(),
          SectionView(section: sections[i], senderName: from),
        ],
        const SizedBox(height: AppSpacing.xxl),
        _Closing(from: from),
        if (footer != null) ...[
          const SizedBox(height: AppSpacing.xl),
          footer!,
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.keepsake});

  final Keepsake keepsake;

  @override
  Widget build(BuildContext context) {
    final k = keepsake;
    final from = k.senderName.trim();
    return Column(
      children: [
        const LeafSeal(size: 44),
        const SizedBox(height: AppSpacing.md),
        Text(
          k.occasion.label,
          style: AppTypography.eyebrow,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          k.recipientName.isEmpty ? k.title : 'For ${k.recipientName}',
          style: AppTypography.displaySmall,
          textAlign: TextAlign.center,
        ),
        if (from.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'from $from',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// A quiet break between sections: a short line, a leaf, a short line.
class _Sprig extends StatelessWidget {
  const _Sprig();

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(
          width: 36,
          height: 1,
          color: AppColors.giftEdge,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          line(),
          const SizedBox(width: AppSpacing.xs),
          const Leaf(size: 14, angle: -0.6, color: AppColors.sageSoft),
          const SizedBox(width: AppSpacing.xs),
          line(),
        ],
      ),
    );
  }
}

class _Closing extends StatelessWidget {
  const _Closing({required this.from});

  final String from;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Mascot(size: 112, pose: MascotPose.hugging),
        const SizedBox(height: AppSpacing.sm),
        Text(
          from.isEmpty ? 'Made with care' : 'Made with care by $from',
          style: AppTypography.heading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'This one is yours to keep.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
