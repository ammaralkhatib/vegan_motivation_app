# claude-reports/

Short reports **Claude Code** writes back after running a prompt. One report per
prompt, in the **same date folder + same slug** as the prompt.

## One folder per day

```
claude-reports/2026-06-11/001-add-dark-mode.md   # matches claude-prompts/2026-06-11/001-add-dark-mode.md
claude-reports/2026-06-11/inline.md              # all inline-lane one-liners for the day
```

Claude Code creates the day's folder if needed (`mkdir -p claude-reports/YYYY-MM-DD`).

## Template

Use `TEMPLATE.md`. A report is **intent, not diff** — git holds the diff, and Planning
Claude reads it with `git show`. The report records: summary, files touched (reasons
only), decisions, verification results, self-correction outcome, commit SHA + push
result, open items, and deviations. Never paste the full diff.

## Who writes what

- **Claude Code** writes the report files.
- **Planning Claude** maintains only `TEMPLATE.md` + this `README.md` and *reads*
  reports during verification — alongside `git show`, which is the real check.
