# Localization setup + first migrated feature (settings)

## Goal
Prepare the app for multiple languages (German, French, Spanish coming later).
Set up Flutter's official localization (gen_l10n + ARB files), wire it into the
app, and migrate the settings feature's hardcoded strings as the reference
pattern for all later migrations. After this prompt the app still shows English
only, but settings strings come from the ARB file instead of being hardcoded.

## Scope
- In: `pubspec.yaml`, new `l10n.yaml`, new `lib/l10n/app_en.arb`,
  `lib/app/app.dart`, `lib/features/settings/settings_screen.dart`,
  `lib/features/settings/notification_settings_screen.dart`.
- Out: every other feature (onboarding, paywall, quotes, explore, journey,
  habits, notifications service, share, shell) — they migrate in later prompts.
  Do NOT touch the quotes content JSON or the DB importer — quote content stays
  English for now (locked: UI-only localization in this phase).

## Requirements
1. Add `flutter_localizations` (sdk: flutter) to dependencies. `intl` is already
   present; keep its version as is unless gen_l10n demands a bump.
2. Create `l10n.yaml` at repo root with: `arb-dir: lib/l10n`,
   `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`,
   `nullable-getter: false`.
3. Create `lib/l10n/app_en.arb` with `"@@locale": "en"`. Key naming convention
   (this is the pattern all later prompts follow): `<feature><Description>` in
   lowerCamelCase, e.g. `settingsTitle`, `settingsNotificationsDaily`. Strings
   with variables use ARB placeholders (e.g. `"habitStreakDays": "{count} days"`
   with proper `@`-metadata and plural forms where counts are involved).
4. In `lib/app/app.dart` (`MaterialApp.router`): set
   `localizationsDelegates: AppLocalizations.localizationsDelegates` and
   `supportedLocales: AppLocalizations.supportedLocales`. Locale resolution stays
   default (follow device language) — no in-app picker.
5. Migrate ALL user-visible hardcoded strings in the two settings screens to
   `AppLocalizations.of(context)` lookups. User-visible = anything rendered on
   screen (Text, labels, titles, hints, tooltips, SnackBars, dialog buttons,
   semanticLabels). Not user-visible (leave alone): route names, keys, asset
   paths, debug/log strings, channel IDs.
6. The generated `app_localizations*.dart` files: gen_l10n writes them under
   `.dart_tool/` by default with `generate: true` — confirm the build picks them
   up; do not commit generated files from `.dart_tool/`.
7. Add a short "Localization" subsection to CLAUDE.md §1 conventions: ARB
   workflow, key naming rule, and the locked decision "UI strings only — quote
   content is not localized in this phase".

## Constraints
- Locked decisions hold: offline-first, Riverpod/drift/go_router untouched,
  home_widget pinned <0.8, versioned content imports untouched.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries,
  CLAUDE.md §2). If existing widget tests pump widgets that now need
  localizations, add the delegates to those test harnesses — do not delete or
  weaken tests.
- English wording must stay exactly as it is today (copy freeze) — this prompt
  moves strings, it does not rewrite them.

## Verify
- `flutter analyze` and `flutter test` both clean/green.
- `grep -rn "Text('" lib/features/settings/` returns no user-visible hardcoded
  strings (icons/keys may remain).
- App builds and settings screens render identical English text (record that
  you ran `flutter build` or at minimum analyze+test; Ammar will click through
  settings locally).

## Commit & push
- Conventional Commit, e.g. `feat(l10n): add gen_l10n setup and migrate settings strings`.
- Body includes `Prompt: claude-prompts/2026-06-12/010-l10n-setup.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/010-l10n-setup.md` from TEMPLATE.md
  (mkdir -p the folder). Record intent, decisions (especially any key-naming
  judgment calls), verification output, commit SHA, push result, open items.
  No full diff.
