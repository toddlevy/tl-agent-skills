# tl-agent-skills

Reusable agent skills and optional MCP servers — project-agnostic, for use with Cursor, Codex, Copilot, and other AI agents. Follows the [Agent Skills open standard](https://agentskills.io/specification).

**Repo:** [https://github.com/toddlevy/tl-agent-skills](https://github.com/toddlevy/tl-agent-skills)

---

## Branches

| Branch   | Purpose |
|----------|---------|
| **staging** | Work in progress, PRs, integration checks. Create or use this for new skills before release. |
| **main**    | Production. Stable, released skills. Merge from `staging` after review. |

Default branch can be `main`; use `staging` for development.

---

## Suites

Skills are organized into **suites** — groups of related skills that cross-reference each other via `metadata.suite` and `metadata.related` in frontmatter.

### tl-agent-plan (Plan Lifecycle)

| Skill | Type | Purpose |
|-------|------|---------|
| `skills/tl-agent-plan-create/` | methodology | Structured plan creation with strategic/technical templates |
| `skills/tl-agent-plan-audit/` | methodology | Pre-execution audit: critique, pre-mortem, parallelization, readiness |

### tl-database (Database)

| Skill | Type | Purpose |
|-------|------|---------|
| `skills/tl-kysely-patterns/` | knowledge | Type-safe SQL with Kysely: query patterns, JSONB, migrations, pitfalls |
| `skills/tl-pg-boss/` | knowledge | PostgreSQL job queue with exactly-once delivery via SKIP LOCKED |

### tl-openmeter (OpenMeter)

| Skill | Type | Purpose |
|-------|------|---------|
| `skills/tl-openmeter-api/` | knowledge | REST API reference: endpoints, schemas, gotchas |
| `skills/tl-openmeter-local-dev/` | knowledge + scripts | Local dev setup: Docker, ngrok, Stripe App, webhooks |
| `skills/tl-openmeter-api-mcp-server/` | MCP server | Tools for calling local OpenMeter from Cursor |

---

## Skill Structure

All skills live in the `skills/` directory. Each skill follows the [Agent Skills specification](https://agentskills.io/specification) with progressive disclosure:

```
skills/
└── tl-skill-name/
├── SKILL.md              # Required: instructions + metadata (<500 lines)
├── references/           # Optional: detailed docs (loaded on demand)
│   ├── REFERENCE.md      # Environment vars, config, troubleshooting
│   └── topic.md          # Focused deep dives
├── scripts/              # Optional: executable verification/setup scripts
│   ├── verify-setup.ps1  # PowerShell health check
│   └── verify-setup.sh   # Bash health check
└── assets/               # Optional: templates, schemas, data files
    └── env.template      # Environment variable template
```

### Progressive Disclosure

1. **Metadata** (~100 tokens): `name` + `description` loaded at startup for all skills
2. **Instructions** (<5000 tokens): Full `SKILL.md` body loaded when skill is activated
3. **Resources** (as needed): `references/`, `scripts/`, `assets/` loaded only when required

---

## Adding a New Skill

1. Create `skills/tl-<skill-name>/` with `SKILL.md` (frontmatter: name, description, license, metadata).
2. Add `references/` for detailed documentation that shouldn't bloat `SKILL.md`.
3. Add `scripts/` for executable helpers (health checks, setup verification).
4. Add `assets/` for templates and static resources.
5. If the skill needs tools: add `skills/tl-<skill-name>-mcp-server/` with Node/TS MCP server and `scripts/add-cursor-mcp.js`.
6. Run `agentskills validate skills/tl-<skill-name>` to verify before pushing.
7. Work on **staging**, then merge to **main** for prod.

### Naming Convention

All skills use the `tl-` prefix followed by a RESTful-style slug.

**Format**: `tl-{product}-{resource}[-{action}]`

The slug reads like a REST path: product first, then the resource or concept, then an optional action or qualifier.

| Pattern | Example | Reads as |
|---------|---------|----------|
| `tl-{product}-{resource}` | `tl-openmeter-api` | OpenMeter → API reference |
| `tl-{product}-{resource}-{qualifier}` | `tl-openmeter-local-dev` | OpenMeter → local dev setup |
| `tl-{product}-{resource}-{server}` | `tl-openmeter-api-mcp-server` | OpenMeter → API → MCP server |
| `tl-{domain}-{action}` | `tl-agent-skill-create` | Agent skill → create |

**Rules**:
- Prefix: always `tl-`
- Segments: lowercase, hyphen-separated
- Max 64 characters (per [Agent Skills spec](https://agentskills.io/specification))
- No consecutive hyphens (`--`)
- Folder name **must** match the `name` field in SKILL.md frontmatter

**Suite grouping**: Skills in the same suite share a common `tl-{product}` prefix (e.g., `tl-openmeter-*`). This makes them sort together in file listings and easy to discover.

See the **tl-agent-skill-create** skill for the full checklist.

---

## Validation

Skills are validated against the [Agent Skills specification](https://agentskills.io/specification) using the [`skills-ref`](https://pypi.org/project/skills-ref/) reference library. CI runs validation automatically on every push and PR.

### Install

```bash
pip install skills-ref
```

Or with [uv](https://docs.astral.sh/uv/):

```bash
uv tool install skills-ref
```

### Validate a single skill

```bash
agentskills validate skills/tl-openmeter-api
```

### Validate all skills

```bash
# Bash
bash scripts/validate-all.sh

# PowerShell
pwsh scripts/validate-all.ps1
```

The scripts discover skill directories automatically (any directory containing `SKILL.md`) and exit non-zero if any fail.

---

## Cursor Setup

For a skill that ships an MCP server (e.g., `skills/tl-openmeter-api-mcp-server/`):

1. From the server directory: `npm install && npm run build`
2. Run the install script to add the server to user config:  
   `node scripts/add-cursor-mcp.js`  
   Use `--dry-run` to see the diff first.

---

## License

MIT
