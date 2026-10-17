import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../shared/widgets/gift_tag.dart';

/// Each occasion's tag, printed for what it's for.
TagLook tagLookFor(Occasion o) => switch (o) {
  Occasion.birthday => const TagLook(
    paper: Color(0xFFF8E9C8),
    ink: Color(0xFF5E4310),
    edge: Color(0xFFE2C98F),
    motif: TagMotif.candle,
    pattern: TagPattern.confetti,
  ),
  Occasion.anniversary => const TagLook(
    paper: Color(0xFFF3DED6),
    ink: Color(0xFF6E3530),
    edge: Color(0xFFE2C1B6),
    motif: TagMotif.rings,
  ),
  Occasion.graduation => const TagLook(
    paper: Color(0xFF3A4757),
    ink: Color(0xFFF6EEDB),
    edge: Color(0xFF2A3440),
    motif: TagMotif.cap,
    tassel: true,
  ),
  Occasion.congratulations => const TagLook(
    paper: Color(0xFFFBF2DC),
    ink: Color(0xFF574516),
    edge: Color(0xFFE6D3A3),
    motif: TagMotif.star,
    pattern: TagPattern.sparkles,
  ),
  Occasion.love => const TagLook(
    paper: Color(0xFFEFCDC7),
    ink: Color(0xFF6A2A25),
    edge: Color(0xFFDDADA5),
    motif: TagMotif.heart,
    heartHole: true,
  ),
  Occasion.longDistance => const TagLook(
    paper: Color(0xFFFFFCF6),
    ink: Color(0xFF2F3B4A),
    edge: Color(0xFFD9D2C4),
    motif: TagMotif.plane,
    pattern: TagPattern.airmail,
  ),
  Occasion.friendship => const TagLook(
    paper: Color(0xFFDDE7D3),
    ink: Color(0xFF2F4329),
    edge: Color(0xFFBFCDB2),
    motif: TagMotif.beads,
  ),
  Occasion.family => const TagLook(
    paper: Color(0xFFC9A57A),
    ink: Color(0xFF3B2918),
    edge: Color(0xFFA9875E),
    motif: TagMotif.house,
    kraft: true,
  ),
  Occasion.thankYou => const TagLook(
    paper: Color(0xFFE6EDDF),
    ink: Color(0xFF2C5641),
    edge: Color(0xFFC6D3BC),
    motif: TagMotif.leaf,
  ),
  Occasion.apology => const TagLook(
    paper: Color(0xFFDFE6EB),
    ink: Color(0xFF30455A),
    edge: Color(0xFFC3CED6),
    motif: TagMotif.olive,
  ),
  Occasion.encouragement => const TagLook(
    paper: Color(0xFFF7E4A9),
    ink: Color(0xFF5A4410),
    edge: Color(0xFFE3C979),
    motif: TagMotif.sun,
  ),
  Occasion.justBecause => const TagLook(
    paper: Color(0xFFFBF7EF),
    ink: Color(0xFF3B4733),
    edge: Color(0xFFDCCFB8),
    motif: TagMotif.daisy,
  ),
  Occasion.custom => const TagLook(
    paper: Color(0xFFFBF7EF),
    ink: Color(0xFF3B4733),
    edge: Color(0xFFB9AA8E),
    motif: TagMotif.pencil,
    dashed: true,
  ),
};

/// The words on a tag. Mostly the occasion's name; the two long single
/// words get friendlier, shorter wording so they don't shrink.
String tagLabelFor(Occasion o) => switch (o) {
  Occasion.congratulations => 'Congrats',
  Occasion.encouragement => 'Cheering You On',
  Occasion.custom => 'Something Else',
  _ => o.label,
};

/// The occasions, shelved by what they're for. "Something else" sits on
/// its own at the end.
const occasionGroups = <(String, List<Occasion>)>[
  (
    'To celebrate',
    [
      Occasion.birthday,
      Occasion.anniversary,
      Occasion.graduation,
      Occasion.congratulations,
    ],
  ),
  (
    'For someone close',
    [
      Occasion.love,
      Occasion.longDistance,
      Occasion.friendship,
      Occasion.family,
    ],
  ),
  (
    'To say something',
    [
      Occasion.thankYou,
      Occasion.apology,
      Occasion.encouragement,
      Occasion.justBecause,
    ],
  ),
];
