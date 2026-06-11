# Veggie 🌱

Daily vegan motivation, gentle habit tracking, and a clear view of the good
you do. Offline-first — no account, no backend; everything lives on-device.

## Features

- **Today feed** — full-screen, vertically swipeable quotes (tap to advance),
  with favorites and per-category color moods
- **6 content categories** — Why Vegan, Quick Tips, You're Awesome, Facts,
  Staying Strong, Milestones — with a "mix" toggle that shapes the feed,
  notifications, and widget
- **Habit tracker** — vegan-relevant presets + custom habits, streaks,
  weekly strip, monthly heatmap, confetti celebrations
- **Journey dashboard** — days vegan + estimated impact (animals, CO₂e,
  water, grain, forest), with an honest "these are estimates" info sheet;
  a "just curious" mode shows a 30-day projection instead
- **Daily notifications** — 1–10 per day inside a custom time window; the
  full quote rides in the notification body, so Apple Watch / Wear OS
  mirroring shows it (with haptic tap on watch)
- **Home-screen widget** — daily quote on Android and iOS
  (iOS needs a one-time Xcode step: see [docs/IOS_WIDGET_SETUP.md](docs/IOS_WIDGET_SETUP.md))
- **Share as image** — styled 1080×1350 quote cards (cream / forest / coral)
- **Light & dark themes** — "fresh & organic": cream, forest green, sage,
  soft coral; Fraunces + Inter, bundled (fully offline)

## Stack

Flutter · Riverpod · drift (SQLite) · go_router ·
flutter_local_notifications · home_widget · share_plus

## Development

```sh
flutter pub get
dart run build_runner build   # drift codegen (generated files are committed)
flutter test
flutter run
```

Content lives in `assets/content/quotes_v1.json` and is imported into the
local database on first run (versioned — bump `version` to ship new content
without touching user data).

Fonts: Fraunces & Inter, SIL Open Font License 1.1 (see
`assets/fonts/OFL_NOTICE.txt`).
