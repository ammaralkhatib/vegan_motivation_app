# Switch to RevenueCat hosted Paywalls (delete custom paywall UI)

**Prompt:** `claude-prompts/2026-06-23/002-revenuecat-hosted-paywalls.md`
**Completed:** 2026-06-23 · **Status:** done

> Keep this short. Git holds the diff.

## Summary

We used to build our own paywall screen in Flutter. Now we show RevenueCat's
**hosted paywalls** instead — the ones Ammar designs in the RevenueCat dashboard,
one per offering (`onboarding`, `default`, `discount`). Every place that used to
open our screen now asks RevenueCat to show its paywall for the right offering.
The whole custom paywall UI is deleted. The "your trial ends tomorrow" reminder
still gets scheduled after a trial purchase, and every paywall keeps a working
close button (Apple 5.6). `flutter analyze` is clean and all 169 tests pass.

## Files touched

- `pubspec.yaml` / `pubspec.lock` — added `purchases_ui_flutter: ^10.2.3` (matches
  the `purchases_flutter` major version 10).
- `lib/features/paywall/paywall_presenter.dart` — **new**. A small `PaywallPresenter`
  interface + the real RevenueCat implementation + a Riverpod provider. It looks
  up the offering through the existing `PurchaseService`, calls
  `RevenueCatUI.presentPaywall(... displayCloseButton: true)`, and (on a buy)
  schedules the trial reminder.
- `lib/features/paywall/paywall_data.dart` — slimmed down to just the
  `PaywallVariant` enum + its `offeringId` getter. Removed `PaywallData`,
  `buildPaywallData`, `anchorPriceFrom`, `TrialPeriodUnit`, `fromName`.
- `onboarding_paywall_funnel.dart` — presents the `onboarding` paywall via the
  presenter; signature is now `(WidgetRef ref)` (no more `BuildContext`).
- `discount_banner.dart` — the banner's tap now presents the `discount` paywall
  via the presenter; all the 001 gating / one-time-flag logic is unchanged.
- `core/purchases/premium_gate.dart` — `showPremiumPaywall(WidgetRef)` now presents
  the `default` paywall; `explore_screen.dart` passes `ref`.
- `settings_screen.dart` — both upgrade rows present the `default` paywall.
- `app/router.dart` — deleted the `/paywall/:variant` route + its imports.
- `app/onboarding_flow.dart` — updated the one funnel call site to drop `context`.
- Deleted: `paywall_screen.dart`, `paywall_providers.dart`, and the tests that only
  covered the old UI (`paywall_view_test`, `paywall_data_test`, `paywall_screen_test`,
  `support/paywall_fixtures.dart`).
- Tests: new `support/fake_paywall_presenter.dart`; rewrote `onboarding_funnel_test`,
  `discount_banner_test`, `premium_gate_test`, `legal_screen_test`,
  `onboarding_story_test`, and `photo_feed_polish_test` to inject the fake presenter
  (or pump `LegalScreen` directly) instead of asserting navigation to the old screen.

## Decisions

- **How the trial reminder is detected after a purchase.** RevenueCat's hosted
  paywall does the buying, so we no longer have the bought `package` in hand. After
  a `purchased` result, the presenter reads `Purchases.getCustomerInfo()`, takes the
  active `premium` entitlement's `productIdentifier`, and schedules the reminder only
  if `shouldScheduleTrialReminder(productId)` is true (i.e. it's the trial product).
  Wrapped in try/catch so a reminder failure never breaks the purchase flow — same
  intent as the old `_buy`.
- **Result mapping.** RevenueCat's `error` and `notPresented` both collapse to our
  `PaywallPresentResult.notPresented` — both just mean "nothing was bought, carry on".
- **Dead ARB strings: left in place.** Deleting the custom screen orphaned ~25 paywall
  l10n keys (`paywallOnboardingTitle`, `paywallBadge50`, `paywallTrialText`,
  `paywallClose`, etc.) across all four ARBs. Unused ARB keys don't fail `analyze`,
  and removing them × 4 files would balloon the diff for no functional gain, so I left
  them and list them as an open item. The `discountBanner*` keys stay (still used).
- **Also fixed `photo_feed_polish_test`** (not named in the prompt) — it asserted the
  old `/paywall/` navigation, so it had to move to the fake presenter too.

## Verification

```
$ flutter analyze
No issues found! (ran in 3.1s)

$ flutter test
00:05 +169: All tests passed!
```

Self-correction: one test failed on the first full run (`photo_feed_polish_test`
still expected the old paywall route); fixed it to use the fake presenter and the
suite went green (attempt 2). No commit was made before green.

Manual click-path (Ammar runs on a device, needs the dashboard paywalls live):
- [ ] Finish onboarding → RevenueCat `onboarding` paywall → close (X) → Today, free.
- [ ] Tap a locked category / Settings upgrade row → `default` paywall.
- [ ] Home discount banner → tap → `discount` paywall; dismissing still consumes it.
- [ ] Buy the trial product → "trial ends tomorrow" reminder is scheduled.
- [ ] Every paywall shows a working close button.

## Commit & push

- **Commit(s):** `6149241` (code) + this report commit — `feat(paywall): switch to RevenueCat hosted paywalls, delete custom paywall UI`
- **Push:** `origin/main` — ok.

## Open items for the owner

**Dashboard (RevenueCat) — required before the paywalls show anything:**
1. Attach a hosted paywall to each of the three offerings (`onboarding`, `default`,
   `discount`).
2. Set the **Privacy Policy + Terms of Use footer URLs** on each paywall — Apple
   3.1.2c needs working Privacy + Terms links **on the paywall itself**.
3. Keep the **close button enabled** on each paywall (Apple 5.6 — backed by our
   `displayCloseButton: true`, but the dashboard must not hide it).

**Build / device:**
4. **iOS deployment target may need raising to 15.0.** RevenueCat's Paywall UI SDK
   (pulled in by `purchases_ui_flutter`) targets newer iOS than our current Runner
   setting (13.0). If `pod install` / the iOS build errors on deployment target,
   bump `IPHONEOS_DEPLOYMENT_TARGET` (and the `ios/Podfile` `platform :ios`) to
   `15.0`. (Not changed here — it's a native build setting I can't verify in this
   environment.)
5. Run `flutter pub get` + `pod install` on your machine before the device test.

**Cleanup (optional):**
6. ~25 now-unused `paywall*` ARB keys remain in all four locale files. Safe to delete
   later in a dedicated cleanup; they don't affect analyze/tests/build.

## Deviations from prompt

None. (One extra test — `photo_feed_polish_test` — was updated beyond the named list
because it also asserted the deleted navigation.)
