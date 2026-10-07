import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography for Keepsake - "Sage" direction.
///
/// Two families used with discipline:
///  - Montserrat ([headingFamily]) - structural headings and the big title.
///  - Inter ([sans]) - running text, labels, captions.
///
/// Hierarchy comes from size + weight. Headings get tight tracking for a
/// modern, confident feel; body stays at a comfortable 1.5 line-height.
abstract final class AppTypography {
  static const String headingFamily = 'Montserrat';
  static const String sans = 'Inter';

  /// The one focal headline per screen.
  static const TextStyle display = TextStyle(
    fontFamily: headingFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.6,
    color: AppColors.ink,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: headingFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.4,
    color: AppColors.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: headingFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: headingFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.1,
    color: AppColors.ink,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.inkSoft,
  );

  static const TextStyle label = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.ink,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.inkFaint,
  );

  /// Small uppercase eyebrow (e.g. the "KEEPSAKE" kicker, occasion labels).
  static const TextStyle eyebrow = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.6,
    color: AppColors.inkFaint,
  );

  /// Maps our scale onto Material's [TextTheme] so framework widgets inherit it.
  static const TextTheme textTheme = TextTheme(
    displayLarge: display,
    displayMedium: displaySmall,
    displaySmall: displaySmall,
    headlineMedium: title,
    headlineSmall: heading,
    titleLarge: heading,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    labelLarge: label,
    bodySmall: caption,
  );
}
