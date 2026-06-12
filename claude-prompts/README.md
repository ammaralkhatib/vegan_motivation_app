# claude-prompts/

Self-contained prompts **Planning Claude** (Cowork) writes for **Claude Code**
(terminal) to execute — plus `WORKFLOW.md`, Planning Claude's playbook.

## WORKFLOW.md

`WORKFLOW.md` is the planning/verification protocol: the loop, the lanes, the prompt
format, light verification, and rollback. **Planning Claude reads it once per Cowork
session. Claude Code does NOT read it** — that keeps Claude Code's per-run read cheap.
Project facts, Claude Code's execution rules, and the "talk in plain simple English /
be honest" rules live in the repo-root `CLAUDE.md`.

## One folder per day

Prompts go in a dated folder, created on the first prompt of the day
(`mkdir -p claude-prompts/YYYY-MM-DD`):

```
claude-prompts/2026-06-11/001-add-dark-mode.md
claude-prompts/2026-06-11/002-fixup-add-dark-mode.md   # fix-forward
claude-prompts/2026-06-11/003-revert-add-dark-mode.md  # revert
```

The date is the folder; the file is `NNN-<slug>.md` — a 3-digit per-day counter plus
a short kebab-case slug. The number shows the order and lets you tell which prompt you
are on, even with several Cowork sessions open. Pick NNN by adding 1 to the highest
number already in today's folder (start at `001`); re-check right before writing so two
sessions don't clash. Original prompt files are never deleted — they're the historical
record.

## Shape

Standard/batch prompts have: **Goal · Scope · Requirements · Constraints · Verify ·
Commit & push · Report.** Full template is in `WORKFLOW.md`.

## Run command

After saving a prompt, Planning Claude emits a paste-ready command for the terminal:

```
Read CLAUDE.md, then read and execute claude-prompts/YYYY-MM-DD/NNN-<slug>.md exactly as
written. Self-correct lint/test failures before committing (CLAUDE.md §2).
Commit + push, then write the report to claude-reports/YYYY-MM-DD/NNN-<slug>.md.
```
