// Renders the screenshots and the opening clip used on the website, from the
// real app with sample content. Off by default; to regenerate:
//
//   flutter test test/site/site_shots_test.dart --dart-define=SITE=true
//   python3 tool/build_site_media.py
//
// Raw frames go to build/site_raw/ (not committed).

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/core/theme/app_theme.dart';
import 'package:keepsake/data/models/enums.dart';
import 'package:keepsake/data/models/keepsake.dart';
import 'package:keepsake/data/models/keepsake_response.dart';
import 'package:keepsake/data/models/keepsake_section.dart';
import 'package:keepsake/data/providers.dart';
import 'package:keepsake/data/remote/keepsake_backend.dart';
import 'package:keepsake/features/creation/create_screen.dart';
import 'package:keepsake/features/editor/editor_screen.dart';
import 'package:keepsake/features/keepsakes/application/keepsakes_controller.dart';
import 'package:keepsake/features/reader/book_view.dart';
import 'package:keepsake/features/reader/keepsake_content_view.dart';
import 'package:keepsake/features/receive/receive_screen.dart';
import 'package:keepsake/features/sections/writing_screen.dart';
import 'package:keepsake/shared/widgets/gift_art.dart';
import 'package:keepsake/shared/widgets/nav_icons.dart';
import 'package:keepsake/shared/widgets/paper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

const _site = bool.fromEnvironment('SITE');
const _out = 'build/site_raw';
const _size = Size(390, 844);
const _pad = EdgeInsets.only(top: 47, bottom: 34);

final _now = DateTime(2026, 10, 17, 9, 30);

const _letter =
    'Happy birthday. I wanted to write down a few things I never '
    'manage to say out loud, so here they are.\n\n'
    'Thank you for the slow Sundays, for the bad movies we keep watching on '
    'purpose, and for answering the phone at 2am that one time without '
    'asking why.\n\n'
    'This year I hope you get the window seat, the last slice, and every '
    'green light on the way home.';

const _style = KeepsakeStyle(
  envelope: 'kraft',
  seal: SealColor.terracotta,
  mono: 'S',
  stickers: [
    PlacedSticker(kind: StickerKind.stamp, x: 0.85, y: 0.2, turn: 6),
    PlacedSticker(kind: StickerKind.sprig, x: 0.14, y: 0.76, turn: -12),
    PlacedSticker(
      kind: StickerKind.heart,
      x: 0.27,
      y: 0.22,
      turn: -8,
      scale: 0.8,
    ),
  ],
);

/// A quick cursive scribble, like signing a card.
final _signature = [
  [
    for (var i = 0; i <= 60; i++) ...[
      0.1 + i * 0.012,
      0.5 -
          0.28 * math.sin(i / 60 * math.pi * 4.5) * (1 - i / 90) -
          (i < 12 ? (12 - i) * 0.015 : 0),
    ],
  ],
  [0.12, 0.84, 0.45, 0.8, 0.86, 0.82],
];

KeepsakeSection _sec(int i, SectionType t, Map<String, dynamic> c) =>
    KeepsakeSection(
      id: 's$i',
      type: t,
      position: i,
      content: c,
      createdAt: _now,
      updatedAt: _now,
    );

final _gift = Keepsake(
  id: 'mia',
  title: "For Jamie's 30th",
  occasion: Occasion.birthday,
  recipientName: 'Jamie',
  senderName: 'Sam',
  status: KeepsakeStatus.published,
  shareToken: 'sampleTOKEN000000000a',
  coverNote: 'Open this with your coffee, before anyone else texts you.',
  createdAt: _now,
  updatedAt: _now,
  style: _style,
  sections: [
    _sec(0, SectionType.letter, {
      'title': 'Dear Jamie',
      'body': _letter,
      'signoff': 'Love, always',
      'paper': 'kraft',
      'font': 'hand',
      'signature': _signature,
    }),
    _sec(2, SectionType.openWhen, {
      'title': 'Open when',
      'items': [
        {'label': 'you miss home', 'body': 'Call me. I will put the kettle on.'},
        {'label': 'it rains all weekend', 'body': 'The good blanket is yours.'},
      ],
    }),
    _sec(1, SectionType.reasons, {
      'title': 'Things I like about you',
      'items': [
        'You laugh before the joke is finished.',
        'You remember everyone’s coffee order.',
        'You always say yes to one more walk.',
      ],
    }),
  ],
);

class _Backend extends KeepsakeBackend {
  @override
  bool get isAvailable => true;
  @override
  Future<CoverResult> fetchCover(String token) async => CoverResult(
    status: 'available',
    occasion: 'birthday',
    recipientName: 'Jamie',
    senderName: 'Sam',
    coverNote: _gift.coverNote,
    style: _style,
    receipts: true,
    sentOn: DateTime(2026, 10, 21),
  );
  @override
  Future<OpenResult> open(String token, {String? pin}) async =>
      OpenResult(status: 'ok', keepsake: _gift);
  @override
  Future<List<KeepsakeResponse>?> fetchResponses(String token) async => [];
}

Widget _tab(Widget screen, int index) => Scaffold(
  body: screen,
  bottomNavigationBar: NavigationBar(
    selectedIndex: index,
    destinations: [
      for (final g in NavGlyph.values)
        NavigationDestination(
          icon: NavIcon(g),
          selectedIcon: NavIcon(g, filled: true),
          label: g.name,
        ),
    ],
  ),
);

final _boundary = GlobalKey();

Future<void> _setUp(WidgetTester t, Widget screen) async {
  t.view.physicalSize = _size * 3;
  t.view.devicePixelRatio = 3;
  t.view.padding = FakeViewPadding(top: _pad.top * 3, bottom: _pad.bottom * 3);
  t.view.viewPadding = t.view.padding;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await t.runAsync(() => PaperTextures.instance.load());
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      keepsakeBackendProvider.overrideWithValue(_Backend()),
    ],
  );
  addTearDown(c.dispose);
  await c.read(keepsakesControllerProvider.future);
  await c
      .read(keepsakesControllerProvider.notifier)
      .upsert(_gift.copyWith(status: KeepsakeStatus.draft));
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: RepaintBoundary(
        key: _boundary,
        child: MaterialApp(
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          home: PaperPage(child: screen),
        ),
      ),
    ),
  );
  await _frames(t, 14);
  await t.runAsync(() async {
    for (final el in find.byType(Image).evaluate()) {
      await precacheImage((el.widget as Image).image, el);
    }
  });
  await _frames(t, 4);
}

Future<void> _frames(WidgetTester t, int n, [int ms = 80]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(Duration(milliseconds: ms));
  }
}

Future<void> _save(WidgetTester t, String name, {double ratio = 3}) async {
  await t.runAsync(() async {
    final b =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: ratio);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/$name.png')..createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('create', skip: !_site, (t) async {
    await _setUp(t, _tab(const CreateScreen(), 1));
    await t.tap(find.text('Birthday'));
    await _frames(t, 12);
    // Back to the top: the heading and the picked tag on their shelf.
    await t.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await _frames(t, 12);
    await _save(t, 'create');
  });

  testWidgets('writer', skip: !_site, (t) async {
    await _setUp(
      t,
      WritingScreen(
        kind: WritingKind.letter,
        heading: 'Letter',
        title: 'Dear Jamie',
        body: _letter,
        signoff: 'Love, always',
        paper: 'kraft',
        font: 'hand',
        signature: _signature,
      ),
    );
    await _save(t, 'writer');
  });

  testWidgets('wrap', skip: !_site, (t) async {
    await _setUp(t, const EditorScreen(keepsakeId: 'mia'));
    await t.ensureVisible(find.text('Wrapping'));
    await t.tap(find.text('Wrapping'));
    await _frames(t, 14);
    await _save(t, 'wrap');
  });

  testWidgets('cover', skip: !_site, (t) async {
    await _setUp(t, const ReceiveScreen(token: 'sampleTOKEN000000000a'));
    await _save(t, 'cover');
  });

  testWidgets('letter', skip: !_site, (t) async {
    await _setUp(t, Scaffold(body: KeepsakeContentView(keepsake: _gift)));
    await _save(t, 'letter');
  });

  testWidgets('reasons', skip: !_site, (t) async {
    await _setUp(t, Scaffold(body: KeepsakeContentView(keepsake: _gift)));
    await t.drag(find.byType(Scrollable).first, const Offset(0, -620));
    await _frames(t, 16);
    await _save(t, 'reasons');
  });

  testWidgets('book', skip: !_site, (t) async {
    await _setUp(
      t,
      const BookReaderScreen(
        title: 'The Year in Small Things',
        author: 'Sam',
        dedication: 'For Jamie, who reads the last page first.',
        pages: [
          BookPage(
            title: 'January',
            body:
                'You made soup for the whole street when the snow came, '
                'and then pretended it was an accident that you made so much.',
          ),
        ],
      ),
    );
    await _save(t, 'book');
  });

  // The clip: the cover, the seal breaking, the letter rising, the gift.
  testWidgets('opening clip', skip: !_site, (t) async {
    await _setUp(t, const ReceiveScreen(token: 'sampleTOKEN000000000a'));
    var n = 0;
    Future<void> shoot(int frames) async {
      for (var i = 0; i < frames; i++) {
        await t.pump(const Duration(microseconds: 33333));
        await _save(t, 'clip/f${(n++).toString().padLeft(4, '0')}', ratio: 1.5);
      }
    }

    await shoot(36); // a moment on the cover
    await t.tap(find.text('Open'));
    await shoot(120); // seal, flap, letter, then the gift settles in
    await t.drag(find.byType(Scrollable).first, const Offset(0, -260));
    await shoot(50);
  });
}
