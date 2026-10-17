import 'package:flutter/widgets.dart';

/// The four destinations in the bottom navigation.
enum NavGlyph { home, create, keepsakes, profile }

/// Keepsake's own navigation icons, drawn as vectors on a 24-unit grid.
///
/// Outlined when idle; when [filled], the shape gets a soft tinted fill under
/// the same outline (a quiet duotone), so the active tab reads at a glance
/// without shouting. Color and size come from the surrounding [IconTheme], so
/// the navigation bar controls active and idle colors.
class NavIcon extends StatelessWidget {
  const NavIcon(this.glyph, {super.key, this.filled = false});

  final NavGlyph glyph;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    final color = theme.color ?? const Color(0xFF000000);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _NavIconPainter(glyph: glyph, color: color, filled: filled),
      ),
    );
  }
}

class _NavIconPainter extends CustomPainter {
  _NavIconPainter({
    required this.glyph,
    required this.color,
    required this.filled,
  });

  final NavGlyph glyph;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = filled ? 1.9 : 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    switch (glyph) {
      case NavGlyph.home:
        _home(canvas, stroke, fill);
      case NavGlyph.create:
        _create(canvas, stroke, fill);
      case NavGlyph.keepsakes:
        _keepsakes(canvas, stroke, fill);
      case NavGlyph.profile:
        _profile(canvas, stroke, fill);
    }
  }

  void _home(Canvas canvas, Paint stroke, Paint fill) {
    final house = Path()
      ..moveTo(4.6, 10.4)
      ..lineTo(12, 4.1)
      ..lineTo(19.4, 10.4)
      ..lineTo(19.4, 18.6)
      ..quadraticBezierTo(19.4, 20.2, 17.8, 20.2)
      ..lineTo(6.2, 20.2)
      ..quadraticBezierTo(4.6, 20.2, 4.6, 18.6)
      ..close();
    final door = Path()
      ..moveTo(9.9, 20.2)
      ..lineTo(9.9, 16.4)
      ..arcToPoint(const Offset(14.1, 16.4), radius: const Radius.circular(2.1))
      ..lineTo(14.1, 20.2);
    if (filled) canvas.drawPath(house, fill);
    canvas.drawPath(house, stroke);
    canvas.drawPath(door, stroke);
  }

  /// A leaf that doubles as a quill pen, writing a line: the brand leaf as "make".
  void _create(Canvas canvas, Paint stroke, Paint fill) {
    final leaf = Path()
      ..moveTo(8.2, 15.8)
      ..quadraticBezierTo(6.6, 6.2, 19.6, 4.4)
      ..quadraticBezierTo(17.8, 17.4, 8.2, 15.8)
      ..close();
    final rib = Path()
      ..moveTo(8.2, 15.8)
      ..lineTo(14.6, 9.4);
    final nib = Path()
      ..moveTo(8.2, 15.8)
      ..lineTo(4.4, 19.6);
    final line = Path()
      ..moveTo(12.6, 20.2)
      ..lineTo(19.6, 20.2);
    if (filled) canvas.drawPath(leaf, fill);
    canvas.drawPath(leaf, stroke);
    canvas.drawPath(rib, stroke);
    canvas.drawPath(nib, stroke);
    canvas.drawPath(line, stroke);
  }

  /// A small gift box: a keepsake is something given and kept.
  void _keepsakes(Canvas canvas, Paint stroke, Paint fill) {
    final lid = RRect.fromLTRBR(
      3.6,
      8.4,
      20.4,
      11.8,
      const Radius.circular(1.4),
    );
    final body = Path()
      ..moveTo(5.2, 11.8)
      ..lineTo(5.2, 18.8)
      ..quadraticBezierTo(5.2, 20.4, 6.8, 20.4)
      ..lineTo(17.2, 20.4)
      ..quadraticBezierTo(18.8, 20.4, 18.8, 18.8)
      ..lineTo(18.8, 11.8);
    final ribbon = Path()
      ..moveTo(12, 8.4)
      ..lineTo(12, 20.4);
    final bow = Path()
      ..moveTo(12, 8.4)
      ..cubicTo(10.2, 4.2, 6.4, 5.0, 8.6, 8.4)
      ..moveTo(12, 8.4)
      ..cubicTo(13.8, 4.2, 17.6, 5.0, 15.4, 8.4);
    if (filled) {
      canvas.drawRRect(lid, fill);
      canvas.drawPath(Path.from(body)..close(), fill);
    }
    canvas.drawRRect(lid, stroke);
    canvas.drawPath(body, stroke);
    canvas.drawPath(ribbon, stroke);
    canvas.drawPath(bow, stroke);
  }

  void _profile(Canvas canvas, Paint stroke, Paint fill) {
    const head = Offset(12, 8.3);
    const r = 3.7;
    final body = Path()
      ..moveTo(5.0, 19.8)
      ..cubicTo(5.0, 15.6, 8.2, 13.6, 12, 13.6)
      ..cubicTo(15.8, 13.6, 19.0, 15.6, 19.0, 19.8)
      ..close();
    if (filled) {
      canvas.drawCircle(head, r, fill);
      canvas.drawPath(body, fill);
    }
    canvas.drawCircle(head, r, stroke);
    canvas.drawPath(body, stroke);
  }

  @override
  bool shouldRepaint(_NavIconPainter old) =>
      old.glyph != glyph || old.color != color || old.filled != filled;
}
