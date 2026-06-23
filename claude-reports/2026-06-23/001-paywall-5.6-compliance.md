# Paywall 5.6 compliance — kill the exit discount, opt-in home banner, instant close

**Prompt:** `claude-prompts/2026-06-23/001-paywall-5.6-compliance.md`
**Completed:** 2026-06-23 · **Status:** done

> Keep this short. Git holds the diff.

## Summary

Apple rejected the build under Guideline 5.6: the app pushed an 80%-off "last
chance" paywall when the user tried to **leave** the first paywall. I removed
that exit-intent behavior. Now finishing onboarding shows only the trial paywall,
and closing it goes straight into the app. The 80%-off offer still exists — it
just moved to a small, dismissible banner on the home screen that the user can
**choose** to tap (it never opens a paywall by itself). I also made every
paywall's close (X) button work on the first frame, with no 2-second delay.
`flutter analyze` is clean and all 186 tests pass.

## Files touched

- `lib/features/paywall/onboarding_paywall_funnel.dart` — funnel now just shows
  the trial paywall and returns; deleted the exit discount, the interstitial
  spinner, and the dead `discountOfferShown` write (the banner owns that now).
- `lib/features/paywall/paywall_screen.dart` — removed the close-button delay
  (timer/opacity/`IgnorePointer` gating); the X is always live.
- `lib/features/paywall/discount_banner.dart` — **new** opt-in discount banner.
- `lib/app/shell.dart` — mount the banner top-center, alongside the streak banner.
- `lib/l10n/app_en.arb` (+ `fr`/`es`/`de`) — added the 4 banner strings; removed
  the now-dead `paywallInterstitialMessage`. Regenerated `app_localizations*`.
- `test/onboarding_funnel_test.dart` — funnel now shows trial only, no discount.
- `test/paywall_screen_test.dart` — added "X tappable on first frame" (onboarding).
- `test/discount_banner_test.dart` — **new** banner gating + flag-once + CTA tests.

## Decisions

- **StreakBanner collision (Req 4): the discount banner yields to the streak
  banner.** Both want the top-center slot. The streak banner only appears on the
  first launch of a new day and auto-hides after a few seconds; the discount
  banner is persistent. Simplest clean rule: when the streak banner is showing
  this launch, the discount banner doesn't show — it reappears on a later launch.
  This avoids any overlap and avoids two pills fighting for the same spot.
  Documented in a code comment in `discount_banner.dart`.
- **One-time flag is set the first time the banner is actually shown**, via a
  post-frame callback, and the "show this session" decision is captured once in
  `initState` so setting the flag doesn't instantly re-hide the banner. Tapping
  the CTA or dismissing both leave the flag true, matching the old once-ever
  semantics.
- **Removed `paywallInterstitialMessage` entirely** (all 4 ARBs) since the
  interstitial it fed is gone — keeping a dead string around would mislead.

## Verification

```
$ flutter analyze
No issues found! (ran in 3.2s)

$ flutter test
00:07 +186: All tests passed!
```

Self-correction: none — clean on the first run.

Manual click-path (logic verified by the automated tests above; not run on a
device this session):
- [ ] Fresh install → finish onboarding → trial paywall → tap X → Today feed,
      no second paywall, no interstitial.
- [ ] Free user on Today → discount banner appears → tap it → 80% paywall opens;
      close it → banner gone; relaunch → still gone (`discountOfferShown` stuck).
- [ ] Open any paywall → X tappable immediately.

## Commit & push

- **Commit(s):** `486d577` (code) + this report commit — `fix(paywall): remove exit-intent discount, add opt-in discount banner, instant close (App Review 5.6)`
- **Push:** `origin/main` — ok.

## Open items for the owner

- **Device check before resubmitting.** Run the 3 click-paths above on a real
  device/simulator once, since I verified them via tests, not on hardware.
- **App Store Connect metadata (3.1.2c).** The EULA-link half of the rejection is
  yours to fix in the console — not a code change (per the prompt).
