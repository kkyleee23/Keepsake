import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/core/config/app_config.dart';
import 'package:keepsake/data/remote/update_check.dart';

Map<String, dynamic> body({
  Object? versionCode = 5,
  Object? minVersionCode = 1,
  Object? versionName = '1.0.4',
  Object? note = 'A newer Keepsake is ready.',
  Object? url,
}) => {
  'versionCode': versionCode,
  'minVersionCode': minVersionCode,
  'versionName': versionName,
  'note': note,
  'url': url ?? AppConfig.downloadUrl,
};

void main() {
  group('which build is out', () {
    test('says nothing when this is already the newest', () {
      expect(readUpdate(body(), installed: 5).urgency, UpdateUrgency.none);
      expect(readUpdate(body(), installed: 9).urgency, UpdateUrgency.none);
    });

    test('mentions a newer one', () {
      final u = readUpdate(body(), installed: 4);
      expect(u.urgency, UpdateUrgency.optional);
      expect(u.mustUpdate, isFalse);
      expect(u.versionName, '1.0.4');
    });

    test('insists when the build is below the lowest allowed', () {
      final u = readUpdate(body(minVersionCode: 4), installed: 3);
      expect(u.urgency, UpdateUrgency.required_);
      expect(u.mustUpdate, isTrue);
    });

    test('a lowest allowed that is met is only a suggestion', () {
      final u = readUpdate(body(minVersionCode: 4), installed: 4);
      expect(u.urgency, UpdateUrgency.optional);
    });
  });

  group('read leniently, because this comes off the network', () {
    test('rubbish is ignored', () {
      for (final junk in <Object?>[null, 'nope', 42, [], {}]) {
        expect(readUpdate(junk, installed: 1).urgency, UpdateUrgency.none);
      }
    });

    test('a missing or unreadable version says nothing', () {
      expect(
        readUpdate(body(versionCode: null), installed: 1).urgency,
        UpdateUrgency.none,
      );
      expect(
        readUpdate(body(versionCode: 'soon'), installed: 1).urgency,
        UpdateUrgency.none,
      );
    });

    test('a version sent as text still counts', () {
      expect(
        readUpdate(body(versionCode: '7'), installed: 1).urgency,
        UpdateUrgency.optional,
      );
    });

    test('long text is cut, and newlines are flattened', () {
      final u = readUpdate(
        body(note: 'x' * 500, versionName: 'y' * 100),
        installed: 1,
      );
      expect(u.note.length, lessThanOrEqualTo(160));
      expect(u.versionName.length, lessThanOrEqualTo(24));

      final tidy = readUpdate(body(note: 'one\n\n  two'), installed: 1);
      expect(tidy.note, 'one two');
    });

    test('text where a number belongs does not throw', () {
      expect(
        () => readUpdate(body(minVersionCode: 'all of them'), installed: 1),
        returnsNormally,
      );
    });
  });

  group('the address it sends people to', () {
    test('an address on another site is refused', () {
      for (final bad in [
        'https://example.com/get',
        'http://keepsake-ph.vercel.app.evil.test/x',
        'javascript:alert(1)',
        '//evil.test',
      ]) {
        final u = readUpdate(body(url: bad), installed: 1);
        expect(
          u.url,
          AppConfig.downloadUrl,
          reason: '$bad should not have been used',
        );
      }
    });

    test('an address on our own site is kept', () {
      final mine = '${AppConfig.siteOrigin}/download?from=app';
      expect(readUpdate(body(url: mine), installed: 1).url, mine);
    });

    test('a missing address falls back to the download page', () {
      expect(
        readUpdate(body(url: ''), installed: 1).url,
        AppConfig.downloadUrl,
      );
    });
  });

  group('one APK per kind of phone', () {
    test('the release number is taken out of the built-up code', () {
      // Flutter builds the same release as 3, and as 1003 / 2003 / 4003 for
      // armeabi-v7a, arm64-v8a and x86_64.
      expect(releaseNumberOf(3), 3);
      expect(releaseNumberOf(1003), 3);
      expect(releaseNumberOf(2003), 3);
      expect(releaseNumberOf(4003), 3);
      expect(releaseNumberOf(0), 0);
      expect(releaseNumberOf(999), 999);
    });

    test('a per-phone build is still told about a newer release', () {
      // Before this was handled, 2003 looked newer than 4 and the person was
      // told they were up to date for good.
      final u = readUpdate(
        body(versionCode: 4),
        installed: releaseNumberOf(2003),
      );
      expect(u.urgency, UpdateUrgency.optional);
    });

    test('a per-phone build can still be made to update', () {
      final u = readUpdate(
        body(versionCode: 9, minVersionCode: 9),
        installed: releaseNumberOf(4003),
      );
      expect(u.mustUpdate, isTrue);
    });
  });

  test('the site address has no path on it', () {
    expect(AppConfig.siteOrigin, isNot(endsWith('/app')));
    expect(AppConfig.downloadUrl, endsWith('/download'));
  });
}
