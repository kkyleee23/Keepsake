import 'package:flutter/material.dart';

/// Keepsake color tokens - "Sage" direction.
///
/// 60/30/10 with a single accent: warm-neutral stone background, deep evergreen
/// accent. Calm, natural, and timeless - matched to the brand's leaf-green mark.
/// No gradients, no glass, no neon. Semantic colors are the only exception to
/// the single-accent rule and are kept muted; the soft clay red also carries the
/// brand's "heart" warmth.
abstract final class AppColors {
  // 60% - background (warm stone, deliberately greener than a plain cream)
  static const Color paper = Color(0xFFF1F1EB);

  // 30% - surfaces
  static const Color surface = Color(0xFFFCFCF9);
  static const Color surfaceAlt = Color(0xFFEAEAE1); // quiet fills / pressed

  // 30% - text
  static const Color ink = Color(0xFF191B16); // primary text, focal
  static const Color inkSoft = Color(0xFF5F6358); // secondary text
  static const Color inkFaint = Color(0xFF989B8C); // hints / placeholders

  // 10% - the one accent (deep evergreen): primary action only
  static const Color accent = Color(0xFF2E6B4F);
  static const Color accentPressed = Color(0xFF255640);
  static const Color onAccent = Color(0xFFFFFFFF);

  // Hairline border - preferred over shadows
  static const Color hairline = Color(0xFFE2E2D9);

  // Semantic (muted, used consistently). Error doubles as the brand's warm
  // clay-red "heart" tone.
  static const Color success = Color(0xFF3F7A4E);
  static const Color error = Color(0xFFBC5A46);
  static const Color warning = Color(0xFFB07A1E);

  // Gift surfaces: only inside an opened keepsake (letter paper, envelope,
  // tape, leaf). Taken from the brand sheet so the gift feels hand-made but
  // still belongs to the app.
  static const Color giftPaper = Color(0xFFFBF7EF); // letter sheet
  static const Color envelope = Color(0xFFF1E9DA); // envelope body
  static const Color envelopeShade = Color(0xFFE7DCC8); // pocket and flap inside
  static const Color giftEdge = Color(0xFFDCCFB8); // paper edges and folds
  static const Color sage = Color(0xFF6B7F63); // leaves, vine
  static const Color sageSoft = Color(0xFFC8D4B5); // washi tape, leaf fills
  static const Color heart = Color(0xFFA0524D); // tiny hearts only

  // Scrim for sealed / modal overlays
  static const Color scrim = Color(0x66191B16);
}
