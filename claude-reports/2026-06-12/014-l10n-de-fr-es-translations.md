# Add German, French + Spanish translations

**Prompt:** `claude-prompts/2026-06-12/014-l10n-de-fr-es-translations.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Added `app_de.arb`, `app_fr.arb`, `app_es.arb` — every one of the 309 message
keys translated, zero fallback-to-English gaps. The app now follows the device
language for German, French, and Spanish (plus English). No Dart source changes;
`supportedLocales` updated itself from the generated `AppLocalizations`. Analyze
clean, all 140 tests pass (7 new), `untranslated_messages.json` absent.

## Per-requirement status

1. **Three ARB files, all keys, `@@locale` set, no `@`-metadata copied** ✅.
2. **Informal address** ✅ — German "du", French "tu", Spanish "tú" throughout.
   Warm and concise; emoji kept verbatim.
3. **Placeholders verbatim + plurals** ✅ — `{name}`, `{count}`, `{price}`,
   `{trial}`, `{goal}`, `{obstacle}`, `{error}`, `{date}` all preserved
   (reordered where the grammar needs it). Plural keys use CLDR `one`/`other`
   for each language; gen_l10n validated them with no warnings.
4. **Brand/product terms kept** ✅ — "Veggie" and "Veggie Premium" untranslated;
   `{price}` is the store string. Category names **are** translated
   (`categoryName…`).
5. **`untranslated-messages-file`** ✅ — added to `l10n.yaml`
   (`build/untranslated_messages.json`). After generation the file is **absent**,
   which gen_l10n only does when there are **zero** untranslated keys for any
   locale (it writes + warns otherwise).
6. **Parity test** ✅ — `test/l10n_parity_test.dart` parses all four ARB files
   and asserts (a) identical message-key sets and (b) identical placeholder sets
   per key across locales. Placeholder extraction uses
   `\{\s*([A-Za-z]\w*)\s*[,}]` so it captures real ICU args and ignores plural
   literals like `{1 Tag}`. Guards every future string add.
7. **iOS `CFBundleLocalizations`** ✅ — added `en, de, fr, es` to
   `ios/Runner/Info.plist`.
8. **Length/overflow flags** ✅ — see list below.

## Tone choices

- **German:** informal "du", nouns capitalised (so the emphasis words in the
  bold headlines are capitalised too, e.g. "Motivation", "Warum"). The English
  lowercase styling can't carry over (German orthography), so German reads in
  natural sentence case.
- **French & Spanish:** informal "tu"/"tú", lowercase styling kept where natural.
- **Gender (FR/ES):** where an adjective refers to the user and a neutral
  rephrase was awkward, I used the conventional **masculine** default (e.g.
  FR "déterminé", "seul"; ES "vegano", "decidido", "solo"). A native reviewer
  should adapt for inclusivity — flagged as an open item.

## Tricky translations (and why)

- **Bold-headline split.** The UI bolds a substring by locating it inside the
  full sentence (`onboarding…Emphasis`). Each translated headline was written to
  **contain its emphasis substring verbatim** so the split still works:
  DE "Motivation"/"Warum"/"2 Minuten"/"dich", FR "motivation"/"pourquoi"/
  "2 minutes"/"toi", ES "motivación"/"porqué"/"2 minutos"/"ti". The parity test
  doesn't check this (it's not a placeholder), so it's noted here for reviewers.
- **Bombshell number fragments.** The animated number sits mid-sentence between
  a `…Before` and `…After` fragment. Translations keep that structure and the
  leading/trailing spaces, and reflow the sentence around the number
  (e.g. DE "…rettest du ~" + N + " Tiere").
- **`{name}` carrying punctuation.** In the bombshell `…Before` keys `{name}` is
  "Sam, " or "" — kept first so "Sam, wenn du…" / "Sam, en restant…" /
  "Sam, si sigues…" read naturally.
- **Trial duration composes into `paywallTrialText`.** Plurals
  (`paywallTrialDuration*`) feed `{trial}` into "{trial} gratis, danach …" etc.;
  kept consistent gender/number across the pieces.
- **Discount badges** localised the "% OFF" wording: DE "50% RABATT",
  FR "-50 %", ES "50 % DTO.".

## Overflow-risk list (no code changed — review on device)

- **Bottom-tab labels** (tightest space): DE "Gewohnheiten" (Habits) and
  "Entdecken" (Explore); FR "Aujourd'hui" (Today). These are noticeably longer
  than the English and may wrap/ellipsize on narrow phones.
- **Paywall badge:** DE "80% RABATT — einmaliges Angebot" is long for the pill;
  FR/ES are shorter.
- **Buttons:** DE "Käufe wiederherstellen", "Gewohnheit hinzufügen" and
  "Änderungen speichern" run long but sit on full-width buttons, so low risk.
- **Onboarding chips:** DE "Wirkungs-Tracking inklusive",
  FR "6 petites bêtes qui t'encouragent" are wider than the English chips.

## Verification

```
$ flutter gen-l10n        # build/untranslated_messages.json → absent (0 untranslated)
$ flutter analyze
No issues found! (ran in 2.6s)
$ flutter test
All tests passed!   (140 tests; 7 new in l10n_parity_test.dart)
```

Spot-render: the parity test pumps a widget under `Locale('de')` and asserts the
German "Einstellungen" and "Heute" appear — confirms the de bundle loads and
resolves end-to-end.

## Open items (for Ammar)

- **These are machine translations.** Have native German / French / Spanish
  speakers review before release — especially the FR/ES gendered adjectives
  (currently masculine default) and the marketing copy (paywall, onboarding).
- Check the overflow-risk items above on a narrow device.
- App Store / Play Store listings and the store product descriptions are
  separate from in-app strings and still need localising (out of scope here).

## Commit & push

- **Commit:** `<filled by stamp>` — `feat(l10n): add German, French and Spanish translations`
- **Push:** `<filled by stamp>`

## Deviations from prompt

None.
