# Rename the home-screen widget target VeggieWidget → VeganKitWidget

**Prompt:** `claude-prompts/2026-06-13/006-rename-widget-target-vegankit.md`
**Completed:** 2026-06-13 · **Status:** done

> Keep this short. Git holds the diff — Planning Claude reads it with `git show`.

## Summary

The app display name is now **VeganKit**, but the home-screen widget was still
built under the old code name `VeggieWidget` / `VeggieWidgetProvider`. I renamed
the widget target/identifier to `VeganKitWidget` across the Dart bridge, the iOS
Swift sources, the Android Kotlin provider + manifest + resource XML, and the
setup doc — using `git mv` so history is preserved. The iOS `kind:` string, the
Android provider class, the Dart name constants, the renamed files, and the doc
all now agree on `VeganKitWidget` / `VeganKitWidgetProvider`. `flutter analyze`
is clean and all 166 tests pass.

## Files touched

- `lib/core/widgetkit/home_widget_service.dart` — set `_androidProvider =
  'VeganKitWidgetProvider'` and `_iosWidgetName = 'VeganKitWidget'`.
- `ios/VeganKitWidget/VeganKitWidget.swift` — renamed from
  `ios/VeggieWidget/VeggieWidget.swift`; renamed the Swift types
  (`VeganKitWidget`, `VeganKitWidgetView`, `VeganKitTimelineProvider`) and the
  `kind:` string to `"VeganKitWidget"`.
- `ios/VeganKitWidget/VeganKitWidget.entitlements` — renamed from
  `ios/VeggieWidget/VeggieWidget.entitlements` (contents unchanged).
- `android/app/src/main/kotlin/io/develooper/vegankit/VeganKitWidgetProvider.kt`
  — renamed file + class `VeggieWidgetProvider → VeganKitWidgetProvider` (same
  package).
- `android/app/src/main/AndroidManifest.xml` — receiver
  `android:name=".VeganKitWidgetProvider"`, meta-data
  `android:resource="@xml/vegankit_widget_info"`.
- `android/app/src/main/res/xml/vegankit_widget_info.xml` — renamed from
  `veggie_widget_info.xml` (contents unchanged).
- `docs/IOS_WIDGET_SETUP.md` — every `VeggieWidget` → `VeganKitWidget`, including
  paths, the `iOSName` line, the target-name bullet, and the widget bundle id
  `io.develooper.vegankit.VeganKitWidget`.

## Decisions

- **Left content/placeholder string literals as-is** (per Scope/Out): the
  category fallbacks `"🌱 Veggie"` (swift line 14) / `"Veggie"` (swift line 59),
  the Kotlin fallback `"🌱 Veggie"` (kt line 39), and the `// Veggie cream`
  color comment. These are display data, not target names.
- **Staged only the 7 in-scope widget files.** The working tree has unrelated
  pre-existing changes (app icons, CLAUDE.md, Podfile.lock); those were left
  untouched and out of this commit.
- Confirmed via `grep` that `ios/Runner.xcodeproj/project.pbxproj` has zero
  `VeggieWidget` refs — the Xcode widget target still does not exist, so no
  pbxproj edit was made (matches Scope/Out).

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
All tests passed! (166 tests, +166)
```

Self-correction: none needed (clean first pass).

Four name pairings — all confirmed by eye:

- Dart `_iosWidgetName` (`'VeganKitWidget'`) ↔ Swift `kind:` (`"VeganKitWidget"`) ✓
- Dart `_androidProvider` (`'VeganKitWidgetProvider'`) ↔ Kotlin class
  `VeganKitWidgetProvider` ✓
- Manifest `android:name=".VeganKitWidgetProvider"` ↔ Kotlin class ✓
- Manifest `@xml/vegankit_widget_info` ↔ file `res/xml/vegankit_widget_info.xml` ✓

`grep -rn "VeggieWidget\|veggie_widget\|VeggieWidgetProvider" lib ios android docs`
returns nothing.

Note: the Swift / Kotlin sources aren't covered by `flutter test`; verified by
inspection. No `flutter build` run (the iOS widget target doesn't exist yet, and
no Drift schema change → no `build_runner`).

## Commit & push

- **Commit:** `3228da3` — `refactor(widget): rename widget target VeggieWidget → VeganKitWidget`
  (SHA recorded in a small follow-up `docs` commit, matching the repo's existing
  pattern — e.g. commit `30d6332` for the 005 report.)
- **Push:** `origin/main` — ok

## Open items for the owner

- Manual (on device, later): build Runner, add the widget — confirm it still
  shows the daily quote. The iOS widget Xcode **target** is still created
  manually per `docs/IOS_WIDGET_SETUP.md`; this prompt only made the names it
  will use correct.

## Deviations from prompt

None.
