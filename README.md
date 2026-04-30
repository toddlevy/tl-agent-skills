# tl-agent-skills

A curated collection of [Agent Skills](https://docs.anthropic.com/en/docs/agent-skills) authored by Todd Levy for use with Cursor, Claude Code, and other agent runtimes that support the Anthropic Agent Skills specification. Each skill is a self-contained `SKILL.md` (with optional `references/`, `scripts/`, and `assets/` folders) that gives an agent durable, composable expertise in a specific domain.

## Install

Install all skills into the universal global skills directory (`~/.agents/skills/`):

```powershell
npx skills add toddlevy/tl-agent-skills -g -y --agent universal
```

This is the canonical install command — use it for both fresh installs and updates. It overwrites every previously installed skill folder with the latest version from `origin/main`.

## Skills

### Plan suite

| Skill | Purpose |
|-------|---------|
| [`tl-agent-plan-create`](skills/tl-agent-plan-create/SKILL.md) | Create structured plan documents for features, projects, or multi-phase tasks. |
| [`tl-agent-plan-audit`](skills/tl-agent-plan-audit/SKILL.md) | Audit plan documents before execution and produce verification receipts. |
| [`tl-agent-plan-execute`](skills/tl-agent-plan-execute/SKILL.md) | Execute a verified plan, consuming audit receipts to avoid redundant re-verification. |

### Documentation suite

| Skill | Purpose |
|-------|---------|
| [`tl-docs-create`](skills/tl-docs-create/SKILL.md) | Create documentation from scratch with SSOT-driven generation and writing standards. |
| [`tl-docs-audit`](skills/tl-docs-audit/SKILL.md) | Audit existing documentation for gaps, staleness, and sync issues. |
| [`tl-docs-viewer-create`](skills/tl-docs-viewer-create/SKILL.md) | Build a React admin UI for browsing docs with tree navigation, markdown, and Mermaid. |

### OpenMeter suite

| Skill | Purpose |
|-------|---------|
| [`tl-openmeter-api`](skills/tl-openmeter-api/SKILL.md) | Reference for the OpenMeter REST API: metering, billing, entitlements, subscriptions. |
| [`tl-openmeter-local-dev`](skills/tl-openmeter-local-dev/SKILL.md) | Set up and troubleshoot OpenMeter locally with Docker, ngrok, and the Stripe app. |
| [`tl-openmeter-api-mcp-server`](skills/tl-openmeter-api-mcp-server/SKILL.md) | MCP server exposing local OpenMeter as tools for Cursor and other AI assistants. |

### Code quality and architecture

| Skill | Purpose |
|-------|---------|
| [`tl-first-principles`](skills/tl-first-principles/SKILL.md) | Foundational software design principles traced to their intellectual origins. |
| [`tl-complexity-assessment`](skills/tl-complexity-assessment/SKILL.md) | Find large files, god modules, and refactoring candidates in TS/JS/React codebases. |
| [`tl-knip`](skills/tl-knip/SKILL.md) | Find and remove unused files, dependencies, and exports using Knip. |
| [`tl-devlog`](skills/tl-devlog/SKILL.md) | Maintain a structured `DEVLOG.md` capturing decisions, milestones, and incidents. |

### Data and integrations

| Skill | Purpose |
|-------|---------|
| [`tl-kysely-patterns`](skills/tl-kysely-patterns/SKILL.md) | Type-safe SQL query building with Kysely for PostgreSQL. |
| [`tl-pg-boss`](skills/tl-pg-boss/SKILL.md) | PostgreSQL-backed job queue with exactly-once delivery via SKIP LOCKED. |
| [`tl-schema-org`](skills/tl-schema-org/SKILL.md) | The full Schema.org vocabulary with production patterns for JSON-LD, DBs, and APIs. |
| [`tl-live-music-data`](skills/tl-live-music-data/SKILL.md) | Reference for live music APIs (MusicBrainz, Setlist.fm, JamBase, Bandsintown, etc.). |

## License & Attribution

This project is licensed under the [MIT License](LICENSE) — see the `LICENSE` file at the repo root and the per-skill `LICENSE` file inside each `skills/<name>/` folder. The MIT license permits use, modification, and redistribution provided the copyright notice and license text are preserved.

Each `SKILL.md` carries an SPDX license header (`SPDX-License-Identifier: MIT`) immediately after its YAML frontmatter so the license travels with the file when individual skills are copied or vendored into other projects. Please preserve that header.

Several skills in this repo are **quilted** — synthesized from multiple upstream sources with per-source weights and attribution recorded in each skill's `metadata.quilted` block. See [NOTICE](NOTICE) for the consolidated list of upstream sources by skill.

## Author

**Todd Levy** — `<toddlevy@gmail.com>` — [github.com/toddlevy](https://github.com/toddlevy)

## Contributing

This is a single-author repository. If you find a bug or have a suggestion, open an issue at [github.com/toddlevy/tl-agent-skills/issues](https://github.com/toddlevy/tl-agent-skills/issues).
