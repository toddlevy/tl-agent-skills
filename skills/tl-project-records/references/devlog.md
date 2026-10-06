# DEVLOG.md

The DEVLOG answers "what happened, when, and why?" It is the project's chronological memory: the entry a future session reads to learn what was done and what it cost, without replaying commits.

## Location and header

- `DEVLOG.md` at the repository root. Root is where agents and people look first.
- The header holds a one-paragraph purpose and a `## Conventions` list (copy `assets/templates/DEVLOG.md`), followed by a `---` separator. Entries follow the separator.
- A workspace that declares different conventions in that header (location, commit prefix, approval flow) overrides this skill. Read the header before writing.

## Entry shape

```markdown
## [YYYY-MM-DD] Brief descriptive title

**Category:** `architecture`
**Tags:** `topic`, `searchable-keyword`

### Summary
One or two sentences: what happened or was decided.

### Detail
- What was decided or accomplished, with concrete names, numbers, and versions.
- Why this approach was chosen.
- What alternatives were considered and why they lost.
- What follows from it.

### Related
- ADR-0007, the pull request or issue, commit SHAs, and earlier entries by date.
```

The five labels appear in that order. `check` rejects a missing or reordered label, an empty `**Tags:**`, a category outside the configured list, an ADR reference with no matching file, and a date newer than the entry above it.

## Categories

Exactly one per entry. Prefer the more specific category.

| Category | Captures | Example title |
|----------|----------|---------------|
| `architecture` | Design decisions, data models, stack choices, API shape | Chose PostgreSQL over MongoDB for the audit store |
| `milestone` | Completed work units, releases, phase transitions | Closed the billing v2 work unit |
| `incident` | Production issues: timeline, root cause, resolution | Resolved a 45-minute API outage |
| `bug` | Non-production defects found through debugging | Fixed a race in WebSocket reconnection |
| `ops` | Infrastructure, deployment, monitoring | Moved CI from a hosted runner to GitHub Actions |
| `design` | UX decisions, UI patterns, feature specifications | Adopted skeleton loading for the dashboard |
| `strategy` | Business direction, positioning, prioritization | Moved from self-serve to sales-led growth |
| `takeaway` | Lessons and context for future work | Bulk imports need progress feedback |

## Triggers

Write an entry at these moments, and only these:

| Moment | Category hint | Who writes it |
|--------|---------------|---------------|
| A work unit closes (a plan, epic, or cycle is archived) | `milestone` | The close-out ceremony, inline |
| A production release ships | `milestone` or `ops` | The release step |
| A live incident is resolved | `incident` | Whoever resolved it |
| A decision produces an ADR | `architecture` (or the closest fit) | Whoever writes the ADR |
| The user says "log this", "devlog", or "record this decision" | from content | On request |

Do not log routine questions, lookups, in-flight work with no decision point, audit findings (they belong in the plan or review), or dispatch and process notes (they belong in the workspace's own notes file).

## Writing rules

- **Why over what.** Rationale is the part a commit cannot carry. Every "what" gets its "why".
- **Specific.** File names, version numbers, counts, durations, SHAs. "Fixed the database issue" is not an entry.
- **Past tense** for decisions and completed work; present tense for standing context.
- **Tags** are lowercase and hyphenated, three to five, chosen for search.
- **Link, do not restate.** The reasons for an ADR-backed decision live in the ADR. The entry names `ADR-NNNN` under Related and summarizes in one line.
- **No secrets.** Never write a credential, key, token, password, or personal data. Redact before drafting.
- **Seeded history.** An entry written after the fact (a retroactive seed when adopting the records) carries the tag `retroactive` and cites the commits it rests on.

## Update modes

- **Append** (default): add a new entry at the top, or add bullets to an existing same-day entry without changing prior text.
- **Change**: the user names a specific correction. Apply the smallest edit that is faithful to it. A correction to a fact never rewrites the rationale that was true at the time.

## Approval and commit

- A **standalone** entry (on request or at an incident) is drafted, shown to the user in full, and committed only after they confirm. Commit subject: `docs(records): <entry title in lowercase>`.
- A **close-out** or **release** entry is part of that ceremony's own commit, which the user has already authorized by running the ceremony. It is still shown in the ceremony's report.
- Never push as part of logging. Pushing is a separate decision.

## Reading the log

When the user asks about past decisions or history, read `DEVLOG.md` and search it:

```powershell
Select-String -Path DEVLOG.md -Pattern '^\*\*Category:\*\* `incident`' -Context 2,0
Select-String -Path DEVLOG.md -Pattern '^\*\*Tags:\*\*.*`auth-flow`' -Context 3,0
Select-String -Path DEVLOG.md -Pattern '^## \[2026-03-'
```

```bash
grep -B 2 'Category:\*\* `architecture`' DEVLOG.md
grep -n '^## \[2026-03-' DEVLOG.md
```

Summarize the matching entries and cite them by date.

## Optional storage modes

Project mode (`DEVLOG.md` in the repository) is the default and the only mode the records tool checks. A user may ask for a private log instead: `.devlog/` in the project (gitignored) or `~/.devlog/` for a cross-project personal log. Use those only on explicit request; they are outside `check`.
