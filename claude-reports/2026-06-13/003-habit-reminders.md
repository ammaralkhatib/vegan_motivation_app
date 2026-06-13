# Habit reminders (one daily time per habit)

**Prompt:** `claude-prompts/2026-06-13/003-habit-reminders.md`
**Completed:** 2026-06-13 · **Status:** done

## Summary

Added an optional daily reminder time to each habit. In the habit edit screen
there is now a "Daily reminder" switch (off by default) with a time picker. When
on, the OS shows one notification each day with the habit's emoji + name; tapping
it opens the Habits screen. Turning the switch off, or archiving the habit, stops
it. Quote and trial notifications keep working — to stay under the iOS 64 pending
cap, the quote schedule is now truncated to the 50 soonest slots, leaving room for
the trial reminder + habit reminders. `flutter analyze` clean, `flutter test`
green (166 tests).

## Files touched

- `lib/core/db/database.dart` — added nullable `reminderMinutes` column to
  `Habits`; bumped `schemaVersion` 2 → 3 with an additive `from < 3` migration.
- `lib/core/db/database.g.dart` — drift codegen for the new column (committed).
- `lib/core/db/daos/habit_dao.dart` — new `setHabitReminder(id, minutes?)`.
- `lib/core/notifications/habit_reminder.dart` — new pure helper: reserved id
  band (`800000000 + habitId`) + `nextHabitFireTime(...)` (today-vs-tomorrow).
- `lib/core/notifications/notification_service.dart` — `scheduleHabitReminder`
  (daily-repeating via `matchDateTimeComponents: DateTimeComponents.time`),
  `cancelHabitReminder`, `rescheduleAllHabitReminders`; `_cancelDailyNotifications`
  now skips the trial id **and** the habit band so a quote reschedule never wipes
  habit reminders.
- `lib/core/notifications/notification_coordinator.dart` — `maxQuotePending = 50`
  cap on the quote schedule; new `rescheduleHabits()`.
- `lib/app/app.dart` — tap routing branches on payload (`habit:<id>` → `/habits`,
  else quote); calls `rescheduleHabits()` alongside `reschedule()` on launch +
  resume.
- `lib/features/habits/habit_edit_screen.dart` — reminder switch + time picker;
  save schedules/cancels that habit's reminder directly; archive cancels it;
  permission requested once when first turning a reminder on.
- `lib/l10n/app_en.arb` (+ `app_de/fr/es.arb`) — 4 new strings (see deviation).
- `test/habit_reminder_test.dart` — new unit tests (next-fire boundary, id band).
- `test/quote_translations_test.dart` — migration test fixture updated for v3.

## Decisions

- **Habit id band = `800000000 + habitId`** — sits clear of all bands in use
  (spread < ~1.6M, meal 100M–101.6M, trial 900000001) and below it. Documented in
  the helper.
- **Pending cap of 50** — exactly as the prompt specified; truncates the soonest
  quote slots only, leaving 14 slots for trial + habit reminders.
- **Daily-repeat approach** — one pending slot per habit using
  `DateTimeComponents.time`, anchored at `nextHabitFireTime(...)`, so each habit
  costs one slot, not one per day.
- **Default reminder time 9:00 AM** when the switch is first turned on (prompt
  left the default unspecified); the user can adjust via the time picker.

## Verification

```
$ flutter analyze
No issues found! (ran in 1.6s)

$ flutter test
00:05 +166: All tests passed!
```

Self-correction: fixed two failures before committing — (1) regenerated
`AppLocalizations` via `flutter gen-l10n` so the new string getters resolved;
(2) the v1→v3 migration test hit a "duplicate column" error (the test creates the
DB at the current schema, so `reminder_minutes` already existed when it rolled
back to v1) — updated the rollback to also drop that column so the migration is
exercised honestly.

Manual click-path for Ammar (device/emulator):
- [ ] Open a habit → turn on Daily reminder → set a time ~2 min out → save
      (approve the permission prompt if asked) → notification fires with the
      habit emoji + name; tapping opens Habits.
- [ ] Re-open the habit → turn the reminder off → save → no further notifications.
- [ ] Turn reminders on for a couple of habits → confirm quote notifications still
      arrive (pending stays under the cap).

## Commit & push

- **Commit(s):** `f511ecb` — `feat(habits): add optional daily habit reminders`
- **Push:** `origin/main` — ok (`0aead40..f511ecb`)

## Open items for the owner

- Schema migrated 2 → 3 (additive, no user data touched). On-device upgrade runs
  automatically on first launch of this build.

## Deviations from prompt

- **Strings added to all four ARBs, not en-only.** The prompt (and the locked
  l10n decision) say add UI strings to `app_en.arb` only. But the existing
  `test/l10n_parity_test.dart` is a hard gate requiring `de`/`fr`/`es` to carry
  exactly the same keys as `en`. En-only would fail that test, so per CLAUDE.md §2
  (keep tests green) I added the same 4 keys to `app_de/fr/es.arb` with real
  translations. This is consistent with the spirit of the locked decision (UI
  strings are localized; quote *content* is not). Flag for Planning Claude: the
  "en-only" instruction in future prompts conflicts with this test — either the
  test should allow en-ahead-of-translations, or prompts should expect all-locale
  key additions.

## Known limitations (carry forward)

- A reminder still fires even if the habit is already checked off that day
  ("skip if done today" is explicitly later work).
- Only ~13 habit reminders are guaranteed a pending slot (50 quotes + 1 trial +
  ~13 habits ≈ 64). A user who sets a very large number of reminders may not get
  every one scheduled on iOS.
