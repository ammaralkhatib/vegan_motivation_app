# Diagnose why daily quote notifications never fire

**Prompt:** `claude-prompts/2026-06-17/001-notification-diagnostic.md`
**Completed:** 2026-06-17 · **Status:** done

## Summary

Added a **temporary "Diagnostics (temporary)" section** to the bottom of
Settings → Notifications. It shows the real, runtime scheduling state (which we
cannot see from the source code) and gives four buttons, including two test
buttons that fire a notification the **two different ways** the app does. This
is throwaway debug code — every block is tagged
`// TEMP DIAGNOSTIC — remove after notif debug (prompt 2026-06-17/001)` so it is
trivial to find and delete once we know the cause. It is **not** hidden behind
debug mode, so it works in the TestFlight release build. Normal users see only
the one extra labelled section; nothing about real scheduling changed.

Analyze clean, all 178 tests green.

## Files touched

- `lib/core/notifications/notification_service.dart` — temp debug helpers:
  timezone name, "tz now", iOS `checkPermissions()` as text, a pending-list
  breakdown (quote/habit/trial/other + first 5), and the two test-schedule
  methods.
- `lib/core/notifications/notification_coordinator.dart` — wrapped
  `reschedule()` and `rescheduleHabits()` bodies in try/catch that
  `debugPrint`s the error + stack and swallows (behavior unchanged); added
  `debugComputePlan()` that returns the computed counts **without** scheduling.
- `lib/features/settings/notification_settings_screen.dart` — the
  `_DiagnosticsSection` widget (read-only card + Refresh + Force reschedule +
  two test buttons).

## What each number on the card means (plain English)

The card is a read-out of the app's real state right now:

- **enabled / mode / perDay / window** — your current notification settings.
  In meals mode it lists each meal's on/off, time, and count instead.
- **locale** — the language the app picks for notification text in the
  background (same rule the scheduler uses).
- **unlocked (N): …** — which quote categories you can use, and how many.
- **quotes in mix: N** — how many quotes are actually available to schedule
  from. If this is **0**, that is the bug (nothing to send).
- **plans now: N** — how many quote notifications the app would create right
  now. **first fires: …** are the next few send times. If this is **0**, the
  schedule is empty — the bug is in the data/timing path.
- **tz / tz now** — the time zone the app thinks the phone is in, and "now" in
  that zone. If this looks wrong or says UTC, that points at a time-zone bug.
- **iOS perms** — whether iOS allows alert / badge / sound.
- **pending total / pending: quote=… habit=… trial=… other=…** — how many
  notifications iOS currently has queued, split by type. The bug is most likely
  here: if **habit** is non-zero but **quote** is **0**, the quote schedule is
  not making it into iOS's queue.
- **first 5** — the first few queued items (id + title), to eyeball.

## What Ammar should do (the actual test)

1. Open the app → **Settings → Notifications**, scroll to the bottom to the red
   **"Diagnostics (temporary)"** section.
2. Tap **Refresh**, then **screenshot the card** and send it to me.
3. Tap **"Test one-shot (+20s)"**, then **"Test repeating-time (+~90s)"**.
4. **Lock the phone** (or switch to another app) and **wait ~2 minutes**.
5. Tell me **which** test notification(s) appeared:
   - **TEST one-shot** (fired the way *quote* notifications are scheduled), and/or
   - **TEST repeating** (fired the way *habit* reminders are scheduled).
6. Optional: tap **Force reschedule now**, then **Refresh** — the pending
   **quote** count should jump above 0 if a forced reschedule works.

### How to read the result

- **one-shot does NOT appear but repeating DOES** → iOS is not delivering our
  non-repeating quote triggers in this build (a delegate / scene setup issue),
  not our Dart logic.
- **both appear** → on-demand scheduling works, so the bulk quote schedule is
  either empty or throwing — the card's `quotes in mix` / `plans now` numbers
  and any `RESCHEDULE ERROR` in the device log will say which.
- **card shows `quotes in mix: 0` or `plans now: 0`** → we found it in the data
  path.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
All tests passed! (178)
```

Self-correction (1 of 2): the new card first used a spinner while loading, which
made the existing meal-mode widget test's `pumpAndSettle` time out (a spinner
animates forever). Replaced it with a plain "Loading…" text and wrapped the
async load in try/catch (so a missing DB provider in tests, or any runtime
error on device, shows as `ERROR: …` on the card instead of crashing). Re-ran:
analyze clean, all 178 tests green.

## Commit & push

- **Commit:** `a54b441` — `feat(notifications): add temporary scheduling diagnostics section`
- **Push:** `origin/main` — ok.

## Open items for the owner

- Run the on-device test above and report which test notification(s) appear.
- This is throwaway code — we revert all of it once the cause is found.

## Deviations from prompt

- The pending breakdown classifies our **test** ids (2000000001/2) as **other**
  (they sit far above every real band), so the test notifications don't inflate
  the `quote` count. Real quote ids (spread `<~1.6M`, meal `100M` band) still
  count as `quote`, as specified.
