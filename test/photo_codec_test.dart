import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:keepsake/data/media/photo_codec.dart';

void main() {
  test('large photos are shrunk to the max side and re-encoded as JPEG', () {
    final big = img.Image(width: 4000, height: 3000);
    img.fill(big, color: img.ColorRgb8(120, 160, 190));
    final png = Uint8List.fromList(img.encodePng(big));

    final out = PhotoCodec.encodeSync(png);
    expect(out, isNotNull);
    final decoded = img.decodeJpg(PhotoCodec.decode(out)!)!;
    expect(decoded.width, PhotoCodec.maxSide);
    expect(decoded.height, 960);
    expect(decoded.exif.isEmpty, isTrue);
  });

  test('bytes that are not an image give null instead of throwing', () {
    expect(PhotoCodec.encodeSync(Uint8List.fromList([1, 2, 3, 4])), isNull);
    expect(PhotoCodec.decode('not base64!'), isNull);
  });
}
