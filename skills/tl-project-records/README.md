# tl-project-records

Keep a repository's project records current: `DEVLOG.md`, Architecture Decision Records in `docs/adr/`, and a `CHANGELOG.md` rendered from Conventional commit subjects, plus the hooks, CI job, and close-out ceremony that keep them current.

## Quick Start

- "log this" or "devlog": a DEVLOG entry, shown before it is committed
- "write an ADR for this": a numbered ADR with its index row
- "cut the release": preview, tag, render the stanza
- "adopt project records here": scaffold the records, config, hooks, and CI job

## The three records

| Record | Answers |
|--------|---------|
| `DEVLOG.md` | What happened, when, and why? |
| `docs/adr/` | Why is the project shaped this way? |
| `CHANGELOG.md` | What did each release change? |

## The records tool

`scripts/project-records.ps1` runs on Windows PowerShell 5.1 and PowerShell 7, needs only git, and reads its vocabulary from `records.config.json`.

| Command | Does |
|---------|------|
| `check-msg <file>` | Commit-subject rule (the commit-msg hook) |
| `check-commit` | Archive rule (the pre-commit hook) |
| `check-range -Base -Head` | Subject rule over a pull request (CI) |
| `check` | ADR, DEVLOG, and CHANGELOG structure |
| `changelog-preview` | Render the next release, read-only |
| `changelog-cut -Tag` | Write the release stanza |
| `self-test` | Temp-repo fixtures for every rule |

## Resources

| Path | Purpose |
|------|---------|
| `SKILL.md` | Workflows, boundaries, verification, rollback |
| `references/` | DEVLOG, entry examples, ADRs, changelog, commit subjects, wiring, adoption, pitfalls, tool contract |
| `scripts/project-records.ps1` | The records tool |
| `assets/templates/` | Config, record scaffolds, hook shims, CI job, AGENTS.md section |

## Quilted Skill

Synthesized from two private reference deployments (a private WordPress deployment and a private TypeScript monorepo), the earlier `tl-devlog` skill, and:

- [skillrecordings/adr-skill](https://github.com/skillrecordings/adr-skill): agent-readiness review
- [d6veteran/devlog-skill](https://github.com/d6veteran/devlog-skill): why-focus and triggers
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills): type-to-section mapping
- [stealth-factory/skills](https://github.com/stealth-factory/skills): subject guidance
- [SkillMedev/skills](https://github.com/SkillMedev/skills), [product-on-purpose/pm-skills](https://github.com/product-on-purpose/pm-skills), [josephmiclaus/skill-devlog](https://github.com/josephmiclaus/skill-devlog), [jotafurtado/dev-skills](https://github.com/jotafurtado/dev-skills), [skrrt-sh/skills](https://github.com/skrrt-sh/skills)
