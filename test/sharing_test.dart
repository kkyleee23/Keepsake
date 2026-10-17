import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/data/models/enums.dart';
import 'package:keepsake/data/models/keepsake.dart';
import 'package:keepsake/data/remote/keepsake_backend.dart';

final _now = DateTime(2026, 10, 17);

Keepsake _published() => Keepsake(
      id: 'k1',
      title: 'For Mia',
      occasion: Occasion.birthday,
      recipientName: 'Mia',
      recipientContact: 'mia@example.com',
      status: KeepsakeStatus.published,
      shareToken: 'tokenNEW000000000000',
      pastTokens: const ['tokenOLD000000000000'],
      privacy: const PrivacySettings(pin: '4821'),
      createdAt: _now,
      updatedAt: _now,
      publishedAt: _now,
    );

void main() {
  group('Stop sharing', () {
    test('turns the keepsake back into a draft and remembers the link', () {
      final draft = _published().unshared();
      expect(draft.status, KeepsakeStatus.draft);
      expect(draft.shareToken, isNull);
      expect(draft.publishedAt, isNull);
      expect(draft.isPublished, isFalse);
      expect(draft.pastTokens,
          ['tokenNEW000000000000', 'tokenOLD000000000000']);
      // Everything the person made is still there.
      expect(draft.title, 'For Mia');
      expect(draft.privacy.pin, '4821');
    });

    test('old links survive saving and loading', () {
      final draft = _published().unshared();
      final back = Keepsake.fromJson(draft.toJson());
      expect(back.pastTokens, draft.pastTokens);
      expect(back.allTokens, draft.pastTokens);
    });

    test('a bad pastTokens value is ignored, not a crash', () {
      final json = _published().toJson()..['pastTokens'] = ['ok', 3, null];
      expect(Keepsake.fromJson(json).pastTokens, ['ok']);
      final json2 = _published().toJson()..remove('pastTokens');
      expect(Keepsake.fromJson(json2).pastTokens, isEmpty);
    });
  });

  group('What gets uploaded', () {
    test('never the PIN, old links or the recipient contact', () {
      final p = KeepsakeBackend.uploadPayload(_published(),
          token: 'tokenNEW000000000000', creatorId: 'u1');
      expect((p['privacy'] as Map)['pin'], isNull);
      expect(p.containsKey('pastTokens'), isFalse);
      expect(p.containsKey('recipientContact'), isFalse);
      expect(p.toString(), isNot(contains('4821')));
      expect(p.toString(), isNot(contains('tokenOLD')));
      expect(p.toString(), isNot(contains('mia@example.com')));
    });

    test('still has what the recipient needs', () {
      final p = KeepsakeBackend.uploadPayload(_published(),
          token: 'tokenNEW000000000000');
      final k = Keepsake.fromJson(p);
      expect(k.title, 'For Mia');
      expect(k.recipientName, 'Mia');
      expect(k.shareToken, 'tokenNEW000000000000');
      expect(k.status, KeepsakeStatus.published);
    });

    test('does not touch the local copy', () {
      final k = _published();
      KeepsakeBackend.uploadPayload(k, token: 'tokenNEW000000000000');
      expect(k.privacy.pin, '4821');
      expect(k.pastTokens, isNotEmpty);
    });
  });
}
