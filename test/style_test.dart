import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/data/models/enums.dart';
import 'package:keepsake/data/models/keepsake.dart';
import 'package:keepsake/shared/widgets/gift_art.dart';

void main() {
  test('wrapping survives a save and load', () {
    final now = DateTime(2026, 10, 17);
    final k = Keepsake(
      id: 'k',
      title: 'T',
      occasion: Occasion.birthday,
      createdAt: now,
      updatedAt: now,
      style: const KeepsakeStyle(envelope: 'kraft', seal: SealColor.plum),
    );
    final back = Keepsake.fromJson(k.toJson());
    expect(back.style, k.style);
  });

  test('old keepsakes without a style get the standard wrapping', () {
    expect(KeepsakeStyle.fromJson(null), KeepsakeStyle.standard);
    expect(KeepsakeStyle.fromJson({'envelope': 'glitter', 'seal': 'gold'}),
        KeepsakeStyle.standard);
  });

  test('letter fonts fall back to clean', () {
    expect(LetterFont.fromId('hand'), LetterFont.hand);
    expect(LetterFont.fromId(null), LetterFont.clean);
    expect(LetterFont.fromId('comic'), LetterFont.clean);
  });
}
