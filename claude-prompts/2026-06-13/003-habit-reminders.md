# Habit reminders (one daily time per habit)

## Goal
Let a user set an optional daily reminder time on each habit. When set, the OS shows
a notification at that time every day with the habit's emoji + name (e.g. "🌱 Drink
water — time for your habit"). Off by default; the user turns it on per habit in the
habit edit screen. Tapping the reminder opens the app on the Habits screen. This is the
first habit-notification support — today habits schedule nothing.

"Done" = a user opens a habit, switches on "Daily reminder", picks a time, saves, and
gets a notification at that time each day. Turning it off (or archiving the habit)
stops it. Quotes and the trial reminder keep working unchanged.

## Scope
- In:
  - `lib/core/db/database.dart` (Habits table: add `reminderMinutes`; bump schema + migration)
  - `lib/core/db/daos/habit_dao.dart` (carry/clear the reminder field)
  - `lib/core/notifications/notification_service.dart` (schedule/cancel one daily habit reminder)
  - `lib/core/notifications/notification_coordinator.dart` (reschedule all habit reminders; keep quotes under the pending cap)
  - a small new pure helper for the habit notification id band + next-fire time (e.g. `lib/core/notifications/habit_reminder.dart`), mirroring `trial_reminder.dart`
  - `lib/features/habits/habit_edit_screen.dart` (reminder switch + time picker UI)
  - the notification tap handler (app layer — find where `NotificationService.instance.onTap` is set)
  - `lib/l10n/app_en.arb` (new UI strings)
  - generated files from `build_runner` (commit them)
- Out:
  - Quote scheduling math beyond the one pending-cap change described below.
  - Per-weekday reminders, snooze, or "skip if already done today" (explicitly later work).
  - Any RevenueCat / paywall / widget code.

## Background (read before coding)
- iOS caps pending local notifications at **64**. The quote scheduler already budgets
  up to ~60 (`notification_scheduler.dart`), and the trial reminder reserves 1
  (`trial_reminder.dart`, id `900000001`). There is almost no headroom, so habit
  reminders must (a) use as few pending slots as possible and (b) we must lower the
  quote budget to make room.
- Use **one daily-repeating** notification per habit (fires every day at the same
  local time) via `zonedSchedule(..., matchDateTimeComponents: DateTimeComponents.time)`.
  That is **one** pending slot per habit, not one per day.
- Notification id bands in use (keep habits clear of all of them): spread quotes
  `< ~1.6M`; meal quotes `100M–101.6M`; trial `900000001`.

## Requirements
1. **Schema.** Add `IntColumn get reminderMinutes => integer().nullable()();` to the
   `Habits` table (minutes from local midnight; `null` = no reminder). Bump
   `schemaVersion` 2 → 3 and add an `onUpgrade` step `if (from < 3) await
   m.addColumn(habits, habits.reminderMinutes);`. This is additive and must not touch
   any existing user data. Run `dart run build_runner build` and commit the generated
   `.g.dart` changes.

2. **DAO.** Add `Future<void> setHabitReminder(int id, int? minutes)` to `HabitDao`
   (writes `reminderMinutes`, allowing null to clear it). `insertHabit` keeps its
   current signature (new habits start with no reminder). `getActiveHabits` /
   `watchActiveHabits` already return the new column via the row — no change needed.

3. **Habit reminder helper** (new pure file, mirror `trial_reminder.dart`):
   - A reserved id band for habit reminders that cannot collide with the bands above,
     e.g. `int habitReminderNotificationId(int habitId) => 800000000 + habitId;`
     (habit ids are small autoincrement ints). Document the band in a comment.
   - `DateTime nextHabitFireTime(int reminderMinutes, DateTime now)` → today at that
     minute-of-day if still in the future, else tomorrow at that minute. Pure +
     unit-testable (no drift/plugin imports).

4. **NotificationService** — add three methods, matching the existing style:
   - `Future<void> scheduleHabitReminder({required int habitId, required String name,
     required String emoji, required int reminderMinutes})`: `zonedSchedule` a
     **daily-repeating** notification at `nextHabitFireTime(...)` with
     `matchDateTimeComponents: DateTimeComponents.time`, reusing the existing
     `_channelId` / details pattern. Title = `"$emoji $name"`; body = a localized
     "time for your habit" string. Payload = `"habit:$habitId"`. Wrap in try/catch
     like `scheduleTrialEndReminder` (best-effort, never throw to UI). No-op when the
     plugin isn't initialized / unsupported platform.
   - `Future<void> cancelHabitReminder(int habitId)`: `_plugin.cancel(habitReminderNotificationId(habitId))`.
   - `Future<void> rescheduleAllHabitReminders(List<({int id, String name, String emoji, int reminderMinutes})> habits)`:
     cancel each habit's id first, then schedule the ones with a reminder. Keep it
     simple and idempotent.
   - **Important:** `_cancelDailyNotifications()` (used by `scheduleAll`) currently
     cancels every pending id except the trial reminder — make sure it does **not**
     wipe habit reminders. Exclude the habit band (id `>= 800000000` and the trial id)
     from that loop so a quote reschedule never kills habit reminders.

5. **Pending budget.** Lower the quote pending count so quotes + trial + habit
   reminders stay ≤ 64. In `NotificationCoordinator.reschedule`, after building
   `plans` and before `service.scheduleAll`, sort by `fireAt` and cap the list to a
   single named constant `maxQuotePending = 50`. (Reserves 14 slots for trial + habit
   reminders.) Do not change the scheduler's internal math — just truncate the output.

6. **Reschedule habit reminders.**
   - Add `Future<void> rescheduleHabits()` to `NotificationCoordinator`: read
     `getActiveHabits()`, map to the record shape, call
     `service.rescheduleAllHabitReminders(...)`. Call this from the same places the
     quote reschedule already runs (app launch + resume — find the existing
     `coordinator.reschedule()` call sites and add `rescheduleHabits()` alongside).
   - In `habit_edit_screen.dart`, after saving a habit with a reminder change, schedule
     or cancel **that** habit's reminder directly via `NotificationService.instance`
     (don't force a full app-wide reschedule). On archive, call
     `cancelHabitReminder(id)`.

7. **Permission prompt.** When the user switches the reminder **on** for a habit that
   previously had none, call `NotificationService.instance.requestPermission()` once
   before scheduling (same method onboarding uses). If denied, still save the chosen
   time (the OS just won't show it) — do not block saving.

8. **Habit edit UI** (`habit_edit_screen.dart`). Below the emoji picker add a
   "Daily reminder" section: a `SwitchListTile` (off by default; on when the habit
   already has `reminderMinutes`). When on, show the chosen time and a button that
   opens `showTimePicker`. Persist on save: reminder on → `setHabitReminder(id,
   minutes)`; off → `setHabitReminder(id, null)`. For a brand-new habit, insert first
   to get the id, then set the reminder. Keep the layout consistent with the existing
   Material widgets on this screen.

9. **Tap routing.** Update the app-layer `onTap` handler that currently treats the
   payload as a quote id. Branch on the payload: `"habit:<id>"` → navigate to the
   Habits screen (use the existing go_router route for habits); anything else → keep
   the current quote behavior. A habit payload must never be parsed as a quote id.

10. **Strings.** Add UI strings to `lib/l10n/app_en.arb` only (English template;
    other ARBs land later per the locked l10n decision). Suggested keys:
    `habitsReminderSectionTitle` ("Daily reminder"),
    `habitsReminderSubtitle` ("Get a nudge at the same time each day"),
    `habitsReminderSetTime` ("Set time"),
    `notificationHabitBody` ("Time for your habit 🌱"). Use `AppLocalizations` in the
    notification body via the same `_notificationL10n(...)` pattern already in
    `notification_service.dart`.

## Constraints
- Offline-first, no backend (CLAUDE.md §3). All on-device; no network.
- Riverpod / drift / go_router only; follow existing provider + DAO patterns.
- `home_widget` stays < 0.8 — untouched here.
- Drift schema changed → run `dart run build_runner build` and commit generated files.
- `flutter analyze` clean; `flutter test` green. Self-correct up to 2 tries (CLAUDE.md §2);
  if still failing, commit nothing and write a `blocked` report.
- Add at least one unit test for `nextHabitFireTime` (today-vs-tomorrow boundary) and
  for `habitReminderNotificationId` staying outside the quote/trial/meal bands.

## Verify
- `flutter analyze` and `flutter test` both pass (paste the tail of each in the report).
- Manual click-path for Ammar to run on a device/emulator:
  1. Open a habit → turn on Daily reminder → set a time 2 minutes out → save. Approve
     the permission prompt if asked.
  2. Wait — the notification fires with the habit emoji + name; tapping opens the
     Habits screen.
  3. Re-open the habit → turn the reminder off → save → no further notifications.
  4. Confirm quote notifications still arrive (turn habit reminder on for a couple of
     habits, confirm quotes keep coming — pending stays under the cap).

## Commit & push
- Conventional Commit, e.g. `feat(habits): add optional daily habit reminders`.
- Body includes `Prompt: claude-prompts/2026-06-13/003-habit-reminders.md`.
- Push to origin/main; on failure stop and report (never force).

## Report
- Write `claude-reports/2026-06-13/003-habit-reminders.md` from `TEMPLATE.md`
  (`mkdir -p` the folder). Record intent, key decisions (id band, pending cap of 50,
  daily-repeat approach), the `flutter analyze` / `flutter test` results, the commit
  SHA, push result, and these known limitations to carry forward:
  (a) a reminder still fires even if the habit is already checked off that day;
  (b) only the first ~13 habit reminders are guaranteed a pending slot if a user sets
  a very large number of them. No full diff.
