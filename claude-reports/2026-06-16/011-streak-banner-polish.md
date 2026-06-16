# Polish the app-open streak banner

**Prompt:** `claude-prompts/2026-06-16/011-streak-banner-polish.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Made the once-a-day app-open streak banner feel more substantial: a taller pill,
bigger day dots, and completed days now shown as a colored check that pops in
(scale + fade, staggered left→right). Added a ~600 ms delay so the banner lands a
beat after the screen settles. The new look is opt-in via new `WeekStrip` params,
so the habits-screen tiles are visually unchanged. Analyze clean, all 178 tests
green.

## Files touched

- `lib/features/habits/week_strip.dart` — added `dotSize` (default 10),
  `showCheck` (default false), `animateChecks` (default false); added a private
  `_AnimatedCheck` (delayed `AnimatedScale` + `AnimatedOpacity`). Weekday label
  size scales with `dotSize`.
- `lib/features/streak/streak_banner.dart` — taller pill, bumped badge, opts into
  the new `WeekStrip` look, and a pre-show delay timer.

## Decisions

- **WeekStrip params + defaults preserve `habit_tile`.** `dotSize: 10`,
  `showCheck: false`, `animateChecks: false` are the defaults; `habit_tile.dart`
  still calls `WeekStrip` with no new args, so its dots stay 10px, plain-filled,
  no check, no animation. Label font size = `(dotSize * 0.65).clamp(10, 13)`,
  which is exactly 10 at the default size — no regression.
- **Banner opts in** with `dotSize: 17`, `showCheck: true`, `animateChecks: true`.
  Completed dots keep the `primary` fill; the check uses `onPrimary` so it reads
  on the dark inverse pill (the banner's existing inverse-`Theme` override leaves
  `primary`/`onPrimary` intact, so contrast is correct). The current-day border
  treatment is unchanged.
- **Check animation:** each check scales (`easeOutBack`, 300 ms) + fades (250 ms)
  in, staggered 90 ms per dot left→right (leftmost/oldest first). Under reduced
  motion (`MediaQuery…disableAnimations`) checks render instantly (computed in
  `WeekStrip.build`, passed as `animate: animateChecks && !reduceMotion`).
- **Taller pill:** vertical padding 12 → 18, radius 20 → 24, badge 40 → 46,
  spacing 16 → 18. Still a rounded pill; slide+fade in/out and collapse-to-nothing
  are unchanged.
- **Entrance delay:** 600 ms `Timer` before `_controller.forward()`; the hold
  timer is armed only after the slide-in starts, so the visible hold (3 s) is
  unchanged. The delay timer is canceled in `dispose`. Reduced motion still
  shows/hides correctly (the controller animation is unchanged — only the checks
  go instant).

## Verification

```
$ flutter analyze
No issues found! (ran in 2.4s)

$ flutter test
All tests passed! (178)
```

No test pumps the banner or `WeekStrip` (searched `test/`), so no timing updates
were needed. Self-correction: none needed (passed first try).
Manual click-path: [ ] not run by Claude Code — Ammar to confirm: the banner
appears after a short delay, taller pill, bigger dots, checks pop in staggered,
auto-dismisses; the habits-screen week dots look unchanged; and reduced motion
shows checks instantly.

## Commit & push

- **Commit:** `e596a5a` — `feat(streak): bigger banner with animated check dots + entrance delay`
- **Push:** `origin/main` — ok

## Open items for the owner

- Visual click-path verification (banner look + delay + reduced motion, and the
  unchanged habit-tile dots).

## Deviations from prompt

None.
