import 'package:flutter/material.dart';

/// Keepsake color tokens.
///
/// Follows the design system's 60/30/10 rule with a single accent:
///  - 60% background: warm paper
///  - 30% surfaces + text: warm ink
///  - 10% accent: one muted terracotta, used only for the primary action
///
/// No gradients, no glass, no neon. Semantic colors (1.15) are the only
/// allowed exception to the single-accent rule and are kept muted.
abstract final class AppColors {
  // 60% — background
  static const Color paper = Color(0xFFFBF5EA);

  // 30% — surfaces
  static const Color surface = Color(0xFFFFFCF5);
  static const Color surfaceAlt = Color(0xFFF3EADB); // quiet fills / pressed

  // 30% — text (warm ink hierarchy)
  static const Color ink = Color(0xFF2E201A); // primary text, focal
  static const Color inkSoft = Color(0xFF6E5C50); // secondary text
  static const Color inkFaint = Color(0xFF9C8B7D); // hints / placeholders

  // 10% — the one accent (terracotta): primary action only
  static const Color accent = Color(0xFF9E4E2C);
  static const Color accentPressed = Color(0xFF874026);
  static const Color onAccent = Color(0xFFFFF7EF);

  // Hairline border — preferred over shadows (design system 1.13)
  static const Color hairline = Color(0xFFE7DCC9);

  // Semantic (muted, used consistently — 1.15)
  static const Color success = Color(0xFF4F7C4A);
  static const Color error = Color(0xFFB3392E);
  static const Color warning = Color(0xFFB0791E);

  // Scrim for sealed / modal overlays
  static const Color scrim = Color(0x662E201A);
}
