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

  test('location and camera data are removed', () {
    final photo = img.Image(width: 800, height: 600);
    img.fill(photo, color: img.ColorRgb8(200, 180, 150));
    photo.exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N');
    photo.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(51, 1);
    photo.exif.gpsIfd['GPSLongitude'] = img.IfdValueRational(0, 1);
    photo.exif.imageIfd['Make'] = img.IfdValueAscii('PhoneMaker');
    final withGps = Uint8List.fromList(img.encodeJpg(photo));
    // The original really does carry the location.
    expect(img.decodeJpg(withGps)!.exif.gpsIfd.isEmpty, isFalse);

    final out = PhotoCodec.decode(PhotoCodec.encodeSync(withGps))!;
    final back = img.decodeJpg(out)!;
    expect(back.exif.gpsIfd.isEmpty, isTrue);
    expect(back.exif.imageIfd.isEmpty, isTrue);
    // No EXIF block in the file at all.
    expect(String.fromCharCodes(out).contains('Exif'), isFalse);
    expect(String.fromCharCodes(out).contains('PhoneMaker'), isFalse);
  });
}
