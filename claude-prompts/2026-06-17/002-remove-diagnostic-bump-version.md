# Remove the temporary notification diagnostic + bump build number for release

## Goal
The daily-quote notification problem is solved (both test notifications fired on
device — the earlier silence was stale build state). Now make the app
release-clean: **completely remove the temporary diagnostic** added in prompt
`2026-06-17/001` (it must NOT ship to the App Store), and **bump the build
number** so the next TestFlight upload is accepted. "Done" = no diagnostic code
or markers remain anywhere, the notification settings screen looks exactly as it
did before prompt 001, `flutter analyze` is clean, `flutter test` is green, and
`pubspec.yaml` shows the new version.

## Scope
- In:
  - `lib/features/settings/notification_settings_screen.dart` — remove the
    "Diagnostics (temporary)" section and any helpers it added.
  - `lib/core/notifications/notification_service.dart` — remove the temporary
    debug helpers (pending-breakdown, `checkPermissions` readout, tz-name getter,
    the two test-schedule methods).
  - `lib/core/notifications/notification_coordinator.dart` — remove the temporary
    debug method; **keep the try/catch error logging ONLY if it does not change
    behavior** — actually remove it too, to return the file to its original state
    (see Requirement 2).
  - `pubspec.yaml` — version bump (one line).
- Out: do not change real notification behavior, scheduling logic, onboarding,
  prefs, icons, or anything else.

## Requirements
1. **Remove every trace of the diagnostic.** Delete all code added by prompt
   `2026-06-17/001`. The reliable check: after your edits,
   `grep -rn "TEMP DIAGNOSTIC" lib/` must return **nothing**. The three touched
   files must read exactly as they did before prompt 001 (compare against the
   commit just before the 001 diagnostic commit — `git log` to find it; a
   `git revert` of the 001 commit(s) is acceptable if it lands cleanly, otherwise
   remove by hand and verify the diff).
2. **Restore original `reschedule()` / `rescheduleHabits()`.** Remove the
   temporary try/catch + `debugPrint` you added; the methods must match their
   pre-001 form. (We don't want surprise error-swallowing in release.)
3. **Notification settings screen unchanged from before 001.** The screen shows
   only the real controls (master switch, mode, per-day, window / meals). No
   diagnostics card, no test buttons, no "force reschedule" button.
4. **Bump the build number.** In `pubspec.yaml`, set the version to
   `1.0.1+3` (keep the name `1.0.1`, raise the build number from `+2` to `+3`).
   The build number must be higher than any build already uploaded to
   App Store Connect; if `+3` is ever rejected as already-used, the next run bumps
   again.
5. **Gates green.** `flutter analyze` clean and `flutter test` green before
   committing. Confirm the test count is back to the pre-001 baseline (no leftover
   diagnostic tests).

## Acceptance
- `grep -rn "TEMP DIAGNOSTIC" lib/` → no matches.
- `git diff` of the three code files vs the pre-001 state → effectively empty
  (only real code remains).
- `pubspec.yaml` shows `version: 1.0.1+3`.
- analyze clean, tests green.

## Report (plain English, CLAUDE.md §0)
State clearly: the diagnostic is fully removed, the three files are back to
normal, the version is now 1.0.1+3, and analyze/tests pass. One line on how you
removed it (revert vs by-hand) so Ammar can trust it's clean.
