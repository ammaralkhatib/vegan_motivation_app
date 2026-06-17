# Remove the temporary notification diagnostic + bump build number

**Prompt:** `claude-prompts/2026-06-17/002-remove-diagnostic-bump-version.md`
**Completed:** 2026-06-17 · **Status:** done

## Summary

The diagnostic from prompt 001 is **fully removed** — it will not ship to the
App Store. The three touched files are **back to their exact pre-001 state**, and
the version is now **1.0.1+3**. `flutter analyze` is clean and `flutter test` is
green (178 tests — the pre-001 baseline, so no leftover diagnostic tests).

The earlier "quote notifications never fire" silence was just stale build state:
on a fresh device build both test notifications fired, so the real code was fine.

## How I removed it (so you can trust it's clean)

I restored each of the three code files from the commit right before the 001
diagnostic (`e797609`) with `git checkout e797609 -- <file>`. That makes them
**byte-for-byte identical** to the pre-001 version — not a hand edit that "looks
right". Proof:

- `grep -rn "TEMP DIAGNOSTIC" lib/` → **no matches**.
- `git diff e797609 -- <the three files>` → **empty**.

So `reschedule()` / `rescheduleHabits()` are back to their original form with **no
try/catch error-swallowing**, and the notification settings screen shows only the
real controls (master switch, mode, per-day, window / meals) — no diagnostics
card, no test buttons, no "force reschedule" button.

## Files touched

- `lib/features/settings/notification_settings_screen.dart` — restored to pre-001.
- `lib/core/notifications/notification_service.dart` — restored to pre-001.
- `lib/core/notifications/notification_coordinator.dart` — restored to pre-001.
- `pubspec.yaml` — `version: 1.0.1+2` → `1.0.1+3` (name unchanged, build +1).

(The 001 prompt and report markdown files are kept as project history — only the
code was reverted.)

## Verification

```
$ grep -rn "TEMP DIAGNOSTIC" lib/
(no matches)

$ flutter analyze
No issues found! (ran in 2.2s)

$ flutter test
All tests passed! (178)
```

Self-correction: none needed (passed first try).

## Commit & push

- **Commit:** `75cf9bb` — `chore(release): remove temp notification diagnostic, bump to 1.0.1+3`
- **Push:** `origin/main` — ok.

## Open items for the owner

- Build and upload the new `1.0.1+3` to TestFlight. If App Store Connect ever
  rejects `+3` as already-used, the next run bumps the build number again.

## Deviations from prompt

None.
