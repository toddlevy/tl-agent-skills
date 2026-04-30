# Technical Plan Template

> Loaded on-demand by `tl-agent-plan-create` when authoring a Technical plan. See `../SKILL.md` for the parent skill.

Use when the plan has concrete implementation steps, file-level changes, and verifiable gates.

## YAML Todo Rules (Technical)

- **One todo per atomic subtask** — never group multiple steps into one todo
- **Hierarchical numbering** in todo IDs: `t{phase}-{group}-{step}` (e.g., `t1-1-1`, `t2-3-2`)
- **One todo per gate**: ID format `gate-p{phase}` (e.g., `gate-p1`, `gate-p3`)
- **Named gates** for significant checkpoints: `gate-delete-usage-service`, `gate-schema-verify`
- No `dependencies` arrays — numbering implies execution order
- **Content must be plain ASCII safe for YAML** — Cursor's frontmatter parser is fragile. Content strings must never contain backticks, colons, curly braces, square brackets, or wrapping quotes. Use em-dash (—) to separate file from action. Use "line N" instead of `file.ts:N`. Describe code changes in plain words instead of code syntax (e.g., "add tags contacts to payload" not "add { tags: ['contacts'] } to payload").

```yaml
todos:
  # Phase 1 — Schema + Migration
  - id: t1-1-1
    content: 1.1.1 shared/db-schema.ts — rename billing_cycle_start to quota_cycle_anchor
    status: pending
  - id: t1-1-2
    content: 1.1.2 shared/db-schema.ts — add billing_cycle_anchor nullable timestamp for paid plans
    status: pending
  - id: t1-2-1
    content: 1.2.1 npm run db generate
    status: pending
  - id: t1-2-2
    content: 1.2.2 npm run db push local
    status: pending
  - id: gate-p1
    content: Gate 1 — typecheck passes and quota_cycle_anchor column exists
    status: pending

  # Phase 2 — Services
  - id: t2-1-1
    content: 2.1.1 openmeter-service.ts — add usagePeriod field to EntitlementBalance interface
    status: pending
  - id: t2-2-1
    content: 2.2.1 stripe-service.ts (new) — getSubscriptionDetails and getSubscriptionDates
    status: pending
  - id: gate-p2
    content: Gate 2 — typecheck passes
    status: pending
```

## Technical Plan Body Structure

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

## Technical Plan Template

```markdown
---
name: [Plan Name]
overview: [One-sentence summary — what changes and why]
todos:
  # Phase 1 — [Name]
  - id: t1-1-1
    content: 1.1.1 [file] — [specific action in plain ASCII]
    status: pending
  - id: gate-p1
    content: Gate 1 — [verification criteria in plain words]
    status: pending
isProject: false
---

# [Plan Title]

## Plan Metadata

| Field | Value |
|-------|-------|
| Status | planned |
| Verified at | `[short SHA]` |

### Verifications

| Claim | Command | Result |
|-------|---------|--------|
| [Factual claim made in the plan body] | `[Exact command that was run to verify]` | [Observed output] |

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

## Technical Plan Guidelines

- **Phases are sequential by precondition** — state explicitly which gate must pass first
- **Subtasks are file-level or command-level** — never vague ("update the service")
- **Gates must be runnable bash commands** that produce pass/fail output
- **Parallel work within a phase** is noted as "(parallel)" in the phase heading
- **New files** are marked `(new)` next to the path
- **Deleted files** get their own named gate: `gate-delete-{name}`
- **Ratio**: minimal rationale, maximum specificity (what file, what function, what value changes to what)
- **Every subtask is an action, not a narrative** — no prose explanation blocks; context goes in a brief section header, actions go in numbered subtasks
