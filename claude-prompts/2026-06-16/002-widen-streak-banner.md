# 002 — Widen the app-open streak banner

## Goal

The streak banner from prompt 001 is too small — it shrink-wraps to its
content. Make it a **full-width** pill across the top of the feed. It is fine
(intended, per Ammar) for the wide pill to **cover the top-left and top-right
corner icons** while it is on screen — it already paints above them because it
is the last child in the shell `Stack`.

Match the reference screenshot: the round streak-count badge sits at the far
**left**, and the seven weekday dots **spread evenly** across the rest of the
width to the right edge.

Only touch the banner's layout (and a small, backward-compatible option on
`WeekStrip`). Do not change the streak logic, the animation timing, the colors,
or anything in `open_streak.dart`.

## Changes

### 1. `lib/features/streak/streak_banner.dart` — full width + spread

In the `build` method's pill:

- Reduce the outer horizontal padding so the pill reaches close to the screen
  edges: change the outer `Padding` from
  `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` to
  `EdgeInsets.symmetric(horizontal: 8, vertical: 8)`.
- Make the inner `Row` fill the width and space its children apart:
  - `mainAxisSize: MainAxisSize.max` (was `min`).
  - `mainAxisAlignment: MainAxisAlignment.spaceBetween`.
- Let the weekday dots take the leftover width and spread evenly. Wrap the
  `WeekStrip` (the `Theme(...)` that contains it) in `Expanded`, and tell
  `WeekStrip` to space its dots evenly (new optional param below):
  `WeekStrip(..., alignment: MainAxisAlignment.spaceEvenly)`.
- Keep the `SizedBox(width: 16)` between the badge and the strip, or replace it
  with a slightly larger gap if it reads better — your judgement, but the badge
  must stay hard-left and the dots must reach the right edge.

### 2. `lib/features/habits/week_strip.dart` — optional alignment param

`WeekStrip` is reused by the habits screen, so this change must be
**backward-compatible** (the habits screen must look exactly the same):

- Add an optional field `final MainAxisAlignment alignment;` with a constructor
  default of `MainAxisAlignment.start` (its current implicit behavior).
- Pass it to the `Row`: `Row(mainAxisAlignment: alignment, children: [...])`.
- When the dots are spread (`spaceEvenly`), the per-dot
  `Padding(right: 10)` will double up the spacing on the right edge. Remove that
  trailing-right padding when spreading, or simpler: keep the existing per-dot
  padding but drop it to a smaller value — pick whichever looks even. The
  **default-path** (habits screen, `start` alignment) layout must not change.

Do not change dot size, colors, or the weekday letters.

## Verify (must pass before commit — CLAUDE.md §2)

```
flutter analyze        # clean
flutter test           # green
```

Confirm the existing habits-screen widget tests still pass (the `WeekStrip`
default path must be unchanged).

## Out of scope

- No change to streak counting, the once-per-day rule, animation timing, or the
  pill color/opacity.
- Do not add new packages.

## Report

Write the report to `claude-reports/2026-06-16/002-widen-streak-banner.md`
(template: `claude-reports/TEMPLATE.md`). Note the commit SHA and ask Ammar to
confirm on a device that the wide pill looks right and the habits-screen week
dots are unchanged.
