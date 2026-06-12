# In-app language picker in settings

## Goal
Let the user override the app language from the settings screen: System
default (follow phone), English, Deutsch, Français, Español. The choice
persists on-device and applies everywhere — UI strings, quote content,
notifications, home widget — immediately, without restarting the app.

## Scope
- In: `lib/features/settings/settings_screen.dart`, prefs layer
  (`lib/core/prefs/**`), `lib/app/app.dart` (apply override via `locale:`),
  `lib/core/locale/locale_provider.dart`, background locale resolution
  (`notification_service.dart` `_notificationL10n`, `home_widget_service.dart`,
  `notification_coordinator.dart`), `lib/l10n/app_*.arb` (new keys), tests.
- Out: quote content JSON, DB schema, onboarding (no language step — the app
  already starts in the device language).

## Requirements
1. **Pref:** store an optional language code (`null` = system default) via the
   existing shared_preferences repository pattern. Default `null`.
2. **Settings UI:** a "Language" row (follow the screen's existing row style)
   opening a picker with: System default (localized label, ARB key), then
   English, Deutsch, Français, Español. Language names are **endonyms and stay
   literal** (never translated) — that's intentional, note it in code. Current
   selection shown as the row subtitle.
3. **Apply:** `MaterialApp.router` gets `locale:` from a riverpod provider
   (null = system). Changing the setting rebuilds the app into the new language
   immediately — no restart.
4. **Quote content follows:** `localeCodeProvider` (015) must resolve from the
   override when set, else the system locale, so quotes switch in the same
   frame as the UI.
5. **Background paths follow:** notifications (`_notificationL10n`) and the
   home-widget text must use the override when set, not raw
   `PlatformDispatcher.instance.locale`. After a language change, trigger the
   existing notification reschedule and a home-widget refresh so both flip
   promptly (reuse existing mechanisms — the daily reschedule-on-launch from
   013's report and the widget update service; no new scheduling logic).
6. **Unsupported system locale** (e.g. phone set to Italian) keeps falling back
   to English exactly as today.
7. New ARB keys translated in all four ARB files (the 014 parity test will
   enforce this anyway).
8. **Tests:** pref round-trip; provider resolves override > system; a widget
   test asserting the settings flow switches visible UI text (e.g. pump,
   select Deutsch, expect "Einstellungen").

## Constraints
- Locked decisions hold (offline-first, Riverpod/drift/go_router, home_widget
  <0.8, UI-strings-only l10n + quote translations system).
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries);
  never weaken tests; l10n parity test must stay green.
- No change to locale resolution for users who never touch the setting
  (system default behavior byte-identical).

## Verify
- `flutter analyze` + `flutter test` clean/green.
- Manual path for Ammar: Settings → Language → Deutsch → whole app flips
  (tabs, quotes, settings) without restart; back to System default restores.

## Commit & push
- Conventional Commit, e.g. `feat(settings): add in-app language picker`.
- Body includes `Prompt: claude-prompts/2026-06-12/017-language-picker-setting.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/017-language-picker-setting.md` from
  TEMPLATE.md. Record how the override propagates to background paths, new ARB
  keys, verification output, commit SHA, push result, open items.
