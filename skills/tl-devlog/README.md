# tl-devlog

Maintain a living development log (`DEVLOG.md`) in project repositories. Captures decisions, progress, incidents, and insights so future sessions have full context.

## Quick Start

Say any of these to add an entry:
- "log this"
- "devlog"  
- "archive this decision"

Or the agent will suggest logging at natural pause points after significant decisions.

## What Gets Logged

| Category | Example |
|----------|---------|
| `architecture` | "Chose PostgreSQL over MongoDB for transactional integrity" |
| `milestone` | "Completed v1.0 API endpoints" |
| `incident` | "Fixed memory leak in worker process" |
| `bug` | "Resolved race condition in auth flow" |
| `ops` | "Added Datadog APM instrumentation" |
| `design` | "Adopted card-based layout for dashboard" |
| `strategy` | "Pivoted from B2C to B2B focus" |
| `takeaway` | "Learned that bulk imports need progress indicators" |

## Entry Format

```markdown
## [2026-03-10] Chose event sourcing for audit trail

**Category:** `architecture`
**Tags:** `audit`, `events`, `compliance`

### Summary
Decided to use event sourcing pattern for the audit subsystem.

### Detail
- Captures full history of state changes for compliance
- Rejected simple logging — doesn't support replays
- Rejected change data capture — adds operational complexity
- Will use PostgreSQL with JSONB for event storage

### Related
- [2026-03-08] Database selection decision
```

## Resources

| File | Purpose |
|------|---------|
| `SKILL.md` | Full methodology and workflow |
| `references/entry-examples.md` | Real examples for each category |

## Quilted Skill

Synthesized from:
- [d6veteran/devlog-skill](https://github.com/d6veteran/devlog-skill) - Entry format, proactive suggestions
- [maoruibin/devlog](https://github.com/maoruibin/devlog) - Extended categories, storage modes
- [josephmiclaus/skill-devlog](https://github.com/josephmiclaus/skill-devlog) - Safety constraints
