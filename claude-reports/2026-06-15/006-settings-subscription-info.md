# Subscription info card in Settings (for premium users)

**Prompt:** `claude-prompts/2026-06-15/006-settings-subscription-info.md`
**Completed:** 2026-06-15 · **Status:** done

## Summary

Premium users used to see *nothing* about their plan — the whole premium/restore
card was hidden once subscribed. Now a premium user sees a **Subscription** card
(in the same top spot) showing "Active" plus the renewal date (or expiry date if
the plan is set not to renew), and a **Manage subscription** button that opens the
store's subscription page. Free users see exactly what they saw before. The card
degrades gracefully to plain "Active" (no date) when details can't be loaded —
offline, an unsupported platform, or no SDK configured. Analyze is clean and all
170 tests pass.

## Files touched

- `lib/core/purchases/purchase_service.dart` — new immutable `SubscriptionDetails`
  value type; new `getSubscriptionDetails()` on the `PurchaseService` interface;
  RevenueCat impl reads the active `premium` entitlement (`willRenew`,
  `expirationDate`, `info.managementURL`), guarded by `_supported/_configured` and
  wrapped in try/catch → null on any failure.
- `lib/core/purchases/purchase_providers.dart` — `subscriptionDetailsProvider`
  (`FutureProvider`) that watches `isPremiumProvider`; returns null without
  calling the service when not premium.
- `lib/features/settings/settings_screen.dart` — premium branch now renders a new
  `_SubscriptionCard` (status line + Manage button); `_manageSubscription` opens
  `managementUrl` (or the platform default store URL) via `url_launcher`, with a
  SnackBar fallback if it can't launch.
- `test/support/fake_purchase_service.dart` — new `subscriptionDetails` field +
  `getSubscriptionDetails()` impl (keeps every existing test compiling).
- `test/settings_premium_row_test.dart` — premium case updated: asserts the
  upsell/restore is gone **and** the Subscription card + Manage button show;
  added a second premium case (`subscriptionDetails: null`) asserting "Active"
  with no crash. Free-user test unchanged.
- `lib/l10n/app_en.arb` (+ `app_de/fr/es.arb`) — 6 new `settings*` strings.
- `pubspec.yaml` / `pubspec.lock` — added `url_launcher: ^6.3.1`.

## Decisions

- **Status line in plain code, not the ARB.** `DateFormat.yMMMMd(localeName)`
  formats the date and the formatted *string* is passed into the ARB placeholder
  (kept `String`, not `DateTime`), per the prompt — avoids extra l10n config.
  Loading / error / null / no-expiry all collapse to "Active".
- **Platform default store URL** chosen with `defaultTargetPlatform`
  (Android → Play, else Apple) only as a fallback when the SDK gives no
  `managementUrl`.
- **`launchUrl` wrapped in try/catch** in addition to checking its bool return —
  the plugin can throw (e.g. no handler) as well as return false; both paths show
  the error SnackBar.

## Offline / unsupported fallback

The card never blocks on the network: `subscriptionDetailsProvider` returns null
for free users without an SDK call, and the RevenueCat impl returns null when the
platform is unsupported, the SDK isn't configured, or the call throws. In all
those cases the card still shows "Active" (no date) and the Manage button falls
back to the platform's generic subscription URL.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
All tests passed! (170 tests)
# settings_premium_row_test.dart — pass (3 cases: free / premium+details / premium+null)
# purchase_providers_test.dart — pass (unchanged, still compiles with the new method)
# l10n_parity_test.dart — pass (6 keys added to all 4 locales)
```

Self-correction: fixed on attempt 1 — `defaultTargetPlatform` was undefined
(material.dart doesn't re-export it); added an explicit
`package:flutter/foundation.dart` import. Re-ran analyze clean and tests green.

Manual click-path (Ammar runs on device, ideally `--dart-define=FORCE_PREMIUM=true`):
- [ ] Premium Settings → Subscription card shows "Active" + renewal/expiry date
      when available.
- [ ] "Manage subscription" opens the store's subscription page.
- [ ] Free user → Settings unchanged (upsell + restore).

## Commit & push

- **Commit:** `fd2a20a` — `feat(settings): show subscription info + manage button for premium users`
- **Push:** `origin/main` — ok

## Open items for the owner

- **Real date/Manage need a live (sandbox) subscription.** With `FORCE_PREMIUM`
  there's no RevenueCat entitlement, so the card shows "Active" with no date and
  Manage uses the generic store URL — that's expected. Verify the real renewal
  date + deep link with a sandbox purchase on a device.
- The de/fr/es translations of the 6 new strings are my best effort — worth a
  native-speaker check before the localized release ships.

## Deviations from prompt

- Also edited `app_de.arb` / `app_fr.arb` / `app_es.arb` (Scope named only
  `app_en.arb`). Required: `l10n_parity_test.dart` enforces identical keys across
  all four locales, so English-only additions fail it. Minimal change to keep
  `flutter test` green; same situation as prompt 005.
