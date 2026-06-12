# Quote content translations — schema, importer + display plumbing

## Goal
Make quote content translatable per-language without touching user state.
After this prompt the app can store and display translated quote text (device
locale, fallback English), but ships no translations yet — the 508 German
texts arrive in the next prompt as pure content. Built so French/Spanish later
are data-only additions.

## Scope
- In: `lib/core/db/database.dart` (+ codegen), `lib/core/db/daos/quote_dao.dart`,
  `lib/data/content_importer.dart`, quote display call sites (feed, detail,
  favorites, category detail, share card, home-widget bridge) as needed to pass
  the locale, `assets/content/quotes_v1.json` schema support (format only — no
  translated content yet), tests.
- Out: the German translations themselves (next prompt), UI strings (done,
  010–014), habits/journey/settings features.

## Requirements
1. **Schema:** new Drift table `QuoteTranslations`:
   `quoteId` (references Quotes.id), `locale` (text, e.g. 'de'), `body` (text),
   primary key (quoteId, locale). Add a schema migration (bump schemaVersion,
   `onUpgrade` creates the table). Run build_runner; commit generated files.
2. **Content format:** the content JSON may now carry an optional top-level
   `"translations"` block:
   ```json
   "translations": { "de": { "1001": "…", "1002": "…" } }
   ```
   (locale → quoteId-string → text). The importer upserts these into
   `QuoteTranslations` on import. Missing block / missing ids are fine —
   translations are always optional. Keep the importer idempotent and
   version-gated exactly as today; user state (isFavorite, favoritedAt,
   shownCount, inMix) stays untouched on re-import. Do NOT bump the content
   `version` in this prompt (no content change).
3. **Display resolution:** quote text shown anywhere in the app resolves as:
   translation for the current locale's language code if present, else English
   `body`. Implement at ONE seam (DAO/repository level — e.g. queries take a
   `locale` param and COALESCE a LEFT JOIN), not per-widget string juggling.
   Favorites, shownCount, ids, category logic all keep operating on the quote
   row — translation affects display text only.
4. **Home widget + share card** must show the same resolved text as the feed.
5. **Locale source:** the widget layer passes `Localizations.localeOf(context)`
   (or the riverpod-appropriate equivalent already available); background paths
   (widget update, notifications) may use `PlatformDispatcher.instance.locale`.
   Language switch must not require re-import or app reinstall.
6. **Tests:** unit tests for the importer (imports translations block; re-import
   preserves user state) and the DAO resolution (de text when locale de;
   English fallback when translation missing). Use a small inline JSON fixture.

## Constraints
- Locked decisions hold (offline-first, Riverpod/drift/go_router, home_widget
  <0.8, versioned content imports — extended here, not broken).
- Drift schema change → `dart run build_runner build`, commit generated files,
  and a migration test if the repo has the drift migration-test setup (add a
  simple upgrade smoke test if not).
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries).
- Existing users' DBs must upgrade in place — no data loss, no reset.
- English behavior must be 100% unchanged (no translations in DB yet).

## Verify
- `flutter analyze` + `flutter test` clean/green (including new tests).
- Record in the report: the exact resolution seam chosen and why, and confirm
  the migration path from current schemaVersion.

## Commit & push
- Conventional Commit, e.g. `feat(content): add quote translations table, importer and locale-aware display`.
- Body includes `Prompt: claude-prompts/2026-06-12/015-quote-translations-plumbing.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/015-quote-translations-plumbing.md` from
  TEMPLATE.md. Record schema/migration details, the resolution seam, importer
  format decision, verification output, commit SHA, push result, open items.
