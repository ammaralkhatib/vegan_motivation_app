# Rename product IDs to vegankit_ + re-anchor pricing to $29.99

**Prompt:** `claude-prompts/2026-06-13/005-vegankit-product-ids-pricing.md`
**Completed:** 2026-06-13 · **Status:** done

> Keep this short. Git holds the diff — Planning Claude reads it with `git show`.

## Summary

Renamed the three subscription product IDs from the `veggie_` prefix to
`vegankit_` (suffixes `_full`/`_50`/`_80` kept) across the app's trial-reminder
constant, the two tests that assert on them, and `docs/STORE_SETUP.md`. Re-anchored
the setup-guide prices to the new $29.99 tier ($29.99 / $14.99 / $5.99) and fixed
one stale `$49.99` comment in `paywall_data.dart`. The STORE_SETUP display name was
already "VeganKit" (done in the prior inline task). `flutter analyze` clean; all
166 tests pass.

## Files touched

- `lib/core/notifications/trial_reminder.dart` — `trialProductId` →
  `vegankit_yearly_full`.
- `test/trial_reminder_test.dart` — id literals → `vegankit_yearly_*` (still asserts
  the full id schedules the reminder; `_50`/`_80` do not).
- `test/support/paywall_fixtures.dart` — fixture product id → `vegankit_yearly_full`.
- `docs/STORE_SETUP.md` — all `veggie_yearly_*` → `vegankit_yearly_*` (table, Apple
  steps, Google steps, RevenueCat import list, offerings table); prices $49.99 →
  $29.99, $24.99 → $14.99, $9.99 → $5.99. Base plan `yearly` and free-trial offer id
  `free-trial` unchanged; Apple `$99` / Play `$25` fees unchanged.
- `lib/features/paywall/paywall_data.dart` — comment "sells the $49.99 product" →
  "$29.99 product" (comment only, no logic change).

## Decisions

None — the prompt was fully specified. Display name in STORE_SETUP.md was already
VeganKit, so requirement 4 needed no new change (verified zero "Veggie" left).

## Verification

```
$ grep -rn "veggie_yearly" lib/ test/ docs/
(no results)

$ flutter analyze
No issues found! (ran in 2.4s)

$ flutter test
00:05 +166: All tests passed!
```

Self-correction: none needed — clean on first run.

## Commit & push

- **Commit:** `<sha>` — `chore(purchases): rename product ids to vegankit_ and re-anchor pricing to $29.99`
- **Push:** `origin/main` — see below.

## Open items for the owner

- **Create the store products with the NEW ids and prices.** In App Store Connect
  and Play Console make `vegankit_yearly_full` ($29.99, 7-day trial),
  `vegankit_yearly_50` ($14.99), `vegankit_yearly_80` ($5.99). If any old `veggie_`
  products were already created, they **cannot be renamed** — create fresh ones with
  the new ids.
- The RevenueCat `appl_…` and `goog_…` public SDK keys still need to reach Planning
  Claude to paste into `lib/core/purchases/purchase_config.dart`.

## Deviations from prompt

None.
