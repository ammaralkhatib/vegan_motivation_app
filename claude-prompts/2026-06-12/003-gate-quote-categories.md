# Gate quote categories behind premium

## Goal
Introduce the free/premium split for content (CLAUDE.md §3): free users keep 2
quote categories, premium unlocks all 6. "Done" = a free user sees locked
categories clearly marked in Explore, can't open them or add them to the daily
mix, and the feed only serves quotes from unlocked categories; flipping
`isPremiumProvider` to true unlocks everything live, with no restart.

## Scope
- In: `lib/features/explore/`, `lib/features/quotes/providers.dart`, the
  quote DAO query used by the feed, a new small
  `lib/core/purchases/premium_gate.dart` helper, `test/`.
- Out: paywall UI (comes in prompt 004), onboarding, settings, habits,
  journey, widgets, share. No changes to the content importer or JSON. No
  Drift schema changes — gate in queries/providers, not in the DB.

## Requirements
1. Define the free-tier category ids in `lib/core/purchases/premium_gate.dart`:
   `why_vegan` and `facts` are free; `quick_tips`, `milestones`,
   `staying_strong`, `youre_awesome` are premium. Expose a small helper /
   provider (e.g. `unlockedCategoryIdsProvider`) that returns all 6 ids when
   `isPremiumProvider` is true, else the free 2. All gating below reads from
   this one place.
2. Feed: the daily mix only draws quotes from unlocked categories for free
   users. Filter in the provider/DAO layer that builds the feed (reactive to
   premium changes — Riverpod dependencies, not a one-shot read).
3. Explore screen: locked categories stay visible but show a lock indicator
   (small lock icon on the category card, in keeping with the current visual
   style) and their "in mix" toggle is disabled.
4. Tapping a locked category does NOT navigate to the detail screen. Instead
   call a single shared function `showPremiumSheet(context)` (put it in
   `premium_gate.dart`): for now a simple modal bottom sheet — lock icon,
   short line "This category is part of Veggie Premium", and an "OK" button.
   Mark it with a `// TODO(004): replace with paywall` comment; prompt 004/005
   replaces its body with the real 50%-off paywall. Keep it deliberately
   minimal — no pricing text yet.
5. Favorites: quotes the user already favorited stay visible and openable even
   if their category is locked (never take away what the user saved).
6. Notifications/widget: if their daily quote selection goes through the same
   mix query as the feed, the category filter from (2) must apply there too;
   if they use a separate query, apply the same `unlockedCategoryIds` filter
   to it. No other notification/widget changes.
7. Tests: widget/unit tests proving (a) free user: feed quotes only from free
   categories, locked card shows lock and opens the sheet instead of
   navigating; (b) premium user (via the existing `FakePurchaseService` from
   `test/support/`): everything unlocked; (c) premium flip at runtime updates
   the unlocked set.

## Constraints
- Locked decisions hold (CLAUDE.md §3): offline-first (gating must work with
  no network — it only reads `isPremiumProvider`), Riverpod/drift/go_router,
  no new packages.
- Don't mutate user data: category rows, favorites and habit data untouched.
  If a free user previously had a premium category `inMix = true`, leave the
  stored flag as-is and filter it out at query time, so going premium restores
  their old mix exactly.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries,
  CLAUDE.md §2). Run `dart run build_runner build` only if a DAO query change
  requires regeneration.

## Verify
- `flutter analyze`, `flutter test`.
- Manual click-path (note in report for Ammar): run the app as free user →
  Explore shows 4 locked cards → tap one → sheet appears → feed only shows
  Why Vegan / Facts quotes.

## Commit & push
- Conventional Commit, e.g. `feat(purchases): gate quote categories behind premium`.
- Body includes `Prompt: claude-prompts/2026-06-12/003-gate-quote-categories.md`.
- Push to origin/main; on failure stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/003-gate-quote-categories.md` from
  TEMPLATE.md. Record intent, decisions (especially how the feed/notification
  queries were filtered), verification results, commit SHA, push result, open
  items.
