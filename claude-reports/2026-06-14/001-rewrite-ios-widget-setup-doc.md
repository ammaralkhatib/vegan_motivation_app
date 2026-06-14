# Rewrite docs/IOS_WIDGET_SETUP.md as a beginner-friendly guide

**Prompt:** `claude-prompts/2026-06-14/001-rewrite-ios-widget-setup-doc.md`
**Completed:** 2026-06-14 · **Status:** done

> Keep this short. Git holds the diff — Planning Claude reads it with `git show`.

## Summary

Ammar created the Widget Extension target in Xcode, which generated Apple's
emoji sample files and overwrote our prepared quote-widget Swift. The old setup
doc was terse and assumed Xcode knowledge. I replaced the whole of
`docs/IOS_WIDGET_SETUP.md` with the verbatim beginner guide from the prompt — a
10-section, step-by-step walkthrough for a first-time Xcode user (Xcode 26.x,
`home_widget ^0.7.0` / `iOSName:` API), including how to delete the generated
Control/LiveActivity files, trim the Bundle to a single `@main`, restore our
`VeganKitWidget.swift` from git, wire up the App Group, and troubleshoot.
Docs-only change, committed as a single file and pushed.

## Files touched

- `docs/IOS_WIDGET_SETUP.md` — replaced entirely with the prompt's verbatim
  beginner guide (238 insertions, 46 deletions).

## Decisions

None. The content was specified verbatim between `===BEGIN FILE===` /
`===END FILE===`; I wrote it exactly and did not reflow or improve wording.

## Verification

Docs-only change — no `flutter analyze` / `flutter test` needed (per prompt
Constraints).

- `git show --stat HEAD` → only `docs/IOS_WIDGET_SETUP.md` (1 file changed,
  +238 / -46). Confirmed single-file commit.
- `git status` after commit still lists the pre-existing uncommitted changes
  (app icons, `ios/Runner.xcodeproj/project.pbxproj`, the Xcode-modified
  `ios/VeganKitWidget/VeganKitWidget.swift`, `android/.../VeganKitWidgetProvider.kt`,
  etc.) — none were swept in. I staged only `docs/IOS_WIDGET_SETUP.md`
  (`git add docs/IOS_WIDGET_SETUP.md`, never `git add -A`).

Self-correction: none needed.

## Commit & push

- **Commit:** `f24afc6` — `docs(widget): rewrite IOS_WIDGET_SETUP for beginners`
  (SHA recorded in a small follow-up `docs` commit, matching the repo's pattern.)
- **Push:** `origin/main` — ok (`43a6608..f24afc6`).

## Open items for the owner

- The doc is now the guide to follow on your Mac to finish the iOS widget setup
  (create/fix the target, delete the generated Control + LiveActivity files,
  restore our `VeganKitWidget.swift`, add the App Group, build, add the widget).
- Your working tree still has uncommitted changes (app icons, pbxproj, the
  Xcode-generated/modified widget Swift). I left them exactly as they were —
  decide separately what to do with them.

## Deviations from prompt

None.
