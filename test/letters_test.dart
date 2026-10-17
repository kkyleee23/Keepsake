import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/core/text/prompts.dart';
import 'package:keepsake/data/models/enums.dart';
import 'package:keepsake/shared/widgets/gift_art.dart';

void main() {
  test('every occasion gets ideas, its own first', () {
    for (final o in Occasion.values) {
      expect(Prompts.forOccasion(o), isNotEmpty);
    }
    expect(Prompts.forOccasion(Occasion.apology).first, startsWith('I am sorry'));
    expect(Prompts.forOccasion(null), isNotEmpty);
  });

  test('prompts read as plain sentences (no em dashes)', () {
    for (final o in [null, ...Occasion.values]) {
      for (final p in Prompts.forOccasion(o)) {
        expect(p.contains('—'), isFalse, reason: p);
      }
    }
  });

  test('unknown paper falls back to cream', () {
    expect(LetterPaper.fromId('kraft'), LetterPaper.kraft);
    expect(LetterPaper.fromId(null), LetterPaper.cream);
    expect(LetterPaper.fromId('glitter'), LetterPaper.cream);
  });
}
