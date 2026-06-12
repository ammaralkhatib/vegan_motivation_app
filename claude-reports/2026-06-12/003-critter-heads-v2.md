# Critter art v2: head-only frames + breathing animation

**Prompt:** `claude-prompts/2026-06-12/003-critter-heads-v2.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Swapped the full-body critter art for the approved head-only (face-emoji
style) versions, and changed the idle motion from up-down bobbing to a gentle
in-place "breathing" scale. Blink and tap-happy-wiggle are unchanged. All 18
PNGs were re-downloaded (2048×2048 transparent originals), downscaled to
512×512, and dropped in under the same filenames. `flutter analyze` clean,
`flutter test` green (160 tests, incl. 1 new breathing assertion).

## Files touched

- `assets/critters/*.png` (18 files) — replaced with the new head-only art,
  same filenames, 512×512, transparent, 156–188 KB each.
- `lib/core/critters/animated_critter.dart` — idle animation only: removed the
  `Transform.translate` bob; the idle motion is now `scale = 1 + 0.04·sin(…)`
  over the same ~2.8 s period. Renamed `_bob`→`_breathe`, `_bobPeriod`→
  `_breathePeriod` for honesty. Tap wiggle (rotation ±8° + ≤1.05 scale bump) and
  blink frame-swap untouched; the two scales now multiply on one
  `Transform.scale`.
- `test/animated_critter_test.dart` — new test asserting the idle critter scales
  (peak ~1.04 a quarter-period in) and never translates; updated a stale "bob"
  comment.
- `test/helpers.dart` — updated the comment that described the idle motion as a
  "bob" to "breathing scale".

## Decisions

- **Combined the breathing and tap scales onto a single `Transform.scale`**
  (`breathScale * tapScale`) instead of nesting two scale widgets — simpler tree,
  identical visual result. Tap bump stays ≤1.05 as specified; breathing is the
  base motion.
- **Breathing test checks `getMaxScaleOnAxis()` across the `Transform`s** rather
  than reaching for a private field — it proves "scaling, not translating"
  through the public widget tree, which is what the prompt asked for.
- Kept `animate: false` / reduced-motion behavior exactly as before (static base
  frame, scale 1.0, no controllers running).

## Verification

```
$ flutter analyze
No issues found! (ran in 3.1s)

$ flutter test
All tests passed! (160 tests)
```

Self-correction: none needed — analyze and tests passed first try.
Manual click-path (open item for Ammar): [ ] run the app — heads (not bodies) on
the feed, breathing gently in place with no vertical movement, blinking, happy
wiggle on tap.

## Final asset sizes

All 18 are 512×512, transparent PNG, well under the 300 KB ceiling:
chicken 156–160 KB, cow 163–166 KB, duck 167–178 KB, goat 171–188 KB,
pig 174–184 KB, sheep 178–181 KB.

## Commit & push

- **Commit(s):** `25c4c09` — `feat(critters): head-only art v2 + breathing idle animation`
- **Push:** `origin/main` — ok (`a43ba5b..25c4c09`)

## Open items for the owner

- Visual check on a real device/emulator: confirm the new heads look right and
  the breathing reads as intended (tests can't judge the art itself).

## Deviations from prompt

None.
