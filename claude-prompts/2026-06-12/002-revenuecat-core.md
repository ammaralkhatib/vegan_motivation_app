# RevenueCat core — SDK, purchase service, cached premium state

## Goal
Add the RevenueCat SDK and a clean purchase layer so the app knows whether the
user is premium. No UI and no feature gating yet — this prompt only builds the
plumbing that later paywall prompts sit on. "Done" = the app builds and runs on
all targets, a Riverpod provider exposes `isPremium`, the state survives app
restarts offline, and everything is mockable in tests.

## Scope
- In: `pubspec.yaml`, new `lib/core/purchases/` module, `lib/main.dart` (init
  hook only), `test/`.
- Out: any UI, onboarding flow, quote feed, settings screens, habit/journey
  features. No gating of any feature in this prompt.

## Requirements
1. Add `purchases_flutter` (latest stable) to `pubspec.yaml`.
2. Create `lib/core/purchases/purchase_config.dart`:
   - Placeholder API key constants for iOS/macOS and Android (clearly marked
     `TODO(ammar): paste real key from RevenueCat dashboard`).
   - Constants for entitlement id `premium` and offering ids: `onboarding`,
     `default`, `discount`.
3. Create `lib/core/purchases/purchase_service.dart`:
   - `init()` — configures the RevenueCat SDK. Only on Android, iOS, macOS.
     On Windows (or any unsupported platform) skip the SDK entirely.
   - `isPremium` exposed as a stream/notifier, driven by RevenueCat's
     `CustomerInfo` listener (entitlement `premium` active = true).
   - `getOffering(String id)` — fetches one of the three offerings.
   - `purchase(Package)` and `restorePurchases()` — both return success/failure
     the UI can act on; user-cancelled is not an error.
   - All SDK calls wrapped so network failure never crashes or blocks the app.
4. Offline cache: persist last-known premium status in `shared_preferences`
   (reuse the existing prefs wrapper pattern in `lib/core/prefs/`). On app
   start, `isPremium` is seeded from the cache before any network call, then
   updated when RevenueCat responds. Unsupported platforms: `isPremium` = true
   (per CLAUDE.md §3 — desktop targets don't ship).
5. Riverpod providers in `lib/core/purchases/purchase_providers.dart`:
   `purchaseServiceProvider` and `isPremiumProvider`, following the provider
   style already used in `lib/features/`.
6. Call `init()` during app startup in `main.dart` without blocking first
   frame (fire-and-forget with error logging, matching how other startup work
   is handled).
7. Tests: unit tests for the cache seeding logic and provider behavior using a
   fake/mock purchase service (no real SDK calls in tests). The fake should be
   reusable by later prompts.

## Constraints
- Locked decisions hold (CLAUDE.md §3): offline-first with RevenueCat as the
  single exception; Riverpod/drift/go_router; no other new packages beyond
  `purchases_flutter` unless strictly required by it.
- The app must keep working with placeholder API keys (init failure is caught
  and logged; app continues as free user — or premium on desktop).
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries,
  CLAUDE.md §2).

## Verify
- `flutter analyze` and `flutter test`.
- Build check for one mobile target if available (e.g. `flutter build apk
  --debug`); if the toolchain for that target isn't installed, note it in the
  report instead.

## Commit & push
- Conventional Commit, e.g. `feat(purchases): RevenueCat SDK + premium state core`.
- Body includes `Prompt: claude-prompts/2026-06-12/002-revenuecat-core.md`.
- Push to origin/main; on failure stop and report (never force). No remote yet
  is expected — commit locally and note it.

## Report
- Write `claude-reports/2026-06-12/002-revenuecat-core.md` from TEMPLATE.md
  (mkdir -p the folder). Record intent, decisions, verification results,
  commit SHA, push result, open items (e.g. "API keys still placeholders").
