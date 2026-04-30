---
name: tl-agent-plan-create
description: Create structured plan documents for features, projects, or multi-phase tasks. Includes YAML frontmatter, strategic/technical templates, phases, gates, and real-time update requirements.
license: MIT
metadata:
  version: 1.4.1
  author: Todd Levy <toddlevy@gmail.com>
  homepage: https://github.com/toddlevy/tl-agent-skills
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
    - tl-agent-plan-execute
---

<!-- Copyright (c) 2026 Todd Levy. Licensed under MIT. SPDX-License-Identifier: MIT -->

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

### Question 0: Plan Type (ask this FIRST â€” it determines everything else)

```
prompt: "Is this a strategic plan or a technical plan?"
options:
  - id: strategic
    label: "Strategic â€” high-level phases, milestones, grouped todos (e.g. roadmap, initiative overview)"
  - id: technical
    label: "Technical â€” granular subtasks, one todo per step, programmatic gates (e.g. implementation, refactor)"
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

## CreatePlan Tool Invocation Contract

> See [CreatePlan Invocation Contract](references/tool-invocation-contract.md) for the full rules on how to call the `CreatePlan` tool, including correct/incorrect examples and the duplicate-frontmatter failure mode.

The single most important rule: **the `plan` argument MUST begin with the H1 heading (`# Plan Title`) and MUST NOT contain a `---` frontmatter fence.** The tool generates frontmatter from the `todos` argument and prepends it.

---

## Plan Type: TECHNICAL

Use when the plan has concrete implementation steps, file-level changes, and verifiable gates.

> See [Technical Plan Template](references/technical-plan-template.md) for the full YAML todo rules, body structure, complete plan template, and authoring guidelines.

Key constraints at a glance:

- One todo per atomic subtask, IDs `t{phase}-{group}-{step}`, gates `gate-p{N}` or `gate-{descriptive-name}`
- Plain ASCII todo content (no backticks, colons, braces, brackets, wrapping quotes)
- Phases sequenced by precondition; gates are runnable bash commands

---

## Decision Resolution Rule (Both Types)

Plans must contain resolved decisions, not open questions. If the planner encounters multiple valid approaches, they must:

1. Read the codebase to understand existing patterns and conventions
2. Apply first principles (separation of concerns, SSOT, information hiding â€” reference `tl-first-principles` if available)
3. Evaluate which approach is most structurally sound, forward-thinking, and consistent with the existing architecture
4. Commit to one approach in the plan with a one-line rationale

**Banned patterns** â€” plans must never contain:

*Unresolved alternatives:*
- "Option A / Option B" or "Approach 1 / Approach 2"
- "Alternatively..." or "Another approach would be..."
- "Either...or..." presenting uncommitted choices
- "Could also..." or "We might..."
- Prose paragraphs explaining trade-offs without a conclusion
- Narrative context blocks where a numbered subtask should be

*Soft hedges and deferred specificity:*
- "or equivalent" / "or similar" â€” name the exact command, file, or tool
- "approximately" / "around line ~N" / "(line ~283)" â€” verify and state the exact line number, or omit it
- "should be" / "will likely" / "probably" â€” confirm by reading the code, then state what IS
- "update the relevant files" / "fix any remaining references" â€” list every file explicitly
- "if needed" / "as necessary" / "when applicable" â€” decide now whether it is needed and state yes or no
- "run it manually" appearing alongside an automatic path without choosing one â€” pick one approach

*Factual claims that must be verified before writing:*
- Every file path referenced in the plan must exist (check before writing)
- Every line number cited must be current (read the file before citing)
- Every code snippet shown as "current state" must match the actual file
- YAML todo `content` fields must not contradict the plan body (e.g., todo says "keep fallback" but body says "throw")

---

## Verification Requirements

> See [Verification Requirements](references/verification-requirements.md) for the full rules on what requires a verification receipt, the entry format, the `Verified at` field, and what does NOT require verification.

Every factual claim a plan makes about the codebase (file existence, importer counts, "always null" claims, scope greps, line number citations) must produce a row in the `### Verifications` table inside the `## Plan Metadata` section of the plan body. Verification metadata MUST NOT go in the YAML frontmatter.

---

## Plan Type: STRATEGIC

Use when the plan captures initiative scope, milestones, or phased rollout at a feature level.

> See [Strategic Plan Template](references/strategic-plan-template.md) for the full YAML todo rules, body structure, and complete plan template.

Key constraints at a glance:

- One todo per phase (grouped), IDs are descriptive slugs (`phase1-foundation`, `gate-phase1`)
- Content is a short phrase describing the phase goal; gates are milestone-level (not bash)
- Plain ASCII todo content (same sanitization as Technical)

---

## Plan-Level Status Lifecycle

The `Status` row in the `## Plan Metadata` table tracks the plan's overall state. This is separate from individual todo statuses. Status MUST NOT go in YAML frontmatter.

```
planned â†’ audited â†’ building â†’ built
```

| Status | Set by | Meaning |
|---|---|---|
| `planned` | `tl-agent-plan-create` | Plan is written. Todos are all `pending`. |
| `audited` | `tl-agent-plan-audit` | Plan passed audit. Verifications table is populated. |
| `building` | `tl-agent-plan-execute` | Execution has started. At least one todo is `in_progress`. |
| `built` | `tl-agent-plan-execute` | All todos are `completed` and all exit gates pass. |

The executor MUST update the `Status` row in the Plan Metadata table at the appropriate transitions. This is what makes the plan visible as actively being worked on or finished.

---

## Real-Time Update Rule (Both Types)

**Update the plan file before moving to the next subtask.**

- For technical plans: update todo `status` from `pending` â†’ `in_progress` â†’ `complete`
- For strategic plans: check `[ ]` boxes and update `Status` in the Plan Metadata table
- Never batch or defer updates

---

## Completed Plans

When a plan is complete:

1. Verify all gates pass
2. Set `Status` to `built` in the Plan Metadata table
3. Move file to `.cursor/plans/archive/` folder
