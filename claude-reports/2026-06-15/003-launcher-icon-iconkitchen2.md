# Replace launcher icon with IconKitchen-Output(2)

**Prompt:** `claude-prompts/2026-06-15/003-launcher-icon-iconkitchen2.md`
**Completed:** 2026-06-15 · **Status:** done

## Summary

Swapped the Android + iOS launcher icon to the new mint-background set in
`../IconKitchen-Output(2)/`. Direct asset copy only — `flutter_launcher_icons` was
**not** run, so the adaptive background/foreground/monochrome layers are preserved.
Android now carries all three adaptive layers in every density; iOS now has only the
new `AppIcon-*.png` set + `Contents.json` (no stale `Icon-App-*.png`). Analyze clean,
all 166 tests green.

## Files touched

- `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/` — overwrote
  `ic_launcher.png` and added `ic_launcher_background/foreground/monochrome.png` in
  each (the three layer PNGs were already untracked in the working tree; now committed).
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` — new adaptive icon
  referencing the background + foreground + monochrome mipmaps.
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — deleted the 21 old
  `Icon-App-*.png` + old `Contents.json`; copied in the 21 new `AppIcon-*.png` and the
  new `Contents.json`.

## Decisions

- **Copied with `AppIcon*.png`, not `AppIcon-*.png`.** The iOS source includes files
  with no hyphen after `AppIcon` (e.g. `AppIcon@3x.png`, `AppIcon~ios-marketing.png`).
  The prompt's "`AppIcon-*.png`" wording would have skipped the marketing/1024 icon and
  several others that `Contents.json` references. I copied the full `AppIcon*.png` set so
  every filename referenced in `Contents.json` exists — which is the real requirement.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.7s)

$ flutter test
All tests passed!  (166 tests, +166)
```

Self-correction: none — asset-only change, clean on first run.

Manual / spot checks:
- [x] `file mipmap-xxxhdpi/ic_launcher.png` → `PNG image data, 192 x 192`.
- [x] `mipmap-anydpi-v26/ic_launcher.xml` references `@mipmap/ic_launcher_background`,
      `_foreground`, `_monochrome`; all three exist in every density folder.
- [x] appiconset lists only `AppIcon-*.png` / `AppIcon*.png` + `Contents.json`, no
      `Icon-App-*.png`; every `Contents.json` filename has a matching file.
- [x] `git status` showed only the in-scope icon paths changed; the pre-existing
      unrelated working-tree changes (CLAUDE.md, widget provider, etc.) were left staged
      nowhere and untouched.
- [ ] `flutter run` on device/sim to eyeball the icon — not run (no device/sim here).

## Commit & push

- **Commit:** `e9e5b82` — `chore(icons): swap launcher icon to IconKitchen-Output(2)`
- **Push:** `origin/main` — ok

## Open items for the owner

- **macOS / Windows / web icons intentionally left unchanged** (out of scope). If you
  want those to match the new mint icon too, that's a separate prompt.
- A quick `flutter run` on a real Android device + iPhone to confirm the new launcher
  icon and the Android adaptive/monochrome (themed) icon render as expected.

## Deviations from prompt

- See Decisions: used `AppIcon*.png` instead of the prompt's literal `AppIcon-*.png`
  glob so the no-hyphen files (incl. the 1024 marketing icon) referenced by
  `Contents.json` were copied. End state still matches requirement 4 (only the new
  AppIcon set + Contents.json, no `Icon-App-*.png`).
