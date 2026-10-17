/// Small helpers for long writing: counting words, estimating reading time,
/// and splitting text into paragraphs the way the writer typed them.
abstract final class Reading {
  /// A relaxed reading pace for personal writing.
  static const int wordsPerMinute = 200;

  static int words(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  /// Whole minutes, at least 1 when there is any text.
  static int minutes(String text) {
    final w = words(text);
    if (w == 0) return 0;
    return (w / wordsPerMinute).ceil();
  }

  static String minutesLabel(String text) {
    final m = minutes(text);
    return m <= 1 ? '1 min read' : '$m min read';
  }

  /// Paragraphs split on blank lines. Single line breaks inside a paragraph
  /// are kept, so poems and lists still read as written.
  static List<String> paragraphs(String text) => text
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
}
