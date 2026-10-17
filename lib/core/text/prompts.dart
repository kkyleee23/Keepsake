import '../../data/models/enums.dart';

/// Gentle ways to begin, for when the page is blank. Each is the start of a
/// sentence the writer finishes in their own words.
abstract final class Prompts {
  static const List<String> _anyone = [
    'The first thing I remember about you is',
    'Something I never told you:',
    'You make ordinary days better because',
    'A small moment with you I keep coming back to is',
    'I hope you know that',
    'If I could give you one thing right now, it would be',
    'Thank you for the time you',
  ];

  static const Map<Occasion, List<String>> _byOccasion = {
    Occasion.birthday: [
      'Happy birthday. This year, I hope',
      'The best thing about the past year with you was',
      'Things about you that got even better this year:',
    ],
    Occasion.anniversary: [
      'When I think back to where we started,',
      'My favorite thing we built together is',
      'Here is what I want for our next year:',
    ],
    Occasion.love: [
      'I fall for you a little more every time you',
      'The way you',
      'Being with you feels like',
    ],
    Occasion.longDistance: [
      'Even from here, I can picture you',
      'Next time we are together, I want to',
      'The miles are long, but',
    ],
    Occasion.friendship: [
      'I knew we would be friends when',
      'You are the person I call when',
      'My favorite version of us is',
    ],
    Occasion.family: [
      'Growing up, you taught me',
      'Something I only understand now is',
      'I see you in the way I',
    ],
    Occasion.graduation: [
      'Watching you get here, I saw',
      'Whatever you do next, remember',
      'I am proud of you for',
    ],
    Occasion.congratulations: [
      'You did it. I knew you would because',
      'What I admire most about how you got here is',
    ],
    Occasion.thankYou: [
      'Thank you for',
      'I did not say it enough at the time, but',
      'Because of you, I',
    ],
    Occasion.apology: [
      'I am sorry for',
      'I have been thinking about what happened, and',
      'What I want you to know now is',
    ],
    Occasion.encouragement: [
      'I know things feel heavy right now, but',
      'Here is what I see when I look at you:',
      'You have already made it through',
    ],
    Occasion.justBecause: [
      'No reason, just this:',
      'I was thinking about you today when',
    ],
  };

  /// Prompts for [occasion] first, then a few that suit anyone.
  static List<String> forOccasion(Occasion? occasion) => [
        ...?_byOccasion[occasion],
        ..._anyone,
      ];
}
