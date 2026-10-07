import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/keepsake.dart';
import '../../../data/providers.dart';

/// Loads and mutates the list of Keepsakes, persisting through the repository.
///
/// A single source of truth for Home, the library, and the editor's autosave.
class KeepsakesController extends AsyncNotifier<List<Keepsake>> {
  @override
  Future<List<Keepsake>> build() =>
      ref.read(keepsakeRepositoryProvider).getAll();

  Future<void> upsert(Keepsake keepsake) async {
    await ref.read(keepsakeRepositoryProvider).save(keepsake);
    state = AsyncData(await ref.read(keepsakeRepositoryProvider).getAll());
  }

  Future<void> remove(String id) async {
    await ref.read(keepsakeRepositoryProvider).delete(id);
    state = AsyncData(await ref.read(keepsakeRepositoryProvider).getAll());
  }

  Future<void> archive(Keepsake k) =>
      upsert(k.copyWith(status: KeepsakeStatus.archived, updatedAt: DateTime.now()));

  Future<void> unarchive(Keepsake k) => upsert(k.copyWith(
        status: k.shareToken != null
            ? KeepsakeStatus.published
            : KeepsakeStatus.draft,
        updatedAt: DateTime.now(),
      ));

  /// Deletes a keepsake. If it's one you published, it's revoked on the server
  /// too so the link stops working.
  Future<void> deleteKeepsake(Keepsake k) async {
    if (k.shareToken != null && !k.isReceived) {
      await ref.read(keepsakeBackendProvider).revoke(k.shareToken!);
    }
    await remove(k.id);
  }

  /// Saves a copy of a keepsake opened as a recipient, so it lives in the
  /// library under "Received".
  Future<void> saveReceived(Keepsake k) async {
    final existing = await ref.read(keepsakeRepositoryProvider).getById(k.id);
    await upsert(k.copyWith(
      receivedAt: existing?.receivedAt ?? DateTime.now(),
    ));
  }
}

final keepsakesControllerProvider =
    AsyncNotifierProvider<KeepsakesController, List<Keepsake>>(
  KeepsakesController.new,
);

/// Drafts only - powers "Continue where you left off".
final draftsProvider = Provider<List<Keepsake>>((ref) {
  final all = ref.watch(keepsakesControllerProvider).valueOrNull ?? const [];
  return all.where((k) => k.status == KeepsakeStatus.draft).toList();
});

/// Everything that isn't archived, for "Recently created" / the library.
final recentKeepsakesProvider = Provider<List<Keepsake>>((ref) {
  final all = ref.watch(keepsakesControllerProvider).valueOrNull ?? const [];
  return all.where((k) => k.status != KeepsakeStatus.archived).toList();
});
