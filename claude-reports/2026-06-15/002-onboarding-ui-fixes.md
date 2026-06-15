# Onboarding UI fixes (batch)

**Prompt:** `claude-prompts/2026-06-15/002-onboarding-ui-fixes.md`
**Completed:** 2026-06-15 · **Status:** done

## Summary

Four unrelated visual bugs in the onboarding flow. Fixed all four: the keyboard
now hides when leaving the name step, the two overflow stripes (first-spark quote
card and snapshot value card) are gone, and the loading ring is bigger and clearer.
No behaviour changes beyond these. `QuoteCard` and the main quote feed were not
touched, so the feed stays pixel-identical. Analyze clean, all 166 tests green.

## Files touched

- `lib/features/onboarding/onboarding_flow.dart` — `_next()` now calls
  `FocusScope.of(context).unfocus()` first, so advancing drops keyboard focus for
  the name step (and any future text input) in one central spot.
- `lib/features/onboarding/steps/first_spark_step.dart` — quote box height 380 → 480
  so the full `QuoteCard` fits without overflow. The step is a `ListView`, so it can
  still scroll on a small phone.
- `lib/features/onboarding/steps/loading_step.dart` — ring box 96 → 130, strokeWidth
  6 → 8, and the `%` label bumped `titleMedium` → `headlineSmall` so it stays legible
  inside the bigger ring. Timing and checklist untouched.
- `lib/features/onboarding/steps/snapshot_step.dart` — `_ValueCard` value `Text`
  wrapped in `Flexible` with `textAlign: TextAlign.end` (plus a 12px gap), so a long
  strengths value wraps instead of overflowing the row.

## Decisions

- **Requirement 2: height-only fix, `QuoteCard` NOT touched.** The prompt's
  "nudge the quote text smaller" was optional ("Recommended"). Just growing the box
  to 480 removes the overflow and keeps the card fully visible and readable, and it
  guarantees the feed is byte-for-byte unchanged (the harder, riskier option of an
  opt-in compact flag wasn't needed). The feed stays pixel-identical because nothing
  in `quote_card.dart` changed.
- **Loading `%` style → `headlineSmall`.** Within "adjust to taste"; reads well
  centred in the 130px ring.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.7s)

$ flutter test
All tests passed!  (166 tests, +166)
```

Self-correction: none — clean on first run. No test asserted the old ring size or
card height, so no test changes were needed.

Manual click-path: not run in this environment (no device/simulator). Code-level
expectation per requirement:
- [x] name step → `_next()` unfocuses before paging, keyboard closes.
- [x] first-spark → 480px box holds the card, no overflow stripe.
- [x] loading → 130×130 ring, strokeWidth 8, centred `%`.
- [x] snapshot → long value wraps via `Flexible`, no overflow stripe.

## Commit & push

- **Commit:** `1ad126d` — `fix(onboarding): dismiss keyboard, fix two overflows, enlarge loading ring`
- **Push:** `origin/main` — ok

## Open items for the owner

- Quick visual pass on a real small phone (Pixel-class) to confirm the 480px box and
  the wrapped strengths value look right — code is verified, the exact pixels are not.

## Deviations from prompt

None. (Requirement 2 used the height-only path the prompt allowed; `QuoteCard`
untouched, as noted above.)
