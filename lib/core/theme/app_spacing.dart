/// The 8dp spacing grid (design system 1.1).
///
/// Every margin, padding, and gap is a multiple of 8. 4dp is allowed only for
/// fine vertical rhythm. Using named tokens keeps spacing consistent instead of
/// scattering magic numbers through the widget tree.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;

  /// Standard screen side gutter.
  static const double gutter = 24;
}
