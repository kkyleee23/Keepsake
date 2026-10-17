import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/data/models/signature.dart';

void main() {
  test('round-trips through JSON', () {
    const sig = Signature([
      [Offset(0.1, 0.5), Offset(0.2, 0.4), Offset(0.3, 0.6)],
      [Offset(0.5, 0.5)],
    ]);
    final back = Signature.fromJson(sig.toJson())!;
    expect(back.strokes.length, 2);
    expect(back.strokes.first[1], const Offset(0.2, 0.4));
    expect(back.pointCount, 4);
  });

  test('nothing usable gives null, not a crash', () {
    expect(Signature.fromJson(null), isNull);
    expect(Signature.fromJson('scribble'), isNull);
    expect(Signature.fromJson([]), isNull);
    expect(Signature.fromJson([['a', 'b'], 7, {}]), isNull);
  });

  test('points are kept inside the box', () {
    final s = Signature.fromJson([
      [-5, 9, 0.5, double.nan, 2, 0.5, 0.25, 0.75],
    ])!;
    expect(s.strokes.single, const [Offset(0, 1), Offset(1, 0.5), Offset(0.25, 0.75)]);
  });

  test('a huge signature is cut down to the limits', () {
    final many = [
      for (var i = 0; i < 500; i++) [for (var j = 0; j < 40; j++) 0.5],
    ];
    final s = Signature.fromJson(many)!;
    expect(s.strokes.length, lessThanOrEqualTo(Signature.maxStrokes));
    expect(s.pointCount, lessThanOrEqualTo(Signature.maxPoints));
  });

  test('stored compactly (three decimals)', () {
    const sig = Signature([
      [Offset(0.123456, 0.987654)],
    ]);
    expect(sig.toJson().single, [0.123, 0.988]);
  });
}
