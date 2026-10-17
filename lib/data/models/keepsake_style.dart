import 'dart:ui' show Color;

/// The wax seal's colour.
enum SealColor {
  evergreen('evergreen', 'Evergreen', Color(0xFF2E6B4F)),
  terracotta('terracotta', 'Terracotta', Color(0xFFA0524D)),
  honey('honey', 'Honey', Color(0xFFB08A3E)),
  plum('plum', 'Plum', Color(0xFF6E4A6B)),
  night('night', 'Night', Color(0xFF2F3B4A));

  const SealColor(this.id, this.label, this.color);

  final String id;
  final String label;
  final Color color;

  static SealColor fromId(String? id) => SealColor.values.firstWhere(
        (s) => s.id == id,
        orElse: () => SealColor.evergreen,
      );
}

/// How a keepsake is wrapped: the envelope's paper and the seal's colour.
/// Seen on the cover before opening and carried into the gift.
class KeepsakeStyle {
  const KeepsakeStyle({this.envelope = 'cream', this.seal = SealColor.evergreen});

  /// A paper id (cream, kraft, sage, linen); see LetterPaper.
  final String envelope;
  final SealColor seal;

  static const KeepsakeStyle standard = KeepsakeStyle();

  bool get isStandard => envelope == 'cream' && seal == SealColor.evergreen;

  KeepsakeStyle copyWith({String? envelope, SealColor? seal}) => KeepsakeStyle(
        envelope: envelope ?? this.envelope,
        seal: seal ?? this.seal,
      );

  Map<String, dynamic> toJson() => {'envelope': envelope, 'seal': seal.id};

  /// Lenient on purpose: anything unknown falls back to the standard look,
  /// so older or newer app versions never break each other.
  factory KeepsakeStyle.fromJson(Object? json) {
    if (json is! Map) return standard;
    final env = json['envelope'];
    return KeepsakeStyle(
      envelope: (env is String && const {'cream', 'kraft', 'sage', 'linen'}
              .contains(env))
          ? env
          : 'cream',
      seal: SealColor.fromId(json['seal'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeepsakeStyle && other.envelope == envelope && other.seal == seal;

  @override
  int get hashCode => Object.hash(envelope, seal);
}
