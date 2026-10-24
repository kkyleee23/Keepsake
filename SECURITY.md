# Security

How Keepsake protects private content, and what still needs doing.

## What's in place

**Access is enforced on the server, not in the app.**
- Published keepsakes live in Supabase with Row-Level Security on. Creators can
  only read or change their own rows (`auth.uid() = creator_id`). Recipients get
  no direct table access at all.
- Recipients read through two `SECURITY DEFINER` functions (`keepsake_cover`,
  `keepsake_open`). These check, on the server, that a keepsake is published, not
  expired, past its scheduled open time, and that the PIN matches, before any
  content is returned. A known share token alone never reveals protected or
  not-yet-open content.

**PINs are hashed, never stored in the clear.**
- A PIN is sent once over HTTPS and hashed with bcrypt (`pgcrypto`) on the
  server. It is never written to a column and never stored on the device. The
  app also strips the PIN from the uploaded payload.

**Accounts.**
- Creators sign in with email + password (Supabase Auth). The app no longer uses
  anonymous sign-in. Each creator's `auth.uid()` is what RLS keys on.
- Recipients never sign in; they open a share link, which is the point.

**Secrets.**
- The app ships only the Supabase URL and the **publishable** (public) client
  key. The **secret** key is never in the repo or the app. Share tokens are
  128-bit, generated with a secure RNG.

**Links.**
- Stop Sharing deletes the content from the server at once. A link that was
  stopped or deleted is remembered as a one-way hash and can never be
  published again, by anyone (`retired_share_tokens`, migration 0006).
- PIN guesses are counted on the server and lock the keepsake for a while
  after too many wrong tries.

**Writes only through checked functions.**
- The app can't insert or update keepsake rows directly. Everything goes
  through `publish_keepsake`, which checks lengths, the token's shape, the
  PIN's shape, the 5 MB size cap and the envelope style (only known papers,
  seals, initials and stickers survive, with every number clamped).
- Fair use per account (0007): 20 publishes in 10 minutes, 200 a day, 500
  shared keepsakes, 100 MB in total.

**Opened receipts are disclosed.** The cover tells the recipient when the
sender will see that it was opened. Only the creator can read the receipt
(`my_keepsake_status`, which runs with the caller's own permissions).

**Untrusted content is read leniently.** Every section the recipient's app
reads (letters, signatures, photos, scratch cards, note jars...) is
type-checked and length-capped when loaded, so a tampered keepsake can't
crash the app or flood the screen. Photos lose their location and camera
data on the phone before upload.

**Website.** Strict security headers (`website/_headers`) plus a content
policy and Trusted Types on every page. No third-party scripts, fonts or
trackers. This is checked in a real browser before each release.

**Tests.** A database test script runs every migration twice on a local
Postgres and then 77 checks that try to break the rules above (stealing a
link, writing directly, guessing PINs, hostile styles, limits).

## Do these in the Supabase dashboard

1. **Run the database migrations** in order before first use.
2. **Turn OFF anonymous sign-ins** (Authentication > Providers). The app
   doesn't use them.
3. **Turn on leaked-password protection** (Authentication > Policies) so
   common breached passwords are rejected.
4. **Confirm email**: turn it back on once the website is hosted, so
   confirmation links land on a real page.
5. **Don't turn on CAPTCHA yet.** The app doesn't send a CAPTCHA token, so
   sign-up would stop working. It's on the list below.

## Still to do

- CAPTCHA on sign-up (hCaptcha or Turnstile in the app, then turn it on in
  Supabase).
- When voice or video lands, keep it in a private Storage bucket behind row
  security and serve it with short-lived signed URLs, never public ones.
- Email notifications (a reply arrived, it was opened) would need a server
  function; nothing sends email today except Supabase sign-in mail.
- Optional per-keepsake view limits.
