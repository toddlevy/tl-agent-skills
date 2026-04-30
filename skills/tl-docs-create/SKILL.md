---
name: tl-docs-create
description: Create documentation from scratch for codebases. Covers SSOT-driven generation, writing standards, and templates for README/AGENTS.md/CHANGELOG. Use when creating new docs or documenting an undocumented codebase.
license: MIT
metadata:
  version: "1.1"
  author: Todd Levy <toddlevy@gmail.com>
  homepage: https://github.com/toddlevy/tl-agent-skills
  quilted:
    - source: google-gemini/gemini-cli/docs-writer
      weight: 0.25
      description: 4-phase workflow, voice/tone rules, verification checklist
    - source: shpigford/skills/readme
      weight: 0.15
      description: Exploration-first, 3 purposes, absurd thoroughness
    - source: getsentry/skills/agents-md
      weight: 0.12
      description: AGENTS.md structure, brevity rules, file-scoped commands
    - source: softaworks/agent-toolkit/crafting-effective-readmes
      weight: 0.10
      description: Project type detection, audience analysis
    - source: itechmeat/llm-code/changelog
      weight: 0.08
      description: CHANGELOG.md template, Keep a Changelog format
    - source: patricio0312rev/skills/api-docs-generator
      weight: 0.08
      description: OpenAPI patterns, API doc templates
    - source: remotion-dev/remotion/writing-docs
      weight: 0.06
      description: Language brevity, API-per-page rule
    - source: plaited/development-skills/code-documentation
      weight: 0.05
      description: TSDoc patterns
    - source: aj-geddes/useful-ai-prompts/markdown-documentation
      weight: 0.05
      description: GFM syntax, do/don't list
    - source: local/jambase-docs
      weight: 0.04
      description: SSOT generation, hierarchical READMEs, source attribution
    - source: local/agents-md-create
      weight: 0.02
      description: Project type templates
  moment: implement
  surface:
    - repo
  output: artifact
  risk: safe
  posture: opinionated
  suite: tl-docs
  related:
    - tl-docs-audit
    - tl-docs-viewer-create
---

<!-- Copyright (c) 2026 Todd Levy. Licensed under MIT. SPDX-License-Identifier: MIT -->

# Documentation Creation

Create documentation from scratch for any codebase with SSOT-driven generation, writing standards, and templates.

## When to Use

- "create documentation"
- "generate README"
- "create AGENTS.md"
- "start CHANGELOG"
- "document this codebase"
- Starting a new project that needs docs
- Documenting an undocumented codebase
- Creating docs folder structure

For auditing existing docs, see `tl-docs-audit`.

## Outcomes

- **Artifact**: Documentation tree (README, AGENTS.md, CHANGELOG, docs/ folder, API reference)
- **Artifact**: Cursor rules for ongoing documentation maintenance (optional)
- **Decision**: Doc types needed based on project and audience

---

## Configuration Discovery

Before creating documentation, gather user intent through structured questions. See `references/configuration.md` for full question schemas.

### Question Flow Summary

1. **Light scan** â€” Check for existing `docs/`, `README.md`, `AGENTS.md`, `CHANGELOG.md`
2. **Existing docs?** â€” If found, suggest `tl-docs-audit` instead; otherwise proceed
3. **Audience** â€” Contributors / Users / Operators / Future self / Mixed
4. **Scope** â€” Minimal / Standard / Comprehensive / Absurdly thorough
5. **Doc Types** â€” README / AGENTS.md / CHANGELOG / docs/ / API reference / Rules
6. **Rules** â€” Create Cursor rules for doc maintenance? Yes / Pick / No

---

## Phase 1: Assessment

Explore the codebase before writing. Understand before documenting.

### Step 1: Deep Codebase Exploration

- Map directory organization and entry points
- Identify framework/language from `package.json`, `Gemfile`, `go.mod`, etc.
- Read deployment configs, CI configs, Docker files
- Check database type, migrations, seeds
- Note key dependencies and scripts

### Step 2: Detect Project Type

| Type | Indicators | Doc Focus |
|------|------------|-----------|
| **Monorepo** | `pnpm-workspace.yaml`, `nx.json`, multiple `package.json` | Per-package READMEs, root overview |
| **Frontend** | React/Vue/Angular deps, `vite.config`, `next.config` | Component docs, deployment |
| **Backend** | Express/Fastify/Rails, API routes | API reference, database schema |
| **Library** | `main`/`exports` in package.json, no app code | API docs, examples, changelog |
| **CLI** | `bin` field, commander/yargs deps | Usage, options, examples |

### Step 3: Identify Audience

Ask via AskQuestion if not clear from context. Affects tone, depth, and doc types.

---

## Phase 2: Doc Type Selection

Based on assessment and user answers, determine which artifacts to create.

| Doc Type | When Needed | Template |
|----------|-------------|----------|
| `README.md` | Always | `templates/readme-project.md` |
| `AGENTS.md` | AI-assisted development | `templates/agents-md.md` |
| `CHANGELOG.md` | Versioned releases | `templates/changelog.md` |
| `docs/` folder | Comprehensive scope | `templates/readme-root.md` |
| API reference | Backend/library projects | `templates/api-reference.md` |
| Docs Viewer UI | Admin interface needed | See `tl-docs-viewer` skill |

---

## Phase 3: Standards

Apply writing standards from `references/writing-standards.md`.

### Quick Reference

| Rule | Description |
|------|-------------|
| Address as "you" | Not "we" or passive voice |
| No Latin abbreviations | "for example" not "e.g." |
| Serial comma | Oxford comma always |
| Overview after headings | Every heading needs intro paragraph |
| Brevity | Developers don't read; extra words = info loss |
| No blame | "Input is invalid" not "You provided wrong input" |
| No assumptions | Avoid "simply" and "just" |

---

## Phase 4: Execution

Create or update documentation using templates from `references/templates/`.

### For Each Doc Type

1. Load appropriate template
2. Fill with codebase-specific content
3. Apply writing standards
4. Add source attribution where applicable
5. Create Cursor rules if user selected rule creation

### Source Attribution

For generated docs (scripts, env vars), add footer:
```markdown
---
_Source: `path/to/source-file.ts`_
```

### Last Updated

For docs with freshness tracking:
```markdown
> **Last Updated:** 2026-03-17
```

---

## Phase 5: Verification

Before completing, verify documentation quality.

### Checklist

- [ ] All selected doc types created
- [ ] Writing standards applied (run through `references/writing-standards.md`)
- [ ] Internal links validated (relative paths exist)
- [ ] No orphaned docs (all docs reachable from README or index)
- [ ] Last Updated dates current

### Validation Commands

If available, run:
- `pnpm lint` or project's lint command
- Link checker if configured
- `agentskills validate` for skill-specific validation

---

## Self-Documentation

Generate docs from code where possible. See `references/self-documentation.md`.

### Script Documentation

Parse script headers to generate docs:
- Usage, Options, Examples
- Environment Variables
- Prerequisites, Related
- Exit Codes, Troubleshooting

### Environment Variables

Generate tables from config:

| Variable | Service(s) | Description | Example |
|----------|------------|-------------|---------|
| `DATABASE_URL` | api | PostgreSQL connection | `postgresql://...` |

---

## Documentation Rules

Optionally create Cursor rules for ongoing maintenance. See `references/doc-rules.md`.

Available rules:
- `readme-sync.mdc` â€” Update README when features change
- `changelog-commits.mdc` â€” CHANGELOG from conventional commits
- `api-doc-sync.mdc` â€” Sync API docs with code changes
- `agents-md-maintain.mdc` â€” Keep AGENTS.md current
- `doc-style.mdc` â€” Enforce documentation style
- `last-updated.mdc` â€” Track Last Updated dates
- `link-check.mdc` â€” Validate internal doc links

---

## References

### Skill References

| File | Purpose |
|------|---------|
| `references/configuration.md` | AskQuestion flows and branching logic |
| `references/writing-standards.md` | Voice, tone, formatting rules |
| `references/self-documentation.md` | SSOT generation patterns |
| `references/doc-types.md` | README, AGENTS.md, CHANGELOG, API patterns |
| `references/docs-viewer.md` | Reference to `tl-docs-viewer-create` skill |
| `references/doc-rules.md` | Cursor rules for doc maintenance |

### First-Party Documentation

- [Keep a Changelog](https://keepachangelog.com/) â€” CHANGELOG format standard
- [MADR](https://adr.github.io/madr/) â€” Markdown Architectural Decision Records
- [DiÃ¡taxis](https://diataxis.fr/) â€” Documentation framework (tutorial/how-to/reference/explanation)
- [Conventional Commits](https://www.conventionalcommits.org/) â€” Commit message convention
- [Write the Docs](https://www.writethedocs.org/guide/) â€” Documentation community style guide

### Documentation Tools

- [TypeDoc](https://typedoc.org/) â€” TypeScript API documentation generator
- [JSDoc](https://jsdoc.app/) â€” JavaScript documentation generator
- [OpenAPI](https://www.openapis.org/) â€” REST API specification

---

## Related Skills

- [tl-docs-audit](../tl-docs-audit/SKILL.md) â€” Audit docs coverage, find gaps, generate sync reports
- [tl-docs-viewer-create](../tl-docs-viewer-create/SKILL.md) â€” React admin UI for browsing docs/ folder
