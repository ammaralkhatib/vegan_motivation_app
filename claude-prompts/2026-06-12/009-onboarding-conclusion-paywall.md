# Onboarding Story — Part 3: Conclusion + paywall polish

## Goal
Close the onboarding story built in prompts 007–008: fake-loading transition,
personalized 30-day plan summary, commitment screens (Cialdini), motivation
snapshot, reframed notifications step, honest social-proof screen, then the
existing (dismissible) paywall funnel. Also two paywall polish items: a 2-second
delayed close button on the onboarding/discount paywalls, and a local notification
one day before the free trial ends. Done = the full 27-step story runs start to
finish and the trial reminder is scheduled on a successful trial purchase.

## Scope
- In: `lib/features/onboarding/**`, `lib/core/prefs/prefs_repository.dart` (one new
  key), `lib/features/paywall/paywall_screen.dart` (close-button delay only),
  `lib/core/notifications/**` + the purchase success path (trial reminder),
  `test/**`.
- Out: `pubspec.yaml`, router, quote feed, journey dashboard, RevenueCat config
  (`purchase_config.dart`), funnel order in `onboarding_paywall_funnel.dart`.

## Requirements

1. **S21 Loading** (insert after the streak step) — circular progress with a
   percentage counting to 100% over ~3.5 s and three checklist lines appearing in
   sequence: "reading your answers ✓" / "shaping your daily mix ✓" / "building your
   plan ✓". Caption: "building your motivation plan...". Auto-advances when done.
   With `MediaQuery.disableAnimations`, skip straight through.
2. **S22 Plan summary** — headline: "{name}, you'll have an unshakable habit by
   **{date}**" where date = today + 30 days, formatted with `intl` (already a
   dependency); name-free fallback: "your unshakable habit arrives by {date}".
   Three small chips: "daily spark" / "streaks that stick" / "impact you can see".
   Then "how we'll get you there:" with two cards:
   - "a personal spark, daily — no more hunting for motivation. quotes picked for
     your why, every morning."
   - "proof of the good you do — watch your animal, CO₂ and water impact grow, day
     by day."
   CTA: "begin my journey".
3. **S23 Commitment question** — "how committed are you to making this future
   happen?" single-select: "🔥 extremely committed" (`extreme`), "💪 very committed"
   (`very`), "🙂 somewhat committed" (`somewhat`), "🌱 a little committed"
   (`little`), "👀 just trying it out" (`trying`). New prefs key `commitmentLevel`
   (String?), saved in `_finish()`.
4. **S24 Commitment response** — full-color (primaryContainer) screen with copy
   tailored to the answer:
   - `extreme`: "you're all-in — that's where change lives. let's turn that fire
     into a habit."
   - `very`: "strong start. commitment like this is what carries people through the
     hard weeks."
   - `somewhat`: "honest — and that's enough. small daily sparks will do the heavy
     lifting."
   - `little`: "every big change starts a little unsure. we'll keep it light and
     easy — just show up."
   - `trying`: "perfect — no pressure. try it for a few days and let the streak
     speak for itself."
   CTA: "done ✓".
5. **S25 Snapshot** — "✨ your motivation snapshot" with small cards built from
   saved answers (sensible fallbacks when unset):
   - "current motivation" — low→high bar positioned from `whyRelationship`
     (`fading`=low, `ups_downs`/`starting`=mid, `strong`=high).
   - "weekly dips" — "{motivationDipsPerWeek} days/week".
   - "commitment level" — bar filled by level (`extreme`=100% … `trying`=20%).
   - "strengths" — one line from their first goal pick.
   CTA: "continue".
6. **S26 Notifications (reframed, replaces the temporary tail step)** — eyebrow:
   "this is how your plan reaches you", headline: "daily sparks?". Keep the existing
   toggle + 1–10 per-day slider and opt-in-only permission request. CTA "continue".
7. **S27 Social proof — honest version** — headline: "veggie was made for people
   like you". Factual stat chips only: "508 hand-picked quotes" / "6 cheering
   critters" / "impact tracking built in". One line: "no accounts. no ads. your
   journey stays on your phone." **Do not invent download counts, star ratings, or
   fake reviews** — the app has no published ratings yet. CTA: "join veggie 🌱" →
   `_finish()` (unchanged: save, `runOnboardingPaywallFunnel`, `/today`).
8. **Paywall close delay** — in `paywall_screen.dart`, for the `onboarding` and
   `discount` variants only, fade the close button in after 2 s (so the offer is
   seen, not reflex-dismissed). `defaultOffer` keeps an immediate close. Respect
   `MediaQuery.disableAnimations` (show immediately).
9. **Trial-end reminder** — when a purchase of the trial product
   (`veggie_yearly_full`) succeeds, schedule a local notification **6 days later**
   (trial is 7 days): title "your free trial ends tomorrow", body "you won't be
   charged until then — cancel anytime in your store settings, or do nothing to
   keep your sparks coming." Use the existing `flutter_local_notifications`
   plumbing in `lib/core/notifications/` with a dedicated reserved notification id
   so it never collides with daily quote notifications. Schedule only for the trial
   product, not the 50%/80% products. If notification permission is denied,
   skip silently.
10. **Final step order:** S1–S17 (007) → S18–S19 (008) → S21 loading → S22 plan →
    S23 commitment → S24 response → S25 snapshot → S26 notifications → S27 social
    proof → funnel → `/today`.
11. **Tests:** widget test driving the conclusion steps to completion asserting
    `commitmentLevel` persists; unit test for the trial-reminder scheduling
    decision (trial product → scheduled, discount products → not). Fake the
    notifications plugin; don't fire real ones in tests.

## Constraints
- Locked decisions hold (CLAUDE.md §3): offline-first, RevenueCat is the only
  network exception, yearly-only products, discount framing rule (anchor price only
  ever the real $49.99), Riverpod/drift/go_router, no new packages.
- Do not reorder or change the funnel logic in `onboarding_paywall_funnel.dart`
  (trial → discount-once → `/today` stays as is).
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries,
  CLAUDE.md §2).

## Verify
- `flutter analyze && flutter test`
- Manual: fresh onboarding run end-to-end → loading → plan shows date +30 days →
  pick "just trying it out" → tailored copy shows → snapshot reflects answers →
  notifications opt-in → social proof → trial paywall (close appears after ~2 s) →
  close → 80% paywall → close → `/today`. Trial purchase can only be verified after
  Ammar finishes RevenueCat dashboard setup — note as an open item.

## Commit & push
- Conventional Commit, e.g. `feat(onboarding): conclusion screens + paywall polish
  + trial reminder`; body includes
  `Prompt: claude-prompts/2026-06-12/009-onboarding-conclusion-paywall.md`.
- Push to origin/main; on failure stop and report (never force). No remote yet is
  expected — note it.

## Report
- Write `claude-reports/2026-06-12/009-onboarding-conclusion-paywall.md` from
  TEMPLATE.md (mkdir -p). Record intent, decisions, verification results, commit
  SHA, push result, open items. No full diff.
