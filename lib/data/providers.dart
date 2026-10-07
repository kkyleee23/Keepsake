import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'remote/keepsake_backend.dart';
import 'repositories/keepsake_repository.dart';
import 'repositories/local_keepsake_repository.dart';

/// Provides the initialized [SharedPreferences] instance.
///
/// Overridden in `main()` with the real instance so the rest of the app can
/// read it synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// The app's single Keepsake storage boundary (local-first for now).
final keepsakeRepositoryProvider = Provider<KeepsakeRepository>(
  (ref) => LocalKeepsakeRepository(ref.watch(sharedPreferencesProvider)),
);

/// Backend for the parts that must leave the device (publish + recipient open).
final keepsakeBackendProvider =
    Provider<KeepsakeBackend>((ref) => KeepsakeBackend());

