import 'dart:convert';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../models/enums.dart';
import '../models/keepsake.dart';
import '../models/keepsake_response.dart';

/// Result of asking the server what a recipient may see before opening.
class CoverResult {
  const CoverResult({
    required this.status,
    this.opensAt,
    this.requiresPin = false,
    this.occasion,
    this.title,
    this.recipientName,
    this.senderName,
    this.coverNote,
    this.style = KeepsakeStyle.standard,
  });

  /// One of: available, sealed, expired, not_found, error.
  final String status;
  final DateTime? opensAt;
  final bool requiresPin;
  final String? occasion;
  final String? title;
  final String? recipientName;
  final String? senderName;
  final String? coverNote;

  /// Envelope paper and seal colour, shown before opening.
  final KeepsakeStyle style;
}

/// Result of attempting to open the content.
class OpenResult {
  const OpenResult({required this.status, this.keepsake, this.opensAt});

  /// One of: ok, sealed, expired, pin_required, wrong_pin, locked,
  /// not_found, error.
  final String status;
  final Keepsake? keepsake;

  /// When sealed: when it opens. When locked: when PIN tries are allowed again.
  final DateTime? opensAt;
}

/// Talks to Supabase for the parts that must leave the device: publishing a
/// keepsake and letting a recipient open one. Drafts never come here.
///
/// Every method degrades gracefully when Supabase isn't configured so the app
/// still runs locally.
class KeepsakeBackend {
  bool get isAvailable => AppConfig.isSupabaseConfigured;

  SupabaseClient get _client => Supabase.instance.client;

  static String _newToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// What goes to the server for [keepsake]: everything the recipient needs
  /// and nothing else. The PIN never leaves the phone in the payload (it's
  /// sent once, separately, and stored only as a hash), and earlier links
  /// stay private.
  static Map<String, dynamic> uploadPayload(
    Keepsake keepsake, {
    required String token,
    String? creatorId,
  }) {
    final payload = keepsake
        .copyWith(
          creatorId: creatorId,
          status: KeepsakeStatus.published,
          shareToken: token,
          publishedAt: keepsake.publishedAt ?? DateTime.now(),
        )
        .toJson();
    payload['privacy'] = {...payload['privacy'] as Map, 'pin': null};
    payload.remove('pastTokens');
    payload.remove('recipientContact');
    return payload;
  }

  /// Publishes [keepsake]. Returns the share token. [pin] (if any) is sent once
  /// and hashed on the server - it is never stored on the device.
  Future<String> publish(Keepsake keepsake, {String? pin}) async {
    if (!isAvailable) {
      throw StateError('Sharing is not set up yet.');
    }
    // Creators are signed in before reaching here; the server also rejects an
    // unauthenticated publish.
    if (_client.auth.currentUser == null) {
      throw StateError('Please sign in to publish.');
    }

    final token = keepsake.shareToken ?? _newToken();

    final payload = uploadPayload(keepsake,
        token: token, creatorId: _client.auth.currentUser?.id);

    final params = <String, dynamic>{
      'p_token': token,
      'p_payload': payload,
      'p_occasion': keepsake.occasion.id,
      'p_title': keepsake.title,
      'p_recipient_name': keepsake.recipientName,
      'p_sender_name': keepsake.senderName,
      'p_cover_note': keepsake.coverNote,
      'p_delivery_mode': keepsake.delivery.mode.id,
      'p_open_at': keepsake.delivery.openAt?.toUtc().toIso8601String(),
      'p_expires_at': keepsake.privacy.expiresAt?.toUtc().toIso8601String(),
      'p_unlisted': keepsake.privacy.unlisted,
      'p_pin': (pin != null && pin.isNotEmpty) ? pin : null,
    };
    dynamic res;
    try {
      res = await _client.rpc('publish_keepsake',
          params: {...params, 'p_style': keepsake.style.toJson()});
    } on PostgrestException {
      // The wrapping needs migration 0005. Without it, publish anyway with
      // the standard look rather than failing.
      res = await _client.rpc('publish_keepsake', params: params);
    }

    final map = Map<String, dynamic>.from(res as Map);
    final status = map['status'] as String?;
    if (status == 'too_large') {
      throw StateError(
          'This keepsake is too large to send. Try removing a photo or two.');
    }
    if (status == 'unauthenticated') {
      throw StateError('Please sign in again, then publish.');
    }
    if (status == 'invalid_pin') {
      throw StateError('A PIN is 4 to 12 digits, numbers only.');
    }
    if (status == 'invalid') {
      throw StateError(
          'Something in this keepsake is too long. Try a shorter title or note.');
    }
    if (status != 'ok') {
      throw StateError('Something went wrong on our side. Try again.');
    }
    return token;
  }

  /// Turns a link off: it stops working right away and the server deletes
  /// the content, keeping only the replies already sent. A stopped link is
  /// never used again (migration 0006). Before 0006 is run, the keepsake is
  /// removed from the server instead, which also stops the link.
  Future<void> stopSharing(String token) async {
    if (!isAvailable) throw StateError('Sharing is not set up yet.');
    if (_client.auth.currentUser == null) {
      throw StateError('Please sign in again, then try that.');
    }
    try {
      final res =
          await _client.rpc('stop_sharing', params: {'p_token': token});
      final status = Map<String, dynamic>.from(res as Map)['status'];
      // not_found: already gone, which is what was asked for.
      if (status == 'ok' || status == 'not_found') return;
      throw StateError('Something went wrong on our side. Try again.');
    } on PostgrestException catch (e) {
      // PGRST202: the function doesn't exist yet (0006 not run).
      if (e.code != 'PGRST202' && e.code != '42883') rethrow;
      await revoke(token);
    }
  }

  /// Removes a published keepsake (RLS limits this to the creator's own rows).
  Future<void> revoke(String token) async {
    if (!isAvailable || _client.auth.currentUser == null) return;
    await _client.from('keepsakes').delete().eq('share_token', token);
  }

  /// Deletes every published keepsake owned by the signed-in creator.
  Future<void> deleteAllMine() async {
    final uid = _client.auth.currentUser?.id;
    if (!isAvailable || uid == null) return;
    await _client.from('keepsakes').delete().eq('creator_id', uid);
  }

  Future<CoverResult> fetchCover(String token) async {
    if (!isAvailable) return const CoverResult(status: 'error');
    try {
      final res = await _client.rpc('keepsake_cover', params: {'p_token': token});
      final m = Map<String, dynamic>.from(res as Map);
      return CoverResult(
        status: m['status'] as String? ?? 'error',
        opensAt: _parseDate(m['opens_at']),
        requiresPin: m['requires_pin'] as bool? ?? false,
        occasion: m['occasion'] as String?,
        title: m['title'] as String?,
        recipientName: m['recipient_name'] as String?,
        senderName: m['sender_name'] as String?,
        coverNote: m['cover_note'] as String?,
        style: KeepsakeStyle.fromJson(m['style']),
      );
    } catch (_) {
      return const CoverResult(status: 'error');
    }
  }

  Future<OpenResult> open(String token, {String? pin}) async {
    if (!isAvailable) return const OpenResult(status: 'error');
    try {
      final res = await _client
          .rpc('keepsake_open', params: {'p_token': token, 'p_pin': pin});
      final m = Map<String, dynamic>.from(res as Map);
      final status = m['status'] as String? ?? 'error';
      if (status == 'ok') {
        final payload = Map<String, dynamic>.from(m['payload'] as Map);
        return OpenResult(status: status, keepsake: Keepsake.fromJson(payload));
      }
      return OpenResult(
        status: status,
        opensAt: _parseDate(m['opens_at'] ?? m['retry_at']),
      );
    } catch (_) {
      return const OpenResult(status: 'error');
    }
  }

  /// Sends a recipient's reply. Returns the server status: ok, empty,
  /// rate_limited, too_long, wrong_pin, sealed, expired, not_found, or error.
  Future<String> respond(
    String token, {
    String? pin,
    Reaction? reaction,
    String? message,
    String? name,
  }) async {
    if (!isAvailable) return 'error';
    try {
      final res = await _client.rpc('respond_to_keepsake', params: {
        'p_token': token,
        'p_pin': pin,
        'p_reaction': reaction?.id,
        'p_message': message,
        'p_name': name,
      });
      return Map<String, dynamic>.from(res as Map)['status'] as String? ??
          'error';
    } catch (_) {
      return 'error';
    }
  }

  /// Replies to one of the signed-in creator's keepsakes, newest first.
  /// Returns null when they can't be loaded (offline, or not set up yet).
  Future<List<KeepsakeResponse>?> fetchResponses(String token) async {
    if (!isAvailable || _client.auth.currentUser == null) return null;
    try {
      final res = await _client
          .rpc('my_keepsake_responses', params: {'p_token': token});
      return [
        for (final row in res as List)
          KeepsakeResponse.fromJson(Map<String, dynamic>.from(row as Map)),
      ];
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDate(Object? v) =>
      (v is String && v.isNotEmpty) ? DateTime.tryParse(v)?.toLocal() : null;
}
