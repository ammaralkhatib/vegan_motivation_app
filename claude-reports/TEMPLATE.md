# <Title of the change>

**Prompt:** `claude-prompts/YYYY-MM-DD/NNN-<slug>.md`
**Completed:** YYYY-MM-DD · **Status:** done | partial | blocked

> Keep this short. Git holds the diff — Planning Claude reads it with `git show`.
> The report records what git *can't* tell: intent, decisions, results, follow-ups.
> Do **not** paste the full diff here.

## Summary

One paragraph: what was asked, what you did, headline result.

## Files touched

One line each — the *reason*, not the diff (git has the names + contents).

- `path/to/file` — why it changed.

## Decisions

Anything you decided that the prompt didn't fully specify, with brief rationale.
"None." if nothing.

- **<decision>** — why.

## Verification

```
$ flutter analyze
<result>

$ flutter test
<result>
```

Self-correction: <none | "fixed X on attempt 2" | "still failing after 2 — committed nothing">.
Manual click-path (if any): [ ] step …

## Commit & push

- **Commit(s):** `<sha>` — `<type>(<scope>): <subject>`
- **Push:** `origin/main` — ok | failed (reason: …)

If the push failed: what happened and what you did (always: stopped + reported —
never force-pushed or amended).

## Open items for the owner

External things Planning Claude can't verify (DB migration, regenerate assets,
store/dashboard changes). Delete the section if there are none.

- …

## Deviations from prompt

Anything in Scope / Requirements / Constraints skipped or done differently, with a
reason. "None." if nothing.
