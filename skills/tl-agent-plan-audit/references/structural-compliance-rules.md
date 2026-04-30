# Analysis 0: Structural Compliance Rules

> Loaded on-demand by `tl-agent-plan-audit` to perform Step 0 mechanical validation. See `../SKILL.md` for the parent skill.

Validate the plan against the `tl-agent-plan-create` specification before evaluating quality. This is not a judgment call — it is mechanical validation that produces observable output.

**This analysis MUST always produce a "Structural Compliance" section in the audit output.** If all checks pass, write "All 9 structural checks pass." If any fail, list each violation numbered.

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

**Step 7 — Decision Resolution.** Scan the entire plan body for unresolved decision markers. This is mechanical detection followed by active resolution.

**Detection:** Search for these patterns in the plan body:
- "Option A" / "Option B" or "Approach 1" / "Approach 2"
- "Alternatively" / "Another approach"
- "Either...or..." presenting uncommitted choices
- "Could also" / "We might" / "One way... another way"
- Paragraphs of 3+ sentences that explain context or trade-offs without concluding with a numbered subtask

Report each instance as a numbered violation.

**Resolution (auto-fix):** For each unresolved decision found:
1. Read the relevant codebase files to understand existing patterns and conventions
2. Apply first principles (separation of concerns, SSOT, information hiding, composition over inheritance)
3. Choose the approach that is most consistent with existing architecture, most structurally sound, and most forward-thinking
4. Replace the alternatives block with a single committed approach and a `> Decision:` rationale line
5. If genuinely unable to resolve after codebase research, escalate to the user as a non-obvious decision — never leave it unresolved in the plan

**Step 8 — Plan Integrity Verification.** This step catches errors that slip past structural and decision-resolution checks. It verifies that the plan's claims are internally consistent, factually accurate, and complete in scope.

**8a. Internal consistency.** Compare the YAML `todos` section against the plan body:
1. Does each todo's `content` text accurately summarize what the body describes for that phase? If a todo says "keep fallback" but the body says "throw on unknown," that is a violation.
2. Do exit gate descriptions in the body match any gate criteria stated in the YAML?
3. Do phase preconditions form a consistent DAG? (e.g., Phase 4 says "Precondition: Phase 2" but Phase 3 also depends on Phase 2's output — is the ordering correct?)

Report each inconsistency as a numbered violation.

**8b. Factual accuracy and verification receipts.** For every file path, line number, and code snippet the plan cites as "current state":
1. Read the file. Does it exist? If not, report: "VIOLATION: Plan references [path] which does not exist."
2. Does the cited line number match the actual content? If the plan says "line 283" but the content is at line 310 (or the file has fewer lines), report the discrepancy.
3. Does any "current state" code snippet match what is actually in the file? If the plan shows code that has already been changed by a prior plan or migration, report it as stale.

This is not optional — every file reference must be spot-checked. For plans with 10+ file references, check at minimum: all files in the first phase, all files in the last phase, and any file referenced in multiple phases.

Report each inaccuracy as a numbered violation.

**Producing verification receipts:** After completing all 8b checks, update the plan's YAML frontmatter:
1. Set `verified_at_commit` to the current `git rev-parse --short HEAD`.
2. For every factual claim verified during this step (existence checks, importer counts, line number confirmations, scope greps from 8c), add or update an entry in the `verifications:` array with `claim`, `command`, and `result` fields.
3. If the plan already has a `verifications:` array from the planner, re-run each listed verification command and update the `result` if it has changed. Flag any changed results as violations.

The goal: after this audit, the `verifications:` block is a complete, current record of every factual claim in the plan. An executor reading this block can trust verified claims without re-running the checks, as long as `verified_at_commit` matches their HEAD.

**8c. Scope completeness.** For every structural change (column drop, constant rename, type deletion, interface change):
1. Grep the codebase for ALL consumers of the thing being changed — not just the ones the plan lists.
2. Compare the grep results against the plan's file list. Any file that references the changed entity but is not in the plan is a violation.
3. Check frontend, backend, scripts, tests, i18n files, and type definition files — not just the primary app code.

Example: if the plan drops column `bounced` from a table, grep for `bounced` across the entire codebase. Every file that references it must appear in the plan or in a "no change needed" note with rationale.

Report each missing file as a numbered violation.

**8d. Cross-section coherence.** Scan for apparent contradictions between plan sections:
1. If one phase adopts a "fail hard" philosophy (throw on unknown) and another phase uses a fallback/default for a similar concept, the plan must include an explicit rationale explaining why the philosophy differs. Absence of that rationale is a violation.
2. If the plan says "no change needed" for a file in one section but modifies a related file that would break it, flag the dependency.
3. If exit gate criteria use example values (e.g., "logs show `opened`"), verify those examples match the actual output the code would produce.

Report each unresolved contradiction as a numbered violation.

**Step 9 — Verification Metadata Compliance.** Check that the plan meets the verification requirements from `tl-agent-plan-create`:

1. Does the YAML frontmatter contain `verified_at_commit`? If missing, this is a violation.
2. Does the YAML frontmatter contain a `verifications:` array? If missing, this is a violation.
3. For each factual claim in the plan body (existence assertions, importer counts, "always null" claims, scope claims like "only these N files reference X"), is there a corresponding entry in `verifications:`? List any unverified claims as violations.
4. For each entry in `verifications:`, does the `command` field contain a runnable command (not prose), and does the `result` field contain the actual output (not a prediction)?

If the `verifications:` block is absent or incomplete, this is an auto-fixable violation: run the checks as part of Step 8b and produce the block.
