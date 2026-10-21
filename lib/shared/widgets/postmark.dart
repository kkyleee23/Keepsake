import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

/// A round ink postmark with the day it was sent, and wavy cancel lines,
/// stamped a little crooked like real mail.
class Postmark extends StatelessWidget {
  const Postmark({super.key, required this.date, this.size = 64});

  final DateTime date;
  final double size;

  static const ink = Color(0xFF2F3B4A);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Postmarked ${DateFormat.yMMMMd().format(date)}',
      child: Transform.rotate(
        angle: -0.16,
        child: CustomPaint(
          size: Size(size * 2.1, size),
          painter: _PostmarkPainter(date),
        ),
      ),
    );
  }
}

class _PostmarkPainter extends CustomPainter {
  _PostmarkPainter(this.date);

  final DateTime date;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final c = Offset(size.width - r, r);
    final ink = Paint()
      ..color = Postmark.ink.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, r * 0.06);

    // Wavy cancel lines, running off to the left.
    for (var i = 0; i < 3; i++) {
      final y = r * (0.55 + i * 0.45);
      final wave = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width - r * 1.7; x += 2) {
        wave.lineTo(x, y + math.sin(x / (r * 0.28)) * r * 0.08);
      }
      canvas.drawPath(wave, ink);
    }

    canvas.drawCircle(c, r * 0.95, ink);
    canvas.drawCircle(c, r * 0.72, ink..strokeWidth = math.max(0.8, r * 0.035));

    void text(String s, double dy, double fontSize, FontWeight w) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: fontSize,
            fontWeight: w,
            letterSpacing: fontSize * 0.08,
            color: Postmark.ink.withValues(alpha: 0.7),
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c + Offset(-tp.width / 2, dy - tp.height / 2));
      tp.dispose();
    }

    text(
      DateFormat('d MMM').format(date).toUpperCase(),
      -r * 0.12,
      r * 0.36,
      FontWeight.w700,
    );
    text('${date.year}', r * 0.34, r * 0.26, FontWeight.w600);
  }

  @override
  bool shouldRepaint(_PostmarkPainter old) => old.date != date;
}
