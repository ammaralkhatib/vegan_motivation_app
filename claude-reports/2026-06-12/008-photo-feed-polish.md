# Photo-background polish: paywall hook, full-screen feed, motion, stronger tints

**Prompt:** `claude-prompts/2026-06-12/008-photo-feed-polish.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Six small polish changes on the photo-background feature, all shipped. The feed
now fills the screen behind a see-through bottom bar on Today, photos drift with a
slow Ken Burns motion, quote text has a soft shadow, the critter steps aside on
photo cards, the Settings switch is always visible (and opens the paywall for free
users), and the gradient cards use six clearly distinct category colors. Analyze
clean, all 133 tests pass (3 new).

## Per-requirement status

1. **Settings switch → paywall (free users)** ✅ — the "Photo backgrounds" row is
   always shown. Premium: a live `SwitchListTile`. Free: a `ListTile` with a
   dimmed off `Switch(onChanged: null)` whose row taps into the existing
   `showPaywall(context, PaywallVariant.defaultOffer)` (50%-off) — reused, nothing
   new built inside purchases.
2. **Hide critter on photo cards** ✅ — `AnimatedCritter` (and its spacer) only
   render when `!onPhoto`; the two `Spacer(flex: 2)` absorb the gap. Gradient
   cards keep the critter exactly as before.
3. **Full-screen photo + translucent bar (Today only)** ✅ — `shell.dart` phone
   layout sets `extendBody` and the translucent bar **only when on Today**
   (`currentIndex == 0`): `surface @ 70%`, `surfaceTintColor: transparent`,
   `elevation: 0`. Other tabs keep `extendBody: false` + the default solid bar, so
   they're untouched. The feed card's existing `SafeArea` picks up the bar height
   that `extendBody` adds to `MediaQuery.padding.bottom`, so the favorite/share
   buttons clear the bar. NavigationRail (wide) unchanged.
4. **Text shadow on photo cards** ✅ — body + author text get
   `Shadow(blurRadius: 12, color: Colors.black54, offset: Offset(0, 2))` when
   `onPhoto`; gradient cards get none.
5. **Slow Ken Burns motion** ✅ — a `_KenBurnsPhoto` StatefulWidget wraps the
   photo: a 14 s `easeInOut` forward-only controller animates scale and the
   `Transform.scale` alignment. Variant is deterministic — `kenBurnsVariant(id)`
   returns `(zoomIn, corner)` from `id % 8` (zoom in/out × 4 corners). Always
   `BoxFit.cover` + scale ≥ 1.0, so edges never show; scrim and content don't
   move; static under reduced motion; controller disposed.
6. **Stronger, distinct category tints** ✅ — see hex values below; gradient
   rendering (tint → scaffold) unchanged.

## Tint hex values

Light: why_vegan `#CBE6C2` (green), quick_tips `#E9E2A6` (yellow-olive),
youre_awesome `#F8CFC6` (coral), facts `#BFE2E6` (teal), staying_strong `#EBCFAF`
(earthy orange), milestones `#F6DCA0` (amber).
Dark: why_vegan `#1C3A28`, quick_tips `#34330F`, youre_awesome `#3F231D`,
facts `#123537`, staying_strong `#3A280F`, milestones `#3E2E0B`.
Light tints stay light (dark text readable); dark tints stay dark (light text
readable); the gradient fades each toward the scaffold background.

## Ken Burns parameters

14 s, `Curves.easeInOut`, forward-only (no ping-pong). Scale 1.0↔1.08. Alignment
lerps center → corner. 8 variants = (zoom in | out) × {topLeft, topRight,
bottomLeft, bottomRight}, picked by `quote.id % 8`.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
All tests passed!   (133 tests; 3 new)
```

New tests: (a) free user sees the off/disabled switch and tapping the row routes
to the paywall; (b) photo card has no `AnimatedCritter`, gradient card has one;
(c) photo text style carries a shadow, gradient text doesn't; (d) `kenBurnsVariant`
is deterministic, cycles every 8 ids, and yields 8 distinct moves.

Self-correction: none — analyze and tests were green on the first run.

Manual click-path (open item for Ammar): premium build → photo fills the screen
behind a see-through bar on Today, drifting slowly (each slide different), text
pops, no critter on photos; Habits/Explore/Journey look unchanged; free build →
Settings switch dimmed, tap opens the 50%-off paywall; gradient cards show six
clearly different colors.

## Commit & push

- **Commit(s):** `babf248` — `feat(quotes): photo-feed polish — paywall hook, full-screen, Ken Burns, tints`
  (this report's SHA stamp is a tiny follow-up `docs` commit).
- **Push:** `origin/main` — ok (`1d65cdc..babf248`).

## Deviations from prompt

None.
