# Paywall screens — one design, three variants

**Prompt:** `claude-prompts/2026-06-12/004-paywall-screens.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Built the paywall UI: one reusable screen with three variants — `onboarding`
(7-day free trial), `defaultOffer` (50% off), `discount` (80% off, "last
chance") — each mapped to its RevenueCat offering. Prices and trial wording come
from the store, never hard-coded. A purchase runs end-to-end through
`PurchaseService` with confetti + auto-close on success, silent stay on cancel,
and a "you were not charged" SnackBar on error. If offers can't load (offline /
placeholder keys) it shows a friendly retry state and the close button always
works. Reachable from a new Settings → "Veggie Premium" row (hidden once
premium). Triggers are deferred to prompt 005. Analyze clean, all 80 tests pass
(17 new). No new packages.

## Files touched

- `lib/features/paywall/paywall_data.dart` (new) — `PaywallVariant` enum,
  `PaywallData` model, and `buildPaywallData()` / `anchorPriceFrom()` mappers.
- `lib/features/paywall/paywall_providers.dart` (new) — `paywallDataProvider`
  (FutureProvider.family) that loads the offering and maps it.
- `lib/features/paywall/paywall_screen.dart` (new) — `PaywallScreen` (load +
  purchase/restore flow + retry/close), the render-only `PaywallView`, and
  `showPaywall()`.
- `lib/app/router.dart` — `/paywall/:variant` full-screen route.
- `lib/features/settings/settings_screen.dart` — "Veggie Premium" row, hidden
  when premium.
- `test/support/paywall_fixtures.dart` (new) + 4 new test files (see below).

## Decisions

- **The `PaywallData` seam.** The screen renders only `PaywallData` (title, CTA,
  price string, optional anchor/trial/badge/subtitle, package). A mapper turns a
  RevenueCat `Offering` into it. So widget tests build `PaywallData` by hand and
  almost never touch SDK types — exactly the pain the 002 report flagged. Only a
  handful of minimal real RevenueCat objects exist, in `test/support/`, for the
  mapper tests and to hand a `package` to the fake's `purchase`.
- **Anchor price is sourced, never invented (CLAUDE.md §3).** For the 50%/80%
  variants the provider fetches the `onboarding` offering's real full price and
  passes it as the crossed-out anchor. If that fetch returns nothing,
  `buildPaywallData` drops both the anchor *and* the "% OFF" badge — the user
  just sees the real discounted price, no fake "was" number.
- **Trial wording follows the store.** The onboarding variant only says "N days
  free, then <price>/year" when the product actually has a *free* introductory
  phase (`introductoryPrice.price == 0`); otherwise it falls back to plain
  "<price>/year". We never promise a trial the store won't honor.
- **Offline degrades, never blocks.** `getOffering` returning null → the friendly
  "Can't load offers right now" state with Retry; the X always pops. Nothing
  traps the user.
- **Purchase flow** lives in `PaywallScreen`: CTA → `purchase(package)`; success
  → reuse the app's `confetti` package + auto-close; cancel → stay, no message;
  error → SnackBar. Restore → `restorePurchases()`, then check `isPremiumProvider`
  → "Welcome back!" + close, or "No previous purchase found."
- **Settings row** is the manual test path until 005 wires real triggers; it's
  hidden once `isPremiumProvider` is true (nothing left to sell).

## Verification

```
$ flutter analyze
No issues found! (ran in 2.8s)

$ flutter test
All tests passed!   (80 tests; 17 new for the paywall)
```

New tests: mapper (trial present/absent, 50%/80% badge + anchor, anchor hidden
when unavailable, null when no package); `PaywallView` renders each variant
(badge/anchor/trial shown or hidden, benefits/restore/footnote always present);
`PaywallScreen` flow (offering-null → retry + close works, purchase success →
confetti + auto-close, cancel → stays silent, error → not-charged SnackBar);
Settings row shown for free / hidden for premium.

Self-correction: none — analyze and tests were green on the first run.
(The `drift` "database created multiple times" warning in the log is pre-existing
test-harness noise, unrelated to this change.)

Manual click-path (for the owner):
- [ ] Settings → "Veggie Premium" → the paywall opens.
- [ ] With placeholder API keys, expect the friendly "Can't load offers" state;
      both Retry and the X work.
- [ ] (After real keys + dashboard setup) each variant shows real store prices,
      and a sandbox purchase confettis and closes.

## Open items for the owner

- Real purchases still need the **real API keys** (prompt 002 placeholders) and
  the **dashboard setup**: 3 yearly products, the `premium` entitlement, and the
  3 offerings (`onboarding`, `default`, `discount`). Until then every variant
  shows the offline/retry state — which is the expected, safe behavior.
- Prompt 005 wires the real triggers (onboarding → trial paywall → one-time 80%
  offer; locked content → 50% paywall) and replaces `premium_gate.dart`'s
  placeholder sheet with `showPaywall`.

## Commit & push

- **Commit(s):** `8b1b836` — `feat(paywall): paywall screen with trial/50/80 variants`
  (this report's SHA stamp is a tiny follow-up `docs` commit).
- **Push:** `origin/main` — ok (`006e570..8b1b836`).

## Deviations from prompt

None.
