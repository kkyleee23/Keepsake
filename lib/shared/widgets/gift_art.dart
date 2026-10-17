import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Hand-drawn pieces that make an opened keepsake feel like a gift: an
/// envelope with a leaf seal, letter paper with a folded corner, washi tape,
/// and small leaves. All flat vector shapes (no gradients, no shadows) in the
/// brand's paper and sage tones.

/// The brand leaf as a path inside [rect]: pointed tip top-right, stem
/// bottom-left, matching the leaf on the wordmark and the mascot.
Path leafPath(Rect rect) {
  final w = rect.width, h = rect.height;
  Offset p(double x, double y) => Offset(rect.left + x * w, rect.top + y * h);
  final a = p(0.08, 0.92), b = p(0.95, 0.06);
  return Path()
    ..moveTo(a.dx, a.dy)
    ..quadraticBezierTo(p(-0.02, 0.22).dx, p(-0.02, 0.22).dy, b.dx, b.dy)
    ..quadraticBezierTo(p(1.02, 0.80).dx, p(1.02, 0.80).dy, a.dx, a.dy)
    ..close();
}

/// A small leaf, filled, with a midrib.
class Leaf extends StatelessWidget {
  const Leaf({
    super.key,
    this.size = 18,
    this.color = AppColors.sage,
    this.angle = 0,
  });

  final double size;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(size: Size.square(size), painter: _LeafPainter(color)),
    );
  }
}

class _LeafPainter extends CustomPainter {
  _LeafPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawPath(leafPath(r), Paint()..color = color);
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.84),
      Offset(size.width * 0.70, size.height * 0.30),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = math.max(1, size.width * 0.06)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.color != color;
}

/// The wax seal: an evergreen disc with a white leaf. Closes every envelope.
class LeafSeal extends StatelessWidget {
  const LeafSeal({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _SealPainter());
  }
}

class _SealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) =>
      paintSeal(canvas, size.center(Offset.zero), size.shortestSide / 2);

  @override
  bool shouldRepaint(_SealPainter old) => false;
}

/// Draws the seal centered at [c] with radius [r]. A slightly wavy rim reads
/// as pressed wax without any shading.
void paintSeal(Canvas canvas, Offset c, double r, {double opacity = 1}) {
  if (opacity <= 0) return;
  final rim = Path();
  const bumps = 14;
  for (var i = 0; i <= bumps * 4; i++) {
    final t = i / (bumps * 4) * math.pi * 2;
    final rr = r * (1 + 0.045 * math.sin(t * bumps));
    final o = c + Offset(math.cos(t) * rr, math.sin(t) * rr);
    i == 0 ? rim.moveTo(o.dx, o.dy) : rim.lineTo(o.dx, o.dy);
  }
  rim.close();
  canvas.drawPath(
    rim,
    Paint()..color = AppColors.accent.withValues(alpha: opacity),
  );
  canvas.drawCircle(
    c,
    r * 0.74,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.28 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, r * 0.06),
  );
  final leafRect = Rect.fromCenter(
    center: c,
    width: r * 0.95,
    height: r * 0.95,
  );
  canvas.drawPath(
    leafPath(leafRect),
    Paint()..color = Colors.white.withValues(alpha: 0.95 * opacity),
  );
}

/// An envelope that can open. [open] runs 0 (sealed) to 1 (flap fully up),
/// [rise] lifts the letter out of the pocket (0 to 1).
class EnvelopeArt extends StatelessWidget {
  const EnvelopeArt({
    super.key,
    this.width = 260,
    this.open = 0,
    this.rise = 0,
    this.showSeal = true,
  });

  final double width;
  final double open;
  final double rise;
  final bool showSeal;

  static const double aspect = 0.66; // height / width

  /// Total box height as a multiple of the envelope height: room above for
  /// the opened flap and the rising letter.
  static const double headroom = 1.62;

  @override
  Widget build(BuildContext context) {
    final h = width * aspect;
    // Extra headroom above so the opened flap and the rising letter fit.
    return SizedBox(
      width: width,
      height: h * EnvelopeArt.headroom,
      child: CustomPaint(
        painter: _EnvelopePainter(open: open, rise: rise, seal: showSeal),
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter({
    required this.open,
    required this.rise,
    required this.seal,
  });

  final double open;
  final double rise;
  final bool seal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = w * EnvelopeArt.aspect;
    final top = size.height - h; // envelope sits at the bottom of the box
    final body = Rect.fromLTWH(0, top, w, h);
    final radius = Radius.circular(w * 0.045);
    final stroke = math.max(1.0, w * 0.006);

    final edge = Paint()
      ..color = AppColors.giftEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;

    // Back panel.
    final back = RRect.fromRectAndRadius(body, radius);
    canvas.drawRRect(back, Paint()..color = AppColors.envelopeShade);
    canvas.drawRRect(back, edge);

    final flapDepth = h * 0.56;
    // Flap scale about the top edge: 1 = closed (pointing down), -1 = open.
    final flapScale = math.cos(open * math.pi);

    void drawFlap() {
      final tipY = top + flapDepth * flapScale;
      final flap = Path()
        ..moveTo(0, top + w * 0.02)
        ..quadraticBezierTo(0, top, w * 0.04, top)
        ..lineTo(w * 0.96, top)
        ..quadraticBezierTo(w, top, w, top + w * 0.02)
        ..lineTo(w * 0.56, tipY - (flapScale >= 0 ? h * 0.03 : -h * 0.03))
        ..quadraticBezierTo(
          w * 0.5,
          tipY,
          w * 0.44,
          tipY - (flapScale >= 0 ? h * 0.03 : -h * 0.03),
        )
        ..close();
      canvas.drawPath(
        flap,
        Paint()
          ..color = flapScale >= 0
              ? AppColors.envelope
              : AppColors.envelopeShade,
      );
      canvas.drawPath(flap, edge);
    }

    // An open flap sits behind the letter.
    if (flapScale < 0) drawFlap();

    // The letter, rising out of the pocket.
    if (rise > 0 || open > 0.5) {
      final lift = h * 0.58 * Curves.easeOut.transform(rise.clamp(0.0, 1.0));
      final letter = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, top + h * 0.08 - lift, w * 0.84, h * 0.84),
        Radius.circular(w * 0.025),
      );
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, w, top + h * 0.98));
      canvas.drawRRect(letter, Paint()..color = AppColors.giftPaper);
      canvas.drawRRect(letter, edge);
      // A few quiet "written" lines and a tiny heart on the letter.
      final line = Paint()
        ..color = AppColors.giftEdge
        ..strokeWidth = stroke * 1.4
        ..strokeCap = StrokeCap.round;
      final lx = letter.left + w * 0.08;
      for (var i = 0; i < 3; i++) {
        final y = letter.top + h * (0.16 + i * 0.1);
        final end = letter.right - w * (i == 2 ? 0.30 : 0.08);
        canvas.drawLine(Offset(lx, y), Offset(end, y), line);
      }
      _heart(
        canvas,
        Offset(letter.right - w * 0.14, letter.top + h * 0.37),
        w * 0.035,
      );
      canvas.restore();
    }

    // Front pocket: left, right and bottom folds.
    final pocket = Path()
      ..moveTo(0, top + h * 0.06)
      ..lineTo(w * 0.5, top + h * 0.60)
      ..lineTo(w, top + h * 0.06)
      ..lineTo(w, top + h - radius.y)
      ..quadraticBezierTo(w, top + h, w - radius.x, top + h)
      ..lineTo(radius.x, top + h)
      ..quadraticBezierTo(0, top + h, 0, top + h - radius.y)
      ..close();
    canvas.drawPath(pocket, Paint()..color = AppColors.envelope);
    // Fold lines from the bottom corners.
    final fold = Path()
      ..moveTo(w * 0.02, top + h * 0.98)
      ..lineTo(w * 0.42, top + h * 0.56)
      ..moveTo(w * 0.98, top + h * 0.98)
      ..lineTo(w * 0.58, top + h * 0.56);
    canvas.drawPath(fold, edge);
    canvas.drawPath(pocket, edge);

    // A closed flap sits on top of everything.
    if (flapScale >= 0) drawFlap();

    // Seal on the flap tip; it lifts away as the flap opens.
    if (seal) {
      final tip = Offset(w * 0.5, top + flapDepth * flapScale - h * 0.02);
      paintSeal(canvas, tip, h * 0.13, opacity: (1 - open * 2.5).clamp(0, 1));
    }
  }

  void _heart(Canvas canvas, Offset c, double s) {
    final p = Path()
      ..moveTo(c.dx, c.dy + s * 0.9)
      ..cubicTo(
        c.dx - s * 1.6,
        c.dy - s * 0.2,
        c.dx - s * 0.6,
        c.dy - s * 1.3,
        c.dx,
        c.dy - s * 0.4,
      )
      ..cubicTo(
        c.dx + s * 0.6,
        c.dy - s * 1.3,
        c.dx + s * 1.6,
        c.dy - s * 0.2,
        c.dx,
        c.dy + s * 0.9,
      )
      ..close();
    canvas.drawPath(p, Paint()..color = AppColors.heart);
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) =>
      old.open != open || old.rise != rise || old.seal != seal;
}

/// Letter paper: a warm sheet with a folded top-right corner.
/// The stationery a letter can be written on.
enum LetterPaper {
  cream('cream', 'Cream', AppColors.giftPaper, AppColors.giftEdge, false),
  dotted('dotted', 'Dotted', AppColors.giftPaper, AppColors.giftEdge, true),
  sage('sage', 'Sage', Color(0xFFEDF1E5), Color(0xFFD3DCC6), false),
  kraft('kraft', 'Kraft', Color(0xFFEADDC6), Color(0xFFD5C2A2), false);

  const LetterPaper(this.id, this.label, this.color, this.edge, this.dots);

  final String id;
  final String label;
  final Color color;
  final Color edge;
  final bool dots;

  static LetterPaper fromId(String? id) => LetterPaper.values.firstWhere(
        (p) => p.id == id,
        orElse: () => LetterPaper.cream,
      );
}

/// A soft dot grid, like a bullet-journal page.
class DotGridPainter extends CustomPainter {
  const DotGridPainter({this.color = AppColors.giftEdge, this.spacing = 20});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var y = spacing; y < size.height; y += spacing) {
      for (var x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter old) =>
      old.color != color || old.spacing != spacing;
}

class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.fold = 22,
    this.color = AppColors.giftPaper,
    this.edge = AppColors.giftEdge,
    this.dots = false,
  });

  /// A sheet in one of the letter papers.
  factory PaperSheet.of(
    LetterPaper paper, {
    Key? key,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(AppSpacing.lg),
    double fold = 22,
  }) =>
      PaperSheet(
        key: key,
        padding: padding,
        fold: fold,
        color: paper.color,
        edge: paper.edge,
        dots: paper.dots,
        child: child,
      );

  final Widget child;
  final EdgeInsets padding;
  final double fold;
  final Color color;
  final Color edge;
  final bool dots;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaperPainter(fold: fold, color: color, edge: edge, dots: dots),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PaperPainter extends CustomPainter {
  _PaperPainter({
    required this.fold,
    required this.color,
    required Color edge,
    required this.dots,
  }) : edgeColor = edge;

  final double fold;
  final Color color;
  final Color edgeColor;
  final bool dots;

  @override
  void paint(Canvas canvas, Size size) {
    const r = AppRadius.lg;
    final w = size.width, h = size.height, f = fold;
    final sheet = Path()..moveTo(r, 0);
    if (f > 0) {
      sheet
        ..lineTo(w - f, 0)
        ..lineTo(w, f);
    } else {
      sheet
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r);
    }
    sheet
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
    final edge = Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(sheet, Paint()..color = color);
    if (dots) {
      canvas.save();
      canvas.clipPath(sheet);
      DotGridPainter(color: edgeColor.withValues(alpha: 0.9))
          .paint(canvas, size);
      canvas.restore();
    }
    canvas.drawPath(sheet, edge);
    if (f <= 0) return;
    // The folded-over corner.
    final corner = Path()
      ..moveTo(w - f, 0)
      ..lineTo(w - f, f * 0.78)
      ..quadraticBezierTo(w - f, f, w - f * 0.78, f)
      ..lineTo(w, f)
      ..close();
    canvas.drawPath(
      corner,
      Paint()..color = Color.lerp(color, edgeColor, 0.55)!,
    );
    canvas.drawPath(corner, edge);
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.fold != fold ||
      old.color != color ||
      old.edgeColor != edgeColor ||
      old.dots != dots;
}

/// A strip of washi tape, as if holding a photo or note in place.
class WashiTape extends StatelessWidget {
  const WashiTape({
    super.key,
    this.width = 72,
    this.height = 20,
    this.angle = -0.06,
    this.color = AppColors.sageSoft,
  });

  final double width;
  final double height;
  final double angle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(width, height),
        painter: _TapePainter(color),
      ),
    );
  }
}

class _TapePainter extends CustomPainter {
  _TapePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const teeth = 5;
    final p = Path()..moveTo(0, 0);
    p.lineTo(w, 0);
    for (var i = 0; i < teeth; i++) {
      final y0 = h * i / teeth, y1 = h * (i + 0.5) / teeth;
      p.lineTo(w - (i.isEven ? 3 : 0), y0);
      p.lineTo(w - 3, y1);
    }
    p.lineTo(w, h);
    p.lineTo(0, h);
    for (var i = teeth; i > 0; i--) {
      final y0 = h * i / teeth, y1 = h * (i - 0.5) / teeth;
      p.lineTo(i.isEven ? 3 : 0, y0);
      p.lineTo(3, y1);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color.withValues(alpha: 0.85));
    // Faint stripes, like printed tape.
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (var x = 10.0; x < w - 6; x += 12) {
      canvas.drawLine(Offset(x, 2), Offset(x - 5, h - 2), stripe);
    }
  }

  @override
  bool shouldRepaint(_TapePainter old) => old.color != color;
}
