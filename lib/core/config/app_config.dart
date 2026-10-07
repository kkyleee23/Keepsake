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
  // Defaults are this project's PUBLIC client values (Supabase publishable key +
  // URL), so the app is configured no matter how it's launched. A --dart-define
  // of the same name overrides them per environment. The secret key is never
  // here.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vrmvvtsosvljnwspausm.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_MSPIPEsBY7Ka3WEDAsMB_Q_8vkJ0oSo',
  );

  /// Base used to build a shareable link: `<base>/receive/<token>`.
  static const String shareLinkBase = String.fromEnvironment(
    'KEEPSAKE_LINK_BASE',
    defaultValue: 'https://keepsake.app',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String shareUrl(String token) => '$shareLinkBase/receive/$token';
}
