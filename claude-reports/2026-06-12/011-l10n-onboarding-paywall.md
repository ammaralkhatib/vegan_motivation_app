# Localize onboarding + paywall strings

**Prompt:** `claude-prompts/2026-06-12/011-l10n-onboarding-paywall.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Moved every user-visible string in the onboarding flow (the 27-step story +
all 8 step widgets + shared copy maps) and the paywall (screen + data) into
`lib/l10n/app_en.arb`, following the settings pattern from 010 (commit 9651c0f).
English is byte-identical — this only relocates text. **175 new ARB keys**
(150 `onboarding…`, 25 `paywall…`). Analyze clean, all 133 tests pass.

## Per-requirement status

1. **Onboarding migrated** ✅ — flow + every step file reads from
   `AppLocalizations.of(context)`. Key prefix `onboarding…`.
2. **Paywall migrated** ✅ — `paywall_screen.dart` + `paywall_data.dart`. Key
   prefix `paywall…`. (`paywall_providers.dart` and
   `onboarding_paywall_funnel.dart` had no user-visible strings — untouched.)
3. **Interpolation → placeholders, no concatenation** ✅ — e.g. the trial line
   is one key `paywallTrialText: "{trial} free, then {price}/year"`; reflection
   lines are `onboardingReflectionGoalLine: "you want {goal}"` etc. Bold
   headlines keep the **whole sentence in one key** plus a separate
   `…Emphasis` key; a helper splits the sentence around the emphasis word at
   render time, so translators can reorder freely (no fragment-per-word).
4. **Name-prefix fragments** ✅ — the bombshell number lines stay as
   before/after fragments around the animated `CountUpNumber`. Each fragment is
   its own key with an `@description` saying it sits before/after a number.
   The name is a `{name}` placeholder; the widget passes `"Sam, "` or `""`
   (empty-name handled in the widget, behavior unchanged). The S22 plan headline
   and S18 spark headline use the same before-fragment + named-variant approach.
5. **Strings built without BuildContext — the refactor** ✅ — see below.
6. **Non-visible left alone** ✅ — RevenueCat IDs, route names, prefs ids, asset
   paths, log strings untouched.
7. **Plurals** ✅ — used ARB `plural` where a count governs a noun:
   `paywallTrialDuration{Days,Weeks,Months,Years}`, `onboardingDipsUnit`,
   `onboardingReflectionDips`, `onboardingSnapshotDipsValue`.

## Requirement-5 decision (string-free data layer)

Two data layers held English and are built **without** a `BuildContext`:

- **`paywall_data.dart`.** `PaywallData` previously stored `title`, `ctaLabel`,
  `subtitle`, `trialText`, `badgeText` (English) — built by `buildPaywallData`
  inside a `FutureProvider`. I shrank `PaywallData` to **store facts only**:
  `variant`, `priceString`, `anchorPriceString` (real store prices — not
  localized), and the trial as a raw `trialPeriodCount` + `trialPeriodUnit`
  (new `TrialPeriodUnit` enum, decoupled from the RevenueCat SDK enum). All
  copy — title, CTA, badge, subtitle, trial line — is now resolved in the
  widget (`PaywallView` / `_PriceBlock`) from `variant` via small
  `_paywallTitle/_paywallCta/_paywallBadge/_paywallSubtitle/_trialText`
  helpers. This was the smallest change that keeps the data layer string-free:
  the `variant` enum already encoded every copy difference, so no new mapping
  state was needed.
- **`onboarding_copy.dart`.** Was `const` maps/lists of `(id, English)`. Now it
  holds **id lists** (`goalIds`, `obstacleIds`, `commitmentIds`) + the numeric
  `commitmentBarFill` map + pure `String fn(AppLocalizations, id)` lookup
  helpers (`goalLabel`, `goalReflection`, `goalPlainWords`, `obstacleLabel`,
  `obstaclePlainWords`, `commitmentLabel`, `commitmentResponse`). Ids stay the
  prefs contract; text is resolved where context exists. The inline
  `_dietOptions/_whyOptions/_motivationOptions` tuples in `onboarding_flow.dart`
  got the same id-list + local-label-helper treatment.

Tests followed the architecture: `paywall_data_test.dart` now asserts the
**structured** fields (`trialPeriodCount`, `anchorPriceString`, `hasTrial`)
instead of English; the copy assertions (badge text, CTA, urgency) moved to the
widget-level `paywall_view_test.dart` (which renders real l10n). No test was
weakened — coverage moved to match where the strings now live.

## Test harnesses

Added the localization delegates to every harness that pumps these screens:
`onboarding_funnel_test`, `onboarding_story_test`, `paywall_view_test`,
`paywall_screen_test`, and `premium_gate_test` (its Explore→paywall route).
`photo_feed_polish_test` already had them (010) and uses a stub paywall route.
`widget_test` pumps the full `VeggieApp`, which carries delegates since 010.

## Intentional non-localized literals

`grep -rnE "Text\('|title: '|label: '" lib/features/onboarding lib/features/paywall`
shows only: `Text('Veggie')` (brand name), `'$_dips'` / `'$percent%'` (numbers),
and `'🌱'` (emoji). Age ranges (`14–24` …) stay literal — numeric tokens, not
words. No translatable English remains.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
All tests passed!   (133 tests)
```

New ARB keys: **175** (150 `onboarding…`, 25 `paywall…`). Generated
`app_localizations*.dart` stay git-ignored (010 setup); the build regenerates
them via `generate: true`.

Self-correction (within the 2-attempt budget): first `flutter test` surfaced
two harnesses still missing delegates after the migration —
`photo_feed_polish_test` (caught in the first pass) and `premium_gate_test`
(its paywall route). Added delegates and the suite went green.

## Open items (for Ammar)

- Click through onboarding end-to-end and open all three paywalls — text should
  read identical to before.
- Later prompts: migrate the remaining features (quotes, explore, journey,
  habits, notifications service, share, shell), then add `app_de/fr/es.arb`.

## Commit & push

- **Commit:** `613a2fe` — `feat(l10n): migrate onboarding and paywall strings to ARB`
- **Push:** `origin/main` — ok (`c710cd3..613a2fe`).

## Deviations from prompt

None. (Bold headlines use a whole-sentence + emphasis-substring split rather
than per-word fragments — a stricter reading of Requirement 3's "no
concatenation"; the fragment pattern from Requirement 4 is still used for the
animated-number lines and the trailing-date headline, where a widget/price sits
mid-sentence.)
