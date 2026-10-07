import '../models/keepsake.dart';

/// Storage boundary for Keepsakes.
///
/// The app talks only to this interface, so the current local-first
/// implementation can be swapped for (or layered with) a backend later without
/// touching the UI or controllers.
abstract interface class KeepsakeRepository {
  /// All Keepsakes known to this device, newest activity first.
  Future<List<Keepsake>> getAll();

  Future<Keepsake?> getById(String id);

  /// Insert or update [keepsake].
  Future<void> save(Keepsake keepsake);

  Future<void> delete(String id);
}
