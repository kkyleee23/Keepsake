import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Supabase is optional: without credentials the app still runs locally,
  // with publishing disabled.
  if (AppConfig.isSupabaseConfigured) {
    try {
      final key = AppConfig.supabaseAnonKey;
      // Supabase's newer "publishable" keys start with sb_; the classic anon
      // key is a JWT. Pass whichever was supplied to the right parameter.
      final isPublishable = key.startsWith('sb_');
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: isPublishable ? key : null,
        // ignore: deprecated_member_use
        anonKey: isPublishable ? null : key,
      );
    } catch (_) {
      // Leave publishing disabled rather than blocking startup.
    }
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const KeepsakeApp(),
    ),
  );
}
