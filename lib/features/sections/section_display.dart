import '../../data/models/enums.dart';
import '../../data/models/keepsake_section.dart';

/// Shared text helpers so editor cards, the library, and the reader all describe
/// a section the same way.
abstract final class SectionDisplay {
  /// A short heading for the section (falls back to the type label).
  static String heading(KeepsakeSection s) {
    switch (s.type) {
      case SectionType.letter:
      case SectionType.memory:
        final t = (s.content['title'] as String?)?.trim();
        return (t == null || t.isEmpty) ? s.type.label : t;
      case SectionType.reasons:
        final t = (s.content['title'] as String?)?.trim();
        return (t == null || t.isEmpty) ? 'Reasons' : t;
      default:
        return s.type.label;
    }
  }

  /// A one-line preview of the section's content, or empty if nothing yet.
  static String preview(KeepsakeSection s) {
    switch (s.type) {
      case SectionType.letter:
      case SectionType.memory:
      case SectionType.customMessage:
        return _firstLine(s.content['body'] as String?);
      case SectionType.question:
        return _firstLine(s.content['prompt'] as String?);
      case SectionType.reasons:
        final items = (s.content['items'] as List?)?.length ?? 0;
        return items == 0 ? '' : '$items ${items == 1 ? 'reason' : 'reasons'}';
      default:
        return '';
    }
  }

  /// True when the section has no meaningful content yet.
  static bool isEmpty(KeepsakeSection s) => preview(s).isEmpty &&
      heading(s) == s.type.label &&
      s.type != SectionType.photo;

  static String _firstLine(String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return '';
    final line = t.split('\n').first;
    return line.length > 80 ? '${line.substring(0, 80)}…' : line;
  }
}
