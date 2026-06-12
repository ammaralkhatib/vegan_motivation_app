# Onboarding Story — Part 3: Conclusion + paywall polish

**Prompt:** `claude-prompts/2026-06-12/009-onboarding-conclusion-paywall.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Closed the onboarding story. After the day-1 streak the flow now runs: a
fake-loading transition → a personalized 30-day plan summary → a commitment
question → a tailored response → a motivation snapshot → the (reframed)
notifications step → an honest social-proof screen → the existing paywall funnel
→ `/today`. Two paywall-polish items shipped too: the onboarding/discount paywalls
fade their close button in after 2 s, and a successful **trial** purchase schedules
a "your trial ends tomorrow" local notification 6 days out. The full 27-step story
runs end to end. Analyze clean, all 128 tests pass (4 new). No new packages.

## Files touched

- `lib/features/onboarding/onboarding_flow.dart` — replaced the temporary
  notifications tail with S21–S27; reframed the notifications step; saves
  `commitmentLevel` in `_finish()`.
- `lib/features/onboarding/steps/loading_step.dart` (new) — S21.
- `lib/features/onboarding/steps/plan_summary_step.dart` (new) — S22.
- `lib/features/onboarding/steps/snapshot_step.dart` (new) — S25.
- `lib/features/onboarding/onboarding_copy.dart` — commitment options + response
  copy + bar fills (S23/24/25).
- `lib/core/prefs/prefs_repository.dart` — new `commitmentLevel` key.
- `lib/features/paywall/paywall_screen.dart` — 2 s delayed close (onboarding/
  discount only) + trial-reminder hook on purchase success.
- `lib/core/notifications/trial_reminder.dart` (new) — pure decision helpers +
  reserved id.
- `lib/core/notifications/notification_service.dart` — `scheduleTrialEndReminder`
  and a targeted cancel that preserves the reserved reminder.
- `test/trial_reminder_test.dart` (new); `test/onboarding_story_test.dart` +
  `test/onboarding_funnel_test.dart` updated.

## Decisions

- **Loading step auto-advances via an `active` flag** (same pattern as the streak
  step): a 3.5 s controller drives the % and checklist, and `onDone` runs on
  completion. Under reduced motion it posts `onDone` after the frame (never
  navigates mid-build) — so tests and reduced-motion users skip straight through.
- **Trial reminder lives in `lib/core/notifications`** as pure helpers
  (`shouldScheduleTrialReminder`, `trialReminderFireTime`, a reserved id at 900M,
  well clear of the daily <1.6M and meal 100–101.6M ranges) plus a
  `NotificationService.scheduleTrialEndReminder`. The success path in
  `paywall_screen` calls it only for product `veggie_yearly_full`.
- **Reserved id survives daily reschedules.** `scheduleAll` used `cancelAll()`,
  which would wipe the reminder. I changed its internal cancel to skip the
  reserved id (cancel each pending id except the reminder), so the once-set trial
  reminder persists through every daily replan.
- **Close-button delay** is gated in `didChangeDependencies`: onboarding/discount
  variants start with the X hidden (`AnimatedOpacity` + `IgnorePointer`) and fade
  it in after 2 s; `defaultOffer` and reduced-motion show it immediately.
- **Social proof stays honest** — only factual chips (508 quotes, 6 critters,
  impact tracking) and the "no accounts, no ads, on your phone" line. No invented
  counts, ratings, or reviews.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.5s)

$ flutter test
All tests passed!   (128 tests; 4 new)
```

New/updated tests: the trial-reminder decision (trial → scheduled, 50%/80% → not;
fire time +6 days; reserved id range); the full vegan flow drives through all the
conclusion steps to `/today` and asserts `commitmentLevel` persists; the
never-fires-twice + curious-skip flows updated for the new tail; the funnel close
taps now disable animations so the 2 s gate doesn't block them.

Self-correction: none — analyze and tests were green on the first full run after
implementation.

Manual click-path (open item for Ammar):
- [ ] Fresh onboarding → loading → plan shows today+30 days → pick "just trying it
      out" → tailored copy → snapshot reflects answers → notifications → social
      proof → trial paywall (X appears after ~2 s) → close → 80% → close → `/today`.

## Open items for the owner

- The **trial reminder can only be verified after the RevenueCat dashboard setup**
  (real products + a sandbox purchase of `veggie_yearly_full`). Until then the
  hook is in place but never triggers in a real purchase.
- "Skip if notification permission denied" is handled implicitly: the reminder is
  scheduled best-effort and the OS silently drops it without permission (matching
  the existing daily-notification behavior).
- Scope note: requirement 9 ("the purchase success path") was implemented in
  `paywall_screen.dart`'s success case (one call), since that's the only
  in-scope place the purchased product id is known; the rest of that file's change
  is the close-delay, as scoped.

## Deviations from prompt

None.
