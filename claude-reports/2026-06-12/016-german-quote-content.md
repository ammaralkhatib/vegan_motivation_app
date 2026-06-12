# German quote content — translate all 508 quotes

**Prompt:** `claude-prompts/2026-06-12/016-german-quote-content.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Added German translations for the entire quote library — **508/508** ids — as a
`translations.de` block in `assets/content/quotes_v1.json`, and bumped the
content `version` 2 → 3 so existing users re-import (the 015 importer preserves
user state). Pure content change on the 015 plumbing: no schema, no Dart source
touched. Added a coverage test. German-device users now see every quote in
German; everyone else is unaffected.

## Files touched

- `assets/content/quotes_v1.json` — `version` 2→3; new top-level
  `translations.de` (508 entries, id-string → German text). All English quote
  texts and ids left byte-identical (verified: zero `"text"` lines changed in
  the diff; only the version line and `]`→`],` deletions plus the appended
  block).
- `test/quote_content_de_test.dart` — new coverage test.

## Decisions

- **Translation style.** Informal **"du"** throughout (matches the 014 UI
  translations), warm and idiomatic — translated for feeling, not word-for-word.
  Kept lines short to fit the card (~2–4 lines) and preserved every emoji
  (🌱 🍝 🍫 🎉 🏆 👏).
- **Terminology consistency** across all 508:
  - "plant-based" → **"pflanzlich"** (never randomly "vegan"); "vegan" reserved
    for the identity/lifestyle ("vegan zu sein", "veganer Geburtstag").
  - "compassion" → **"Mitgefühl"**, "kindness/gentle" → **"Güte"/"sanft"**,
    "values" → **"Werte"**, "streak" → **"Serie"**, "plate" → **"Teller"**.
- **Facts keep their figures.** Numbers/units translated faithfully, never
  changed: `365`, `30 km`, `20-mal`, `1944`, `7.000 Sorten`, `18 Gramm`, etc.
  Only the phrasing and number format were localised (German thousands
  separator, e.g. `4,000 litres` → `4.000 Liter`; `200°C` → `200 °C`).
- **Gender-neutral address.** Avoided gendered nouns about the reader (e.g.
  "you've become a better cook" → "kochst du viel besser", verb form not
  "Köchin/Koch"; "eats like royalty" → "speist fürstlich").
- **No trailing newline / 2-space indent / literal UTF-8** to match the existing
  file exactly (it uses `ensure_ascii=False`, no `\u` escapes, no final newline).

## Hard-to-translate calls (for the record)

- **5008 "the room now contains a vegan"** — kept the deliberate flip:
  "Im Raum ist jetzt ein Veganer." Generic masculine; a native review may prefer
  a neutral rephrase.
- **1069 "climate diplomacy" / 3083 "frequent flyer program"** — kept the
  playful metaphors ("Klimadiplomatie", "Vielfliegerprogramm") rather than
  flattening them.
- **3043 "standing ovation" / 3034 "superpower in comfortable shoes"** — left
  the anglicisms that read naturally in German ("Standing Ovation",
  "Superkraft in bequemen Schuhen").
- **6005 / 6051 / 5024 etc.** — quoted speech rendered with German quotation
  marks „ … " for typographic correctness.

## Sample before → after

| id | English | German |
|----|---------|--------|
| 1001 | Every meal is a quiet vote for the kind of world you want to live in. | Jede Mahlzeit ist eine leise Stimme für die Welt, in der du leben möchtest. |
| 4002 | Plant-based eaters spare roughly one animal's life every single day. That's 365 lives a year. | Wer pflanzlich isst, verschont etwa jeden Tag ein Tierleben. Das sind 365 Leben im Jahr. |
| 5001 | Cravings pass. Values stay. Pour a glass of water, take a breath — you've got this. | Gelüste vergehen. Werte bleiben. Gieß dir ein Glas Wasser ein, atme durch – du schaffst das. |
| 6015 | One year vegan. Three hundred sixty-five days of practice, patience, and plates… 🎉 | Ein Jahr vegan. Dreihundertfünfundsechzig Tage Übung, Geduld und Teller… 🎉 |

**Translated count: 508 / 508.**

## Verification

```
$ flutter analyze
No issues found! (ran in 3.1s)

$ flutter test
00:06 +153: All tests passed!

$ flutter test test/quote_content_de_test.dart
00:00 +3: All tests passed!
  - content version is at least 3
  - translations.de covers exactly the quote id set (508, no missing/orphans)
  - every German translation is a non-empty string
```

Self-correction: none needed (analyze + tests green on the first run).

## Commit & push

- **Commit:** `8f86626` — `feat(content): add German translations for all 508 quotes (content v3)`
- **Push:** `origin/main` — ok (`db67b82..8f86626`)

## Open items for the owner

- **Native-speaker review recommended.** These are machine-authored German.
  They follow the style bar (informal "du", idiomatic, consistent terms), but a
  fluent German reader should skim for tone/rhythm before release — especially
  the playful metaphors and the few anglicisms noted above. Fixes are pure
  content edits (no version bump needed unless you want users to re-import).
- French/Spanish remain data-only additions for later prompts (same block
  shape, e.g. `translations.fr`, `translations.es`).

## Deviations from prompt

None.
