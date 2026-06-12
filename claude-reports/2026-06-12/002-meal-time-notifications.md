# Meal-time notification mode (breakfast / lunch / dinner)

**Prompt:** `claude-prompts/2026-06-12/002-meal-time-notifications.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Added a second notification mode. Alongside the existing "spread across a daily
window" mode, the user can now anchor notifications to meals. Each meal
(breakfast / lunch / dinner) has a time and a count (1–3); the app places
notifications in a smart pattern around that time and prefers quotes that fit the
moment — encouragement before eating, praise after dinner. Settings offers both
modes; spread mode is byte-for-byte unchanged for existing users. Analyze clean,
all 108 tests pass (19 new), and the original `notification_scheduler_test.dart`
passes untouched.

## Files touched

- `lib/core/notifications/notification_scheduler.dart` — added `categoryId` to
  `SchedulableQuote` (optional, default `''`), a new pure `planMealSlots()`
  function, `MealConfig`, and the before/after category constants. `planSlots`
  (spread) is unchanged.
- `lib/core/prefs/prefs_repository.dart` — new keys: `notifMode` + per-meal
  enabled/time/count (defaults 08:00 / 13:00 / 19:00, on, count 2).
- `lib/features/settings/notification_prefs.dart` — `NotifMode`, `Meal`,
  `MealSetting`; `NotifSettings` extended; notifier setters for mode/meal fields
  (each goes through `invalidateSelf` so the coordinator's listener replans).
- `lib/core/notifications/notification_coordinator.dart` — picks the planner by
  mode; passes `categoryId` through; meal mode with all meals off cancels all.
- `lib/features/settings/notification_settings_screen.dart` — mode selector +
  three meal cards.
- Tests: `meal_scheduler_test.dart`, `notif_meal_settings_test.dart`,
  `notification_settings_meal_test.dart` (new).

## Decisions

- **Slot pattern & jitter.** Per enabled meal at time T: count 1 → [T−20];
  count 2 → [T−60, T−15]; count 3 → [T−60, T−15, T+30] (the +30 is the only
  "after" slot). Each slot gets ±7 min deterministic jitter seeded by
  `day*31 + slotIndex` — the same seeding *style* as spread mode, so a reschedule
  never moves an already-planned time. Past slots on day 0 are skipped, exactly
  like spread mode.
- **Id scheme (no collisions).** Spread ids are `(day%100000)*16 + slot` (< ~1.6M).
  Meal ids live in a separate high band: `100_000_000 + (day%100000)*16 +
  slotIndex`, where `slotIndex = mealIndex*3 + j` (0–8). Because the slot index is
  derived from the meal's *position* (breakfast 0–2, lunch 3–5, dinner 6–8),
  changing one meal's count never shifts another meal's ids. `cancelAll` still
  runs on every reschedule, so the two modes never coexist anyway — the separate
  band is belt-and-suspenders.
- **Budget.** `totalPerDay = sum of enabled counts` (≤9); reused
  `daysAhead = clamp(60 ~/ totalPerDay, 3, 14)`. Max load (3×3) → 6 days × 9 = 54,
  comfortably under the iOS-64 cap.
- **Category preference + fallback.** `SchedulableQuote` now carries `categoryId`.
  Before-meal slots prefer `staying_strong` / `why_vegan`; the after-dinner slot
  prefers `youre_awesome` (real content ids, verified against the JSON). "Prefer"
  = pick the first unused quote in those categories *if the mix has one*;
  otherwise fall back to the normal day ordering. A per-day "used" set avoids
  repeating a quote across that day's slots.
- **Meal-spacing UI rule.** I chose **block-with-a-hint** over cascading
  auto-adjustment: picking a meal time within 2 hours of another *enabled* meal
  shows a brief SnackBar and doesn't apply. Three independent times don't have an
  obvious "adjust the neighbor" direction the way the single start/end window
  does, so blocking is simpler and clearer.
- **All meals off = nothing scheduled.** Meal mode with no enabled meals takes the
  same path as the master switch being off (cancel all); the screen shows a small
  "turn on at least one meal" hint.

## Verification

```
$ flutter analyze
No issues found! (ran in 3.1s)

$ flutter test
All tests passed!   (108 tests; 19 new)
```

New tests: slot positions for counts 1/2/3 (±7), deterministic jitter, past-slot
skipping, budget/daysAhead (54 at max, 14 at min), id uniqueness + non-collision
with spread + per-meal id stability, category preference and fallback when
preferred categories are absent; prefs defaults + round-trip + legacy→spread +
count clamp; widget test (mode switch reveals meal cards, toggling a meal updates
state). The pre-existing `notification_scheduler_test.dart` passes unchanged.

Self-correction: fixed one over-strict test on attempt 2 — the id-stability test
compared full id lists, but changing a meal's count legitimately changes the
*horizon length* (daysAhead). Reworked it to compare the shared-day prefix; the
per-day ids are stable. No source changes were needed.

Manual click-path (open item for Ammar):
- [ ] Settings → Notifications → switch to "Around meals"; set times/counts.
- [ ] Confirm pending notifications land around the meals (OS settings or a debug
      print of the plan); the after-dinner one is praise-flavored.
- [ ] Switch back to "Through the day" → the old behavior is restored unchanged.

## Open items for the owner

- Manual on-device check of real fired notifications (above) — can't be verified
  in CI.

## Deviations from prompt

None.
