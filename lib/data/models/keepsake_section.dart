import 'enums.dart';

/// One block inside a Keepsake (a letter, a photo, an Open-When item...).
///
/// The payload is intentionally generic: [content] holds the type-specific data
/// (e.g. letter body, caption, item list) and [config] holds presentation and
/// unlock rules. This keeps the architecture open to new [SectionType]s without
/// a schema migration, which the product brief calls for.
class KeepsakeSection {
  const KeepsakeSection({
    required this.id,
    required this.type,
    required this.position,
    this.content = const {},
    this.mediaIds = const [],
    this.config = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final SectionType type;

  /// Ordering within the Keepsake (0-based). Lower appears first.
  final int position;

  /// Type-specific content (plain, serializable values only).
  final Map<String, dynamic> content;

  /// References to [MediaAsset]s used by this section, in display order.
  final List<String> mediaIds;

  /// Presentation + unlock/visibility rules.
  final Map<String, dynamic> config;

  final DateTime createdAt;
  final DateTime updatedAt;

  KeepsakeSection copyWith({
    SectionType? type,
    int? position,
    Map<String, dynamic>? content,
    List<String>? mediaIds,
    Map<String, dynamic>? config,
    DateTime? updatedAt,
  }) {
    return KeepsakeSection(
      id: id,
      type: type ?? this.type,
      position: position ?? this.position,
      content: content ?? this.content,
      mediaIds: mediaIds ?? this.mediaIds,
      config: config ?? this.config,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.id,
        'position': position,
        'content': content,
        'mediaIds': mediaIds,
        'config': config,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory KeepsakeSection.fromJson(Map<String, dynamic> json) {
    return KeepsakeSection(
      id: json['id'] as String,
      type: SectionType.fromId(json['type'] as String),
      position: (json['position'] as num).toInt(),
      content: Map<String, dynamic>.from(json['content'] as Map? ?? const {}),
      mediaIds: List<String>.from(json['mediaIds'] as List? ?? const []),
      config: Map<String, dynamic>.from(json['config'] as Map? ?? const {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
