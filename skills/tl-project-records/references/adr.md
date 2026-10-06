# Architecture Decision Records

An ADR answers "why is the project shaped this way?" for one decision. The DEVLOG says a decision happened; the ADR is where its reasons, alternatives, and consequences live.

## Home and naming

- `docs/adr/NNNN-kebab-case-title.md`. Four digits, monotonic from `0001`, never reused, no gaps. Numbers record acceptance order, not date.
- `docs/adr/README.md` holds the conventions, the trigger rule, and the index table. `docs/adr/template.md` is unnumbered.
- Copy both from `assets/templates/adr-README.md` and `assets/templates/adr-template.md`.

## ADRs and a decision ledger

Some projects keep a decision ledger: a single file whose entries (`D-nn`, for example) are product, content, or rules rulings. The two split by kind:

- **ADR**: a structural decision that meets the trigger rule below, with its reasons, alternatives, and consequences.
- **Ledger**: a ruling the project made about what it builds or says. It stays in the ledger and is never copied into an ADR.

When an ADR implements rulings, it cites each by id (`D-12`) and does not restate the ruling, so the ledger stays the only home. A DEVLOG entry cites an ADR by `ADR-NNNN` and a ledger ruling by its id under Related. A project with no ledger records such rulings in whichever of the ADR or the DEVLOG fits the trigger rule.

## Header and sections

Six header bullets, in this order, before the first `##` heading:

| Bullet | Holds |
|--------|-------|
| `Status` | `Proposed`, `Accepted (YYYY-MM-DD)`, `Superseded by NNNN`, or `Deprecated` |
| `Component` | What the rule binds: a package, service, pipeline, tooling, or process |
| `Originating signal` | The incident, commit, review finding, or request that forced the decision |
| `Owner` | The document, skill, or workstream that maintains the rule |
| `Supersedes` | `none`, or the ADR numbers this one replaces |
| `Recorded` | The date the ADR was written |

Then `Context`, `Decision`, `Consequences` (with `### Positive` and `### Negative and accepted trade-offs`), `Alternatives considered`, optional `Compliance and verification`, and `References`.

The header-bullet form was chosen over MADR's YAML front matter because each bullet is checkable with a line match, and MADR's `decision-makers`, `consulted`, and `informed` fields are team ceremony a small project does not run. A workspace that already uses MADR keeps it; set `adr.headerLabels` in `records.config.json` to the bullets it does use, and only `Status` is required.

## When an ADR is required

The rule has exactly one home: the "When an ADR is required" section of `docs/adr/README.md`. `AGENTS.md`, skills, and plan templates link that section and never restate it, so the rule cannot drift between copies. The template's default rule:

- **(a)** Sets or changes a rule that binds more than one package, team, or agent.
- **(b)** Chooses between viable alternatives where reversal costs more than one unit of planned work.
- **(c)** Moves a security, privacy, or production-access boundary.

Not required: module-local choices, version bumps, content edits.

| Decision | ADR? | Why |
|----------|------|-----|
| Chose PostgreSQL over MongoDB for the audit store | Yes | (b): reversal is a migration |
| All third-party calls go through one shared client | Yes | (a): binds every integration |
| Moved admin pages behind SSO | Yes | (c): access boundary |
| Added rate limiting to one endpoint | No, unless it sets a project-wide policy | Module-local |
| Renamed a config key | No | No alternatives in play |

## Lifecycle

1. **Draft** as `Proposed` while the decision is still open. A proposed ADR may be edited freely.
2. **Accept** by setting `Accepted (YYYY-MM-DD)` with the date the decision took effect. Update the index row's status in the same commit.
3. **Immutable after acceptance.** The only edits an accepted ADR receives are its status line and a cross-reference bullet. A tooling-driven mechanical path rewrite is also allowed if the workspace has one. At adoption, an existing ADR that carries its date in a separate `Date` bullet has its status line normalized to `Accepted (<that date>)`, which is a status-line edit, not a substantive one.
4. **Supersede** fully by writing a new ADR whose `Supersedes` names the old number, and flipping the old ADR's status to `Superseded by NNNN`.
5. **Amend in part** by writing a new ADR and adding a `- **Superseded in part by:** NNNN` bullet to the old one. Both stay accepted.
6. **Deprecate** a rule that no longer applies and has no successor.

Never append an "Update" section to an accepted ADR. A revisited decision is a new decision.

## Backfilling at adoption

A project adopting the records usually has decisions in effect that were never written down. Backfill them under these rules:

- Record only decisions **in effect on the main branch** and **evidenced** by a commit, a document section, or a completed plan.
- `Status` carries the date the decision landed; `Recorded` carries the adoption date. `Originating signal` cites the commit SHAs.
- State rationale and alternatives **only where the evidence names them**. Otherwise `Alternatives considered` reads "None recorded at the time." Inventing a rationale after the fact is the most common way a backfilled ADR becomes wrong.

## Agent-readiness review

Before accepting an ADR, read it as an agent that has only this file:

- Could it implement or police the decision from the `Decision` section alone? If the rule needs the reader to infer scope, state the scope.
- Is every constraint concrete: named paths, commands, versions, numbers?
- Does `Compliance and verification` name a command that fails when the rule is broken? If no such check exists, delete the section rather than describe a manual review.
- Are the trade-offs honest? An ADR with no negative consequence has not been examined.
- Is anything secret in it? Remove it.

## Index

The README's `## Index` is a table with `#`, `Title` (a relative link to the file), and `Status`. One row per file, in number order. `check` fails on a missing row, a row with no file, a link that does not match the file name, or a status that differs from the file. An index status may omit the acceptance date (`Accepted`) while the file carries it.

## Linking

- From the DEVLOG: name `ADR-NNNN` under Related. `check` fails when the number has no file.
- From commit bodies and pull requests: `ADR-NNNN` in the body.
- Between ADRs: the `Supersedes` bullet, a "Superseded in part by" bullet, and the References section.
- To work that is still in flight: cite plans or issues by file name or number plus a commit SHA, not by a folder path that will move when the work is archived.
