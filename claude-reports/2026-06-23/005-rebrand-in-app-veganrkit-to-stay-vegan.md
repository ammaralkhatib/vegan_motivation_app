# Rebrand in-app text: "VeganKit" → "Stay Vegan"

**Prompt:** `claude-prompts/2026-06-23/005-rebrand-in-app-veganrkit-to-stay-vegan.md`
**Completed:** 2026-06-23 · **Status:** done

## Summary

Replaced every user-facing "VeganKit" inside the app with "Stay Vegan" so the
interior matches the new icon name (set in prompt 004). The swap covers settings,
paywall + onboarding copy, the discount banner, the notif-preview sender, legal
(privacy + terms), the share-card watermark, the onboarding logo, the daily-
notification title, and the desktop window title — across all four languages
(en/de/es/fr). "Stay Vegan" is kept as one invariant proper noun in every language
(not translated). The three protected technical identifiers were left untouched.
Analyzer clean, all 172 tests pass.

## Files touched

- `lib/l10n/app_en.arb`, `app_de.arb`, `app_es.arb`, `app_fr.arb` — every value with
  the brand token swapped 1:1 (surrounding localized text unchanged), then
  regenerated `app_localizations*.dart` via `flutter gen-l10n` (generated files are
  git-ignored, so they aren't in the commit).
- `lib/core/notifications/notification_service.dart` — daily-notification title
  `'VeganKit 🌱'` → `'Stay Vegan 🌱'`. (Windows `appName` left as `VeganKit` — protected.)
- `lib/features/settings/settings_screen.dart` — About dialog `applicationName`.
- `lib/features/quotes/share_card.dart` — share-card watermark.
- `lib/features/legal/legal_content.dart` — all privacy + terms copy, plus the two
  doc-comments that referenced "the VeganKit website" (so the grep check is clean).
- `lib/features/onboarding/onboarding_flow.dart` — the big brand logo text.
- `lib/main.dart` — desktop `WindowOptions.title`.
- `test/onboarding_story_test.dart`, `test/widget_test.dart`,
  `test/settings_restore_test.dart`, `test/settings_premium_row_test.dart` — updated
  the brand assertions (and one test-name string) to "Stay Vegan".

## Decisions

- **Dead paywall ARB keys: swapped.** `paywallOnboardingTitle`, `paywallDefaultTitle`,
  `paywallDefaultCta` (unused since the RevenueCat hosted-paywall migration) had their
  brand token swapped too. They aren't shown to users, but Requirement 1 wants
  `grep -rn "VeganKit" lib/` to return only the 3 protected identifiers — and the ARB
  files live under `lib/`, so leaving them would fail that check. A 1:1 token swap, so
  no codegen complications.
- **Legal doc-comments swapped too.** The two `///` comments in `legal_content.dart`
  ("verbatim from the VeganKit website") aren't user-facing, but again the grep clean
  requirement forced them; harmless to update.
- **Bulk vs targeted edits.** Used a 1:1 `VeganKit`→`Stay Vegan` replace on the 4 ARB
  files, `legal_content.dart`, and the 4 test files (every occurrence there is the
  brand token). Used precise single-line edits for the source files that also contain
  protected strings, to be sure nothing else moved.

## Protected identifiers — confirmed intact

`grep -rn "VeganKit" lib/` now returns exactly these three, all left unchanged:

- `lib/core/widgetkit/home_widget_service.dart:18` — `'VeganKitWidgetProvider'`
- `lib/core/widgetkit/home_widget_service.dart:19` — `'VeganKitWidget'`
- `lib/core/notifications/notification_service.dart:79` — Windows init `appName: 'VeganKit'`

## Verification

```
$ grep -rn "VeganKit" lib/
lib/core/widgetkit/home_widget_service.dart:18:  ... 'VeganKitWidgetProvider';
lib/core/widgetkit/home_widget_service.dart:19:  ... 'VeganKitWidget';
lib/core/notifications/notification_service.dart:79:        appName: 'VeganKit',
(only the 3 protected identifiers)

$ flutter analyze
No issues found! (ran in 2.1s)

$ flutter test
00:05 +172: All tests passed!
```

Self-correction: none needed.

Manual click-path (needs a device — not run here):
- [ ] Onboarding, settings, discount banner, legal screens, a shared quote card, and
  a real daily notification all read "Stay Vegan".

## Commit & push

- **Commit:** `d68bf17` — `chore(branding): rename in-app "VeganKit" to "Stay Vegan"`
- **Push:** `origin/main` — ok (`789e4a5..d68bf17`)

## Open items for the owner

- The generated `app_localizations*.dart` are git-ignored and rebuilt on each build,
  so nothing extra to commit — but confirm your CI/build step runs l10n codegen (it
  does automatically via `generate: true` in pubspec).
- On-device visual check of the screens listed in the manual click-path.

## Deviations from prompt

None.
