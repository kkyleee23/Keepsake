import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/data/models/keepsake_response.dart';

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
}
