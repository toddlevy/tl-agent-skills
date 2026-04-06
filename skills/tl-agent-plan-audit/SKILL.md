---
name: tl-agent-plan-audit
description: Audit plan documents before execution. Performs Principal Engineer critique, Pre-Mortem simulation, Parallelization review, and Implementation Readiness analysis as a unified audit. Use when the user says "audit this plan", "review the plan", or before starting plan execution.
license: MIT
metadata:
  version: 1.0.0
  author: tl-agent-skills
  moment: review
  surface:
    - repo
  output: analysis
  risk: low
  effort: low
  posture: guided
  agentFit: chat-only
  portability: high
  suite: tl-agent-plan
  related:
    - tl-agent-plan-create
---

# Plan Audit

Unified audit workflow for `.plan.md` files. Combines critique, pre-mortem simulation, parallelization review, and implementation readiness analysis into a single cohesive audit.

## When to Use

- User says "audit this plan" or "review the plan"
- Before starting execution of a plan
- User asks to optimize a plan for efficiency
- User wants a pre-mortem or critique

## Outcomes

- **Analysis**: Unified audit report with findings grouped by subject matter
- **Decision**: Verdict (Ready to execute | Changes recommended | Rework needed)
- **Artifact**: Actionable recommendations for plan revision

## Audit Process

Perform all four analyses mentally, then produce a **unified output** grouped by subject matter. Do NOT reveal the four-phase structure to the user.

### Analysis 1: Principal Engineer Critique

Evaluate:

- **Clarity**: Is the goal unambiguous? Are subtasks atomic and verifiable? Will another engineer understand this?
- **Risk**: What could fail? Are failure modes addressed? Hidden assumptions?
- **Sequencing**: Is the order optimal? Unnecessary dependencies? Could earlier phases de-risk later ones?
- **Leverage**: What has highest impact-to-effort ratio? Are high-leverage tasks front-loaded?

### Analysis 2: Pre-Mortem Simulation

Mentally execute the plan start-to-finish. For each subtask, identify:

- Hidden subtasks (unstated work required)
- Dependencies (what must exist before this can start)
- Bottlenecks (where things will slow down)
- Failure points (what's most likely to go wrong)

### Analysis 3: Parallelization Review

Identify:

- Independent tasks (no dependencies between them)
- Parallel agent opportunities (multiple agents working simultaneously)
- Blocking paths (what MUST be sequential)
- Specific agent allocation recommendations

### Analysis 4: Implementation Readiness

For EVERY file the plan modifies, creates, or deletes, perform exhaustive pre-reads and document:

- **Signatures**: Exact function signatures with parameter types, return types, and line numbers. Not summaries — the actual code.
- **Import graph**: Every file that currently imports the target. Every import the target file has that may break. Exact file paths and line numbers.
- **Call sites**: The exact lines where changes hook in. If the plan says "add externalIdService.link after upsert", the audit must show the upsert call and its surrounding context.
- **API surface**: For route handlers, the exact request schema (query params, body shape) and response shape today.
- **Job handler shape**: For job files, what `job.data` looks like today and whether it is currently used or ignored (`_job` pattern).
- **State of the world**: Which planned deletions/creations overlap with work already done in prior plans? Which files have already been deleted?

The standard is: an implementor should be able to execute the plan start-to-finish without a single exploratory file read. Every fact needed is either in the plan body or in a code reference within the Implementation Context section.

Red flags that MUST be caught:
- Plan says "modify X.ts" but doesn't include X's current function signature
- Plan says "delete Y.ts" without listing every file that imports Y
- Plan says "extend endpoint Z" without stating Z's current query params and response shape
- Plan says "replace CONSTANT" without listing every file that imports it
- Plan says "add after upsert" without showing the upsert call site with surrounding context
- Plan says "accept NewPayload" but target already has a different options type (naming conflict)

## Adaptive Depth

Scale analysis depth to plan complexity:

| Plan Size | Risk Level | Analysis Depth |
|-----------|------------|----------------|
| Small (1-2 phases) | Low | Brief findings, focus on blockers only |
| Medium (3-4 phases) | Medium | Standard analysis, all major findings |
| Large (5+ phases) | High | Detailed analysis, every subtask reviewed |

| Any size | Any risk | If plan modifies 5+ files: require Implementation Readiness analysis |

**Risk multipliers**: External integrations, data migrations, auth/security, billing = deeper analysis regardless of size.

## Smart Auto-Fix Rule

**Obvious improvements**: Apply directly without asking. Examples:
- Missing gate criteria → add specific verification
- Vague subtask → make atomic
- Missing dependencies → add them
- Parallelizable tasks not marked → add parallelization notes

**Implementation unknowns**: If a plan modifies a file but doesn't document the current signature/shape, add an "Implementation Context" section with those facts. This is an obvious fix — perform the pre-reads and add the results to the plan.

**Non-obvious decisions**: Probe, ask questions, propose with rationale. Examples:
- Reordering phases (may have unstated reasons)
- Removing scope (user may have context you don't)
- Architectural changes
- Adding significant new work

## Output Format

Produce a unified audit report. Group findings by **subject matter** (e.g., by phase, by system component, by risk area) — NOT by audit type.

```markdown
# Plan Audit: [Plan Name]

## Summary

[2-3 sentences: Overall assessment, biggest risk, key recommendation]

**Verdict**: [Ready to execute | Changes recommended | Rework needed]

---

## Findings

### [Subject Area 1: e.g., "Phase 1: Database Setup"]

**Issues**:
- [Finding with analysis]
- [Finding with analysis]

**Recommendations**:
- [Specific fix]

---

### [Subject Area 2: e.g., "Cross-Phase Dependencies"]

**Issues**:
- [Finding with analysis]

**Recommendations**:
- [Specific fix]

---

### [Subject Area N: e.g., "Execution Strategy"]

**Parallelization opportunities**:
- Tasks X and Y can run in parallel (no dependencies)
- Phase 2 exploration work: spawn 2 agents

**Critical path**:
- Task A → Task B → Task C (blocking, ~60% of timeline)

**Agent allocation**:
```
Agent 1: Tasks 1.1, 1.3, 2.1 (critical path)
Agent 2: Tasks 1.2, 2.2, 2.3 (parallel work)
```

---

## Recommendations

Actionable list for plan revision:

1. **[Action]** — [Brief rationale]
2. **[Action]** — [Brief rationale]
3. **[Action]** — [Brief rationale]
...
```

## After the Audit

If verdict is "Changes recommended":

```
Audit complete. I've identified [N] changes.

[If any are obvious fixes]: I can apply items 1, 3, 5 directly — they're straightforward improvements.

[If any need discussion]: Items 2, 4 involve trade-offs. Want me to elaborate on any before proceeding?

Ready to revise the plan?
```

If verdict is "Ready to execute":

```
Plan looks solid. Minor suggestions in the findings, but nothing blocking.

Ready to start execution?
```

## Branch Workflow Check

Before execution begins, ask about branching strategy if not already specified in the plan:

```
prompt: "Should this work be done in a feature branch?"
options:
  - id: yes_branch
    label: "Yes - create a feature branch (e.g., feat/plan-name)"
  - id: no_branch
    label: "No - work directly on current branch"
  - id: already_specified
    label: "Already specified in plan"
```

If yes:
1. Add a "create-branch" task as the first todo
2. Add a "Branch" section at the top of the plan body
3. Add commit/push instructions at the end
4. Suggest branch name based on plan name (e.g., `feat/embedded-checkout`)

## Example Subject Groupings

Group findings by whatever makes the content clearest:

**By phase** (most common):
- Phase 1: Schema Design
- Phase 2: API Implementation
- Phase 3: Frontend Integration

**By system component**:
- Database Layer
- API Routes
- Authentication
- Frontend

**By risk category**:
- Data Integrity Risks
- Integration Risks
- Performance Risks

**By execution concern**:
- Sequencing Issues
- Missing Dependencies
- Parallelization Opportunities

Choose the grouping that minimizes redundancy for the specific plan being audited.
