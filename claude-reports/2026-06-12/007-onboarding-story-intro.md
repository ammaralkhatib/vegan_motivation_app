# Onboarding Story — Part 1: Intro + Question Bank

**Prompt:** `claude-prompts/2026-06-12/007-onboarding-story-intro.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Rebuilt onboarding from 5 skippable screens into an 18-step story funnel:
problem → solution → personal questions → a personalized "bombshell" impact stat
→ a self-persuasion question bank → a motivation chart → the existing
notifications step → the existing paywall funnel → `/today`. All answers persist;
the app is still fully usable end-to-end. Skip buttons are gone, replaced by a
slim progress bar; steps are either tap-to-continue or input-with-CTA. Animations
respect reduced motion. Analyze clean, all 121 tests pass (3 new flow tests; the
old onboarding assertions updated).

## Files touched

- `lib/features/onboarding/onboarding_flow.dart` — rewritten controller: state for
  every answer, dynamic step list, progress bar, navigation, `_finish()`.
- `lib/features/onboarding/onboarding_widgets.dart` (new) — shared
  `TapStep` / `InputStep` / `ChoiceCard` / `OnboardingProgressBar` / `FadeInLine` /
  `CountUpNumber` / `compactNumber`, all reduced-motion aware.
- `lib/features/onboarding/onboarding_copy.dart` (new) — goal/obstacle option
  lists + reflection/plain-words copy maps (shared by S10 and S15).
- `lib/features/onboarding/steps/bombshell_step.dart` (new) — S7.
- `lib/features/onboarding/steps/final_reflection_step.dart` (new) — S15.
- `lib/features/onboarding/steps/motivation_chart.dart` (new) — S17 CustomPaint.
- `lib/core/prefs/prefs_repository.dart` — 6 new keys (`ageRange`, `dietStatus`,
  `goalsPick`, `motivationDipsPerWeek` default -1, `obstacles`,
  `whyRelationship`).
- `test/onboarding_story_test.dart` (new); `test/widget_test.dart` updated.

## Decisions

- **Dynamic step list, not auto-skip.** S14 (journey date) is included in the
  step list only when `dietStatus` is `vegan`/`mostly`. Inserting a later step
  doesn't shift the indices of earlier/current pages, so the `PageController`
  position stays valid — cleaner than navigating onto S14 and bouncing off it.
  For `cutting_down`/`curious`, `setCurious()` is applied in `_finish()`.
- **Two step scaffolds.** `TapStep` (whole-screen tap target + "tap to continue →"
  hint) for steps 1/2/3/7/8/10/15; `InputStep` (CTA disabled until valid) for the
  rest. S17 (chart) and S18 (notifications) use the CTA form but are always
  enabled. The name step continues with empty input.
- **Bombshell math** uses `ImpactEstimates` × 365 × `yearsLeft`, where
  `yearsLeft = max(5, 80 − ageMidpoint)` and ageMidpoint = 19/30/40/50/60. Numbers
  count up (`TweenAnimationBuilder`) and use a compact formatter adapted from
  `_compact()`. Positive framing for vegan/mostly, negative for the rest.
- **Reduced motion** (`MediaQuery.disableAnimations`): `FadeInLine` shows its
  child immediately with no timer; `CountUpNumber` jumps to the final value.
  Matches the `AnimatedCritter` precedent — and the widget tests drive the flow
  under reduced motion.
- **Scroll safety.** Tall steps overflow on short screens, so `TapStep` content is
  wrapped in a centered scroll view, and the chart/motivation steps are
  `ListView`s; the chart is a fixed-height `CustomPaint`. (S10's content is a
  `Column`, not a nested scrollable, since `TapStep` now scrolls.)
- **Removed the onboarding theme picker** (it already lives in Settings); the rest
  of the notifications step is unchanged. The paywall funnel and `_finish()`
  ordering (mark done → funnel → `/today`) are untouched.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.5s)

$ flutter test
All tests passed!   (121 tests; 3 new)
```

New tests: the full vegan flow is driven through all 18 steps and asserts every
new pref persisted (age, diet, goals, dips, obstacles, why, motivation, name,
veganSince) plus landing on `/today`; and the journey-date step is proven skipped
for "just curious" (its headline never appears, S15 shows instead).

Self-correction: fixed on the 2nd pass. Two layout issues surfaced only when the
flow actually rendered each step at the test viewport size — a `RenderFlex`
overflow (the chart was ~496 px tall) and a nested-scrollable error after I made
`TapStep` scrollable. Fixed by sizing the chart, making the chart/motivation
steps `ListView`s, and changing S10 from a `ListView` to a `Column`. Analyze and
all tests green afterward.

Manual click-path (open item for Ammar):
- [ ] Clear app data → walk all 18 steps → bombshell shows positive copy for
      "i'm vegan", negative for "just curious".
- [ ] Finish → trial paywall → close → 80% paywall → close → lands on `/today`.

## Open items for the owner

- Parts 2 (climax) and 3 (conclusion) are separate prompts
  (`008-onboarding-climax-review.md`, `009-onboarding-conclusion-paywall.md`) and
  will insert more steps; the notifications step is a temporary tail for now.
- Unrelated to this prompt: background images now exist under
  `assets/images/backgrounds/` but `backgrounds_v1.json` still lists empty arrays
  — wiring those into the manifest is the prompt-006 follow-up, left untouched
  here.

## Commit & push

- **Commit(s):** `1ca4af4` — `feat(onboarding): story-driven intro + question bank`
  (this report's SHA stamp is a tiny follow-up `docs` commit).
- **Push:** `origin/main` — ok (`d363aff..1ca4af4`).

## Deviations from prompt

None.
