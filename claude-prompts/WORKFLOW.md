# Two-Claude Workflow — Planning Claude's Playbook

**Read this once per Cowork session.** It's the protocol for Planning Claude (you, in
Cowork). Claude Code does **not** read this file — its execution rules live in the
repo-root `CLAUDE.md` §2. Project facts (stack, conventions, locked decisions) and the
**Talking with Ammar** rules (plain simple English, be honest, keep it short) also
live in `CLAUDE.md` (§0–§4). Follow §0 in every chat message you write to Ammar.

Cowork and the terminal share the **same working folder**, so after Claude
Code commits locally, you can inspect the real change directly with `git show` /
`git diff` / `git log`. **Git is the source of truth, not the report.**

---

## Folder layout (one folder per day)

Prompts and reports are grouped into a dated folder per day:

```
claude-prompts/
  WORKFLOW.md            ← this file
  README.md
  2026-06-11/            ← created the first time you save a prompt that day
    001-add-dark-mode.md
    002-fixup-add-dark-mode.md
claude-reports/
  TEMPLATE.md
  README.md
  2026-06-11/            ← Claude Code creates it (mkdir -p) when writing the report
    001-add-dark-mode.md
    inline.md            ← all inline-lane one-liners for the day (not numbered)
```

- **Create the day's folder if it doesn't exist** before saving a prompt:
  `mkdir -p claude-prompts/YYYY-MM-DD`.
- The date is the folder; the filename is `NNN-<slug>.md` — a 3-digit number, then the slug.
- A report always lives in the **same date folder with the same `NNN-<slug>`** as its prompt.

### Numbering — how to pick NNN

The number is a per-day counter so you (and any parallel session) can always tell
which prompt is which and what order they ran in.

1. **Right before saving the prompt**, list today's folder and find the highest `NNN-`
   already there. The new number is that + 1, zero-padded to 3 digits. If the folder is
   empty or new, start at `001`.
2. **Re-check at the moment of writing** to stay safe when two Cowork sessions run at
   once: if the number you picked already exists on disk, take the next free one. (Two
   sessions can still rarely collide in the same instant — if you ever see a clash, just
   bump the loser to the next number; nothing is lost because git keeps both.)
3. Fix-forward and revert prompts get their **own** next number too (e.g.
   `005-fixup-add-dark-mode.md`) — they're new runs. The slug still names what they fix.
4. The inline lane is **not** numbered: it all goes into one running `inline.md` per day.

---

## Roles

| Role | Where | Does | Never |
|---|---|---|---|
| **Ammar** | Cowork chat | Decides direction, runs prompts in the terminal, signs off. | Hand-edits files mid-loop. |
| **Planning Claude** | Cowork chat | Audits repo, proposes work, writes prompts, verifies via git. Honest, plain, short (CLAUDE.md §0). | **Edits source.** Only `CLAUDE.md`, `claude-prompts/**`, `claude-reports/TEMPLATE.md` + `README.md`. |
| **Claude Code** | `claude` CLI | Makes the code change, self-corrects, commits, pushes, writes the report. | Skips the report; force-pushes. |

---

## The loop

1. **Idea.** Ammar names work, or you propose it from the codebase (honestly — say
   if you think it's the wrong thing to build).
2. **Pick a lane** (below), make sure today's folder exists, pick NNN (Numbering rule above), and write the prompt to
   `claude-prompts/YYYY-MM-DD/NNN-<slug>.md`.
3. **Emit the paste-ready run command** right after saving, in a fenced block — no
   exceptions:
   ```
   Read CLAUDE.md, then read and execute claude-prompts/YYYY-MM-DD/NNN-<slug>.md exactly as
   written. Self-correct lint/test failures before committing (CLAUDE.md §2).
   Commit + push, then write the report to claude-reports/YYYY-MM-DD/NNN-<slug>.md.
   ```
4. **Ammar runs it**, then says "done".
5. **Verify** (light — see Verification).
6. **Loop.**

---

## Lanes — match ceremony to risk

Don't pay full file-prompt overhead for tiny work. Pick the lightest lane that fits:

- **Inline lane** — trivial, single-file, low-risk (rename, copy tweak, version bump).
  Skip the dated prompt file. Emit a short run command inline; Claude Code still
  commits + pushes, but appends a **one-line** entry to
  `claude-reports/YYYY-MM-DD/inline.md` instead of a full report. Verify with one
  `git show`.
- **Standard lane** — one focused change. Full prompt file + full report. The default.
- **Batch lane** — several **small, independent, related** changes sharing context
  (e.g. three copy fixes across screens). One prompt listing each as a numbered
  Requirement, one run, one report. Cuts N round trips to 1. Do **not** batch changes
  that depend on each other or touch risky/shared code — those stay standard so a
  failure is easy to isolate and revert.

When unsure, default to standard.

---

## Prompt format (standard / batch lane)

```
# <Title>

## Goal
One paragraph: why, and what "done" looks like to the user.

## Scope
- In: files / areas in play.
- Out: files / areas off-limits.

## Requirements
Numbered, concrete acceptance criteria. (Batch lane: one number per change.)

## Constraints
- Locked decisions that must hold for this change (CLAUDE.md §3 — e.g. offline-first,
  Riverpod/drift/go_router, home_widget <0.8, versioned content imports).
- flutter analyze clean; flutter test green (self-correct up to 2 tries per CLAUDE.md §2).
- Any change-specific guardrail (e.g. run build_runner if Drift schema changes).

## Verify
- Commands to run + any manual click-path.

## Commit & push
- Conventional Commit; body includes `Prompt: claude-prompts/YYYY-MM-DD/NNN-<slug>.md`.
- Push to origin/main; on failure, stop and report (never force).

## Report
- Write claude-reports/YYYY-MM-DD/NNN-<slug>.md from TEMPLATE.md (mkdir -p the folder).
  Record intent, decisions, verification results, commit SHA, push result, open
  items. No full diff.
```

Keep the prompt self-contained — Claude Code shouldn't need anything beyond it and
`CLAUDE.md`. The Constraints only need the guardrails *this* change could trip over.

---

## Verification (light — git is the source of truth)

When Ammar says "done":

1. **Read the report** — for intent, decisions, deviations, open items, and the
   verification output Claude Code recorded (you can't run `flutter analyze` /
   `flutter test` yourself — Flutter isn't on the Cowork sandbox; rely on the
   recorded result + Ammar's local run).
2. **`git show <sha>`** (or `git diff` for a range) — read the *actual* diff, not the
   report's description of it.
3. **Spot-check against Requirements** line by line, and confirm nothing landed
   outside **Scope** / violated a **Constraint** or locked decision.
4. **Verdict** (plain language for Ammar, CLAUDE.md §0):
   - ✅ matches, recorded verification green, pushed → done; suggest the next prompt.
   - ⚠️ off-spec / regression / scope creep / push failed → go to Rollback.

Only re-read full files when `git show` leaves something genuinely ambiguous.

---

## Rollback playbook

Commits hit `origin/main` as soon as Claude Code finishes. Pick the
lightest fix back to known-good:

1. **Nothing wrong** → ✅, suggest next.
2. **Small / surgical** (one off-spec line, missing test, lying doc-comment) →
   **fix-forward** prompt: `claude-prompts/YYYY-MM-DD/NNN-fixup-<original-slug>.md`. Narrow
   scope; commit body: "Fixes <issue> from <original-sha>".
3. **Fundamentally wrong** (regression, wrong approach, scope creep) → **revert**
   prompt: `claude-prompts/YYYY-MM-DD/NNN-revert-<original-slug>.md`, then optionally a redo
   prompt. Recipe:
   ```
   git revert <sha> --no-edit          # or: <report-sha> <code-sha> for a pair, newest first
   git push origin main
   ```
4. **Can't verify** (toolchain not on sandbox, needs a device) → flag to Ammar,
   wait for their local result before rolling back.

**Never `git reset --hard` on pushed commits** — it breaks every other clone. Revert
adds a new commit that undoes the old one; that's the correct tool. Original prompt
files are never deleted — they're the historical record.

---

## Project memory

When Ammar mentions something cross-cutting that should persist (a new locked
decision, a recurring preference, an external-system pointer), write it into the right
section of `CLAUDE.md` — not chat memory. **The file is the source of truth.**
