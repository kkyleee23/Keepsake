# Keepsake: notes for Claude Code

Flutter app (Android, iOS, web) for making a small private digital gift for
one person, wrapping it in an envelope and sharing a link. Supabase backend.
Website in `website/`. Read `docs/HANDOFF.md` for the full picture (design
system, security model, database); `docs/SETUP.md` is the owner's checklist.

## Rules from the owner (always follow)

- **Commits show only the owner's profile (kkyleee23).** Never add
  `Co-Authored-By`, `Claude-Session` or any Claude attribution to commits,
  PRs, code comments or docs. After committing, check with
  `git log -1 --format=%B | grep -ci "co-authored\|claude"`; it must print 0.
- **Never put the Supabase secret key (`sb_secret_...`) anywhere.** Only the
  publishable key belongs in `dart_defines.json`.
- **Update `docs/SETUP.md` every session**: the status table, the "Latest"
  entry, and any new SQL file in the migrations table.
- Every new feature ships with the security behind it: server-side checks
  for anything stored, lenient capped `fromJson` for anything read, tests.
- Copy: plain human English, like explaining to a friend. No em dashes, no
  "empower / unleash / seamless", no emoji in the UI. Buttons in Title Case.
- Design: one flat background and one accent (evergreen #2E6B4F on stone
  #F1F1EB). No gradients, glass, blur, orbs, fake mockups or fake
  testimonials, in the app or on the website. Montserrat headings, Inter
  body (line height 1.5), Caveat only for small handwritten labels and gift
  ink. Use the tokens in `lib/core/theme/`, never raw values.
- Website pictures must come from the real app (see "Website" below).
  Sample people: **Jamie sends, Kyle receives** (a 30th birthday). Sample
  text must read like a real person wrote it.

## Commands

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json   # with Supabase
flutter analyze lib test
flutter test                                            # ~190 tests
bash tool/test_db.sh                                    # 77 DB checks, local Postgres 15+
flutter test test/layout_matrix_test.dart --dart-define=SHOTS=true --update-goldens
                                                        # screenshots -> test/_matrix/
```

- Run `dart format` **only on files you touched**. Formatting the whole
  folder reflows dozens of unrelated files.
- Every new screen or interactive widget gets an entry in
  `test/layout_matrix_test.dart` (5 devices; fails on overflow or a button
  under the system bars), plus an `actions` entry if it needs taps.

## Where things are

- `lib/core/theme/` tokens; `lib/shared/widgets/` paper, envelope, seal,
  tags, stickers, postmark, signature, motion.
- `lib/features/sections/` editors and how each section renders
  (`section_view.dart`); new section types: model in `lib/data/models/`,
  default content in `creation/keepsake_factory.dart`, label/preview in
  `section_display.dart`, editor + shelf + blurb + icon in
  `editor/editor_screen.dart`, render case in `section_view.dart`.
- `lib/data/remote/keepsake_backend.dart` all Supabase calls; publish falls
  back to older function signatures on `PGRST202` / `42883` so the app works
  while migrations are behind.
- `supabase/migrations/0001..0007` (each must be safe to run twice) and
  `supabase/tests/` (`test.eq`, `test.denied` helpers).

## Done

Accounts (email + password), onboarding, four tabs; occasion gift tags on
three shelves; editor with sections: Letter (paper, font, ink, signed by
hand), Custom Message, Essay, Book, Question, Photos, Memory, Timeline,
Reasons, Scratch to Reveal, Jar of Notes, Open When, Countdown; grouped
scrollable Add sheet; Wrapping (envelope paper, seal colour, initials, up to
6 stickers, postmark on/off); Preview; publish with open date, expiry, PIN,
opened receipts; link + QR; Stop Sharing; replies with "new" badges; opened
status on cards; recipient cover with postmark and seal-break opening;
reduced-motion and haptics throughout. Backend: row security, writes only
through `publish_keepsake`, PIN hashing and lockout, dead links never
reused, style cleaning, 5 MB cap, fair-use limits, receipts, nightly purge.
Website with real screenshots and opening clip, privacy page, 404, CSP +
Trusted Types, browser check script.

## Owner still has to do (outside the code)

1. Run SQL 0002 to 0007 in Supabase in order (0001 done). Optional: enable
   pg_cron before 0007.
2. Turn off anonymous sign-ins; turn on leaked-password protection. Leave
   CAPTCHA off (the app doesn't send a token yet).
3. Host the site (SETUP step 4), set `KEEPSAKE_LINK_BASE` (still the
   placeholder `https://keepsake.app`), then turn Confirm email back on.
4. Before store release: own app id (now `com.keepsake.keepsake`), signing,
   contact email in `website/privacy.html`.

## Next to build (suggested order)

1. Website pictures of Scratch to Reveal and Jar of Notes
   (`test/site/site_shots_test.dart`, then `tool/build_site_media.py`).
2. CAPTCHA on sign-up (Turnstile or hCaptcha token passed to Supabase).
3. Voice / video sections: private Storage bucket, row security, short-lived
   signed URLs only.
4. Notifications (opened, replied): needs a server function.
5. Dark mode (tokens only; gift surfaces stay paper-coloured).
6. Unbuilt `SectionType`s: Quiz, Puzzle, Music Link, Future Note, Place,
   Photo Gallery, Voice Message, Video.

## Traps we've hit

- A cascade inside an arrow closure (`g..onDown = (d) => f(d)..onUpdate =
  ...`) parses wrongly; assign handlers as separate statements.
- Gestures inside scrolling sheets: use `EagerPan`
  (`lib/shared/widgets/eager_pan.dart`) or the sheet steals the drag.
- Rows of cards that must match heights: `IntrinsicHeight` + stretch.
- `intl` exports a `TextDirection` that clashes with Flutter's: import it
  `show DateFormat`.
- Tests: lazy lists need `scrollUntilVisible` before tapping; landscape
  needs `ensureVisible`; `OutlinedButton.icon` is a private subclass, so find
  it by text, not `widgetWithText(OutlinedButton, ...)`.
- `privacy.copyWith(expiresAt: null)` can't clear a value; build a fresh
  `PrivacySettings` instead.
- Headless Chrome with locale `en-US@posix` crashes Flutter web; use
  `en-US` in browser tests.
- Chromium in Playwright can't play H.264; the site lists WebM first.

## Website

```bash
flutter test test/site/site_shots_test.dart --dart-define=SITE=true   # renders build/site_raw/
python3 tool/build_site_media.py        # WebP images, clip, fonts (Pillow + ffmpeg)
bash tool/build_site.sh                 # website + web app (/app/) -> dist/
python3 tool/serve_dist.py dist 8790
NODE_PATH=$(npm root -g) node tool/check_site.js http://localhost:8790
```

If an image's content changes, update its `alt` text in `website/index.html`.
