# Rename app id to io.develooper.vegankit

**Prompt:** `claude-prompts/2026-06-13/001-rename-app-id.md`
**Completed:** 2026-06-13 · **Status:** done

> Keep this short. Git holds the diff — Planning Claude reads it with `git show`.

## Summary

Renamed the app/bundle identifier everywhere it is defined from
`com.ammarkhatib.veggie` to `io.develooper.vegankit`, and the shared widget App
Group from `group.com.ammarkhatib.veggie` to `group.io.develooper.vegankit`.
Identifier-only change — no behavior, no display name, no DB name touched. The
required verify grep returns zero matches in tracked source, `flutter analyze` is
clean, and all 160 tests pass.

## Files touched

- `android/app/build.gradle.kts` — `namespace` + `applicationId` → new id.
- `android/app/src/main/kotlin/io/develooper/vegankit/MainActivity.kt`,
  `…/VeggieWidgetProvider.kt` — `git mv`d from the old `com/ammarkhatib/veggie/`
  path; `package` declarations updated. Old `com/…` dir tree removed.
- `ios/Runner.xcodeproj/project.pbxproj` — all 6 `PRODUCT_BUNDLE_IDENTIFIER`
  lines (Runner ×3, RunnerTests ×3) → new id / `.RunnerTests`.
- `ios/Runner/Runner.entitlements`, `ios/VeggieWidget/VeggieWidget.entitlements`,
  `ios/VeggieWidget/VeggieWidget.swift` — App Group string → new value.
- `macos/Runner/Configs/AppInfo.xcconfig` — bundle id → new id.
- `macos/Runner.xcodeproj/project.pbxproj` — 3 `*.RunnerTests` ids normalized
  from the old `com.ammarkhatib.veganMotivationApp.RunnerTests` to
  `io.develooper.vegankit.RunnerTests`.
- `lib/core/widgetkit/home_widget_service.dart` — `_appGroupId` → new App Group.
- `lib/core/notifications/notification_service.dart` — `appUserModelId` → new id.
- `docs/IOS_WIDGET_SETUP.md`, `docs/STORE_SETUP.md` — old id/App-Group references
  updated so the docs stay accurate.

## Decisions

- **AndroidManifest.xml left unchanged** — it references `.MainActivity` and
  `.VeggieWidgetProvider` relatively, which resolve against the new `namespace`.
  No absolute class names, so no edit needed (verified, as the prompt asked).
- **iOS VeggieWidget extension bundle id not set in pbxproj** — the widget target
  does not exist in `project.pbxproj` yet (it's the pending manual Xcode step in
  `docs/IOS_WIDGET_SETUP.md`). There was no `…VeggieWidget` id line to change. Its
  Swift App-Group string and entitlements *are* updated; the target's bundle id
  (`io.develooper.vegankit.VeggieWidget`) gets set when Ammar adds the target in
  Xcode — the doc now states the new value.
- **Copyright / CompanyName strings left unchanged** — `com.ammarkhatib` still
  appears in macOS `PRODUCT_COPYRIGHT` and Windows `Runner.rc` company/copyright
  fields. Those are a company-name brand string, not the bundle identifier and not
  in the prompt's scope or verify grep. Left untouched to avoid scope creep.

## Verification

```
$ grep -rn "com\.ammarkhatib\.veggie\|group\.com\.ammarkhatib\.veggie" . \
    | grep -vE "Pods/|/build/|\.gradle/|xcuserdata|\.dart_tool/"
(only the prompt file itself; zero matches in tracked source)

$ flutter clean && flutter pub get && flutter analyze
No issues found! (ran in 1.6s)

$ flutter test
All tests passed!  (+160)
```

Self-correction: none needed — clean on first run.
Manual click-path (pending Ammar): [ ] build iOS + Android under the new id,
launch the app, add the home-screen widget, confirm it shows live data (proves
the App Group matches end-to-end).

## Commit & push

- **Commit:** `115a84c` — `chore: rename app id to io.develooper.vegankit`
- **Push:** `origin/main` — ok (`91c8fe9..115a84c`).

## Open items for the owner

Out-of-repo follow-ups the rename now requires (none are code):

- **App Store Connect:** new app record / bundle id `io.develooper.vegankit`.
- **Play Console:** new app with package name `io.develooper.vegankit`.
- **Apple Developer portal:** register App Group `group.io.develooper.vegankit`,
  add it to the new app id's capabilities, and regenerate provisioning profiles.
- **RevenueCat dashboard:** point the app config at the new bundle id / package.
- **Xcode (iOS widget):** when adding the VeggieWidget extension target, set its
  bundle id to `io.develooper.vegankit.VeggieWidget` (nested under the app id) —
  see `docs/IOS_WIDGET_SETUP.md`.
- **Manual widget data check** (above) is still pending on a real device/sim.

## Deviations from prompt

None. (The widget-extension pbxproj id in Requirement 3 has no line to change
because the target isn't in the Xcode project yet — covered under Decisions.)
