# Premium photo backgrounds on quote feed cards (v1, bundled)

**Prompt:** `claude-prompts/2026-06-12/006-premium-card-backgrounds.md`
**Completed:** 2026-06-12 · **Status:** done

## Summary

Premium users now get a full-bleed photo behind each feed card, themed per
category, with a scrim so the quote stays readable. Free users see exactly
today's gradient — zero change. Images come from a versioned JSON manifest of
bundled assets, so a future CDN move only swaps the manifest source. The whole
thing degrades to the gradient when a category has no images — which is the
current state, since no images are curated yet. A premium-only settings switch
turns photos off. Analyze clean, all 119 tests pass (16 new). No new packages,
no DB changes.

## Files touched

- `lib/core/backgrounds/background_manifest.dart` (new) — `BackgroundManifest`
  model: `fromJson`, `pathsForCategory`, deterministic `pathForQuote`, `empty`.
- `lib/core/backgrounds/background_providers.dart` (new) — `backgroundManifest…`
  loader (FutureProvider → sync value provider) and the `photoBackgrounds`
  toggle provider (Notifier over prefs, like `themeModeProvider`).
- `lib/features/quotes/quote_card.dart` — background rendering only: gradient vs
  photo `Stack`.
- `lib/core/prefs/prefs_repository.dart` — one new `photoBackgrounds` toggle
  (default true).
- `lib/features/settings/settings_screen.dart` — premium-only "Photo
  backgrounds" switch.
- `assets/content/backgrounds_v1.json` (new manifest, all lists empty for now),
  `assets/images/backgrounds/<cat>/.gitkeep` ×6, `pubspec.yaml` asset entries.
- Tests: `background_manifest_test.dart`, `quote_card_background_test.dart`
  (new); `feed_widget_test.dart` updated (see Decisions).

## Decisions

- **Manifest-as-seam.** Rendering reads only `BackgroundManifest`
  (`pathForQuote(categoryId, id)`). The loader is the only thing that knows the
  source is a bundled JSON; swapping to CDN later touches just that provider.
- **Deterministic image:** `paths[quote.id % paths.length]` — same quote always
  the same picture, no state, no randomness (per requirement 3).
- **Scrim values:** a top→bottom black gradient, `0x40000000` (≈25%) →
  `0x8C000000` (≈55%), as const colors. This guarantees a dark backdrop, so
  on a photo I force the quote/author text to white / white70 and the
  favorite/share icons to a translucent-white treatment — regardless of light or
  dark app theme. The category chip is left as-is (its own surface reads fine on
  the scrim).
- **Graceful fallback, two layers.** (1) If premium-off / toggle-off / the
  category list is empty → render exactly today's gradient. (2) If an image is
  listed but fails to decode, `errorBuilder` swaps in the gradient; the scrim
  still sits on top, so the forced-light text stays readable either way.
- **Premium read-only.** Consumes the existing `isPremiumProvider`; nothing in
  `lib/core/purchases/` was touched.
- **Empty asset folders kept in git** via `.gitkeep`, and the 6 category folders
  are listed in `pubspec.yaml` so images dropped in later are picked up with no
  code change. The manifest currently has all-empty lists (no images yet).
- **Test fix:** `feed_widget_test`'s harness now also overrides `prefsProvider`
  and the manifest value provider, because `QuoteCard` (premium in that test)
  now reads the photo toggle. Behaviour of those tests is unchanged (still
  gradient, since the manifest override is empty).

## Verification

```
$ flutter analyze
No issues found! (ran in 2.6s)

$ flutter test
All tests passed!   (119 tests; 16 new)
```

New tests: manifest parsing (full paths, empty + missing category lists, missing
categories block, the `empty` constant); deterministic selection (same id → same
path, modulo cycling, null for an empty category); QuoteCard shows the photo only
when premium + toggle on + images exist (and forces white text), and stays on the
gradient for free users / toggle off / no images.

Self-correction: fixed on attempt 2. Adding the photo toggle made `QuoteCard`
read `prefsProvider`, which broke `feed_widget_test` (it didn't override prefs) —
added the override. Also corrected one of my own new assertions (`copyWith(color:
null)` keeps the theme colour, it isn't null). No source-logic changes were
needed; analyze/tests green after the fixes.

Manual click-path (open item for Ammar, once images exist):
- [ ] Desktop dev build (premium unlocked) → feed cards show per-category photos,
      text readable.
- [ ] Settings → "Photo backgrounds" off → gradients return.
- [ ] With images absent (current state) → gradients everywhere, no log errors.

## Open items for the owner

- **Manifest is empty — waiting for Pexels images.** Drop files into
  `assets/images/backgrounds/<categoryId>/` and list their filenames in
  `assets/content/backgrounds_v1.json`; no code change needed. Convention:
  `<categoryId>/<categoryId>_NN.webp` (jpg also fine).

## Deviations from prompt

None.
