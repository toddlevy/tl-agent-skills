# Architecture Decision Records

This directory holds the project's cross-cutting decisions and the reasons they hold. Each decision is one numbered ADR. An accepted ADR is immutable; a later decision is a new ADR that relates to the earlier one as described below.

## Conventions

- **Filename:** `NNNN-kebab-case-title.md`, where `NNNN` is a four-digit number, monotonic from `0001` and never reused. `template.md` is unnumbered.
- **Status:** one of `Proposed`, `Accepted (YYYY-MM-DD)`, `Superseded by NNNN`, or `Deprecated`.
- **Supersession and amendment:** full supersession flips the prior ADR's status to `Superseded by NNNN` and fills the new ADR's `Supersedes` header. A partial amendment leaves both ADRs accepted and adds a "Superseded in part by NNNN" header bullet to the prior ADR.
- **Immutability:** the only edit an accepted ADR receives is that status line or cross-reference line. A later decision that revisits an ADR is a new ADR, never an appended amendment.
- **Header bullets and sections:** every ADR carries the six header bullets `Status`, `Component`, `Originating signal`, `Owner`, `Supersedes`, and `Recorded`, followed by `Context`, `Decision`, `Consequences` (with `Positive` and `Negative and accepted trade-offs`), `Alternatives considered`, optional `Compliance and verification`, and `References`. Copy `template.md`.
- **Backfilled ADRs:** an ADR written after the decision landed carries the date the decision landed in `Status` and the date it was written in `Recorded`. Its `Originating signal` cites the commit SHAs.
- **Evidence only:** an ADR states rationale and alternatives only where a commit, issue, or document names them. Where none is named, `Alternatives considered` reads "None recorded at the time."
- **No secrets:** an ADR never contains a credential, key, token, or password.
- **Enforcement:** `./scripts/project-records.ps1 check` enforces numbering, header bullets, and index parity.

## When an ADR is required

An ADR is required when a change does any of the following:

- **(a)** Sets or changes a rule that binds more than one package, team, or agent.
- **(b)** Chooses between viable alternatives where reversal would cost more than one unit of planned work: deploy model, branch model, credential storage, data ownership and sync direction, test harness, or a shared-module boundary.
- **(c)** Moves a security, privacy, or production-access boundary.

Not required: module-local choices, version bumps, and content edits.

Where it is applied: a plan or design review marks the decisions that meet the rule, and close-out writes their ADRs before the work unit is archived. The DEVLOG close-out entry lists them under Related.

## Index

| #    | Title | Status |
| ---- | ----- | ------ |
