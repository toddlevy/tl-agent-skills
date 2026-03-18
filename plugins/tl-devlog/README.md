# tl-devlog Plugin

Cursor plugin for maintaining structured development changelogs.

## What's Included

### Skill: tl-devlog

Maintain a living `DEVLOG.md` in project repositories capturing:
- Architecture decisions with rationale
- Milestones and completed work
- Incidents and resolutions
- Key insights and lessons learned

### Rule: tl-devlog-usage.mdc

Guidance for when and how to invoke the devlog skill:
- Explicit triggers: "log this", "devlog", "archive this"
- Proactive suggestions at natural pause points
- Always capture the "why" behind decisions

## Categories

| Category | What It Captures |
|----------|------------------|
| `architecture` | Technical design decisions, data models, stack choices |
| `milestone` | Completed work, version releases, phase transitions |
| `incident` | Production issues, root cause, resolution |
| `bug` | Non-production bugs, debugging sessions |
| `ops` | Infrastructure, deployment, monitoring changes |
| `design` | UX decisions, UI patterns, feature specifications |
| `strategy` | Business decisions, positioning, go-to-market |
| `takeaway` | Key insights, lessons learned |

## Usage

After completing significant work or making architecture decisions, either:
- Say "log this" to capture the decision
- The agent may proactively suggest: "This feels worth capturing — want me to log it?"

Entries are added to `DEVLOG.md` in reverse-chronological order.
