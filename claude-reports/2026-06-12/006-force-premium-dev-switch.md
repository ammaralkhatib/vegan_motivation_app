# Dev-only "force premium" switch

**Prompt:** `claude-prompts/2026-06-12/006-force-premium-dev-switch.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Added a compile-time `FORCE_PREMIUM` switch so Ammar can test the app as a
premium user before RevenueCat is set up. Run with the define and premium is on
for that run (all 6 categories, no paywalls, premium settings rows hidden); run
without it and nothing changes. The flag is read at one point only and never
writes to the cache, so it can't leak into a real build or persist.

## Files touched

- `lib/core/purchases/purchase_config.dart` — added
  `static const bool forcePremium = bool.fromEnvironment('FORCE_PREMIUM');`
  with a doc comment (dev/testing only; defaults false so it can't ship enabled).
- `lib/core/purchases/purchase_providers.dart` — applied the flag at the single
  point: `PremiumStatusNotifier.build()` returns `true` early when
  `forcePremium` is set, before touching the service/cache. Everything
  downstream (gating, paywalls, settings, onboarding funnel) follows with no
  other change.
- `test/purchase_providers_test.dart` — one guard test: with the define absent
  (its compile-time default in `flutter test`), a free user is **not** forced
  premium — real gating still drives `isPremiumProvider`. Comment notes the
  `true` branch is fixed at compile time and can't be unit-tested.

## Decisions

- **Applied via early-return in the notifier's `build()`**, not by mutating the
  service or cache. This keeps it to one line at one point, guarantees no write
  to the prefs cache (req 3), and means the flag has zero effect on the service
  layer or any test that overrides `purchaseServiceProvider`.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
00:03 +129: All tests passed!
```

How Ammar runs it:
- **Premium on:** `flutter run --dart-define=FORCE_PREMIUM=true`
- **Normal (free):** `flutter run`

Self-correction: none needed (analyze + tests green on first run).
Manual click-path (Ammar): [ ] run with the flag → all 6 categories open, no
paywalls, premium rows hidden; [ ] run without → behaves as today.

## Commit & push

- **Commit:** `50d8428` — `feat(purchases): dev-only FORCE_PREMIUM build flag`
- **Push:** `origin/main` — ok (`a8ccf8e..50d8428`).

## Deviations from prompt

None.
