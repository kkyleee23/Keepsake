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

Foundation in place:

* Flutter project scaffolded (Android / iOS / Web).
* Design-system theme: warm paper + ink, a single terracotta accent, Playfair
  Display for headlines and Inter for body, on an 8dp spacing grid.
* App shell with four tabs: Home, Create, Keepsakes, Profile.
* Core data model: `Keepsake` → ordered `KeepsakeSection`s, with delivery and
  privacy settings. Built so new section types can be added without a rewrite.

Next: the recipient flow, the section editor, and preview.

## Running it

```bash
flutter pub get
flutter run            # pick a device, or:
flutter run -d chrome  # quick preview in the browser
```

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
