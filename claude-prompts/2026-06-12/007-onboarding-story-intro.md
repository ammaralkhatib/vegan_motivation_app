# Onboarding Story — Part 1: Intro + Question Bank

## Goal
Rebuild onboarding from the current 5 skippable screens into the first part of a
story-driven funnel (problem → solution → personal questions → personalized
"bombshell" impact stat → self-persuasion question bank → chart). After this prompt
the app must still be fully usable end-to-end: the new flow saves all answers, then
ends with the existing notifications step, the existing paywall funnel, and `/today`.
Parts 2 (climax) and 3 (conclusion) come in later prompts and will insert more steps.

## Scope
- In: `lib/features/onboarding/**` (restructure `onboarding_flow.dart`; split steps
  into `lib/features/onboarding/steps/*.dart` if that keeps files readable),
  `lib/core/prefs/prefs_repository.dart` (new keys), `test/**`.
- Out: paywall files, router (route stays `/onboarding`), quote feed, settings,
  journey dashboard, notification scheduling logic, `pubspec.yaml` (no new packages).

## Requirements

1. **Replace the 5-step PageView with this ordered step list.** Keep the
   non-scrollable PageView pattern. **Remove all Skip buttons.** Replace the progress
   dots with a slim rounded progress bar at the top (hidden on step 1).
2. **Two step interaction types:**
   - *Tap-to-continue* steps (1, 2, 3, 7, 8, 10, 15): whole screen is the tap target,
     with a subtle "tap to continue →" label bottom-right.
   - *Input* steps: a `FilledButton` "continue" CTA, disabled until a valid
     selection exists (name step may continue with empty input).
3. **New prefs keys** in `PrefsRepository`, following the existing
   `_kKey` + getter-with-default + setter pattern: `ageRange` (String?),
   `dietStatus` (String?), `goalsPick` (List<String>, via `setStringList`),
   `motivationDipsPerWeek` (int, default -1 = unset), `obstacles` (List<String>),
   `whyRelationship` (String?). All answers persist in `_finish()` together with the
   existing keys.
4. **Steps and copy** (use this copy as written; lowercase styling is intentional;
   `{name}` falls back to a name-free phrasing when empty):
   - **S1 Welcome** — leaf icon + "Veggie", line: "your daily dose of vegan
     motivation". Tap to continue.
   - **S2 Problem** — headline: "ever feel your **motivation** fade, even when your
     reasons haven't?" body: "you're not alone. cravings, social pressure, and busy
     days quietly pull people away from the path they chose." Bolded word uses the
     theme primary color.
   - **S3 Solution** — headline: "veggie keeps your **why** in front of you" body:
     "it's simple — every day, a small spark of motivation, made for you."
   - **S4 Name** — eyebrow: "first things first", headline: "what should we call
     you?", text field (hint "your name", words auto-capitalized). Saves `userName`.
   - **S5 Age** — "how old are you?" single-select cards: 14–24 / 25–34 / 35–44 /
     45–54 / 55+. Saves `ageRange` (store the label string).
   - **S6 Diet status** — "where are you on the path right now?" single-select:
     "🌱 i'm vegan" (`vegan`), "🥦 mostly plant-based" (`mostly`), "🍃 cutting down"
     (`cutting_down`), "👀 just curious" (`curious`). Saves `dietStatus`.
   - **S7 Bombshell** — lines fade in one by one (~500 ms apart), numbers count up
     (TweenAnimationBuilder, like `ImpactCounter`), highlights in primary color.
     Math uses `ImpactEstimates` constants
     (`lib/data/impact_estimates.dart`): `yearsLeft = max(5, 80 − ageMidpoint)`
     where ageMidpoint = 19/30/40/50/60 per range.
     - *Positive framing* (`vegan`/`mostly`): "{name}, by staying on this path
       you'll save ~**{animals}** animals" / "that's **{co2} tonnes** of CO₂" /
       "and **{water}** litres of water over your lifetime..." / "what could matter
       more than protecting that?"
     - *Negative framing* (`cutting_down`/`curious`): "{name}, the average diet
       takes ~**{animalsPerYear}** animal lives every year" / "that's
       ~**{animalsLifetime}** animals over a lifetime" / "and **{co2} tonnes** of
       CO₂..." / "how many of them could you spare?"
     Format large numbers compactly (reuse/adapt the `_compact()` approach).
   - **S8 Bridge** — "it doesn't have to be this way" / "do you have just
     **2 minutes** a day?" / "let's build a plan for **you**". Tap to continue.
   - **S9 Goals** (multi-select, max 3, "choose up to 3") — "what do you want from
     veggie?" options: "🔥 stay motivated every day" (`daily_motivation`),
     "🌱 build habits that stick" (`habits`), "💪 stay strong in social situations"
     (`social_strength`), "❤️ reconnect with my why" (`reconnect_why`),
     "🤝 feel less alone on this path" (`less_alone`). Saves `goalsPick`.
   - **S10 Goals reflection** — mirrors each picked goal back as a card with its
     line: daily_motivation → "a fresh spark every morning — your feed and reminders
     will keep the fire lit." / habits → "gentle streaks and small wins, so good days
     turn into a way of life." / social_strength → "the right words for the hard
     moments — awkward dinner questions included." / reconnect_why → "we'll keep
     your reason close, especially on the days it feels far." / less_alone →
     "you're part of something bigger — we'll remind you of the good you do."
     Footer block: "**you're in the right place**" + "every journey here starts with
     the same goals — veggie was built for exactly this." Do **not** invent user
     counts or testimonials.
   - **S11 Dips slider** — "be honest — how many days a week does your motivation
     dip?" slider 0–7, big live number. Saves `motivationDipsPerWeek`.
   - **S12 Obstacles** (multi-select, max 3) — "what gets in the way most?"
     options: "🍕 cravings & convenience" (`cravings`), "🥂 social pressure"
     (`social_pressure`), "😮‍💨 motivation fades over time" (`fading_motivation`),
     "🧍 nobody around me gets it" (`alone`), "⏰ busy life, no headspace"
     (`busyness`). Saves `obstacles`.
   - **S13 Relationship with the why** — "and how's your connection to your why
     right now?" single-select: "📈 it has its ups and downs" (`ups_downs`),
     "🍂 fading a bit lately" (`fading`), "🌱 just starting or rebuilding"
     (`starting`), "💪 strong and steady" (`strong`). Saves `whyRelationship`.
   - **S14 Journey date** — only shown when `dietStatus` is `vegan` or `mostly`:
     "when did your journey start?" with the existing date picker plus a "today"
     quick option → `journeyProvider.setVeganSince(...)`. For `cutting_down` /
     `curious` this step is skipped automatically and `journeyProvider.setCurious()`
     is applied in `_finish()`.
   - **S15 Final reflection** — lines fade in one by one, built from saved answers
     with fallbacks when something wasn't answered: "you want {first goal, in plain
     words}" / "but {first obstacle, in plain words} keeps getting in the way" /
     "your motivation dips {n} days a week" / "veggie was made for exactly this
     moment."
   - **S16 Motivation pick** — eyebrow: "last one — to make the quotes feel right
     for you", headline: "what moves you most?" Keep the existing 4 options and
     values exactly (`animals`, `planet`, `health`, `curious`) →
     `setMotivationPick`.
   - **S17 Chart** — headline: "your motivation, with and without a daily spark".
     A simple `CustomPaint` with two curves (rising "with veggie" in primary color,
     sagging "on willpower alone" in muted grey), small labels, caption: "small daily
     reminders beat willpower. that's the whole idea." No chart package.
   - **S18 Notifications (temporary tail)** — keep the existing notifications step
     (toggle + per-day slider, permission requested only on opt-in) as the final
     step, **but remove the theme picker** (it already lives in settings). CTA
     "start my journey" → existing `_finish()` behavior: save everything,
     `runOnboardingPaywallFunnel(context, ref)`, then `context.go('/today')`.
5. **Animations** must respect `MediaQuery.disableAnimations` (show content
   immediately, no fades/count-ups), matching the `AnimatedCritter` precedent.
6. **Tests:** update/extend widget tests so the full flow can be driven to
   completion (selecting answers) and asserts the new prefs keys are persisted, and
   that S14 is skipped for `curious`. Keep existing tests green.

## Constraints
- Locked decisions hold (CLAUDE.md §3): offline-first, Riverpod/drift/go_router,
  no new packages, no backend/analytics.
- Don't change paywall behavior or the funnel — it is already wired and dismissible.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries,
  CLAUDE.md §2).

## Verify
- `flutter analyze && flutter test`
- Manual: fresh install path (clear prefs) → walk all 18 steps → bombshell shows
  positive copy for "i'm vegan", negative for "just curious" → finish → trial
  paywall → close → 80% paywall → close → lands on `/today`.

## Commit & push
- Conventional Commit, e.g. `feat(onboarding): story-driven intro + question bank`;
  body includes `Prompt: claude-prompts/2026-06-12/007-onboarding-story-intro.md`.
- Push to origin/main; on failure stop and report (never force). No remote yet is
  expected — note it.

## Report
- Write `claude-reports/2026-06-12/007-onboarding-story-intro.md` from TEMPLATE.md
  (mkdir -p). Record intent, decisions, verification results, commit SHA, push
  result, open items. No full diff.
