# French quote content — translate all 508 quotes

## Goal
Ship French translations for the full quote library, exactly like the German
batch (016, commit 8f86626). French-device users (or picker choice "Français")
see every quote in French. Pure content change on the 015 plumbing — no schema
or code changes expected.

## Scope
- In: `assets/content/quotes_v1.json` (add `translations.fr` + version bump),
  coverage test.
- Out: all Dart source (if a real plumbing bug surfaces, stop and report),
  DB schema, UI strings, the existing `translations.de` block (byte-identical).

## Requirements
1. Add `"translations": { …, "fr": { … } }` covering **all 508 quote ids**.
   Bump content `version` 3 → 4 (existing users re-import; user state is
   preserved — tested in 015/016).
2. **Translation quality bar** (same as 016):
   - Informal "tu" (matches the 014 UI translations).
   - Natural, warm, idiomatic French — rhythm and punch over literalism; a
     French reader should not sense a translation. French typographic
     conventions where natural (« … » for quoted speech, espace before
     ! ? : ; — narrow no-break space or regular, consistent throughout).
   - Concise lines (card fits ~2–4 short lines). Keep emoji.
   - Facts keep their figures; localize number formats (e.g. `4 000 litres`,
     decimal comma).
   - Consistent terminology across all 508 (e.g. "végétal"/"à base de
     plantes" vs "végane" — pick per context, stay consistent; "streak" →
     one consistent French term, matching the UI ARB's choice if one exists).
   - Gender-neutral phrasing for the reader where possible (verb forms over
     gendered nouns), masculine default only when unavoidable — note instances
     in the report.
3. **Coverage test:** extend/generalize `test/quote_content_de_test.dart` (or
   add a sibling) so every locale present under `translations` is checked:
   exact id coverage, non-empty values. Assert `fr` and `de` both present and
   version >= 4.
4. JSON formatting matches the existing file conventions (UTF-8 literals,
   2-space indent, no trailing newline if that's the current state).

## Constraints
- Locked decisions hold; importer/schema untouched.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries).
- Quote ids, English texts, and the German block byte-identical — additions only.

## Verify
- `flutter analyze` + `flutter test` clean/green.
- Report the count (must be 508/508) and 3–4 sample before/after pairs.

## Commit & push
- Conventional Commit, e.g. `feat(content): add French translations for all 508 quotes (content v4)`.
- Body includes `Prompt: claude-prompts/2026-06-12/018-french-quote-content.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/018-french-quote-content.md` from
  TEMPLATE.md. Record terminology choices, hard calls, gendered-phrasing
  instances, samples, verification output, commit SHA, push result, open items
  (native-speaker review!).
