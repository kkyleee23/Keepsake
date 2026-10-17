import 'dart:ui' show Offset;

/// A signature drawn by hand. Each stroke is a list of points inside a 3:1
/// box, as fractions of its width (x) and height (y), so it looks the same
/// at any size.
class Signature {
  const Signature(this.strokes);

  final List<List<Offset>> strokes;

  /// Width / height of the box every signature is drawn in.
  static const double aspect = 3;

  /// Limits, so a signature stays small and a tampered one can't freeze the
  /// letter it's on.
  static const int maxStrokes = 40;
  static const int maxPoints = 1500;

  /// Points closer than this (a fraction of the width) are dropped.
  static const double minStep = 0.004;

  bool get isEmpty => strokes.every((s) => s.isEmpty);
  int get pointCount => strokes.fold(0, (n, s) => n + s.length);

  static double _round(double v) => (v * 1000).roundToDouble() / 1000;

  /// Flat lists of numbers: [[x, y, x, y, ...], ...].
  List<List<double>> toJson() => [
    for (final s in strokes)
      [
        for (final p in s) ...[_round(p.dx), _round(p.dy)],
      ],
  ];

  /// Null when there's nothing usable. Anything that isn't a number pair is
  /// skipped, every point is clamped into the box, and the limits apply.
  static Signature? fromJson(Object? raw) {
    if (raw is! List) return null;
    final strokes = <List<Offset>>[];
    var total = 0;
    for (final s in raw) {
      if (strokes.length >= maxStrokes || total >= maxPoints) break;
      if (s is! List) continue;
      final pts = <Offset>[];
      for (var i = 0; i + 1 < s.length && total < maxPoints; i += 2) {
        final x = s[i], y = s[i + 1];
        if (x is! num || y is! num || !x.isFinite || !y.isFinite) continue;
        pts.add(
          Offset(x.toDouble().clamp(0.0, 1.0), y.toDouble().clamp(0.0, 1.0)),
        );
        total++;
      }
      if (pts.isNotEmpty) strokes.add(pts);
    }
    return strokes.isEmpty ? null : Signature(strokes);
  }
}
