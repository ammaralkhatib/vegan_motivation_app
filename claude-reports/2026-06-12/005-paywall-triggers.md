# Wire the paywall triggers

**Prompt:** `claude-prompts/2026-06-12/005-paywall-triggers.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Connected the paywalls to the app so real users meet them. Finishing onboarding
now shows the trial paywall; dismissing it while still free shows the 80% "last
chance" paywall exactly once ever; tapping locked content opens the 50% paywall
(the old placeholder sheet is gone); and Settings gained a "Restore purchases"
row. Premium users never see any paywall, and the 80% offer can never repeat —
it's gated by a persisted flag set *before* it shows. Analyze clean, all 91 tests
pass (11 new). No new packages, no schema changes.

## Files touched

- `lib/features/paywall/onboarding_paywall_funnel.dart` (new) —
  `runOnboardingPaywallFunnel()`: trial → (once-ever) discount, premium-aware.
- `lib/features/onboarding/onboarding_flow.dart` — `_finish()` sets
  `onboardingDone`, runs the funnel, then navigates to `/today`.
- `lib/core/prefs/prefs_repository.dart` — new `discountOfferShown` flag.
- `lib/core/purchases/restore_flow.dart` (new) — shared `performRestore()` +
  `restoreMessage()` used by both the paywall and Settings.
- `lib/features/paywall/paywall_screen.dart` — restore button now uses the shared
  helper.
- `lib/core/purchases/premium_gate.dart` — `showPremiumSheet` →
  `showPremiumPaywall`, body now opens the 50% paywall (resolved the `TODO(004)`).
- `lib/features/explore/explore_screen.dart` — calls the renamed function.
- `lib/features/settings/settings_screen.dart` — "Restore purchases" row
  (hidden when premium, next to the premium row).
- `lib/app/router.dart` — removed the done→`/today` auto-bounce (see Decisions).
- Tests: `test/support/fake_purchase_service.dart` extended; updated
  `premium_gate_test.dart`; new `onboarding_funnel_test.dart`,
  `settings_restore_test.dart`, `restore_flow_test.dart`.

## Decisions

- **Onboarding → paywall → today sequencing.** `_finish()` persists
  `onboardingDone` *first* (so a closed paywall or a crash never re-shows
  onboarding), then `await`s the funnel, then `context.go('/today')`. The funnel
  pushes each paywall full-screen and `await`s its close; between the two
  paywalls we sit harmlessly back on `/onboarding` (still mounted).
- **Router redirect adjusted (this was the real fork).** The old redirect bounced
  a finished user off `/onboarding` to `/today`. That fired the instant the trial
  paywall popped — tearing down onboarding before the discount paywall could
  show. I removed that auto-bounce. The "force a *not*-onboarded user into
  onboarding" rule stays; nothing else routes a finished user to `/onboarding`
  (the reset path clears the flag first), so the bounce was safe to drop.
- **The once-ever 80% flag.** `discountOfferShown` is set **before** the discount
  paywall is shown, so even a crash mid-show can't repeat it. It's only set when
  the user is still free after the trial paywall — if they bought on the trial,
  nothing is offered and the flag stays false. Persisted in prefs → once ever,
  not once per session.
- **Shared restore helper.** `performRestore(service)` returns
  `restored / noneFound / error` by reading the service's `isPremium` *directly*
  (synchronous, correct the moment restore returns — a provider read could lag a
  stream tick). Both the paywall and the Settings row use it, plus `restoreMessage`
  for the copy — no copy-paste.
- **Offline still safe.** If offers can't load at the end of onboarding, 004's
  retry/close state shows; closing continues to `/today` normally. The funnel
  never traps the user.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.9s)

$ flutter test
All tests passed!   (91 tests; 11 new)
```

New/updated tests: free user funnel (trial → discount → Today, flag set only
before the discount shows); discount never repeats once the flag is set; premium
user sees no paywalls; locked-category tap now opens the 50% paywall (updated the
003 sheet test); Settings restore row hidden for premium and shows the right
SnackBar for restored / none-found / error; plus a `performRestore` unit test.

Self-correction: none — analyze and tests were green on the first run.
(The `drift` "database created multiple times" warning in the log is pre-existing
test-harness noise, unrelated to this change.)

Manual click-path (for the owner):
- [ ] Fresh install → finish onboarding → trial paywall → close → 80% paywall →
      close → lands on Today.
- [ ] Restart the app → no paywall on launch.
- [ ] Explore → tap a locked category → 50% paywall.
- [ ] Settings → Restore purchases → "No previous purchase found." (with
      placeholder keys, the paywall screens show the friendly retry state — still
      closeable, funnel still reaches Today).

## Open items for the owner

- Still needs the **real API keys + dashboard setup** (products, `premium`
  entitlement, the 3 offerings) before any paywall shows real prices or a purchase
  can complete. Until then every paywall shows the offline/retry state — which the
  funnel handles gracefully.
- This completes the monetization phase (prompts 002–005): SDK + premium state,
  category gating, paywall UI, and now the triggers.

## Commit & push

- **Commit(s):** `2d6d554` — `feat(paywall): wire onboarding/discount/locked-content triggers`
  (this report's SHA stamp is a tiny follow-up `docs` commit).
- **Push:** `origin/main` — ok (`f239b23..2d6d554`).

## Deviations from prompt

None. (`showPremiumSheet` was renamed to `showPremiumPaywall`, which the prompt
explicitly allowed.)
