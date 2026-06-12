# Add German, French + Spanish translations

## Goal
Ship `app_de.arb`, `app_fr.arb`, `app_es.arb` so the app follows the device
language for German, French, and Spanish users. Every one of the ~309 keys in
`app_en.arb` gets a translation — no fallback-to-English gaps.

## Scope
- In: `lib/l10n/app_de.arb`, `app_fr.arb`, `app_es.arb` (new), `l10n.yaml`,
  `ios/Runner/Info.plist`, `lib/l10n/app_en.arb` only if a key needs an
  `@description` clarified (no English copy changes), tests.
- Out: all Dart feature code (no source changes should be needed), quote
  content DB (locked — quotes stay English), Android native files.

## Requirements
1. Create the three ARB files with `"@@locale"` set, translating every message
   key from `app_en.arb`. Do not copy `@`-metadata into the translation files
   (metadata lives in the template only).
2. **Tone: informal address** — German "du", French "tu", Spanish "tú".
   Friendly, warm, concise — it's a motivation app. Keep emoji as-is.
3. **Placeholders survive verbatim** — `{name}`, `{count}`, `{price}` etc. must
   appear in every translation, reordered as the language needs. Plural keys
   get correct plural forms per language (German/French/Spanish each handle
   `one`/`other`; French treats 0 as singular — follow CLDR rules, gen_l10n
   enforces them).
4. **Brand + product terms stay untranslated:** "Veggie", "Veggie Premium",
   store price strings. Quote category names DO get translated
   (`categoryName…` keys).
5. Add `untranslated-messages-file: build/untranslated_messages.json` to
   `l10n.yaml`. After generation, the file must show zero untranslated keys for
   de/fr/es — include its content (or emptiness) in the report.
6. Add a test that parses the four ARB files and asserts: identical key sets,
   and identical placeholder sets per key across all locales. This guards every
   future string addition.
7. iOS: add `CFBundleLocalizations` (en, de, fr, es) to `ios/Runner/Info.plist`
   so iOS exposes the languages properly.
8. Length sanity: German/French run ~30% longer than English. Flag in the
   report any translation you suspect may overflow tight UI (bottom-tab labels,
   chip labels, paywall badge) — do not change code, just list them.

## Constraints
- Locked decisions hold (offline-first, UI-strings-only l10n, etc.).
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries).
- No English copy changes; no Dart source changes (supportedLocales comes from
  the generated AppLocalizations automatically).
- These are machine translations to be reviewed by native speakers before
  release — note this in the report and add it as an open item.

## Verify
- `flutter analyze` + `flutter test` clean/green (including the new parity test).
- `untranslated_messages.json` empty / absent.
- Spot-render check if cheap (e.g. a widget test pumping one screen under
  `Locale('de')` asserting a known German string appears).

## Commit & push
- Conventional Commit, e.g. `feat(l10n): add German, French and Spanish translations`.
- Body includes `Prompt: claude-prompts/2026-06-12/014-l10n-de-fr-es-translations.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/014-l10n-de-fr-es-translations.md` from
  TEMPLATE.md. Record tone choices, any tricky translations (and why), the
  overflow-risk list, verification output, commit SHA, push result, open items.
