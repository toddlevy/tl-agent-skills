---
name: tl-devlog
description: Maintain a structured development changelog (DEVLOG.md) capturing architectural decisions, milestones, incidents, and insights. Use when the user says "log this", "devlog", "archive this", or at natural pause points after significant decisions. Trigger on changelog, decision log, work log, or progress tracking.
metadata:
  moment: implement
  surface:
    - repo
  output: patch
  risk: safe
  effort: minimal
  posture: opinionated
  agentFit: repo-write
  dryRun: none
  quilted:
    version: 1
    synthesized: 2026-03-05
    sources:
      - url: https://github.com/d6veteran/devlog-skill
        borrowed:
          - Entry format
          - Category system (architecture/milestone/takeaway/strategy)
          - Proactive suggestions
          - Why-focus philosophy
          - GitHub push workflow
          - Reading devlog for context
        weight: 0.45
      - url: https://github.com/maoruibin/devlog
        borrowed:
          - Extended categories (incident/bug/ops)
          - Explicit trigger rules
          - Global/local storage modes
        weight: 0.30
      - url: https://github.com/josephmiclaus/skill-devlog
        borrowed:
          - Safety constraints
          - APPEND/CHANGE modes
          - Structured entry sections
        weight: 0.25
    excluded:
      - url: https://github.com/lordshashank/devlog
        reason: Different domain — generates narrative blog posts from session transcripts rather than maintaining a structured work log
    enhancements:
      - Unified category system merging strategic and operational categories
      - Combined explicit triggers with optional proactive suggestions
      - Simplified workflow without external script dependencies
---

# tl-devlog

Maintain a living development log (`DEVLOG.md`) in project repositories. Captures decisions, progress, incidents, and insights so future sessions have full context on what was done and why.

## Quick Start

Just say **"log this"** or **"devlog"** after any significant decision or milestone.

**Example interaction:**
```
You: "We decided to use PostgreSQL instead of MongoDB for the audit system"
Agent: "This feels worth capturing — we decided PostgreSQL for transactional 
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

Frame suggestions naturally: "This feels worth capturing — we decided X because of Y. Want me to log it?"

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
- The "why" — rationale is the most valuable part
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
# [Project Name] — Development Log

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
✅ Logged: [Category] - [Title]
📂 DEVLOG.md updated
🔗 Pushed to origin
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

This makes the devlog bidirectional — for writing and recalling context.

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
- Be specific — include versions, filenames, concrete details
- Include the "why" for every "what"
- Tags: lowercase, hyphenated, searchable (`rate-limiting`, `auth-flow`)
- Reference related devlog entries by date when relevant

### What Good Looks Like

```
❌ BAD: "Fixed the database issue"

✅ GOOD: "Resolved 45-minute API outage caused by connection pool exhaustion.
   Root cause: analytics cron job ran 3-hour query without statement timeout.
   Fix: Killed query, added 5-minute timeout, separated analytics pool."
```

---

## Skill Resources

| Document | Purpose |
|----------|---------|
| `references/entry-examples.md` | Complete examples for each category |

Load the examples reference when you need inspiration for a specific category.
