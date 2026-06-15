# Set the real RevenueCat public SDK API keys

**Prompt:** `claude-prompts/2026-06-15/001-set-revenuecat-api-keys.md`
**Completed:** 2026-06-15 · **Status:** done

> Keep this short. Git holds the diff — Planning Claude reads it with `git show`.

## Summary

The app shipped placeholder RevenueCat keys (`appl_TODO_…` / `goog_TODO_…`), so
`Purchases.getOfferings()` failed and every paywall showed "Can't load offers
right now." I replaced the two key constants in
`lib/core/purchases/purchase_config.dart` with the real public SDK keys Ammar
provided from the dashboard. Keys only — no offering ids, entitlement id, or
logic changed. `flutter analyze` clean; committed and pushed as a single file.

## Files touched

- `lib/core/purchases/purchase_config.dart` — set `appleApiKey` and
  `googleApiKey` to the real public SDK keys; also removed the two now-done
  `TODO(ammar)` comment lines (the prompt allowed this). Everything else
  (doc comments, `forcePremium`, entitlement id, offering ids) unchanged.

## Decisions

- **Removed the two `TODO(ammar)` comment lines** — the prompt left this to my
  call and the keys are now set, so the TODOs are stale. Kept the
  "Apple key covers both iOS and macOS App Store apps." comment.

## Verification

```
$ git show -- lib/core/purchases/purchase_config.dart
# only the two key lines changed + the two TODO comment lines removed
# (2 insertions, 4 deletions)

$ git show --stat HEAD
 lib/core/purchases/purchase_config.dart | 6 ++----
 1 file changed   # → only this file

$ flutter analyze
No issues found! (ran in 2.6s)
```

Self-correction: none needed.

## Commit & push

- **Commit:** `57107b0` — `fix(purchases): set real RevenueCat public SDK API keys`
- **Push:** `origin/main` — ok (`3d65e5c..57107b0`).

## Open items for the owner

- These keys are **public SDK keys** (safe in the binary), matching the file's
  existing comment — nothing to rotate or hide.
- Next per CLAUDE.md §4: run a sandbox purchase test on a real device to confirm
  the offerings/paywalls now load. (Still requires the 3 store products + 3
  offerings + `premium` entitlement being live in the RevenueCat dashboard.)
- Other working-tree changes (app icons, pbxproj, the untracked widget files,
  etc.) were left untouched — only `purchase_config.dart` was committed.

## Deviations from prompt

None.
