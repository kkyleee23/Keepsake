import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/data/models/keepsake_response.dart';
import 'package:keepsake/features/publishing/new_replies.dart';

void main() {
  test('parses a reply row from the server', () {
    final r = KeepsakeResponse.fromJson({
      'id': 'a1',
      'created_at': '2026-10-17T09:30:00Z',
      'reaction': 'made_my_day',
      'message': 'Thank you',
      'responder_name': 'Mia',
    });
    expect(r.reaction, Reaction.madeMyDay);
    expect(r.message, 'Thank you');
    expect(r.responderName, 'Mia');
  });

  test('unknown reactions are ignored, not fatal', () {
    final r = KeepsakeResponse.fromJson({
      'id': 'a2',
      'created_at': '2026-10-17T09:30:00Z',
      'reaction': 'something_new',
      'message': 'Hi',
    });
    expect(r.reaction, isNull);
    expect(r.message, 'Hi');
  });

  test('reaction ids match the database check constraint', () {
    expect(
      Reaction.values.map((r) => r.id).toSet(),
      {'love', 'thank_you', 'made_my_day', 'happy_tears', 'miss_you'},
    );
  });

  group('New replies', () {
    final t0 = DateTime(2026, 10, 17, 9);
    final replies = [
      KeepsakeResponse(id: 'a', createdAt: t0),
      KeepsakeResponse(id: 'b', createdAt: t0.add(const Duration(hours: 2))),
      KeepsakeResponse(id: 'c', createdAt: t0.add(const Duration(hours: 5))),
    ];

    test('all are new before the first look', () {
      expect(countNewReplies(replies, null), 3);
    });

    test('only ones after the last look', () {
      expect(countNewReplies(replies, t0.add(const Duration(hours: 1))), 2);
      expect(countNewReplies(replies, t0.add(const Duration(hours: 6))), 0);
    });

    test('none when there are none', () {
      expect(countNewReplies(const [], null), 0);
    });
  });
}
