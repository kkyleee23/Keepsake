import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/data/models/surprises.dart';

void main() {
  group('Scratch to Reveal', () {
    test('round-trips through JSON', () {
      const c = ScratchContent(
        title: 'Guess',
        hint: 'Scratch',
        secret: 'Lisbon',
      );
      final back = ScratchContent.fromJson(c.toJson());
      expect(back.title, 'Guess');
      expect(back.hint, 'Scratch');
      expect(back.secret, 'Lisbon');
    });

    test('a tampered gift is trimmed, capped and never a crash', () {
      final c = ScratchContent.fromJson({
        'title': 42,
        'hint': 'x' * 500,
        'secret': '  ${'y' * 5000}  ',
      });
      expect(c.title, '');
      expect(c.hint.length, ScratchContent.maxHint);
      expect(c.secret.length, ScratchContent.maxSecret);
      expect(ScratchContent.fromJson(const {}).isEmpty, isTrue);
    });
  });

  group('Jar of Notes', () {
    test('keeps only real notes, at most 30, each capped', () {
      final jar = NoteJar.fromJson({
        'title': 'Things',
        'notes': [
          'one',
          '   ',
          7,
          null,
          {'x': 1},
          'z' * 400,
          for (var i = 0; i < 50; i++) 'n$i',
        ],
      });
      expect(jar.notes.first, 'one');
      expect(jar.notes[1].length, NoteJar.maxNote);
      expect(jar.notes.length, NoteJar.maxNotes);
    });

    test('notes that are not a list are ignored', () {
      expect(NoteJar.fromJson({'notes': 'hello'}).isEmpty, isTrue);
      expect(
        NoteJar.fromJson({
          'notes': {'a': 'b'},
        }).isEmpty,
        isTrue,
      );
    });
  });
}
