# Gate quote categories behind premium

**Prompt:** `claude-prompts/2026-06-12/003-gate-quote-categories.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Added the free/premium content split. Free users keep two categories (Why Vegan,
Facts); premium unlocks all six. One small helper — `unlockedCategoryIdsProvider`
— is the single source of truth, and the feed, notifications, home-screen widget
and Explore screen all read from it. Locked categories stay visible in Explore but
show a lock, can't be toggled into the mix, and tapping one opens a minimal
"premium" sheet instead of the category. The gate is reactive: flipping
`isPremiumProvider` to true unlocks everything live, with no restart. No DB schema
change, no user data touched. Analyze clean, all 63 tests pass (8 new).

## Files touched

- `lib/core/purchases/premium_gate.dart` (new) — the free/premium id sets,
  `unlockedCategoryIdsProvider`, and `showPremiumSheet()` (marked
  `// TODO(004): replace with paywall`).
- `lib/core/db/daos/quote_dao.dart` — `getQuotesInMix` gained an optional
  `unlockedCategoryIds` filter. Method-signature change only, so no Drift
  regeneration was needed (the `.g.dart` only tracks table shapes).
- `lib/features/quotes/providers.dart` — `feedQueueProvider` now watches the
  unlocked set and passes it to the query (reactive to premium).
- `lib/core/notifications/notification_coordinator.dart`,
  `lib/core/widgetkit/home_widget_service.dart` + `lib/app/app.dart` — the same
  filter is applied to the notification and widget quote queries.
- `lib/features/explore/explore_screen.dart` — locked category cards show a lock
  icon (instead of the mix Switch) and route taps to `showPremiumSheet`.
- `test/premium_gate_test.dart` (new), `test/feed_widget_test.dart`,
  `test/widget_test.dart` — see below.

## Decisions

- **Filter at query time, never mutate `inMix`.** A free user who once had a
  premium category switched on keeps that stored flag; it's just filtered out by
  the `unlockedCategoryIds` predicate. Upgrading restores their exact old mix —
  the constraint in the prompt. The DB schema is untouched.
- **One source of truth.** `unlockedCategoryIdsProvider` reads `isPremiumProvider`
  and returns all six ids when premium, else the free two. Feed, notifications,
  widget and Explore all consume it — no duplicated split logic.
- **How each query was filtered.** All three quote-mix consumers already had a
  Riverpod `ref`: the feed provider `ref.watch`es the set (so it rebuilds on a
  premium flip); the notification coordinator and the widget push read it once at
  build/refresh time and pass it into `getQuotesInMix(unlockedCategoryIds: …)`.
- **Explore lock UI** swaps the mix `Switch` for a small `lock_outline` icon on
  locked cards (keeps the row layout/visual style) and disables the toggle by
  removing it; the card's tap opens the sheet rather than navigating.
- **`showPremiumSheet` is intentionally bare** — lock icon, one line, an OK
  button, no pricing — with a `TODO(004)` so prompt 004/005 drops the real
  50%-off paywall into its body.
- **Test harness update:** the feed and full-app tests now also override
  `purchaseServiceProvider` with the existing `FakePurchaseService`, because the
  feed/app tree now reads `isPremiumProvider`. Both use a premium fake so their
  existing assertions stay independent of the gate.

## Verification

```
$ flutter analyze
No issues found! (ran in 3.0s)

$ flutter test
All tests passed!   (63 tests; 8 new for gating)
```

New tests cover: free user gets 2 categories / premium gets 6 / runtime flip
expands the set live; the mix query excludes premium categories for free users and
includes all for premium (and stays unfiltered with no argument); Explore shows a
lock + opens the sheet (not the detail screen) for a free user, and shows all
switches with no locks for premium.

Self-correction: none — analyze and tests were green on the first run.
(The `drift` "database created multiple times" warning in the log is pre-existing
test-harness noise, unrelated to this change.)

Manual click-path (for the owner):
- [ ] Run as a free user → Explore shows 4 locked cards (lock icon, no switch).
- [ ] Tap a locked card → the "Veggie Premium" sheet appears; it does not open
      the category.
- [ ] The daily feed only shows Why Vegan / Facts quotes.
- [ ] A previously-favorited quote from a now-locked category still opens.

## Open items for the owner

- The premium sheet is a placeholder; the real 50%-off paywall lands in prompt
  004/005 (RevenueCat `default` offering).
- Still depends on the placeholder API keys from prompt 002 — gating itself needs
  no network (it only reads cached premium status), so this works offline today.

## Commit & push

- **Commit(s):** `69d7d14` — `feat(purchases): gate quote categories behind premium`
  (this report's SHA stamp is a tiny follow-up `docs` commit).
- **Push:** `origin/main` — ok (`5b3c9c6..69d7d14`).

## Deviations from prompt

None.
