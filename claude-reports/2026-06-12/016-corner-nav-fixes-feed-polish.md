# Corner-nav fixes + feed polish (batch)

**Prompt:** `claude-prompts/2026-06-12/016-corner-nav-fixes-feed-polish.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Fixed two bugs the corner-button shell (prompt 015) exposed and applied four small
polish items. The two bugs: pushed screens were see-through (they relied on the old
tab shell's Scaffold to paint behind them), and Explore/Habits sub-navigation used
`context.go(...)`, which replaced the whole stack and dropped `/today` so the X had
nothing to pop to. Polish: the critter now sits directly under the quote text and is
bigger, the date moved off the feed onto Journey, the feed's eco icon is gone, and
the Journey corner button uses a person icon. `flutter analyze` is clean and all 142
tests pass (added one regression test).

## Files touched

- `lib/features/{habits/habits_screen, habits/habit_edit_screen, explore/explore_screen,
  explore/category_detail_screen, explore/favorites_screen, journey/journey_screen,
  settings/settings_screen, settings/notification_settings_screen}.dart`
  — removed `backgroundColor: Colors.transparent` so each pushed sheet paints the
  solid theme background (Req 1).
- `lib/features/quotes/feed_screen.dart` — **kept** transparent (VeggieShell paints
  behind it); deleted the date-header `Positioned` overlay (date text + eco icon) and
  dropped the now-unused `intl` import (Req 5).
- `lib/features/explore/explore_screen.dart`, `lib/features/habits/habits_screen.dart`,
  `lib/features/habits/habit_tile.dart` — `context.go` → `context.push` for
  favorites / category / habit-edit so `/today` stays under the sheet (Req 2).
- `lib/features/{habits/habits_screen, explore/explore_screen, journey/journey_screen,
  settings/settings_screen}.dart` — X button is now defensive:
  `canPop() ? pop() : go('/today')` (Req 3).
- `lib/features/quotes/quote_card.dart` — moved the `AnimatedCritter` block to sit
  directly below the quote/author (24px gap, only when the critter renders) and
  raised its size 96 → 140 (Req 4).
- `lib/features/journey/journey_screen.dart` — added today's date as the first body
  item, `textTheme.labelSmall`, localized via
  `DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString())` (Req 5).
- `lib/app/shell.dart` — Journey corner icon `favorite_outline` → `person_outline`
  (Req 6).
- `test/widget_test.dart` — added the Explore → Favorites → back → X regression test
  (Req 7).

## Decisions

- **Kept the feed's `Stack` with a single child** after removing the overlay, rather
  than restructuring `build` — smallest diff, no behaviour change, analyzer is happy.
- **No test needed fixing for the icon/overlay change.** `feed_widget_test` renders
  `FeedScreen` directly (no shell), so its `Icons.favorite_outline` finder still
  matches only the card's heart; the prior `widget_test` finds corner buttons by
  tooltip, which is unchanged. So Req 7's "fix any test" was a no-op beyond the new
  regression test.

## Verification

```
$ flutter analyze
No issues found! (ran in 3.1s)

$ flutter test
All tests passed!  (142)
```

Self-correction: none — clean on the first run.
Manual click-path (Ammar):
- [ ] Every corner screen now has a solid background.
- [ ] Explore → Favorites → back → X returns to the feed (no dead end).
- [ ] Habit long-press edit → back → X returns to the feed.
- [ ] Critter sits right under the quote text and is clearly bigger.
- [ ] Feed top edge is clean (no date, no eco icon).
- [ ] Journey shows today's date at the top, in the app language.
- [ ] Top-left corner button is a person icon.

## Commit & push

- **Commit:** `c975b71` — `fix(shell): solid sheet backgrounds, push-based subnav, feed polish`
- **Push:** `origin/main` — ok (`8441fb9..c975b71`).

## Open items for the owner

- Worth an eye on the **localized date on Journey**: it relies on
  `flutter_localizations` having loaded date symbols for the active locale (de/fr/es/en).
  It renders fine in tests under `en`; please confirm German/French/Spanish read
  naturally on a device.
- Two unrelated working-tree changes were left **uncommitted** (not part of this
  prompt): `CLAUDE.md` and `ios/Podfile.lock`. I didn't touch them — commit or
  discard as you see fit.

## Deviations from prompt

None.
