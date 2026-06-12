# Meal-time notification mode (breakfast / lunch / dinner)

## Goal

Add a second notification mode: instead of spreading notifications across one
daily window, the user can anchor them to their meals — the moments where vegan
support actually matters. Each meal (breakfast, lunch, dinner) gets a time and a
count (1–3); the app places notifications in a smart pattern around that time,
and prefers quotes that fit the moment (encouragement before eating, praise
after). "Done" = the notification settings screen offers both modes, meal mode
schedules correctly, and all behavior is covered by tests.

## Scope

- In: `lib/core/notifications/` (scheduler, coordinator),
  `lib/core/prefs/prefs_repository.dart` (new keys),
  `lib/features/settings/notification_prefs.dart`,
  `lib/features/settings/notification_settings_screen.dart`,
  tests under `test/`.
- Out: everything else. Do not touch onboarding (meal mode is opt-in from
  settings only), feed, habits, journey, database schema, content JSON,
  widgetkit, critters.

## Requirements

1. **Settings model.** Extend `NotifSettings` + prefs with:
   - `mode`: `spread` (default — current behavior) | `meals`.
   - Per meal (breakfast, lunch, dinner): `enabled` (bool), `timeMin`
     (minutes from midnight), `count` (1–3).
   - Defaults: breakfast 08:00, lunch 13:00, dinner 19:00, all enabled,
     count 2. Existing users keep working untouched: missing prefs must
     resolve to `spread` mode with their current window/perDay values.
2. **Slot pattern.** In the scheduler (keep it a pure, testable function like
   `planSlots`), for each enabled meal with meal time T:
   - count 1 → T−20 min.
   - count 2 → T−60, T−15.
   - count 3 → T−60, T−15, T+30 (the after-meal slot is the *only* "after").
   - Apply deterministic seeded jitter of ±7 min per slot (same seeding style
     as the existing scheduler: seeded by epochDay and slot index, so a
     reschedule never moves already-planned times).
   - Skip slots whose time is already past "now" on the first day.
3. **Budget.** Total per day = sum of enabled meal counts (max 9). Reuse the
   existing iOS-64 budgeting approach: `daysAhead = clamp(60 ~/ totalPerDay, 3, 14)`.
   Stable notification ids must not collide with spread-mode ids (cancelAll on
   reschedule already runs — keep that behavior).
4. **Meal-aware quote choice.** Add the quote's category id to
   `SchedulableQuote`. For slots *before* a meal, prefer quotes from
   `staying_strong` and `why_vegan`; for the after-meal slot, prefer
   `youre_awesome`. "Prefer" means: pick from those categories when the user's
   current mix contains them and they have unused quotes; otherwise fall back
   to the normal mix selection. Verify the real category ids from the content
   JSON / database before hardcoding (the feed uses ids like `why_vegan`,
   `staying_strong`, `youre_awesome`).
5. **Coordinator.** `NotificationCoordinator.reschedule` picks the planner by
   mode. Settings changes must keep triggering an immediate forced replan
   (existing listener covers this — just make sure meal pref changes go through
   `notifSettingsProvider` so it fires).
6. **Settings UI.** In `NotificationSettingsScreen`:
   - A two-option mode selector (e.g. `SegmentedButton`): "Through the day" /
     "Around meals", visible only when notifications are enabled.
   - Spread mode shows the existing controls unchanged.
   - Meals mode shows three meal cards (Breakfast, Lunch, Dinner), each with:
     on/off switch, time (tap to open time picker), count selector 1–3.
   - Keep enabled meal times at least 2 hours apart — on conflict, adjust the
     other value like the existing window logic does, or block with a brief
     message; pick the simpler pattern consistent with the current screen.
   - If meals mode is on but all three meals are disabled, schedule nothing
     (equivalent to notifications off) and show a small hint text.
   - Follow the existing visual style of the screen (list tiles, slider/labels).
7. **Notification body** still carries the full quote text (watch mirroring —
   existing behavior, don't regress).
8. **Tests.**
   - Pure scheduler tests: pattern positions for counts 1/2/3, jitter bounded
     ±7 and deterministic across calls, past-slot skipping, budget/daysAhead,
     id stability, category preference with fallback when preferred categories
     are absent from the mix.
   - Prefs/notifier test: defaults + round-trip of new settings, legacy users
     resolve to spread mode.
   - Widget test: mode switch shows meal cards; toggling a meal updates state.
   - All existing tests stay green (`notification_scheduler_test.dart` must
     keep passing unchanged behavior for spread mode).

## Constraints

- Locked decisions hold (CLAUDE.md §3): offline-first; Riverpod/drift/go_router;
  home_widget untouched; no new packages.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries per
  CLAUDE.md §2).
- Spread mode behavior must be byte-for-byte unchanged for existing users —
  same slot times for the same settings as before this change.

## Verify

- `flutter analyze`
- `flutter test`
- Manual (open item for Ammar): switch to meals mode, set times/counts, check
  the pending notifications land around meals (e.g. via a debug print of the
  plan or OS notification settings), and that switching back to "Through the
  day" restores the old behavior.

## Commit & push

- Conventional Commit, e.g. `feat(notifications): meal-time mode with smart slot pattern`;
  body includes `Prompt: claude-prompts/2026-06-12/002-meal-time-notifications.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report

- Write `claude-reports/2026-06-12/002-meal-time-notifications.md` from
  `claude-reports/TEMPLATE.md`. Record intent, decisions (especially the
  meal-spacing UI rule you chose, id scheme, and how category preference
  interacts with the mix), verification results, commit SHA, push result, open
  items. No full diff.
