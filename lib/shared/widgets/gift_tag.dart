import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'gift_art.dart';
import 'motion.dart';

/// A paper gift tag: a pointed end with a punched, ringed hole. Hangs at a
/// slight [tilt] (degrees); when picked it swings straight and turns
/// evergreen.
class GiftTag extends StatelessWidget {
  const GiftTag({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tilt = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double tilt;

  static const double _point = 16;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.94,
        child: AnimatedRotation(
          turns: selected ? 0 : tilt / 360,
          duration: Motion.of(context, Motion.long),
          curve: Motion.pop,
          child: AnimatedScale(
            scale: selected ? 1.05 : 1,
            duration: Motion.of(context, Motion.medium),
            curve: Motion.pop,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: CustomPaint(
                  painter: _TagPainter(selected: selected),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _point + 14,
                      AppSpacing.xs + 2,
                      AppSpacing.md,
                      AppSpacing.xs + 2,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: Motion.of(context, Motion.short),
                      style: AppTypography.label.copyWith(
                        fontSize: 15,
                        color: selected ? AppColors.onAccent : AppColors.ink,
                      ),
                      child: Text(label),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagPainter extends CustomPainter {
  _TagPainter({required this.selected})
    : super(repaint: PaperTextures.instance);

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const p = GiftTag._point;
    const r = 7.0;
    final shape = Path()
      ..moveTo(p, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(p, h)
      ..lineTo(1.5, h * 0.58)
      ..quadraticBezierTo(0, h * 0.5, 1.5, h * 0.42)
      ..close();
    final c = Offset(p * 0.85, h / 2);
    final hole = Path()..addOval(Rect.fromCircle(center: c, radius: 3.2));
    final tag = Path.combine(PathOperation.difference, shape, hole);

    final fill = selected
        ? (Paint()..color = AppColors.accent)
        : (PaperTextures.instance.paint(PaperTextures.cream) ??
              (Paint()..color = AppColors.giftPaper));
    canvas.drawPath(tag, fill);
    canvas.drawPath(
      tag,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = selected ? AppColors.accent : AppColors.giftEdge,
    );
    // The paper reinforcement ring around the hole.
    canvas.drawCircle(
      c,
      5.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = selected
            ? AppColors.onAccent.withValues(alpha: 0.55)
            : AppColors.giftEdge,
    );
  }

  @override
  bool shouldRepaint(_TagPainter old) => old.selected != selected;
}
