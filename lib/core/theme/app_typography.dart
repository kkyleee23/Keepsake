import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography for Keepsake.
///
/// Two families, used with discipline (design system 1.4, section 4):
///  - [serif] Playfair Display — the ONE big title per screen only.
///  - [sans]  Inter — every other piece of text (hierarchy by size + weight).
///
/// Line-height: body x1.5, headings x1.25.
abstract final class AppTypography {
  static const String serif = 'Playfair Display';
  static const String sans = 'Inter';

  /// Editorial title. Reserve for a single focal headline per screen.
  static const TextStyle display = TextStyle(
    fontFamily: serif,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.ink,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: serif,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: sans,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.ink,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: sans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
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
