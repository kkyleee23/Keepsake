// Renders the main screens on a range of devices and fails if anything
// overflows, throws, or puts a main button under the system navigation bar
// or home indicator.
//
// Devices: a small Android phone with 3-button navigation, an iPhone with a
// notch and home bar, the same iPhone with very large text, a tablet, and a
// phone in landscape.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepsake/app/app.dart';
import 'package:keepsake/core/theme/app_theme.dart';
import 'package:keepsake/data/models/enums.dart';
import 'package:keepsake/data/models/keepsake.dart';
import 'package:keepsake/data/models/keepsake_response.dart';
import 'package:keepsake/data/models/keepsake_section.dart';
import 'package:keepsake/data/providers.dart';
import 'package:keepsake/data/remote/keepsake_backend.dart';
import 'package:keepsake/features/auth/auth_screen.dart';
import 'package:keepsake/features/creation/create_screen.dart';
import 'package:keepsake/features/editor/editor_screen.dart';
import 'package:keepsake/features/home/home_screen.dart';
import 'package:keepsake/features/keepsakes/application/keepsakes_controller.dart';
import 'package:keepsake/features/keepsakes/keepsakes_screen.dart';
import 'package:keepsake/features/onboarding/onboarding_screen.dart';
import 'package:keepsake/features/profile/profile_screen.dart';
import 'package:keepsake/features/publishing/delivery_screen.dart';
import 'package:keepsake/features/publishing/published_screen.dart';
import 'package:keepsake/features/reader/book_view.dart';
import 'package:keepsake/features/reader/keepsake_content_view.dart';
import 'package:keepsake/features/reader/long_form.dart';
import 'package:keepsake/features/receive/receive_screen.dart';
import 'package:keepsake/features/sections/book_editor_screen.dart';
import 'package:keepsake/features/sections/photo_editor_screen.dart';
import 'package:keepsake/features/sections/writing_screen.dart';
import 'package:keepsake/shared/widgets/gift_art.dart';
import 'package:keepsake/shared/widgets/nav_icons.dart';
import 'package:keepsake/shared/widgets/paper.dart';
import 'package:keepsake/shared/widgets/primary_button.dart';
import 'package:keepsake/shared/widgets/stickers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Device {
  const Device(this.name, this.size, this.dpr,
      {this.top = 0, this.bottom = 0, this.side = 0, this.text = 1});
  final String name;
  final Size size; // logical
  final double dpr;
  final double top, bottom, side, text;
}

const devices = [
  Device('android-small-3button', Size(360, 640), 2, top: 24, bottom: 48),
  Device('iphone-notch', Size(390, 844), 3, top: 47, bottom: 34),
  Device('iphone-large-text', Size(390, 844), 3, top: 47, bottom: 34, text: 1.6),
  Device('tablet', Size(820, 1180), 2, top: 24, bottom: 20),
  Device('phone-landscape', Size(844, 390), 3, top: 0, bottom: 21, side: 47),
];

Future<void> _fonts() async {
  Future<void> load(String fam, List<String> paths) async {
    final l = FontLoader(fam);
    for (final p in paths) {
      l.addFont(Future.value(ByteData.view(File(p).readAsBytesSync().buffer)));
    }
    await l.load();
  }

  await load('Inter', ['regular', 'medium', 'semibold', 'bold']
      .map((w) => 'fonts/inter/inter_$w.ttf')
      .toList());
  await load('Montserrat', ['regular', 'semibold', 'bold', 'extrabold']
      .map((w) => 'fonts/montserrat/montserrat_$w.ttf')
      .toList());
  await load('Caveat', ['fonts/caveat/caveat_variable.ttf']);
  await load('Playfair', ['regular', 'semibold', 'bold']
      .map((w) => 'fonts/playfair-display/playfair_display_$w.ttf')
      .toList());
  // Real icon glyphs in the review images, when the SDK ships the font.
  final icons = '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(icons).existsSync()) await load('MaterialIcons', [icons]);
}

final _now = DateTime(2026, 10, 17, 9, 30);
KeepsakeSection _sec(int i, SectionType t, Map<String, dynamic> c) =>
    KeepsakeSection(
        id: 's$i',
        type: t,
        position: i,
        content: c,
        createdAt: _now,
        updatedAt: _now);

const _letter = 'Happy birthday. I wanted to write down a few things I never '
    'say out loud, so here they are.\n\nThank you for every slow Sunday and '
    'every late call.';

Keepsake _ks(String id, KeepsakeStatus st,
        {String? token, List<KeepsakeSection> sections = const []}) =>
    Keepsake(
      id: id,
      title: 'A keepsake with a fairly long title for testing',
      occasion: Occasion.congratulations,
      recipientName: 'Maximiliana',
      senderName: 'Kyle',
      status: st,
      shareToken: token,
      createdAt: _now,
      updatedAt: _now,
      coverNote: 'Open this when you have a quiet minute and a cup of tea.',
      sections: sections,
    );

final _sections = [
  _sec(0, SectionType.letter, {
    'title': 'Dear Maximiliana',
    'body': '$_letter\n\n$_letter',
    'signoff': 'With all my love',
    'paper': 'kraft',
    'font': 'hand',
  }),
  _sec(1, SectionType.reasons, {
    'title': 'Reasons',
    'items': ['You laugh first.', 'You remember everything.'],
  }),
  _sec(2, SectionType.openWhen, {
    'items': [
      {'label': 'you miss me', 'body': 'Call me.'},
    ],
  }),
  _sec(3, SectionType.countdown, {
    'label': 'Until our trip',
    'date': DateTime.now().add(const Duration(days: 40)).toIso8601String(),
  }),
];

class _FakeBackend extends KeepsakeBackend {
  _FakeBackend(this.cover, this.openStatus);
  final CoverResult cover;
  final String openStatus;
  @override
  bool get isAvailable => true;
  @override
  Future<CoverResult> fetchCover(String token) async => cover;
  @override
  Future<OpenResult> open(String token, {String? pin}) async =>
      OpenResult(status: openStatus, opensAt: cover.opensAt);
  @override
  Future<void> stopSharing(String token) async {}
  @override
  Future<List<KeepsakeResponse>?> fetchResponses(String token) async => [];
}

/// Two replies waiting on every link.
class _RepliesBackend extends _FakeBackend {
  _RepliesBackend() : super(_cover, 'ok');
  @override
  Future<List<KeepsakeResponse>?> fetchResponses(String token) async => [
        KeepsakeResponse(id: 'r1', createdAt: DateTime.now(), message: 'Oh!'),
        KeepsakeResponse(
            id: 'r2', createdAt: DateTime.now(), reaction: Reaction.love),
      ];
}

/// The tab screens inside a bottom bar like the real shell.
Widget _tab(Widget screen) => Scaffold(
      body: screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
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

final _cover = CoverResult(
  status: 'available',
  occasion: 'congratulations',
  recipientName: 'Maximiliana',
  senderName: 'Kyle',
  coverNote: 'Open this when you have a quiet minute and a cup of tea.',
  requiresPin: true,
  style: KeepsakeStyle(
    envelope: 'kraft',
    seal: SealColor.terracotta,
    stickers: [
      PlacedSticker(kind: StickerKind.stamp, x: 0.85, y: 0.2, turn: 6),
      PlacedSticker(kind: StickerKind.sprig, x: 0.14, y: 0.76, turn: -12),
      PlacedSticker(kind: StickerKind.heart, x: 0.26, y: 0.22, turn: -8, scale: 0.8),
    ],
  ),
);

final Map<String, (Widget Function(), List<Override>)> screens = {
  'onboarding': (() => const OnboardingScreen(), const []),
  'auth': (() => const AuthScreen(), const []),
  'home': (() => _tab(const HomeScreen()), const []),
  'create': (() => _tab(const CreateScreen()), const []),
  'create-picked': (() => _tab(const CreateScreen()), const []),
  'library': (() => _tab(const KeepsakesScreen()), const []),
  'library-replies': (
    () => _tab(const KeepsakesScreen()),
    [keepsakeBackendProvider.overrideWithValue(_RepliesBackend())]
  ),
  'profile': (() => _tab(const ProfileScreen()), const []),
  'editor': (() => const EditorScreen(keepsakeId: 'd1'), const []),
  'editor-stickers': (() => const EditorScreen(keepsakeId: 'd1'), const []),
  'delivery': (() => const DeliveryScreen(keepsakeId: 'd1'), const []),
  'published': (() => const PublishedScreen(keepsakeId: 'p1'), const []),
  'published-stopped': (
    () => const PublishedScreen(keepsakeId: 'p1'),
    [keepsakeBackendProvider.overrideWithValue(_FakeBackend(_cover, 'ok'))]
  ),
  'receive-cover': (
    () => const ReceiveScreen(token: 'x'),
    [keepsakeBackendProvider.overrideWithValue(_FakeBackend(_cover, 'ok'))]
  ),
  'receive-sealed': (
    () => const ReceiveScreen(token: 'x'),
    [
      keepsakeBackendProvider.overrideWithValue(_FakeBackend(
          CoverResult(
              status: 'sealed',
              recipientName: 'Maximiliana',
              opensAt: DateTime.now().add(const Duration(days: 3))),
          'sealed'))
    ]
  ),
  'gift': (
    () => Scaffold(
        body: KeepsakeContentView(
            keepsake: _ks('g', KeepsakeStatus.published, sections: _sections))),
    const []
  ),
  'writer': (
    () => const WritingScreen(
        kind: WritingKind.letter,
        heading: 'Letter',
        title: 'Dear you',
        body: _letter,
        paper: 'kraft',
        font: 'hand'),
    const []
  ),
  'essay': (
    () => const EssayReaderScreen(
        title: 'On staying', body: '$_letter\n\n$_letter', author: 'Kyle'),
    const []
  ),
  'book': (
    () => BookReaderScreen(
        title: 'The Book of Us',
        author: 'Kyle',
        dedication: 'For Maximiliana, who reads the last page first.',
        pages: const [BookPage(title: 'One', body: _letter)]),
    const []
  ),
  'photo-editor': (
    () => PhotoEditorScreen(
        section: _sec(0, SectionType.photo, {'title': '', 'photos': []}),
        otherPhotos: 0),
    const []
  ),
  'book-editor': (
    () => BookEditorScreen(
        section: _sec(0, SectionType.book, {'title': '', 'pages': []})),
    const []
  ),
};

/// Screens that need a tap or two first. Each runs after the first frames and
/// can check what the tap did.
final Map<String, Future<void> Function(WidgetTester)> actions = {
  'editor-stickers': (t) async {
    await t.ensureVisible(find.text('Wrapping'));
    await t.tap(find.text('Wrapping'));
    await _settle(t);
    final trayList = find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal);
    final tray =
        find.descendant(of: trayList, matching: find.byType(StickerView));
    await t.ensureVisible(trayList);
    await _settle(t);
    for (final i in [1, 0]) {
      await t.tap(tray.at(i));
      await _settle(t);
    }
    // Further along the tray: a pup.
    final pup = find.descendant(
      of: trayList,
      matching: find.byWidgetPredicate(
          (w) => w is StickerView && w.kind == StickerKind.pupWave),
    );
    await t.scrollUntilVisible(pup, 80,
        scrollable:
            find.descendant(of: trayList, matching: find.byType(Scrollable)));
    await _settle(t);
    await t.tap(pup);
    await _settle(t);
    expect(find.text('3 of 6'), findsOneWidget);
    // Drag the newest one a little; it stays on the envelope.
    final board = find.byType(StickerView).at(2);
    await t.drag(board, const Offset(-30, -12));
    await _settle(t);
    expect(find.text('Peel Off'), findsOneWidget);
  },
  'library-replies': (t) async {
    expect(find.text('2 new replies'), findsOneWidget);
  },
  'published-stopped': (t) async {
    await t.scrollUntilVisible(find.text('Stop Sharing'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Stop Sharing'));
    await _settle(t);
    await t.tap(find.text('Stop Sharing'));
    await _settle(t);
    expect(find.text('Stop sharing this link?'), findsOneWidget);
    await t.tap(find.text('Stop Sharing').last);
    await _settle(t);
    expect(find.text('The link is off'), findsOneWidget);
  },
  'create-picked': (t) async {
    await t.tap(find.text('Birthday'));
    await _settle(t);
    final b = t.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(b.onPressed, isNotNull, reason: 'picking a tag enables Continue');
    expect(find.textContaining('Happy birthday'), findsOneWidget);
  },
};

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 80));
  }
}

/// `flutter test --dart-define=SHOTS=true --update-goldens` also saves a
/// screenshot of every screen on every device into test/_matrix/ for review.
const _shots = bool.fromEnvironment('SHOTS');

void main() {
  setUpAll(_fonts);

  for (final d in devices) {
    for (final e in screens.entries) {
      testWidgets('${e.key} on ${d.name}', (t) async {
        t.view.physicalSize = d.size * d.dpr;
        t.view.devicePixelRatio = d.dpr;
        final pad = FakeViewPadding(
          top: d.top * d.dpr,
          bottom: d.bottom * d.dpr,
          left: d.side * d.dpr,
          right: d.side * d.dpr,
        );
        t.view.padding = pad;
        t.view.viewPadding = pad;
        t.platformDispatcher.textScaleFactorTestValue = d.text;
        addTearDown(() {
          t.view.reset();
          t.platformDispatcher.clearTextScaleFactorTestValue();
        });

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await t.runAsync(() => PaperTextures.instance.load());
        final c = ProviderContainer(overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...e.value.$2,
        ]);
        addTearDown(c.dispose);
        await c.read(keepsakesControllerProvider.future);
        final ctl = c.read(keepsakesControllerProvider.notifier);
        await ctl.upsert(_ks('d1', KeepsakeStatus.draft, sections: _sections));
        await ctl.upsert(_ks('p1', KeepsakeStatus.published, token: 'tok'));

        await t.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            // Same wide-screen column as the real app.
            builder: (context, child) => AppFrame(child: child),
            home: PaperPage(child: e.value.$1()),
          ),
        ));
        for (var i = 0; i < 12; i++) {
          await t.pump(const Duration(milliseconds: 80));
        }

        final act = actions[e.key];
        if (act != null) await act(t);

        // 1. Nothing overflowed or threw while laying out.
        expect(t.takeException(), isNull);

        if (_shots) {
          await t.runAsync(() async {
            for (final el in find.byType(Image).evaluate()) {
              await precacheImage((el.widget as Image).image, el);
            }
          });
          await t.pump(const Duration(milliseconds: 100));
          await expectLater(find.byType(MaterialApp),
              matchesGoldenFile('_matrix/${d.name}/${e.key}.png'));
        }

        // 2. No main button sits under the system bars when it isn't in a
        //    scrolling list (scrolling content can always be scrolled up).
        final screenH = d.size.height;
        for (final el in find.byType(PrimaryButton).evaluate()) {
          final inScroll = find
              .ancestor(
                  of: find.byWidget(el.widget), matching: find.byType(Scrollable))
              .evaluate()
              .isNotEmpty;
          if (inScroll) continue;
          final r = t.getRect(find.byWidget(el.widget));
          expect(r.bottom <= screenH - d.bottom + 0.5, isTrue,
              reason: '${e.key}: button bottom ${r.bottom} is under the '
                  'system bar (screen $screenH, bar ${d.bottom})');
          expect(r.top >= d.top - 0.5, isTrue,
              reason: '${e.key}: button under the status bar');
        }
      });
    }
  }
}
