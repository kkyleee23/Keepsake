import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/core/text/reading.dart';

void main() {
  test('counts words across spaces and line breaks', () {
    expect(Reading.words(''), 0);
    expect(Reading.words('  one two\nthree\n\nfour  '), 4);
  });

  test('reading time rounds up and is at least a minute', () {
    expect(Reading.minutes(''), 0);
    expect(Reading.minutesLabel('a few words'), '1 min read');
    expect(Reading.minutes(List.filled(401, 'word').join(' ')), 3);
  });

  test('paragraphs split on blank lines and keep single line breaks', () {
    const text = 'Roses are red,\nviolets are blue.\n\n\nSecond part.\n  \nThird.';
    expect(Reading.paragraphs(text), [
      'Roses are red,\nviolets are blue.',
      'Second part.',
      'Third.',
    ]);
  });
}
