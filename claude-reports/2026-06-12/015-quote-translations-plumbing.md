# Quote content translations — schema, importer + display plumbing

**Prompt:** `claude-prompts/2026-06-12/015-quote-translations-plumbing.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

The app can now store and display translated quote text per language, with
English as the fallback — but ships **no** translations yet (the German texts
arrive in the next prompt as pure content). Added a `QuoteTranslations` Drift
table (+ migration to schemaVersion 2), taught the content importer to upsert an
optional `"translations"` block, and resolved display text at a single seam in
`QuoteDao`. Feed, category lists, favorites, the home-screen widget and
notifications all show the same resolved text. English behavior is unchanged.

## Files touched

- `lib/core/db/database.dart` — new `QuoteTranslations` table; `schemaVersion`
  1→2 with an `onUpgrade` that `createTable`s it (existing DBs upgrade in place).
- `lib/core/db/database.g.dart`, `lib/core/db/daos/quote_dao.g.dart` — Drift
  codegen (committed).
- `lib/core/db/daos/quote_dao.dart` — the resolution seam: each quote query
  takes an optional `locale` and `LEFT JOIN`s the translation, swapping the
  translated `body` into the returned row; added `watchQuoteById`.
- `lib/data/content_importer.dart` — upserts the optional `translations` block
  (locale → quoteId-string → text); idempotent, version-gated, user state never
  touched.
- `lib/core/locale/locale_provider.dart` — new `localeCodeProvider` (active
  language code) the quote providers watch.
- `lib/app/app.dart` — keeps `localeCodeProvider` in sync with the resolved UI
  locale so an OS language switch re-resolves live.
- `lib/features/quotes/providers.dart` — `quoteByIdProvider` resolves via the
  DAO + locale.
- `lib/features/explore/category_detail_screen.dart`,
  `lib/features/explore/favorites_screen.dart` — pass locale to the DAO.
- `lib/core/widgetkit/home_widget_service.dart`,
  `lib/core/notifications/notification_coordinator.dart` — background paths
  resolve text against `PlatformDispatcher.instance.locale`.
- `test/quote_translations_test.dart` — new: importer, DAO resolution, in-place
  v1→v2 migration smoke test.

## Decisions

- **Resolution seam = `QuoteDao`, via `copyWith(body: translation)`.** Each query
  adds a `LEFT OUTER JOIN` to `QuoteTranslations` on `quoteId` + `locale` and
  returns the normal `Quote` row with its `body` swapped to the translation when
  one exists. This means **every** read path (feed, lists, favorites, widget,
  notifications) and the **share card** get resolved text for free — the share
  card already receives the already-resolved `Quote` from `quoteByIdProvider`, so
  it needed no change. Favorites, shownCount, ids and category logic keep
  operating on the untouched quote row; translation is display-only.
- **English path stays literally the old query.** For `locale == null` or
  `'en'` the translation join is omitted entirely (we never store an `'en'`
  translation), so English reads `quotes.body` exactly as before — English
  behavior is byte-identical.
- **Locale source.** Foreground reads a riverpod `localeCodeProvider` synced from
  `Localizations.localeOf(context)` (the prompt's "riverpod-appropriate
  equivalent"); background paths (widget refresh, notifications) use
  `PlatformDispatcher.instance.locale` since they have no `BuildContext`. A
  language switch only changes which row is read — no re-import, no reinstall.
- **`feedQueueProvider` deliberately gets no locale** — it returns only ids /
  ordering, so translation can't and shouldn't reshuffle the daily queue.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.1s)

$ flutter test
00:04 +150: All tests passed!
```

New `test/quote_translations_test.dart` (8 tests): importer imports/skips the
block and preserves user state on re-import; DAO returns German where present and
falls back to English otherwise (and for fully-untranslated locales / null /
`'en'`); `getQuoteById` + `getQuotesInMix` resolve; **v1→v2 upgrades in place,
recreating the table and keeping favorites**.

Self-correction: fixed 3 lint infos on attempt 1 (redundant `dart:ui` import,
unused test import, null-aware map entry); analyze then clean.

## Migration path

Current users are on `schemaVersion 1`. On next launch Drift sees `user_version`
1 < 2 and runs `onUpgrade(from:1, to:2)` → `createTable(quoteTranslations)`. No
existing table is altered, so quotes/categories/habits and all user state
(favorites, shownCount, mix) survive untouched. Fresh installs get the table via
the default `onCreate`/`createAll`. Both paths are exercised by tests.

## Commit & push

- **Commit:** `68c58b8` — `feat(content): add quote translations table, importer and locale-aware display`
- **Push:** `origin/main` — ok (`82aeb54..68c58b8`)

## Open items for the owner

- None for this prompt. The German translations land next prompt as a
  `"translations"` block in the content JSON (with a `version` bump there).

## Deviations from prompt

None.
