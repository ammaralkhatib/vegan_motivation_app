# Rename app/bundle identifier to io.develooper.vegankit

## Goal
Change the app's identifier everywhere it's defined from the current
`com.ammarkhatib.veggie` to **`io.develooper.vegankit`**, and the shared widget
App Group from `group.com.ammarkhatib.veggie` to **`group.io.develooper.vegankit`**.
"Done" means the app builds and runs on iOS and Android under the new identifier,
the home-screen widget still shares data with the app (App Group matches on both
sides), and no reference to the old identifier remains anywhere in tracked source
(outside generated/build folders). This is a pre-launch rename — there is no
published listing to preserve.

## Scope
- **In:**
  - `android/app/build.gradle.kts` — `namespace` and `applicationId`.
  - Android Kotlin sources: move
    `android/app/src/main/kotlin/com/ammarkhatib/veggie/` →
    `android/app/src/main/kotlin/io/develooper/vegankit/`, and update the `package`
    declaration at the top of `MainActivity.kt` and `VeggieWidgetProvider.kt` to
    `io.develooper.vegankit`. Delete the now-empty old `com/ammarkhatib/...` dirs.
  - `android/app/src/main/AndroidManifest.xml` — only if any class is referenced by
    an absolute name; the relative `.MainActivity` / `.VeggieWidgetProvider` forms
    resolve against `namespace` and should need no change. Verify, don't force.
  - iOS `ios/Runner.xcodeproj/project.pbxproj` — every `PRODUCT_BUNDLE_IDENTIFIER`:
    Runner → `io.develooper.vegankit`, RunnerTests → `io.develooper.vegankit.RunnerTests`,
    VeggieWidget extension → `io.develooper.vegankit.VeggieWidget` (keep the widget a
    child of the main id).
  - `ios/Runner/Runner.entitlements` and `ios/VeggieWidget/VeggieWidget.entitlements`
    — App Group string → `group.io.develooper.vegankit`.
  - `ios/VeggieWidget/VeggieWidget.swift` — the hardcoded App Group string →
    `group.io.develooper.vegankit`.
  - macOS (for consistency; not a shipping target but keep it clean):
    `macos/Runner/Configs/AppInfo.xcconfig` → `io.develooper.vegankit`, and the
    `*.RunnerTests` `PRODUCT_BUNDLE_IDENTIFIER` lines in
    `macos/Runner.xcodeproj/project.pbxproj` → `io.develooper.vegankit.RunnerTests`
    (note: one currently reads `com.ammarkhatib.veganMotivationApp.RunnerTests` —
    normalize it to the new base too).
  - Dart: `lib/core/widgetkit/home_widget_service.dart` `_appGroupId` →
    `group.io.develooper.vegankit`; `lib/core/notifications/notification_service.dart`
    `appUserModelId` → `io.develooper.vegankit`.
  - Docs: `docs/IOS_WIDGET_SETUP.md` and `docs/STORE_SETUP.md` — update the old
    identifier/App-Group references so the docs stay accurate.
- **Out (do NOT touch):**
  - `driftDatabase(name: 'veggie')` in `lib/core/db/database.dart` — that's the local
    DB filename, not the bundle id. Changing it would orphan existing user data.
  - Any user-facing "veggie" brand/app-name strings (e.g. `lib/l10n/**`,
    `CFBundleName`/`CFBundleDisplayName`). This task changes the *identifier* only,
    not the display name.
  - Generated/build artifacts: `ios/Pods/**`, `**/build/**`, `android/.gradle/**`,
    `**/xcuserdata/**`, `.dart_tool/**`. Don't hand-edit these — they regenerate.

## Requirements
1. After the change, `grep -rn "com\.ammarkhatib\.veggie"` and
   `grep -rn "group\.com\.ammarkhatib\.veggie"` over tracked source (excluding the
   generated/build dirs listed in Scope > Out) return **zero** matches.
2. The Android Kotlin package physically lives at
   `android/app/src/main/kotlin/io/develooper/vegankit/` with matching `package`
   declarations; the old `com/ammarkhatib/veggie` directory tree is gone.
3. iOS main app, RunnerTests, and the VeggieWidget extension all carry the new
   bundle id, with the widget id nested under the app id.
4. The App Group string is identical (`group.io.develooper.vegankit`) in all four
   places it appears: Runner.entitlements, VeggieWidget.entitlements,
   VeggieWidget.swift, and home_widget_service.dart.
5. App name / display name and the Drift DB name are unchanged.

## Constraints
- Locked stack/decisions per CLAUDE.md §3 hold (offline-first; Riverpod/drift/go_router;
  home_widget <0.8; versioned content imports). This change touches none of those
  behaviors — it's identifier-only.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries per
  CLAUDE.md §2). Run `flutter clean` before the verification build so stale artifacts
  under the old id don't mask a problem.
- Do not regenerate or reformat the Xcode project beyond the identifier lines; keep
  the pbxproj diff minimal and limited to `PRODUCT_BUNDLE_IDENTIFIER` values.

## Verify
- `grep -rn "com\.ammarkhatib\.veggie\|group\.com\.ammarkhatib\.veggie" . \
   | grep -vE "Pods/|/build/|\.gradle/|xcuserdata|\.dart_tool/"` → no output.
- `flutter clean && flutter pub get && flutter analyze && flutter test`.
- Manual (Ammar, on device/sim): build iOS + Android; confirm app launches, then
  add the home-screen widget and confirm it shows live data (proves the App Group
  matches end-to-end). Note in the report that this manual step is pending Ammar.

## Commit & push
- Conventional Commit, e.g. `chore: rename app id to io.develooper.vegankit`.
- Commit body includes `Prompt: claude-prompts/2026-06-13/001-rename-app-id.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write `claude-reports/2026-06-13/001-rename-app-id.md` from TEMPLATE.md
  (`mkdir -p` the folder). Record intent, the exact files touched, the grep result,
  recorded `flutter analyze`/`test` output, commit SHA, push result, and open items —
  especially the pending manual widget check and the out-of-repo follow-ups
  (new App Store Connect / Play Console records, RevenueCat app config, Apple
  Developer App Group + provisioning profiles for the new id).
