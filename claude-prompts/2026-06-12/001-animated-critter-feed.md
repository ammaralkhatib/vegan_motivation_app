# Animated farm critters: assets + AnimatedCritter widget + quote feed integration

## Goal

Give the quote feed life: a small kawaii farm animal sits on each quote card,
gently bobbing and blinking, and does a happy wiggle when tapped. This is the
first of several critter placements (habit celebrations, onboarding, and journey
come later). "Done" = all 6 animals bundled as assets, a reusable
`AnimatedCritter` widget, and the matching animal visible and animated on every
quote card in the Today feed.

## Scope

- In: `assets/critters/` (new), `pubspec.yaml` (asset registration only),
  a new widget file under `lib/core/` (suggested:
  `lib/core/critters/animated_critter.dart`), the quote feed card widget under
  `lib/features/quotes/`, new test file(s) under `test/`.
- Out: everything else. Do not touch habits, journey, onboarding, settings,
  notifications, widgetkit, database, or content JSON. No new packages.

## Requirements

1. **Download the 18 frames** into `assets/critters/`, named
   `<animal>_<frame>.png` (e.g. `cow_base.png`, `cow_blink.png`,
   `cow_happy.png`). Source URLs (transparent PNGs, 2048×2048), prefix
   `https://d8j0ntlcm91z4.cloudfront.net/user_3EG5pBhqcAcQxHpM3yL8XPvtR0A/`:

   | File | URL suffix |
   |---|---|
   | cow_base.png | hf_20260612_072826_8f479e08-0d69-4ff0-9f6e-51676a13e693.png |
   | cow_blink.png | hf_20260612_072828_43a0cfd5-a714-46cf-a593-def5ef8e6be1.png |
   | cow_happy.png | hf_20260612_080032_1787f4ee-2043-45ec-9fe1-e795a5408a84.png |
   | pig_base.png | hf_20260612_080442_2db5b112-fb44-4064-bca5-cb48d204ec2f.png |
   | pig_blink.png | hf_20260612_080444_548d5f82-fe7e-4860-86e4-37b627479319.png |
   | pig_happy.png | hf_20260612_080446_978f4b98-da74-4295-a2cc-ea60ba2c23cd.png |
   | sheep_base.png | hf_20260612_080447_8dc81e57-ba72-4715-aac2-c3dca15f448c.png |
   | sheep_blink.png | hf_20260612_080449_35587ef7-a546-47a5-9881-c9b793783d0b.png |
   | sheep_happy.png | hf_20260612_080451_d6a44609-fb6c-4c1e-8f4a-2601d2a7470e.png |
   | chicken_base.png | hf_20260612_080452_40b29a4a-7718-4eb4-ad63-68c14f37ae46.png |
   | chicken_blink.png | hf_20260612_080454_44cbcc91-0912-4687-8917-a15079a279fd.png |
   | chicken_happy.png | hf_20260612_080455_c4da0cf1-b40c-41f0-a7be-2b6caf0cd745.png |
   | duck_base.png | hf_20260612_080457_ad98cd6c-2620-43dc-b3dd-d5f1d95d3eda.png |
   | duck_blink.png | hf_20260612_080458_022f73b7-d8bd-4536-b4c7-7e73d9b8a35c.png |
   | duck_happy.png | hf_20260612_080500_d20aa3b3-c803-4117-9b57-a48aa0737840.png |
   | goat_base.png | hf_20260612_080606_a2d84224-52a2-42ca-ba7f-b3f37556882d.png |
   | goat_blink.png | hf_20260612_080504_ac14285d-e6ed-45ff-93ef-7e141bc280a6.png |
   | goat_happy.png | hf_20260612_080506_98aa3d1b-aba7-44ec-be52-013ca449d4a3.png |

2. **Downscale every PNG to 512×512** before committing (keep transparency) so
   the app bundle stays small — on macOS `sips -Z 512 <file>` works. Verify the
   18 files are each well under 300 KB after resizing. Register
   `assets/critters/` in `pubspec.yaml`.
3. **Create a `Critter` enum** (cow, pig, sheep, chicken, duck, goat) with the
   asset paths for its 3 frames: `base`, `blink`, `happy`.
4. **Create `AnimatedCritter` widget** (suggested:
   `lib/core/critters/animated_critter.dart`):
   - Constructor: `AnimatedCritter({required Critter critter, double size = 96, bool animate = true})`.
   - All 3 frames pre-loaded and stacked (`Stack` + `Visibility` or opacity
     swap) so frame changes never flicker; `precacheImage` the frames.
   - **Bob:** whole widget moves up-down with a sine wave, amplitude ≈ 5–7 px
     at size 96 (scale with size), period ≈ 2.8 s. Drive with a single repeating
     `AnimationController`.
   - **Blink:** swap to the blink frame for ≈ 160 ms at random intervals of
     2.2–4.8 s.
   - **Tap → happy:** on tap, show the happy frame for ≈ 1.2 s with a decaying
     wiggle (rotation oscillating up to ±8°, slight scale up to 1.05), then
     return to base. Expose an optional `onTap` callback that still fires.
   - `animate: false` renders the static base frame (for tests / reduced
     motion). Respect `MediaQuery.disableAnimations` by falling back to static.
   - Dispose controllers properly; widget must not tick when not mounted.
5. **Quote feed integration:** show an `AnimatedCritter` (size ≈ 96) on each
   quote card in the Today feed, positioned where it does not overlap the quote
   text or action buttons (bottom area of the card is expected to work; use your
   judgment from the existing layout). Map content category → animal
   deterministically so each category has its own companion:
   Why Vegan → cow, Quick Tips → chicken, You're Awesome → pig,
   Facts → duck, Staying Strong → goat, Milestones → sheep.
   If a card's category is unknown, fall back to cow.
6. **Tests:** add a widget test for `AnimatedCritter` (renders base frame;
   swaps to happy frame on tap with `animate: true` and pumped time) and update
   any feed widget tests broken by the new child. All existing tests must stay
   green.

## Constraints

- Locked decisions hold (CLAUDE.md §3): offline-first — assets are bundled,
  no network calls at runtime (downloads happen only at build time in this
  task); Riverpod/drift/go_router untouched; home_widget untouched.
- **No new packages.** Plain `AnimationController`/`Ticker` only.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries
  per CLAUDE.md §2).
- Keep the feed's swipe/tap-to-advance behavior working — the critter's tap
  target must not swallow the card's main gestures outside its own bounds.

## Verify

- `flutter analyze`
- `flutter test`
- Manual (recorded as an open item for Ammar): run the app, swipe a few quote
  cards — every card shows its animal bobbing; it blinks occasionally; tapping
  it shows the happy wiggle; text remains readable.

## Commit & push

- Conventional Commit, e.g. `feat(quotes): animated farm critters on feed cards`;
  body includes `Prompt: claude-prompts/2026-06-12/001-animated-critter-feed.md`.
- Push to origin/main; on failure, stop and report (never force). If no remote
  is configured yet, commit locally and note it in the report.

## Report

- Write `claude-reports/2026-06-12/001-animated-critter-feed.md` from
  `claude-reports/TEMPLATE.md` (mkdir -p the folder). Record intent, decisions
  (especially critter placement on the card and any layout trade-offs),
  verification results, final asset sizes, commit SHA, push result, open items.
  No full diff.
