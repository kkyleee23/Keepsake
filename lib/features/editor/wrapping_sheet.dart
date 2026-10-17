import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/keepsake_style.dart';
import '../../shared/widgets/gift_art.dart';
import '../../shared/widgets/motion.dart';
import '../../shared/widgets/paper.dart';
import '../../shared/widgets/primary_button.dart';

const _envelopes = [
  LetterPaper.cream,
  LetterPaper.kraft,
  LetterPaper.sage,
  LetterPaper.linen,
];

String describeStyle(KeepsakeStyle s) {
  final paper = LetterPaper.fromId(s.envelope).label.toLowerCase();
  return '${paper[0].toUpperCase()}${paper.substring(1)} envelope, '
      '${s.seal.label.toLowerCase()} seal';
}

/// A row in the editor showing how the keepsake is wrapped.
class WrappingRow extends StatelessWidget {
  const WrappingRow({super.key, required this.style, required this.onTap});

  final KeepsakeStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.985,
      child: PaperCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            EnvelopeArt(
              width: 56,
              paper: LetterPaper.fromId(style.envelope),
              sealColor: style.seal.color,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wrapping', style: AppTypography.eyebrow),
                  Text(
                    describeStyle(style),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

/// Pick the envelope paper and seal colour, with a live preview.
Future<KeepsakeStyle?> showWrappingSheet(
  BuildContext context,
  KeepsakeStyle current,
) {
  return showModalBottomSheet<KeepsakeStyle>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _WrappingSheet(initial: current),
  );
}

class _WrappingSheet extends StatefulWidget {
  const _WrappingSheet({required this.initial});

  final KeepsakeStyle initial;

  @override
  State<_WrappingSheet> createState() => _WrappingSheetState();
}

class _WrappingSheetState extends State<_WrappingSheet> {
  late KeepsakeStyle _style = widget.initial;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.short);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How should it arrive?', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'They see this envelope before they open it.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.medium),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.96, end: 1.0).animate(a),
                    child: c,
                  ),
                ),
                child: EnvelopeArt(
                  key: ValueKey(_style),
                  width: 190,
                  paper: LetterPaper.fromId(_style.envelope),
                  sealColor: _style.seal.color,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Envelope', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final p in _envelopes)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _style = _style.copyWith(envelope: p.id),
                      ),
                      child: Pressable(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: d,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _style.envelope == p.id
                                      ? AppColors.accent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: EnvelopeArt(
                                width: 58,
                                paper: p,
                                showSeal: false,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              p.label,
                              style: AppTypography.body.copyWith(
                                color: _style.envelope == p.id
                                    ? AppColors.accent
                                    : AppColors.inkSoft,
                                fontWeight: _style.envelope == p.id
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Seal', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in SealColor.values)
                  Semantics(
                    button: true,
                    selected: _style.seal == c,
                    label: '${c.label} seal',
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _style = _style.copyWith(seal: c)),
                      child: Pressable(
                        scale: 0.9,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: d,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _style.seal == c
                                      ? AppColors.ink
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: LeafSeal(size: 40, color: c.color),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(c.label, style: AppTypography.caption),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Use This Wrapping',
              onPressed: () => Navigator.pop(context, _style),
            ),
          ],
        ),
      ),
    );
  }
}
