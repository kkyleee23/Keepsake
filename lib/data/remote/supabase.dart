import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

/// The Supabase client, or null when it isn't configured or not yet
/// initialized. Keeps the app (and tests) from throwing when Supabase is
/// unavailable instead of assuming `Supabase.instance` always works.
SupabaseClient? get supabaseClientOrNull {
  if (!AppConfig.isSupabaseConfigured) return null;
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}
