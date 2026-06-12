# Veggie (vegan_motivation_app) — Working Notes for Claude

Shared brief between **Ammar** (owner), the **Planning Claude in Cowork**
(designs prompts, verifies results — never edits source), and **Claude Code in the
terminal** (does the code changes, writes a report).

> **This file is the stable project context.** Claude Code reads it at the start of
> every run; keep it lean so that read stays cheap. The planning/verification
> protocol lives in `claude-prompts/WORKFLOW.md` — that's Planning Claude's playbook
> and Claude Code does **not** need to read it.

---

## 0. Talking with Ammar

Both Claudes follow this whenever they write anything Ammar will read (chat
messages and reports):

- **Plain, simple English.** Ammar's first language is not English, so use short
  sentences and easy words. Explain any technical term the first time it appears, in
  a few words (e.g. "lint = a tool that checks your code for mistakes"). Imagine
  explaining to a smart person who is new to coding — clear and simple, never talking
  down to them.
- **Be honest.** Give real opinions and real suggestions. If an idea has a problem,
  say so and explain why, then offer a better option. Do **not** agree just to be
  nice — the planning role exists to catch problems early, so always agreeing would
  make this workflow pointless. Honest disagreement, said kindly, is the job.
- **Keep it short.** Say the most important thing first. Cut filler. A few clear
  sentences beat a long wall of text.

---

## 1. Project at a glance

**What it is.** Veggie is a Flutter app for daily vegan motivation: a swipeable
quote feed (6 categories), a habit tracker with streaks, a "journey" impact
dashboard, daily notifications, a home-screen widget, and share-as-image cards.
Offline-first — no account, no backend; everything lives on-device.

**Status.** Core features shipped (feed, explore, habits, journey, onboarding,
notifications, share, widgets, 508-entry content library, app icon, Android
release build fixed). Still building features as of 2026-06-11. No git remote yet —
Ammar is setting one up.

**Stack.**

- Dart (SDK ^3.11.5), Flutter (Android, iOS, macOS, Windows targets).
- State management: flutter_riverpod 2.x.
- Database: drift (SQLite) + drift_dev/build_runner codegen — generated files
  are committed.
- Navigation: go_router. Preferences: shared_preferences.
- flutter_local_notifications + timezone, home_widget (pinned <0.8 — see locked
  decisions), share_plus, confetti, intl, window_manager.

**Layout.**

```
lib/
  main.dart        entry point
  app/             app shell, router
  core/
    db/            drift database, DAOs, content importer
    notifications/ scheduling
    prefs/         shared_preferences wrappers
    theme/         colors, typography (Fraunces + Inter, bundled)
    utils/
    widgetkit/     home-screen widget bridge
  data/            repositories / models
  features/        explore, habits, journey, onboarding, quotes, settings
assets/content/    quotes JSON (versioned, imported into DB on first run)
test/              unit + widget tests
docs/              IOS_WIDGET_SETUP.md (manual Xcode step for the iOS widget)
```

**Conventions worth knowing before touching code.**

- Content ships in `assets/content/quotes_v*.json` and is imported into the local
  DB by a versioned importer — bump `version` to ship new content; never mutate
  user data on import.
- Drift codegen: after changing tables/DAOs run `dart run build_runner build` and
  commit the generated files.
- Feature code lives under `lib/features/<feature>/`; shared plumbing under
  `lib/core/`. Follow the existing Riverpod provider patterns in each feature.
- Lint config is `flutter_lints` defaults (see `analysis_options.yaml`).

**Verification commands.**

```
flutter analyze                 # must stay clean
flutter test                    # must stay green
dart run build_runner build     # only when Drift schema/codegen inputs change
```

---

## 2. Execution protocol (Claude Code)

When Ammar hands you a prompt from `claude-prompts/<date>/`, follow it exactly, then:

1. **Self-correct before committing.** After making the change, run `flutter analyze`
   and `flutter test`. If either fails, fix it and re-run — up to **2 attempts**.
   - Still failing after 2 attempts → **commit nothing**, write the report with status
     `blocked` and the exact failure output, and stop.
   - Don't expand scope to "improve" things the prompt didn't ask for.
2. **Commit & push** (see Git policy) only once lint is clean and tests pass.
3. **Write the report** to `claude-reports/<date>/NNN-<slug>.md` (same date folder and
   slug as the prompt). Create the day's folder if it doesn't exist
   (`mkdir -p claude-reports/<date>`). Use `claude-reports/TEMPLATE.md`. The report is
   short by design — git holds the diff, so the report records intent, decisions,
   verification results, the commit SHA, and anything Ammar must do externally.
   Do **not** paste the full diff into the report.

### Git policy

- **Branch:** commit directly to `main`. No per-prompt feature branches
  unless a prompt explicitly says so.
- **Commit message:** Conventional Commits — `<type>(<scope>): <subject>` on the first
  line; body references the prompt file. Types: `feat`, `fix`, `refactor`, `chore`,
  `docs`, `test`, `perf`, `style`. Example:
  ```
  feat(habits): add weekly reminder option

  Adds a weekly cadence to habit reminders.

  Prompt: claude-prompts/2026-06-11/003-weekly-habit-reminder.md
  ```
- **Granularity:** one prompt = one commit by default (code + report together is
  fine). A batch prompt may use one commit per logical change if that reads cleaner.
- **Push:** to `origin/main`. On non-fast-forward / missing remote / auth
  failure, **stop and record it in the report** — never amend, force, or rebase.
  (Until Ammar connects the remote, a missing remote is expected: commit locally,
  note "no remote yet" in the report, and continue.)

---

## 3. Locked decisions (don't relitigate)

Committed choices. Claude Code must respect these; if a prompt would break one, that's
a bug in the prompt — note it in the report rather than silently complying.

- **Offline-first, no backend, no accounts** (locked 2026-06-11, amended 2026-06-12).
  Everything lives on-device. No login, no server, no analytics service.
  **One exception: RevenueCat**, used only for subscription purchases. The app must
  still work fully offline — last-known premium status is cached on-device and the
  app never blocks on a network call.
- **Monetization: RevenueCat, yearly-only** (locked 2026-06-12).
  - One entitlement: `premium`. Premium unlocks all 6 quote categories + full
    library; free tier keeps 2 categories. Habits, widgets, share, journey stay free.
  - Three yearly products (Ammar creates them in App Store Connect / Play Console
    and maps them in the RevenueCat dashboard):
    `veggie_yearly_full` $49.99 with 7-day free trial, `veggie_yearly_50` $24.99,
    `veggie_yearly_80` $9.99.
  - Three RevenueCat offerings → three paywalls: `onboarding` (trial, end of
    onboarding), `default` (50% off, shown on locked content / settings),
    `discount` (80% off, shown **once** right after the onboarding paywall is
    dismissed — "last chance").
  - Discount framing rule: a crossed-out anchor price may only reference the real
    $49.99 product — never an invented number.
  - Unsupported platforms (Windows; desktop dev builds): skip the RevenueCat SDK
    and treat premium as unlocked — these targets don't ship to users.
- **State management: Riverpod. Database: drift. Navigation: go_router**
  (locked 2026-06-11). No refactors to other libraries.
- **home_widget stays pinned below 0.8.x** (locked 2026-06-11). 0.8 pulls
  androidx.compose.remote (alpha) which needs AGP 9.1; this project is on
  Flutter-default AGP 8.x. Don't bump until the AGP story changes.
- **Content ships via versioned JSON imports** (locked 2026-06-11). New quotes go
  into the versioned content file + importer; user data is never touched by imports.

---

## 4. Current focus

**Monetization — RevenueCat + 3 paywalls** (started 2026-06-12). See locked
decisions in §3. Phased prompts: (1) SDK + purchase service + cached premium
state, (2) gate quote categories, (3) reusable paywall screen with 3 variants,
(4) wire triggers (onboarding → trial paywall → one-time 80% offer; locked
content → 50% paywall) + restore purchases in settings. Ammar does the
dashboard side: RevenueCat account, store products, offerings, API keys.

**Animated kawaii farm-animal characters — PAUSED 2026-06-12, phase 1 shipped.**
Phase 1 done: 6 animals (cow, pig, sheep, chicken, duck, goat) × 3 frames
(base/blink/happy) live in `assets/critters/`; `AnimatedCritter` widget
(`lib/core/critters/`) bobs, blinks, tap-wiggles; each quote feed card shows its
category's animal (commit `a5e560a`, prompt
`claude-prompts/2026-06-12/001-animated-critter-feed.md`). Generated via
Higgsfield Nano Banana Pro; master style sheet + per-animal frames are minimal
edits of a base image so frames stay pixel-aligned (whole-image frame swap;
layered puppet and AutoSprite were tested and rejected).

**Future critter work (when Ammar resumes — keep this list):**

- Remaining placements, one prompt each: habit check-off celebrations →
  onboarding slides → journey dashboard.
- Two more frames per animal, same minimal-edit rule: **ear flop** (ears
  slightly lowered) and **mouth open / "moo"** (talking-cheering, for
  onboarding).
- Rules that still hold: assets bundled in `assets/` (offline-first), art must
  be original kawaii style (no copies of existing sticker sets), happy frame =
  tap + celebrations.

<!-- keep this section current; use absolute dates -->
