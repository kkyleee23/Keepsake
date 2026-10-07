import 'dart:convert';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../models/enums.dart';
import '../models/keepsake.dart';

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
}

/// Result of attempting to open the content.
class OpenResult {
  const OpenResult({required this.status, this.keepsake, this.opensAt});

  /// One of: ok, sealed, expired, pin_required, wrong_pin, not_found, error.
  final String status;
  final Keepsake? keepsake;
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

    // Strip any PIN from the uploaded payload; it lives only as a server hash.
    final payload = keepsake
        .copyWith(
          creatorId: _client.auth.currentUser?.id,
          status: KeepsakeStatus.published,
          shareToken: token,
          publishedAt: keepsake.publishedAt ?? DateTime.now(),
        )
        .toJson();
    (payload['privacy'] as Map)['pin'] = null;

    final res = await _client.rpc('publish_keepsake', params: {
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
    });

    final map = Map<String, dynamic>.from(res as Map);
    final status = map['status'] as String?;
    if (status != 'ok') {
      throw StateError('Could not publish (${status ?? 'unknown'}).');
    }
    return token;
  }

  /// Removes a published keepsake (RLS limits this to the creator's own rows).
  Future<void> revoke(String token) async {
    if (!isAvailable || _client.auth.currentUser == null) return;
    await _client.from('keepsakes').delete().eq('share_token', token);
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
      return OpenResult(status: status, opensAt: _parseDate(m['opens_at']));
    } catch (_) {
      return const OpenResult(status: 'error');
    }
  }

  static DateTime? _parseDate(Object? v) =>
      (v is String && v.isNotEmpty) ? DateTime.tryParse(v)?.toLocal() : null;
}
