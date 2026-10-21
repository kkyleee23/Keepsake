# Keepsake handoff

Start here after cloning. This covers what the project is, how to run it on
your laptop, what is left for you to do, the design rules we've kept, and how
the security and database fit together.

Other docs:

- `docs/SETUP.md`: step-by-step setup outside the code (Supabase, sign-in,
  hosting). Has a status table at the top.
- `SECURITY.md`: what protects people's content, and what's still missing.
- `README.md`: the short version.
- `CLAUDE.md`: a brief that Claude Code reads automatically when you open
  this folder with it: the rules, what's done, what's next, known traps.

---

## 1. What Keepsake is

A Flutter app (Android, iOS and web) for making a small private gift for one
person: a letter, photos, a little book, notes for later, a secret to scratch
off. You wrap it in an envelope, share a link, and they open it.

The flow:

```
Create tab: pick an occasion tag
  -> who it's for
  -> Editor: add sections, reorder, Wrapping (envelope, seal, stickers)
  -> Preview (exactly what they'll see)
  -> Publish: when it opens, expiry, PIN, opened receipts
  -> Link + QR, Stop Sharing, replies
Recipient (no account): link -> envelope cover -> Open -> seal breaks -> gift
  -> they can reply
```

**Section types with an editor today**

| Shelf | Types |
| --- | --- |
| Write | Letter (paper, font, ink, signed by hand), Custom Message, Essay, Book (pages they turn), Question |
| Remember | Photos (prints with captions), Memory, Timeline (moments on a vine), Reasons |
| Surprise | Scratch to Reveal (secret under gold foil), Jar of Notes (draw one at a time), Open When (envelopes for later), Countdown |

Listed in `SectionType` but not built yet (they never show in the Add
sheet): Photo Gallery, Voice Message, Video, Music Link, Quiz, Puzzle,
Future Note, Place.

**Limits** (enforced when content is read, and on the server where it
matters): 6 photos and 40 book pages per keepsake, about 8,000 words per
letter, essay or page, 30 notes in a jar (140 characters each), a 280
character scratch secret, 6 stickers per envelope, 5 MB per shared
keepsake.

---

## 2. Run it on your laptop

You need:

- **Flutter stable** (built with 3.47.6, Dart 3.10 or newer). Check with
  `flutter doctor`.
- Android Studio (Android SDK and an emulator) and/or Xcode on a Mac for iOS.
- Chrome, for the quickest preview.
- Optional: **Postgres 15+** for the database tests, **Python 3** with
  Pillow and **Node** with Playwright for the website tools.

```bash
git clone <your repo url> keepsake
cd keepsake
flutter pub get

# The app with sharing (uses dart_defines.json: Supabase URL + publishable key)
flutter run --dart-define-from-file=dart_defines.json

# Quick look in the browser
flutter run -d chrome --dart-define-from-file=dart_defines.json

# Without Supabase (everything stays on the device, no sharing)
flutter run
```

In VS Code, pick the **Keepsake (Supabase)** run configuration; it passes
the defines for you.

`dart_defines.json` holds only the **publishable** key (`sb_publishable_...`),
which is meant to be public. Never put the secret key (`sb_secret_...`)
anywhere in this repo.

**Checks before you commit**

```bash
flutter analyze lib test
flutter test                       # about 190 tests, incl. 5 phone/tablet sizes
bash tool/test_db.sh               # database rules, needs local Postgres
```

Format only the files you touched (`dart format path/to/file.dart`), not
the whole folder; a full format reflows a lot of files for no reason.

**Screens on every device size.** `test/layout_matrix_test.dart` renders
every main screen on a small Android phone, an iPhone, an iPhone with huge
text, a tablet and a phone in landscape. It fails on any overflow or a
button hidden under the system bars. To see them:

```bash
flutter test test/layout_matrix_test.dart --dart-define=SHOTS=true --update-goldens
# pictures land in test/_matrix/<device>/<screen>.png (not committed)
```

**Database tests on your laptop.** Install Postgres (Mac: `brew install
postgresql@16 && brew services start postgresql@16`; Windows: the
installer from postgresql.org, then use Git Bash or WSL). Make sure your user
can create databases, then run `bash tool/test_db.sh`. It applies every
migration twice and runs 77 checks; all should print `ok`.

---

## 3. What's left on your side

In order. Tick them off in the status table in `docs/SETUP.md` too.

### Supabase (do these first)

1. **Run the SQL files 0002 to 0007** in the SQL Editor, in order (0001 is
   done). Paste the whole file, Run, next. Every file is safe to run twice;
   if you ran an older copy of 0006, run it again.
2. **Optional: turn on pg_cron** (Database > Extensions) *before* running
   0007. Then expired keepsakes are wiped every night at 03:17 UTC. Without
   it nothing breaks; expired links already stop working on their own.
3. **Turn off anonymous sign-ins** (Authentication > Sign In / Providers).
4. **Turn on leaked-password protection** (Authentication > Policies).
5. **Leave CAPTCHA off for now.** The app doesn't send a CAPTCHA token yet,
   so turning it on would block sign-up.
6. **Check it worked:** Database > Functions should list `publish_keepsake`,
   `keepsake_cover`, `keepsake_open`, `respond_to_keepsake`,
   `my_keepsake_responses`, `my_keepsake_status`, `stop_sharing`,
   `delete_my_account`, `keepsake_pin_check`, `clean_cover_style` and
   `purge_expired_keepsakes`.

### Try the whole thing on a phone

1. Sign up, make a keepsake with a letter, a scratch card and a jar.
2. Wrap it, publish with a PIN and receipts on.
3. Open the link on another device (or Profile > Open with a code): cover,
   PIN, open, scratch, draw notes, reply.
4. Back on your phone: the card should say it was opened, and show the reply.
5. Stop Sharing: the link should say it can't be found.

### Hosting (when you're ready to share real links)

Follow **SETUP step 4**: pick Netlify or Cloudflare Pages, set
`KEEPSAKE_LINK_BASE` in `dart_defines.json` to `https://<your-site>/app`
(it's still the placeholder `https://keepsake.app`), run
`tool/build_site.sh`, upload `dist/`, then set the Site URL and Redirect URLs
in Supabase and turn **Confirm email** back on.

### Before a store release

- Change the app id from `com.keepsake.keepsake` to one you own (Android
  `android/app/build.gradle.kts`, iOS bundle id in Xcode).
- Signing: an Android upload keystore, and an Apple developer account.
- Add a contact email to `website/privacy.html` and link that page from the
  store listings.
- Store screenshots: `test/site/site_shots_test.dart` already renders clean
  ones (see section 7).

### Not built yet (ideas, roughly by value)

- Website pictures of Scratch to Reveal and Jar of Notes.
- CAPTCHA on sign-up.
- Voice and video (needs a private Storage bucket and signed URLs).
- Notifications when a gift is opened or replied to.
- Dark mode.
- The unbuilt section types listed in section 1.

---

## 4. Design system ("Sage")

All tokens live in `lib/core/theme/`. Use them; don't hard-code colours,
sizes or spacing in screens.

### Colour: 60 / 30 / 10, one accent

| Role | Token | Hex | Use |
| --- | --- | --- | --- |
| 60% background | `paper` | #F1F1EB | warm stone behind everything |
| 30% surfaces | `surface`, `surfaceAlt` | #FCFCF9, #EAEAE1 | cards, sheets, quiet fills |
| Text | `ink`, `inkSoft`, `inkFaint` | #191B16, #5F6358, #989B8C | main, secondary, hints |
| 10% accent | `accent` | #2E6B4F | the one main action per screen, selected states |
| Lines | `hairline` | #E2E2D9 | borders (preferred over shadows) |
| Semantic | `success`, `error`, `warning` | muted | only for their meaning |

**Gift surfaces** (only inside a keepsake: the letter, envelope, tags):
`giftPaper`, `envelope`, `envelopeShade`, `giftEdge`, `sage`, `sageSoft`,
`heart`. Paper textures (cream, kraft, seed, linen) come from
`PaperTextures`. The gold foil and jar-note pastels are drawn in
`surprises_view.dart` and stay inside those two sections.

No gradients, no glass or blur, no neon, no drop-shadow stacks.

### Type

| Role | Style | Font | Size / weight |
| --- | --- | --- | --- |
| The one focal headline on a screen | `display` | Montserrat | 34 / 700 |
| Big title | `displaySmall` | Montserrat | 26 / 700 |
| Screen title | `title` | Montserrat | 22 / 600 |
| Section heading | `heading` | Montserrat | 18 / 600 |
| Reading text | `bodyLarge` | Inter | 16 / 400, line height 1.5 |
| Secondary text | `body` | Inter | 14 / 400, line height 1.5 |
| Labels, list titles | `label` | Inter | 16 / 600 |
| Small print | `caption` | Inter | 13 / 400 |
| Handwritten tag ("Birthday", "Open when") | `eyebrow` | Caveat | 21 / 600, sage |

Caveat (handwriting) is only for small labels and for the gift's own ink:
letters in the hand font, scratch secrets, jar notes, sign-offs. Never for
buttons or UI text.

### Spacing, shape, motion

- Spacing scale (`AppSpacing`): 4, 8, 12, 16, 24, 32, 40, 48. Screen side
  gutter 24. Sections in a screen are 24 or 32 apart; keep the rhythm even.
- Corners (`AppRadius`): 8 small, 12 buttons and inputs, 14 cards, 20
  sheets.
- Motion (`lib/shared/widgets/motion.dart`): 180 / 320 / 520 ms, a soft
  settle curve, a small pop for playful moments. Everything goes still when
  the phone asks for reduced motion (`Motion.reduced`). Light haptics at real
  moments only: the seal breaking, a reply sent, foil revealed, a note drawn.

### Hierarchy rules for every screen

1. One focal headline, one main button (`PrimaryButton`, evergreen). Other
   actions are text or outlined buttons.
2. Buttons in Title Case ("Use This Wrapping", "Take Another").
3. Plain words, like explaining it to a friend. No "empower", "unleash",
   "seamless", no em dashes, no emoji in the UI.
4. Main buttons never sit under the system bars (the layout test checks).
5. Every new screen goes in `test/layout_matrix_test.dart`.

### Where the pieces live

| Piece | File |
| --- | --- |
| Paper sheet, envelope art, seal, letter papers and inks | `lib/shared/widgets/gift_art.dart` |
| Occasion gift tags | `lib/shared/widgets/gift_tag.dart`, `lib/features/creation/occasion_tags.dart` |
| Stickers | `lib/shared/widgets/stickers.dart` |
| Postmark | `lib/shared/widgets/postmark.dart` |
| Signature pad and view | `lib/shared/widgets/signature.dart` |
| Scratch card and note jar | `lib/features/sections/surprises_view.dart` |
| How each section looks to the recipient | `lib/features/sections/section_view.dart` |
| The cover and opening animation | `lib/features/reader/gift_cover.dart` |
| Mascot and brand | `lib/shared/widgets/brand.dart`, `assets/` |

---

## 5. Security model

The short rule: **the server decides, the app only asks.** Anyone can read
the publishable key out of the app, so nothing depends on the app behaving.

| Concern | How it's handled |
| --- | --- |
| Who can read a keepsake | Recipients have no table access at all. They call `keepsake_cover` (envelope only) and `keepsake_open`, which check published, not expired, past the open date, and the PIN, on the server. |
| Writing | Direct insert/update on tables is revoked. Publishing only through `publish_keepsake`, which validates every field and the size. |
| PINs | Hashed with bcrypt on the server; never stored on the phone or in the payload. Wrong guesses are counted and lock the keepsake for a while. |
| Stolen or reused links | Stopped or deleted links are kept as a sha256 hash and refused forever. Tokens are 22 random characters (128 bits). |
| Someone else's link | Publishing to a token you don't own returns "conflict", and the server never says whose it is. |
| Envelope style | `clean_cover_style` keeps only known papers, seals, two capital letters, the postmark switch and up to 6 known stickers, numbers clamped. |
| Floods | Per account: 20 publishes per 10 minutes, 200 a day, 500 shared, 100 MB. Replies are rate limited too. |
| Receipts | Only the creator can read them, and the cover tells the recipient they're on. Creators can turn them off. |
| Tampered content | Every model's `fromJson` type-checks and caps lengths, so a hand-edited payload can't crash a recipient's app. |
| Photos | Shrunk and re-encoded on the phone; location and camera data removed (tested). |
| Account deletion | `delete_my_account` removes the sign-in, every shared keepsake and its replies; the app wipes the local copy. |
| Website | CSP and Trusted Types on every page, strict headers, nothing loaded from other sites, `/app/` not indexed. |

Never:

- put the secret key in the app, in `dart_defines.json`, or in git;
- add a policy that lets `anon` select from `keepsakes`;
- grant `purge_expired_keepsakes` to an app role;
- return the payload from `keepsake_cover`.

---

## 6. Database

Supabase (Postgres) with row security on every table.

**Tables**

| Table | What's in it | Who can touch it |
| --- | --- | --- |
| `keepsakes` | One row per shared keepsake: token, status, names, cover note, open date, expiry, PIN hash, payload (the content as JSON), envelope style, receipts and open counts | Creator can read and delete their own rows; writes only through functions |
| `keepsake_responses` | Replies: reaction, note, name | Only through functions; creator reads their own |
| `keepsake_pin_attempts` | Wrong-PIN counts and lockouts | No app access |
| `retired_share_tokens` | Hashes of dead links | No app access |
| `publish_events` | When each account published, last 2 days | No app access |

**Functions**

| Function | Called by | Does |
| --- | --- | --- |
| `publish_keepsake` | signed-in creators | Validate and store or update a keepsake, apply limits |
| `keepsake_cover` | anyone | Envelope info only: names, note, style, sent date, whether a PIN or receipts apply |
| `keepsake_open` | anyone | Check date, expiry and PIN, record the receipt, return the content |
| `respond_to_keepsake` | anyone | Leave a reply (rate limited) |
| `my_keepsake_responses` | creators | Replies to their own keepsake |
| `my_keepsake_status` | creators | Opened when, how often, reply count, for up to 200 links |
| `stop_sharing` | creators | Turn a link off and wipe its content |
| `delete_my_account` | creators | Remove the account and everything shared |
| `purge_expired_keepsakes` | nightly job only | Wipe keepsakes expired over 30 days ago |
| `keepsake_pin_check`, `clean_cover_style`, `retire_share_token` | internal | Helpers and the delete trigger |

**Migrations** (`supabase/migrations/`, run in order, each safe to rerun)

| File | Adds | State |
| --- | --- | --- |
| 0001_init | tables, row security, publish / cover / open | Done |
| 0002_responses | replies | To do |
| 0003_payload_limit | 5 MB cap, conflict fix | To do |
| 0004_security | PIN lockout, writes only through functions, account deletion | To do |
| 0005_wrapping | envelope paper and seal on the cover | To do |
| 0006_stop_sharing | Stop Sharing, dead links stay dead, stickers, initials | To do |
| 0007_receipts_and_limits | receipts, postmark date and switch, fair-use limits, nightly clean-up | To do |

The app copes with a database that is behind: if a newer function isn't
there yet, it falls back to the older one, so nothing crashes while you
catch up. New features just won't show until the file is run.

**Adding a migration.** Name it `0008_<what>.sql`, make it safe to run twice
(`create or replace`, `if not exists`, `drop ... if exists`), keep
`security definer` functions on `set search_path = public, extensions,
pg_temp`, revoke from `public, anon` before granting, add checks in
`supabase/tests/`, and run `tool/test_db.sh`.

---

## 7. Website

`website/` is the landing page (`index.html`), `privacy.html` and `404.html`,
with `_headers` and `_redirects` for the host.

- **Every picture comes from the real app.** `test/site/site_shots_test.dart`
  renders them with sample content (Jamie sending a 30th birthday gift to
  Kyle), then `tool/build_site_media.py` turns them into the WebP images,
  the opening clip (WebM and MP4) and the fonts:

  ```bash
  flutter test test/site/site_shots_test.dart --dart-define=SITE=true
  python3 tool/build_site_media.py      # needs Pillow and ffmpeg
  ```

- **Build and check:**

  ```bash
  bash tool/build_site.sh                       # website + web app -> dist/
  python3 tool/serve_dist.py dist 8790          # serves it like the host would
  NODE_PATH=$(npm root -g) node tool/check_site.js http://localhost:8790
  ```

  The check opens every page in a real browser at four widths and fails on
  blocked loads, requests to other sites, sideways scroll, or the code box
  opening anything off-site.

---

## 8. Git

- Commit as yourself; the history uses your profile only.
- `dart_defines.json` is committed with the publishable key only.
- Not committed: `build/`, `dist/`, `test/_matrix/`, `test/_shots_test.dart`.
