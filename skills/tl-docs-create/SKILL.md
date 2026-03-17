---
name: tl-docs-create
description: Create documentation from scratch for codebases. Covers SSOT-driven generation, writing standards, and templates for README/AGENTS.md/CHANGELOG. Use when creating new docs or documenting an undocumented codebase.
license: MIT
quilted:
  version: 1
  synthesized: 2026-03-17
  sources:
    - url: https://skills.sh/google-gemini/gemini-cli/docs-writer
      borrowed: ["4-phase workflow", "voice/tone rules", "verification checklist"]
      weight: 0.25
    - url: https://skills.sh/shpigford/skills/readme
      borrowed: ["exploration-first", "3 purposes", "absurd thoroughness"]
      weight: 0.15
    - url: https://skills.sh/getsentry/skills/agents-md
      borrowed: ["AGENTS.md structure", "brevity rules", "file-scoped commands"]
      weight: 0.12
    - url: https://skills.sh/softaworks/agent-toolkit/crafting-effective-readmes
      borrowed: ["project type detection", "audience analysis"]
      weight: 0.10
    - url: https://skills.sh/itechmeat/llm-code/changelog
      borrowed: ["CHANGELOG.md template", "Keep a Changelog format"]
      weight: 0.08
    - url: https://skills.sh/patricio0312rev/skills/api-docs-generator
      borrowed: ["OpenAPI patterns", "API doc templates"]
      weight: 0.08
    - url: https://skills.sh/remotion-dev/remotion/writing-docs
      borrowed: ["language brevity", "API-per-page rule"]
      weight: 0.06
    - url: https://skills.sh/plaited/development-skills/code-documentation
      borrowed: ["TSDoc patterns"]
      weight: 0.05
    - url: https://skills.sh/aj-geddes/useful-ai-prompts/markdown-documentation
      borrowed: ["GFM syntax", "do/don't list"]
      weight: 0.05
    - local: JamBase data.jambase.com/docs
      borrowed: ["SSOT generation", "hierarchical READMEs", "source attribution"]
      weight: 0.04
    - local: agents-md-create
      borrowed: ["project type templates"]
      weight: 0.02
  excluded:
    - url: https://skills.sh/am-will/codex-skills/openai-docs-skill
      reason: "Different domain — MCP for fetching external docs"
    - url: https://skills.sh/openai/openai-agents-python/docs-sync
      reason: "Gap analysis scope — see tl-docs-audit"
    - url: https://skills.sh/jezweb/claude-skills/docs-workflow
      reason: "Staleness audit scope — see tl-docs-audit"
  enhancements:
    - "Unified 4-phase workflow (assess, select, write, verify)"
    - "Doc type selection gate"
    - "Self-documentation generation from code"
    - "Audience-aware templates"
metadata:
  moment: implement
  surface: [repo]
  output: artifact
  risk: safe
  posture: opinionated
  suite: tl-docs
  related:
    - tl-docs-audit
    - tl-docs-viewer-create
---

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

1. **Light scan** — Check for existing `docs/`, `README.md`, `AGENTS.md`, `CHANGELOG.md`
2. **Existing docs?** — If found, suggest `tl-docs-audit` instead; otherwise proceed
3. **Audience** — Contributors / Users / Operators / Future self / Mixed
4. **Scope** — Minimal / Standard / Comprehensive / Absurdly thorough
5. **Doc Types** — README / AGENTS.md / CHANGELOG / docs/ / API reference / Rules
6. **Rules** — Create Cursor rules for doc maintenance? Yes / Pick / No

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
- `readme-sync.mdc` — Update README when features change
- `changelog-commits.mdc` — CHANGELOG from conventional commits
- `api-doc-sync.mdc` — Sync API docs with code changes
- `agents-md-maintain.mdc` — Keep AGENTS.md current
- `doc-style.mdc` — Enforce documentation style
- `last-updated.mdc` — Track Last Updated dates
- `link-check.mdc` — Validate internal doc links

---

## References

| File | Purpose |
|------|---------|
| `references/configuration.md` | AskQuestion flows and branching logic |
| `references/writing-standards.md` | Voice, tone, formatting rules |
| `references/self-documentation.md` | SSOT generation patterns |
| `references/doc-types.md` | README, AGENTS.md, CHANGELOG, API patterns |
| `references/docs-viewer.md` | Reference to `tl-docs-viewer-create` skill |
| `references/doc-rules.md` | Cursor rules for doc maintenance |

---

## Related Skills

- [tl-docs-audit](../tl-docs-audit/SKILL.md) — Audit docs coverage, find gaps, generate sync reports
- [tl-docs-viewer-create](../tl-docs-viewer-create/SKILL.md) — React admin UI for browsing docs/ folder
