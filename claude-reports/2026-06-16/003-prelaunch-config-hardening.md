# Pre-launch config hardening

**Prompt:** `claude-prompts/2026-06-16/003-prelaunch-config-hardening.md`
**Completed:** 2026-06-16 · **Status:** done

## Summary

Three independent pre-launch config fixes, no Dart logic touched: lock the phone
to portrait (iOS + Android), declare no non-exempt encryption so Apple stops
asking the export-compliance question, and drop a stale Flutter-template comment
in gradle. Analyze clean, all 178 tests green.

## Files touched

- `ios/Runner/Info.plist` — `UISupportedInterfaceOrientations` (iPhone) reduced
  to portrait-only (removed the two landscape entries); `~ipad` array left
  untouched. Added `ITSAppUsesNonExemptEncryption` = `<false/>`.
- `android/app/src/main/AndroidManifest.xml` — added
  `android:screenOrientation="portrait"` to `.MainActivity`; all other activity
  attributes (`configChanges`, `launchMode`, etc.) unchanged.
- `android/app/build.gradle.kts` — deleted the `// TODO: Specify your own unique
  Application ID …` template comment; `applicationId = "io.develooper.vegankit"`
  unchanged.

## Decisions

None — applied the prompt's exact edits. Staged only these three files; the other
pre-existing working-tree changes (CLAUDE.md, the widget Kotlin file, Podfile.lock,
project.pbxproj) were left alone as they're unrelated to this prompt.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
All tests passed! (178)
```

Config-only edits, so tests were unaffected. Self-correction: none needed.

## Commit & push

- **Commit:** `20d2644` — `chore(config): lock portrait, set encryption flag, drop stale gradle comment`
- **Push:** `origin/main` — ok

## Open items for the owner

- **Device rotation check (Ammar):** on a real phone (iOS and Android), rotate the
  device and confirm the app stays in portrait. I can't verify orientation lock
  from analyze/test.

## Deviations from prompt

None.
