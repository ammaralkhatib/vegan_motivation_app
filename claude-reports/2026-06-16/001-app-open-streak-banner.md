# App-open streak banner

**Prompt:** `claude-prompts/2026-06-16/001-app-open-streak-banner.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Added a brand-new **app-open streak** (days the app was opened — separate from
the habit streak) and a **top banner** that slides in on the first launch of a
new calendar day, holds ~3 s, then slides up and disappears. The streak count
and seven weekday dots reuse the existing habit-streak math (`currentStreak`) and
the `WeekStrip` widget read-only. Shows once per day. The habit streak and all
habit code are untouched.

## Files touched

- `lib/core/prefs/prefs_repository.dart` — new `openDays` getter/setter (epoch-days
  stored as a string list, like `goalsPick`).
- `lib/features/streak/open_streak.dart` — new: pure `computeOpenStreak()` (the
  decision: prune to last 30 days, count, showBanner) + `appOpenStreakProvider`
  (plain `Provider`, computed once per process → "once per day" on cold launch;
  persists the new day list as a side effect).
- `lib/features/streak/streak_banner.dart` — new: the animated pill widget.
- `lib/app/shell.dart` — mount `const StreakBanner()` as the last (top-most) child
  of the shell's `Stack`, top-center aligned.
- `lib/l10n/app_en.arb` (+ `_de`, `_fr`, `_es`) — new `streakBannerLabel`
  accessibility string (`"{count}-day streak"`) with an `int` placeholder.
- `test/features/streak/open_streak_test.dart` — new: 5 unit tests for the pure
  function.

## Decisions

- **Hold uses a cancelable `Timer`, not `Future.delayed`** — `Future.delayed`
  can't be cancelled, so its 3 s timer outlived the widget and tripped the
  "Timer still pending" check in the existing shell widget tests. A `Timer` field
  cancelled in `dispose()` matches the codebase convention (`unmountAndFlush`)
  and made all tests green again.
- **WeekStrip on a dark pill** — `WeekStrip` reads the ambient `colorScheme` for
  its dot colors. To keep the dots readable on the dark pill, I wrap it in a
  `Theme` that maps the variant colors onto the inverse-surface scheme. No
  changes to `WeekStrip` itself (reused as-is).
- **Pill color** — `scheme.inverseSurface` at 92% alpha (dark translucent), per
  the prompt's "reads over a bright photo" guidance. No hard-coded hex.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
All tests passed! (175 tests)
```

Self-correction: fixed the pending-timer test failures on attempt 2 by switching
the hold from `Future.delayed` to a cancelable `Timer` (see Decisions).

## Commit & push

- **Commit:** `e4890f1` — `feat(streak): app-open streak banner`
- **Push:** `origin/main` — ok

## Open items for the owner

Please check on a real device:

- [ ] The slide-in / hold / slide-out timing feels right (350 ms in, ~3 s hold,
      350 ms out).
- [ ] The banner is easy to read over a bright feed photo (dark pill contrast).
- [ ] It shows on the first open of a new day and does **not** show again on a
      second open the same day.

## Deviations from prompt

None.
