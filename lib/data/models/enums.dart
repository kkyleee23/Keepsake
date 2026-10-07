/// Shared enums for the Keepsake domain.
///
/// Each enum carries a human [label] so the UI never hardcodes display strings
/// next to logic. `fromId` keeps (de)serialization stable even if the enum order
/// changes later.
library;

enum Occasion {
  birthday('birthday', 'Birthday'),
  anniversary('anniversary', 'Anniversary'),
  love('love', 'Love'),
  longDistance('long_distance', 'Long Distance'),
  friendship('friendship', 'Friendship'),
  family('family', 'Family'),
  graduation('graduation', 'Graduation'),
  congratulations('congratulations', 'Congratulations'),
  thankYou('thank_you', 'Thank You'),
  apology('apology', 'Apology'),
  encouragement('encouragement', 'Encouragement'),
  justBecause('just_because', 'Just Because'),
  custom('custom', 'Custom');

  const Occasion(this.id, this.label);

  final String id;
  final String label;

  static Occasion fromId(String id) =>
      Occasion.values.firstWhere((o) => o.id == id, orElse: () => Occasion.custom);
}

/// Lifecycle of a Keepsake.
enum KeepsakeStatus {
  draft('draft', 'Draft'),
  published('published', 'Published'),
  sealed('sealed', 'Sealed'),
  opened('opened', 'Opened'),
  archived('archived', 'Archived');

  const KeepsakeStatus(this.id, this.label);

  final String id;
  final String label;

  static KeepsakeStatus fromId(String id) => KeepsakeStatus.values
      .firstWhere((s) => s.id == id, orElse: () => KeepsakeStatus.draft);
}

/// Every section type the product may hold. The content model is deliberately
/// generic (see [KeepsakeSection]) so adding a new type here is the only change
/// required to support it structurally.
enum SectionType {
  letter('letter', 'Letter'),
  photo('photo', 'Photo'),
  photoGallery('photo_gallery', 'Photo Gallery'),
  memory('memory', 'Memory'),
  timeline('timeline', 'Timeline'),
  voiceMessage('voice_message', 'Voice Message'),
  video('video', 'Video'),
  musicLink('music_link', 'Music Link'),
  countdown('countdown', 'Countdown'),
  openWhen('open_when', 'Open When'),
  question('question', 'Question'),
  quiz('quiz', 'Quiz'),
  puzzle('puzzle', 'Puzzle'),
  scratchReveal('scratch_reveal', 'Scratch Reveal'),
  reasons('reasons', 'Reasons'),
  futureNote('future_note', 'Future Note'),
  place('place', 'Place'),
  customMessage('custom_message', 'Custom Message');

  const SectionType(this.id, this.label);

  final String id;
  final String label;

  static SectionType fromId(String id) => SectionType.values
      .firstWhere((t) => t.id == id, orElse: () => SectionType.customMessage);
}

/// How a published Keepsake becomes available to its recipient.
enum DeliveryMode {
  immediately('immediately', 'Open immediately'),
  scheduled('scheduled', 'Open at a date & time'),
  countdown('countdown', 'Open after a countdown'),
  manual('manual', 'Keep sealed until I unlock it');

  const DeliveryMode(this.id, this.label);

  final String id;
  final String label;

  static DeliveryMode fromId(String id) => DeliveryMode.values
      .firstWhere((m) => m.id == id, orElse: () => DeliveryMode.immediately);
}
