---
name: tl-agent-plan-execute
description: Execute a verified plan document. Consumes verification receipts from tl-agent-plan-audit to avoid redundant re-verification. Defines the trust model, staleness protocol, and exit gate execution process. Use when executing a .plan.md file, starting plan implementation, or when the user says "implement the plan" or "execute the plan".
license: MIT
metadata:
  version: 1.0.0
  author: tl-agent-skills
  moment: implement
  surface:
    - repo
  output: implementation
  risk: medium
  effort: medium
  posture: autonomous
  agentFit: repo-write
  portability: high
  suite: tl-agent-plan
  related:
    - tl-agent-plan-create
    - tl-agent-plan-audit
---

# Execute Plan Document

Execute a `.plan.md` file that was created with `tl-agent-plan-create` and audited with `tl-agent-plan-audit`. This skill defines how an executor should consume verification metadata, decide what to trust vs. re-verify, and run exit gates.

## When to Use

- User says "implement the plan", "execute the plan", or "do it"
- A `.plan.md` file is attached or referenced
- Todos from a plan are already created and the user says to start

## Core Principle: Planning Work Must Compound

Plans and audits invest time verifying facts about the codebase. That investment is wasted if the executor re-verifies everything from scratch. The executor's job is to **implement**, not to re-plan.

**Preconditions are inputs verified during planning. Trust them.**
**Exit gates are outputs you produce. Always run them.**

---

## Plan-Level Status Transitions

The execute skill owns two transitions in the plan lifecycle:

```
planned → audited → building → built
                    ^^^^^^^^^   ^^^^^
                    executor     executor
```

| Transition | When | Action |
|---|---|---|
| `→ building` | First todo moves to `in_progress` | Update the plan file's YAML `status` field to `building` |
| `→ built` | All todos are `completed`, all exit gates pass | Update the plan file's YAML `status` field to `built` |

**These updates go in the plan's YAML frontmatter, not just in the agent's local todo list.** The plan file is the durable record. Update it alongside todo status changes.

If the plan file has no `status` field (older plan), add one and set it to `building` when execution starts.

---

## Step 0: Read the Plan and Assess Verification State

Before writing any code, read the plan's YAML frontmatter and classify it into one of three states:

### State A: Fully Verified Plan

The plan has both `verified_at_commit` and a populated `verifications:` array.

1. Run `git rev-parse --short HEAD` and compare to `verified_at_commit`.
2. **If they match**: trust all verification entries. Proceed directly to implementation. Do not re-run any verification commands.
3. **If they differ**: run `git log --oneline {verified_at_commit}..HEAD` to see what changed. Then:
   - For each verification entry, check if any of the changed commits touched files relevant to that claim. If not, trust the entry.
   - For entries where relevant files changed, re-run only those specific verification commands.
   - Log which entries were re-verified and which were trusted.

### State B: Partially Verified Plan

The plan has `verified_at_commit` but the `verifications:` array is missing or incomplete (some factual claims in the body lack corresponding entries).

1. Trust the entries that exist (applying the staleness check from State A).
2. For unverified factual claims, run a targeted check before acting on them. This is a planning process gap — note it but don't block on it.

### State C: Unverified Plan

The plan has no `verified_at_commit` and no `verifications:` array. It was created before verification requirements existed, or skipped auditing.

1. Perform minimal verification before each phase: confirm the files referenced in that phase exist and contain what the plan describes.
2. Do NOT exhaustively re-audit the plan. Execute the plan as written, and if you encounter a factual error (file doesn't exist, code doesn't match), fix the discrepancy locally and continue.

---

## Step 1: Execute Phases in Order

For each phase:

1. **Mark the phase todo as `in_progress` in both the agent's local todo list AND the plan file's YAML.** On the very first transition, also set the plan-level `status: building` in the YAML frontmatter.
2. **Read the precondition.** If it says "Phase N complete," verify the prior gate todo is marked `completed`. Do not re-run prior exit gates.
3. **Implement the subtasks** in the order specified by the plan. Follow the plan's specifics (file paths, function names, SQL, code snippets) as written. The plan is the authority.
4. **Run the exit gate.** Exit gates are the executor's responsibility — always run them, even for fully verified plans. Gates validate your work, not the plan's claims.
5. **Mark the gate todo as `completed`** in both the local todo list and the plan file's YAML, only after the gate passes.

### When the Plan Is Wrong

If implementation reveals the plan is incorrect (file was restructured, function signature changed, new dependency appeared):

1. **Fix it locally and continue.** Do not stop to re-audit the whole plan.
2. **If the error cascades** (affects multiple subsequent phases), pause and notify the user with a specific description of what changed and which phases are affected.
3. **Never silently deviate** from the plan. If you change the approach, state what you changed and why in your response to the user.

---

## Step 2: Run Exit Gates

Exit gates are runnable verification commands. Execute them exactly as written.

- **Build gates** (`pnpm build`, `npx tsc --noEmit`): run and confirm exit code 0.
- **Query gates** (`SELECT ...`, `\d tablename`): run and confirm the output matches the gate description.
- **Grep gates** (`rg 'pattern' path/`): run and confirm the expected result (e.g., "returns zero hits").
- **Manual verification gates** (e.g., "charts render correctly"): state what you verified and how.

If a gate fails, fix the issue before proceeding to the next phase.

---

## Step 3: Completion

When all phases and gates are complete:

1. Mark all remaining todos as `completed` in both the local todo list and the plan file's YAML.
2. Set the plan-level `status: built` in the plan file's YAML frontmatter.
3. Report a summary of what was implemented, organized by phase.
4. Note any deviations from the plan and why.

The plan file is the durable record of execution. The `status: built` field is what marks the plan as finished for any agent or human reviewing it later.

---

## Anti-Patterns

These are things the executor must NOT do:

| Anti-pattern | Why it's wrong | Instead |
|---|---|---|
| "Let me first check if X has any importers" when the plan says "X has zero importers" and `verifications:` confirms it | Wastes the planning investment | Trust the verification receipt |
| Re-reading every file the plan references before starting | Turns execution into a second audit | Trust the plan; read files only when you need context to implement |
| Running `rg` to "make sure" before each deletion | Redundant with verified scope checks | Trust `verifications:` for scope claims |
| Saying "I'll verify the current state of..." for something the plan already documents | Planning work doesn't compound | Act on the plan's documented state |
| Exhaustively re-auditing an unverified plan (State C) | The user asked you to execute, not audit | Do minimal per-phase checks and implement |
| Only updating the local todo list, not the plan file | The plan file is the durable record; local todos disappear between sessions | Update both: plan YAML `status` + todo statuses, and agent todo list |
| Leaving `status: building` after all work is done | Signals the plan is still in progress to other agents/humans | Set `status: built` when all gates pass |

---

## What the Executor IS Responsible For

- Running exit gates (these validate YOUR work)
- Fixing build errors, lint errors, and type errors introduced by your changes
- Notifying the user if the codebase has diverged enough that the plan is no longer viable
- Producing clean, working code that matches the plan's intent

---

## Trust Model Summary

| Artifact | Trust Level | Executor Action |
|---|---|---|
| Verified claim (in `verifications:`, commit matches) | Full trust | Proceed without checking |
| Verified claim (in `verifications:`, commit differs, no relevant changes) | Full trust | Proceed without checking |
| Verified claim (in `verifications:`, commit differs, relevant files changed) | Re-verify | Re-run that specific verification command |
| Factual claim in body (no `verifications:` entry) | Low trust | Quick check before acting |
| Plan body instructions (what to implement) | Authority | Follow as written |
| Exit gate criteria | Executor responsibility | Always run |
| Design decisions (`> Decision:` lines) | Full trust | Follow as written |
