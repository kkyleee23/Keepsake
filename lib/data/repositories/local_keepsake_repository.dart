import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/keepsake.dart';
import 'keepsake_repository.dart';

/// Local-first [KeepsakeRepository] backed by [SharedPreferences].
///
/// Everything is stored as one JSON array under [_key]. This is enough to keep
/// drafts safe across launches (so an unfinished Keepsake is never lost) and is
/// a clean seam for a networked repository later.
class LocalKeepsakeRepository implements KeepsakeRepository {
  LocalKeepsakeRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'keepsake.items.v1';

  List<Keepsake> _readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => Keepsake.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _writeAll(List<Keepsake> items) async {
    final raw = jsonEncode(items.map((k) => k.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  @override
  Future<List<Keepsake>> getAll() async {
    final items = _readAll()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<Keepsake?> getById(String id) async {
    for (final k in _readAll()) {
      if (k.id == id) return k;
    }
    return null;
  }

  @override
  Future<void> save(Keepsake keepsake) async {
    final items = _readAll();
    final index = items.indexWhere((k) => k.id == keepsake.id);
    if (index >= 0) {
      items[index] = keepsake;
    } else {
      items.add(keepsake);
    }
    await _writeAll(items);
  }

  @override
  Future<void> delete(String id) async {
    final items = _readAll()..removeWhere((k) => k.id == id);
    await _writeAll(items);
  }
}
