# Notification defaults + move habit reminder toggle to the detail screen

## Goal
Three related notification changes Ammar asked for:
1. Spread mode: change the "per day" slider to range **1–12** with a new default of
   **6** (was 1–10, default 3).
2. Spread mode: change the default time window to **7:30 AM–9:30 PM** (was
   9:00 AM–9:00 PM).
3. Per-habit reminders: make the reminder **default ON** for new habits, and move
   the reminder toggle + time control **out of the edit-habit screen and onto the
   habit detail screen** (the stats/calendar screen). When a new habit is created
   (reminder now on by default), ask for notification permission so the reminder
   can actually fire.

"Done" looks like: a fresh install's spread settings start at 6/day and
7:30 AM–9:30 PM; creating a habit gives it a 9:00 AM daily reminder by default and
prompts for notification permission; the habit's detail screen has a "Daily
reminder" switch + time the user can change or turn off; the edit screen no longer
shows any reminder UI.

## Scope
- In:
  - `lib/core/prefs/prefs_repository.dart` — the three default values.
  - `lib/features/settings/notification_prefs.dart` — `setPerDay` clamp bound.
  - `lib/features/settings/notification_settings_screen.dart` — slider max/divisions.
  - `lib/core/notifications/notification_scheduler.dart` — `planSlots` perDay assert
    upper bound.
  - `lib/features/habits/habit_edit_screen.dart` — remove the reminder section;
    handle the default-on reminder + permission on create; reschedule on rename.
  - `lib/features/habits/habit_detail_screen.dart` — add the reminder switch + time.
  - Affected tests (Requirements 7).
- Out:
  - Meal mode (offsets, meal defaults, meal times) — untouched.
  - The app icon / notification icon — **not part of this change** (Ammar is
    verifying it's an iOS icon-cache artifact first; no code change).
  - The notification scheduling internals beyond the perDay bound (jitter, ids,
    quote selection) — untouched.

## Requirements
1. **Per-day default + range.** In `prefs_repository.dart`, `notifPerDay` default
   `3` → `6`. In `notification_settings_screen.dart`, the spread slider `max: 10` →
   `12` and `divisions: 9` → `11` (so every integer 1–12 is selectable). In
   `notification_prefs.dart`, `setPerDay`'s `value.clamp(1, 10)` → `clamp(1, 12)`.
2. **planSlots bound.** In `notification_scheduler.dart`, the
   `assert(perDay >= 1 && perDay <= 10)` → `<= 12`. Confirm the iOS-64 budgeting
   still holds: at perDay 12, `daysAhead = (60 ~/ 12).clamp(3,14) = 5`, so
   12 × 5 = 60 pending ≤ 64 — fine. Update the doc-comment numbers that mention the
   old 10 cap so they match.
3. **Window default.** In `prefs_repository.dart`, `notifWindowStart` default
   `9 * 60` → `7 * 60 + 30` (450 = 7:30 AM) and `notifWindowEnd` default `21 * 60` →
   `21 * 60 + 30` (1290 = 9:30 PM). Update the `// Default 9:00–21:00` comment to
   `7:30–21:30`. (The 2-hour-minimum window logic in the settings screen is
   unchanged.)
4. **Habit reminder defaults ON for new habits.** In `habit_edit_screen.dart`, a
   newly created habit gets a reminder at the existing `_defaultReminderMinutes`
   (9:00 AM) **by default**, even though the toggle UI is gone from this screen.
   Concretely: when `_isNew`, on save, insert the habit, then
   `setHabitReminder(habitId, _defaultReminderMinutes)`, **request notification
   permission** (`NotificationService.instance.requestPermission()` — "ask at
   creation"), and `scheduleHabitReminder(...)`. Existing habits keep whatever
   reminder they already have.
5. **Remove the reminder UI from the edit screen.** Delete the reminder
   `SwitchListTile` + the time `TextButton` and the `_pickTime` / `_reminderMinutes`
   state from `habit_edit_screen.dart`. The edit screen keeps name, emoji, archive.
   **But** when an existing habit is renamed/re-emoji'd and it has a reminder, the
   scheduled reminder must be re-scheduled so the notification's title (`$emoji
   $name`) updates — i.e. on save of an existing habit, if its `reminderMinutes`
   is non-null, call `scheduleHabitReminder` with the new name/emoji (no permission
   prompt for an existing reminder). Archiving still cancels the reminder (unchanged).
6. **Add the reminder control to the detail screen.** In `habit_detail_screen.dart`,
   add a "Daily reminder" card (reuse the `habitsReminderSectionTitle` /
   `habitsReminderSubtitle` / `habitsReminderSetTime` l10n keys):
   - A switch whose value is `habit.reminderMinutes != null`.
   - Turning it **on**: set the reminder to `_defaultReminderMinutes` (9:00 AM) via
     `habitDao.setHabitReminder`, request permission the first time (only when
     turning on from off), and `scheduleHabitReminder` with the habit's name/emoji.
   - Turning it **off**: `setHabitReminder(id, null)` + `cancelHabitReminder(id)`.
   - When on, show a time button (like the old edit-screen one) that opens
     `showTimePicker`, persists the new minutes, and reschedules.
   - The screen already watches `habitProvider(widget.habitId)`, so the switch/time
     reflect DB changes reactively — persist, don't hold local state that can drift.
7. **Tests.**
   - Update `notification_scheduler_test.dart` (and `meal_scheduler_test.dart` if it
     shares the bound) for the new perDay upper bound of 12 — e.g. any test asserting
     the old `<= 10` limit, and add/adjust a case at perDay 12 confirming
     ≤ 64 pending.
   - `notif_meal_settings_test.dart` / any settings test asserting the old default
     of 3 or window 9:00–21:00 → update to 6 and 7:30–21:30.
   - Add a focused test that a **new** habit is created with a non-null
     `reminderMinutes` (default-on), and a test of the detail-screen reminder toggle
     behavior (on → non-null + scheduled; off → null + cancelled) using the existing
     notification test seams if present. If habit screens have no widget-test
     harness, at minimum cover the DAO-level default-on behavior.
   - Keep everything else green.
8. `flutter analyze` clean; `flutter test` green.

## Constraints
- Locked decisions (CLAUDE.md §3): offline-first; Riverpod / drift / go_router.
  Persist reminder changes through `habitDao` + `NotificationService` (the existing
  seams) — no new persistence path.
- Reminder scheduling stays best-effort (never throw to UI); permission denial just
  means the OS drops the reminder, as today.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries,
  CLAUDE.md §2). Run l10n codegen only if you add ARB keys (prefer reusing the
  existing `habitsReminder*` keys — no new copy expected).
- Plain simple English in the report (CLAUDE.md §0).

## Verify
- `flutter analyze` (clean) and `flutter test` (green) incl. the updated tests.
- Manual click-path to record:
  1. Fresh install → Settings → Notifications → spread mode shows **6/day** and
     **7:30 AM–9:30 PM**; slider goes up to 12.
  2. Create a new habit → it gets a 9:00 AM reminder by default and the app asks for
     notification permission.
  3. Open a habit → detail screen has a "Daily reminder" switch + time; turn it off
     (reminder cancelled), back on (rescheduled), change the time (rescheduled).
  4. The edit-habit screen no longer shows any reminder UI; renaming a habit that has
     a reminder updates the reminder's title.

## Commit & push
- Conventional Commit (e.g. `feat(notifications): new spread defaults (6/day,
  7:30–21:30), habit reminders default on + moved to detail screen`); body includes
  `Prompt: claude-prompts/2026-06-23/003-notif-defaults-and-habit-reminder-move.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-23/003-notif-defaults-and-habit-reminder-move.md`
  from TEMPLATE.md (`mkdir -p` the folder). Record intent, decisions (esp. the
  rename-reschedule handling and the create-time permission prompt), verification
  results, commit SHA, push result, and open items. No full diff.
