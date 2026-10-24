import 'dart:async';
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
    this.sentOn,
    this.receipts = false,
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

  /// The day it was first sent, for the postmark (needs migration 0007).
  final DateTime? sentOn;

  /// Whether the sender will see that it was opened.
  final bool receipts;
}

/// What the creator can see about one of their links.
class LinkStatus {
  const LinkStatus({
    required this.receipts,
    this.firstOpenedAt,
    this.lastOpenedAt,
    this.openCount = 0,
    this.replyCount = 0,
  });

  final bool receipts;
  final DateTime? firstOpenedAt;
  final DateTime? lastOpenedAt;
  final int openCount;
  final int replyCount;

  bool get opened => firstOpenedAt != null;
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
  /// Nothing waits forever. On a poor connection the call is given up on so
  /// the screen can say something, instead of sitting there with a spinner.
  static const Duration _wait = Duration(seconds: 15);

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

    final payload = uploadPayload(
      keepsake,
      token: token,
      creatorId: _client.auth.currentUser?.id,
    );

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
    // Newest first. When the database is older than the app (a migration
    // not run yet), fall back to what it understands rather than failing:
    // receipts need 0007, the wrapping needs 0005.
    final attempts = [
      {
        ...params,
        'p_style': keepsake.style.toJson(),
        'p_receipts': keepsake.privacy.receipts,
      },
      {...params, 'p_style': keepsake.style.toJson()},
      params,
    ];
    dynamic res;
    for (var i = 0; i < attempts.length; i++) {
      try {
        res = await _client
            .rpc('publish_keepsake', params: attempts[i])
            .timeout(_wait);
        break;
      } on PostgrestException catch (e) {
        final missing = e.code == 'PGRST202' || e.code == '42883';
        if (!missing || i == attempts.length - 1) rethrow;
      } on TimeoutException {
        throw StateError(
          'That took too long to send. Check your connection and try again.',
        );
      }
    }

    final map = Map<String, dynamic>.from(res as Map);
    final status = map['status'] as String?;
    if (status == 'too_large') {
      throw StateError(
        'This keepsake is too large to send. Try removing a photo or two.',
      );
    }
    if (status == 'unauthenticated') {
      throw StateError('Please sign in again, then publish.');
    }
    if (status == 'invalid_pin') {
      throw StateError('A PIN is 4 to 12 digits, numbers only.');
    }
    if (status == 'rate_limited') {
      throw StateError(
        'You’ve shared a lot in a short time. Try again in a few minutes.',
      );
    }
    if (status == 'quota') {
      throw StateError(
        'You’ve used all the space for shared keepsakes. '
        'Stop sharing an old one to make room.',
      );
    }
    if (status == 'invalid') {
      throw StateError(
        'Something in this keepsake is too long. Try a shorter title or note.',
      );
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
      final res = await _client
          .rpc('stop_sharing', params: {'p_token': token})
          .timeout(_wait);
      final status = Map<String, dynamic>.from(res as Map)['status'];
      // not_found: already gone, which is what was asked for.
      if (status == 'ok' || status == 'not_found') return;
      throw StateError('Something went wrong on our side. Try again.');
    } on PostgrestException catch (e) {
      // PGRST202: the function doesn't exist yet (0006 not run).
      if (e.code != 'PGRST202' && e.code != '42883') rethrow;
      await revoke(token);
    } on TimeoutException {
      throw StateError(
        'That took too long. Check your connection and try again.',
      );
    }
  }

  /// Removes a published keepsake (RLS limits this to the creator's own rows).
  Future<void> revoke(String token) async {
    if (!isAvailable || _client.auth.currentUser == null) return;
    await _client
        .from('keepsakes')
        .delete()
        .eq('share_token', token)
        .timeout(_wait);
  }

  /// Deletes every published keepsake owned by the signed-in creator.
  Future<void> deleteAllMine() async {
    final uid = _client.auth.currentUser?.id;
    if (!isAvailable || uid == null) return;
    await _client
        .from('keepsakes')
        .delete()
        .eq('creator_id', uid)
        .timeout(_wait);
  }

  Future<CoverResult> fetchCover(String token) async {
    if (!isAvailable) return const CoverResult(status: 'error');
    try {
      final res = await _client
          .rpc('keepsake_cover', params: {'p_token': token})
          .timeout(_wait);
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
        sentOn: m['sent_on'] is String
            ? DateTime.tryParse(m['sent_on'] as String)
            : null,
        receipts: m['receipts'] == true,
      );
    } catch (_) {
      return const CoverResult(status: 'error');
    }
  }

  Future<OpenResult> open(String token, {String? pin}) async {
    if (!isAvailable) return const OpenResult(status: 'error');
    try {
      final res = await _client
          .rpc('keepsake_open', params: {'p_token': token, 'p_pin': pin})
          .timeout(_wait);
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
      final res = await _client
          .rpc(
            'respond_to_keepsake',
            params: {
              'p_token': token,
              'p_pin': pin,
              'p_reaction': reaction?.id,
              'p_message': message,
              'p_name': name,
            },
          )
          .timeout(_wait);
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
          .rpc('my_keepsake_responses', params: {'p_token': token})
          .timeout(_wait);
      return [
        for (final row in res as List)
          KeepsakeResponse.fromJson(Map<String, dynamic>.from(row as Map)),
      ];
    } catch (_) {
      return null;
    }
  }

  /// Opened receipts and reply counts for the signed-in creator's links.
  /// Null when they can't be loaded (offline, or migration 0007 not run).
  Future<Map<String, LinkStatus>?> fetchStatus(List<String> tokens) async {
    if (!isAvailable || tokens.isEmpty) return null;
    if (_client.auth.currentUser == null) return null;
    try {
      final res = await _client
          .rpc(
            'my_keepsake_status',
            params: {'p_tokens': tokens.take(200).toList()},
          )
          .timeout(_wait);
      return {
        for (final row in res as List)
          if (row is Map && row['share_token'] is String)
            row['share_token'] as String: LinkStatus(
              receipts: row['receipts'] == true,
              firstOpenedAt: _parseDate(row['first_opened_at']),
              lastOpenedAt: _parseDate(row['last_opened_at']),
              openCount: (row['open_count'] as num?)?.toInt() ?? 0,
              replyCount: (row['reply_count'] as num?)?.toInt() ?? 0,
            ),
      };
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDate(Object? v) =>
      (v is String && v.isNotEmpty) ? DateTime.tryParse(v)?.toLocal() : null;
}
