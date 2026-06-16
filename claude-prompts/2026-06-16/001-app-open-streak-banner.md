# 001 — App-open streak banner

## Goal

Add a **daily app-open streak** with a **top banner** that slides in when the
user opens the app on a new calendar day, holds for a few seconds, then slides
away — like the reference screenshot (a dark rounded pill at the top showing a
streak number in a circle and seven weekday dots, with the opened days
checked).

This is a **new, separate streak** that counts *days the app was opened*. It is
**not** the habit streak. Do not change or touch the existing habit streak,
`streak_engine.dart`, habits screen, or any habit code beyond *reusing*
`currentStreak()` and the `WeekStrip` widget read-only (see below).

Show the banner **once per calendar day**: only on the first app launch of a new
day. If the app is launched again the same day, do not show it.

## What already exists (reuse, don't rebuild)

- `lib/features/habits/streak_engine.dart` → `currentStreak(List<int> sortedDays, int today)`.
  Reuse this exact function to compute the open-streak count. (It already treats
  an unchecked *today* gracefully, but here we always record today before
  computing, so today will be present.)
- `lib/features/habits/week_strip.dart` → `WeekStrip({completedDays, today})`
  draws the seven trailing-day dots with today outlined. Reuse this widget as-is
  for the weekday dots in the banner. Import it from the habits feature.
- `lib/core/utils/date_utils.dart` → `todayEpochDay()`, `epochDay`,
  `dateFromEpochDay`. Use these; do not invent new date math.
- `lib/core/prefs/prefs_repository.dart` → typed SharedPreferences wrapper,
  exposed via `prefsProvider`. Add the new stored value here (pattern below).

## Step 1 — Persist the open days (prefs)

In `PrefsRepository`, add a stored list of the epoch-days the app was opened,
following the existing getter/setter style (see `goalsPick` for a `List<String>`
example — store ints as strings):

- Key constant: `_kOpenDays = 'openDays'`.
- Getter `List<int> get openDays` → read the string list, parse to ints, drop
  anything unparseable, return ascending. Default `const []`.
- Setter `Future<void> setOpenDays(List<int> days)` → store as a string list.

Keep the list small: when recording, prune to roughly the **last 30 days**
(anything older than `today - 30` can be dropped) so it never grows unbounded.

## Step 2 — Open-streak logic + provider

Create a new small feature folder `lib/features/streak/`.

`lib/features/streak/open_streak.dart`:

- A pure result class, e.g.
  `class OpenStreakResult { final int count; final Set<int> openedDays; final int today; final bool showBanner; ... }`.
- A provider `appOpenStreakProvider` (a plain `Provider<OpenStreakResult>`, so it
  is computed **once** per app process — that is what gives us "once per day"
  for a cold launch). On first read it must:
  1. `today = todayEpochDay()`.
  2. Read `prefs.openDays`.
  3. `alreadyOpenedToday = openDays.contains(today)`.
  4. If not already opened today: add `today`, prune to last 30 days, sort
     ascending, and `prefs.setOpenDays(...)`. Set `showBanner = true`.
  5. If already opened today: leave the list as is, `showBanner = false`.
  6. `count = currentStreak(sortedOpenDays, today)` (import from
     `habits/streak_engine.dart`).
  7. `openedDays = sortedOpenDays.toSet()` (for the WeekStrip).
- Keep this logic pure and small so it is unit-testable. The `prefs` write is a
  side effect inside the provider body — that is acceptable here and mirrors how
  the app already does one-time-on-read work, but factor the *decision* (given
  an existing day list + today → new list, count, showBanner) into a pure
  top-level function `computeOpenStreak(List<int> existingDays, int today)` that
  returns the result **without** touching prefs, and have the provider call it
  then persist. The pure function is what the test exercises.

## Step 3 — The banner widget

`lib/features/streak/streak_banner.dart`:

- A `ConsumerStatefulWidget` `StreakBanner` that:
  - Reads `appOpenStreakProvider` once in `initState`/first build.
  - If `showBanner` is false → renders `const SizedBox.shrink()` (nothing).
  - If true → shows the pill and runs the animation:
    **slide down + fade in (~350 ms) → hold ~3 s → slide up + fade out
    (~350 ms) → then collapse to nothing.** Use a single
    `AnimationController` with `SlideTransition` + `FadeTransition`; drive the
    hold with a `Future.delayed` then reverse. Guard all async with `mounted`.
- Visual target (match the screenshot, but use theme colors, not hard-coded):
  - A rounded pill (`BorderRadius.circular(20)` ish), padded, sitting just below
    the status bar — wrap the whole thing in `SafeArea`.
  - Background: a dark translucent surface
    (`scheme.inverseSurface` or `scheme.surface` with alpha) so it reads on top
    of the bright feed photo.
  - Left: a circular badge with the streak `count` (big number) and a small
    spark/▢ icon is optional — number is enough.
  - Right: the `WeekStrip(completedDays: result.openedDays, today: result.today)`.
  - Respect dark/light theme via `Theme.of(context).colorScheme`. Do not
    hard-code hex colors.

## Step 4 — Mount it on the feed

In `lib/app/shell.dart` (`VeggieShell`), add `const StreakBanner()` as the
**last** child of the outer `Stack` (so it paints above the feed and the corner
buttons), inside the existing `SafeArea`/`Stack` is fine as long as it aligns to
the **top**. Use `Align(alignment: Alignment.topCenter, child: StreakBanner())`.
The banner manages its own show/hide, so mounting it unconditionally is correct.

`VeggieShell` is currently `StatelessWidget` — that is fine; `StreakBanner`
is the stateful piece. Do not convert the shell unless you must.

## Step 5 — Localization (gen_l10n)

Per CLAUDE.md, user-facing text goes through ARB (`lib/l10n/app_en.arb` is the
template; settings is the reference pattern). The banner is mostly numbers and
weekday letters (the letters already come from `DateFormat`), so add **only** a
semantics label for accessibility, e.g.:

- `app_en.arb`: `"streakBannerLabel": "{count}-day streak"` with an `intl`
  placeholder for `count` (look at an existing placeholder string like
  `notificationsPerDayCount` for the exact ARB shape).
- Wrap the pill in a `Semantics(label: l.streakBannerLabel(count))`.
- Add the same key to the other ARBs (`_de`, `_fr`, `_es`). Translate simply
  ("{count}-Tage-Serie" for de, etc.) — keep it short; if unsure, a reasonable
  literal translation is fine.

Do not localize anything else here. Do not route quote content through ARB.

## Step 6 — Tests

Add `test/features/streak/open_streak_test.dart` covering the **pure**
`computeOpenStreak(existingDays, today)`:

- First ever open (empty list) → count 1, showBanner true, day added.
- Open again **same day** (today already in list) → showBanner false, count
  unchanged, list unchanged.
- Open the **next day** in a row → count increments, showBanner true.
- Open after a **gap** (missed a day) → count resets to 1, showBanner true.
- Pruning: a day older than `today - 30` is dropped from the saved list.

No need for a widget/animation test.

## Verify (must all pass before commit — CLAUDE.md §2)

```
flutter analyze        # clean
flutter test           # green
```

No Drift schema change here, so `build_runner` is **not** needed.

## Out of scope / do not do

- Do not touch the habit streak, habits screen, DB, or `streak_engine.dart`
  internals (reuse only).
- No backend, no account, no new packages — offline-first, on-device only
  (locked decision). Use existing prefs + Riverpod.
- Do not add a settings toggle for this in the same prompt; keep it focused.

## Report

Write the report to `claude-reports/2026-06-16/001-app-open-streak-banner.md`
using `claude-reports/TEMPLATE.md`. Note the commit SHA and anything Ammar
should check on a device (the slide-in/out timing feels right, banner is
readable over a bright photo).
