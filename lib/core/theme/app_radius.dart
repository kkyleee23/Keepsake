import 'package:flutter/widgets.dart';

/// One consistent corner-radius scale (design system 1.16).
///
/// Mismatched radii look sloppy, so buttons/cards/inputs draw from the same set.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12; // buttons, inputs
  static const double lg = 14; // cards
  static const double xl = 20; // large surfaces / sheets

  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius input = BorderRadius.all(Radius.circular(md));
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheet = BorderRadius.all(Radius.circular(xl));
}
