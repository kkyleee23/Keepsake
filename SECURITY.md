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

## Do these in the Supabase dashboard

1. **Turn OFF anonymous sign-ins** (Authentication → Providers). Now that
   creators use real accounts, this closes the door on anyone using the public
   key to create rows anonymously.
2. **Keep "Confirm email" ON** so sign-ups prove they own the address. (The app
   handles the "confirm your email, then sign in" state.)
3. **Enable CAPTCHA** for auth (Supabase recommends this) to limit abuse and
   fake sign-ups.
4. **Turn on leaked-password protection** (Authentication → Policies) so common
   breached passwords are rejected.

## Still to do

- Rate-limit publishing per account.
- When media (photos, voice) lands, store it in a private Supabase Storage
  bucket behind RLS and serve it with short-lived signed URLs, never public ones.
- A proper "delete my account and data" flow.
- Audit logging for opens, and optional view limits per keepsake.
