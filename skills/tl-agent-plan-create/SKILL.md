---
name: tl-agent-plan-create
description: Create structured plan documents for features, projects, or multi-phase tasks. Includes YAML frontmatter, strategic/technical templates, phases, gates, and real-time update requirements.
license: MIT
metadata:
  version: 1.1.0
  author: tl-agent-skills
  moment: plan
  surface:
    - repo
  output: artifact
  risk: low
  effort: low
  posture: guided
  agentFit: repo-write
  portability: high
  suite: tl-agent-plan
  related:
    - tl-agent-plan-audit
---

# Create Plan Document

Create structured plan documents for features, projects, or multi-phase tasks.

## When to Use

- User asks to "create a plan" or "plan out" something
- Starting a new feature or project
- Breaking down complex work into phases
- User mentions "phases", "milestones", or "roadmap"

## Outcomes

- **Artifact**: Plan document in `.cursor/plans/` with YAML frontmatter and phased structure
- **Decision**: Plan type, complexity level, dependencies, issue tracker integration, documentation scope

---

## Before You Begin: Configuration Discovery

Gather requirements using the AskQuestion tool. Ask all questions in a single batch where possible.

### Question 0: Plan Type (ask this FIRST — it determines everything else)

```
prompt: "Is this a strategic plan or a technical plan?"
options:
  - id: strategic
    label: "Strategic — high-level phases, milestones, grouped todos (e.g. roadmap, initiative overview)"
  - id: technical
    label: "Technical — granular subtasks, one todo per step, programmatic gates (e.g. implementation, refactor)"
```

**If strategic:** use the Strategic Template (grouped todos, milestone-level phases).
**If technical:** use the Technical Template (one todo per atomic subtask, hierarchical numbering, bash gates).

---

### Question 1: Plan Name/Title

```
prompt: "What is this plan for?"
options:
  - id: feature
    label: "New feature implementation"
  - id: integration
    label: "Third-party integration"
  - id: refactor
    label: "Refactoring or migration"
  - id: infrastructure
    label: "Infrastructure or DevOps"
  - id: other
    label: "Something else..."
```

### Question 2: Complexity

```
prompt: "How complex is this work?"
options:
  - id: small
    label: "Small - 1-2 phases, can finish in a day"
  - id: medium
    label: "Medium - 3-4 phases, multi-day effort"
  - id: large
    label: "Large - 5+ phases, week+ of work"
  - id: agent
    label: "You tell me - you already analyzed this"
# If agent: assess complexity from prior conversation context and state your assessment.
```

### Question 3: Dependencies

```
prompt: "Does this plan depend on other plans or work?"
options:
  - id: none
    label: "No dependencies - standalone work"
  - id: yes
    label: "Yes - depends on previous plan(s)"
# If yes: "Which plan(s)?"
```

### Question 4: Issue Tracker Integration (optional)

```
prompt: "Should this plan link to issue tracker tickets (e.g. JIRA, Linear, GitHub Issues)?"
options:
  - id: yes
    label: "Yes - include ticket references and transitions"
  - id: no
    label: "No - standalone plan without ticket tracking"
```

### Question 5: Documentation

```
prompt: "Will this plan create user-facing or developer documentation?"
options:
  - id: both
    label: "Both user and developer documentation"
  - id: developer
    label: "Developer documentation only"
  - id: user
    label: "User documentation only"
  - id: none
    label: "No documentation deliverables"
```

### Question 6: Branch Strategy

```
prompt: "Should this work be done in a feature branch?"
options:
  - id: yes
    label: "Yes - create a feature branch"
  - id: no
    label: "No - work on current branch"
# If yes: suggest branch name as feat/{plan-name-kebab-case}
```

---

## File Naming Convention

```
{descriptive-name}-{8-char-hex}.plan.md
```

Example: `quota-cycle-ground-truth-ccb07975.plan.md`

- Kebab-case descriptive name
- 8-character hex suffix (generate randomly)

Location: `.cursor/plans/`

---

## Plan Type: TECHNICAL

Use when the plan has concrete implementation steps, file-level changes, and verifiable gates.

### YAML Todo Rules (Technical)

- **One todo per atomic subtask** — never group multiple steps into one todo
- **Hierarchical numbering** in todo IDs: `t{phase}-{group}-{step}` (e.g., `t1-1-1`, `t2-3-2`)
- **One todo per gate**: ID format `gate-p{phase}` (e.g., `gate-p1`, `gate-p3`)
- **Named gates** for significant checkpoints: `gate-delete-usage-service`, `gate-schema-verify`
- Content is a single quoted string — no block scalars needed
- No `dependencies` arrays — numbering implies execution order

```yaml
todos:
  # Phase 1 — Schema + Migration
  - id: t1-1-1
    content: "1.1.1 shared/db-schema.ts — rename billing_cycle_start → quota_cycle_anchor"
    status: pending
  - id: t1-1-2
    content: "1.1.2 shared/db-schema.ts — add billing_cycle_anchor (nullable timestamp, paid plans only)"
    status: pending
  - id: t1-2-1
    content: "1.2.1 npm run db:generate"
    status: pending
  - id: t1-2-2
    content: "1.2.2 npm run db:push:local"
    status: pending
  - id: gate-p1
    content: "Gate 1 — npx tsc --noEmit; psql \\d jbd_subscriptions | grep quota_cycle_anchor"
    status: pending

  # Phase 2 — Services
  - id: t2-1-1
    content: "2.1.1 openmeter-service.ts — add usagePeriod field to EntitlementBalance interface"
    status: pending
  - id: t2-2-1
    content: "2.2.1 stripe-service.ts (new) — getSubscriptionDetails(), getSubscriptionDates()"
    status: pending
  - id: gate-p2
    content: "Gate 2 — npx tsc --noEmit"
    status: pending
```

### Technical Plan Body Structure

Each phase uses this format:

```markdown
## Phase N — [Phase Name]

**Precondition:** [prior gate or "none"]

- **N.1** `path/to/file.ts`
  - N.1.1 [Specific change — field, function, constant, import]
  - N.1.2 [Specific change]
- **N.2** `path/to/other.ts`
  - N.2.1 [Specific change]

**Exit gate:**
```bash
[Verification command(s) — must be runnable, must produce observable output]
```
```

### Technical Plan Template

```markdown
---
name: [Plan Name]
overview: [One-sentence summary — what changes and why]
todos:
  # Phase 1 — [Name]
  - id: t1-1-1
    content: "1.1.1 [file] — [specific action]"
    status: pending
  - id: gate-p1
    content: "Gate 1 — [bash command]"
    status: pending
isProject: false
---

# [Plan Title]

[1-2 sentences: what this replaces/adds and the architectural principle driving it.]

## [Architecture Overview or Key Interfaces]

[Code block or table showing the new structure. Omit extensive rationale — the what/how/where matters more than the why.]

## [Route Map, DB Changes, Data Flow — as applicable]

[Mermaid diagram or table. Keep it concise.]

---

## Phase 1 — [Name]

**Precondition:** none

- **1.1** `path/file.ts`
  - 1.1.1 [Action]
  - 1.1.2 [Action]
- **1.2** [Command or step]
  - 1.2.1 [Action]

**Exit gate:**
```bash
npx tsc --noEmit
```

---

## Phase 2 — [Name]

**Precondition:** Phase 1 gate passes

- **2.1** `path/file.ts`
  - 2.1.1 [Action]
- **2.2** `path/other.ts` (new)
  - 2.2.1 [method()]
  - 2.2.2 [method()]

**Exit gate:**
```bash
npx tsc --noEmit
```

---

## Phase N — [Final Phase]

**Precondition:** All prior phases complete

- **N.1** [Final verification steps]

**Manual verification checklist:**
```bash
[E2E or integration test commands]
```

**Exit gate:**
```bash
[Final gate commands]
```
```

### Technical Plan Guidelines

- **Phases are sequential by precondition** — state explicitly which gate must pass first
- **Subtasks are file-level or command-level** — never vague ("update the service")
- **Gates must be runnable bash commands** that produce pass/fail output
- **Parallel work within a phase** is noted as "(parallel)" in the phase heading
- **New files** are marked `(new)` next to the path
- **Deleted files** get their own named gate: `gate-delete-{name}`
- **Ratio**: minimal rationale, maximum specificity (what file, what function, what value changes to what)

---

## Plan Type: STRATEGIC

Use when the plan captures initiative scope, milestones, or phased rollout at a feature level.

### YAML Todo Rules (Strategic)

- One todo per phase (grouped)
- IDs are descriptive slugs: `phase1-foundation`, `phase2-api`, `gate-phase1`
- Content is a short phrase describing the phase goal
- Gates are milestone-level, not bash commands

```yaml
todos:
  - id: phase1-schema
    content: "Phase 1: Database schema and migration"
    status: pending
  - id: phase1-gate
    content: "GATE 1: Schema deployed, tsc passes"
    status: pending
  - id: phase2-services
    content: "Phase 2: Service layer implementation"
    status: pending
  - id: phase2-gate
    content: "GATE 2: All endpoints return correct data"
    status: pending
```

### Strategic Plan Body Structure

```markdown
## Phase 1: [Phase Name]

**Goal:** [One sentence]

### Subtasks

- [ ] **1.1** [Task]
- [ ] **1.2** [Task]
- [ ] **1.G** GATE: [Milestone criteria]
```

### Strategic Plan Template

```markdown
---
name: [Plan Name]
overview: [One-sentence summary]
todos:
  - id: phase1-name
    content: "Phase 1: [Goal]"
    status: pending
  - id: gate-phase1
    content: "GATE 1: [Criteria]"
    status: pending
isProject: false
---

# [Plan Title]

> **Created:** YYYY-MM-DD

**Depends on:** [Plan or "None"]

## Overview

[2-3 sentences describing the problem and approach.]

### Current State

- [How things work today]

### New Mental Model

[Diagram or description of the new behavior.]

---

## Phase 1: [Name]

**Goal:** [One sentence]

### Subtasks

- [ ] **1.1** [Task]
- [ ] **1.2** [Task]
- [ ] **1.G** GATE: [Milestone verification]

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| [Problem] | [Solution] |

---

## Completion Checklist

- [ ] All phases complete
- [ ] All gates pass
- [ ] Plan moved to `completed/` folder
```

---

## Real-Time Update Rule (Both Types)

**Update the plan file before moving to the next subtask.**

- For technical plans: update todo `status` from `pending` → `in_progress` → `complete`
- For strategic plans: check `[ ]` boxes and update YAML `status`
- Never batch or defer updates

---

## Completed Plans

When a plan is complete:

1. Verify all gates pass
2. Move file to `.cursor/plans/archive/` folder
