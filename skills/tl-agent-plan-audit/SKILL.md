---
name: tl-agent-plan-audit
description: Audit plan documents before execution. Validates structural compliance, plan integrity, and verification metadata against tl-agent-plan-create, then performs Principal Engineer critique, Pre-Mortem simulation, Parallelization review, and Implementation Readiness analysis. Produces durable verification receipts so executors can trust factual claims without re-verification. Use when the user says "audit this plan", "review the plan", or before starting plan execution.
license: MIT
metadata:
  version: 1.5.0
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
    - tl-agent-plan-execute
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

> See [Structural Compliance Rules](references/structural-compliance-rules.md) for the full 9-step mechanical validation procedure (plan-type detection, frontmatter checks, todo structure, phase/gate completeness, body/YAML cross-reference, specificity, decision resolution, plan integrity, verification metadata compliance).

This analysis MUST always produce a "Structural Compliance" section in the audit output. If all checks pass, write "All 9 structural checks pass." If any fail, list each violation numbered.

Read the rules file first, then execute its 9 steps in order against the target plan. The validation is mechanical — no judgment calls.


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
- Unresolved "Option A / Option B" alternatives → research codebase, apply first principles, commit to one approach

**Implementation unknowns**: If a plan modifies a file but doesn't document the current signature/shape, add an "Implementation Context" section with those facts. This is an obvious fix — perform the pre-reads and add the results to the plan.

**Integrity violations (Steps 8-9)**: These are always obvious fixes — apply directly:
- Stale file path → verify and correct or remove the reference
- Wrong line number → read the file, update to the actual line
- YAML/body inconsistency → update the YAML todo text to match the body
- Missing files from scope → grep, find the consumers, add them to the plan
- Exit gate example values that don't match actual output → correct the examples
- Missing cross-section rationale → read both sections, add a `> Decision:` note explaining the difference
- Missing `verified_at_commit` → run `git rev-parse --short HEAD` and add it
- Missing or incomplete `verifications:` array → run the verification commands from Step 8b and produce the block
- Stale verification results → re-run the command, update the result, flag if the claim changed

**Non-obvious decisions**: Probe, ask questions, propose with rationale. Examples:
- Reordering phases (may have unstated reasons)
- Removing scope (user may have context you don't)
- Architectural changes
- Adding significant new work
- Alternatives where both approaches have legitimate first-principles arguments and codebase evidence is ambiguous → ask the user

## Output Format

> See [Output Format Template](references/output-format-template.md) for the complete audit report template (Summary, Findings grouped by subject area, Parallelization, Critical path, Agent allocation, Recommendations list).

Produce a unified audit report. Group findings by **subject matter** (e.g., by phase, by system component, by risk area) — NOT by audit type.

## After the Audit

**Update plan-level status.** If the verdict is "Ready to execute," set the plan's YAML frontmatter `status` field to `audited`. This signals to `tl-agent-plan-execute` that the plan has been reviewed and its verification receipts are trustworthy. If the verdict is "Changes recommended" or "Rework needed," leave `status` as `planned` until the revisions are applied and the plan is re-audited.

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

> See [Example Subject Groupings](references/example-subject-groupings.md) for guidance on organizing findings (by phase, by system component, by risk category, or by execution concern).

Choose the grouping that minimizes redundancy for the specific plan being audited.
