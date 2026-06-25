# Rename the on-device app name to "Stay Vegan"

**Prompt:** `claude-prompts/2026-06-23/004-rename-app-to-stay-vegan.md`
**Completed:** 2026-06-23 · **Status:** done

## Summary

Changed the on-device app name (the label under the icon and in the task switcher)
from `VeganKit` to **`Stay Vegan`** on every platform target plus the Flutter app
title. This is a label-only change — no bundle id, package, applicationId, binary
name, or signing was touched. Analyzer is clean and all 172 tests pass.

## Files touched

One line each — the reason, not the diff.

- `ios/Runner/Info.plist` — `CFBundleDisplayName` and `CFBundleName` → `Stay Vegan`
  (the iOS home-screen label).
- `android/app/src/main/AndroidManifest.xml` — `android:label` → `Stay Vegan` (the
  Android launcher label).
- `lib/app/app.dart` — `MaterialApp.title` → `Stay Vegan` (the Android task-switcher
  label).
- `macos/Runner/Info.plist` — added `CFBundleDisplayName` = `Stay Vegan`.
- `windows/runner/Runner.rc` — `ProductName` value → `Stay Vegan` (internal
  `OriginalFilename` / `InternalName` left unchanged).

## Decisions

- **macOS done via `CFBundleDisplayName`, not `PRODUCT_NAME`.** The prompt preferred
  this. I added a `CFBundleDisplayName` key to `macos/Runner/Info.plist` and left
  `PRODUCT_NAME = VeganKit` in `AppInfo.xcconfig` untouched, so `CFBundleName` (which
  derives from `PRODUCT_NAME`) and the built executable/bundle keep the `VeganKit`
  name. The user-visible name shows `Stay Vegan` without renaming the binary or
  risking the build.
- **In-app brand text left as "VeganKit".** Onboarding welcome copy and the
  "VeganKit Premium" settings row still say VeganKit. These are in-app content
  strings, not the on-device app label, and are out of scope for this rename. No test
  changes were needed — none assert `MaterialApp.title` (which isn't a findable text
  widget anyway).
- **Notification heading left as "VeganKit 🌱".** That's the daily-notification title
  in `notification_service.dart`, not the app label; out of scope.

## Verification

```
$ flutter analyze
No issues found! (ran in 1.9s)

$ flutter test
00:07 +172: All tests passed!
```

Self-correction: none needed.

Grep confirms no stray user-visible `VeganKit` label in the scoped manifest/plist/app
files — all five now read `Stay Vegan`. (macOS `PRODUCT_NAME`/bundle name and the
Windows internal filename strings legitimately stay `VeganKit` / `vegan_motivation_app`.)

Manual click-path (needs a device — not run here):
- [ ] Installed app shows "Stay Vegan" under its icon on iOS.
- [ ] Installed app shows "Stay Vegan" under its icon on Android.

## Commit & push

- **Commit:** `9daa157` — `chore(branding): rename on-device app to "Stay Vegan"`
- **Push:** `origin/main` — ok (`bd0cfe5..9daa157`)

## Open items for the owner

- Confirm the home-screen label reads "Stay Vegan" on a real iOS and Android install
  (label changes can only be verified on a device, not in unit/widget tests).

## Deviations from prompt

None.
