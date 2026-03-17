# Gap Analysis

Identify missing, outdated, and incorrect documentation through systematic inventory and cross-referencing. Synthesized from docs-sync and next.js update-docs skills.

---

## Overview

Gap analysis runs in two passes:
1. **Doc-first pass** — Walk existing docs, identify what's missing from code
2. **Code-first pass** — Map features to docs, find undocumented elements

The output is a structured sync report with actionable findings.

---

## Phase 1: Feature Inventory

Before comparing docs to code, build a complete inventory of documentable features.

### What to Inventory

| Category | Where to Look | What to Extract |
|----------|---------------|-----------------|
| **Public API** | `src/index.ts`, exported modules | Functions, classes, types |
| **Configuration** | `config/`, env files, schema files | Options, defaults, constraints |
| **Environment Variables** | `.env.example`, config loaders | Variable names, services, required vs optional |
| **CLI Commands** | `package.json` scripts, `bin/` | Command names, options, examples |
| **Routes/Endpoints** | `routes/`, `api/`, controllers | HTTP methods, paths, request/response |
| **Database Schema** | Migrations, `drizzle/schema.ts` | Tables, relations, constraints |
| **Components** | `components/`, `ui/` | Props, variants, usage patterns |

### Inventory Format

```markdown
## Feature Inventory

### Public API
- `createUser(options)` — Creates a new user
- `getUser(id)` — Retrieves user by ID
- `UserSchema` — Zod schema for user validation

### Configuration
- `PORT` (env) — Server port, default 3000
- `DATABASE_URL` (env, required) — PostgreSQL connection
- `LOG_LEVEL` (config) — winston log level, default "info"

### CLI Commands
- `pnpm dev` — Start dev server
- `pnpm build` — Production build
- `pnpm db:migrate` — Run migrations

### API Endpoints
- `POST /api/users` — Create user
- `GET /api/users/:id` — Get user
- `PATCH /api/users/:id` — Update user
```

---

## Phase 2: Doc-First Pass

Walk through existing documentation and check coverage against the feature inventory.

### Process

1. List all documentation files (`README.md`, `docs/**/*.md`, `AGENTS.md`, etc.)
2. For each file, extract:
   - Topics covered
   - Features referenced
   - Code examples shown
   - Links to other docs/code
3. Cross-reference against feature inventory
4. Flag gaps:
   - Features not mentioned
   - Features mentioned but outdated
   - Missing code examples
   - Broken links

### Finding Categories

| Category | Description | Example |
|----------|-------------|---------|
| **Missing** | Feature exists but not documented | API endpoint with no docs |
| **Outdated** | Doc describes old behavior | Renamed function, changed default |
| **Structural** | Doc exists but poorly organized | All endpoints on one page |
| **Orphaned** | Doc not linked from anywhere | Unreachable page |
| **Incomplete** | Doc exists but lacks depth | Only signature, no examples |

---

## Phase 3: Code-First Pass

Start from code and verify each element has adequate documentation.

### Code-to-Docs Mapping

Create a mapping table showing where code changes should update docs.

| Source Path | Doc Location | Notes |
|-------------|--------------|-------|
| `src/api/users.ts` | `docs/api/users.md` | REST endpoints |
| `src/config/index.ts` | `docs/reference/config.md` | Config schema |
| `drizzle/schema.ts` | `docs/reference/database.md` | Schema definitions |
| `package.json` scripts | `README.md` > Commands | Script docs |
| `.env.example` | `docs/reference/env-vars.md` | Env variables |

### Verification Checklist

For each code element:

- [ ] Documented somewhere?
- [ ] Documentation accurate to current implementation?
- [ ] Examples work with current API?
- [ ] Linked from appropriate index/overview page?

---

## Phase 4: Sync Report

Generate a structured report of findings for action.

### Report Template

```markdown
# Documentation Sync Report

Generated: YYYY-MM-DD
Scope: Full codebase analysis

## Summary

| Category | Count |
|----------|-------|
| Missing | 3 |
| Outdated | 2 |
| Structural | 1 |
| Orphaned | 0 |

## Doc-First Findings

### Missing Content

| Page | Missing | Evidence |
|------|---------|----------|
| `docs/api/users.md` | PATCH endpoint | `src/api/users.ts:45` exports `updateUser` |
| `README.md` | Database setup | Migration scripts in `package.json` |

### Outdated Content

| Page | Issue | Correct Info |
|------|-------|--------------|
| `docs/config.md` | Default port shown as 8080 | Default is 3000 (see `src/config/index.ts:12`) |
| `AGENTS.md` | Missing `pnpm test:e2e` command | Added in recent PR |

## Code-First Gaps

| Feature | Evidence | Suggested Location |
|---------|----------|-------------------|
| `validateEmail` helper | Exported in `src/utils/email.ts` | `docs/reference/utils.md` |
| Rate limiting middleware | Used in `src/middleware/rateLimit.ts` | `docs/api/rate-limits.md` |

## Structural Issues

| Page | Issue | Recommendation |
|------|-------|----------------|
| `docs/api/README.md` | 15 endpoints on one page | Split by resource (users, posts, etc.) |

## Proposed Edits

1. **docs/api/users.md** — Add PATCH endpoint documentation
2. **README.md** — Add "Database Setup" section with migration commands
3. **docs/config.md** — Fix default port value
4. **AGENTS.md** — Add `pnpm test:e2e` to commands
5. **docs/reference/utils.md** (NEW) — Document utility functions
```

---

## Shared Content Handling

From next.js skill: When content appears in multiple places, identify the source of truth.

### Principles

1. **Edit source, not duplicates** — Find the canonical location
2. **Use links over repetition** — Reference instead of copying
3. **Sync, don't diverge** — If duplication is necessary, ensure consistency

### Common Duplications

| Content | Often Duplicated In | Canonical Location |
|---------|---------------------|-------------------|
| Installation steps | README, docs, wiki | README.md |
| Config options | README, config.md, code comments | `docs/reference/config.md` |
| API examples | README, API docs, tutorials | API reference docs |

---

## Lifecycle Integration

Run gap analysis at key moments:

| Trigger | Scope | Action |
|---------|-------|--------|
| New feature merged | Changed files only | Check for doc gaps |
| Major release | Full codebase | Complete sync report |
| Quarterly review | Full codebase | Staleness audit |
| Developer onboarding | Areas of responsibility | Verify docs are current |

### Staleness Indicators

Flag docs as potentially stale if:

- Not updated in 90+ days
- References deprecated APIs
- Links to removed files
- Mentions outdated dependency versions

---

## Output Artifacts

Gap analysis produces:

1. **Feature Inventory** — Complete list of documentable elements
2. **Sync Report** — Findings categorized by type
3. **Code-to-Docs Mapping** — Table for ongoing maintenance
4. **Proposed Edits** — Prioritized list of changes needed
