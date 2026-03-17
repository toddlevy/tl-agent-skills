# tl-docs-create-review

Create, review, and maintain documentation for any codebase with gap analysis, SSOT-driven generation, and standards enforcement.

## What This Skill Does

- **Assesses** existing documentation and identifies gaps
- **Creates** documentation from scratch or updates existing docs
- **Enforces** consistent writing standards
- **Generates** docs from code (scripts, env vars, API)
- **Optionally creates** Cursor rules for ongoing maintenance

## When to Use

- "create documentation"
- "review the docs"
- "audit doc coverage"
- "generate README"
- "create AGENTS.md"
- "sync docs with code"

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill with 6-phase workflow |
| `references/configuration.md` | AskQuestion flows and branching logic |
| `references/writing-standards.md` | Voice, tone, formatting rules |
| `references/gap-analysis.md` | Feature inventory and sync report workflow |
| `references/self-documentation.md` | SSOT generation patterns |
| `references/doc-types.md` | README, AGENTS.md, CHANGELOG, API patterns |
| `references/docs-viewer.md` | Reference to tl-docs-viewer skill |
| `references/doc-rules.md` | Cursor rules for doc maintenance |
| `references/templates/` | 8 doc templates |
| `references/rules/` | 7 rule templates |

## Source Attribution

This is a quilted skill synthesized from 16 sources.

### Tier 1: Primary Sources

| Source | Weight | Borrowed |
|--------|--------|----------|
| [gemini-cli/docs-writer](https://skills.sh/google-gemini/gemini-cli/docs-writer) | 0.20 | 4-phase workflow, voice/tone rules, verification checklist |
| [openai-agents-python/docs-sync](https://skills.sh/openai/openai-agents-python/docs-sync) | 0.15 | Gap analysis, feature inventory, sync report format |
| [shpigford/skills/readme](https://skills.sh/shpigford/skills/readme) | 0.12 | Exploration-first, 3 purposes, absurd thoroughness |
| [getsentry/skills/agents-md](https://skills.sh/getsentry/skills/agents-md) | 0.08 | AGENTS.md structure, brevity rules, file-scoped commands |

### Tier 2: Specialized Sources

| Source | Weight | Borrowed |
|--------|--------|----------|
| [softaworks/crafting-effective-readmes](https://skills.sh/softaworks/agent-toolkit/crafting-effective-readmes) | 0.06 | Project type detection, audience analysis |
| [jezweb/docs-workflow](https://skills.sh/jezweb/claude-skills/docs-workflow) | 0.06 | Lifecycle commands, staleness audit |
| [itechmeat/changelog](https://skills.sh/itechmeat/llm-code/changelog) | 0.05 | CHANGELOG.md template, Keep a Changelog format |
| [patricio0312rev/api-docs-generator](https://skills.sh/patricio0312rev/skills/api-docs-generator) | 0.05 | OpenAPI patterns, API doc templates |
| [vercel/next.js/update-docs](https://skills.sh/vercel/next.js/update-docs) | 0.04 | Code-to-docs mapping table |
| [remotion-dev/remotion/writing-docs](https://skills.sh/remotion-dev/remotion/writing-docs) | 0.04 | Language brevity, API-per-page rule |

### Tier 3: Supporting Sources

| Source | Weight | Borrowed |
|--------|--------|----------|
| [plaited/code-documentation](https://skills.sh/plaited/development-skills/code-documentation) | 0.04 | TSDoc patterns, maintenance workflow |
| [aj-geddes/markdown-documentation](https://skills.sh/aj-geddes/useful-ai-prompts/markdown-documentation) | 0.04 | GFM syntax, do/don't list |
| JamBase docs (local) | 0.04 | SSOT generation, hierarchical READMEs, source attribution |
| agents-md-create (local) | 0.02 | Project type templates |
| codebase-audit (local) | 0.01 | Finding categories, time-boxing |

### Excluded Sources

| Source | Reason |
|--------|--------|
| [am-will/openai-docs-skill](https://skills.sh/am-will/codex-skills/openai-docs-skill) | Different domain — MCP for fetching external docs |
| docs-code-snippets (local) | Implementation-focused (React components), not workflow |

## Suite

Part of the `tl-docs` suite.

### Related Skills

- **tl-docs-viewer** — React admin UI for browsing docs/ folder (separate skill)

## License

MIT
