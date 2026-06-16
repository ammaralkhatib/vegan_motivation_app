# Redesign the onboarding notifications step + denial education screen

**Prompt:** `claude-prompts/2026-06-16/009-notifications-step-redesign.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Rebuilt the onboarding notifications step (S26) to match the reference: headline +
subtitle, a decorative notification preview card, a −/+ amount stepper, start/until
time rows, and a full-width "allow & save" button. The button asks for the OS
permission and saves the chosen settings; on **denial** it shows a friendly
education soft-wall (turn on / continue without — never a hard block), then the
flow advances either way. The duplicate permission/save work was removed from
`_finish`. Analyze clean, all 178 tests green.

## Files touched

- `lib/features/onboarding/onboarding_flow.dart` — new `_notificationsStep`
  (preview card + stepper + time rows), `_allowAndSaveNotifications` handler,
  `_pickNotifWindow` (≥2h guard), `_fmtTime`, new state fields
  (`_notifPerDay`/`_notifWindowStart`/`_notifWindowEnd`) seeded in `initState`
  from `notifSettingsProvider`, a `_NotifPreviewCard` widget, and the trimmed
  `_finish`.
- `lib/features/onboarding/steps/notifications_education_screen.dart` (new) — the
  soft-wall.
- `lib/l10n/app_en.arb` (+ de/es/fr) — new keys, updated title/body, removed
  unused keys.
- `test/onboarding_story_test.dart` — updated the conclusion path for the new S26.

## Decisions

- **ARB keys.** Updated: `onboardingNotifTitle`, `onboardingNotifBody` (lowercase
  warm voice — "gentle reminders, all day" / "a few quotes spread across your
  day…"). Added: `onboardingNotifAmount`, `onboardingNotifStart`,
  `onboardingNotifUntil`, `onboardingNotifAllowSave`,
  `onboardingNotifPreviewSender`, `onboardingNotifPreviewSample`,
  `onboardingNotifNow`, `onboardingNotifEduTitle`, `onboardingNotifEduBody`,
  `onboardingNotifEduTurnOn`, `onboardingNotifEduContinue`,
  `onboardingNotifEduSettingsHint`. Reused existing `notificationsPerDayCount`
  ("{count}×") for the stepper value. **Removed** (checked: only the old step
  referenced them) `onboardingNotifEyebrow`, `onboardingNotifToggle`,
  `onboardingNotifPerDaySliderLabel`, `onboardingNotifPerDayValue` from all four
  ARBs. German uses natural capitalization; en/es/fr stay lowercase to match the
  brand voice.
- **No `_wantsNotifications` field.** Once `_finish` stopped touching
  notifications (Req 9), a flow `_wantsNotifications` field would be write-only
  (analyzer warning). The provider's `enabled` is the single source of truth, so
  the step calls `setEnabled(true)` and the education screen calls
  `setEnabled(false)` directly — functionally identical to what the prompt
  described, just without the redundant mirror field. (Minor, faithful deviation.)
- **Education screen escape behavior.** Always escapable: "continue without
  notifications" calls `setEnabled(false)` and pops; the caller then advances.
  "turn on notifications" re-requests permission — if granted it sets enabled and
  pops; if still denied it best-effort opens settings and the screen *stays open*
  so the user can come back and either flow works.
- **Settings deep-link per platform.** iOS: `launchUrl(Uri.parse('app-settings:'))`
  (the iOS app-settings scheme). Android / any failure: there's no reliable
  settings deep link via `url_launcher` without adding a package (out of scope),
  so we show a SnackBar hint ("open settings and allow notifications…") instead.
  No new package added.
- **Pushed via `Navigator.push`** (awaitable `MaterialPageRoute`) rather than a
  go_router route, so the handler can await it and advance on return without
  touching `router.dart` (out of scope).

## Verification

```
$ flutter analyze
No issues found! (ran in 2.7s)

$ flutter test
All tests passed! (178)
```

Ran `flutter gen-l10n` after the ARB edits (generated files are git-ignored).
Test updated: `onboarding_story_test.dart` — S26 now taps "allow & save"; since
the plugin isn't initialized in tests `requestPermission()` returns false, so the
education screen appears and the test escapes via "continue without notifications".
Self-correction: none needed (passed first try).

## Commit & push

- **Commit:** `6e92ba7` — `feat(onboarding): redesign notifications step + add permission education screen`
- **Push:** `origin/main` — ok

## Open items for the owner

On-device confirmation (I can't drive the OS permission dialog or settings):
- **Grant path:** tap "allow & save", grant → flow advances to S27.
- **Deny path:** deny → education screen appears; "continue without notifications"
  advances; "turn on notifications" re-prompts.
- **iOS settings deep-link:** after a hard denial on iOS, "turn on notifications"
  should open the app's settings page (`app-settings:`) — please confirm on a real
  device. On Android it shows the hint SnackBar (no deep link).
- **German:** switch device language to German and confirm the step + education
  screen read naturally.

## Deviations from prompt

- Dropped the `_wantsNotifications` flow field in favor of the provider's
  `enabled` (see Decisions) — same behavior, avoids an unused-field warning.
