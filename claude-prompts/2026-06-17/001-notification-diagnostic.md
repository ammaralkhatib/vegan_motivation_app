# Diagnose why daily quote notifications never fire (habit reminders work)

## Goal
On Ammar's iPhone, **habit reminder** notifications arrive, but the **daily
motivation (quote)** notifications never do — even though the in-app "Daily
motivation" switch is ON, iOS permission is granted, and he did a clean
reinstall. Both kinds are scheduled through the same `zonedSchedule` call, so
the cause is **runtime state we cannot see from the source** (is the plan empty?
is `reschedule()` throwing? are the one-shot notifications being created but
dropped by iOS?).

Add a **temporary, clearly-labelled diagnostic section** to the notification
settings screen that shows the real scheduling state, plus **two test buttons**
that fire a notification the two different ways the app does. "Done" = Ammar can
open Settings → Notifications, scroll to a "Diagnostics (temporary)" section,
screenshot the numbers, tap the two test buttons, and report which test
notification(s) appear. **This is throwaway code — we revert it once we find the
cause.**

## Scope
- In:
  - `lib/features/settings/notification_settings_screen.dart` — add the temporary
    diagnostics section at the bottom of the list.
  - `lib/core/notifications/notification_service.dart` — add temporary debug
    helpers (pending requests + breakdown, iOS `checkPermissions`, the timezone
    name, two test-schedule methods).
  - `lib/core/notifications/notification_coordinator.dart` — wrap the body of
    `reschedule()` (and `rescheduleHabits()`) in try/catch that `debugPrint`s any
    error + stack; add a debug method that returns the computed counts (quotes in
    mix, plan count, first few fire times) **without scheduling**.
- Out: do **not** change any scheduling behavior or the scheduler math
  (`notification_scheduler.dart`), prefs, onboarding, or the service's real
  schedule/cancel methods. Normal users must see no behavior change except the
  new visible section.

## Requirements
1. **Mark every addition temporary.** Each block you add carries the comment
   `// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)` so it
   is trivial to find and revert. Do **not** gate behind `kDebugMode` — it must
   work in the TestFlight **release** build — but place all of it under a clear
   "Diagnostics (temporary)" header so it obviously isn't a shipping feature.

2. **Read-only state readout** — a card at the bottom of the screen, one item per
   line:
   - `enabled`, `mode` (spread/meals), `perDay`, window start/end (formatted HH:mm)
   - meals mode: each meal's enabled + time + count
   - resolved locale code (use the same `resolveLanguageCode(prefs.languageOverride)`
     the coordinator uses)
   - unlocked category ids + their count
   - count of quotes from
     `quoteDao.getQuotesInMix(unlockedCategoryIds: unlocked, locale: locale)`
   - number of plans the coordinator would schedule right now (run the same
     `planSlots` / `planMealSlots` with `now = DateTime.now()`), and the first 3
     plan fire times (formatted, local)
   - `tz.local.name` and `tz.TZDateTime.now()` (to catch a wrong / UTC timezone)
   - iOS permission status from the plugin's `checkPermissions()` (alert / badge /
     sound)
   - pending notifications: total from `pendingNotificationRequests()`, broken
     down into **quote / habit / trial / other** using the existing id rules
     (`trialReminderNotificationId`, `isHabitReminderNotificationId`, the meal id
     base `100000000`, else quote), and list the first 5 (id + title).
   Add a **"Refresh"** button that recomputes the card.

3. **"Force reschedule now"** button — calls
   `ref.read(notificationCoordinatorProvider).reschedule(force: true)` then
   refreshes the card. This proves whether a forced reschedule actually creates
   pending quote notifications.

4. **Two test buttons** (the key test — fire a notification the two ways the app
   does it):
   - **"Test one-shot (+20s)"** — schedule ONE notification ~20 seconds out using
     a plain `zonedSchedule` with **no** `matchDateTimeComponents` (exactly how
     **quote** notifications are scheduled). Title `TEST one-shot`. Use a fixed
     test id well outside the quote/habit/trial ranges (e.g. `2000000001`).
   - **"Test repeating-time (+~90s)"** — schedule ONE notification ~90 seconds out
     using `matchDateTimeComponents: DateTimeComponents.time` (exactly how
     **habit** reminders are scheduled). Title `TEST repeating`. Fixed test id
     (e.g. `2000000002`).
   Both use the same `NotificationDetails` the app already uses
   (`DarwinNotificationDetails()` for iOS). After a tap, show a snackbar telling
   Ammar to lock the phone / background the app and wait.

5. **Catch + log reschedule errors.** Wrap the body of
   `NotificationCoordinator.reschedule()` in try/catch; on error
   `debugPrint('RESCHEDULE ERROR: $e\n$st')` then swallow (do not rethrow — keep
   behavior unchanged). Same for `rescheduleHabits()`. Keep the TEMP comment.

6. **No new packages.** Use what's already in the repo (flutter_local_notifications,
   timezone). Keep imports tidy.

7. **Plain-English report** (CLAUDE.md §0). In the report, explain in simple words
   what each number on the card means and exactly what Ammar should do:
   open Settings → Notifications, scroll down, screenshot the card, tap both test
   buttons, lock the phone, wait ~2 minutes, and report **which** test
   notification(s) appeared.

## Acceptance
- `flutter analyze` clean; `flutter test` green.
- No behavior change for normal users beyond the extra temporary section.
- Each test button schedules exactly one notification; after "Refresh" the
  pending list reflects them.

## Why this design (for the reviewer)
The two test buttons isolate the cause fast:
- If **one-shot does NOT appear** but **repeating DOES** → the problem is iOS
  delivery of non-repeating triggers in this build (ties to the UIScene /
  notification-delegate setup), not our Dart logic.
- If **both appear** → on-demand scheduling works, so the bulk quote schedule is
  either producing an **empty plan** or **throwing** — the card's plan/quote
  counts and the `RESCHEDULE ERROR` log will say which.
- If the card shows **quotes = 0** or **plans = 0** → we found it in the data path.
