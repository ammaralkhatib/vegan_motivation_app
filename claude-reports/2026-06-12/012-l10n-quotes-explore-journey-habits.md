# Localize quotes, explore, journey + habits strings

**Prompt:** `claude-prompts/2026-06-12/012-l10n-quotes-explore-journey-habits.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Moved every user-visible string in the quotes feed, explore, journey, and
habits features into `lib/l10n/app_en.arb`, following 010/011. English is
byte-identical. **72 new ARB keys** (category 6, feed 2, quotes 4, explore 7,
favorites 3, journey 23, habits 27). Analyze clean, all 133 tests pass.

## Per-requirement status

1. **Screens migrated** ✅ — quotes (`feed…`/`quotes…`), explore (`explore…`,
   `favorites…`), journey (`journey…`), habits (`habits…`).
2. **Interpolation → placeholders, counts → plural** ✅ — error lines use a
   `{error}` placeholder; plurals on `exploreQuoteCount`, `habitsStartTracking`,
   `habitsStreak`. (See "judgment calls" for the count-as-prefix cases.)
3. **`impact_estimates.dart` — Requirement-5 refactor** ✅ — see below.
4. **Category names** ✅ — see below.
5. **Dates/weekday labels** ✅ — `week_strip.dart` dropped its hardcoded
   `['M','T','W','T','F','S','S']` list and now uses
   `DateFormat('EEEEE')` (narrow weekday) on the ambient locale; English renders
   the identical letters. Existing `DateFormat` calls (feed date header,
   journey "since", month-heatmap month name) were already locale-aware and
   left as-is.
6. **Left alone** ✅ — asset paths, route names, keys, DB column values.

## Requirement-3/5 decision: `impact_estimates.dart`

`ImpactStat` stored an English `label` ('animal lives spared', …) and is built
as a top-level `const` list with no `BuildContext`. Applied the 011 pattern:
`ImpactStat` now carries a stable **`id`** ('animals','co2','water','grain',
'forest') instead of `label`; a new `impactStatLabel(AppLocalizations, id)`
helper (in the same file) resolves the visible text. The journey widgets
(`impact_counter.dart`) call the helper. Keys live under the `journeyImpact…`
prefix since that's the only place they render. Smallest change that keeps the
data file string-free.

## Requirement-4 decision: category names

The 6 category names come from the content JSON / DB (`category.name`). The DB
is untouched (locked). Added `categoryDisplayName(l10n, id, fallbackName)` in a
new `lib/features/quotes/category_display.dart`, with ARB keys
`categoryName<Id>` for the 6 known ids and a **fallback to the raw DB name** for
any unknown id (so future content can't crash the UI). Used in the feed card
chip, the explore list, and the category-detail title. The category **emoji**
still comes from the DB (not localized).

## Judgment calls

- **Counts shown as a prefix/label, not a counted noun**, use a plain
  placeholder rather than `plural`: `journeyDayCount` ("Day {count} 🌱") and the
  per-day notification-style figures. The genuinely counted nouns
  (`{n} quote(s)`, `{n} habit(s)`, `{n}-day streak`) do use `plural`.
- **Tooltips shared across features:** the favorite/unfavorite tooltips render
  in both `quote_card` (quotes) and `QuoteListTile` (explore). Both use the
  `quotesFavorite`/`quotesUnfavorite` keys (one source of truth) rather than
  duplicating the same English under two prefixes.
- **Preset habit names** (`'${preset.emoji}  ${preset.name}'`) come from
  `lib/data/preset_habits.dart`, which is **out of scope** (only
  `impact_estimates.dart` was named). Left as-is, like quote content. The names
  become persisted habit names, so localizing display without touching the data
  file would have been inconsistent.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
All tests passed!   (133 tests)

$ grep -rnE "Text\('|title: '|label: '" lib/features/quotes lib/features/explore lib/features/journey lib/features/habits
```

The grep's only matches are **out of scope**: `share_service.dart` (the share
feature — prompt 013) and the `preset.name` interpolation above. No in-scope
user-visible English words remain.

New ARB keys: **72**. Generated `app_localizations*.dart` stay git-ignored;
`generate: true` rebuilds them.

Self-correction: none needed — analyze and the full suite were green on the
first run after wiring the four screen harnesses
(`feed_widget_test`, `quote_card_background_test`, `habit_checkoff_widget_test`,
and the `premium_gate_test` Explore harness) with the localization delegates.

## Open items (for Ammar)

- Click through Today/Explore/Journey/Habits and confirm text reads identical.
- Prompt 013: share_service, notifications, shell, theme — then ship the
  `app_de/fr/es.arb` translations.

## Commit & push

- **Commit:** `f68c2ca` — `feat(l10n): migrate quotes, explore, journey and habits strings`
- **Push:** `origin/main` — ok (`2995c78..f68c2ca`).

## Deviations from prompt

None.
