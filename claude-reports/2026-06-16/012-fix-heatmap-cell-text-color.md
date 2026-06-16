# Fix the habit calendar day-number color

**Prompt:** `claude-prompts/2026-06-16/012-fix-heatmap-cell-text-color.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Prompt 003's auto-contrast change recolored every cell's day number and used
`onInverseSurface` for dark cells — which is dark in dark theme, so dark cells
got dark-on-dark numbers. Reverted the helper so only **light-background** cells
get a stronger color (`onSurface`); every other cell (green/filled, transparent)
keeps the original `onSurfaceVariant`. One helper fix covers both callers (month
heatmap + per-habit calendar). Analyze clean, all 178 tests green.

## Files touched

- `lib/features/habits/cell_text_color.dart` — new logic + updated doc comment.

## Decisions

Final helper logic (exactly as the prompt specified):

```dart
Color cellTextColor(Color background, ColorScheme scheme) {
  final isLight =
      ThemeData.estimateBrightnessForColor(background) == Brightness.light;
  return isLight ? scheme.onSurface : scheme.onSurfaceVariant;
}
```

- **Dark-mode bug fixed.** The old `onInverseSurface` branch (dark in dark theme)
  is gone; dark cells now use `onSurfaceVariant`, so no dark-on-dark. Light cells
  use `onSurface` (a strong on-light color in both themes), so no light-on-light.
- No call-site changes — both `month_heatmap.dart` and `habit_calendar.dart`
  already pass the cell background to the helper, so the fix is automatic and
  consistent. Cell backgrounds, ramp, and legend are untouched.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
All tests passed! (178)
```

Self-correction: none needed (passed first try).
Manual click-path: [ ] not run by Claude Code — Ammar to confirm: month heatmap
green cells read muted (as before), light/empty cells are clearly readable, no
dark-on-dark in dark mode, and the per-habit detail calendar is consistent.

## Commit & push

- **Commit:** `512192a` — `fix(habits): restore heatmap day-number color, adjust only light cells`
- **Push:** `origin/main` — ok

## Open items for the owner

- Visual click-path verification (light + dark theme, heatmap + habit calendar).

## Deviations from prompt

None.
