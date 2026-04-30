---
name: tl-devlog
description: Maintain a structured development changelog (DEVLOG.md) capturing architectural decisions, milestones, incidents, and insights. Use when the user says "log this", "devlog", "archive this", or at natural pause points after significant decisions. Trigger on changelog, decision log, work log, or progress tracking.
license: MIT
metadata:
  version: "1.1"
  author: Todd Levy <toddlevy@gmail.com>
  homepage: https://github.com/toddlevy/tl-agent-skills
  quilted:
    - source: d6veteran/devlog-skill
      weight: 0.40
      description: Entry format, category system, proactive suggestions, why-focus philosophy
    - source: maoruibin/devlog
      weight: 0.25
      description: Extended categories (incident/bug/ops), explicit trigger rules
    - source: josephmiclaus/skill-devlog
      weight: 0.20
      description: Safety constraints, APPEND/CHANGE modes, structured entry sections
    - source: skillrecordings/adr-skill
      weight: 0.15
      description: ADR integration, MADR 4.0 template, promotion workflow
  moment: implement
  surface:
    - repo
  output: patch
  risk: safe
  effort: minimal
  posture: opinionated
  agentFit: repo-write
  dryRun: none
---

<!-- Copyright (c) 2026 Todd Levy. Licensed under MIT. SPDX-License-Identifier: MIT -->

# tl-devlog

Maintain a living development log (`DEVLOG.md`) in project repositories. Captures decisions, progress, incidents, and insights so future sessions have full context on what was done and why.

## Quick Start

Just say **"log this"** or **"devlog"** after any significant decision or milestone.

**Example interaction:**
```
You: "We decided to use PostgreSQL instead of MongoDB for the audit system"
Agent: "This feels worth capturing â€” we decided PostgreSQL for transactional 
       integrity over MongoDB's flexibility. Want me to log it?"
You: "Yes, log it"
Agent: [Drafts entry, shows for approval, commits to DEVLOG.md]
```

---

## When to Use

**Explicit triggers** (user-initiated):
- "Log this", "devlog", "archive this"
- "Add to the devlog", "record this decision"
- "This should go in the changelog"

**Proactive suggestions** (agent-initiated, at natural pause points):
- A technical architecture decision was made
- A significant piece of work was completed
- A production incident was resolved
- An important insight emerged
- A strategic direction was established

Frame suggestions naturally: "This feels worth capturing â€” we decided X because of Y. Want me to log it?"

**Do NOT log**:
- Routine Q&A or simple lookups
- Work still in progress with no decision point
- Minor clarifications that don't change direction

## Outcomes

- **Artifact**: Entry added to `DEVLOG.md` in project root
- **Patch**: Git commit with `devlog:` prefix pushed to origin

---

## Safety Constraints

- Do NOT store secrets, API keys, tokens, or credentials in devlog entries
- If sensitive information is mentioned, redact it before logging
- Always show the user the draft entry before committing
- Never auto-push without user confirmation

---

## Categories

Choose the category that best fits each entry:

| Category | What It Captures | Example |
|----------|------------------|---------|
| `architecture` | Technical design decisions, data models, stack choices, API design | "Chose PostgreSQL over MongoDB for transactional integrity" |
| `milestone` | Completed work, version releases, phase transitions | "Completed v1.0 API endpoints" |
| `incident` | Production issues, root cause, resolution | "Fixed memory leak in worker process" |
| `bug` | Non-production bugs, debugging sessions | "Resolved race condition in auth flow" |
| `ops` | Infrastructure, deployment, monitoring changes | "Added Datadog APM instrumentation" |
| `design` | UX decisions, UI patterns, feature specifications | "Adopted card-based layout for dashboard" |
| `strategy` | Business decisions, positioning, go-to-market | "Pivoted from B2C to B2B focus" |
| `takeaway` | Key insights, lessons learned, context for future | "Learned that bulk imports need progress indicators" |

---

## Entry Format

```markdown
## [YYYY-MM-DD] Brief descriptive title

**Category:** `architecture` | `milestone` | `incident` | `bug` | `ops` | `design` | `strategy` | `takeaway`
**Tags:** `relevant`, `topic`, `tags`

### Summary
1-2 sentence overview of what happened or was decided.

### Detail
- What was decided or accomplished
- Why this approach was chosen
- What alternatives were considered (and why rejected)
- Dependencies or implications for future work

### Related
- Links to related entries, PRs, issues, or docs
```

---

## Instructions

### Step 1: Identify the Project

On first use in a session, establish context:

1. Check if the current working directory is a git repo
2. If yes, use the repo root for `DEVLOG.md`
3. If ambiguous, ask: "Which project should I log this to?"

### Step 2: Identify Category and Content

From the conversation or user request, determine:
- **Category**: Which of the 8 categories fits best
- **Title**: Brief descriptive phrase
- **Content**: What happened, why, what alternatives were considered

### Step 3: Draft the Entry

Write the entry following the format above. Include:
- Specific details (file names, version numbers, concrete outcomes)
- The "why" â€” rationale is the most valuable part
- Past tense for decisions and completed work

### Step 4: Show User for Approval

Present the drafted entry and ask:
- "Does this capture it accurately?"
- "Any edits before I commit?"

**Never commit without user confirmation.**

### Step 5: Update DEVLOG.md

Determine the file path:
- Use `{repo_root}/DEVLOG.md`
- If the file doesn't exist, create it with this header:

```markdown
# [Project Name] â€” Development Log

A living record of architectural decisions, milestones, incidents, and insights.
Entries are reverse-chronological (newest first).

---
```

Insert the new entry immediately below the header separator (`---`). Entries are always newest-first.

### Step 6: Commit and Push

After user approval:

```bash
git add DEVLOG.md
git commit -m "devlog: [brief title from entry]"
git push origin HEAD
```

### Step 7: Confirm

Report back:
```
âœ… Logged: [Category] - [Title]
ðŸ“‚ DEVLOG.md updated
ðŸ”— Pushed to origin
```

---

## Update Modes

When updating an existing date's entry:

**APPEND** (default): Add new bullets to existing sections without modifying prior content.

**CHANGE**: User describes specific edits. Apply minimal changes faithful to the request.

---

## Reading the Devlog

When the user asks about past decisions, progress, or project history:

1. Read `DEVLOG.md` from the repo
2. Search entries by category, tags, date, or keywords
3. Summarize relevant entries in the conversation

This makes the devlog bidirectional â€” for writing and recalling context.

---

## Multiple Entries Per Session

If a conversation covers several loggable topics:
- Draft all entries at once
- Present them together for review
- Commit in a single push: `devlog: session updates - [topic1], [topic2]`

---

## Storage Modes

| Mode | Location | Use Case |
|------|----------|----------|
| **Project** (default) | `{repo_root}/DEVLOG.md` | Checked into git, shared with team |
| **Local** | `.devlog/` in project | Git-ignored, private notes |
| **Global** | `~/.devlog/` | Cross-project personal log |

Default to project mode. Switch to local/global only if user explicitly requests.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Not a git repo | Ask user where to store the log |
| Push fails | Show error, suggest fixes (auth, branch protection). Save entry locally. |
| Merge conflicts | Show conflict, help resolve, retry |
| No write access | Fall back to local mode, inform user |

---

## Style Guidelines

- Past tense for decisions and completed work ("Chose X over Y")
- Present tense for ongoing context ("The system supports N")
- Be specific â€” include versions, filenames, concrete details
- Include the "why" for every "what"
- Tags: lowercase, hyphenated, searchable (`rate-limiting`, `auth-flow`)
- Reference related devlog entries by date when relevant

### What Good Looks Like

```
âŒ BAD: "Fixed the database issue"

âœ… GOOD: "Resolved 45-minute API outage caused by connection pool exhaustion.
   Root cause: analytics cron job ran 3-hour query without statement timeout.
   Fix: Killed query, added 5-minute timeout, separated analytics pool."
```

---

## Skill Resources

| Document | Purpose |
|----------|---------|
| `references/entry-examples.md` | Complete examples for each category |

Load the examples reference when you need inspiration for a specific category.

---

## ADR Integration

Some `architecture` entries deserve promotion to formal Architecture Decision Records.

### When to Promote to ADR

| Devlog Entry | Promote? | Reasoning |
|--------------|----------|-----------|
| "Chose PostgreSQL over MongoDB" | âœ“ Yes | Significant, reversible-with-effort decision |
| "Added rate limiting to API" | Maybe | If it affects system design |
| "Fixed typo in config" | âœ— No | Trivial, no alternatives considered |

### MADR 4.0 Template

When promoting to ADR, use this format in `docs/decisions/NNNN-decision-title.md`:

```markdown
---
status: accepted
date: 2026-03-18
decision-makers: [team members]
consulted: [stakeholders]
informed: [affected parties]
---

# ADR-NNNN: [Decision Title]

## Context and Problem Statement

[1-2 sentences describing the situation and the decision to be made]

## Decision Drivers

* [Concern 1]
* [Concern 2]

## Considered Options

1. [Option A]
2. [Option B]
3. [Option C]

## Decision Outcome

Chosen option: "[Option X]" because [justification].

### Consequences

* Good, because [positive outcome]
* Bad, because [negative outcome]
* Neutral, because [side effect]

## Links

* [Link to devlog entry]
* [Link to related ADRs]
```

### Bidirectional Linking

When promoting a devlog entry to ADR:

1. Create the ADR file
2. Update the devlog entry with a link:

```markdown
### Related
- **ADR**: [ADR-0015: PostgreSQL for Audit System](docs/decisions/0015-postgresql-for-audit.md)
```

---

## CHANGELOG Bridging

Extract `milestone` entries to generate CHANGELOG releases.

### Workflow

1. **Query milestones since last release:**
   ```bash
   grep -A 20 "Category.*milestone" DEVLOG.md | head -50
   ```

2. **Map to CHANGELOG categories:**
   
   | Devlog Tag | CHANGELOG Section |
   |------------|-------------------|
   | `new-feature` | Added |
   | `enhancement` | Changed |
   | `deprecation` | Deprecated |
   | `removal` | Removed |
   | `fix`, `bug` | Fixed |
   | `security` | Security |

3. **Generate entry:**

   ```markdown
   ## [1.2.0] - 2026-03-18
   
   ### Added
   - API endpoint for bulk imports (#123)
   
   ### Changed  
   - Improved rate limiting algorithm
   
   ### Fixed
   - Memory leak in worker process (incident 2026-03-15)
   ```

### Keep a Changelog Format

Follow [keepachangelog.com](https://keepachangelog.com/):

- Newest entries at top
- Group by version, then by type
- Use ISO dates (YYYY-MM-DD)
- Link versions to git tags

---

## Search Patterns

### Find entries by category

```bash
grep -B 2 "Category.*architecture" DEVLOG.md
```

### Find entries by tag

```bash
grep -B 5 "Tags:.*auth-flow" DEVLOG.md
```

### Find entries by date range

```bash
awk '/## \[2026-03-/{flag=1} flag; /## \[2026-02-/{flag=0}' DEVLOG.md
```

### Full-text search

```bash
grep -B 10 -A 10 "PostgreSQL" DEVLOG.md
```

---

## References

### Quilted Skills

- [d6veteran/devlog-skill](https://github.com/d6veteran/devlog-skill) â€” Entry format, categories
- [maoruibin/devlog](https://github.com/maoruibin/devlog) â€” Extended categories
- [josephmiclaus/skill-devlog](https://github.com/josephmiclaus/skill-devlog) â€” Safety constraints
- [skillrecordings/adr-skill](https://github.com/skillrecordings/adr-skill) â€” ADR integration

### First-Party Documentation

- [Keep a Changelog](https://keepachangelog.com/) â€” CHANGELOG format standard
- [MADR](https://adr.github.io/madr/) â€” Markdown Architectural Decision Records
- [Conventional Commits](https://www.conventionalcommits.org/) â€” Commit message convention

### Industry Perspectives

- [Engineering Daybook (Fowler)](https://martinfowler.com/bliki/EngineeringDaybook.html) â€” Philosophy
- [Documenting Architecture Decisions (Nygard)](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) â€” Original ADR proposal
