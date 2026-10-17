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
| Confirm email turned off for testing | Done |
| Anonymous sign-ins turned off | To do |
| Web hosting for share links (step 4) | Later |

## What changed in each session

- **Latest:** Stickers on the envelope (in `0006`, so no extra file).
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

Running a file twice is safe.

**Check:** in **Table Editor** you should see `keepsakes` and
`keepsake_responses`. In **Database > Functions** you should see
`publish_keepsake`, `keepsake_cover`, `keepsake_open`, `respond_to_keepsake`,
`my_keepsake_responses`, `keepsake_pin_check`, `delete_my_account` and
`stop_sharing`, and the tables `keepsake_pin_attempts` and
`retired_share_tokens`.

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

## 4. Later: a home for share links

Share links look like `https://keepsake.app/receive/<code>`. You don't own
that domain, so in a browser those links go nowhere yet. Until this step is
done, recipients can still open a keepsake inside the app: **Profile > Open
with a code**, then paste the link or code.

To make links open in any browser:

1. Build the web app: `flutter build web --dart-define-from-file=dart_defines.json`
2. Upload the `build/web` folder to a free static host (Netlify, Vercel or
   Cloudflare Pages all work). Set the host to send every path to
   `index.html` so `/receive/...` links load the app.
3. Put your new address in `dart_defines.json` as `KEEPSAKE_LINK_BASE`
   (for example `https://keepsake-yourname.netlify.app`) and rebuild.
4. In Supabase, **Authentication > URL Configuration**: set **Site URL** to
   that same address, and add it under **Redirect URLs**. Now email
   confirmation and password reset links land on a real page, and you can
   turn **Confirm email** back on.

## Keys, for reference

- The app only contains the **publishable** key (`sb_publishable_...`).
  That key is meant to be public; the privacy rules in the SQL files are what
  protect the data.
- Never put the **secret** key (`sb_secret_...`) in the app, in
  `dart_defines.json`, or in git.
