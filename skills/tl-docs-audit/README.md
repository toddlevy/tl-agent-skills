# tl-docs-audit

Audit existing documentation for gaps, staleness, and sync issues. Generates actionable sync reports.

## What This Skill Does

- **Inventories** all documentable features in the codebase
- **Audits** existing docs with two-pass analysis (doc-first + code-first)
- **Categorizes** findings (missing, outdated, structural, orphaned, incomplete)
- **Generates** structured sync reports with evidence
- **Optionally fixes** issues with user approval

For creating new docs from scratch, see `tl-docs-create`.

## When to Use

- "audit the docs"
- "review doc coverage"
- "find outdated docs"
- "sync docs with code"
- After major refactoring
- Quarterly documentation review

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill with 5-phase audit workflow |
| `references/configuration.md` | AskQuestion flows for scope selection |
| `references/sync-report.md` | Report templates (full, compact, staleness) |

## Finding Categories

| Category | Description |
|----------|-------------|
| **Missing** | Feature exists but not documented |
| **Outdated** | Doc describes old behavior |
| **Structural** | Doc poorly organized |
| **Orphaned** | Doc not linked from anywhere |
| **Incomplete** | Doc lacks depth or examples |

## Source Attribution

This is a quilted skill synthesized from 5 sources.

| Source | Weight | Borrowed |
|--------|--------|----------|
| [openai-agents-python/docs-sync](https://skills.sh/openai/openai-agents-python/docs-sync) | 0.35 | Gap analysis, feature inventory, sync report format |
| [vercel/next.js/update-docs](https://skills.sh/vercel/next.js/update-docs) | 0.25 | Code-to-docs mapping table, shared content handling |
| [jezweb/docs-workflow](https://skills.sh/jezweb/claude-skills/docs-workflow) | 0.20 | Lifecycle commands, staleness audit, staleness indicators |
| codebase-audit (local) | 0.10 | Finding categories, time-boxing |
| [plaited/code-documentation](https://skills.sh/plaited/development-skills/code-documentation) | 0.10 | Maintenance workflow |

## Suite

Part of the `tl-docs` suite.

### Related Skills

- **tl-docs-create** — Create documentation from scratch
- **tl-docs-viewer-create** — React admin UI for browsing docs/ folder

## License

MIT
