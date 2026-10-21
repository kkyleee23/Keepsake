/// Content for the little surprises in a keepsake. Read leniently and
/// capped, so a tampered gift can't break or flood the screen.
library;

String _clip(Object? v, int max) {
  if (v is! String) return '';
  final t = v.trim();
  return t.length > max ? t.substring(0, max) : t;
}

/// A secret under gold foil that the recipient scratches off.
class ScratchContent {
  const ScratchContent({this.title = '', this.hint = '', this.secret = ''});

  final String title;

  /// Printed on the foil, like "Scratch to see where we're going".
  final String hint;

  /// What's underneath.
  final String secret;

  static const int maxTitle = 80;
  static const int maxHint = 40;
  static const int maxSecret = 280;

  bool get isEmpty => secret.isEmpty;

  Map<String, dynamic> toJson() => {
    'title': title,
    'hint': hint,
    'secret': secret,
  };

  factory ScratchContent.fromJson(Map<String, dynamic> c) => ScratchContent(
    title: _clip(c['title'], maxTitle),
    hint: _clip(c['hint'], maxHint),
    secret: _clip(c['secret'], maxSecret),
  );
}

/// A jar of tiny folded notes, drawn out one at a time.
class NoteJar {
  const NoteJar({this.title = '', this.notes = const []});

  final String title;
  final List<String> notes;

  static const int maxTitle = 80;
  static const int maxNotes = 30;
  static const int maxNote = 140;

  bool get isEmpty => notes.isEmpty;

  Map<String, dynamic> toJson() => {'title': title, 'notes': notes};

  factory NoteJar.fromJson(Map<String, dynamic> c) {
    final raw = c['notes'] is List ? c['notes'] as List : const [];
    return NoteJar(
      title: _clip(c['title'], maxTitle),
      notes: [
        for (final n in raw)
          if (_clip(n, maxNote).isNotEmpty) _clip(n, maxNote),
      ].take(maxNotes).toList(),
    );
  }
}
