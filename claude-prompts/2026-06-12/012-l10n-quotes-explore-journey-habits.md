# Localize quotes, explore, journey + habits strings

## Goal
Move every user-visible hardcoded string in the quotes feed, explore,
journey, and habits features into `lib/l10n/app_en.arb`, following the
established pattern (010 settings, 011 onboarding/paywall). English stays
byte-identical.

## Scope
- In: `lib/features/quotes/**` (feed_screen, quote_card, quote_detail_screen —
  NOT share_service, that's prompt 013), `lib/features/explore/**`,
  `lib/features/journey/**`, `lib/features/habits/**`,
  `lib/data/impact_estimates.dart` (user-visible impact labels),
  `lib/l10n/app_en.arb`, test harnesses as needed.
- Out: share_service.dart, notifications, shell, theme (prompt 013). Quote
  content from the DB (the 508 quotes) stays untouched — locked. Category
  *names* shown in UI: see Requirement 4.

## Requirements
1. Migrate quotes screens (key prefix `quotes…` / `feed…`), explore screens
   (`explore…`), journey screen (`journey…`), habits screens (`habits…`).
   Copy freeze.
2. Interpolated strings → one ARB key with placeholders (011 rule). Counts get
   ARB `plural` (streak days, habit counts, favorites counts, impact numbers).
3. `lib/data/impact_estimates.dart`: if it stores user-visible English labels,
   apply the 011 Requirement-5 pattern — data layer keeps ids/numbers, widgets
   resolve text via AppLocalizations. Smallest refactor that works; explain in
   the report.
4. **Category names** (the 6 quote categories shown in explore/feed chips):
   if they come from the DB/content JSON, do NOT touch the DB — map category id
   → localized display name in the UI layer (`categoryDisplayName(l10n, id)`
   helper, ARB keys `categoryName<Id>`). If a category id has no mapping, fall
   back to the raw DB name so future content can't crash the UI.
5. Dates/weekday labels (month heatmap, journey): use `intl` DateFormat with
   the ambient locale instead of hardcoded English month/weekday strings, where
   applicable.
6. Leave alone: asset paths, route names, keys, log strings, DB column values.

## Constraints
- Locked decisions hold (offline-first, Riverpod/drift/go_router, home_widget
  <0.8, versioned content imports, UI-strings-only l10n).
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries).
  Add delegates to harnesses as needed; never weaken tests.
- No behavior change; no DB schema change (no build_runner needed).

## Verify
- `flutter analyze` + `flutter test` clean/green.
- `grep -rnE "Text\('|title: '|label: '" lib/features/quotes lib/features/explore lib/features/journey lib/features/habits`
  shows no user-visible English words (numbers/emoji/brand may remain).
- Record the number of new ARB keys.

## Commit & push
- Conventional Commit, e.g. `feat(l10n): migrate quotes, explore, journey and habits strings`.
- Body includes `Prompt: claude-prompts/2026-06-12/012-l10n-quotes-explore-journey-habits.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/012-l10n-quotes-explore-journey-habits.md`
  from TEMPLATE.md. Record the impact_estimates and category-name decisions,
  key count, verification output, commit SHA, push result, open items.
