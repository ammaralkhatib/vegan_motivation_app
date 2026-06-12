# In-app language picker in settings

**Prompt:** `claude-prompts/2026-06-12/017-language-picker-setting.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Added a "Language" row to Settings that lets the user override the app language
(System default / English / Deutsch / Français / Español). The choice persists
on-device and flips the **whole app at once** — UI strings, quote text,
notifications and the home widget — with no restart. The override is a new
prefs value (`languageOverride`, `null` = follow the phone). A new
`appLocaleProvider` feeds `MaterialApp.router`'s `locale:`, so the existing
locale-sync machinery (015) re-resolves quote text in the same rebuild.
Background paths (notifications, widget) read the override directly since they
have no `BuildContext`. `flutter analyze` clean, `flutter test` green (157
tests, incl. 4 new).

## Files touched

- `lib/core/prefs/prefs_repository.dart` — new `languageOverride` getter/setter
  (`null` = system, removes the key).
- `lib/core/locale/locale_provider.dart` — added `languageOverrideProvider`
  (persisted notifier), `appLocaleProvider` (`Locale?` for `MaterialApp`), and
  `resolveLanguageCode(override)` helper for the context-free background paths.
- `lib/app/app.dart` — wired `locale: ref.watch(appLocaleProvider)` into
  `MaterialApp.router`; bootstrap widget push now passes the override.
- `lib/features/settings/settings_screen.dart` — "Language" row + scrollable
  picker sheet; on change it persists, force-reschedules notifications and
  pushes a fresh widget queue. Endonyms are hardcoded literals (commented).
- `lib/core/notifications/notification_coordinator.dart` — resolves quote locale
  from the override (was raw `PlatformDispatcher`); passes it to `scheduleAll`.
- `lib/core/notifications/notification_service.dart` — `_notificationL10n` /
  `scheduleAll` take an optional `languageCode` so channel + body strings follow
  the override; `null` keeps the old device-locale behavior.
- `lib/core/widgetkit/home_widget_service.dart` — `pushQueue` takes
  `languageOverride` and resolves text via `resolveLanguageCode`.
- `lib/l10n/app_{en,de,fr,es}.arb` — new keys `settingsLanguage`,
  `settingsLanguageSystemDefault` in all four (parity test enforces this).
- `test/language_picker_test.dart` — new: pref round-trip; provider resolves
  override > system; widget test (pick Deutsch → "Einstellungen" appears).

## How the override reaches each path

- **UI + quotes:** `appLocaleProvider` → `MaterialApp.locale` → Flutter resolves
  the locale → `Localizations.localeOf` → the existing `_syncLocale` pushes it
  into `localeCodeProvider`, so quotes re-resolve in the same frame. Unset
  (`null`) means Flutter follows the device locale exactly as before.
- **Notifications:** coordinator resolves `resolveLanguageCode(override)` and
  threads it into `scheduleAll`; a language change calls `reschedule(force: true)`.
- **Home widget:** settings passes the override into `pushQueue` after a change;
  the bootstrap push passes it on every launch.
- **Unsupported system locale** (e.g. Italian) is untouched: the override is
  `null`, the raw code flows through, and the quote DAO / `lookupAppLocalizations`
  fall back to English exactly as today.

## Decisions

- **Picker = scrollable bottom sheet returning a `({String? code})` record.** A
  plain `String?` return can't tell "picked System default" (a real `null` code)
  apart from "dismissed the sheet". The record wrapper distinguishes them.
- **Endonyms hardcoded, not in ARB.** Language names stay literal per the prompt
  ("Français", never "French"); only "System default" is localized.
- **`SingleChildScrollView` around the sheet** so the 5 options never overflow on
  short screens (caught by the widget test, also better on small phones).
- **Trial-end reminder keeps its scheduled language.** It's a one-shot scheduled
  at purchase time with no override in hand; documented in the existing comment.

## Verification

```
$ flutter analyze
No issues found! (ran in 3.0s)

$ flutter test
All tests passed! (157 tests)
```

Self-correction: fixed a bottom-sheet overflow surfaced by the new widget test
on attempt 2 (wrapped the sheet in `SingleChildScrollView`); re-ran clean.
Manual click-path: [ ] Settings → Language → Deutsch → app flips (tabs, quotes,
settings) without restart; [ ] back to System default restores device language.

## Commit & push

- **Commit(s):** `bd15068` — `feat(settings): add in-app language picker`
- **Push:** `origin/main` — ok (`c1b6872..bd15068`)

## Open items for the owner

- None for code. Worth a quick on-device check that notifications and the home
  widget show the new language after switching (background paths can't be fully
  exercised in widget tests).

## Deviations from prompt

None.
