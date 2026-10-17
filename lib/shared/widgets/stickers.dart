import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/keepsake_style.dart';
import 'gift_art.dart';

const _terracotta = Color(0xFFA0524D);
const _night = Color(0xFF2F3B4A);
const _honey = Color(0xFFC79A45);
const _leaf = Color(0xFF6B7F63);
const _leafDark = Color(0xFF4F6249);

/// One sticker, [size] logical pixels square.
class StickerView extends StatelessWidget {
  const StickerView({super.key, required this.kind, required this.size});

  final StickerKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kind.isPup) {
      final image = Image.asset(
        'assets/stickers/${kind.id}.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      );
      // A soft shadow under the die-cut, from the picture's own shape.
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: size * 0.025,
            bottom: -size * 0.025,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: size * 0.02,
                sigmaY: size * 0.02,
              ),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0x30191B16),
                  BlendMode.srcIn,
                ),
                child: image,
              ),
            ),
          ),
          image,
        ],
      );
    }
    return CustomPaint(size: Size.square(size), painter: _StickerPainter(kind));
  }
}

/// Stickers on an envelope [width] wide whose body starts at [top] in the
/// surrounding box. Positions are fractions of the envelope, so they line
/// up with [EnvelopeArt] at any size.
class EnvelopeStickers extends StatelessWidget {
  const EnvelopeStickers({
    super.key,
    required this.stickers,
    required this.width,
    required this.top,
  });

  final List<PlacedSticker> stickers;
  final double width;
  final double top;

  /// A sticker's size on an envelope [width] wide.
  static double sizeFor(PlacedSticker s, double width) =>
      width * 0.24 * s.scale * (s.kind.isPup ? 1.2 : 1);

  @override
  Widget build(BuildContext context) {
    final h = width * EnvelopeArt.aspect;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final s in stickers)
          Positioned(
            left: s.x * width - sizeFor(s, width) / 2,
            top: top + s.y * h - sizeFor(s, width) / 2,
            width: sizeFor(s, width),
            height: sizeFor(s, width),
            child: Transform.rotate(
              angle: s.turn * math.pi / 180,
              child: StickerView(kind: s.kind, size: sizeFor(s, width)),
            ),
          ),
      ],
    );
  }
}

class _StickerPainter extends CustomPainter {
  _StickerPainter(this.kind) : super(repaint: PaperTextures.instance);

  final StickerKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    switch (kind) {
      case StickerKind.sprig:
        _sprig(canvas, s);
      case StickerKind.stamp:
        _stamp(canvas, s);
      case StickerKind.heart:
        _heart(canvas, s);
      case StickerKind.daisy:
        _daisy(canvas, s);
      case StickerKind.moon:
        _moon(canvas, s);
      case StickerKind.airmail:
        _airmail(canvas, s);
      default:
        break;
    }
  }

  /// Shadow, then a white die-cut border with a faint paper edge.
  void _dieCut(Canvas canvas, Path shape, double s, {double border = 0.075}) {
    canvas.drawPath(
      shape.shift(Offset(0, s * 0.02)),
      Paint()
        ..color = const Color(0x2A191B16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * border * 2
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = AppColors.giftEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * border * 2 + s * 0.012
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = const Color(0xFFFFFFFD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * border * 2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(shape, Paint()..color = const Color(0xFFFFFFFD));
  }

  void _shadow(Canvas canvas, Path shape, double s) {
    canvas.drawPath(
      shape.shift(Offset(0, s * 0.022)),
      Paint()
        ..color = const Color(0x2E191B16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.022),
    );
  }

  /// A pressed sprig: a curved stem with leaves along it.
  void _sprig(Canvas canvas, double s) {
    final stem = Path()
      ..moveTo(s * 0.30, s * 0.90)
      ..quadraticBezierTo(s * 0.36, s * 0.50, s * 0.68, s * 0.12)
      ..lineTo(s * 0.70, s * 0.14)
      ..quadraticBezierTo(s * 0.40, s * 0.52, s * 0.33, s * 0.90)
      ..close();
    final leaves = <Path>[];
    void leafAt(double t, double side, double len) {
      // Along the stem, angled out to one side.
      final p = Offset(
        s * (0.30 + 0.38 * t + 0.02 * math.sin(t * math.pi)),
        s * (0.90 - 0.78 * t),
      );
      final m = Matrix4.identity()
        ..translateByDouble(p.dx, p.dy, 0, 1)
        ..rotateZ(side * 0.9 - 0.75)
        ..translateByDouble(-s * len * 0.08, -s * len * 0.92, 0, 1);
      leaves.add(
        leafPath(Rect.fromLTWH(0, 0, s * len, s * len)).transform(m.storage),
      );
    }

    leafAt(0.22, -1, 0.30);
    leafAt(0.36, 1, 0.30);
    leafAt(0.52, -1, 0.27);
    leafAt(0.66, 1, 0.25);
    leafAt(0.82, -1, 0.21);
    var all = stem;
    for (final l in leaves) {
      all = Path.combine(PathOperation.union, all, l);
    }
    _dieCut(canvas, all, s, border: 0.06);
    canvas.drawPath(stem, Paint()..color = _leafDark);
    for (final (i, l) in leaves.indexed) {
      canvas.drawPath(l, Paint()..color = i.isEven ? _leaf : _leafDark);
    }
  }

  /// A postage stamp: perforated edge, a little landscape inside.
  void _stamp(Canvas canvas, double s) {
    final r = Rect.fromLTRB(s * 0.14, s * 0.06, s * 0.86, s * 0.94);
    var paper = Path()..addRect(r);
    final bite = s * 0.028;
    final step = s * 0.072;
    for (var x = r.left + step / 2; x < r.right; x += step) {
      for (final y in [r.top, r.bottom]) {
        paper = Path.combine(
          PathOperation.difference,
          paper,
          Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: bite)),
        );
      }
    }
    for (var y = r.top + step / 2; y < r.bottom; y += step) {
      for (final x in [r.left, r.right]) {
        paper = Path.combine(
          PathOperation.difference,
          paper,
          Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: bite)),
        );
      }
    }
    _shadow(canvas, paper, s);
    canvas.drawPath(
      paper,
      PaperTextures.instance.paint(PaperTextures.cream) ??
          (Paint()..color = AppColors.giftPaper),
    );
    final inner = r.deflate(s * 0.08);
    canvas.save();
    canvas.clipRect(inner);
    canvas.drawRect(inner, Paint()..color = const Color(0xFFD9E3CF));
    canvas.drawCircle(
      Offset(inner.left + inner.width * 0.68, inner.top + inner.height * 0.32),
      inner.width * 0.16,
      Paint()..color = _honey,
    );
    final far = Path()
      ..moveTo(inner.left, inner.bottom)
      ..lineTo(inner.left, inner.top + inner.height * 0.62)
      ..quadraticBezierTo(
        inner.left + inner.width * 0.35,
        inner.top + inner.height * 0.38,
        inner.left + inner.width * 0.7,
        inner.top + inner.height * 0.66,
      )
      ..lineTo(inner.right, inner.top + inner.height * 0.6)
      ..lineTo(inner.right, inner.bottom)
      ..close();
    canvas.drawPath(far, Paint()..color = _leaf);
    final near = Path()
      ..moveTo(inner.left, inner.bottom)
      ..lineTo(inner.left, inner.top + inner.height * 0.82)
      ..quadraticBezierTo(
        inner.left + inner.width * 0.6,
        inner.top + inner.height * 0.62,
        inner.right,
        inner.top + inner.height * 0.8,
      )
      ..lineTo(inner.right, inner.bottom)
      ..close();
    canvas.drawPath(near, Paint()..color = AppColors.accent);
    canvas.restore();
    canvas.drawRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = _terracotta,
    );
  }

  Path _heartPath(Rect r) {
    final w = r.width, h = r.height;
    Offset p(double x, double y) => Offset(r.left + x * w, r.top + y * h);
    return Path()
      ..moveTo(p(0.5, 0.95).dx, p(0.5, 0.95).dy)
      ..cubicTo(
        p(0.05, 0.62).dx,
        p(0.05, 0.62).dy,
        p(-0.02, 0.18).dx,
        p(-0.02, 0.18).dy,
        p(0.26, 0.1).dx,
        p(0.26, 0.1).dy,
      )
      ..cubicTo(
        p(0.4, 0.06).dx,
        p(0.4, 0.06).dy,
        p(0.48, 0.16).dx,
        p(0.48, 0.16).dy,
        p(0.5, 0.24).dx,
        p(0.5, 0.24).dy,
      )
      ..cubicTo(
        p(0.52, 0.16).dx,
        p(0.52, 0.16).dy,
        p(0.6, 0.06).dx,
        p(0.6, 0.06).dy,
        p(0.74, 0.1).dx,
        p(0.74, 0.1).dy,
      )
      ..cubicTo(
        p(1.02, 0.18).dx,
        p(1.02, 0.18).dy,
        p(0.95, 0.62).dx,
        p(0.95, 0.62).dy,
        p(0.5, 0.95).dx,
        p(0.5, 0.95).dy,
      )
      ..close();
  }

  /// A heart cut from kraft paper, with a running stitch.
  void _heart(Canvas canvas, double s) {
    final heart = _heartPath(
      Rect.fromLTWH(s * 0.12, s * 0.14, s * 0.76, s * 0.72),
    );
    _dieCut(canvas, heart, s);
    canvas.drawPath(
      heart,
      PaperTextures.instance.paint(
            PaperTextures.kraft,
            tint: const Color(0xFFE8B8A8),
          ) ??
          (Paint()..color = _terracotta),
    );
    final stitch = _heartPath(
      Rect.fromLTWH(s * 0.21, s * 0.23, s * 0.58, s * 0.54),
    );
    final dash = Paint()
      ..color = const Color(0xF0FFFFFD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round;
    for (final m in stitch.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += s * 0.07) {
        canvas.drawPath(m.extractPath(d, d + s * 0.035), dash);
      }
    }
  }

  /// A daisy: white petals around a honey centre.
  void _daisy(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    var petals = Path();
    for (var i = 0; i < 9; i++) {
      final a = i * 2 * math.pi / 9;
      final m = Matrix4.identity()
        ..translateByDouble(c.dx, c.dy, 0, 1)
        ..rotateZ(a);
      petals = Path.combine(
        PathOperation.union,
        petals,
        (Path()..addOval(
              Rect.fromCenter(
                center: Offset(0, -s * 0.24),
                width: s * 0.17,
                height: s * 0.34,
              ),
            ))
            .transform(m.storage),
      );
    }
    _shadow(canvas, petals, s);
    canvas.drawPath(petals, Paint()..color = const Color(0xFFFFFEFA));
    canvas.drawPath(
      petals,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = AppColors.giftEdge,
    );
    canvas.drawCircle(c, s * 0.12, Paint()..color = _honey);
    final dot = Paint()..color = const Color(0x55704A12);
    for (var i = 0; i < 7; i++) {
      final a = i * 2.4;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * s * 0.055 * (i % 2 + 0.6),
        s * 0.012,
        dot,
      );
    }
  }

  /// A round night badge with a crescent moon and three stars.
  void _moon(Canvas canvas, double s) {
    final c = Offset(s / 2, s / 2);
    final badge = Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.36));
    _dieCut(canvas, badge, s);
    canvas.drawPath(badge, Paint()..color = _night);
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(
        Rect.fromCircle(center: c.translate(-s * 0.04, 0), radius: s * 0.2),
      ),
      Path()..addOval(
        Rect.fromCircle(
          center: c.translate(s * 0.05, -s * 0.07),
          radius: s * 0.18,
        ),
      ),
    );
    canvas.drawPath(moon, Paint()..color = const Color(0xFFF3E3B5));
    for (final (dx, dy, r) in [
      (0.2, -0.17, 0.035),
      (0.17, 0.12, 0.025),
      (-0.05, -0.24, 0.02),
    ]) {
      _star(canvas, c.translate(s * dx, s * dy), s * r);
    }
  }

  void _star(Canvas canvas, Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2;
      final rr = i.isEven ? r : r * 0.4;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(p..close(), Paint()..color = const Color(0xFFF3E3B5));
  }

  /// An airmail label: striped border, a small paper plane.
  void _airmail(Canvas canvas, double s) {
    final r = Rect.fromLTRB(s * 0.06, s * 0.24, s * 0.94, s * 0.76);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.03));
    final shape = Path()..addRRect(rr);
    _shadow(canvas, shape, s);
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(r, Paint()..color = const Color(0xFFFFFEFA));
    final band = s * 0.07;
    for (var i = -8; i < 20; i++) {
      final x = r.left + i * band;
      final stripe = Path()
        ..moveTo(x, r.top)
        ..lineTo(x + band, r.top)
        ..lineTo(x + band - r.height, r.bottom)
        ..lineTo(x - r.height, r.bottom)
        ..close();
      if (i % 2 != 0) continue;
      canvas.drawPath(
        stripe,
        Paint()..color = (i ~/ 2).isEven ? _terracotta : _night,
      );
    }
    final inner = r.deflate(s * 0.07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(s * 0.015)),
      PaperTextures.instance.paint(PaperTextures.cream) ??
          (Paint()..color = AppColors.giftPaper),
    );
    canvas.restore();
    // Paper plane.
    final c = inner.center;
    final u = inner.height * 0.34;
    final plane = Path()
      ..moveTo(c.dx + u * 1.5, c.dy - u * 0.9)
      ..lineTo(c.dx - u * 1.5, c.dy - u * 0.05)
      ..lineTo(c.dx - u * 0.25, c.dy + u * 0.25)
      ..lineTo(c.dx + u * 0.05, c.dy + u * 0.95)
      ..close();
    canvas.drawPath(plane, Paint()..color = _night);
    canvas.drawLine(
      Offset(c.dx + u * 1.5, c.dy - u * 0.9),
      Offset(c.dx - u * 0.25, c.dy + u * 0.25),
      Paint()
        ..color = const Color(0xFFFFFEFA)
        ..strokeWidth = s * 0.012,
    );
  }

  @override
  bool shouldRepaint(_StickerPainter old) => old.kind != kind;
}
