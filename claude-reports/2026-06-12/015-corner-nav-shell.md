# Corner-button navigation: drop the tab bar, full-screen feed, sheet-style screens

**Prompt:** `claude-prompts/2026-06-12/015-corner-nav-shell.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Replaced the bottom NavigationBar / wide-layout NavigationRail with the "floating
corner buttons" pattern. The quote feed is now the only base screen and is always
full-screen. Four round, semi-transparent buttons float in the corners — Journey
(top-left), Settings (top-right), Habits (bottom-left), Explore (bottom-right).
Each one pushes its screen as a bottom-up modal sheet whose AppBar has an X that
returns to the feed. Settings moved out of Journey into its own top-level route.
`flutter analyze` is clean and all 141 tests pass.

## Files touched

- `lib/app/shell.dart` — rewrote `VeggieShell`: now a stateless full-screen feed
  with a `Stack` of four circular corner buttons (`surface` @ 70% opacity, icon in
  `onSurface`, ≥48dp tap target, tooltip = existing `shellTab*` / `settingsTitle`
  keys). Buttons navigate with `context.push`. NavigationRail/NavigationBar gone.
- `lib/app/router.dart` — dropped `StatefulShellRoute.indexedStack`. `/today` now
  renders the shell; `/habits`, `/explore`, `/journey`, `/settings` are plain
  top-level routes using a new `_sheetPage` slide-up `CustomTransitionPage`
  (ease-out, 300ms). Nested sub-routes keep default transitions. `/settings/notifications`
  is now nested under the new top-level `/settings`.
- `lib/features/journey/journey_screen.dart` — removed the gear AppBar action;
  added a leading `Icons.close` that pops to the feed.
- `lib/features/settings/settings_screen.dart` — added leading close button;
  `'/journey/settings/notifications'` → `push('/settings/notifications')`;
  `go('/explore')` → `push('/explore')`. Reset's `go('/onboarding')` left as-is.
- `lib/features/habits/habits_screen.dart`, `lib/features/explore/explore_screen.dart`
  — added a leading `Icons.close` button to each AppBar.
- `lib/l10n/app_{en,de,fr,es}.arb` — deleted the now-unused `shellTabToday` key
  (and its `@` metadata in en). Kept the other `shellTab*` keys (now tooltips).
- `test/widget_test.dart` — replaced the "four tabs" check with a "four corner
  buttons" check, plus a new test: tap Habits → HabitsScreen with close icon → tap
  close → back on the feed.
- `test/l10n_parity_test.dart` — the German render check used `shellTabToday`;
  switched it to `shellTabJourney` ("Reise").

## Decisions

- **Close-button tooltip uses `MaterialLocalizations.closeButtonTooltip`** — there is
  no app-specific "close" l10n key and the prompt said remove only `shellTabToday`,
  not add keys. The platform string is already localized for de/fr/es.
- **Left `journeySettingsTooltip` ARB key in place** — it is now unused but the prompt
  scoped l10n deletion to `shellTabToday` only; removing more would be out of scope.
- **Shell wraps the feed in its own `Scaffold`** so the theme background shows behind
  the feed's transparent scaffold — same role the old shell Scaffold played.

## Verification

```
$ flutter analyze
No issues found! (ran in 3.1s)

$ flutter test
All tests passed!  (141 +)
```

Self-correction: none — clean on the first run.
Manual click-path (Ammar):
- [ ] App opens on the full-screen feed with 4 corner buttons.
- [ ] Each button slides its screen up; the X returns to the feed.
- [ ] Journey no longer shows the gear (Settings has its own corner button).
- [ ] Settings → Notifications still works.
- [ ] Settings → "manage categories" opens Explore.

## Commit & push

- **Commit:** `6fd9bc8` — `feat(shell): replace tab bar with floating corner buttons`
- **Push:** `origin/main` — ok (`b7a73b4..6fd9bc8`). The remote now exists
  (`git@github.com:ammaralkhatib/vegan_motivation_app.git`) — CLAUDE.md §1 still says
  "no git remote yet"; worth updating that note.

## Open items for the owner

- None required for this change. (See the manual click-path above.)

## Deviations from prompt

None.
