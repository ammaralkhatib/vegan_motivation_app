# Photo-background polish: paywall hook, full-screen feed, motion, stronger tints

Batch lane: six small, related changes, all polish on the photo-background
feature (prompts 006–007) after Ammar's on-device review.

## Goal
Make the photo feed feel premium and finished: full-screen photo behind a
see-through bottom bar, subtle slow motion on the photo, readable text with a
shadow, no critter competing with the photo, a paywall hook on the settings
switch for free users, and clearly distinct category colors for the
gradient (non-photo) cards.

## Scope
- In: `lib/features/quotes/quote_card.dart`, `lib/features/quotes/feed_screen.dart`
  (if needed), `lib/app/shell.dart`, `lib/features/settings/settings_screen.dart`,
  `lib/core/theme/app_theme.dart` (categoryTints only), tests.
- Out: `lib/core/purchases/` internals (you may *call* the existing paywall
  navigation/trigger, change nothing inside), DB, content importer, manifest
  format, habits/explore/journey screens (no visual change there).

## Requirements
1. **Settings switch → paywall for free users.** The "Photo backgrounds" switch
   is currently hidden for free users. Instead: always show it; for free users
   render it disabled-looking (off, dimmed) and tapping the row opens the
   existing **default** paywall (the 50%-off offering already used for locked
   content — reuse the existing trigger/navigation helper from prompt 005, don't
   build a new one). Premium users: unchanged behavior.
2. **Hide the critter on photo cards.** When the card renders a photo background
   (`imagePath != null`), do not show `AnimatedCritter`. Gradient cards keep the
   critter exactly as today. Keep the layout balanced when it's absent (no big
   empty gap — let the spacers absorb it).
3. **Full-screen photo + translucent bottom bar (Today tab only).** In
   `lib/app/shell.dart` (phone layout): set `extendBody: true` so the feed
   draws behind the bottom `NavigationBar`, and when the current branch is
   Today (index 0) give the bar a translucent surface (e.g. theme surface at
   ~70% opacity, no elevation tint that re-opaques it). Other tabs keep
   today's solid bar and must look unchanged — verify their scrollable content
   still clears the bar (SafeArea/MediaQuery handles this with extendBody, but
   check Habits/Explore/Journey visually in tests or by padding audit). The
   feed card's bottom controls must respect the new bottom inset so the
   favorite/share buttons aren't hidden behind the bar. Wide layout
   (NavigationRail) unchanged.
4. **Text shadow on photo cards.** When on a photo, give the quote body and
   author text a soft shadow to lift them off the image (e.g.
   `Shadow(blurRadius: 12, color: Colors.black54, offset: Offset(0, 2))`).
   No shadow on gradient cards.
5. **Slow Ken Burns motion on the photo.** Each photo slowly scales AND drifts
   toward a corner while the card is on screen. Deterministic per quote:
   8 variants = (zoom in | zoom out) × 4 corners, picked by `quote.id % 8`, so
   every slide feels different but a given quote always moves the same way.
   Implementation guidance: StatefulWidget around the photo with an
   `AnimationController` (~14s, `Curves.easeInOut`, forward only — no looping
   ping-pong needed for a feed card), animating scale between 1.0 and ~1.08
   and `alignment` from center toward the variant's corner. The image must
   always cover the screen (never reveal edges): keep `BoxFit.cover` and only
   scale ≥1.0. Dispose the controller properly; the PageView recreates cards
   per page so each swipe restarts the motion — that's the desired "new
   movement every slide". Scrim and content do NOT move.
6. **Stronger, distinct category tints.** In `VeggieAccents.light` and `.dark`,
   replace the six `categoryTints` with clearly distinguishable, more saturated
   colors (keep the existing gradient rendering — tint → scaffold background).
   Direction: why_vegan = green, quick_tips = yellow-olive, youre_awesome =
   warm pink/coral, facts = teal/blue, staying_strong = earthy orange/brown,
   milestones = golden amber. Each must still pass text contrast with the
   default theme text colors in its own theme (light tints stay light enough
   for dark text; dark tints stay dark enough for light text). Update any test
   that asserts the old constants.

## Constraints
- Locked decisions hold: offline-first, Riverpod/drift/go_router, no new
  packages, no purchases-internal changes.
- `flutter analyze` clean; `flutter test` green (≤2 self-correct attempts,
  CLAUDE.md §2).
- Keep each change minimal — this is polish, not a refactor.

## Verify
- `flutter analyze` && `flutter test`
- Add/extend widget tests: (a) free user sees the disabled switch and tapping
  routes to the paywall, (b) photo card has no `AnimatedCritter`, gradient card
  has one, (c) photo card's quote text style contains a shadow, gradient card's
  doesn't, (d) Ken Burns variant selection is deterministic (id → same variant).
- Manual (Ammar): premium build → photo fills the screen behind a see-through
  bar on Today; photos drift slowly, each slide differently; text pops; no
  critter on photos; Habits/Explore/Journey look unchanged; free build →
  settings switch dimmed, tap opens 50%-off paywall; gradient cards show six
  clearly different colors.

## Commit & push
- One commit (or per-change commits if cleaner), Conventional Commits; body
  includes `Prompt: claude-prompts/2026-06-12/008-photo-feed-polish.md`.
- Push to `origin/main`; on failure stop and record — never force.

## Report
- `claude-reports/2026-06-12/008-photo-feed-polish.md` from TEMPLATE.md.
  Record per-requirement status (1–6), the chosen tint hex values, Ken Burns
  parameters, verification output, commit SHA(s), push result.
