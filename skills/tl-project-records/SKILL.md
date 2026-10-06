---
name: tl-project-records
description: >-
  Keep a repository's project records current: DEVLOG.md (what happened and why), ADRs in
  docs/adr/ (why the project is shaped this way), and a CHANGELOG.md rendered from Conventional
  commit subjects (what each release changed), plus the hooks, CI job, and close-out ceremony that
  keep them current. Use when the user says "log this", "devlog", "record this decision", "write an
  ADR", "cut a release", "changelog", or "adopt project records", when closing a plan or work unit,
  after a release or incident, or when writing a commit subject the changelog will render.
license: MIT
metadata:
  version: "1.1"
  author: Todd Levy <toddlevy@gmail.com>
  homepage: https://github.com/toddlevy/tl-agent-skills
  moment: implement
  surface:
    - repo
    - ci
  output: patch
  risk: medium
  effort: low
  posture: opinionated
  agentFit: repo-write
  dryRun: full
  quilted:
    version: 1
    synthesized: 2026-10-05
    sources:
      - source: "Private reference deployments: a private WordPress deployment and a private TypeScript monorepo"
        weight: 0.30
        borrowed:
          - "Three records with one question each, and the boundaries between them"
          - "Records tool: check-msg, check-commit, check-range, check, changelog-preview, changelog-cut, self-test"
          - "Permanently empty [Unreleased]; stanzas rendered from subjects and filtered by export-ignore"
          - "Six-bullet ADR header, immutability, supersession and partial amendment, backfill rules"
          - "Single-home ADR trigger rule; archive rule; hook-install-commit range start"
          - "Production pitfalls 1-10"
      - source: toddlevy/tl-agent-skills tl-devlog
        weight: 0.20
        borrowed:
          - "DEVLOG entry shape, eight categories, and per-category examples"
          - "Proactive suggestion framing; show-before-commit"
          - "Search patterns for reading the log"
      - source: https://github.com/skillrecordings/adr-skill
        weight: 0.12
        borrowed:
          - "Agent-readiness review before accepting an ADR (paraphrased; upstream has no license)"
          - "When-to-write-an-ADR examples"
      - source: https://github.com/d6veteran/devlog-skill
        weight: 0.10
        borrowed:
          - "Why-focus; do-not-log list; natural pause-point triggers"
      - source: https://github.com/alirezarezvani/claude-skills
        weight: 0.05
        borrowed:
          - "Type-to-section mapping for Keep a Changelog"
      - source: https://github.com/stealth-factory/skills
        weight: 0.05
        borrowed:
          - "Breaking-change marker; subject-writing guidance"
      - source: https://github.com/SkillMedev/skills
        weight: 0.04
        borrowed:
          - "Release range from the previous tag"
      - source: https://github.com/product-on-purpose/pm-skills
        weight: 0.04
        borrowed:
          - "When-not-to-write-an-ADR guidance (paraphrased; Apache-2.0)"
      - source: https://github.com/josephmiclaus/skill-devlog
        weight: 0.04
        borrowed:
          - "Secrets constraint; append and change update modes"
      - source: https://github.com/jotafurtado/dev-skills
        weight: 0.03
        borrowed:
          - "Resolve workspace conventions before drafting"
      - source: https://github.com/skrrt-sh/skills (ship/release)
        weight: 0.02
        borrowed:
          - "Release pull request body from the rendered range"
      - source: https://github.com/skrrt-sh/skills (ship/commit)
        weight: 0.01
        borrowed:
          - "One logical change per commit"
    excluded:
      - source: https://github.com/vercel/ai/tree/main/skills/adr-skill
        reason: "Duplicate of skillrecordings/adr-skill"
      - source: https://github.com/maoruibin/devlog
        reason: "Category set is a subset of the adopted eight; CLI-specific"
      - source: https://github.com/wshobson/agents (changelog-automation)
        reason: "Tool survey and release-notes domain; subset of the porting note"
    enhancements:
      - "Config-driven PowerShell records tool with temp-repo self-test, proven byte-identical to its reference implementation"
      - "Two release models (semver and deploy-dated) through named tag-pattern groups"
      - "BOM-safe and collision-safe commit message files on Windows"
      - "Optional archive rule and removal-ledger rendering"
---

<!-- Copyright (c) 2026 Todd Levy. Licensed under MIT. SPDX-License-Identifier: MIT -->

# tl-project-records

Three records, each answering one question, and the wiring that keeps them current without a separate chore.

| Record | Answers | Written | Reference |
|--------|---------|---------|-----------|
| `DEVLOG.md` | What happened, when, and why? | Close-out, release, incident, ADR-producing decision, or on request | `references/devlog.md` |
| `docs/adr/NNNN-*.md` | Why is the project shaped this way? | When a change meets the trigger rule in `docs/adr/README.md` | `references/adr.md` |
| `CHANGELOG.md` | What did each release change? | Rendered at release by `changelog-cut`; never hand-edited | `references/changelog.md` |

Commit subjects feed the changelog, so they follow one rule (`references/commit-subjects.md`). One script, `scripts/project-records.ps1`, enforces every mechanical rule and renders the changelog (`references/tool-contract.md`).

## Quick Start

- **"Log this"**: draft a DEVLOG entry from the conversation, show it, commit after confirmation.
- **"Write an ADR for this"**: check the trigger rule, draft from `docs/adr/template.md`, add the index row.
- **"Cut the release"**: preview, tag, `changelog-cut`, commit.
- **"Adopt project records here"**: follow `references/adoption.md`.

## Boundaries

Each fact has one home. Before writing, put the fact where it belongs:

| Fact | Home |
|------|------|
| The reasons for a cross-cutting decision | An ADR |
| A product, content, or rules ruling, where the project keeps a decision ledger | The ledger; an ADR cites the rulings it implements and never restates them |
| That something happened, and what it cost | A DEVLOG entry |
| What a release changed for its reader | The CHANGELOG stanza, from commit subjects |
| How the system works today | `docs/` and `AGENTS.md` |
| Why one commit is shaped the way it is | The commit body |
| Audit findings and plan progress | The plan or review itself |

A DEVLOG entry links `ADR-NNNN`, or cites a ledger ruling by its id, instead of restating either. `AGENTS.md` links the ADR trigger rule instead of copying it.

## Workspace conventions first

Before writing any record, read the workspace's own rules: the DEVLOG header's `## Conventions`, `docs/adr/README.md`, `records.config.json`, and the records section of `AGENTS.md`. A workspace rule overrides this skill on location, commit scope, vocabulary, and approval flow. If the repository has none of these, the defaults below apply; offer adoption rather than inventing a local variant.

## Workflow: DEVLOG entry

1. Confirm a trigger (`references/devlog.md`, Triggers). Do not log in-flight work, lookups, or audit findings.
2. Choose one category and three to five tags. Write Summary, Detail (what, why, alternatives, consequences), and Related, with concrete names, numbers, and SHAs. Redact secrets.
3. Insert it at the top of the entries, below the header separator.
4. **Standalone entry:** show the full draft and ask for confirmation. After it, commit `docs(records): <title>` by pathspec. **Ceremony entry:** include it in the ceremony's commit and report.
5. Run `check`.

When the user explicitly says "log this", draft from the preceding conversation without asking what to log. At a natural pause point after a decision, a completed work unit, or a resolved incident, offer specifically: "We chose X over Y because Z; want me to log it?"

Examples for every category, plus close-out, ADR-link, and retroactive entries: `references/entry-examples.md`.

## Workflow: ADR

1. Read the trigger rule in `docs/adr/README.md`. If the change does not meet it, say so and log a DEVLOG entry instead if one is warranted.
2. Take the next number (highest existing plus one). Copy `docs/adr/template.md` to `docs/adr/NNNN-kebab-title.md`.
3. Fill the six header bullets and the sections from evidence. Alternatives only where something names them; otherwise "None recorded at the time."
4. Run the agent-readiness review (`references/adr.md`).
5. Add the index row to the README in the same change. Set `Accepted (YYYY-MM-DD)` when the decision takes effect.
6. Write the companion DEVLOG entry, naming `ADR-NNNN` under Related.
7. Show both drafts, then commit by pathspec as `docs(records): adr NNNN <title>`. Run `check`.

Never edit an accepted ADR's substance. Revisiting it means a new ADR that supersedes it fully or in part.

## Workflow: commit subject

Write `type(scope): subject` with a type from `records.config.json`, one scope, and a subject a release reader understands. Use reserved scopes (`security`, and `legal` where configured) for boundary changes. Multi-line messages go through a no-BOM, uniquely named file and `git commit -F <file> -- <paths>`. Details and the PowerShell pattern: `references/commit-subjects.md`.

## Workflow: release

The operator runs the push and tag steps; the agent runs preview, cut, and check.

```powershell
git push   # operator step
pwsh -NoProfile -File scripts/project-records.ps1 changelog-preview -OutFile $previewPath
# operator steps: open the release pull request with $previewPath as its body; merge; create and push the tag
pwsh -NoProfile -File scripts/project-records.ps1 changelog-cut -Tag <tag>
pwsh -NoProfile -File scripts/project-records.ps1 check
```

Commit `CHANGELOG.md` (and the release DEVLOG entry) as `docs(records): cut <tag>`. The first release needs `-From`. Full procedure and both release models: `references/changelog.md`.

## Workflow: close-out

When a plan, epic, or work unit closes: write its ADRs, then the DEVLOG close-out entry naming the work unit's key verbatim, then archive it in the same commit as the DEVLOG change. The pre-commit rail refuses an archive whose key the staged DEVLOG does not name. Run `check`, commit `docs(records): close <key>`. Details: `references/wiring.md`.

## Workflow: adopt

Survey, configure, scaffold from `assets/templates/`, seed, verify. Never overwrite an existing record; merge into the shape. Full procedure: `references/adoption.md`.

## Dry Run Preview

Every read path is safe to run first:

| Question | Read-only command |
|----------|-------------------|
| Are the records well formed? | `project-records.ps1 check` |
| What would the next release say? | `project-records.ps1 changelog-preview` (stdout, or `-OutFile` to a temp file); read its stderr count line for skipped subjects |
| Would this message pass the hook? | `project-records.ps1 check-msg <file>` |
| Do this branch's subjects pass? | `project-records.ps1 check-range -Base <base> -Head HEAD` |
| Is the tool itself sound? | `project-records.ps1 self-test` |

For a record draft, the dry run is showing the full text to the user before writing it. For adoption, it is the survey report and the list of files to be created.

## Verification

- `check` exits 0 after every record change. Report the exit code.
- `self-test` exits 0 after any change to the tool or its config.
- After a cut, the new stanza's bullets match the preview for the same range.
- After adoption, a free-form subject is rejected by the hook and a conventional one passes.

## Rollback

- **A record commit is wrong:** fix it forward with a new `docs(records)` commit. An accepted ADR is superseded, not edited.
- **A cut wrote the wrong stanza and is not pushed:** restore `CHANGELOG.md` from `HEAD` (`git restore --source=HEAD -- CHANGELOG.md` in a tree only you write), then cut again with the right `-From`. If pushed, fix forward.
- **Adoption needs to come out:** revert the adoption commit and run `git config --unset core.hooksPath`.
- **A hook blocks urgent work:** fix the message. `--no-verify` is the operator's call, and `check-range` in CI will still flag the subject.

## Safety

- Never write a credential, key, token, password, or personal data into any record.
- Never commit a standalone record the user has not seen. Never push as part of record keeping.
- Commit by pathspec only, after `git diff --cached --name-status` shows only your paths. Never sweep another session's staged work.
- Never rewrite published history to make old subjects conform.

## Resources

| File | Load when |
|------|-----------|
| `references/devlog.md` | Writing or reading the DEVLOG |
| `references/entry-examples.md` | Drafting an entry in an unfamiliar category |
| `references/adr.md` | Writing, accepting, superseding, or backfilling an ADR |
| `references/changelog.md` | Releasing, configuring the release model, or porting to another renderer |
| `references/commit-subjects.md` | Writing a subject, or a hook rejected one |
| `references/wiring.md` | Hooks, CI, close-out, AGENTS.md, shared trees |
| `references/adoption.md` | Adding the records to a repository |
| `references/pitfalls.md` | Something is not working, or before adoption |
| `references/tool-contract.md` | Exact command behavior, exit codes, config schema |
| `scripts/project-records.ps1` | Copied into the repository as `scripts/project-records.ps1` |
| `assets/templates/` | `records.config.json`, `DEVLOG.md`, `CHANGELOG.md`, `adr-template.md`, `adr-README.md`, `commit-msg`, `pre-commit`, `ci-records-job.yml`, `agents-md-records.md` |

## References

- [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/)
- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Documenting Architecture Decisions (Nygard)](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [MADR](https://adr.github.io/madr/)
- [git-cliff arguments](https://git-cliff.org/docs/usage/args)
- [Engineering Daybook (Fowler)](https://martinfowler.com/bliki/EngineeringDaybook.html)
