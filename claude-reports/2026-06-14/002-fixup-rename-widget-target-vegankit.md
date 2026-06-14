# Fixup: correct the widget Swift internals + make it bundle-friendly

**Prompt:** `claude-prompts/2026-06-14/002-fixup-rename-widget-target-vegankit.md`
**Completed:** 2026-06-14 · **Status:** done

> Keep this short. Git holds the diff — Planning Claude reads it with `git show`.

## Summary

Prompt 006 renamed the widget file path + Dart + Android but left the Swift
file's *internals* on the old names (`kind: "VeggieWidget"`, `struct
VeggieWidget`, etc.), so the widget's `kind` no longer matched the Dart
`iOSName: 'VeganKitWidget'` and it would never update. The committed widget file
also still carried its own `@main`, which collides with the `@main` in the
Xcode-generated `VeganKitWidgetBundle.swift`. I overwrote both Swift files with
the corrected, final content from the prompt: the widget now uses
`kind: "VeganKitWidget"` with renamed structs and **no** `@main`, and the Bundle
holds the single `@main` listing only `VeganKitWidget()`. Swift-only change;
committed and pushed as exactly two files.

## Files touched

- `ios/VeganKitWidget/VeganKitWidget.swift` — corrected `kind` to
  `"VeganKitWidget"`, renamed structs (`VeganKitWidget`,
  `VeganKitTimelineProvider`, `VeganKitWidgetView`), removed the duplicate
  `@main`. (Was modified; net +8/-7 vs the 006 version.)
- `ios/VeganKitWidget/VeganKitWidgetBundle.swift` — trimmed the body to a single
  `@main` WidgetBundle listing only `VeganKitWidget()` (dropped the generated
  `VeganKitWidgetControl()` / `VeganKitWidgetLiveActivity()` lines). This file
  was previously untracked (Xcode-generated); it is now tracked.

## Decisions

None. Both files were specified verbatim between the `===BEGIN===` / `===END===`
markers; I wrote them exactly. Per the prompt I left the placeholder/fallback
content strings (`"🌱 Veggie"`, `"Veggie"`) and the `// Veggie cream` comment
as-is — they are display/data, not the target name.

## Verification

Swift-only change — `flutter analyze` / `flutter test` don't cover Swift, so they
weren't required; I confirmed no Dart/Android files were altered (only the two
Swift files are in the commit).

```
$ grep -n 'kind:|@main|struct VeganKitWidget|VeganKitTimelineProvider' \
    ios/VeganKitWidget/VeganKitWidget.swift
20: struct VeganKitTimelineProvider: TimelineProvider {
91: struct VeganKitWidgetView: View {
122: struct VeganKitWidget: Widget {
125:     kind: "VeganKitWidget",
126:     provider: VeganKitTimelineProvider()
# → kind correct, structs renamed, NO @main in this file ✓

$ grep -n '@main|VeganKitWidget()' ios/VeganKitWidget/VeganKitWidgetBundle.swift
4: @main
7:     VeganKitWidget()
# → single @main, body lists only VeganKitWidget() ✓

$ git show --stat HEAD
 ios/VeganKitWidget/VeganKitWidget.swift       | 13 +++++-------
 ios/VeganKitWidget/VeganKitWidgetBundle.swift |  9 +++++++++
 2 files changed   # → only the two Swift files ✓
```

Three-name agreement holds: Swift `kind` = `"VeganKitWidget"`, Dart
`_iosWidgetName` = `'VeganKitWidget'` (unchanged), Xcode target name =
`VeganKitWidget`. App Group `group.io.develooper.vegankit` untouched.

Self-correction: none needed.

## Commit & push

- **Commit:** `8058ef4` — `fix(widget): correct VeganKitWidget Swift kind/structs and drop duplicate @main`
- **Push:** `origin/main` — ok (`39ddc29..8058ef4`).

## Open items for the owner

- `VeganKitWidgetControl.swift` and `VeganKitWidgetLiveActivity.swift` were left
  on disk untouched (still untracked) — `project.pbxproj` references them, so
  removing them at the git level would break the Xcode build. **Delete them
  inside Xcode** (right-click → Move to Trash), which keeps `project.pbxproj`
  valid. The trimmed Bundle no longer references them.
- Other working-tree changes (app icons, `ios/Runner.xcodeproj/project.pbxproj`,
  `CLAUDE.md`, the Android provider, etc.) were left untouched — not swept into
  this commit.

## Deviations from prompt

None.
