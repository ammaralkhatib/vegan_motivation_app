# Spanish quote content — translate all 508 quotes

**Prompt:** `claude-prompts/2026-06-12/019-spanish-quote-content.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Added Spanish translations for the entire quote library — **508/508** ids — as a
`translations.es` block in `assets/content/quotes_v1.json`, and bumped the
content `version` 4 → 5 so existing users re-import (the 015 importer preserves
user state). This completes the language set (de 016, fr 018, es 019). Pure
content change on the 015 plumbing: no schema, no Dart source. Spanish-device
users (or picker choice "Español") now see every quote in Spanish; everyone else
is unaffected.

## Files touched

- `assets/content/quotes_v1.json` — `version` 4→5; new `translations.es` (508
  entries). English texts, ids, **and the German + French blocks left
  byte-identical** (verified by deep-comparing the parsed structures vs HEAD).
- `test/quote_content_translations_test.dart` — expectations bumped: locales
  `de`+`fr`+`es` present; version ≥ 5.

## Decisions

- **Matched the app's existing Spanish (`app_es.arb`) conventions** so quotes and
  UI read as one voice:
  - **Neutral international Spanish**, informal **"tú"** throughout (no
    "vosotros", no Spain-only/LatAm-only slang).
  - **`¿` and `¡` opening marks**, closing `?`/`!` and `:` `;` glued to the word
    (Spanish spacing — no space before, unlike French).
  - **« »** for quoted speech with no inner spaces (Spanish style).
  - Terminology: **"racha"** for streak, **"camino"** for journey, **"tú"**,
    **"vegano/a"** for the identity and **"vegetal" / "a base de plantas"** for
    plant-based — picked per context, kept consistent. "compassion"→compasión,
    "kindness"→**bondad**, "gentle"→**suave/dulzura**.
- **Facts keep their figures**, Spanish number formatting (period thousands
  separator): `4,000`→`4.000`, `2,000`→`2.000`, `10,000`→`10.000`,
  `7,000`→`7.000`, `200°C`→`200 °C`; `1944`/`365`/`18 gramos` unchanged.
- **Gender-neutral phrasing for the reader** wherever possible. Spanish made this
  easier than French: compound tenses with *haber* don't agree
  ("te has vuelto", "has hecho"). I leaned on those plus invariable adjectives
  (fuerte, amable, impecable) and abstract nouns ("siente orgullo" not
  "orgulloso"; "no hace falta la perfección" not "perfecto").
- **Validation in the merge step** checked Spanish punctuation before writing:
  `¿`/`?` and `¡`/`!` balance per line, balanced `« »`, and no space before
  `? ! : ;` — it reported zero issues.

## Gendered / masculine-default instances (unavoidable)

These are generic-masculine **nouns/identity or proverbs**, not second-person
adjective agreement (which was avoided throughout). A native reviewer may prefer
inclusive forms:

- **1032** "Ser vegano", **5008** "el único vegano", **5018** "siendo vegano",
  **5036** "un vegano perfecto / uno de verdad", **5014** "todo vegano que
  existe", **6012** "ser vegano" — the noun *vegano* defaults masculine; the
  neutral *veganismo* was used where the sentence allowed (e.g. 1048, 1096,
  3086, 5040, 6041).
- **5028** quoted reader speech «soy vegano» — masculine default (can't know the
  user's gender).
- **6006** "un ser humano … consigo mismo" — generic *ser humano*.
- **5023** "Nutrido vale más que perfecto" — proverb-style generic masculine.

## Sample before → after

| id | English | Spanish |
|----|---------|---------|
| 1001 | Every meal is a quiet vote for the kind of world you want to live in. | Cada comida es un voto silencioso por el mundo en el que quieres vivir. |
| 4002 | Plant-based eaters spare roughly one animal's life every single day. That's 365 lives a year. | Quien come vegetal salva más o menos una vida animal cada día. Son 365 vidas al año. |
| 5001 | Cravings pass. Values stay. Pour a glass of water, take a breath — you've got this. | Los antojos pasan. Los valores quedan. Sírvete un vaso de agua, respira: puedes con esto. |
| 6015 | One year vegan. Three hundred sixty-five days of practice, patience, and plates… 🎉 | Un año vegano. Trescientos sesenta y cinco días de práctica, paciencia y platos… 🎉 |

**Translated count: 508 / 508.**

## Verification

```
$ flutter analyze
No issues found! (ran in 3.2s)

$ flutter test
00:07 +160: All tests passed!

$ flutter test test/quote_content_translations_test.dart
00:00 +5: All tests passed!
  - content version is at least 5
  - expected locales are present (de, fr, es)
  - the library has 508 quotes
  - every locale covers exactly the quote id set
  - every translation value is a non-empty string
```

Byte-identity vs HEAD (parsed comparison): English texts identical ✓, ids
identical ✓, German block identical ✓, French block identical ✓, version 4 → 5.

Self-correction: none needed (analyze + tests green on the first run).

## Commit & push

- **Commit:** `f349a05` — `feat(content): add Spanish translations for all 508 quotes (content v5)`
- **Push:** `origin/main` — ok (`9679055..f349a05`)

## Open items for the owner

- **Native-speaker review recommended.** These are machine-authored, neutral
  international Spanish. They follow the style bar (informal "tú", idiomatic,
  ARB-consistent typography, neutral phrasing where possible), but a fluent
  reader should skim for tone/rhythm and decide on the gendered-noun instances
  listed above. Fixes are pure content edits (no version bump needed unless you
  want users to re-import).
- The language set is now complete (de/fr/es). Adding more languages later is the
  same data-only pattern (a new block under `translations` + a version bump).

## Deviations from prompt

None.
