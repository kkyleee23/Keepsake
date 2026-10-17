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

  group('Stickers', () {
    test('round-trip through JSON', () {
      const style = KeepsakeStyle(
        envelope: 'kraft',
        stickers: [
          PlacedSticker(kind: StickerKind.stamp, x: 0.84, y: 0.2, turn: 6),
          PlacedSticker(kind: StickerKind.pupWave, scale: 1.2),
        ],
      );
      expect(KeepsakeStyle.fromJson(style.toJson()), style);
    });

    test('tampered values are clamped, unknown stickers dropped', () {
      final s = KeepsakeStyle.fromJson({
        'stickers': [
          {'id': 'stamp', 'x': 99, 'y': -5, 'r': 720, 's': 50},
          {'id': '<script>', 'x': 0.5, 'y': 0.5},
          {'id': 'heart', 'x': '0.5', 'y': double.nan},
          'not a map',
        ],
      });
      expect(s.stickers.length, 2);
      final stamp = s.stickers.first;
      expect(stamp.x, 1);
      expect(stamp.y, 0);
      expect(stamp.turn, PlacedSticker.maxTurn);
      expect(stamp.scale, PlacedSticker.maxScale);
      // Bad numbers fall back to the middle, not a crash.
      expect(s.stickers[1].x, 0.5);
      expect(s.stickers[1].y, 0.5);
    });

    test('never more than six', () {
      final s = KeepsakeStyle.fromJson({
        'stickers': [
          for (var i = 0; i < 20; i++) {'id': 'daisy', 'x': 0.5, 'y': 0.5},
        ],
      });
      expect(s.stickers.length, KeepsakeStyle.maxStickers);
    });

    test('a wrong type for stickers is ignored', () {
      expect(KeepsakeStyle.fromJson({'stickers': 'lots'}).stickers, isEmpty);
      expect(KeepsakeStyle.fromJson({'seal': 3}).seal, SealColor.evergreen);
    });

    test('no stickers key when there are none (keeps old data small)', () {
      expect(KeepsakeStyle.standard.toJson().containsKey('stickers'), isFalse);
    });
  });
}
