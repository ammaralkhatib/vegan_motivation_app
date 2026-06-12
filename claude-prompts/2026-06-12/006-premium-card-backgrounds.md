# Premium photo backgrounds on quote feed cards (v1, bundled assets)

## Goal
Premium users see a full-bleed photo background behind each quote card in the
feed, themed per category. Free users see no change (current gradient). Images
are bundled assets listed in a small versioned JSON manifest, so a future move
to CDN-hosted packs only swaps the manifest source — rendering code stays the
same. "Done" = a premium user swipes the feed and sees per-category photos with
fully readable text; a free user sees today's gradient; a settings switch lets
premium users turn photos off.

Note: image files may not exist yet (Ammar is still curating them on Pexels).
Build everything so the feature degrades to the current gradient when a
category has no images — the code must ship and run correctly with zero images
present.

## Scope
- In:
  - `lib/features/quotes/quote_card.dart` (background rendering only)
  - new `lib/core/backgrounds/` (manifest model + loader + providers)
  - `lib/core/prefs/prefs_repository.dart` (one new toggle pref)
  - settings screen under `lib/features/settings/` (one new switch row)
  - `assets/content/backgrounds_v1.json` (new manifest)
  - `pubspec.yaml` (asset folder entries)
  - tests under `test/`
- Out:
  - purchase/paywall code (`lib/core/purchases/` is read-only — consume the
    existing premium state provider, change nothing there)
  - explore screens, share-as-image rendering, widgets
  - Drift schema / DAOs / content importer (no DB changes, no build_runner)

## Requirements
1. **Asset layout + manifest.** Convention:
   `assets/images/backgrounds/<categoryId>/<categoryId>_NN.webp` (jpg also
   acceptable) for the 6 category ids (`why_vegan`, `quick_tips`,
   `youre_awesome`, `facts`, `staying_strong`, `milestones`). Create
   `assets/content/backgrounds_v1.json`:
   ```json
   {
     "version": 1,
     "categories": {
       "why_vegan": ["why_vegan_01.webp"],
       "quick_tips": []
     }
   }
   ```
   Populate each list from whatever image files actually exist in those folders
   right now (likely none — then all lists are empty, which is valid). Add the
   backgrounds folders and the manifest to `pubspec.yaml` assets. If the image
   directories don't exist, create them with a `.gitkeep` so the structure is
   in git.
2. **Loader.** In `lib/core/backgrounds/`: parse the manifest once (rootBundle),
   expose it via a Riverpod provider following existing provider patterns.
   Public API: full asset paths per category, e.g.
   `List<String> pathsForCategory(String categoryId)`.
3. **Deterministic selection.** A given quote always gets the same image:
   `paths[quote.id % paths.length]`. No randomness, no state.
4. **QuoteCard rendering.** When (premium && photo toggle on && selected
   category list non-empty): render a `Stack` — bottom: `Image.asset` full-bleed
   `BoxFit.cover`; middle: scrim gradient (black overlay, stronger toward
   bottom, roughly 25% top → 55% bottom opacity) so quote text passes contrast
   in both light and dark theme; top: the existing card content unchanged
   (text, author, critter, favorite/share buttons). In all other cases render
   exactly today's gradient — zero visual change for free users.
   Use `errorBuilder` on the image to fall back to the gradient if an asset
   fails to load. When a photo background is shown, force the quote/author text
   and icon colors to a light-on-dark scheme regardless of app theme (the scrim
   guarantees a dark backdrop).
5. **Premium gating.** Read the existing cached premium state provider from
   `lib/core/purchases/`. Do not add any new entitlement logic.
6. **Settings toggle.** New switch "Photo backgrounds" in settings, visible only
   when premium, default ON, persisted via `PrefsRepository`
   (`shared_preferences`), exposed through a provider consistent with existing
   prefs providers.
7. **Tests.** (a) manifest parsing incl. empty/missing category lists,
   (b) deterministic selection (same id → same path; empty list → no image),
   (c) QuoteCard shows gradient when toggle off / not premium / no images.
   Follow existing widget-test patterns for provider overrides.

## Constraints
- Offline-first (locked): assets bundled, no network calls, no new packages.
- Riverpod / drift / go_router stay as-is (locked); no Drift changes, so no
  build_runner run needed.
- Do not modify anything in `lib/core/purchases/`.
- `flutter analyze` clean; `flutter test` green — self-correct up to 2 attempts
  (CLAUDE.md §2), otherwise commit nothing and report `blocked`.

## Verify
- `flutter analyze`
- `flutter test`
- Manual (Ammar, later): on a desktop dev build (premium treated as unlocked),
  feed cards show photos once images exist; settings toggle off → gradients;
  with images absent (current state) → gradients everywhere, no errors in log.

## Commit & push
- Conventional Commit, e.g. `feat(quotes): premium photo backgrounds on feed cards`;
  body includes `Prompt: claude-prompts/2026-06-12/006-premium-card-backgrounds.md`.
- Push to `origin/main`; on failure (or no remote yet) stop and record in the
  report — never force.

## Report
- Write `claude-reports/2026-06-12/006-premium-card-backgrounds.md` from
  `claude-reports/TEMPLATE.md` (`mkdir -p` the folder). Record intent, decisions
  (esp. scrim values and text-color handling), verification output, commit SHA,
  push result, open items (e.g. "manifest empty — waiting for Pexels images").
  No full diff.
