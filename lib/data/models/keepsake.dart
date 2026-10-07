import 'enums.dart';
import 'keepsake_section.dart';

/// Where and when a published Keepsake unlocks.
class DeliverySettings {
  const DeliverySettings({
    this.mode = DeliveryMode.immediately,
    this.openAt,
  });

  final DeliveryMode mode;

  /// When [mode] is scheduled/countdown, the moment it becomes openable.
  final DateTime? openAt;

  bool get isSealedUntilDate =>
      (mode == DeliveryMode.scheduled || mode == DeliveryMode.countdown) &&
      openAt != null;

  DeliverySettings copyWith({DeliveryMode? mode, DateTime? openAt}) =>
      DeliverySettings(mode: mode ?? this.mode, openAt: openAt ?? this.openAt);

  Map<String, dynamic> toJson() => {
        'mode': mode.id,
        'openAt': openAt?.toIso8601String(),
      };

  factory DeliverySettings.fromJson(Map<String, dynamic> json) =>
      DeliverySettings(
        mode: DeliveryMode.fromId(json['mode'] as String? ?? 'immediately'),
        openAt: json['openAt'] == null
            ? null
            : DateTime.parse(json['openAt'] as String),
      );
}

/// Who can reach a Keepsake and how it is protected.
///
/// Note: these flags describe intent. Real enforcement (e.g. scheduled access,
/// PIN checks) must live on the backend — never trust client-side hiding alone.
class PrivacySettings {
  const PrivacySettings({
    this.unlisted = true,
    this.pin,
    this.expiresAt,
  });

  /// Reachable only via its private link; not discoverable.
  final bool unlisted;

  /// Optional short code required to open. Null means no PIN.
  final String? pin;

  /// Optional hard expiry after which the link stops working.
  final DateTime? expiresAt;

  bool get hasPin => pin != null && pin!.isNotEmpty;

  PrivacySettings copyWith({bool? unlisted, String? pin, DateTime? expiresAt}) =>
      PrivacySettings(
        unlisted: unlisted ?? this.unlisted,
        pin: pin ?? this.pin,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  Map<String, dynamic> toJson() => {
        'unlisted': unlisted,
        'pin': pin,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      PrivacySettings(
        unlisted: json['unlisted'] as bool? ?? true,
        pin: json['pin'] as String?,
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.parse(json['expiresAt'] as String),
      );
}

/// The primary content object: a private digital gift made for one person.
///
/// A Keepsake is an ordered list of [sections] plus its delivery and privacy
/// settings. It can keep growing after publishing (new sections appended), so
/// nothing here assumes a fixed shape.
class Keepsake {
  const Keepsake({
    required this.id,
    this.creatorId,
    required this.title,
    required this.occasion,
    this.recipientName = '',
    this.recipientContact,
    this.coverNote,
    this.status = KeepsakeStatus.draft,
    this.sections = const [],
    this.delivery = const DeliverySettings(),
    this.privacy = const PrivacySettings(),
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.expiresAt,
  });

  final String id;
  final String? creatorId;
  final String title;
  final Occasion occasion;
  final String recipientName;
  final String? recipientContact;

  /// Short line shown on the cover, e.g. "A little something for your birthday."
  final String? coverNote;

  final KeepsakeStatus status;
  final List<KeepsakeSection> sections;
  final DeliverySettings delivery;
  final PrivacySettings privacy;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? expiresAt;

  bool get isDraft => status == KeepsakeStatus.draft;
  bool get hasContent => sections.isNotEmpty;

  /// Sections in display order.
  List<KeepsakeSection> get orderedSections {
    final list = [...sections]..sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  Keepsake copyWith({
    String? creatorId,
    String? title,
    Occasion? occasion,
    String? recipientName,
    String? recipientContact,
    String? coverNote,
    KeepsakeStatus? status,
    List<KeepsakeSection>? sections,
    DeliverySettings? delivery,
    PrivacySettings? privacy,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? expiresAt,
  }) {
    return Keepsake(
      id: id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      occasion: occasion ?? this.occasion,
      recipientName: recipientName ?? this.recipientName,
      recipientContact: recipientContact ?? this.recipientContact,
      coverNote: coverNote ?? this.coverNote,
      status: status ?? this.status,
      sections: sections ?? this.sections,
      delivery: delivery ?? this.delivery,
      privacy: privacy ?? this.privacy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'creatorId': creatorId,
        'title': title,
        'occasion': occasion.id,
        'recipientName': recipientName,
        'recipientContact': recipientContact,
        'coverNote': coverNote,
        'status': status.id,
        'sections': sections.map((s) => s.toJson()).toList(),
        'delivery': delivery.toJson(),
        'privacy': privacy.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory Keepsake.fromJson(Map<String, dynamic> json) {
    return Keepsake(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String?,
      title: json['title'] as String? ?? '',
      occasion: Occasion.fromId(json['occasion'] as String? ?? 'custom'),
      recipientName: json['recipientName'] as String? ?? '',
      recipientContact: json['recipientContact'] as String?,
      coverNote: json['coverNote'] as String?,
      status: KeepsakeStatus.fromId(json['status'] as String? ?? 'draft'),
      sections: (json['sections'] as List? ?? const [])
          .map((e) => KeepsakeSection.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      delivery: DeliverySettings.fromJson(
          Map<String, dynamic>.from(json['delivery'] as Map? ?? const {})),
      privacy: PrivacySettings.fromJson(
          Map<String, dynamic>.from(json['privacy'] as Map? ?? const {})),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );
  }
}
