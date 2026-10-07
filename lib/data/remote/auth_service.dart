import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';

/// Outcome of a sign-up attempt.
class SignUpResult {
  const SignUpResult({
    required this.ok,
    this.needsConfirmation = false,
    this.error,
  });

  final bool ok;

  /// True when the account was created but the email must be confirmed before
  /// a session exists (depends on the project's "Confirm email" setting).
  final bool needsConfirmation;
  final String? error;
}

/// Wraps Supabase email/password auth for creators. Recipients never sign in;
/// they open keepsakes through share links, handled separately.
class AuthService {
  bool get isAvailable => supabaseClientOrNull != null;

  User? get currentUser => supabaseClientOrNull?.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  String? get displayName {
    final meta = currentUser?.userMetadata;
    final name = meta?['display_name'] as String?;
    return (name != null && name.isNotEmpty) ? name : null;
  }

  String? get email => currentUser?.email;

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final client = supabaseClientOrNull;
    if (client == null) {
      return const SignUpResult(ok: false, error: 'Sign-in is not set up yet.');
    }
    try {
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: (displayName != null && displayName.trim().isNotEmpty)
            ? {'display_name': displayName.trim()}
            : null,
      );
      return SignUpResult(ok: true, needsConfirmation: res.session == null);
    } on AuthException catch (e) {
      return SignUpResult(ok: false, error: e.message);
    } catch (_) {
      return const SignUpResult(ok: false, error: 'Something went wrong.');
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final client = supabaseClientOrNull;
    if (client == null) return 'Sign-in is not set up yet.';
    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong.';
    }
  }

  Future<void> signOut() async {
    await supabaseClientOrNull?.auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
