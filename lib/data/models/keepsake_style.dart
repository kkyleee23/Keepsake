import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable, listEquals;

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

/// A sticker that can go on the envelope. Painted ones are drawn in code;
/// the pup ones are die-cut pictures of the mascot.
enum StickerKind {
  sprig('sprig', 'Pressed sprig'),
  stamp('stamp', 'Stamp'),
  heart('heart', 'Stitched heart'),
  daisy('daisy', 'Daisy'),
  moon('moon', 'Moon'),
  airmail('airmail', 'Airmail'),
  pupWave('pup_wave', 'Pup waving'),
  pupHug('pup_hug', 'Pup hugging'),
  pupCheer('pup_cheer', 'Pup cheering'),
  pupGift('pup_gift', 'Pup with a gift'),
  pupRead('pup_read', 'Pup reading'),
  pupSleep('pup_sleep', 'Pup napping');

  const StickerKind(this.id, this.label);

  final String id;
  final String label;

  bool get isPup => id.startsWith('pup_');

  static StickerKind? fromId(Object? id) {
    for (final k in values) {
      if (k.id == id) return k;
    }
    return null;
  }
}

/// A sticker stuck on the envelope. [x] and [y] place its centre as a
/// fraction of the envelope's width and height, [turn] is its angle in
/// degrees and [scale] its size, so it lands in the same spot on any screen.
@immutable
class PlacedSticker {
  const PlacedSticker({
    required this.kind,
    this.x = 0.5,
    this.y = 0.5,
    this.turn = 0,
    this.scale = 1,
  });

  final StickerKind kind;
  final double x;
  final double y;
  final double turn;
  final double scale;

  static const double minScale = 0.7;
  static const double maxScale = 1.5;
  static const double maxTurn = 40;

  PlacedSticker copyWith({double? x, double? y, double? turn, double? scale}) =>
      PlacedSticker(
        kind: kind,
        x: (x ?? this.x).clamp(0.0, 1.0),
        y: (y ?? this.y).clamp(0.0, 1.0),
        turn: (turn ?? this.turn).clamp(-maxTurn, maxTurn),
        scale: (scale ?? this.scale).clamp(minScale, maxScale),
      );

  static double _round(double v) => (v * 1000).roundToDouble() / 1000;

  Map<String, dynamic> toJson() => {
    'id': kind.id,
    'x': _round(x),
    'y': _round(y),
    'r': turn.round(),
    's': _round(scale),
  };

  /// Null when the sticker is unknown or the data is broken. Numbers are
  /// clamped, so a tampered value can't push a sticker off the envelope or
  /// blow it up to cover the screen.
  static PlacedSticker? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = StickerKind.fromId(json['id']);
    if (kind == null) return null;
    double num0(Object? v, double fallback) =>
        (v is num && v.isFinite) ? v.toDouble() : fallback;
    return PlacedSticker(kind: kind).copyWith(
      x: num0(json['x'], 0.5),
      y: num0(json['y'], 0.5),
      turn: num0(json['r'], 0),
      scale: num0(json['s'], 1),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlacedSticker &&
      other.kind == kind &&
      other.x == x &&
      other.y == y &&
      other.turn == turn &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(kind, x, y, turn, scale);
}

/// How a keepsake is wrapped: the envelope's paper, the seal's colour and
/// any stickers on the front. Seen on the cover before opening.
class KeepsakeStyle {
  const KeepsakeStyle({
    this.envelope = 'cream',
    this.seal = SealColor.evergreen,
    this.stickers = const [],
  });

  /// A paper id (cream, kraft, sage, linen); see LetterPaper.
  final String envelope;
  final SealColor seal;
  final List<PlacedSticker> stickers;

  /// The most stickers one envelope can hold (the server keeps no more).
  static const int maxStickers = 6;

  static const KeepsakeStyle standard = KeepsakeStyle();

  bool get isStandard =>
      envelope == 'cream' && seal == SealColor.evergreen && stickers.isEmpty;

  KeepsakeStyle copyWith({
    String? envelope,
    SealColor? seal,
    List<PlacedSticker>? stickers,
  }) => KeepsakeStyle(
    envelope: envelope ?? this.envelope,
    seal: seal ?? this.seal,
    stickers: stickers ?? this.stickers,
  );

  Map<String, dynamic> toJson() => {
    'envelope': envelope,
    'seal': seal.id,
    if (stickers.isNotEmpty) 'stickers': [for (final s in stickers) s.toJson()],
  };

  /// Lenient on purpose: anything unknown falls back to the standard look,
  /// so older or newer app versions never break each other.
  factory KeepsakeStyle.fromJson(Object? json) {
    if (json is! Map) return standard;
    final env = json['envelope'];
    return KeepsakeStyle(
      envelope:
          (env is String &&
              const {'cream', 'kraft', 'sage', 'linen'}.contains(env))
          ? env
          : 'cream',
      seal: SealColor.fromId(
        json['seal'] is String ? json['seal'] as String : null,
      ),
      stickers: [
        for (final raw
            in (json['stickers'] is List ? json['stickers'] as List : const [])
                .take(maxStickers))
          ?PlacedSticker.fromJson(raw),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeepsakeStyle &&
      other.envelope == envelope &&
      other.seal == seal &&
      listEquals(other.stickers, stickers);

  @override
  int get hashCode => Object.hash(envelope, seal, Object.hashAll(stickers));
}
