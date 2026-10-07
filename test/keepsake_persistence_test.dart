import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/data/models/enums.dart';
import 'package:keepsake/data/models/keepsake.dart';
import 'package:keepsake/data/repositories/local_keepsake_repository.dart';
import 'package:keepsake/features/creation/keepsake_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Keepsake model', () {
    test('factory creates a titled draft for an occasion', () {
      final draft = KeepsakeFactory.newDraft(occasion: Occasion.birthday);
      expect(draft.status, KeepsakeStatus.draft);
      expect(draft.occasion, Occasion.birthday);
      expect(draft.title, 'Birthday');
      expect(draft.sections, isEmpty);
    });

    test('survives a JSON round-trip with sections and sender', () {
      final section = KeepsakeFactory.newSection(SectionType.letter, 0).copyWith(
        content: {'title': 'Hi', 'body': 'Happy birthday.'},
      );
      final original = KeepsakeFactory.newDraft(occasion: Occasion.friendship)
          .copyWith(
        recipientName: 'Jamie',
        senderName: 'Kyle',
        coverNote: 'For you.',
        sections: [section],
      );

      final restored = Keepsake.fromJson(original.toJson());

      expect(restored.recipientName, 'Jamie');
      expect(restored.senderName, 'Kyle');
      expect(restored.coverNote, 'For you.');
      expect(restored.sections.single.type, SectionType.letter);
      expect(restored.sections.single.content['body'], 'Happy birthday.');
    });
  });

  group('LocalKeepsakeRepository', () {
    late LocalKeepsakeRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = LocalKeepsakeRepository(await SharedPreferences.getInstance());
    });

    test('save then getById returns the keepsake', () async {
      final draft = KeepsakeFactory.newDraft(occasion: Occasion.love);
      await repo.save(draft);
      expect((await repo.getById(draft.id))?.id, draft.id);
    });

    test('save upserts instead of duplicating', () async {
      final draft = KeepsakeFactory.newDraft(occasion: Occasion.love);
      await repo.save(draft);
      await repo.save(draft.copyWith(title: 'Renamed'));
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.single.title, 'Renamed');
    });

    test('getAll sorts by most recent activity', () async {
      final older = KeepsakeFactory.newDraft(occasion: Occasion.family)
          .copyWith(updatedAt: DateTime(2025, 1, 1));
      final newer = KeepsakeFactory.newDraft(occasion: Occasion.graduation)
          .copyWith(updatedAt: DateTime(2026, 1, 1));
      await repo.save(older);
      await repo.save(newer);
      final all = await repo.getAll();
      expect(all.first.id, newer.id);
    });

    test('delete removes the keepsake', () async {
      final draft = KeepsakeFactory.newDraft(occasion: Occasion.thankYou);
      await repo.save(draft);
      await repo.delete(draft.id);
      expect(await repo.getById(draft.id), isNull);
    });
  });
}
