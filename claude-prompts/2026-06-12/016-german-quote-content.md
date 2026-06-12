# German quote content — translate all 508 quotes

## Goal
Ship German translations for the full quote library. German-device users see
every quote in German; everyone else is unaffected. Pure content change riding
on the 015 plumbing — no schema or code changes expected.

## Scope
- In: `assets/content/quotes_v1.json` (add `"translations"` block + version
  bump), a coverage test.
- Out: all Dart source (unless a real bug in the 015 plumbing surfaces — if so,
  stop and report rather than patching around it), DB schema, UI strings.

## Requirements
1. Add a `"translations": { "de": { … } }` block covering **all 508 quote ids**
   (the format the importer expects from 015). Bump content `version` 2 → 3 so
   existing users re-import (user state is preserved by the importer — already
   tested in 015).
2. **Translation quality bar.** These are short motivational lines — translate
   for feeling, not word-for-word:
   - Informal "du" (matches the UI translations from 014).
   - Natural, warm, idiomatic German — rhythm and punch over literalism. A
     German reader should not sense a translation.
   - Keep each line concise (target similar length; the card UI fits ~2–4
     short lines). Keep any emoji.
   - Facts stay facts: numbers/units in the `facts` category translate
     faithfully (convert phrasing, never the figures).
   - Consistent terminology across all 508 (e.g. always "pflanzlich" vs
     mixing in "vegan" arbitrarily — pick per context but stay consistent).
3. **Coverage test:** add `test/quote_content_de_test.dart` that loads the
   asset JSON and asserts: `translations.de` covers exactly the set of quote
   ids (no missing, no orphans), all values non-empty strings, and version >= 3.
4. JSON stays valid UTF-8, pretty-printed consistently with the current file.

## Constraints
- Locked decisions hold; importer/schema untouched.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries).
- Quote ids and English texts byte-identical — only additions.

## Verify
- `flutter analyze` + `flutter test` clean/green (incl. the coverage test).
- Report the translated count (must be 508/508) and quote 3–4 sample
  before/after pairs in the report for the record.

## Commit & push
- Conventional Commit, e.g. `feat(content): add German translations for all 508 quotes (content v3)`.
- Body includes `Prompt: claude-prompts/2026-06-12/016-german-quote-content.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/016-german-quote-content.md` from
  TEMPLATE.md. Record terminology choices, any quotes that were hard to
  translate (and what you did), samples, verification output, commit SHA, push
  result, open items (native-speaker review!).
