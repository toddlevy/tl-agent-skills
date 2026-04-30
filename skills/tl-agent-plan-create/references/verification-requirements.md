# Verification Requirements

> Loaded on-demand by `tl-agent-plan-create` when populating the Verifications table. See `../SKILL.md` for the parent skill.

Plans make factual claims about the codebase (file paths exist, constants have zero importers, columns are always null, etc.). These claims cost time to verify during planning — that investment is wasted if the executor re-verifies them from scratch.

**Every factual claim must produce a verification receipt** in the `### Verifications` table inside the `## Plan Metadata` section of the plan body. This is not optional. Verification metadata MUST NOT go in the YAML frontmatter — Cursor's frontmatter parser is fragile and breaks on complex nested arrays.

## What requires a verification entry

1. **Existence/absence claims** — "X has zero importers", "file Y does not exist", "column Z is always null"
2. **Line number citations** — "lines 23-30 contain..." (record the command and result)
3. **Code snippet assertions** — "current state is..." (verify by reading the file)
4. **Scope claims** — "only these 5 files reference CONSTANT" (record the grep)

## Verification entry format

Add rows to the `### Verifications` table in the plan body:

```markdown
### Verifications

| Claim | Command | Result |
|-------|---------|--------|
| ACTIVITY_TYPES has zero importers outside constants.ts | `rg ACTIVITY_TYPES apps/` | 0 matches |
| bounced column on newsletters is always null | `SELECT count(*) FROM newsletters WHERE bounced IS NOT NULL` | 0 |
| formatEventType is at lines 28-44 | `read process-webhook-events.ts lines 28-44` | function formatEventType(eventType: string): string ... |
```

## `Verified at` field

Record `git rev-parse --short HEAD` at plan creation time in the Plan Metadata table as the `Verified at` row. This lets the executor determine whether the codebase has changed since verification.

## What does NOT need a verification entry

- Design decisions (these are documented via `> Decision:` rationale lines)
- Exit gate criteria (these are outputs the executor will produce, not inputs from the codebase)
- Commands to run (these are instructions, not claims)

**When genuinely uncertain**: If the planner cannot resolve a decision after codebase research, they must ask the user via AskQuestion before writing the plan — not embed the question in the plan body.

**Rationale format**: When a decision was non-obvious, add a single line after the relevant subtask or phase header:

```
> Decision: [chosen approach] — [one-sentence reason grounded in first principles or existing patterns]
```
