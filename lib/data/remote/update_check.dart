import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_config.dart';

/// How much to say about a newer build.
enum UpdateUrgency {
  /// Nothing to say: this is the build on the site, or we could not tell.
  none,

  /// A newer one is out. Worth mentioning once, easy to put off.
  optional,

  /// This build is too old to keep using, so say so and don't take no.
  required_,
}

/// What the site says the newest build is.
class UpdateInfo {
  const UpdateInfo({
    required this.urgency,
    this.versionName = '',
    this.note = '',
    this.url = '',
  });

  static const none = UpdateInfo(urgency: UpdateUrgency.none);

  final UpdateUrgency urgency;

  /// Shown to the person, so it is kept short and cleaned of anything odd.
  final String versionName;
  final String note;

  /// Where to send them. Always on this project's own site.
  final String url;

  bool get show => urgency != UpdateUrgency.none;
  bool get mustUpdate => urgency == UpdateUrgency.required_;
}

/// Reads whatever the site returned, leniently: anything missing, the wrong
/// type or too long is dropped rather than trusted, and the address has to
/// be on our own site before it is used.
UpdateInfo readUpdate(Object? body, {required int installed}) {
  if (body is! Map) return UpdateInfo.none;

  int asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String asText(Object? v, int limit) {
    if (v is! String) return '';
    final clean = v.trim().replaceAll(RegExp(r'\s+'), ' ');
    return clean.length <= limit ? clean : clean.substring(0, limit);
  }

  final newest = asInt(body['versionCode']);
  final lowest = asInt(body['minVersionCode']);
  if (newest <= 0) return UpdateInfo.none;

  // A link from the network only gets used when it is on our own site.
  final fallback = AppConfig.downloadUrl;
  final given = asText(body['url'], 300);
  final url = (given.isNotEmpty && given.startsWith(AppConfig.siteOrigin))
      ? given
      : fallback;

  final urgency = installed < lowest
      ? UpdateUrgency.required_
      : (installed < newest ? UpdateUrgency.optional : UpdateUrgency.none);
  if (urgency == UpdateUrgency.none) return UpdateInfo.none;

  return UpdateInfo(
    urgency: urgency,
    versionName: asText(body['versionName'], 24),
    note: asText(body['note'], 160),
    url: url,
  );
}

/// Asks the site which build is out. Only the installed Android app needs
/// this: the web version is always whatever was last put online, and there
/// is no iOS build yet. Any problem means we say nothing at all, so a slow
/// or missing answer never gets in the way of opening a keepsake.
Future<UpdateInfo> checkForUpdate({http.Client? client}) async {
  if (kIsWeb) return UpdateInfo.none;
  if (!Platform.isAndroid) return UpdateInfo.none;

  final web = client ?? http.Client();
  try {
    final info = await PackageInfo.fromPlatform();
    final installed = int.tryParse(info.buildNumber) ?? 0;
    if (installed <= 0) return UpdateInfo.none;

    final res = await web
        .get(Uri.parse('${AppConfig.siteOrigin}/latest.json'))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return UpdateInfo.none;
    if (res.bodyBytes.length > 4096) return UpdateInfo.none;

    return readUpdate(jsonDecode(res.body), installed: installed);
  } catch (_) {
    // Offline, slow, or the file was not there. Say nothing.
    return UpdateInfo.none;
  } finally {
    if (client == null) web.close();
  }
}

/// Checked once when the app starts. Never throws.
final updateInfoProvider = FutureProvider<UpdateInfo>((ref) async {
  return checkForUpdate();
});
