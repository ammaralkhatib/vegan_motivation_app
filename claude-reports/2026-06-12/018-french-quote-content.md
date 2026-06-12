# French quote content — translate all 508 quotes

**Prompt:** `claude-prompts/2026-06-12/018-french-quote-content.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Added French translations for the entire quote library — **508/508** ids — as a
`translations.fr` block in `assets/content/quotes_v1.json`, and bumped the
content `version` 3 → 4 so existing users re-import (the 015 importer preserves
user state). Pure content change on the 015 plumbing: no schema, no Dart source
touched. Generalized the coverage test to check every locale. French-device
users (or picker choice "Français") now see every quote in French; everyone
else is unaffected.

## Files touched

- `assets/content/quotes_v1.json` — `version` 3→4; new `translations.fr` (508
  entries). English texts, ids, **and the German block left byte-identical**
  (verified by deep-comparing the parsed structures against HEAD).
- `test/quote_content_translations_test.dart` — new, generalized coverage test
  (checks every locale under `translations`; asserts `de`+`fr` present, 508
  ids each, non-empty, version ≥ 4).
- `test/quote_content_de_test.dart` — removed (superseded by the generalized
  test above).

## Decisions

- **Matched the app's existing French (`app_fr.arb`) conventions**, not generic
  textbook French, so quote text and UI read as one voice:
  - **Straight apostrophes** `'` (the ARB uses 57 of them, zero curly).
  - **Regular space before `? ! : ;`** (e.g. "réinitialiser ?" in the ARB) —
    consistent throughout; no narrow/no-break spaces (the ARB uses none).
  - **« … »** for quoted speech (regular spaces inside), as the prompt asked.
  - Terminology: **"série"** for streak, **"parcours"** for journey, **"tu"**
    informal, **"végane"** for the identity/lifestyle and
    **"végétal(e)" / "à base de plantes"** for plant-based — picked per context,
    kept consistent. "compassion"→compassion, "kindness"→**bonté**,
    "gentle"→**douceur/doux**.
- **Facts keep their figures**, French number formatting only: `4,000`→`4 000`,
  `2,000`→`2 000`, `10,000`→`10 000`, `7,000`→`7 000`, `200°C`→`200 °C`,
  `1944`/`365`/`18 grammes` unchanged.
- **Gender-neutral phrasing for the reader** wherever possible — verb/infinitive
  forms and abstract nouns instead of agreeing participles/adjectives (e.g.
  "Pas besoin de perfection" not "parfait"; "Devenir végane, ce n'est pas
  devenir quelqu'un d'autre" using infinitives; "que tu sois là" not "resté").
- A coverage-test **validation pass in the merge step** flagged any `« »` /
  `? ! : ;` spacing slip before writing — it reported zero issues.

## Gendered / masculine-default instances (unavoidable)

These are generic-masculine **nouns or proverbs**, not second-person agreement
(which was avoided throughout):

- **5008** "le seul végane", **5014/5036** "véganes / un vrai" — the noun
  *végane* defaults masculine in French; no neutral singular exists.
- **6006** "un humain bien en accord avec lui-même" — generic *humain*.
- **6010** "Chaque cuisinier que tu admires" — generic *cuisinier*.
- **5023** "Nourri vaut mieux que parfait" — proverb-style generic masculine.

A native reviewer may prefer inclusive forms (e.g. "végane·s", or rephrasing);
all are pure content edits.

## Sample before → after

| id | English | French |
|----|---------|--------|
| 1001 | Every meal is a quiet vote for the kind of world you want to live in. | Chaque repas est un vote discret pour le monde dans lequel tu veux vivre. |
| 4002 | Plant-based eaters spare roughly one animal's life every single day. That's 365 lives a year. | Manger végétal épargne à peu près une vie animale chaque jour. Cela fait 365 vies par an. |
| 5001 | Cravings pass. Values stay. Pour a glass of water, take a breath — you've got this. | Les envies passent. Les valeurs restent. Sers-toi un verre d'eau, respire — tu vas y arriver. |
| 6015 | One year vegan. Three hundred sixty-five days of practice, patience, and plates… 🎉 | Un an de véganisme. Trois cent soixante-cinq jours de pratique, de patience et d'assiettes… 🎉 |

**Translated count: 508 / 508.**

## Verification

```
$ flutter analyze
No issues found! (ran in 3.5s)

$ flutter test
00:08 +159: All tests passed!

$ flutter test test/quote_content_translations_test.dart
00:00 +5: All tests passed!
  - content version is at least 4
  - expected locales are present (de, fr)
  - the library has 508 quotes
  - every locale covers exactly the quote id set
  - every translation value is a non-empty string
```

Byte-identity vs HEAD (parsed comparison): English texts identical ✓, ids
identical ✓, German block identical ✓, version 3 → 4.

Self-correction: none needed (analyze + tests green on the first run).

## Commit & push

- **Commit:** `3105b10` — `feat(content): add French translations for all 508 quotes (content v4)`
- **Push:** `origin/main` — ok (`c2f028c..3105b10`)

## Open items for the owner

- **Native-speaker review recommended.** These are machine-authored French.
  They follow the style bar (informal "tu", idiomatic, ARB-consistent
  typography, neutral phrasing where possible), but a fluent reader should skim
  for tone/rhythm — and decide on the gendered-noun instances listed above.
  Fixes are pure content edits (no version bump needed unless you want users to
  re-import).
- Spanish remains a data-only addition for a later prompt (same block shape,
  `translations.es`).

## Deviations from prompt

None.
