# Critter art v2: head-only frames + breathing animation (replaces bob)

## Goal

Swap the full-body critter art for the new approved head-only versions (face-
emoji style), and change the idle motion from up-down bobbing to a gentle
scale "breathing". No behavior changes otherwise — blink and tap-happy-wiggle
stay. "Done" = the feed shows the new heads breathing, blinking, and wiggling
on tap; all tests green.

## Scope

- In: `assets/critters/` (replace the 18 PNGs, same filenames),
  `lib/core/critters/animated_critter.dart` (animation change only),
  affected tests under `test/`.
- Out: everything else. Do not touch `quote_card.dart` (filenames and widget
  API are unchanged), feed logic, notifications, paywall, pubspec (asset dir
  already registered).

## Requirements

1. **Replace the 18 assets** in `assets/critters/`, keeping the exact same
   filenames (`<animal>_<frame>.png`). Source URLs (transparent PNGs,
   2048×2048), prefix
   `https://d8j0ntlcm91z4.cloudfront.net/user_3EG5pBhqcAcQxHpM3yL8XPvtR0A/`:

   | File | URL suffix |
   |---|---|
   | cow_base.png | hf_20260612_202156_160b9629-89a0-40e1-857e-7eeec9bd8dfa.png |
   | cow_blink.png | hf_20260612_202158_f536e13e-3565-4e75-83ac-73bfb47eeae5.png |
   | cow_happy.png | hf_20260612_202159_d36bf753-0013-4c7b-8653-7c71c1957f66.png |
   | pig_base.png | hf_20260612_202200_4b5ad22c-457c-49ff-b10b-aa806a8339f9.png |
   | pig_blink.png | hf_20260612_202202_c73eec81-4055-475a-a4d9-5525b2108842.png |
   | pig_happy.png | hf_20260612_202204_9e9a5155-ccd4-4f85-8f8a-38a313b9c5ac.png |
   | sheep_base.png | hf_20260612_202206_4ba32260-5f5e-40cf-8de6-dc5142aa5465.png |
   | sheep_blink.png | hf_20260612_202207_e23c9691-52e8-4656-a04e-601126c5e96c.png |
   | sheep_happy.png | hf_20260612_202302_aa29c51e-6f4e-4480-99cc-cc6a0d600438.png |
   | chicken_base.png | hf_20260612_202303_912b8884-01c4-4521-8fe4-1d21fb800a3d.png |
   | chicken_blink.png | hf_20260612_202305_9937ff7c-898b-4cfb-9462-39f4eb61bb76.png |
   | chicken_happy.png | hf_20260612_202306_606b690c-deba-4909-aab6-a9fa8ebf339b.png |
   | duck_base.png | hf_20260612_202308_324472fe-a446-48fe-960c-98e639d61941.png |
   | duck_blink.png | hf_20260612_202310_719f3cbc-5328-45ee-9e3d-fb9e2213e028.png |
   | duck_happy.png | hf_20260612_202311_d8a0625a-c4b9-4017-bd4d-a8c3baf2a8a4.png |
   | goat_base.png | hf_20260612_202313_d55515c5-50d6-45d9-a772-2f18c6583be5.png |
   | goat_blink.png | hf_20260612_202408_e16553b1-d84b-4a5d-86de-4d3732807ae1.png |
   | goat_happy.png | hf_20260612_202410_ab6677f7-e103-443a-be1b-51d66ad55ff9.png |

2. **Downscale each to 512×512** (keep transparency, `sips -Z 512` on macOS);
   each file well under 300 KB.
3. **Animation change in `AnimatedCritter`:** remove the up-down bob
   (`Transform.translate` driven by the bob controller). Replace with a gentle
   breathing scale: `scale = 1 + 0.04 * sin(...)`, same ~2.8 s period, driven
   by the same repeating controller (rename internals if it keeps the code
   honest, e.g. `_bob` → `_breathe`). Blink frame-swap and tap-happy decaying
   wiggle (rotation ±8°, extra scale bump ≤1.05) stay exactly as they are.
   Reduced-motion / `animate: false` behavior unchanged (static base frame).
4. **Tests:** update any test that asserts the translate-based bob; add/keep a
   check that idle animation scales rather than translates (e.g. the widget
   tree contains the scale transform when animating). All existing tests stay
   green.

## Constraints

- Locked decisions hold (CLAUDE.md §3). No new packages.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries
  per CLAUDE.md §2).
- Public API of `AnimatedCritter` and the `Critter` enum unchanged.

## Verify

- `flutter analyze`
- `flutter test`
- Manual (open item for Ammar): run the app — heads (not bodies) on the feed,
  breathing gently in place (no vertical movement), blinking, happy wiggle on
  tap.

## Commit & push

- Conventional Commit, e.g. `feat(critters): head-only art v2 + breathing idle animation`;
  body includes `Prompt: claude-prompts/2026-06-12/003-critter-heads-v2.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report

- Write `claude-reports/2026-06-12/003-critter-heads-v2.md` from
  `claude-reports/TEMPLATE.md`. Record intent, decisions, verification
  results, final asset sizes, commit SHA, push result, open items. No full
  diff.
