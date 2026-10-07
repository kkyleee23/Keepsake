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

* Flutter project (Android / iOS / Web).
* Design-system theme: warm paper + ink, a single terracotta accent, Playfair
  Display for headlines and Inter for body, on an 8dp spacing grid.
* App shell with four tabs: Home, Create, Keepsakes, Profile.
* Core data model: `Keepsake` → ordered `KeepsakeSection`s, with delivery and
  privacy settings. Built so new section types can be added without a rewrite.
* Create flow: occasion → recipient → editor (add / edit / reorder / delete
  sections, autosaved) → preview. Sections: letter, memory, reasons, question,
  custom message.
* Publishing on Supabase: publish a draft, get a link + QR, and open it as the
  recipient. Scheduled access, expiry, and PIN are enforced on the server.

Next: media (photos, voice), responses, and the full library tabs.

## Running it

Locally (no sharing) — just run:

```bash
flutter pub get
flutter run            # pick a device, or:
flutter run -d chrome  # quick preview in the browser
```

Publishing needs Supabase credentials passed at build time (never committed):

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY \
  --dart-define=KEEPSAKE_LINK_BASE=http://localhost:PORT
```

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
