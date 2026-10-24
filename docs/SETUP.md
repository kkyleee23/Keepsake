# Keepsake setup

What has to be set up outside the code for everything to work. Do the steps
in order. Each one says how to check it worked.

## Status

| Step | State |
| --- | --- |
| 0001_init.sql | Done |
| 0002_responses.sql (replies) | To do |
| 0003_payload_limit.sql (size cap, conflict fix) | To do |
| 0004_security.sql (PIN lockout, locked-down writes, account deletion) | To do |
| 0005_wrapping.sql (envelope paper and seal colour on the cover) | To do |
| 0006_stop_sharing.sql (Stop Sharing, dead links stay dead, stickers) | To do |
| 0007_receipts_and_limits.sql (opened receipts, postmark, fair-use limits, clean-up) | To do |
| pg_cron turned on (optional, for the nightly clean-up) | Optional |
| Confirm email turned off for testing | Done |
| Anonymous sign-ins turned off | To do |
| Website and share links online (step 4) | Later |

## What changed in each session

- **Latest:** Android fix (no setup): release builds were missing the
  internet permission, so an installed APK couldn't publish or open
  keepsakes. Added, and the app name on the home screen is now "Keepsake".
- **Before that:** Handoff and polish (no new file; `0007` gained one small
  addition, so if you already ran it, run it again).
  - `docs/HANDOFF.md`: start here on a new machine. How to run it, what's
    left, the design rules, security and database in one place.
  - The postmark is tidier (even lines that stop before the ring, the date
    always fits inside) and can be turned off in Wrapping. The server keeps
    only that one switch.
  - Website sample is now Jamie writing to Kyle for a 30th birthday, rewritten to
    sound like a real letter. Jamie's signature is a proper hand-signed J.
  - Privacy page now mentions opened receipts, the publish log and the
    30-day clean-up. `SECURITY.md` and `README.md` brought up to date.
- **Before that:** Two new surprises and a stronger server. **Run
  `0007_receipts_and_limits.sql`** after `0006`.
  - Scratch to Reveal: a secret on a little ticket under gold foil. They
    scratch it off with a finger; past about half, the rest falls away in
    gold flecks. A "Tap to Reveal" button is there for anyone who can't
    scratch, and screen readers don't read the secret until it's revealed.
  - Jar of Notes: up to 30 folded notes in a glass jar. Tap the jar, it
    wiggles, one note tumbles out and unfolds. They come out in a random
    order with no repeats, and the jar empties as they go.
  - The Add sheet is now grouped (Write, Remember, Surprise) with a line
    under each choice, and it scrolls on small phones.
  - Both are read leniently and capped (title, hint and secret lengths,
    30 notes of 140 characters), so a tampered gift can't break the screen.
  - Opened receipts (in `0007`): you see when a keepsake was first opened
    and how many times. You can turn this off per keepsake, and the cover
    tells the recipient whether it's on.
  - A postmark on the envelope with the day it was sent.
  - Fair-use limits per account: 20 shares in 10 minutes, 200 a day, 500
    shared keepsakes and 100 MB in total. The app explains each one plainly.
  - `purge_expired_keepsakes()` wipes keepsakes that expired over 30 days
    ago. If you turn on **pg_cron** (Database > Extensions) before running
    `0007`, it runs every night by itself. Without it nothing breaks;
    expired links already stop working on their own.
  - Database tests: `tool/test_db.sh` runs every migration twice on a local
    Postgres and then 74 checks (stolen links, PIN lockout, stickers,
    receipts, limits). All pass.
- **Before that:** More ways to make it yours (no new setup file, but **run
  `0006` again** if you ran it before; it's safe twice):
  - Occasion tags printed for their occasion (confetti and a candle, gold
    rings, an airmail border, a graduation tassel...) and shelved in three
    groups on the Create screen.
  - Your initials pressed into the wax seal. The server keeps only one or
    two capital letters.
  - Sign a letter by hand with your finger, and pick the ink (classic,
    blue-black, sepia, evergreen). Signatures are size-limited and checked
    when read.
  - Website: the new tags, initials and signature shown, sample name now
    Jamie, and every picture regenerated from the app
    (`test/site/site_shots_test.dart` then `tool/build_site_media.py`).
- **Before that:** Website round two (no setup). A box where someone can paste a
  link or code they were sent (it only ever opens links on your site), a
  questions section, a plain-English privacy page (`privacy.html`, read it
  and add a contact address before launch), and a 404 page. Security: every
  page carries its own content policy, scripts can't write HTML into the
  page (Trusted Types), and `tool/check_site.js` checks all of it in a real
  browser: no blocked loads, no requests to other sites, no sideways scroll
  at four widths, and the code box refusing anything off-site.
- **Before that:** The website (`website/`) and hosting. A landing page made
  from real screenshots and a real recording of a keepsake opening, with a
  live version of the gift-tag picker. `tool/build_site.sh` packs the
  website and the web app into one folder with strict security headers (see
  step 4). Share links now use clean addresses (`/app/receive/<code>`);
  before, the web app ignored the path and showed the home screen.
  Tested in a browser with the headers on. Also: clearer messages when a
  link can't be opened (offline gets a Try Again button), and a test that
  proves photo location data is removed.
- **Before that:** New replies show on your keepsake cards ("2 new replies"),
  counted from when you last opened that keepsake. Light haptics when the
  seal breaks, a reply is sent and tabs change. No setup.
- **Before that:** Stickers on the envelope (in `0006`, so no extra file).
  Twelve stickers (a stamp, a pressed sprig, a stitched heart, a daisy, a
  moon, an airmail label and six mascot ones) can be stuck on the envelope,
  dragged, tilted and resized. The server keeps only known stickers, at most
  six, with every number clamped (tested with hostile input). If you already
  ran `0006`, run it again; it's safe to run twice.
- **Before that:** Stop Sharing and a security fix. Run
  **`0006_stop_sharing.sql`** after `0005`.
  - On a keepsake's link page, **Stop Sharing** turns the link and QR code
    off at once and deletes the content from the server. The keepsake goes
    back to your drafts, and sharing again makes a brand new link. Replies
    you already got are kept.
  - Security fix: before 0006, deleting a keepsake freed its link, so
    someone who knew it could publish something else at the same address.
    Now every deleted or stopped link is remembered (as a one-way hash) and
    can never be used again, by anyone. Tested against a local Postgres:
    another account taking over a link, reviving a stopped link, reusing a
    deleted link, and reusing a link after account deletion are all refused.
  - The upload to the server no longer includes old links or the recipient
    contact field, and never the PIN (there's a test for this).
  - Until 0006 is run, Stop Sharing still works by removing the keepsake
    from the server, but replies to that link are lost.
  - Design: the Create screen's grid of icon tiles became a pile of paper
    gift tags with a preview of how the letter might start.
- **Before that:** Screen-size safety (no setup). Every main screen is now
  checked on a small Android phone with 3-button navigation, a notched
  iPhone, an iPhone with very large text, a tablet and a phone in landscape
  (`test/layout_matrix_test.dart`, 85 checks). It fails if anything
  overflows or if a main button sits under the system bars. Fixes from it:
  long names and words shrink instead of splitting mid-word, buttons wrap
  their label, library filters grow with large text, and onboarding goes
  side by side in landscape.
- **Before that:** Wrapping (envelope paper and seal colour) and letter
  handwriting. Run **`0005_wrapping.sql`** after `0004` so recipients see
  the chosen envelope before opening; until then the gift still publishes,
  with the standard cream envelope on the cover. Paper everywhere (no
  setup).
- **Before that:** Real paper textures for letters, the envelope and the book
  (no setup). Letter ideas and stationery (no setup). New mascot poses
  (no setup). Security: run
  **`0004_security.sql`** after `0003`. It limits PIN guessing (5 wrong
  tries locks for 15 minutes, then longer), makes publish the only way to
  write keepsakes, adds hard size limits on the table, and adds real account
  deletion (Profile > Delete My Account). Until it's run, the app still
  works, but Delete My Account only removes keepsakes, not the sign-in.
- **Before that:** Essays, long letters (with a sign-off), Book gifts, new nav
  icons, favicons and motion. **No new database setup needed**: essays and
  books are stored inside the keepsake like everything else, and the 5 MB
  cap from `0003` already covers them (a full essay is around 50 KB).
- **Before that:** Photos (inside the keepsake, no Storage bucket), and
  migration `0003`. Replies and migration `0002`.

## 1. Database (Supabase SQL Editor)

Open your project at supabase.com, go to **SQL Editor**, click **New query**,
paste the whole file, and click **Run**. Do each file once, in this order.

| File | What it adds | Already done? |
| --- | --- | --- |
| `supabase/migrations/0001_init.sql` | Keepsakes table, privacy rules, publish / cover / open functions | Yes, you ran this earlier |
| `supabase/migrations/0002_responses.sql` | Replies from recipients (only you can read them), rate limit | Run it |
| `supabase/migrations/0003_payload_limit.sql` | 5 MB size cap per keepsake (photos live inside it), and a fix so publishing with someone else's link reports a conflict instead of a fake success | Run it |
| `supabase/migrations/0004_security.sql` | PIN guess limit, writes only through publish, size limits on the table, account deletion | Run it |
| `supabase/migrations/0005_wrapping.sql` | Stores the envelope paper and seal colour, shown on the cover before opening | Run it |
| `supabase/migrations/0006_stop_sharing.sql` | Stop Sharing, stopped or deleted links can never be reused, and stickers on the envelope | Run it |
| `supabase/migrations/0007_receipts_and_limits.sql` | Opened receipts, the postmark date, fair-use limits and the nightly clean-up | Run it |

Running a file twice is safe.

**Check:** in **Table Editor** you should see `keepsakes` and
`keepsake_responses`. In **Database > Functions** you should see
`publish_keepsake`, `keepsake_cover`, `keepsake_open`, `respond_to_keepsake`,
`my_keepsake_responses`, `keepsake_pin_check`, `delete_my_account`,
`stop_sharing`, `my_keepsake_status` and `purge_expired_keepsakes`, and the
tables `keepsake_pin_attempts`, `retired_share_tokens` and
`publish_events`.

## 2. Sign-in settings (Authentication)

1. **Authentication > Sign In / Providers > Email**: make sure Email is on.
2. **Confirm email**: off for now (done). With it on, the confirmation link
   opens `localhost:3000`, which is a page that doesn't exist on your phone.
   Turn it back on once step 4 is done.
3. **Anonymous sign-ins**: turn this **off**. The app no longer uses it, and
   anonymous accounts are treated as signed out.

**Check:** create an account in the app. You should land on Home right away.

## 3. Nothing else for photos, essays or books

Photos (shrunk on the phone, location data removed), essays, long letters
and book pages are all stored inside the keepsake, so there is no Storage
bucket to create. Limits: 6 photos and 40 book pages per keepsake, about
8,000 words per letter, essay or page.

## 4. Later: put the website and share links online

Share links look like `https://<your-site>/app/receive/<code>`. Until this
step is done, recipients can still open a keepsake inside the app:
**Profile > Open with a code**, then paste the link or code.

One folder holds both the website (at `/`) and the web app (at `/app/`,
where share links open). Security headers come with it.

1. Pick a free host: **Netlify** or **Cloudflare Pages**. Both read the
   `_headers` and `_redirects` files the build includes.
2. In `dart_defines.json`, set `KEEPSAKE_LINK_BASE` to your site's address
   plus `/app`, for example `https://keepsake-yourname.netlify.app/app`.
   (You can find the address after the first upload, then rebuild.)
3. Run `tool/build_site.sh`. It builds everything into `dist/`.
4. Upload the `dist` folder (Netlify: drag it onto **Sites**; Cloudflare
   Pages: **Create > Pages > Upload assets**).
5. In Supabase, **Authentication > URL Configuration**: set **Site URL** to
   `https://<your-site>/app/` and add the same under **Redirect URLs**. Now
   email confirmation and password reset links land on a real page, and you
   can turn **Confirm email** back on.

**Check:** open `https://<your-site>/` (the website), then a share link
from the app. It should show the envelope. To check the website on your own
computer first: `python3 tool/serve_dist.py dist 8790`, then
`node tool/check_site.js http://localhost:8790` (needs Playwright:
`npm i -g playwright`).

What the headers do: the website may only load its own files (no
third-party scripts, fonts or trackers); the app may only talk to itself
and your Supabase project; neither can be put inside another site's frame;
links never send your address to other sites; search engines are told not
to index `/app/`, where share links live.

## Keys, for reference

- The app only contains the **publishable** key (`sb_publishable_...`).
  That key is meant to be public; the privacy rules in the SQL files are what
  protect the data.
- Never put the **secret** key (`sb_secret_...`) in the app, in
  `dart_defines.json`, or in git.
