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
    final outer = r * 0.92;
    final inner = r * 0.7;
    final ink = Paint()
      ..color = Postmark.ink.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1, r * 0.055);

    // Three wavy cancel lines, parallel and evenly spaced around the ring's
    // middle, stopping just short of it.
    final end = c.dx - outer - r * 0.16;
    final wavelength = r * 0.9;
    for (var i = -1; i <= 1; i++) {
      final y = c.dy + i * r * 0.4;
      final wave = Path()..moveTo(0, y);
      for (var x = 2.0; x <= end; x += 2) {
        wave.lineTo(x, y + math.sin(x / wavelength * 2 * math.pi) * r * 0.07);
      }
      canvas.drawPath(wave, ink);
    }

    canvas.drawCircle(c, outer, ink);
    canvas.drawCircle(
      c,
      inner,
      Paint()
        ..color = ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.035),
    );

    // The date, shrunk if needed so it always sits inside the inner ring.
    final room = inner * 2 * 0.78;
    void text(String s, double dy, double fontSize, FontWeight w) {
      TextPainter layout(double f) => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: f,
            fontWeight: w,
            letterSpacing: f * 0.06,
            color: Postmark.ink.withValues(alpha: 0.72),
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      var tp = layout(fontSize);
      if (tp.width > room) {
        final fit = fontSize * room / tp.width;
        tp.dispose();
        tp = layout(fit);
      }
      tp.paint(canvas, c + Offset(-tp.width / 2, dy - tp.height / 2));
      tp.dispose();
    }

    text(
      DateFormat('d MMM').format(date).toUpperCase(),
      -r * 0.13,
      r * 0.32,
      FontWeight.w700,
    );
    text('${date.year}', r * 0.26, r * 0.22, FontWeight.w600);
  }

  @override
  bool shouldRepaint(_PostmarkPainter old) => old.date != date;
}
