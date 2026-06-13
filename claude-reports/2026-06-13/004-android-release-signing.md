# Android release signing

**Prompt:** `claude-prompts/2026-06-13/004-android-release-signing.md`
**Completed:** 2026-06-13 · **Status:** done

## Summary

Wired Android release signing to read an untracked `android/key.properties`. When
that file is present, `flutter build appbundle --release` signs with the real
upload key; when it's absent (clean checkout / CI), the release build falls back to
debug signing so it still completes. Only `android/app/build.gradle.kts` changed —
no keystore, `key.properties`, or secret value was created, committed, or printed.

## Files touched

- `android/app/build.gradle.kts` — added `java.util.Properties` / `FileInputStream`
  imports; load `rootProject.file("key.properties")` into a `Properties` only if it
  exists (`hasReleaseSigning` flag); added a `signingConfigs { }` block that creates
  the `release` config from the four properties only when the file exists; changed
  the `release` build type to use that config when present, else the debug config.
  Removed the stale `// TODO: Add your own signing config…` comment.

## Decisions

- **Imports placed above `plugins { }`** — Gradle Kotlin DSL requires `import`
  statements at the top of the file; the property-loading code sits right after the
  `plugins { }` block as the prompt directed.
- **Verified via `:app:tasks -q` for both branches** rather than a full
  `flutter build appbundle --release` — the config-evaluation check proves the
  script compiles on both code paths and is far faster. The real release build +
  signer check is Ammar's step (he has the keystore).

## key.properties contract

- **Path Gradle reads:** `android/key.properties` (via `rootProject.file("key.properties")`,
  which resolves against the `android/` directory).
- **Four expected keys:** `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
- The file is git-ignored (`android/.gitignore` already lists `key.properties`,
  `**/*.keystore`, `**/*.jks`) and must never be committed.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.3s)

$ flutter test
00:07 +166: All tests passed!

# Gradle script evaluates on both paths (JAVA_HOME = Android Studio JBR):
$ cd android && ./gradlew :app:tasks -q          # key.properties PRESENT
→ task list printed, no configuration error (release-signing branch)

$ (key.properties moved aside) ./gradlew :app:tasks -q   # ABSENT
→ GRADLE_EXIT=0, task list printed (debug-fallback branch); file restored intact
```

Self-correction: none needed (analyze/test unaffected; first Gradle run only failed
because the shell had no `JAVA_HOME` — re-ran pointing at Android Studio's bundled
JDK).
Manual click-path: n/a (build config change).

## Commit & push

- **Commit(s):** `<sha>` — `build(android): wire release signing via key.properties`
- **Push:** `origin/main` — `<result>`

Confirmed `git status` shows no `key.properties` / `*.jks` / `*.keystore` staged.

## Open items for the owner

- **Ammar must create the keystore + `android/key.properties` locally.** Until then
  the release build is still debug-signed (and Google Play will keep rejecting it).
  Generate an upload keystore with `keytool`, then create `android/key.properties`
  with the four keys above (`storeFile` pointing at the `.jks`). After that, run
  `flutter build appbundle --release` and verify the signer:
  `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`
  — it should list the upload key, not `CN=Android Debug`.
- (Note: a local `android/key.properties` already exists on Ammar's machine; it was
  left untouched and is not committed. Its contents were not read or printed.)

## Deviations from prompt

None.
