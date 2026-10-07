/// Build-time configuration.
///
/// Supabase credentials are supplied with --dart-define (or
/// --dart-define-from-file) so they never live in source control. The anon key
/// is a public client key (protected by Row-Level Security), but keeping it out
/// of the repo keeps the rule "no hardcoded backend credentials" honest.
///
/// Example:
///   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ... \
///               --dart-define=KEEPSAKE_LINK_BASE=https://your.app
abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Base used to build a shareable link: `<base>/receive/<token>`.
  static const String shareLinkBase = String.fromEnvironment(
    'KEEPSAKE_LINK_BASE',
    defaultValue: 'https://keepsake.app',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String shareUrl(String token) => '$shareLinkBase/receive/$token';
}
