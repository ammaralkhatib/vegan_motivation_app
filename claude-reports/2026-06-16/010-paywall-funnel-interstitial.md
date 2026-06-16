# Add a short interstitial between the two onboarding paywalls

**Prompt:** `claude-prompts/2026-06-16/010-paywall-funnel-interstitial.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Inserted a brief (~1.2 s) non-dismissible loading interstitial between the
onboarding paywall and the discount "last chance" paywall, so the second offer
reads as a new, separate screen instead of looking like the first one flickering.
The interstitial only appears on the branch that actually shows the discount
paywall; the premium early-return and the already-shown path are unchanged.
Analyze clean, all 178 tests green.

## Files touched

- `lib/features/paywall/onboarding_paywall_funnel.dart` — added `_showInterstitial`
  (push transient `MaterialPageRoute` → `Future.delayed(1200ms)` → pop, each gap
  guarded by `if (!context.mounted) return;`) and the private `_PaywallInterstitial`
  widget; called it between `setDiscountOfferShown(true)` and the discount paywall.
- `lib/l10n/app_en.arb` (+ de/es/fr) — new `paywallInterstitialMessage` key.
- `test/onboarding_funnel_test.dart` — pump past the interstitial in the free-user
  test (the indeterminate spinner would hang `pumpAndSettle`).

## Decisions

- **Added the message string** (`paywallInterstitialMessage`): EN "one moment…",
  DE "Einen Moment …", ES "un momento…", FR "un instant…". Shown under the
  spinner. (The prompt allowed spinner-only; a calm line reads nicer.)
- **Ordering preserved.** `setDiscountOfferShown(true)` still runs *before* the
  interstitial and the discount paywall, so the "once ever, even across a crash"
  guarantee holds.
- **Transient Navigator route, not go_router** — per the prompt; the interstitial
  is intentionally not a routable destination.
- **Non-dismissible** via `PopScope(canPop: false)`; it always auto-dismisses
  after the 1.2 s delay (the funnel pops it).
- **Test pumping.** The interstitial's indeterminate `CircularProgressIndicator`
  animates forever, so `pumpAndSettle` would hang. The free-user test now pumps
  fixed steps (1.3 s for the delay + two 0.35 s steps for the pop-out/push-in
  transitions) until the interstitial is gone, then asserts the discount paywall.
  The premium and already-shown tests don't hit the interstitial and were left
  as-is. `onboarding_story_test` runs the funnel as a premium user (early return),
  so it's unaffected.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
All tests passed! (178)
```

Ran `flutter gen-l10n` after the ARB edit (generated files are git-ignored).
Self-correction: none needed (passed first try).
Manual click-path: [ ] not run by Claude Code — Ammar to confirm: finish
onboarding as a free user → onboarding paywall → dismiss → spinner appears
briefly → discount paywall; and a premium user (or already-shown path) sees no
interstitial and no second paywall.

## Commit & push

- **Commit:** `38efee0` — `feat(paywall): add interstitial between onboarding and discount paywalls`
- **Push:** `origin/main` — ok

## Open items for the owner

- Visual click-path verification (free user sees the spinner break; premium /
  already-shown users see nothing extra).

## Deviations from prompt

None.
