# Improve the motivation chart

**Prompt:** `claude-prompts/2026-06-16/004-improve-motivation-chart.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Made the S17 `MotivationChart` look nicer with two changes: the chart now sits in
a soft rounded panel, and the two curves are smoothly drawn instead of jagged
polylines. The up ("with") / down ("willpower") story, legend, and baseline axis
are unchanged. Analyze clean, all tests green.

## Files touched

- `lib/features/onboarding/steps/motivation_chart.dart` — wrapped the
  `CustomPaint` in a rounded container + inner padding, and replaced the
  straight `lineTo` sampling with Catmull-Rom smoothing in the painter.

## Decisions

- **Panel:** `Container` filled `theme.colorScheme.surfaceContainerHighest`,
  `BorderRadius.circular(20)`, `EdgeInsets.all(16)` padding around the painter —
  the painter still draws only the curves + axis, the container owns the
  background. Works in light and dark via the theme color.
- **Smoothing approach: Catmull-Rom → cubic Bezier.** Kept the same `yOf(t)`
  sampling (28 points) but joined them with `cubicTo` using control points
  derived from neighbor slopes (the standard `/6` Catmull-Rom tangent). This
  gives a smooth flowing line with no sharp corners and needs no trig. Kept the
  existing `_wave` wobble and `StrokeCap.round`/`StrokeJoin.round`.
- **`dart:math`: NOT added.** The Catmull-Rom math is plain arithmetic, so the
  file stays free of `dart:math` as the `_wave` comment intends.
- `shouldRepaint` is unchanged — still compares both colors it depends on.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.7s)

$ flutter test
All tests passed! (175)
```

Self-correction: none needed (passed first try).
Manual click-path: [ ] not run by Claude Code — Ammar to confirm the soft rounded
panel, smooth curves, and good contrast in both light and dark mode.

## Commit & push

- **Commit:** `abd3acb` — `style(onboarding): add panel bg + smooth motivation chart curves`
- **Push:** `origin/main` — ok

## Open items for the owner

- Visual click-path verification (panel + smoothness + dark-mode contrast).

## Deviations from prompt

None.
