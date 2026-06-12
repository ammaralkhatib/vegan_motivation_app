# Register + optimize the Pexels background images

**Prompt:** `claude-prompts/2026-06-12/007-register-background-images.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Ammar dropped 110 portrait Pexels JPGs (~31 MB) into the 6 category folders.
I downscaled + recompressed every one, renamed them to our `<categoryId>_NN`
convention, wrote a credits file, and filled in the manifest. All 110 converted
(0 dropped). Final bundle payload is **11 MB** (down from 31 MB — about a third,
as asked). `flutter analyze` is clean and all 124 tests pass.

**Important:** I could **not** produce WebP on this machine, so I used the
prompt's JPG fallback. See Decisions — the quality is lower than WebP would give,
and there's an easy way to redo it better later.

## Files touched

- `assets/images/backgrounds/<cat>/<cat>_NN.jpg` (110 new files) — the converted,
  renamed, downscaled images (one set per category).
- `assets/images/backgrounds/<cat>/.gitkeep` (6 deleted) — no longer needed now
  that each folder has real images. Original `pexels-*.jpg` files deleted too.
- `assets/images/backgrounds/credits.json` (new) — one entry per image
  (`file`, `photographer`, `source`), derived from the original Pexels filenames.
- `assets/content/backgrounds_v1.json` — each category now lists its new
  filenames (same `version: 1`, schema unchanged).

## Decisions

- **JPG instead of WebP (forced).** The prompt's tool ladder is cwebp → magick →
  sips → JPG fallback. This machine has **none** of the WebP-capable tools:
  `cwebp` and ImageMagick aren't installed, Homebrew is broken (a missing
  `libllhttp` dylib), and macOS's own encoder (`sips` / ImageIO, which `sips`
  uses under the hood) has no WebP **writer** — `CGImageDestinationCreateWithURL`
  with the WebP type returns nil, so `sips -s format webp` fails with
  "Can't write format". Pillow/ffmpeg also absent. So I used the prompt's
  explicit JPG fallback (`sips` → JPEG). "The renderer accepts both" — confirmed
  in code: `background_manifest.dart` stores the bare filename and builds the
  path with no extension assumption, so `.jpg` works.
- **Width 1080, quality 30 (not ~75).** "max width 1080" + "quality ~75" was
  sized for WebP. As JPG, width-1080/q75 came out to ~34 MB — far over the 13 MB
  gate. I kept the width at 1080 (req 1's explicit number; "max" allows ≤1080)
  and lowered JPEG quality until the hard ≤13 MB budget was met with margin.
  Measured totals: q75→34 MB, q50→20 MB, q35→12.9 MB (too close to the gate
  given `du` block rounding), **q30→11 MB** (chosen — safe margin, and matches
  the goal "roughly a third of 32 MB"). Lowering quality shrank size more than
  lowering width did, so width stayed faithful to the prompt.
- **Credits parsing.** From `pexels-<slug?>-<userid?>-<photoId>.jpg`: photoId =
  last numeric token; photographer = the leading non-numeric tokens joined by
  `-`. 4 images have no name in the filename (just numbers) → `photographer: ""`.
  `source` = `https://www.pexels.com/photo/<photoId>/`.

## Verification

```
$ flutter analyze
No issues found! (ran in 2.5s)

$ flutter test
00:03 +124: All tests passed!

$ du -sh assets/images/backgrounds
11M   assets/images/backgrounds
```

Per-category counts (all ≥10, all portrait, all width 1080):
why_vegan 23 · quick_tips 21 · youre_awesome 18 · facts 18 · staying_strong 13
· milestones 17  → **110 total, 0 dropped**.

Spot-check (`sips -g`): `why_vegan_01.jpg` 1080×1922, `facts_10.jpg` 1080×1440,
`milestones_17.jpg` 1080×1620 — all valid JPEGs.

Self-correction: none needed (analyze + tests green on first run).
Manual click-path (Ammar): [ ] premium dev build → every feed card shows a photo;
text readable on light and dark photos.

## Commit & push

- **Commit:** `e71c085` — `feat(quotes): bundle 110 Pexels background images`
- **Push:** `origin/main` — ok (`522475f..e71c085`).

## Open items for the owner

- **Quality could be much better with WebP.** Right now these are JPEG q30 — fine
  behind the card scrim, but not premium-crisp. If you install `cwebp`
  (`brew install webp`, once Homebrew is fixed — your `libllhttp` dylib is
  missing) I can re-run this prompt and ship WebP q75: better-looking **and**
  roughly half the size (~6 MB). The originals are gone from the folders, but
  Pexels still has them via the URLs in `credits.json` if you want the full-res
  source again.
- **Heads-up: your Homebrew is broken.** `git`, `swift`'s interpreter, and other
  brew-linked tools abort with `Library not loaded: .../libllhttp.9.3.dylib`. I
  worked around it (used `/usr/bin/git`), but you may want to fix it:
  `brew reinstall llhttp libgit2` (or `brew update && brew upgrade`).

## Deviations from prompt

- **WebP → JPG**, and **quality ~75 → 30**: both forced by the no-WebP-tools
  situation and the 13 MB budget, as explained in Decisions. Width (1080) and all
  other requirements (rename convention, credits, manifest, ≥10/category,
  portrait, ≤13 MB, no code/pubspec changes) met as written.
