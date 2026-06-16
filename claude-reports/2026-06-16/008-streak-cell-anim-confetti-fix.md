# Streak step: animate the day cells + fix the missing confetti

**Prompt:** `claude-prompts/2026-06-16/008-streak-cell-anim-confetti-fix.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Two fixes on the day-1 streak step (`StreakStep`, S19), one file. The seven
first-week day cells now pop in with a left-to-right staggered scale when the
step appears, with day 1 getting a bigger springy pop than the rest. The confetti
— which prompt 005 had moved to the `topRight` corner where the explosive burst
fired off-screen — is moved back on-screen so the burst is clearly visible.
Analyze clean, all 178 tests green.

## Files touched

- `lib/features/onboarding/steps/streak_step.dart` — added a `SingleTickerProvider`
  + `AnimationController` to drive the staggered cell entrance; rewrote `_DayCell`
  to animate (or render full size under reduced motion); changed the
  `ConfettiWidget` alignment.

## Decisions

- **Animation approach: one `AnimationController` (900 ms) + per-cell `Interval`.**
  Each `_DayCell` gets a staggered window (`start = 0.5 * index / 6`, width 0.5)
  inside the shared timeline via an `AnimatedBuilder`, so cells start left→right.
  Scale uses `Curves.elasticOut` for the achieved day-1 cell (bigger, springier
  overshoot) and `Curves.easeOutBack` for days 2–7. A linear opacity fades each
  cell in alongside its scale. `forward()` is kicked from the existing `_onPeak`.
- **Reduced motion.** `_DayCell` takes `animate: !reduceMotion(context)`; when
  false it returns the static circle at full size and the controller is never
  forwarded — no flicker, matching the confetti suppression. (`_onPeak` only
  plays confetti + forwards the controller when motion is enabled.)
- **Confetti alignment: `Alignment(0.3, -1)`.** Why the old `topRight` failed:
  the burst is `BlastDirectionality.explosive` (fires in all directions from the
  emitter point); placed in the top-right *corner*, roughly half the cone went
  off the right/top edges, so almost nothing showed. `(0.3, -1)` puts the emitter
  on the top edge, slightly right of center — on-screen (so the spray is clearly
  visible) while honoring Ammar's earlier note that dead-center looked left-biased.
  A code comment records this so it isn't "fixed" back to the corner. Confetti
  params and reduced-motion suppression are unchanged.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.7s)

$ flutter test
All tests passed! (178)
```

Self-correction: none needed (passed first try).
Manual click-path: [ ] not run by Claude Code — Ammar to confirm on a device:
the 7 cells pop in staggered with day 1 popping bigger, a confetti burst is
clearly visible, and under OS reduced motion the cells appear instantly with no
confetti.

## Commit & push

- **Commit:** `47cd8fa` — `feat(onboarding): animate streak day cells + restore visible confetti`
- **Push:** `origin/main` — ok

## Open items for the owner

- Visual click-path verification (stagger + day-1 pop + visible confetti +
  reduced-motion behavior).

## Deviations from prompt

None. (Chose the prompt's allowed `Alignment(0.3, -1)` over the recommended
`topCenter`, to keep Ammar's documented "not dead-center" preference while
guaranteeing the burst is on-screen.)
