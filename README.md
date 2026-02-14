# tl-agent-skills

> **For maintainers:** This file is intended as the root `README.md` for [github.com/toddlevy/tl-agent-skills](https://github.com/toddlevy/tl-agent-skills). Copy it into your clone as `README.md` to document staging/prod and structure.

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

### tl-openmeter (OpenMeter)

| Skill | Type | Purpose |
|-------|------|---------|
| `tl-openmeter-api/` | knowledge | REST API reference: endpoints, schemas, gotchas |
| `tl-openmeter-local-dev/` | knowledge + scripts | Local dev setup: Docker, ngrok, Stripe App, webhooks |
| `tl-openmeter-api-mcp-server/` | MCP server | Tools for calling local OpenMeter from Cursor |

---

## Skill Structure

Skills follow the [Agent Skills specification](https://agentskills.io/specification) with progressive disclosure:

```
tl-skill-name/
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

1. Create `tl-<skill-name>/` with `SKILL.md` (frontmatter: name, description, license, metadata).
2. Add `references/` for detailed documentation that shouldn't bloat `SKILL.md`.
3. Add `scripts/` for executable helpers (health checks, setup verification).
4. Add `assets/` for templates and static resources.
5. If the skill needs tools: add `tl-<skill-name>-mcp-server/` with Node/TS MCP server and `scripts/add-cursor-mcp.js`.
6. Work on **staging**, then merge to **main** for prod.

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

## Cursor Setup

For a skill that ships an MCP server:

1. From the server directory: `npm install && npm run build`
2. Run the install script to add the server to user config:  
   `node scripts/add-cursor-mcp.js`  
   Use `--dry-run` to see the diff first.

---

## License

MIT
