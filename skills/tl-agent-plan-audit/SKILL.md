---
name: tl-agent-plan-audit
description: Audit plan documents before execution. Validates structural compliance against tl-agent-plan-create, then performs Principal Engineer critique, Pre-Mortem simulation, Parallelization review, and Implementation Readiness analysis as a unified audit. Use when the user says "audit this plan", "review the plan", or before starting plan execution.
license: MIT
metadata:
  version: 1.2.0
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

Unified audit workflow for `.plan.md` files. Validates structural compliance against the `tl-agent-plan-create` specification, then combines critique, pre-mortem simulation, parallelization review, and implementation readiness analysis into a single cohesive audit.

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

Run Analysis 0 first — it is mechanical validation that reads the plan and produces numbered findings. Then perform Analyses 1–4 mentally and merge all findings into a **unified output** grouped by subject matter. Do NOT reveal the analysis numbering to the user.

### Analysis 0: Structural Compliance

Validate the plan against the `tl-agent-plan-create` specification before evaluating quality. This is not a judgment call — it is mechanical validation that produces observable output.

**This analysis MUST always produce a "Structural Compliance" section in the audit output.** If all checks pass, write "All 6 structural checks pass." If any fail, list each violation numbered.

Execute these steps in order. For each step, read the actual plan content and report what you find.

**Step 1 — Determine plan type.** Read the YAML `todos` array. If todo IDs match `t{p}-{g}-{s}` format (e.g., `t1-1-1`), classify as **technical**. If todo IDs are descriptive slugs (e.g., `phase1-foundation`), classify as **strategic**. If the format is mixed or unrecognizable, report: "VIOLATION 1: Cannot determine plan type — todo IDs use inconsistent format." State the classification in the output.

**Step 2 — Check YAML frontmatter.** Read the frontmatter and verify each required field exists:
1. `name` — present or missing?
2. `overview` — present or missing?
3. `todos` (must be a non-empty array) — present, empty, or missing?
4. `isProject` — present or missing?
5. File name — does it match `{descriptive-name}-{8-char-hex}.plan.md`?

List each field with its status. Report any missing field as a numbered violation.

**Step 3 — Validate todo structure.** Read every todo in the YAML array. For each todo, verify:

For technical plans:
1. ID matches `t{phase}-{group}-{step}` format (e.g., `t1-1-1`, `t2-3-2`)
2. Content describes exactly one atomic subtask (not multiple steps joined by "and" or semicolons)
3. Gate todos use `gate-p{N}` or `gate-{descriptive-name}` format
4. Count distinct phase numbers in todo IDs. Each phase must have at least one gate todo.

For strategic plans:
1. IDs are descriptive slugs: `phase1-foundation`, `gate-phase1`
2. One todo per phase (not per subtask)
3. Gate content describes milestone criteria, not bash commands

Report each malformed todo ID or missing gate as a numbered violation.

**Step 4 — Check phase/gate completeness.** Count the `## Phase` headings in the plan body. For each phase, verify:
1. A `**Precondition:**` line exists (technical) or a `**Goal:**` line exists (strategic)
2. An `**Exit gate:**` section exists with a runnable command (technical) or milestone criteria (strategic)
3. The phase count in the body matches the phase count implied by todo IDs

Report each missing element as a numbered violation.

**Step 5 — Cross-reference body and YAML.** Count todos in the YAML (excluding gates). Count subtasks in the body (the numbered items under each phase). Compare:
1. Do the counts match? If not, list the difference.
2. Does the numbering in todo `content` fields (e.g., "1.1.1") match the body numbering (e.g., "- 1.1.1 [Action]")? List any mismatches.
3. Are there orphaned todos (in YAML but not referenced in body)? List them.
4. Are there orphaned subtasks (in body but no corresponding YAML todo)? List them.

Report each mismatch as a numbered violation.

**Step 6 — Check specificity.** Read each subtask in the body. Verify:
1. It references a concrete file path or runnable command — not vague phrases like "update the service" or "fix the issue"
2. New files are marked `(new)` next to the path
3. Files to be deleted have a corresponding named gate: `gate-delete-{name}`

Report each vague subtask or missing marker as a numbered violation.

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
- Missing `isProject` field in frontmatter → add it
- Todo IDs not matching convention → reformat to `t{p}-{g}-{s}` or slug style
- Missing `Precondition:` or `Exit gate:` in a phase → add skeleton
- Body/YAML numbering mismatch → reconcile

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
