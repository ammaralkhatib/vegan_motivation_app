# Rename display name from "Veggie" to "VeganKit"

**Prompt:** `claude-prompts/2026-06-13/002-rename-display-name-vegankit.md`
**Completed:** 2026-06-13 · **Status:** done

> Keep this short. Git holds the diff — Planning Claude reads it with `git show`.

## Summary

Changed the user-facing app/brand name from `Veggie` to `VeganKit` everywhere a
user can see it: platform display names (iOS/Android/macOS/Windows), the Android
home-screen widget label, the 13 localized brand strings in all four `.arb`
locales (en/de/es/fr), and the seven hardcoded Dart brand strings. All code
identifiers, the Drift DB name, store product id, and the bundle id are untouched.
`flutter analyze` clean; all 160 tests pass (10 tests that asserted the old
"Veggie" text were updated to expect "VeganKit", per the prompt).

## Files touched

Brand/display name only — reasons, not diff:

- `ios/Runner/Info.plist` — `CFBundleDisplayName` + `CFBundleName` → `VeganKit`.
- `android/app/src/main/AndroidManifest.xml` — `android:label` → `VeganKit`.
- `android/app/src/main/res/layout/widget_quote.xml` — widget label → `🌱 VeganKit`.
- `macos/Runner/Configs/AppInfo.xcconfig` — `PRODUCT_NAME` → `VeganKit`.
- `windows/runner/Runner.rc` — `ProductName` display string → `VeganKit`
  (FileDescription/InternalName/OriginalFilename left as `vegan_motivation_app`).
- `pubspec.yaml` — `description:` lead `Veggie —` → `VeganKit —` (package `name:`
  unchanged).
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_es.arb`, `app_fr.arb` — brand token in
  the 13 listed keys → `VeganKit`; localizations regenerated with `flutter gen-l10n`.
- `lib/main.dart`, `lib/app/app.dart`, `lib/features/onboarding/onboarding_flow.dart`,
  `lib/features/quotes/share_card.dart`, `lib/features/settings/settings_screen.dart`,
  `lib/core/notifications/notification_service.dart` — the seven hardcoded brand
  strings (incl. the `VeganKit 🌱` notification channel) → `VeganKit`.
- `test/` (8 files: `onboarding_story_test`, `paywall_screen_test`,
  `paywall_view_test`, `premium_gate_test`, `settings_premium_row_test`,
  `settings_restore_test`, `support/paywall_fixtures`, `widget_test`) — assertions
  that expected the old "Veggie" brand text updated to "VeganKit". No assertion
  weakened or deleted.

## Decisions

- **Casing of stylized lowercase lines → `VeganKit`** (flagged per prompt). Seven
  English onboarding strings used an all-lowercase stylized `veggie`; all are now
  proper-case `VeganKit`. The German/French/Spanish versions of these already used
  capitalized `Veggie`. The exact en lines changed lowercase→`VeganKit`
  (`lib/l10n/app_en.arb`): `onboardingSolutionHeadline` ("VeganKit keeps your why
  in front of you"), `onboardingGoalsTitle` ("what do you want from VeganKit?"),
  `onboardingGoalsReflectionBody` ("…— VeganKit was built for exactly this."),
  `onboardingReflectionClose` ("VeganKit was made for exactly this moment."),
  `onboardingChartLegendWith` ("with VeganKit"), `onboardingSocialTitle`
  ("VeganKit was made for people like you"), `onboardingSocialCta`
  ("join VeganKit 🌱"). **Ammar: eyeball these on device** — if you prefer the
  lowercase styling (`vegankit`) in these stylized spots, say so and I'll switch them.
- **`veggie_migr` temp-dir name in `test/quote_translations_test.dart` left as-is**
  — it's an internal temp directory name, not a brand assertion or user-facing.

## Verification

```
$ grep -rniE "\bveggie\b" <the 6 Dart files + 4 .arb + 5 platform files in scope>
(zero matches)

$ flutter gen-l10n
(succeeded — l10n regenerated)

$ flutter clean && flutter pub get && flutter analyze
No issues found! (ran in 1.7s)

$ flutter test
All tests passed!  (+160)
```

Self-correction: 10 tests failed on attempt 1 because they asserted the old
"Veggie" brand text; updated those expectations to "VeganKit" (the intended new
value) — green on attempt 2.
Manual click-path (pending Ammar): [ ] fresh install → confirm home-screen icon
label, app-switcher title, onboarding, paywall, settings "About", a shared quote
card, and a notification all read "VeganKit".

## Commit & push

- **Commit:** `<sha>` — `chore: rename display name to VeganKit`
- **Push:** `origin/main` — see below.

## Open items for the owner

Out-of-repo display-name spots (none are code):

- **App Store Connect:** app name → "VeganKit".
- **Play Console:** app title → "VeganKit".
- **RevenueCat:** app display name → "VeganKit".
- The lowercase-vs-proper-case decision above (eyeball the 7 stylized onboarding
  lines on device).
- Manual on-device name check (above) still pending.

## Deviations from prompt

None.
