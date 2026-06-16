# Streak step: add a week calendar + shift the confetti right

**Prompt:** `claude-prompts/2026-06-16/005-streak-week-calendar.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Added a first-week calendar strip to the day-1 streak celebration (`StreakStep`,
S19) — 7 circular day cells, day 1 marked done and days 2–7 muted — and moved the
confetti burst so it originates from the right side instead of top-center. The
review-prompt logic and its 1.2 s timer are untouched. Analyze clean, all tests
green.

## Files touched

- `lib/features/onboarding/steps/streak_step.dart` — added the 7-cell week strip
  (with a new private `_DayCell` widget) below the body text, and changed the
  `ConfettiWidget` alignment.

## Decisions

- **Cell labels: plain numbers 1–7** (not weekday initials) — simplest,
  language-neutral, and adds no ARB strings. Day 1 is a filled
  `colorScheme.primary` circle with `Icons.check` (white `onPrimary`); days 2–7
  are `surfaceContainerHighest` fill + `outlineVariant` border showing the
  number. Cells are 38 px, 8 px apart.
- **Overflow guard: `FittedBox(fit: scaleDown)`** around the row — on narrow
  screens the seven cells shrink to fit instead of overflowing, rather than
  wrapping (keeps the week on one visual line).
- **Confetti alignment: `Alignment.topRight`** — the prompt's first suggestion;
  the burst is explosive so it still spreads across, just sourced from the right.
  Particle count, forces, gravity, colors, and the reduced-motion suppression are
  all unchanged.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.5s)

$ flutter test
All tests passed! (175)
```

Self-correction: none needed (passed first try).
Manual click-path: [ ] not run by Claude Code — Ammar to confirm the 7-day strip
(day 1 done, 2–7 muted), confetti bursting from the right, and that reduced motion
still suppresses confetti while the strip still renders.

## Commit & push

- **Commit:** `316c796` — `feat(onboarding): add week calendar + move streak confetti right`
- **Push:** `origin/main` — ok

## Open items for the owner

- Visual click-path verification (strip + right-side confetti + reduced-motion).

## Deviations from prompt

None.
