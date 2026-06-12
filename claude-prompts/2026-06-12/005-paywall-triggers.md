# Wire the paywall triggers

## Goal
Connect the paywalls to the app so real users meet them (CLAUDE.md §3): end of
onboarding → trial paywall; dismissing it without buying → the 80% "last
chance" paywall, exactly once ever; tapping locked content → the 50% paywall
(replacing the placeholder sheet); and a "Restore purchases" row in Settings.
"Done" = the full funnel works for a new free user, a premium user never sees
a paywall, and the one-time 80% offer can never appear twice.

## Scope
- In: `lib/features/onboarding/onboarding_flow.dart`,
  `lib/core/purchases/premium_gate.dart`, `lib/core/prefs/prefs_repository.dart`
  (one new flag), `lib/features/settings/settings_screen.dart`,
  `lib/features/paywall/` (only if a small hook is needed), `test/`.
- Out: paywall visual design (done in 004), gating rules (done in 003), quote
  feed, habits, notifications, widgets. No new packages, no schema changes.

## Requirements
1. **Onboarding trigger.** When the user finishes the last onboarding slide
   (where `context.go('/today')` runs today): if not premium, first show the
   `onboarding` (trial) paywall full-screen, then land on `/today` afterwards.
   Premium users (e.g. restored earlier) skip straight to `/today`. Onboarding
   completion (`onboardingDone`) is still set regardless — closing the paywall
   must never dump the user back into onboarding.
2. **One-time 80% offer.** Add a `discountOfferShown` bool to
   `PrefsRepository` (default false, same pattern as existing flags). When the
   onboarding paywall closes and the user is still not premium and the flag is
   false: set the flag (before showing, so even a crash can't repeat it), then
   show the `discount` paywall. It must never show again afterwards — not on
   restart, not from any other path. If the user became premium on the trial
   paywall, skip it and leave the flag false (nothing was offered).
3. **Locked content → 50% paywall.** Replace the body of `showPremiumSheet` in
   `premium_gate.dart` with a call to `showPaywall(context,
   PaywallVariant.defaultOffer)` (resolve the `TODO(004)` comment; rename the
   function if that reads cleaner — update call sites and tests).
4. **Restore in Settings.** Below the "Veggie Premium" row add "Restore
   purchases" (visible only when not premium, like the premium row). It calls
   `restorePurchases()` with the same outcome handling as the paywall's
   restore button ("Welcome back!" / "No previous purchase found." /
   not-charged-style error). Reuse the paywall's restore logic — extract a
   small shared helper rather than copy-pasting it.
5. **Router redirect check.** Verify the `/onboarding` ↔ `/today` redirect in
   `lib/app/router.dart` can't fight with the paywall route while onboarding
   finishes (e.g. paywall pushed before `onboardingDone` is set). Sequence the
   flag-write and navigation so the funnel is deterministic; adjust the
   redirect only if actually needed.
6. **Tests:** (a) finishing onboarding as free user shows the trial paywall,
   then (still free) the discount paywall, then `/today`; (b) the discount
   paywall does NOT appear on a second pass / restart (flag persisted);
   (c) premium user finishing onboarding sees no paywalls; (d) locked category
   tap now opens the `defaultOffer` paywall (update the 003 sheet tests);
   (e) Settings restore row: hidden for premium, outcome SnackBars for free.
   Use `FakePurchaseService` throughout.

## Constraints
- Locked decisions hold (CLAUDE.md §3): offline-first — if the paywall can't
  load offers at the end of onboarding, the existing retry/close state from
  004 shows and closing continues to `/today` normally; the funnel never
  traps the user. Riverpod/drift/go_router; no new packages.
- The 80% offer is once **ever** (prefs-persisted), not once per session.
- Never show any paywall to a premium user.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries,
  CLAUDE.md §2).

## Verify
- `flutter analyze`, `flutter test`.
- Manual click-path (note in report for Ammar): fresh install (or cleared app
  data) → finish onboarding → trial paywall appears → close it → 80% paywall
  appears → close it → lands on Today. Restart the app → no paywall on
  launch. Explore → tap a locked category → 50% paywall. Settings → Restore
  purchases shows the "no previous purchase" message (with placeholder keys,
  the offer screens show the friendly retry state — still fine to close).

## Commit & push
- Conventional Commit, e.g. `feat(paywall): wire onboarding/discount/locked-content triggers`.
- Body includes `Prompt: claude-prompts/2026-06-12/005-paywall-triggers.md`.
- Push to origin/main; on failure stop and report (never force).

## Report
- Write `claude-reports/2026-06-12/005-paywall-triggers.md` from TEMPLATE.md.
  Record intent, decisions (especially the onboarding → paywall → today
  sequencing and the once-ever flag), verification results, commit SHA, push
  result, open items.
