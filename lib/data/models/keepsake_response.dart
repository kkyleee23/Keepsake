/// A small reply a recipient sends back after opening a keepsake.
library;

/// The reactions a recipient can pick. Words, not emoji, so they read the same
/// everywhere and say something real.
enum Reaction {
  love('love', 'Love this'),
  thankYou('thank_you', 'Thank you'),
  madeMyDay('made_my_day', 'Made my day'),
  happyTears('happy_tears', 'Happy tears'),
  missYou('miss_you', 'Miss you');

  const Reaction(this.id, this.label);

  final String id;
  final String label;

  static Reaction? fromId(String? id) {
    for (final r in Reaction.values) {
      if (r.id == id) return r;
    }
    return null;
  }
}

class KeepsakeResponse {
  const KeepsakeResponse({
    required this.id,
    required this.createdAt,
    this.reaction,
    this.message,
    this.responderName,
  });

  final String id;
  final DateTime createdAt;
  final Reaction? reaction;
  final String? message;
  final String? responderName;

  factory KeepsakeResponse.fromJson(Map<String, dynamic> json) =>
      KeepsakeResponse(
        id: json['id'] as String,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        reaction: Reaction.fromId(json['reaction'] as String?),
        message: json['message'] as String?,
        responderName: json['responder_name'] as String?,
      );
}
