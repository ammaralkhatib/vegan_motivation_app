# Investigate and fix the empty onboarding step

**Prompt:** `claude-prompts/2026-06-16/006-fix-empty-onboarding-step.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Investigated the reported blank step "around S25". The prime suspect was right:
the snapshot step's `_ValueCard` once built a `Column` with an `Expanded` child,
which throws a RenderFlex layout assertion inside the unbounded-height `ListView`
and renders blank in a release build. **But that bug is already fixed at HEAD** —
commit `2615c14` (Jun 15) restored the correct `Row` layout. So there was no live
source bug to fix. Because that commit's own message says the card *"had become a
Column"* (i.e. it has regressed at least once before), I added a regression test
that pumps `SnapshotStep` and fails if any card subtree throws during layout. No
source change was needed.

## Files touched

- `test/onboarding_snapshot_step_test.dart` (new) — regression guard for the
  blank-snapshot bug. Source files were **not** changed (none were broken).

## Decisions

- **No source change — the fix was already present.** I confirmed
  `snapshot_step.dart` is byte-identical to HEAD (`git diff` empty) and that
  `_ValueCard` is already a `Row`. Inventing a change would have been dishonest.
- **Root cause confirmed, not assumed.** I proved the test reproduces the real
  bug: temporarily reverting `_ValueCard` to the buggy `Column`+`Expanded` form
  made the new test go **RED** (RenderFlex assertion caught by
  `tester.takeException()`); restoring the `Row` made it **GREEN**. Then I
  confirmed the source matches HEAD again.
- **Added a regression test instead of redesigning.** This is the smallest
  durable action: the bug regressed once already, so a guard is the real fix.
- **Neighbors checked (S24, S26, S27).** S24 `_commitmentResponse` always renders
  a non-empty string (its copy helper has a fallback); S26 notifications and S27
  social proof are plain `ListView`s with no unbounded-flex children. All other
  onboarding flex usages are inside bounded `Row`s or the `InputStep`/`TapStep`
  shells — none can blank a step. No other broken step found.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
All tests passed! (176 — includes the new regression test)
```

RED/GREEN proof of the test: failed on the buggy `Column` layout, passed on the
current `Row` layout.

Self-correction: none needed.
Manual click-path: [ ] **pending Ammar's device run.** I can't drive a device, so
final visual confirmation that no step renders blank in a real release build is
still owed. Static review + the automated test say the onboarding steps are clean.

## Commit & push

- **Commit:** `61e94a6` — `test(onboarding): guard snapshot value card against blank-render regression`
- **Push:** `origin/main` — ok

## Open items for the owner

- **Device walk-through.** Please walk the full onboarding once on a device/
  emulator and watch the console for RenderFlex/overflow errors, especially S25
  snapshot and S26/S27. If you still see a blank step, capture the exact console
  error — it would mean a different root cause than the one already fixed, and
  I'll chase that specific error.

## Deviations from prompt

- The prompt expected a source fix. The actual root cause was **already fixed**
  before this prompt ran (commit `2615c14`), so the deliverable is a regression
  test rather than a code change. Reported honestly rather than fabricating a
  change.
