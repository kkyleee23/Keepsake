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
    'Happy 30th! I started writing this in a card and ran out of room '
    'before I got to the good part, so you get the long version.\n\n'
    'I keep thinking about the night the car broke down two hours from '
    'home and we ate a whole box of gas station donuts on the hood while we '
    'waited for the tow truck. Nothing went right that day and it’s still '
    'one of my favorites.\n\n'
    'You’re the first person I call when something happens, good or bad. '
    'You always pick up, even that time I locked myself out in a towel. '
    'You laughed, but you came.\n\n'
    'I don’t say it enough, so I’m putting it somewhere you can keep: I’m '
    'really glad it’s you.\n\n'
    'Now go eat cake. I hid a slice for you behind the milk.';

const _style = KeepsakeStyle(
  envelope: 'kraft',
  seal: SealColor.terracotta,
  mono: 'J',
  stickers: [
    PlacedSticker(kind: StickerKind.stamp, x: 0.9, y: 0.24, turn: 6),
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

/// Points along a quadratic curve from [a] through control [c] to [b].
List<double> _curve(List<double> a, List<double> c, List<double> b, int n) => [
  for (var i = 0; i <= n; i++)
    for (final k in [0, 1])
      math.pow(1 - i / n, 2) * a[k] +
          2 * (1 - i / n) * (i / n) * c[k] +
          math.pow(i / n, 2) * b[k],
];

/// Jamie's signature: a tall J with a hooked tail, a quick run of loops for
/// "amie", the dot of the i, and an underline.
final _signature = [
  [
    ..._curve([0.06, 0.4], [0.12, 0.06], [0.34, 0.1], 12),
    ..._curve([0.34, 0.1], [0.26, 0.5], [0.24, 0.86], 14),
    ..._curve([0.24, 0.86], [0.18, 1.0], [0.1, 0.74], 10),
  ],
  [
    for (var i = 0; i <= 90; i++) ...[
      0.3 +
          0.0095 * (i / 90 * math.pi * 7) -
          0.022 * math.sin(i / 90 * math.pi * 7),
      0.62 - 0.1 * math.cos(i / 90 * math.pi * 7) * (1 - i / 150),
    ],
  ],
  [0.5, 0.3, 0.505, 0.29],
  [0.06, 0.94, 0.45, 0.9, 0.9, 0.92],
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
  title: "For Kyle's 30th",
  occasion: Occasion.birthday,
  recipientName: 'Kyle',
  senderName: 'Jamie',
  status: KeepsakeStatus.published,
  shareToken: 'sampleTOKEN000000000a',
  coverNote: 'Open this before your phone blows up. I wanted to be first.',
  createdAt: _now,
  updatedAt: _now,
  style: _style,
  sections: [
    _sec(0, SectionType.letter, {
      'title': 'Dear Kyle,',
      'body': _letter,
      'signoff': 'See you Saturday,',
      'paper': 'kraft',
      'font': 'hand',
      'signature': _signature,
    }),
    _sec(2, SectionType.openWhen, {
      'title': 'Open when',
      'items': [
        {
          'label': 'you can’t sleep',
          'body':
              'Text me. I’m probably up too, rewatching something I’ve seen '
              'twelve times.',
        },
        {
          'label': 'work was awful',
          'body': 'Order the good takeout tonight. Send me the receipt.',
        },
      ],
    }),
    _sec(1, SectionType.reasons, {
      'title': 'Stuff I’ve noticed about you',
      'items': [
        'You still text me when you get home.',
        'You know my coffee order better than I do.',
        'You start laughing at your own jokes halfway through, and it gets '
            'me every time.',
        'That plant I gave you is somehow still alive.',
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
    recipientName: 'Kyle',
    senderName: 'Jamie',
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
        title: 'Dear Kyle,',
        body: _letter,
        signoff: 'See you Saturday,',
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
    await t.drag(find.byType(Scrollable).first, const Offset(0, -1240));
    await _frames(t, 16);
    await _save(t, 'reasons');
  });

  testWidgets('book', skip: !_site, (t) async {
    await _setUp(
      t,
      const BookReaderScreen(
        title: 'Things That Happened This Year',
        author: 'Jamie',
        dedication: 'For Kyle, who always reads the last page first. Don’t.',
        pages: [
          BookPage(
            title: 'January',
            body:
                'The power was out for two days. You showed up with a camping '
                'stove and the worst soup I’ve ever had. I ate three bowls.',
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
