import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Photos travel inside the keepsake, so each one is shrunk and re-encoded on
/// the device first: longest side at most [maxSide] px, JPEG at [quality].
/// That keeps a photo around 100 to 250 KB, strips camera metadata (EXIF,
/// including location), and fixes rotation.
abstract final class PhotoCodec {
  static const int maxSide = 1280;
  static const int quality = 78;

  /// The most photos one keepsake can hold, across all its photo sections.
  static const int maxPerKeepsake = 6;

  /// Returns base64 JPEG, or null if the bytes aren't a readable image.
  static Future<String?> encode(Uint8List bytes) => compute(encodeSync, bytes);

  /// The same work on the current isolate (used by [encode] and by tests).
  static String? encodeSync(Uint8List bytes) {
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return null; // not an image we can read
    }
    if (decoded == null) return null;
    var image = img.bakeOrientation(decoded);
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > maxSide) {
      image = image.width >= image.height
          ? img.copyResize(
              image,
              width: maxSide,
              interpolation: img.Interpolation.average,
            )
          : img.copyResize(
              image,
              height: maxSide,
              interpolation: img.Interpolation.average,
            );
    }
    // A fresh JPEG carries no EXIF from the original.
    image.exif = img.ExifData();
    return base64Encode(img.encodeJpg(image, quality: quality));
  }

  static Uint8List? decode(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }
}
