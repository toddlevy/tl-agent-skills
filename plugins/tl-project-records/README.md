# tl-project-records Plugin

Cursor plugin for keeping a repository's project records current.

## What's Included

### Skill: tl-project-records

- `DEVLOG.md`: what happened, when, and why, in eight categories
- `docs/adr/`: numbered, immutable Architecture Decision Records with a single-home trigger rule
- `CHANGELOG.md`: Keep a Changelog stanzas rendered from Conventional commit subjects, never hand-edited
- `scripts/project-records.ps1`: the records tool (subject hook, archive rule, whole-tree check, changelog preview and cut, self-test)
- `assets/templates/`: config, record scaffolds, hook shims, CI job, and an AGENTS.md section

### Rule: tl-project-records-usage.mdc

When to invoke the skill:

- Explicit triggers: "log this", "devlog", "record this decision", "write an ADR", "cut the release"
- Close-out, release, and incident moments
- Decisions that meet the repository's ADR trigger rule
- Show every standalone record before committing; never push as part of record keeping

## Usage

Say "adopt project records here" in a repository without them, or "log this" in one that has them. The skill reads the repository's own conventions first and follows them.
