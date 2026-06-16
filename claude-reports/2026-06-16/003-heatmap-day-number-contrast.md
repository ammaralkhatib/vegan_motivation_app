# Heatmap day-number contrast

**Prompt:** `claude-prompts/2026-06-16/003-heatmap-day-number-contrast.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

The month heatmap drew every day-of-month number in `onSurfaceVariant` (muted
dark), which was hard to read on the darker forest-green cells. Added a tiny
shared helper `cellTextColor` that picks light text on dark cells and muted-dark
on light cells, and wired it into the heatmap. The cell background is now computed
once and reused for both the box color and the text color. Analyze clean, all
tests green.

## Files touched

- `lib/features/habits/cell_text_color.dart` (new) — `cellTextColor(background,
  scheme)` helper, exactly as specified. Shared so prompt 004's per-habit
  calendar can reuse it.
- `lib/features/habits/month_heatmap.dart` — compute `bg` once per cell, use it
  for the `BoxDecoration` color and pass it to `cellTextColor` for the `Text`
  color; added the import. Font size 9 and everything else unchanged.

## Decisions

None — followed the prompt's helper and wiring verbatim. `cellColor(dayOfMonth)`
is now called once per cell (stored in `bg`) instead of twice.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
All tests passed! (176)
```

Self-correction: none needed (passed first try).
Manual click-path: [ ] not run by Claude Code — Ammar can open Habits and confirm
the day numbers on darker cells are now readable (light text).

## Commit & push

- **Commit:** `aa491ae` — `feat(habits): auto-contrast heatmap day numbers`
- **Push:** `origin/main` — ok

## Open items for the owner

- Optional visual check on the Habits screen (light text on dark cells).

## Deviations from prompt

None.
