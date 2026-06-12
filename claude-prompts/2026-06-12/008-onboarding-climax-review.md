# Onboarding Story — Part 2: Climax (first quote, day-1 streak, review prompt)

## Goal
Insert the emotional peak into the onboarding built in prompt 007: the user sees
their first personalized quote (the core feature, live), gets a "day 1" streak
celebration with confetti, and the OS review prompt fires at exactly that peak.
Done = three new steps appear between the chart step (S17) and the notifications
step, and the review prompt is requested once, at the streak moment only.

## Scope
- In: `lib/features/onboarding/**`, `lib/core/prefs/prefs_repository.dart` (one new
  key), `pubspec.yaml` (add `in_app_review`), `test/**`.
- Out: paywall files, quote feed/DAO changes, router, settings, notifications
  scheduling.

## Requirements

1. **S18 First spark** (insert after the chart step) — eyebrow: "built from your
   answers", headline: "here's your first spark{name → ', {name}'}". Below it, a
   real quote card:
   - Map `motivationPick` → category: `animals` → `why_vegan`, `planet` → `facts`,
     `health` → `quick_tips`, `curious`/unset → `why_vegan`.
   - Fetch one quote from that category via the existing Drift plumbing
     (`watchQuotesByCategory(categoryId)` in
     `lib/core/db/daos/quote_dao.dart`); pick deterministically (e.g. first by id).
   - Render with the existing `QuoteCard` (`lib/features/quotes/quote_card.dart`,
     constructor `QuoteCard({required int quoteId, onShare})`) with `onShare: null`.
     If `QuoteCard` drags in feed-only behavior that misbehaves here, build a
     minimal read-only variant in onboarding instead — do not modify `QuoteCard`.
   - Footer: "your quotes are saved for you — to keep your why strong." CTA
     "continue".
   - Note: this single quote may come from a premium category — that's intentional
     (a taste), and it does not unlock anything.
2. **S19 Day-1 streak** — big "day 1" with a 🌱/flame mark and a short confetti
   burst (package `confetti` is already a dependency; see usage in
   `lib/features/paywall/paywall_screen.dart`). Copy: headline "your streak starts
   today" body: "come back tomorrow to keep it alive — your next spark will be
   waiting." CTA "continue". Respect `MediaQuery.disableAnimations` (no confetti).
3. **S20 Review prompt** — fired on the streak step, ~1.2 s after it becomes
   visible (the emotional peak), via the `in_app_review` plugin:
   - Add `in_app_review` to `pubspec.yaml` (latest stable).
   - Call `InAppReview.instance.requestReview()` guarded by
     `isAvailable()`, wrapped in try/catch (the OS may silently skip it — fine).
   - New prefs key `reviewPromptShown` (bool, default false), set true before
     requesting so it can never fire twice. No separate screen — it overlays S19.
4. **Step order after this prompt:** S1–S17 (from 007) → S18 first spark → S19
   streak (+review) → notifications tail step → `_finish()` (unchanged: funnel +
   `/today`).
5. **Tests:** unit-test the motivation→category mapping; widget test that the flow
   still completes and `reviewPromptShown` is persisted (inject/fake the review
   call — don't invoke the real plugin in tests).

## Constraints
- Locked decisions hold (CLAUDE.md §3): offline-first (quote comes from the local
  DB), Riverpod/drift/go_router. `in_app_review` is the only new package.
- Don't change paywall behavior or quote feed behavior.
- `flutter analyze` clean; `flutter test` green (self-correct up to 2 tries,
  CLAUDE.md §2).

## Verify
- `flutter analyze && flutter test`
- Manual: fresh onboarding run → after the chart, a real quote renders matching the
  chosen motivation → streak screen shows confetti → (on a real device) review
  sheet may appear → flow finishes to paywall funnel → `/today`.

## Commit & push
- Conventional Commit, e.g. `feat(onboarding): climax — first quote, day-1 streak,
  review prompt`; body includes
  `Prompt: claude-prompts/2026-06-12/008-onboarding-climax-review.md`.
- Push to origin/main; on failure stop and report (never force). No remote yet is
  expected — note it.

## Report
- Write `claude-reports/2026-06-12/008-onboarding-climax-review.md` from
  TEMPLATE.md (mkdir -p). Record intent, decisions, verification results, commit
  SHA, push result, open items. No full diff.
