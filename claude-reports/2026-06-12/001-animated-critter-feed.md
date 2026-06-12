# Animated farm critters on the quote feed

**Prompt:** `claude-prompts/2026-06-12/001-animated-critter-feed.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

The Today feed now has life: a small kawaii farm animal sits near the bottom of
every quote card, gently bobbing up and down, blinking at random, and playing a
happy wiggle (^ ^ eyes + open smile) when tapped. I downloaded the 18 frames
(6 animals × base/blink/happy), shrank each to 512×512 with transparency kept,
bundled them as assets, built a reusable `AnimatedCritter` widget driven purely
by `AnimationController`/`Timer` (no new packages), and wired each content
category to its own animal. All tests pass and analyze is clean.

## Files touched

- `assets/critters/` (new, 18 PNGs) — the bundled animal frames, 512×512, transparent.
- `pubspec.yaml` — registered `assets/critters/` (asset entry only).
- `lib/core/critters/animated_critter.dart` (new) — `Critter` enum (frame paths +
  category→animal map) and the `AnimatedCritter` widget (bob + blink + tap wiggle).
- `lib/features/quotes/quote_card.dart` — shows the matching critter above the
  action buttons on each card.
- `test/animated_critter_test.dart` (new) — widget + unit tests for the critter.
- `test/helpers.dart` — added `disableCritterAnimations()` so tests that pump the
  feed can still use `pumpAndSettle`.
- `test/feed_widget_test.dart`, `test/widget_test.dart` — call that helper.

## Decisions

- **Placement: in-flow, centered, just above the favorite/share buttons.** The card
  is a `Column` (chip → quote text → author → critter → buttons). Putting the
  critter in the normal flow between the lower `Spacer` and the button row keeps it
  in the calm bottom area, never overlapping the quote text or the buttons, and
  needs no `Stack`/`Positioned` guesswork. Size 96 as specified.
- **Tap target is the critter only.** Its `GestureDetector` covers just its 96×96
  bounds, so the feed's tap-to-advance (outer translucent detector) and vertical
  swipe keep working everywhere else. Tapping the animal plays the wiggle instead
  of advancing — a small, pleasant easter-egg, not a regression.
- **No-flicker frames via opacity swap.** All three frames stay mounted in a
  `Stack`; only the active one has opacity 1. Frames are `precacheImage`d. This
  avoids the decode-flash you'd get from swapping `Image.asset` widgets.
- **Reduced motion = static base.** The widget honours `MediaQuery.disableAnimations`
  and the `animate: false` flag by rendering the still base frame and running no
  controllers/timers. This also gives tests a clean, settle-able path — the new
  `disableCritterAnimations()` helper sets that flag so the existing
  `pumpAndSettle`-based feed/shell tests don't hang on the never-ending bob.
- **Category map** (from the content JSON ids): `why_vegan`→cow, `quick_tips`→
  chicken, `youre_awesome`→pig, `facts`→duck, `staying_strong`→goat,
  `milestones`→sheep; unknown/null → cow.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.5s)

$ flutter test
All tests passed!   (45 tests)
```

Self-correction: none — analyze clean and tests green on the first run.
(The `drift` "database created multiple times" warning in the log is pre-existing
test-harness noise, unrelated to this change.)

Manual click-path (for the owner):
- [ ] Run the app, swipe a few quote cards — each shows its animal bobbing.
- [ ] Watch a card a few seconds — the animal blinks occasionally.
- [ ] Tap the animal — it shows the happy ^ ^ face with a short wiggle, then settles.
- [ ] Confirm quote text stays readable and the card still swipes/taps to advance.

## Asset sizes

All 18 frames are 512×512, transparency preserved. Largest file is
`cow_base.png` at ~207 KB; every file is well under the 300 KB target.

## Commit & push

- **Commit(s):** `a5e560a` — `feat(quotes): animated farm critters on feed cards`
  (this report's SHA stamp is a tiny follow-up `docs` commit).
- **Push:** `origin/main` — ok (`be98a0a..a5e560a`).

## Open items for the owner

- The four manual checks above (visual/touch behaviour can't be verified in CI).
- Later critter placements (habit celebrations, onboarding, journey) are separate
  prompts, per the roadmap — not in this change.

## Deviations from prompt

None.
