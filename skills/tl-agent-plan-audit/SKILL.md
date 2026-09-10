---
name: tl-agent-plan-audit
description: Audit plan documents before execution. Validates structural compliance, plan integrity, and verification metadata against tl-agent-plan-create, then performs Principal Engineer critique, Pre-Mortem simulation, Parallelization review, Implementation Readiness analysis, Ceremony Survival analysis (whether a plan survives the release/deploy/migration ceremony that ships it, not just whether its code is correct), and Premise Verification (every factual claim the plan rests on is probed with a read-only command BEFORE the verdict, so a wrong premise becomes an audit finding instead of a mid-build tripwire). Produces durable verification receipts so executors can trust factual claims without re-verification. Use when the user says "audit this plan", "review the plan", or before starting plan execution.
license: MIT
metadata:
  version: 1.17.0
  author: Todd Levy <toddlevy@gmail.com>
  homepage: https://github.com/toddlevy/tl-agent-skills
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

<!-- Copyright (c) 2026 Todd Levy. Licensed under MIT. SPDX-License-Identifier: MIT -->

# Plan Audit

Unified audit workflow for `.plan.md` files. Validates structural compliance against the `tl-agent-plan-create` specification, then combines critique, pre-mortem simulation, parallelization review, implementation readiness analysis, ceremony-survival analysis, and premise verification into a single cohesive audit.

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

Run Analysis 0 first — it is mechanical validation that reads the plan and produces numbered findings. Then perform Analyses 1–5 mentally, run the Analysis 6 probes for real, and merge all findings into a **unified output** grouped by subject matter. Do NOT reveal the analysis numbering to the user.

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

### Analysis 5: Ceremony Survival

Analyses 1–4 audit whether the plan is **correct** — clear, de-risked, parallelized, and readable start-to-finish. They do NOT audit whether the plan **survives the ceremony that ships it**. A plan can pass every prior analysis and still detonate mid-release, mid-deploy, or mid-migration on an auth/toolchain/environment/permission fact the plan never modeled — because that fact lives in the delivery pipeline, not in the code the plan edits. This analysis exists for exactly that gap, and it applies to any plan whose delivery touches a **ceremony**: a release/publish, a deploy, a data migration, a package/registry install, a credential rotation, an infra provisioning step, or any multi-actor hand-off.

If the plan has no such ceremony (a pure local refactor with no delivery step), state that in one line and skip the rest of this analysis.

Otherwise, answer these questions and treat any "unknown / proven only DURING the ceremony" as a **blocking finding**:

- **New seams.** What auth, toolchain-version, environment-variable, filesystem-permission, or external-service seam does this plan newly exercise, cross, or depend on when it ships — that the pre-ship checks do NOT already exercise? Name each one.
- **Proof timing.** For each seam: is it proven **BEFORE** the point of no return (before the tag/merge/deploy/irreversible mutation), or is the ceremony itself the first thing to exercise it? "The pre-flight/simulation is green" is NOT proof unless the pre-flight exercises the seam **through the same path the real ceremony uses**. A simulation that stubs, mocks, or short-circuits the seam (local tarballs instead of a registry fetch, a fake token, a skipped install path, an in-memory adapter) is **structurally blind** to that seam and its green says nothing.
- **Path divergence.** Does the pre-ship proof take a DIFFERENT code path than the real ceremony? (e.g. the simulation installs via a bare `spawn`, but the real run goes through a wrapper that sanitizes the environment; the CI uses one credential injection, the local run another.) A divergent path is a false green — flag it.
- **Point of no return.** Where is the irreversible step (tag pushed, package published, `main` fast-forwarded, prod row mutated, DNS cut over)? Is every seam proven strictly before it? A seam first exercised AFTER the point of no return converts a cheap pre-fail into an expensive mid-ceremony diagnosis.
- **Gate vs. doc.** For each seam the plan relies on being healthy: is the check a **fail-closed gate** (a script whose non-zero exit blocks the ceremony), or is it PROSE in a runbook the operator must remember to run? Knowledge that lives only in a doc is not prophylaxis — it is a checklist item waiting to lapse. If the plan's safety rests on "the operator will run X first," that is a finding: the plan should make X a gate, or the audit should note the residual risk explicitly.
- **Recurrence class.** If this project keeps a failure-mode / incident catalogue, does this plan's ceremony re-tread a seam that has burned a prior ceremony? If the same class of break has recurred, a point-patch scoped to the exact inch that last failed is a smell — the durable fix makes the pre-ceremony proof share the real ceremony's path, so a break fails BEFORE the ceremony with a pointer, not live.

Red flags that MUST be caught:
- Plan ships via a release/deploy/migration but names no pre-point-of-no-return proof for its new auth/toolchain/env seam
- Plan leans on a "simulation is green" that resolves dependencies, credentials, or services differently than the real ceremony (a structurally-blind pre-proof)
- Plan's only safeguard for a delivery seam is a runbook line ("run X before Y"), with no fail-closed gate
- Plan re-exercises a seam that a prior incident already burned, with a fix scoped only to the last failing point rather than the shared path
- Plan mutates something irreversible (tag, publish, prod data) with a seam proven only mid-ceremony or not at all

### Analysis 6: Premise Verification

Analyses 1–5 judge the plan's **prescriptions** (what to build, in what order, how it ships). They take the plan's **premises** — the facts about the world it was authored against — mostly on trust. Field experience says that is where a well-audited plan still breaks: the prescription was right, but it rested on a claim that was never true, and the fault surfaced mid-build as a "tripwire" that cost a stop, a diagnosis, and a plan amendment. Every one of those tripwires was a fact a single command could have checked at audit time. This analysis is that command pass, run **before** the verdict.

Procedure:

1. **Extract every factual claim** the plan makes about the current state of the world — not what it will do, but what it says *is*. Typical shapes: "file X exists / is enforced / is validated", "tool T prints line L", "version V is what runner R uses", "config C currently fails checks A/B/C", "task Q has no dependency on task P", "the API returns N on success", "branch B is the default".
2. **Classify each claim** as `VERIFIED` (the plan already carries a literal command + output for it), `PROBEABLE` (a read-only command can settle it now), or `UNPROBEABLE` (only the ceremony or a live run can settle it — hand these to Analysis 5).
3. **Run every PROBEABLE probe now.** Read-only, non-mutating: `Test-Path`, `git show/ls-tree/cat-file`, `rg`, `gh api GET`, `npm view`, a validator in dry-run, a real log from a prior run. Record the literal command and output in the plan's Verifications table as a `premise-check` row; a claim with no receipt is treated as unverified, not as true.
4. **Every falsified premise is a finding**, and the fix is applied to the plan (or the codebase, when the premise exposed a defect) before the verdict — never carried into the build as something to "watch for".
5. **Predicted outputs are premises too.** If the plan says a gate will red naming exactly `{X, Y, Z}`, derive the expected set from the real inputs now; a prediction the audit can compute but did not is an unverified premise.
6. **Gate bullets are premises too.** Every exit-gate bullet asserts that some command CAN be run at that moment and WILL observe something. Probe the "can be run" half for each bullet, not just the tasks: a gate that says "run workflow W from branch B" presumes W is dispatchable from B (GitHub registers a `workflow_dispatch`-only workflow only once it exists on the default branch), a gate that greps a tool's output presumes the output's shape (capture a real sample), a gate that calls an API presumes the credential type it holds is accepted by that endpoint. A gate bullet that turns out to be unrunnable at execution time is a plan defect the audit owned.

Red flags that MUST be caught (each is a shape that has cost a real stop):
- **Decorative enforcement**: the plan says a schema / lint / config rule "fails on X", but nothing in the repo evaluates that schema, the lint script excludes that directory, or the rule is an editor hint. Probe: find the evaluator, not the rule.
- **Version-line conflation**: the plan pins tool A to "the same major as" tool B, where A and B are different version lines (an action's tag vs the tool it runs; a client vs its server; an image tag vs the binary inside). Probe: read the actual default in B's manifest.
- **Log/output-format assumption**: the plan asserts on a line, count, or summary a tool "prints" without a captured sample. Probe: a real prior log or a dry run.
- **Stale or under-derived expectation**: the plan predicts which items fail / which files exist / which keys are present without deriving it from the current inputs. Probe: compute it.
- **Hidden inter-task ordering**: task A cites, imports, or registers something task B creates, and a gate rejects the tree between them. Probe: for each new identifier a task introduces, which gate validates it and which task supplies it.
- **Environment as state**: a step depends on an env var, a login, a running service, or a cached token that lives in shell/session state rather than in a durable location. Probe: is it set where the ceremony's shell will actually read it?

- **Self-gating gate**: the plan adds or widens a gate (lint scope, a new `check-*`, a parity assertion, a required plan section) whose predicate is FALSE on the very tree that lands it - it reads a branch the landing commit cannot yet have moved (`origin/main` from a `staging` commit), requires a section the existing plans lack, or lints files never linted before. Probe: run the gate's predicate against the landing tree as the plan describes it, not against the current tree; every "the gate will pass once X" is a hidden inter-task ordering. The 0.131.0 audit found five of these across twelve spokes; the ones it missed cost a build stop each.
- **Workstation-only dependency**: a gate, script, or test spawns a binary (`rg`, `jq`, `sed`, `gh` extensions) or relies on memory/CPU the hosted runner does not have. Probe: `rg -n "spawn|execFile" <new files>` and confirm every binary is one the runner image carries (`git`, `pnpm`, `node`, `gh`); for a widened lint/test scope, ask what the runner's default Node heap is and whether the widened invocation fits it. Local green never proves either.
- **Strict sibling of an advisory ruling**: the plan rules a check "warns", but the implementation also registers a strict variant somewhere (a second script, a `preflight:full` tier entry, a release-tier catalog row). Probe: `rg -n "<gate-id>" <catalog/manifest files>` and confirm every registration matches the ruled binding.
- **Install state after a dependency change**: a spoke adds a devDependency or a hook (lint-staged, husky) in an isolated worktree; the operator's main tree has not run `pnpm install`, so the first commit there fails on `command not found`. Probe: every manifest delta lists the trees that must re-install before the next commit.
- **Substrate default weaker than the behavior it replaces**: a plan lifts a consumer-owned mechanism into a shared library (a gate, a cookie, a retry, an exemption set) and the shared default is less safe or less complete than what the consumers already do - an unlock cookie that is a constant where the consumers sign theirs; a required input where the consumers had a default; a check that runs only when a flag is set where the consumers ran it always. Probe: for each consumer implementation the plan says it generalizes, list the security and completeness properties it has (signed? expiring? timing-safe? default-on? fail-closed?) and confirm the ruled substrate design carries every one. A generalization that drops a property is a regression shipped to every adopter at once.
- **Enumerate-then-assert-zero**: the plan asserts "zero X" (triggers, listeners, open ports, stale files) by iterating a list of Y the caller already knows (services in an inventory, paths in a manifest) and checking X on each - so an X attached to a Y the list omits passes silently. Probe: does the assertion query the whole scope (the environment, the directory tree) or only the enumerated members? A per-member query cannot prove zero.
- **Expected value read from the wrong environment**: a check compares live production state against a value sourced from a local dev file (`.env`, a dev config) rather than a declared contract or the production source. Probe: name the file each expected value comes from and confirm it describes the environment being checked.
- **Public type widened and declared non-breaking**: the plan adds a variant to an exported discriminated union, return type, or result shape (a new `{ ok: false, ... }` case, a new enum member, a new required field) and states that no consumer breaks at adoption. A caller narrowing with a bare `else`, an exhaustive `switch`, or a destructure fails typecheck the moment it bumps. Probe: `rg` every consumer tree for the export name and list each call site that branches on the shape; the claim holds only when that list is empty or every site is a row in the release-uplift plan and the CHANGELOG names the break under Consumer Action Required.
- **External API enum or status string asserted from memory**: the plan (or its gate) compares a value returned by a third-party API (GitHub workflow `state`, a Railway status, an npm dist-tag shape, an HTTP reason string) against a literal the author recalled rather than observed - and the audit marked the row HOLDS. Enums drift and vendors use qualified variants (`disabled_manually`, not `disabled`). Probe: run the real read-only call once (`gh api ... --jq .state`, the vendor GET) and paste the literal into the receipt; the claim holds only when the parser accepts the observed value, and a machine gate that branches on it must carry a test pinned to that observed literal, not the remembered one.
- **Consumer-reported defect fixed without executing the report**: the spoke closes an FM whose row names a consumer and a repro command but cites hub fixtures or substrate tests only, or records a CHANGELOG/uplift claim about consumer behavior with no Verifications row whose Command is the registry repro and whose Result is literal consumer output. Block audited/built until the row exists; block completed until the Result is literal.
- **Contract code asserted against sibling consumer trees from hub source**: a hub gate imports a contract renderer or validator from the hub's own package source and applies it to a sibling consumer checkout instead of spawning that consumer's installed CLI, so any change to the contract reds hub preflight until an adoption the red preflight prevents. Probe: rg the gate for imports from `../../packages/*/src` applied to a consumer repoRoot; the claim "hub preflight passes" holds only when every such assertion runs the installed kit.
- **Gate whose first subject is the tree that ships it, unchecked**: the plan adds or tightens a gate that will run against the repository containing the plan, without a probe showing the current tree passes the new predicate. Probe: run the predicate (or its closest existing equivalent) over the live target tree now and quote the violation count; a non-zero count is a blocker, not a build-time surprise.
- **Zero-count claim on a new gate rule probed only against the authoring plan**: a spoke that adds a plan-gate rule and prescribes "live tree carries zero violations" must run the new predicate over every live plan in the flight (and ideally the repo) at audit; a count taken against the authoring spoke alone is a false HOLDS (0.138.0 S1a: three sibling spokes tripped the rule at build).
- **Stated path existence without a probe row**: a plan or runner packet STATES a path is tracked/untracked (or exists/does not exist) as prose rather than as a Premise probes row the executor runs before acting on it. Probe: `rg` the packet for "is untracked" / "is tracked" / "does not exist" outside the Premise probes block; the 0.137.0 LSC `_remediation` folder was declared untracked from a stale observation and its edits dirtied the live tree mid-cut.
- **CLI flag shape asserted from memory**: a ruling or gate names a subcommand flag (`gh pr view --head <branch>`, `vitest -t`, `pnpm --filter=`) that the tool does not accept in that position. Probe: `<tool> <subcommand> --help` once and quote the matching usage line into the receipt; a flag with no `--help` hit is a falsified premise, not a HOLDS (0.140.0 S1b: `gh pr view` takes the branch positionally; the audit marked the ruling HOLDS).
- **Constant's home named without a search**: the plan names the file that holds a budget, threshold, allowlist, or default (`preflight.ts` for `releaseScriptsMs`) from recall. Probe: `rg -n "<identifier>\s*[:=]"` and quote the defining file; a plan whose Owned files omit the defining file will either edit the wrong file or grow its scope at build (0.140.0 S1f: the constant lived in `preflight-types.ts`).
- **Ceiling committed at the count the same spoke drains**: a spoke drains an allowlist or grandfather set to zero AND commits a no-growth ceiling equal to the pre-drain count - the ceiling licenses regrowth to exactly what was just removed. Probe: compare the ceiling literal to the post-drain count the spoke prescribes; they must match (0.140.0 S1a ruled `50`; built at `0`).
- **Removal task that cites no line**: a task says "drop X from Y" without a quoted `rg -n` hit showing X exists in Y at the evidence tree. Probe: run the search; a zero-hit removal is a false premise even when benign (0.140.0 S1c: `CHERRY_PICK_HEAD` inference in pre-commit never existed).
- **Applied finding that reconciles one section only**: an audit finding is applied to the ruled-decision or task it names while the plan's overview, Integrator handoff, or CHANGELOG-bullet text still describes the prior shape, so the runner builds one and hands off the other. Probe: after each applied finding, `rg` the plan for the superseded phrase and require zero hits (0.140.0 S1d: wave `--end` "derived from landing receipts" survived in two sections after ruling 5 changed it).
- **Gate-shape rule enforced only after `built`**: a plan-gate command validator that downgrades unbuilt plans to advisory means a malformed gate command is invisible at audit and reds at first `Status built`. Probe: run the validator with its simulation flag (`--assume-status built` / `--assume-status audited`) over every plan in the flight before the verdict; treat "advisory: plan not built" as an unverified premise, not a pass.
- **Timing premise without cause isolation**: the plan attributes a measured duration to a mechanism ("21 s spawning git against a nonexistent root") from reading the code path, not from timing the parts. Probe: time the suspected call alone, then the surrounding call alone, and quote both; the fix targets whichever carries the stall (0.140.0 harvest: the stall was `existsSync` on a disconnected `Z:` network drive, 21054 ms, while the same call on a real drive took 7 ms - the proposed git-spawn guard would have relocated the wait, not removed it).
- **New gate rule declared Tier-1 without a red run**: the plan (or an applied audit finding) adds a lint/ast-grep/schema rule and calls the class "closed at Tier 1" without ever showing the GATE - not the underlying tool - go red on a violating input. Probe: plant the violation, run the gate command the plan names, quote a non-zero exit; a tool that matches while the gate passes is a decorative rule (0.141.0 S1b: `check-ast-grep-conventions` silently dropped every `*.test.ts` from rule output, so a rule scoped to `scripts/__tests__` could never fire).
- **Fixture relocation checked on one OS**: the plan moves a fixture root, path literal, or environment shape (drive letter -> `tmpdir()`, backslash -> slash) and the suite also runs on a hosted runner with a different OS. Probe: read the CI job's `runs-on` and derive what the relocated value becomes there; a Windows-only regex over a POSIX `tmpdir()` root extracts nothing (0.141.0 S1b).
- **Helper signature change with a named caller list**: the plan changes a shared helper's signature and lists the callers from the stub's memory. Probe: `rg -n "<helper>\(" <tree>` and require the plan's Owned files to include every hit; a missed caller is a typecheck red at build and a scope change the audit owned (0.141.0 S1d: `parsePlanPathFilter` had a third caller).
- **Call-count premise conflated with reach-the-code-path premise**: "N call sites reach X" is two claims - N sites exist, and each one's control flow reaches X. Probe: count the sites, then for each check the early returns between the call and X (`--help` guards, refusals); state both numbers (0.141.0 S1e: seven calls, two return at the usage guard).
- **New gate rule whose before/after row measures the old predicate**: a spoke adds or tightens a rule and its before/after Verifications row counts violations of the EXISTING rule (or of the spoke's own files) rather than running the NEW predicate over the whole tree the gate will judge. Probe: run the new predicate (or its closest `rg` equivalent) over every live subject and quote the count; a non-zero count is a self-gating landing (sibling of "Self-gating gate", but caught at the receipt: the row exists and says the wrong thing). Two flights in a row shipped strict rules whose rows said `0` against the wrong scope (followon-9 audit: `tag-TBD-` Command-cell rule reds 21 live cells; hub todo-id parity reds 7 of 8 live hubs).
- **Escalation claim that does not name the field it changes**: the plan says a diff class "escalates mode E to O" (or "promotes to strict", "forces the gate") without saying WHICH field moves - the mode label, the budget class, the gate selection, or the exit code. Probe: read the function that applies the escalation and quote the assignment; a claim about the wrong field ships a doc that contradicts the code (0.142.0 S1a: only the budget class was scored against O; the mode label stayed E).
- **Fixture path carrying the runner's test suffix**: a non-test fixture placed under a `__tests__/` segment with a `.test.ts` name is collected by the runner's include glob and reds the suite as a test-less file. Probe: `vitest list --filesOnly` (or the runner's equivalent) with the proposed path; use `.fixture.ts` or a directory outside the glob (0.142.0 S1b).
- **Fixture that lives in a plan the ceremony will move**: a Verifications row or test reads a live plan path (the previous flight's hub, a `cycles/` folder) as its fixture, and the ceremony archives or renumbers that path before the row is re-run. Probe: ask whether the path survives `flight:archive` / `flight:number` between authoring and verification; pin to `!archive/completed/...` or `git show <sha>:<path>` instead (followon-11 S1d: the red-run fixture named the 0.143.0 hub under `cycles/`, which was archived before the spoke built).
- **Prescription fixture never run at audit**: a prescription row's fixture (the input file or command its before-side relies on) must be RUN ONCE at audit time against the locator or parser it feeds, and the literal output captured in the receipt, before the premise is marked HOLDS. Probe: run the fixture command (or read the fixture path) through the same locator/parser the prescription cites and paste the literal output; a HOLDS without that run is an unverified premise the build will trip (0.144.0 S1a: an audit marked HOLDS a premise whose fixture had never been executed).
- **Command cell authored in grep/bash idiom, not the executing shell's**: a Verifications Command uses `\|` alternation inside an `rg` or `Select-String` pattern (both treat it as a literal pipe), or `{a,b}` brace paths (PowerShell does not expand them), and the audit marks the row HOLDS from the plan author's expected output. Probe: run the cell as written in the executing shell and compare the exit code and match count to the Result cell; rewrite with `-e a -e b` (rg) or `-Pattern 'a','b'` (Select-String) and explicit paths, then recapture (0.149.0 S1a: two rows exited 1 at build with "lines ... match (exit 0)" in the receipt).
- **Deletion target inferred from a script name, not probed on disk**: a deletion spoke names a file (`release-retag.ts`, `release-window.ts`) because a `package.json` script is called that, but the code lives inline in another module. Probe: `Test-Path` every path under a delete list and `rg -l` the symbol to its real home before HOLDS; then require the spoke to enumerate every reference site of each deleted symbol (`package.json` scripts, hooks, gate catalog, topic rows, skills, packet templates, docs) in its Owned files or Integrator handoff - a delete list without a reference-site list is an unverified premise (ceremony-simplification audit 2026-09-09: two spokes named files that did not exist; six spokes listed integrator-owned surfaces as their own).
- **Reviewer finding that describes current code, parked as a plan fix**: a coverage/second-opinion review says "the current identity re-opens FM-nn on a bump" and the finding is filed against the future spoke instead of being triaged as a live defect. Probe: for each review finding, ask "does this describe code that runs in the NEXT release?"; if yes it is a fix-forward candidate now, not a plan row (0.149.0: the review predicted the bump-invalidates-receipts class one hour before the bump commit reproduced it).
- **Mount-point file named without reading its framework**: a plan names a server entry file as the Fastify mount when that file is actually an Express (or other) host and the Fastify surface lives elsewhere. Probe: `rg -n "fastify|express|Fastify\(" <file>` on every path the plan cites as the mount point before marking HOLDS (0.151.0 S1a).
- **Delta to absorb whose substrate side was never probed**: a convergence plan lists consumer deltas to lift into the substrate without checking whether the substrate already ships the capability (chrome slots, props, or exports named in the delta table). Probe: for each listed delta, `rg -n "<symbol|slot|prop>" packages/<pkg>/src` in the hub tree and mark rows "already substrate" when the base export exists; an absorb task without that probe is a false premise (0.151.0 S1c).

This analysis is cheap (minutes of read-only probes) relative to what it prevents (a build stop plus a plan amendment per falsified premise), so its depth does NOT scale down for small plans: run the full claim extraction on every plan that touches more than one file or any external tool.

## Adaptive Depth

Scale analysis depth to plan complexity:

| Plan Size | Risk Level | Analysis Depth |
|-----------|------------|----------------|
| Small (1-2 phases) | Low | Brief findings, focus on blockers only |
| Medium (3-4 phases) | Medium | Standard analysis, all major findings |
| Large (5+ phases) | High | Detailed analysis, every subtask reviewed |

| Any size | Any risk | If plan modifies 5+ files: require Implementation Readiness analysis |
| Any size | Any risk | If plan ships via a release/deploy/migration/registry-install/credential/infra ceremony: require Ceremony Survival analysis |
| Any size | Any risk | If plan touches more than one file or any external tool: require Premise Verification (full claim extraction + probes; never abbreviated) |

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
- Missing `Verified at` receipt → run `git rev-parse --short HEAD` and add it as the `Verified at` row of the `## Plan Metadata` **body** table (never frontmatter — Cursor's plan tracker strips custom frontmatter keys on every todo-status change)
- Missing or incomplete `### Verifications` table → run the verification commands from Step 8b and produce the body block
- Stale verification results → re-run the command, update the result, flag if the claim changed
- Falsified premise (Analysis 6) → correct the claim in the plan body and every todo/gate that derived from it, add the `premise-check` Verifications row with the literal probe; if the probe exposed a repo defect (a decorative gate, an unlinted tree), record it as a finding with a durable home (a task in this plan or a queued follow-on), never as a chat-only note

**Non-obvious decisions**: Probe, ask questions, propose with rationale. Examples:
- Reordering phases (may have unstated reasons)
- Removing scope (user may have context you don't)
- Architectural changes
- Adding significant new work
- Alternatives where both approaches have legitimate first-principles arguments and codebase evidence is ambiguous → ask the user

## Output Format

> See [Output Format Template](references/output-format-template.md) for the complete audit report template (Summary, Findings grouped by subject area, Parallelization, Critical path, Agent allocation, Recommendations list).

Produce a unified audit report. Group findings by **subject matter** (e.g., by phase, by system component, by risk area) — NOT by audit type.

### Machine-readable findings block (required)

Every audit report ends with **exactly one** fenced code block tagged `json findings`. It is the last block in the report. The prose report stays for humans; the applier and the next-round auditor consume this block instead of transcribing prose.

```json findings
{
  "schemaVersion": 1,
  "flight": "<cycle-folder-slug>",
  "round": 1,
  "observedAt": "2026-09-06T12:00:00.000Z",
  "evidenceTree": "<40-hex-git-tree-oid-the-probes-ran-against>",
  "findings": [
    {
      "id": "F1",
      "plan": ".cursor/plans/cycles/<cycle>/<spoke>.plan.md",
      "anchor": "section/<heading>",
      "kind": "literal",
      "class": "mechanical",
      "old": "<verbatim probe output>",
      "new": "<verbatim replacement or null when the finding is a question>",
      "probe": "<exact PowerShell command whose output is old>",
      "rationale": "<one sentence>",
      "requiresRuling": false,
      "applied": false
    }
  ]
}
```

**Top-level fields (schema v1).**

| Field | Requirement |
| --- | --- |
| `schemaVersion` | Always `1`. |
| `flight` | Cycle folder slug (for example `tag-0.139.0-ceremony-latency-2`). |
| `round` | Integer audit round (1-based). |
| `observedAt` | UTC ISO-8601 timestamp ending in `Z`. |
| `evidenceTree` | 40-character lowercase hex git tree oid the probes ran against. |
| `findings` | Array of finding objects (may be empty). |

**Each finding object.**

| Field | Requirement |
| --- | --- |
| `id` | `F<n>` contiguous from `F1` through `F<n>`; stable within a flight (round N dispositions every id from round N-1). |
| `plan` | Repo-relative path to the plan under audit. |
| `anchor` | `section/<heading>`, `row/<Claim text>`, or `meta/<Field>`. |
| `kind` | `literal`, `prose`, or `structural`. |
| `class` | `mechanical` or `semantic` (the S1c split). |
| `old` | Verbatim string (probe output for `literal`). |
| `new` | Verbatim string or `null` when the finding is a question. |
| `probe` | Required when `kind` is `literal` — the command whose output is `old`. |
| `rationale` | One sentence. |
| `requiresRuling` | `true` when the operator must decide (semantic / Analysis 6 red-flag path). |
| `applied` | `true` only when `class` is `mechanical` and `requiresRuling` is `false`. |

**Rules.**

- One block per report; a report without it fails `pnpm check-audit-findings <report.md>`.
- `requiresRuling: true` findings are never `applied: true`.
- Literal probe output and rationale remain mandatory in both prose and the block.
- Do not emit extra fields — the hub validator rejects unknown keys.

## After the Audit

**Update plan-level status.** If the verdict is "Ready to execute," update the `Status` row in the plan's body `## Plan Metadata` table to `audited`. **Apply this as a file edit before reporting the verdict** — do not declare the verdict in chat and leave the file unchanged. This signals to `tl-agent-plan-execute` that the plan has been reviewed and its verification receipts are trustworthy. If the verdict is "Changes recommended" or "Rework needed," leave `status` as `planned` until the revisions are applied and the plan is re-audited.

> **Do NOT set YAML frontmatter `status`.** Cursor's plan tracker strips custom frontmatter keys on every todo-status change; the body `## Plan Metadata` table is the durable SSOT. If the plan being audited uses a `## Plan Metadata` body table, that table's `Status` row is the only field to update. If the plan has no body metadata table, add one with a `Status | audited` row.

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
