# Strategic Plan Template

> Loaded on-demand by `tl-agent-plan-create` when authoring a Strategic plan. See `../SKILL.md` for the parent skill.

Use when the plan captures initiative scope, milestones, or phased rollout at a feature level.

## YAML Todo Rules (Strategic)

- One todo per phase (grouped)
- IDs are descriptive slugs: `phase1-foundation`, `phase2-api`, `gate-phase1`
- Content is a short phrase describing the phase goal
- Gates are milestone-level, not bash commands
- **Content must be plain ASCII safe for YAML** — same sanitization rules as Technical todos. No backticks, colons, curly braces, square brackets, or wrapping quotes.

```yaml
todos:
  - id: phase1-schema
    content: Phase 1 — Database schema and migration
    status: pending
  - id: phase1-gate
    content: GATE 1 — Schema deployed, tsc passes
    status: pending
  - id: phase2-services
    content: Phase 2 — Service layer implementation
    status: pending
  - id: phase2-gate
    content: GATE 2 — All endpoints return correct data
    status: pending
```

## Strategic Plan Body Structure

```markdown
## Phase 1: [Phase Name]

**Goal:** [One sentence]

### Subtasks

- [ ] **1.1** [Task]
- [ ] **1.2** [Task]
- [ ] **1.G** GATE: [Milestone criteria]
```

## Strategic Plan Template

```markdown
---
name: [Plan Name]
overview: [One-sentence summary]
todos:
  - id: phase1-name
    content: Phase 1 — [Goal]
    status: pending
  - id: gate-phase1
    content: GATE 1 — [Criteria]
    status: pending
isProject: false
---

# [Plan Title]

## Plan Metadata

| Field | Value |
|-------|-------|
| Status | planned |
| Verified at | `[short SHA]` |
| Created | YYYY-MM-DD |
| Depends on | [Plan or None] |

### Verifications

| Claim | Command | Result |
|-------|---------|--------|
| [Factual claim] | `[Verification command]` | [Observed output] |

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
