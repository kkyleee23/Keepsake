import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's real fonts (and Material icons, when the SDK has them) so
/// test screenshots look like the app instead of using the test font.
Future<void> loadTestFonts() async {
  Future<void> load(String fam, List<String> paths) async {
    final l = FontLoader(fam);
    for (final p in paths) {
      l.addFont(Future.value(ByteData.view(File(p).readAsBytesSync().buffer)));
    }
    await l.load();
  }

  await load('Inter', ['regular', 'medium', 'semibold', 'bold']
      .map((w) => 'fonts/inter/inter_$w.ttf')
      .toList());
  await load('Montserrat', ['regular', 'semibold', 'bold', 'extrabold']
      .map((w) => 'fonts/montserrat/montserrat_$w.ttf')
      .toList());
  await load('Caveat', ['fonts/caveat/caveat_variable.ttf']);
  await load('Playfair', ['regular', 'semibold', 'bold']
      .map((w) => 'fonts/playfair-display/playfair_display_$w.ttf')
      .toList());
  // Real icon glyphs in the review images, when the SDK ships the font.
  final icons = '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(icons).existsSync()) await load('MaterialIcons', [icons]);
}
