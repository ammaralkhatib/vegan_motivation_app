# Spanish quote content — translate all 508 quotes

## Goal
Ship Spanish translations for the full quote library, completing the set
(German 016, French 018). Spanish-device users (or picker choice "Español")
see every quote in Spanish. Pure content change on the 015 plumbing — no
schema or code changes expected.

## Scope
- In: `assets/content/quotes_v1.json` (add `translations.es` + version bump),
  coverage test expectation.
- Out: all Dart source (if a real plumbing bug surfaces, stop and report),
  DB schema, UI strings, the existing `de` and `fr` blocks (byte-identical).

## Requirements
1. Add `"es"` under `translations` covering **all 508 quote ids**. Bump content
   `version` 4 → 5 (existing users re-import; user state preserved — tested).
2. **Translation quality bar** (same as 016/018):
   - Informal "tú" (matches the 014 UI translations in `app_es.arb` — reuse its
     conventions and terminology so quotes and UI read as one voice).
   - **Neutral international Spanish** — avoid regionalisms (no "vosotros"
     forms, no Spain-only or LatAm-only slang); second-person singular "tú"
     conjugation throughout.
   - Natural, warm, idiomatic — rhythm over literalism. Opening ¡ and ¿ where
     the sentence calls for them.
   - Concise lines (card fits ~2–4 short lines). Keep emoji.
   - Facts keep their figures; localize number formats consistently with the
     `app_es.arb` conventions.
   - Consistent terminology across all 508 (e.g. streak → the same term the
     UI ARB uses; "plant-based" → "vegetal"/"a base de plantas" vs "vegano"
     per context, kept consistent).
   - Gender-neutral phrasing for the reader where possible; masculine default
     only when unavoidable — list instances in the report.
3. **Coverage test:** update `test/quote_content_translations_test.dart`
   expectations: locales `de`, `fr`, `es` present; version >= 5.
4. JSON formatting matches the existing file conventions.

## Constraints
- Locked decisions hold; importer/schema untouched.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries).
- Quote ids, English texts, `de` and `fr` blocks byte-identical — additions only.

## Verify
- `flutter analyze` + `flutter test` clean/green.
- Report the count (must be 508/508) and 3–4 sample before/after pairs.

## Commit & push
- Conventional Commit, e.g. `feat(content): add Spanish translations for all 508 quotes (content v5)`.
- Body includes `Prompt: claude-prompts/2026-06-12/019-spanish-quote-content.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/019-spanish-quote-content.md` from
  TEMPLATE.md. Record terminology choices, hard calls, gendered-phrasing
  instances, samples, verification output, commit SHA, push result, open items
  (native-speaker review!).
