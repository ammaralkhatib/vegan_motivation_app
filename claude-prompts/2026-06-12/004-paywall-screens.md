# Paywall screens — one design, three variants

## Goal
Build the paywall UI: one reusable screen with three variants mapped to the
three RevenueCat offerings (CLAUDE.md §3) — `onboarding` (7-day free trial),
`default` (50% off), `discount` (80% off, "last chance"). "Done" = each
variant renders with real store prices, can run a purchase end-to-end through
`PurchaseService`, handles cancel/error/offline gracefully, and is reachable
from Settings for manual testing. Triggers (onboarding flow, locked-content
hook, one-time discount logic) are NOT in this prompt — that's 005.

## Scope
- In: new `lib/features/paywall/` feature, router registration in `lib/app/`,
  one new row in `lib/features/settings/settings_screen.dart`, `test/`.
- Out: onboarding flow, `premium_gate.dart`'s sheet (replaced in 005), quote
  feed, habits, notification/widget code. No new packages.

## Requirements
1. **Display model first, SDK second.** Create a small `PaywallData` model
   (title, price string, optional anchor-price string, optional trial text,
   badge text, package-to-buy) plus a mapper that builds it from RevenueCat
   `Offering` objects. The screen renders only `PaywallData`, so widget tests
   construct it directly and never need real SDK types (the 002 report showed
   RevenueCat types are painful to fake).
2. **Variants** (enum `PaywallVariant { onboarding, defaultOffer, discount }`),
   each loading its offering id from `PurchaseConfig`:
   - `onboarding`: headline about starting the journey, "7 days free, then
     <price>/year" — CTA "Start free trial". Trial wording must come from the
     package's actual intro/trial data when available; if the product has no
     trial configured, fall back to plain "<price>/year" (never promise a
     trial the store won't give).
   - `defaultOffer`: "50% OFF" badge, anchor price crossed out next to the
     real price, CTA "Unlock Veggie Premium".
   - `discount`: "80% OFF — one-time offer" badge, anchor crossed out, urgency
     copy ("This offer won't come back"), CTA "Claim my offer".
3. **Anchor price is never invented** (CLAUDE.md §3). For the discount
   variants, fetch the full-price product's real `priceString` (via the
   `onboarding` offering's package) and show that crossed out. If it can't be
   fetched, hide the crossed-out anchor and the "% OFF" badge — show only the
   real price.
4. **Shared layout**, themed like the rest of the app (Fraunces headings,
   existing color scheme): leaf/app icon, headline, 3–4 benefit bullets (all 6
   quote categories, full 508-quote library, support the mission, everything
   stays on your device), price block, big CTA, "Restore purchases" text
   button, small footnote "Cancel anytime in your store settings". Close (X)
   button top corner — closing just pops; 005 adds variant-specific close
   behavior.
5. **Purchase flow:** CTA → `purchase(package)`; success → confetti (package
   already in app) + auto-close; cancelled → stay open, no message; error →
   SnackBar "Something went wrong — you were not charged." Restore →
   `restorePurchases()`; if premium after restore, close with a "Welcome
   back!" SnackBar, else "No previous purchase found."
6. **Loading/offline state:** while the offering loads show a spinner; if
   `getOffering` returns null (offline, placeholder keys, missing dashboard
   setup) show a friendly "Can't load offers right now — check your
   connection" with a Retry button and the close button still working. Never
   block the user in.
7. **Routing:** register a go_router route (e.g. `/paywall/:variant`) pushed
   as a full-screen page. Helper `showPaywall(context, PaywallVariant)` lives
   in the paywall feature for 005 to reuse.
8. **Settings entry:** in Settings add a "Veggie Premium" row that opens the
   `defaultOffer` paywall; hide the row when the user is already premium.
   (Doubles as the manual test path until 005 wires the real triggers.)
9. **Tests:** widget tests rendering each variant from a hand-built
   `PaywallData` (badge/anchor/trial text shown or hidden correctly); purchase
   success/cancel/error paths via `FakePurchaseService` (extend the fake to
   script `getOffering`/`purchase` outcomes as needed — keep fakes for
   RevenueCat types minimal, the `PaywallData` seam should make heavy faking
   unnecessary); offering-null shows the retry state; Settings row hidden for
   premium users.

## Constraints
- Locked decisions hold (CLAUDE.md §3): Riverpod/drift/go_router, no new
  packages, offline-first — a failed offering load degrades politely, never
  crashes, never blocks closing.
- All user-facing prices/trial text come from the store via RevenueCat
  (`priceString` etc.). The only hard-coded strings are copy, never amounts.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries,
  CLAUDE.md §2).

## Verify
- `flutter analyze`, `flutter test`.
- Manual click-path (note in report for Ammar): Settings → Veggie Premium →
  paywall opens; with placeholder API keys expect the friendly offline state,
  Retry and X both work.

## Commit & push
- Conventional Commit, e.g. `feat(paywall): paywall screen with trial/50/80 variants`.
- Body includes `Prompt: claude-prompts/2026-06-12/004-paywall-screens.md`.
- Push to origin/main; on failure stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/004-paywall-screens.md` from TEMPLATE.md.
  Record intent, decisions (especially the PaywallData seam and anchor-price
  sourcing), verification results, commit SHA, push result, open items.
