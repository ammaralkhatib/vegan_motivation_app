# Habit detail screen + tile interaction

**Prompt:** `claude-prompts/2026-06-16/004-habit-detail-screen.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Added a per-habit detail screen and changed the list interaction. On the habits
list, tapping a tile now **opens the detail screen** (the round check circle is
still the only thing that toggles today). The detail screen shows current/best
streak + total days, a "mark today" toggle, and a month-browsable calendar where
the user can backfill any past/today day; future days are locked. Editing reuses
the existing `HabitEditScreen` via its route. Analyze clean, all 178 tests green.

## Files touched

- `lib/core/db/daos/habit_dao.dart` — added `watchHabit(id)` (method only, no
  schema change → no build_runner).
- `lib/features/habits/providers.dart` — added `habitProvider` family.
- `lib/features/habits/habit_calendar.dart` (new) — single-month binary calendar;
  reuses the `cellTextColor` helper from prompt 003; exposes the pure
  `isToggleable(day, today)` guard.
- `lib/features/habits/habit_detail_screen.dart` (new) — the detail screen.
- `lib/features/habits/habit_tile.dart` — tile `onTap` now pushes
  `/habits/:id`; removed the long-press-to-edit gesture. `_CheckButton`
  unchanged (milestone confetti path untouched).
- `lib/app/router.dart` — added the `:id` detail route alongside `edit/:id`.
- `lib/l10n/app_en.arb` (+ de/fr/es) — 6 new `habitsDetail*` keys.
- `test/habit_calendar_test.dart` (new) — future-day guard tests.

## Decisions

- **Future-day guard tested two ways.** A pure predicate `isToggleable` (unit
  test) plus a widget test that confirms a future day renders no number and isn't
  tappable, while a past day toggles with the correct epoch-day. The widget test
  needs no DB — `HabitCalendar` is a pure StatelessWidget.
- **Stats card layout.** Big current-streak number + label on top, then best
  streak and total days side by side. Reused `currentStreak`/`bestStreak` from
  `streak_engine.dart`; total = `days.length`. Added new labels (existing
  `habitsStreak` carries the "🔥" sentence, which didn't fit a stat label).
- **"Mark today" = `FilledButton.icon`** toggling today via `toggleCompletion`
  with `HapticFeedback.mediumImpact()`; the stream refreshes the UI (no manual
  setState). Calendar toggles use `HapticFeedback.selectionClick()`.
- **Weekday header** uses a known Monday (2024-01-01) + offset with
  `DateFormat('EEEEE')`, matching the heatmap's Mon→Sun (`firstWeekday`) order.
- **No existing test needed the tile-tap change.** The check-off test already
  taps the check button by semantics label, and `widget_test.dart` never taps a
  tile — so the suite stayed green without edits there.
- **Note on `watchHabit` + archived habits.** I used the DAO snippet exactly as
  written in the prompt; it returns the row by id regardless of `archivedAt`.
  Archiving from the edit screen pops back to the detail screen, which would
  still show the (now archived) habit until the user backs out. The detail
  screen's "pop on null" only fires for a truly deleted row. Flagged as a minor
  follow-up if Ammar wants archive to auto-close the detail screen (would need
  `watchHabit` to filter `archivedAt.isNull()`).

## Verification

```
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
All tests passed! (178)
```

Ran `flutter gen-l10n` after the ARB edits (generated files are git-ignored).
No Drift schema change → build_runner not needed.
Self-correction: none needed (passed first try).

## Commit & push

- **Commit:** `3f9ae31` — `feat(habits): habit detail screen + tile opens it`
- **Push:** `origin/main` — ok

## Open items for the owner

Please check on a device:
- Tapping a habit **tile** opens the detail screen; the **check circle** still
  checks today from the list (and milestone confetti still fires).
- **Backfill**: tapping a past calendar day toggles it; the calendar updates live.
- **Future days** are greyed / not tappable; the forward-month arrow is disabled
  on the current month.
- **Edit** (pencil) opens the existing edit screen (name/emoji/reminder).
- Optional: decide whether archiving a habit should auto-close the detail screen
  (see the `watchHabit` note above).

## Deviations from prompt

None. (Used the prompt's exact `watchHabit` snippet; archived-habit nuance noted
above rather than changing the snippet.)
