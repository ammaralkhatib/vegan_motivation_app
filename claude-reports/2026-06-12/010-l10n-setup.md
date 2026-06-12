# Localization setup (gen_l10n) + settings migrated as the reference pattern

**Prompt:** `claude-prompts/2026-06-12/010-l10n-setup.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Wired Flutter's official localization (gen_l10n + ARB) into the app and moved the
two settings screens' hardcoded English to ARB lookups — the reference pattern all
later feature migrations follow. The app still shows English only (one ARB,
`app_en.arb`); device-language resolution stays default with no in-app picker.
Analyze clean, all 133 tests pass.

## Per-requirement status

1. **`flutter_localizations`** ✅ — added via `flutter pub add --sdk=flutter`.
   `intl` unchanged (gen_l10n accepted the existing `^0.20.2`).
2. **`l10n.yaml`** ✅ — `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`,
   `output-localization-file: app_localizations.dart`, `nullable-getter: false`.
3. **`lib/l10n/app_en.arb`** ✅ — `"@@locale": "en"`, ~40 keys in
   `<feature><Description>` lowerCamelCase. One placeholder key:
   `notificationsPerDayCount` = `"{count}×"` (int). Copy is byte-for-byte the
   current English (copy freeze).
4. **`app.dart`** ✅ — `MaterialApp.router` now sets
   `localizationsDelegates: AppLocalizations.localizationsDelegates` and
   `supportedLocales: AppLocalizations.supportedLocales`. Locale resolution left
   default.
5. **Settings strings migrated** ✅ — every on-screen string in
   `settings_screen.dart` and `notification_settings_screen.dart` now reads from
   `AppLocalizations.of(context)` (titles, subtitles, dialog text + buttons,
   the meals-too-close SnackBar, helper text, meal labels). See judgment calls.
6. **Generated files** ✅ — on this Flutter (3.41.9) gen_l10n writes to the
   `arb-dir` (`lib/l10n/app_localizations*.dart`), not `.dart_tool/` (the synthetic
   `flutter_gen` package was removed in modern Flutter). Kept the prompt's intent —
   added `/lib/l10n/app_localizations*.dart` to `.gitignore` so they stay
   generated-not-committed; `generate: true` in pubspec rebuilds them on
   `pub get`/build/test. Confirmed `git add` stages only `app_en.arb`, never the
   `.dart` files.
7. **CLAUDE.md** ✅ — added a "Localization (gen_l10n)" subsection to §1: ARB
   workflow, key-naming rule, and the locked decision "UI strings only — quote
   content is not localized in this phase".

## Decisions / judgment calls

- **Import path:** `package:vegan_motivation_app/l10n/app_localizations.dart`
  (real path), because synthetic `package:flutter_gen/...` no longer exists on
  Flutter 3.41.
- **Brand name left literal:** `showLicensePage(applicationName: 'Veggie')` stays a
  string — it is a proper brand name, not translatable copy. The legalese line on
  that page *was* migrated (`settingsAboutLegalese`).
- **Numeric count selectors left literal:** the per-meal `Text('1'/'2'/'3')`
  segmented buttons are bare numbers, not words — left as-is. So
  `grep "Text('" lib/features/settings/` still shows only these three numeric
  literals; no user-visible *words* remain hardcoded.
- **Test harnesses:** 4 widget tests pump the settings screens directly
  (`settings_restore`, `settings_premium_row`, `notification_settings_meal`,
  `photo_feed_polish`). Added the localization delegates + `supportedLocales` to
  each harness — no test logic weakened or removed. `notif_meal_settings_test` is
  provider-only (no widget tree), so it needed no change.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
All tests passed!   (133 tests)

$ grep -rn "Text('" lib/features/settings/
# only the numeric 1/2/3 meal-count selectors remain (no user-visible words)
```

Did not run a full `flutter build` — analyze + the widget tests already build and
render both settings screens under the real delegates. Manual click-through is the
open item below.

Self-correction (within the 2-attempt budget): first `flutter test` surfaced a 4th
harness (`photo_feed_polish_test.dart`) that also pumps `SettingsScreen` without
delegates; added the delegates there and the suite went green on the next run.

## Open items (for Ammar)

- Click through Settings and Notifications on device — text should read identical to
  before (English copy frozen).
- Later prompts: migrate the remaining features (onboarding, paywall, quotes,
  explore, journey, habits, share, shell) one per prompt, then add `app_de.arb` /
  `app_fr.arb` / `app_es.arb`. Quote content stays English (locked).

## Commit & push

- **Commit:** `<filled by stamp>` — `feat(l10n): add gen_l10n setup and migrate settings strings`
- **Push:** `<filled by stamp>`

## Deviations from prompt

- Requirement 6 assumed generated files land in `.dart_tool/`; on Flutter 3.41 they
  land in `lib/l10n/`. Honored the intent (don't commit them) via `.gitignore`
  rather than relying on the old synthetic-package location.
