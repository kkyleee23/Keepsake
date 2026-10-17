import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'gift_art.dart';
import 'motion.dart';
import 'whole_words.dart';

/// The little picture printed on a tag.
enum TagMotif {
  candle,
  rings,
  cap,
  star,
  heart,
  plane,
  beads,
  house,
  leaf,
  olive,
  sun,
  daisy,
  pencil,
}

/// A print across the tag's paper.
enum TagPattern { none, confetti, sparkles, airmail }

/// How one kind of tag looks: its paper, ink, print and finishing touches.
@immutable
class TagLook {
  const TagLook({
    required this.paper,
    required this.ink,
    required this.edge,
    required this.motif,
    this.pattern = TagPattern.none,
    this.kraft = false,
    this.heartHole = false,
    this.tassel = false,
    this.dashed = false,
  });

  /// Paper colour (multiplied over the cream texture).
  final Color paper;

  /// Label and motif colour.
  final Color ink;
  final Color edge;
  final TagMotif motif;
  final TagPattern pattern;

  /// Real kraft paper instead of tinted cream.
  final bool kraft;

  /// A heart-shaped punch instead of a round hole.
  final bool heartHole;

  /// A gold tassel hangs from the hole.
  final bool tassel;

  /// A dashed edge, for "write your own".
  final bool dashed;

  static const plain = TagLook(
    paper: AppColors.giftPaper,
    ink: AppColors.ink,
    edge: AppColors.giftEdge,
    motif: TagMotif.leaf,
  );
}

/// A paper gift tag: a pointed end with a punched, ringed hole and the
/// occasion's own paper and motif. Hangs at a slight [tilt] (degrees); when
/// picked it swings straight, lifts and gets an evergreen outline.
class GiftTag extends StatelessWidget {
  const GiftTag({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.look = TagLook.plain,
    this.tilt = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TagLook look;
  final double tilt;

  static const double point = 16;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.95,
        child: AnimatedRotation(
          turns: selected ? 0 : tilt / 360,
          duration: Motion.of(context, Motion.long),
          curve: Motion.pop,
          child: AnimatedScale(
            scale: selected ? 1.04 : 1,
            duration: Motion.of(context, Motion.medium),
            curve: Motion.pop,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: CustomPaint(
                  painter: _TagPainter(look: look, selected: selected),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      point + 16,
                      AppSpacing.xs,
                      AppSpacing.sm,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: WholeWords(
                            label,
                            style: AppTypography.label.copyWith(
                              fontSize: 15,
                              height: 1.2,
                              color: look.ink,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Room for the printed motif.
                        const SizedBox(width: 26, height: 26),
                      ],
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
  _TagPainter({required this.look, required this.selected})
    : super(repaint: PaperTextures.instance);

  final TagLook look;
  final bool selected;

  static const _gold = Color(0xFFC79A45);
  static const _terracotta = Color(0xFFA0524D);
  static const _night = Color(0xFF2F3B4A);
  static const _sage = Color(0xFF6B7F63);

  Path _shape(Size size) {
    final w = size.width, h = size.height;
    const p = GiftTag.point;
    const r = 8.0;
    return Path()
      ..moveTo(p, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(p, h)
      ..lineTo(1.5, h * 0.58)
      ..quadraticBezierTo(0, h * 0.5, 1.5, h * 0.42)
      ..close();
  }

  Path _heart(Offset c, double s) => Path()
    ..moveTo(c.dx, c.dy + s * 0.9)
    ..cubicTo(
      c.dx - s * 1.5,
      c.dy - s * 0.1,
      c.dx - s * 0.6,
      c.dy - s * 1.2,
      c.dx,
      c.dy - s * 0.4,
    )
    ..cubicTo(
      c.dx + s * 0.6,
      c.dy - s * 1.2,
      c.dx + s * 1.5,
      c.dy - s * 0.1,
      c.dx,
      c.dy + s * 0.9,
    )
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final shape = _shape(size);
    final c = Offset(GiftTag.point * 0.9, h / 2);
    final hole = look.heartHole
        ? _heart(c, 4.2)
        : (Path()..addOval(Rect.fromCircle(center: c, radius: 3.4)));
    final tag = Path.combine(PathOperation.difference, shape, hole);

    // Lift: a soft shadow under the picked tag.
    if (selected) {
      canvas.drawShadow(tag, const Color(0x55191B16), 4, false);
    }

    // Paper.
    final paper = look.kraft
        ? PaperTextures.instance.paint(PaperTextures.kraft)
        : PaperTextures.instance.paint(PaperTextures.cream, tint: look.paper);
    canvas.drawPath(tag, paper ?? (Paint()..color = look.paper));

    canvas.save();
    canvas.clipPath(tag);
    _pattern(canvas, size);
    canvas.restore();

    // Edge.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = look.edge;
    if (look.dashed) {
      for (final m in shape.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 9) {
          canvas.drawPath(m.extractPath(d, d + 5), edge..strokeWidth = 1.3);
        }
      }
    } else {
      canvas.drawPath(shape, edge);
    }

    // The reinforcement ring around the hole.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = look.edge;
    if (look.heartHole) {
      canvas.drawPath(_heart(c, 6), ring);
    } else {
      canvas.drawCircle(c, 5.6, ring);
    }

    // Motif, in the space the label left on the right.
    _motif(canvas, Rect.fromLTWH(w - 8 - 26, (h - 26) / 2, 26, 26));

    if (look.tassel) _drawTassel(canvas, c, h);

    if (selected) {
      canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = AppColors.accent,
      );
    }
  }

  void _pattern(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    switch (look.pattern) {
      case TagPattern.none:
        break;
      case TagPattern.confetti:
        const colors = [_terracotta, _sage, _gold, Color(0xFF6E4A6B)];
        const spots = [
          (0.30, 0.16),
          (0.42, 0.86),
          (0.55, 0.12),
          (0.63, 0.88),
          (0.72, 0.18),
          (0.36, 0.82),
          (0.50, 0.90),
          (0.66, 0.10),
        ];
        for (final (i, (fx, fy)) in spots.indexed) {
          final p = Paint()
            ..color = colors[i % colors.length].withValues(alpha: 0.75);
          final o = Offset(w * fx, h * fy);
          if (i.isEven) {
            canvas.drawCircle(o, 1.6, p);
          } else {
            canvas.save();
            canvas.translate(o.dx, o.dy);
            canvas.rotate(i * 0.7);
            canvas.drawRect(const Rect.fromLTWH(-2.2, -0.8, 4.4, 1.6), p);
            canvas.restore();
          }
        }
      case TagPattern.sparkles:
        for (final (fx, fy, s) in const [
          (0.34, 0.2, 2.6),
          (0.58, 0.84, 2.2),
          (0.70, 0.16, 1.8),
        ]) {
          _star4(canvas, Offset(w * fx, h * fy), s, _gold);
        }
      case TagPattern.airmail:
        const band = 9.0;
        for (var i = -4; i * band < w + h; i++) {
          final x = i * band;
          final stripe = Path()
            ..moveTo(x, 0)
            ..lineTo(x + band * 0.55, 0)
            ..lineTo(x + band * 0.55 - h, h)
            ..lineTo(x - h, h)
            ..close();
          canvas.drawPath(
            stripe,
            Paint()..color = i.isEven ? _terracotta : _night,
          );
        }
        // Cover the middle again, leaving a striped border.
        final inner = RRect.fromRectAndRadius(
          Rect.fromLTRB(GiftTag.point + 4, 4, w - 4, h - 4),
          const Radius.circular(5),
        );
        canvas.drawRRect(
          inner,
          PaperTextures.instance.paint(PaperTextures.cream, tint: look.paper) ??
              (Paint()..color = look.paper),
        );
    }
  }

  void _star4(Canvas canvas, Offset c, double r, Color color) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2;
      final rr = i.isEven ? r : r * 0.35;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(p..close(), Paint()..color = color);
  }

  void _drawTassel(Canvas canvas, Offset hole, double h) {
    final cord = Paint()
      ..color = _gold
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final top = hole.translate(0, 3);
    final knot = Offset(hole.dx - 3, h + 2);
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(hole.dx - 6, h * 0.8, knot.dx, knot.dy),
      cord,
    );
    canvas.drawCircle(knot, 2.4, Paint()..color = _gold);
    final fringe = Paint()
      ..color = _gold
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        knot.translate(i * 0.9, 1.5),
        knot.translate(i * 1.6, 9),
        fringe,
      );
    }
  }

  void _motif(Canvas canvas, Rect b) {
    final ink = look.ink;
    final c = b.center;
    final s = b.width;
    final fill = Paint()..color = ink;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (look.motif) {
      case TagMotif.candle:
        final body = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c.translate(0, s * 0.16),
            width: s * 0.26,
            height: s * 0.5,
          ),
          const Radius.circular(2),
        );
        canvas.drawRRect(body, Paint()..color = _terracotta);
        for (var i = 0; i < 3; i++) {
          final y = body.top + 3 + i * 4.0;
          canvas.drawLine(
            Offset(body.left, y + 2),
            Offset(body.right, y),
            Paint()
              ..color = const Color(0xFFF7E7C6)
              ..strokeWidth = 1.2,
          );
        }
        canvas.drawLine(
          Offset(c.dx, body.top),
          Offset(c.dx, body.top - 2.5),
          Paint()
            ..color = ink
            ..strokeWidth = 1,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, body.top - 10)
            ..quadraticBezierTo(c.dx + 4, body.top - 4, c.dx, body.top - 2.5)
            ..quadraticBezierTo(c.dx - 4, body.top - 4, c.dx, body.top - 10)
            ..close(),
          Paint()..color = const Color(0xFFE59A2F),
        );
      case TagMotif.rings:
        final ring = Paint()
          ..color = _gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
        canvas.drawCircle(c.translate(-s * 0.13, s * 0.04), s * 0.24, ring);
        canvas.drawCircle(c.translate(s * 0.13, -s * 0.04), s * 0.24, ring);
      case TagMotif.cap:
        final top = Path()
          ..moveTo(c.dx, c.dy - s * 0.3)
          ..lineTo(c.dx + s * 0.46, c.dy - s * 0.1)
          ..lineTo(c.dx, c.dy + s * 0.1)
          ..lineTo(c.dx - s * 0.46, c.dy - s * 0.1)
          ..close();
        final base = Path()
          ..moveTo(c.dx - s * 0.26, c.dy)
          ..lineTo(c.dx - s * 0.26, c.dy + s * 0.22)
          ..quadraticBezierTo(
            c.dx,
            c.dy + s * 0.34,
            c.dx + s * 0.26,
            c.dy + s * 0.22,
          )
          ..lineTo(c.dx + s * 0.26, c.dy)
          ..close();
        canvas.drawPath(base, fill);
        canvas.drawPath(top, fill);
        canvas.drawLine(
          c.translate(0, -s * 0.1),
          c.translate(s * 0.34, s * 0.06),
          Paint()
            ..color = _gold
            ..strokeWidth = 1.2,
        );
        canvas.drawCircle(
          c.translate(s * 0.34, s * 0.12),
          1.8,
          Paint()..color = _gold,
        );
      case TagMotif.star:
        final p = Path();
        for (var i = 0; i < 10; i++) {
          final a = i * math.pi / 5 - math.pi / 2;
          final r = i.isEven ? s * 0.44 : s * 0.19;
          final pt = c + Offset(math.cos(a), math.sin(a)) * r;
          i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(p..close(), Paint()..color = _gold);
      case TagMotif.heart:
        canvas.drawPath(
          _heart(c.translate(0, -s * 0.02), s * 0.3),
          Paint()..color = _terracotta,
        );
      case TagMotif.plane:
        final u = s * 0.34;
        final plane = Path()
          ..moveTo(c.dx + u * 1.3, c.dy - u * 0.9)
          ..lineTo(c.dx - u * 1.3, c.dy - u * 0.05)
          ..lineTo(c.dx - u * 0.2, c.dy + u * 0.25)
          ..lineTo(c.dx + u * 0.1, c.dy + u * 0.95)
          ..close();
        canvas.drawPath(plane, Paint()..color = _night);
        canvas.drawLine(
          Offset(c.dx + u * 1.3, c.dy - u * 0.9),
          Offset(c.dx - u * 0.2, c.dy + u * 0.25),
          Paint()
            ..color = look.paper
            ..strokeWidth = 1,
        );
      case TagMotif.beads:
        // A friendship bracelet: beads on a curved string.
        final string = Path()
          ..moveTo(b.left + 1, c.dy - 2)
          ..quadraticBezierTo(c.dx, c.dy + s * 0.42, b.right - 1, c.dy - 2);
        canvas.drawPath(string, line..strokeWidth = 1);
        const beads = [_terracotta, _gold, _sage, _night, _terracotta];
        final m = string.computeMetrics().first;
        for (var i = 0; i < beads.length; i++) {
          final t = m.getTangentForOffset(m.length * (0.1 + i * 0.2))!;
          canvas.drawCircle(t.position, 3, Paint()..color = beads[i]);
        }
      case TagMotif.house:
        final roof = Path()
          ..moveTo(c.dx - s * 0.42, c.dy - s * 0.02)
          ..lineTo(c.dx, c.dy - s * 0.38)
          ..lineTo(c.dx + s * 0.42, c.dy - s * 0.02)
          ..close();
        canvas.drawRect(
          Rect.fromLTRB(
            c.dx - s * 0.3,
            c.dy - s * 0.06,
            c.dx + s * 0.3,
            c.dy + s * 0.36,
          ),
          Paint()..color = const Color(0xFFF1E9DA),
        );
        canvas.drawRect(
          Rect.fromLTRB(
            c.dx - s * 0.3,
            c.dy - s * 0.06,
            c.dx + s * 0.3,
            c.dy + s * 0.36,
          ),
          line..strokeWidth = 1.3,
        );
        canvas.drawPath(roof, Paint()..color = _terracotta);
        canvas.drawRect(
          Rect.fromLTRB(
            c.dx - s * 0.07,
            c.dy + s * 0.12,
            c.dx + s * 0.07,
            c.dy + s * 0.36,
          ),
          fill,
        );
      case TagMotif.leaf:
        final r = Rect.fromCenter(center: c, width: s * 0.8, height: s * 0.8);
        canvas.drawPath(leafPath(r), Paint()..color = _sage);
        canvas.drawLine(
          r.bottomLeft.translate(s * 0.08, -s * 0.08),
          r.topRight.translate(-s * 0.1, s * 0.1),
          Paint()
            ..color = look.paper
            ..strokeWidth = 1,
        );
      case TagMotif.olive:
        final stem = Path()
          ..moveTo(b.left + 2, b.bottom - 3)
          ..quadraticBezierTo(c.dx - 2, c.dy, b.right - 3, b.top + 4);
        canvas.drawPath(
          stem,
          line
            ..strokeWidth = 1.2
            ..color = _sage,
        );
        final m = stem.computeMetrics().first;
        for (var i = 0; i < 4; i++) {
          final t = m.getTangentForOffset(m.length * (0.25 + i * 0.2))!;
          canvas.save();
          canvas.translate(t.position.dx, t.position.dy);
          canvas.rotate(t.angle * -1 + (i.isEven ? -0.9 : 0.9));
          canvas.drawOval(
            const Rect.fromLTWH(0, -1.6, 7, 3.2),
            Paint()..color = _sage,
          );
          canvas.restore();
        }
        canvas.drawCircle(
          c.translate(-3, 4),
          2.4,
          Paint()..color = const Color(0xFF4F6249),
        );
      case TagMotif.sun:
        canvas.drawCircle(c, s * 0.2, Paint()..color = const Color(0xFFE0A32E));
        final ray = Paint()
          ..color = const Color(0xFFE0A32E)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(c + d * s * 0.3, c + d * s * 0.44, ray);
        }
      case TagMotif.daisy:
        for (var i = 0; i < 7; i++) {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(i * 2 * math.pi / 7);
          final petal = Rect.fromCenter(
            center: Offset(0, -s * 0.24),
            width: s * 0.2,
            height: s * 0.32,
          );
          canvas.drawOval(petal, Paint()..color = Colors.white);
          canvas.drawOval(
            petal,
            Paint()
              ..color = look.edge
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.8,
          );
          canvas.restore();
        }
        canvas.drawCircle(c, s * 0.12, Paint()..color = _gold);
      case TagMotif.pencil:
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(-math.pi / 4);
        final bodyR = Rect.fromLTWH(-s * 0.3, -s * 0.09, s * 0.48, s * 0.18);
        canvas.drawRect(bodyR, Paint()..color = _gold);
        canvas.drawRect(
          Rect.fromLTWH(-s * 0.42, -s * 0.09, s * 0.12, s * 0.18),
          Paint()..color = _terracotta,
        );
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.18, -s * 0.09)
            ..lineTo(s * 0.4, 0)
            ..lineTo(s * 0.18, s * 0.09)
            ..close(),
          Paint()..color = const Color(0xFFE9D3AE),
        );
        canvas.drawCircle(Offset(s * 0.38, 0), 1.4, fill);
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TagPainter old) =>
      old.selected != selected || old.look != look;
}
