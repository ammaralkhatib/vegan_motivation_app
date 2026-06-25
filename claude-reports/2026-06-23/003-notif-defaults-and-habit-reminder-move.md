# Notification defaults + move habit reminder toggle to the detail screen

**Prompt:** `claude-prompts/2026-06-23/003-notif-defaults-and-habit-reminder-move.md`
**Completed:** 2026-06-23 · **Status:** done

## Summary

Three notification changes. (1) Spread mode now defaults to **6 notifications/day**
on a slider that goes **1–12** (was 1–10, default 3). (2) The default time window is
now **7:30 AM–9:30 PM** (was 9:00–21:00). (3) Per-habit reminders are now **on by
default** for new habits, and the reminder switch + time control **moved off the edit
screen and onto the habit detail screen** (the stats/calendar screen). Creating a
habit also asks for notification permission so the reminder can fire. `flutter
analyze` is clean and all 172 tests pass.

## Files touched

- `lib/core/prefs/prefs_repository.dart` — new spread defaults: perDay 6, window
  450–1290 min (7:30–21:30); updated the default comment.
- `lib/features/settings/notification_prefs.dart` — `setPerDay` clamp upper bound
  10 → 12.
- `lib/features/settings/notification_settings_screen.dart` — spread slider `max`
  10 → 12, `divisions` 9 → 11 (every integer 1–12 selectable).
- `lib/core/notifications/notification_scheduler.dart` — `planSlots` assert upper
  bound 10 → 12; refreshed the iOS-64 budgeting doc-comment.
- `lib/features/habits/habit_edit_screen.dart` — removed the reminder switch / time
  UI and its state; new habits get a default-on 9:00 AM reminder + permission prompt;
  renaming an existing habit with a reminder reschedules it (no permission prompt).
- `lib/features/habits/habit_detail_screen.dart` — added the "Daily reminder" card
  (switch + time) that reads/writes the habit row through the DAO + NotificationService.
- `test/notification_scheduler_test.dart` — extended the cap test to perDay 1–12 and
  added a perDay-12 case (60 ≤ 64 pending).
- `test/notif_meal_settings_test.dart` — asserts the new spread defaults (6/day,
  7:30–21:30).
- `test/habit_reminder_move_test.dart` — new: new-habit default-on reminder, and the
  detail-screen switch toggling the stored reminder on/off.

## Decisions

- **Detail screen holds no local reminder state** — the switch/time read straight
  from the watched `habit` row, so they reflect DB changes reactively and can't drift
  (matches Requirement 6's instruction).
- **Rename-reschedule reads the pre-save reminder from `_existing`** — the edit screen
  no longer tracks reminder state, so on save of an existing habit it reuses the
  already-loaded `_existing.reminderMinutes` to decide whether to reschedule the
  notification title (`$emoji $name`). No permission prompt there — the reminder
  already exists.
- **Permission prompt at creation** — `requestPermission()` is called once when a new
  habit is inserted (and once when the detail switch goes off → on). Denial is
  harmless: the OS just drops the reminder, as before.
- **Kept the cap test at ≤ 64 (not ≤ 60)** — at perDay 12 the budget is exactly 60
  pending (5 days × 12), still inside Apple's 64 cap, so I asserted against the real
  hardware limit and added an exact-60 check for perDay 12.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.0s)

$ flutter test
00:08 +172: All tests passed!
```

Self-correction: fixed an `unnecessary_underscores` lint in the new test on the
first re-run (2-argument route builders use `(_, _)`); re-ran analyze clean.

Manual click-path (needs a device/simulator — not run here):
- [ ] Fresh install → Settings → Notifications → spread shows 6/day, 7:30 AM–9:30 PM,
  slider to 12.
- [ ] Create a habit → 9:00 AM reminder by default + permission prompt.
- [ ] Open a habit → "Daily reminder" switch + time; off cancels, on reschedules,
  changing the time reschedules.
- [ ] Edit screen shows no reminder UI; renaming a habit with a reminder updates the
  notification title.

## Commit & push

- **Commit:** `<filled after commit>` — `feat(notifications): new spread defaults
  (6/day, 7:30–21:30), habit reminders default on + moved to detail screen`
- **Push:** `origin/main` — `<filled after push>`

## Open items for the owner

- The manual click-path above should be run once on a real iOS/Android device
  (notification permission + scheduling can't be exercised in unit/widget tests —
  `NotificationService` is a no-op without a live plugin).

## Deviations from prompt

None.
