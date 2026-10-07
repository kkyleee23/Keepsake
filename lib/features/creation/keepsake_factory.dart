import 'package:uuid/uuid.dart';

import '../../data/models/enums.dart';
import '../../data/models/keepsake.dart';
import '../../data/models/keepsake_section.dart';

const _uuid = Uuid();

/// Creates domain objects with sensible defaults so the UI never hand-rolls ids
/// or timestamps.
abstract final class KeepsakeFactory {
  /// A fresh draft for [occasion], titled after the occasion by default.
  static Keepsake newDraft({required Occasion occasion}) {
    final now = DateTime.now();
    return Keepsake(
      id: _uuid.v4(),
      title: occasion == Occasion.custom ? 'Untitled keepsake' : occasion.label,
      occasion: occasion,
      status: KeepsakeStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// A new section of [type] placed at [position], with empty default content.
  static KeepsakeSection newSection(SectionType type, int position) {
    final now = DateTime.now();
    return KeepsakeSection(
      id: _uuid.v4(),
      type: type,
      position: position,
      content: _defaultContent(type),
      createdAt: now,
      updatedAt: now,
    );
  }

  static Map<String, dynamic> _defaultContent(SectionType type) {
    switch (type) {
      case SectionType.letter:
        return {'title': '', 'body': ''};
      case SectionType.memory:
        return {'title': '', 'body': '', 'date': null};
      case SectionType.reasons:
        return {'title': '', 'items': <String>[]};
      case SectionType.question:
        return {'prompt': ''};
      case SectionType.customMessage:
        return {'body': ''};
      default:
        return const {};
    }
  }
}
