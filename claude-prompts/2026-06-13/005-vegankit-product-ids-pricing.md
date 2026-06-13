# Rename subscription product IDs to `vegankit_` + re-anchor pricing to $29.99

## Goal
The store products are being renamed and repriced before launch. Rename the three
subscription product IDs from the `veggie_` prefix to `vegankit_`, and update the
setup guide's prices to the new $29.99 anchor. Also fold in the pending display-name
rename in the setup guide (Veggie → VeganKit). After this, the app's trial-reminder
logic points at the new full-price id, and `docs/STORE_SETUP.md` tells Ammar to create
products with the new ids and prices.

New ids and prices (CLAUDE.md §3, updated 2026-06-13):
- `vegankit_yearly_full` — **$29.99** — 7-day free trial (only this one)
- `vegankit_yearly_50` (50% off) — **$14.99**
- `vegankit_yearly_80` (80% off) — **$5.99**

"Done" = `flutter analyze` clean, `flutter test` green, the only product-id strings in
the repo are `vegankit_yearly_*`, and STORE_SETUP.md shows the new ids, the new prices,
and the VeganKit display name.

## Scope
- In:
  - `lib/core/notifications/trial_reminder.dart` (the `trialProductId` constant)
  - `test/trial_reminder_test.dart` (the product-id literals it asserts on)
  - `test/support/paywall_fixtures.dart` (the product-id literal at ~line 16)
  - `docs/STORE_SETUP.md` (ids, prices, display name)
  - `lib/features/paywall/paywall_data.dart` (one stale comment referencing "$49.99 product")
- Out:
  - `lib/core/purchases/purchase_config.dart` — it holds **no** product ids (only the
    `premium` entitlement and the `onboarding`/`default`/`discount` offering ids). Do
    not touch it.
  - The offering ids, entitlement id, base plan `yearly`, and offer ids — unchanged.
  - **Do not change any numeric price values or price assertions in `test/`** (e.g.
    `$49.99`, `$24.99`, `$9.99`, `price: 49.99`). Those are synthetic fixtures that test
    rendering/anchor logic; the app reads real prices from the store at runtime, so they
    do not represent real pricing and must stay as-is to keep tests stable.
  - No app behavior changes, no schema changes, no l10n ARB/codegen changes.

## Requirements
1. **Product id rename (code + tests).** Replace every occurrence of the product-id
   strings with the `vegankit_` prefix, preserving the `_full` / `_50` / `_80` suffixes:
   - `veggie_yearly_full` → `vegankit_yearly_full`
   - `veggie_yearly_50` → `vegankit_yearly_50`
   - `veggie_yearly_80` → `vegankit_yearly_80`
   Apply in: `trial_reminder.dart` (the `trialProductId` constant becomes
   `vegankit_yearly_full`), `trial_reminder_test.dart` (so it still asserts the full id
   schedules the reminder and the `_50`/`_80` ids do not), and `paywall_fixtures.dart`
   (the fixture product identifier).
2. **STORE_SETUP.md — product ids.** Replace all `veggie_yearly_*` with the matching
   `vegankit_yearly_*` (the comparison table, the Apple steps, the Google steps, the
   RevenueCat product-import list, and the offerings table). The Google base plan stays
   exactly `yearly`; the Google free-trial offer id stays `free-trial`.
3. **STORE_SETUP.md — prices.** Update the prices to the new anchor wherever they
   appear (the table and the Apple/Google price steps):
   - $49.99 → **$29.99**
   - $24.99 → **$14.99**
   - $9.99 → **$5.99**
   Keep the 7-day free trial on the full product only. Do **not** change the
   `$99/year` Apple Developer fee or the `$25` Play fee — those are unrelated.
4. **STORE_SETUP.md — display name.** Replace the display/marketing name "Veggie" with
   "VeganKit" everywhere it names the app, the RevenueCat project, the store app entry,
   the subscription group, and reference/display names (e.g. "Veggie Premium" →
   "VeganKit Premium", "Veggie Yearly Full" → "VeganKit Yearly Full"). Do **not** alter
   the lowercase `vegankit_yearly_*` ids while doing this.
5. **Stale comment.** In `paywall_data.dart`, the comment that says the onboarding
   offering "sells the $49.99 product" should read "$29.99 product" to match the new
   anchor. (Comment only — no logic change.)
6. Confirm no `veggie_yearly` string remains anywhere in `lib/`, `test/`, or `docs/`
   (a repo-wide grep for `veggie_yearly` must return nothing).

## Constraints
- Offline-first / Riverpod / drift unaffected — this is ids + docs only.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries, CLAUDE.md §2).
- No `build_runner` / `gen-l10n` needed (no schema or ARB changes).
- Do not widen scope to the test price fixtures (see Scope/Out).

## Verify
- `grep -rn "veggie_yearly" lib/ test/ docs/` → no results.
- `flutter analyze` clean; `flutter test` green (paste the tails in the report).
- Spot-check STORE_SETUP.md: table shows `vegankit_yearly_full` $29.99 (7-day trial),
  `vegankit_yearly_50` $14.99, `vegankit_yearly_80` $5.99, and the app is called VeganKit.

## Commit & push
- Conventional Commit, e.g. `chore(purchases): rename product ids to vegankit_ and re-anchor pricing to $29.99`.
- Body includes `Prompt: claude-prompts/2026-06-13/005-vegankit-product-ids-pricing.md`.
- Push to origin/main; on failure stop and report (never force).

## Report
- Write `claude-reports/2026-06-13/005-vegankit-product-ids-pricing.md` from
  `TEMPLATE.md`. Record the id/price/name changes, the grep result, analyze/test
  tails, commit SHA, push result. Note the open item for Ammar: the products must be
  created in App Store Connect / Play Console with the **new** ids and prices (old
  `veggie_` products, if any were already created, can't be renamed — create fresh
  ones), and the `appl_`/`goog_` keys still need to reach Planning Claude. No full diff.
