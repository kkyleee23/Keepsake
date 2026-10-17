import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'gift_art.dart' show leafPath;
import 'motion.dart';

/// The four destinations in the bottom navigation.
enum NavGlyph { home, create, keepsakes, profile }

/// Keepsake's own navigation icons, drawn as vectors on a 24-unit grid:
/// a cottage with a sprout, a pencil with a sparkle, a memory jar holding a
/// heart, and the mascot's own face.
///
/// Outlined when idle. When [filled] turns on, the shape fills in and the icon
/// does a small hop, so the tab you picked answers back. Color and size come
/// from the surrounding [IconTheme], so the navigation bar controls active and
/// idle colors.
class NavIcon extends StatefulWidget {
  const NavIcon(this.glyph, {super.key, this.filled = false});

  final NavGlyph glyph;
  final bool filled;

  @override
  State<NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<NavIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void initState() {
    super.initState();
    // The navigation bar swaps in a separate selected icon, so the hop starts
    // when that filled icon first appears.
    if (widget.filled) _hop.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.filled && Motion.reduced(context)) _hop.value = 1;
  }

  @override
  void didUpdateWidget(NavIcon old) {
    super.didUpdateWidget(old);
    if (widget.filled && !old.filled) {
      if (Motion.reduced(context)) {
        _hop.value = 1;
      } else {
        _hop.forward(from: 0);
      }
    } else if (!widget.filled && old.filled) {
      _hop.value = 0;
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    final color = theme.color ?? const Color(0xFF000000);
    return AnimatedBuilder(
      animation: _hop,
      builder: (context, _) {
        final t = _hop.value;
        // A quick hop up and back with a tiny wiggle, then settle.
        final arc = math.sin(math.pi * Curves.easeOut.transform(t));
        final wiggle = math.sin(t * math.pi * 3) * (1 - t) * 0.12;
        return Transform.translate(
          offset: Offset(0, -3.5 * arc),
          child: Transform.rotate(
            angle: wiggle,
            child: Transform.scale(
              scale: 1 + 0.12 * arc,
              child: SizedBox.square(
                dimension: size,
                child: CustomPaint(
                  painter: _NavIconPainter(
                    glyph: widget.glyph,
                    color: color,
                    fill: widget.filled ? Curves.easeOut.transform(t) : 0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavIconPainter extends CustomPainter {
  _NavIconPainter({
    required this.glyph,
    required this.color,
    required this.fill,
  });

  final NavGlyph glyph;
  final Color color;

  /// 0 = outline only, 1 = fully filled in.
  final double fill;

  late final Paint _stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.7 + 0.2 * fill
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  late final Paint _tint = Paint()
    ..color = color.withValues(alpha: 0.22 * fill)
    ..style = PaintingStyle.fill;

  late final Paint _solid = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    switch (glyph) {
      case NavGlyph.home:
        _home(canvas);
      case NavGlyph.create:
        _create(canvas);
      case NavGlyph.keepsakes:
        _jar(canvas);
      case NavGlyph.profile:
        _mascot(canvas);
    }
  }

  /// A cottage with an arched door and a leaf sprouting by the roof.
  void _home(Canvas canvas) {
    final house = Path()
      ..moveTo(4.4, 11.6)
      ..lineTo(11.0, 5.6)
      ..quadraticBezierTo(12, 4.8, 13.0, 5.6)
      ..lineTo(19.6, 11.6)
      ..moveTo(5.8, 10.6)
      ..lineTo(5.8, 18.6)
      ..quadraticBezierTo(5.8, 20.2, 7.4, 20.2)
      ..lineTo(16.6, 20.2)
      ..quadraticBezierTo(18.2, 20.2, 18.2, 18.6)
      ..lineTo(18.2, 10.6);
    final body = Path()
      ..moveTo(5.8, 10.6)
      ..lineTo(12, 5.2)
      ..lineTo(18.2, 10.6)
      ..lineTo(18.2, 20.2)
      ..lineTo(5.8, 20.2)
      ..close();
    final door = Path()
      ..moveTo(10.3, 20.2)
      ..lineTo(10.3, 16.6)
      ..arcToPoint(const Offset(13.7, 16.6), radius: const Radius.circular(1.7))
      ..lineTo(13.7, 20.2);
    canvas.drawPath(body, _tint);
    canvas.drawPath(house, _stroke);
    canvas.drawPath(door, _stroke);
    // Sprout: a short stem and a leaf.
    canvas.drawLine(const Offset(16.3, 8.6), const Offset(16.3, 5.4), _stroke);
    final leaf = leafPath(const Rect.fromLTWH(16.0, 2.2, 4.4, 3.8));
    if (fill > 0) {
      canvas.drawPath(leaf, _solid..color = color.withValues(alpha: fill));
    }
    canvas.drawPath(leaf, _stroke);
  }

  /// A pencil writing, with a little four-point sparkle.
  void _create(Canvas canvas) {
    final pencil = Path()
      ..moveTo(4.2, 19.8)
      ..lineTo(5.3, 15.6)
      ..lineTo(14.9, 6.0)
      ..quadraticBezierTo(16.1, 4.8, 17.3, 6.0)
      ..lineTo(18.0, 6.7)
      ..quadraticBezierTo(19.2, 7.9, 18.0, 9.1)
      ..lineTo(8.4, 18.7)
      ..close();
    canvas.drawPath(pencil, _tint);
    canvas.drawPath(pencil, _stroke);
    canvas.drawLine(const Offset(5.3, 15.6), const Offset(8.4, 18.7), _stroke);
    canvas.drawLine(const Offset(13.2, 7.7), const Offset(16.3, 10.8), _stroke);
    _sparkle(canvas, const Offset(18.6, 16.4), 2.9);
    _sparkle(canvas, const Offset(7.0, 6.2), 1.6);
  }

  void _sparkle(Canvas canvas, Offset c, double r) {
    final k = r * 0.28;
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(p, _solid..color = color);
  }

  /// A memory jar with a lid and a heart inside.
  void _jar(Canvas canvas) {
    final lid = RRect.fromLTRBR(
      7.4,
      3.4,
      16.6,
      6.4,
      const Radius.circular(1.2),
    );
    final jar = Path()
      ..moveTo(8.4, 6.4)
      ..lineTo(8.4, 7.6)
      ..quadraticBezierTo(5.2, 9.2, 5.2, 12.8)
      ..lineTo(5.2, 17.0)
      ..quadraticBezierTo(5.2, 20.6, 8.8, 20.6)
      ..lineTo(15.2, 20.6)
      ..quadraticBezierTo(18.8, 20.6, 18.8, 17.0)
      ..lineTo(18.8, 12.8)
      ..quadraticBezierTo(18.8, 9.2, 15.6, 7.6)
      ..lineTo(15.6, 6.4);
    canvas.drawPath(Path.from(jar)..close(), _tint);
    canvas.drawPath(jar, _stroke);
    canvas.drawRRect(lid, _tint);
    canvas.drawRRect(lid, _stroke);
    // Heart.
    const c = Offset(12, 14.6);
    const s = 2.7;
    final heart = Path()
      ..moveTo(c.dx, c.dy + s * 0.95)
      ..cubicTo(
        c.dx - s * 1.7,
        c.dy - s * 0.1,
        c.dx - s * 0.7,
        c.dy - s * 1.4,
        c.dx,
        c.dy - s * 0.45,
      )
      ..cubicTo(
        c.dx + s * 0.7,
        c.dy - s * 1.4,
        c.dx + s * 1.7,
        c.dy - s * 0.1,
        c.dx,
        c.dy + s * 0.95,
      )
      ..close();
    if (fill > 0) {
      canvas.drawPath(heart, _solid..color = color.withValues(alpha: fill));
    }
    canvas.drawPath(heart, _stroke..strokeWidth = 1.5);
  }

  /// The mascot's face: round head, floppy ears, a leaf on top, two dot eyes
  /// and a small smile.
  void _mascot(Canvas canvas) {
    final head = Rect.fromCenter(
      center: const Offset(12, 13.8),
      width: 12.6,
      height: 11.0,
    );
    final earL = Path()
      ..moveTo(6.6, 11.2)
      ..cubicTo(4.0, 11.6, 2.8, 15.6, 4.2, 17.6)
      ..cubicTo(5.2, 18.9, 6.6, 17.4, 6.9, 15.8);
    final earR = Path()
      ..moveTo(17.4, 11.2)
      ..cubicTo(20.0, 11.6, 21.2, 15.6, 19.8, 17.6)
      ..cubicTo(18.8, 18.9, 17.4, 17.4, 17.1, 15.8);
    canvas.drawOval(head, _tint);
    canvas.drawPath(Path.from(earL)..close(), _tint);
    canvas.drawPath(Path.from(earR)..close(), _tint);
    canvas.drawOval(head, _stroke);
    canvas.drawPath(earL, _stroke);
    canvas.drawPath(earR, _stroke);
    // Leaf on top.
    final leaf = leafPath(const Rect.fromLTWH(11.2, 4.2, 4.6, 4.0));
    if (fill > 0) {
      canvas.drawPath(leaf, _solid..color = color.withValues(alpha: fill));
    }
    canvas.drawPath(leaf, _stroke);
    // Eyes and smile.
    _solid.color = color;
    canvas.drawCircle(const Offset(9.7, 13.9), 1.0, _solid);
    canvas.drawCircle(const Offset(14.3, 13.9), 1.0, _solid);
    final smile = Path()
      ..moveTo(10.9, 16.2)
      ..quadraticBezierTo(12, 17.1, 13.1, 16.2);
    canvas.drawPath(smile, _stroke..strokeWidth = 1.3);
  }

  @override
  bool shouldRepaint(_NavIconPainter old) =>
      old.glyph != glyph || old.color != color || old.fill != fill;
}
