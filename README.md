# Keepsake

> A digital space for creating something meaningful for someone you care about.

Keepsake is a Flutter mobile application focused on creating and giving personal digital gifts.

The idea started from something simple: sometimes a normal message is not enough. A letter, memory, photo, or voice message can mean much more when it is intentionally made for someone and kept somewhere they can always return to.

Keepsake aims to make that possible for anyone.

## What you can create

Keepsakes can eventually include:

* Letters
* Birthday messages
* Photo collections
* Memories
* Voice messages
* Video messages
* Timelines
* Open When messages
* Future messages
* Digital cards
* Personal surprises
* Collaborative gifts

The first version will focus on the basics and grow from there.

## Idea:

A Keepsake is something you create for another person.

```text
Create
   ↓
Personalize
   ↓
Preview
   ↓
Send
   ↓
Open
   ↓
Keep
```

The project is currently focused on establishing the first usable version of the Keepsake experience.

## Development status

In place:

* Flutter project (Android / iOS / Web) with its own brand kit: mascot,
  wordmark, app icon, and a launch splash.
* Design-system theme (the "Sage" direction): warm stone background, a single
  deep evergreen accent, Montserrat headings and Inter body, on an 8dp grid.
  Centered in a phone-width column on tablets and desktop.
* Onboarding on first launch, then email + password accounts (sign up, sign in,
  forgot password, edit profile, delete my data). Recipients never sign in.
* Four tabs: Home, Create, Keepsakes, Profile.
* Core data model: `Keepsake` holds ordered `KeepsakeSection`s plus delivery and
  privacy settings. New section types slot in without a rewrite.
* Create flow: occasion, recipient, editor (add / edit / reorder / delete
  sections, autosaved), preview. Section types: letter, memory, Open When,
  reasons, timeline, question, countdown, custom message.
* Publishing on Supabase: publish a draft, get a link and QR, open it as the
  recipient. Scheduled access, expiry, and PIN are enforced on the server.
* Library: Created / Received / Drafts / Archived, with search and per-card
  actions (open, copy link, archive, delete).

Next (needs a testing session or a backend step): media (photos, voice),
recipient responses, notifications, and dark mode.

## Running it

Locally (no sharing) — just run:

```bash
flutter pub get
flutter run            # pick a device, or:
flutter run -d chrome  # quick preview in the browser
```

With sharing — the Supabase URL and **publishable** key live in
`dart_defines.json` (the publishable key is a public client key, safe to commit;
the secret key is never stored here):

```bash
flutter run -d chrome --dart-define-from-file=dart_defines.json
```

In VS Code, just pick the **"Keepsake (Supabase)"** run configuration. To point
at a different project, edit `dart_defines.json`.

## Sharing / backend setup (Supabase)

1. Create a project at supabase.com and open the **SQL Editor**.
2. Run `supabase/migrations/0001_init.sql` (creates the table, Row-Level
   Security, and the server-side access functions).
3. In **Authentication → Providers**, enable **Anonymous sign-in** (creators get
   an identity without an account; recipients never sign in).
4. Copy the project URL and the `anon` key into the `--dart-define`s above.
5. Set `KEEPSAKE_LINK_BASE` to wherever the app is reachable. On a static host,
   add an SPA fallback so `/receive/<token>` serves `index.html`.

## Project layout

```
lib/
  app/        app shell, router
  core/       theme tokens (colors, type, spacing, radius)
  data/       models
  features/   home, creation, keepsakes, profile
  shared/     reusable widgets
```

Fonts live in `fonts/`; color and UI references in `colors/`, `images/`, and
`login screens/`.
