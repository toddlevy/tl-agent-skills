# tl-docs-create

Create documentation from scratch for any codebase with SSOT-driven generation, writing standards, and templates.

## What This Skill Does

- **Assesses** codebase structure and project type
- **Creates** documentation from scratch (README, AGENTS.md, CHANGELOG, docs/)
- **Enforces** consistent writing standards
- **Generates** docs from code (scripts, env vars, API)
- **Optionally creates** Cursor rules for ongoing maintenance

For auditing existing docs, see `tl-docs-audit`.

## When to Use

- "create documentation"
- "generate README"
- "create AGENTS.md"
- "start CHANGELOG"
- "document this codebase"

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill with 5-phase workflow |
| `references/configuration.md` | AskQuestion flows |
| `references/writing-standards.md` | Voice, tone, formatting rules |
| `references/self-documentation.md` | SSOT generation patterns |
| `references/doc-types.md` | README, AGENTS.md, CHANGELOG, API patterns |
| `references/docs-viewer.md` | Reference to tl-docs-viewer-create skill |
| `references/doc-rules.md` | Cursor rules for doc maintenance |
| `references/templates/` | 8 doc templates |
| `references/rules/` | 7 rule templates |

## Source Attribution

This is a quilted skill synthesized from 11 sources.

### Primary Sources

| Source | Weight | Borrowed |
|--------|--------|----------|
| [gemini-cli/docs-writer](https://skills.sh/google-gemini/gemini-cli/docs-writer) | 0.25 | 4-phase workflow, voice/tone rules, verification checklist |
| [shpigford/skills/readme](https://skills.sh/shpigford/skills/readme) | 0.15 | Exploration-first, 3 purposes, absurd thoroughness |
| [getsentry/skills/agents-md](https://skills.sh/getsentry/skills/agents-md) | 0.12 | AGENTS.md structure, brevity rules, file-scoped commands |
| [softaworks/crafting-effective-readmes](https://skills.sh/softaworks/agent-toolkit/crafting-effective-readmes) | 0.10 | Project type detection, audience analysis |

### Secondary Sources

| Source | Weight | Borrowed |
|--------|--------|----------|
| [itechmeat/changelog](https://skills.sh/itechmeat/llm-code/changelog) | 0.08 | CHANGELOG.md template, Keep a Changelog format |
| [patricio0312rev/api-docs-generator](https://skills.sh/patricio0312rev/skills/api-docs-generator) | 0.08 | OpenAPI patterns, API doc templates |
| [remotion-dev/remotion/writing-docs](https://skills.sh/remotion-dev/remotion/writing-docs) | 0.06 | Language brevity, API-per-page rule |
| [plaited/code-documentation](https://skills.sh/plaited/development-skills/code-documentation) | 0.05 | TSDoc patterns |
| [aj-geddes/markdown-documentation](https://skills.sh/aj-geddes/useful-ai-prompts/markdown-documentation) | 0.05 | GFM syntax, do/don't list |
| JamBase docs (local) | 0.04 | SSOT generation, hierarchical READMEs, source attribution |
| agents-md-create (local) | 0.02 | Project type templates |

### Excluded Sources (Moved to tl-docs-audit)

| Source | Reason |
|--------|--------|
| [openai-agents-python/docs-sync](https://skills.sh/openai/openai-agents-python/docs-sync) | Gap analysis moved to tl-docs-audit |
| [jezweb/docs-workflow](https://skills.sh/jezweb/claude-skills/docs-workflow) | Staleness audit moved to tl-docs-audit |

## Suite

Part of the `tl-docs` suite.

### Related Skills

- [tl-docs-audit](../tl-docs-audit/) — Audit docs coverage, find gaps, generate sync reports
- [tl-docs-viewer-create](../tl-docs-viewer-create/) — React admin UI for browsing docs/ folder

## License

MIT
