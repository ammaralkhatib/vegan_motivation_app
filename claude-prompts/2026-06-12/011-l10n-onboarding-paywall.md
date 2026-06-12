# Localize onboarding + paywall strings

## Goal
Move every user-visible hardcoded string in the onboarding flow and the paywall
into `lib/l10n/app_en.arb`, following the pattern established in
`claude-prompts/2026-06-12/010-l10n-setup.md` (commit 9651c0f, settings feature).
App still shows identical English; strings just come from ARB.

## Scope
- In: `lib/features/onboarding/**` (onboarding_flow.dart + all steps),
  `lib/features/paywall/**` (paywall_screen.dart, paywall_data.dart,
  paywall_providers.dart, onboarding_paywall_funnel.dart), `lib/l10n/app_en.arb`,
  any test harnesses that need localization delegates.
- Out: quotes, explore, journey, habits, notifications service, share, shell,
  theme — later prompts. Quote content JSON / DB untouched (locked).

## Requirements
1. Migrate all user-visible strings in onboarding (flow + every step file) to
   `AppLocalizations.of(context)` lookups. Key prefix `onboarding...`
   (e.g. `onboardingStreakTitle`). Copy freeze: English byte-identical.
2. Migrate all user-visible strings in paywall files. Key prefix `paywall...`.
3. **Interpolated strings become ARB placeholders, never string concatenation.**
   Example: `'$trial free, then $price/year'` →
   `"paywallTrialText": "{trial} free, then {price}/year"` with placeholder
   metadata. Translators must be able to reorder words, so the full sentence
   lives in one key.
4. **Special case — name prefix fragments** (`bombshell_step.dart` etc.):
   strings like `'${namePrefix}by staying on this path you'll save ~'` are
   fragments around an animated number widget. Keep the fragment structure
   (before/after the number), but each fragment becomes its own ARB key with a
   `{name}` placeholder where needed. Handle the empty-name case inside the
   widget (pass empty string to the placeholder, keep current behavior). Add an
   `@`-description on each fragment key explaining it sits before/after an
   animated number, so a future translator has context.
5. **Special case — strings built without BuildContext** (`paywall_data.dart`,
   `paywall_providers.dart`, possibly onboarding data lists): do NOT store
   English in data classes anymore. Restructure minimally so display strings are
   resolved where a BuildContext exists (e.g. pass `AppLocalizations` into the
   builder, or store an enum/key in data and map it to l10n text in the widget).
   Pick the smallest refactor that keeps the data layer string-free; explain the
   choice in the report.
6. Not user-visible (leave alone): RevenueCat product/entitlement IDs, route
   names, keys, asset paths, analytics/log strings.
7. Pluralize where counts appear (use ARB `plural` syntax), even if English
   happens to look fine without it — German/French will need it.

## Constraints
- Locked decisions hold (offline-first, Riverpod/drift/go_router, home_widget
  <0.8, versioned content imports, UI-strings-only l10n).
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries).
  Add delegates to any test harness that pumps these screens; never weaken tests.
- No behavior change: onboarding flow order, paywall pricing logic, trial
  detection all untouched. This prompt only moves text.
- Follow the key-naming convention from CLAUDE.md §1 Localization.

## Verify
- `flutter analyze` + `flutter test` clean/green.
- `grep -rnE "Text\('|title: '|label: '" lib/features/onboarding lib/features/paywall`
  shows no user-visible English words left (IDs/keys may remain).
- Record the total number of new ARB keys added.

## Commit & push
- Conventional Commit, e.g. `feat(l10n): migrate onboarding and paywall strings to ARB`.
- Body includes `Prompt: claude-prompts/2026-06-12/011-l10n-onboarding-paywall.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/011-l10n-onboarding-paywall.md` from
  TEMPLATE.md. Record intent, the Requirement-5 refactor decision, key count,
  verification output, commit SHA, push result, open items. No full diff.
