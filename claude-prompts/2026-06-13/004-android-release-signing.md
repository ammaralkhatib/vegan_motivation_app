# Android release signing

## Goal
Make `flutter build appbundle --release` produce an app bundle signed with a real
**release/upload key** instead of the debug key, so Google Play stops rejecting it
("signed in debug mode"). The keystore file and its passwords are secrets Ammar
creates locally — they must **never** be committed. The Gradle config reads them from
an untracked `android/key.properties`; if that file is absent, the build falls back to
debug signing so other machines/CI can still build.

"Done" = with a valid `android/key.properties` + keystore present, `flutter build
appbundle --release` succeeds and the resulting `.aab` is signed with the release key
(verified, see Verify). With no `key.properties`, the build still works (debug-signed)
and prints nothing secret.

## Scope
- In: `android/app/build.gradle.kts` only.
- Out: do **not** create, commit, or print any keystore or `key.properties` file. Do
  not touch `.gitignore` (it already ignores `key.properties`, `**/*.jks`,
  `**/*.keystore`). No version bumps, no other Gradle changes.

## Requirements
1. At the top of `android/app/build.gradle.kts` (after the `plugins { }` block), load
   an optional properties file:
   - Read `android/key.properties` (i.e. `rootProject.file("key.properties")` resolved
     from the `android/` dir — use `rootProject.file("key.properties")`, which points
     at `android/key.properties`).
   - Load it into a `java.util.Properties` only if the file exists. Keep a boolean like
     `val hasReleaseSigning = keystorePropertiesFile.exists()`.
2. Inside `android { }`, add a `signingConfigs { }` block that creates a `release`
   config **only when** `hasReleaseSigning` is true, reading these keys from the
   properties file: `storeFile` (resolve via `file(...)`), `storePassword`, `keyAlias`,
   `keyPassword`.
3. Change the `release` build type so:
   - `signingConfig = signingConfigs.getByName("release")` when `hasReleaseSigning`,
   - else keep `signingConfig = signingConfigs.getByName("debug")` (current fallback).
   Remove the stale `// TODO: Add your own signing config...` comment and replace it
   with a short comment explaining the key.properties-driven behavior.
4. Leave `minify`/`shrinkResources` as they are (don't enable them in this prompt —
   that's a separate change and could break the release build).
5. Do not echo secret values anywhere (no `println` of passwords/paths).

## Reference shape (adapt to Kotlin DSL; don't copy blindly)
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseSigning) load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}
```

## Constraints
- Offline-first / Riverpod / drift unaffected — this is Gradle only.
- The build must still succeed with **no** `key.properties` present (debug fallback),
  because that's the state on any clean checkout (the file is git-ignored).
- `flutter analyze` clean; `flutter test` green (this change shouldn't affect either,
  but run them per CLAUDE.md §2).
- Gradle must configure without error: run `cd android && ./gradlew :app:tasks -q`
  (or `flutter build appbundle --debug`) to prove the script still evaluates.

## Verify
- `flutter analyze` clean; `flutter test` green.
- With no `key.properties`: `flutter build appbundle --release` still completes
  (debug-signed) — confirms the fallback path compiles.
- Ammar will then create the real keystore + `key.properties` locally and re-run
  `flutter build appbundle --release`; he verifies the signer with:
  `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`
  (should list his upload key, not "CN=Android Debug").
- Record in the report the exact path Gradle reads `key.properties` from and the four
  keys it expects (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`).

## Commit & push
- Conventional Commit, e.g. `build(android): wire release signing via key.properties`.
- Body includes `Prompt: claude-prompts/2026-06-13/004-android-release-signing.md`.
- Confirm `git status` shows **no** `key.properties` or `*.jks` staged. Push to
  origin/main; on failure stop and report (never force).

## Report
- Write `claude-reports/2026-06-13/004-android-release-signing.md` from `TEMPLATE.md`.
  Record what changed, the `key.properties` path + expected keys, verification results,
  commit SHA, push result. Note the open item: Ammar must create the keystore +
  `key.properties` locally (Planning Claude gives him the `keytool` command) — without
  it the release build is still debug-signed. No full diff.
