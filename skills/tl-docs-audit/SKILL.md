---
name: tl-docs-audit
description: Audit existing documentation for gaps, staleness, and sync issues. Generates sync reports with actionable findings. Use when reviewing doc coverage, finding outdated docs, or syncing docs with code.
license: MIT
metadata:
  moment: review
  quilted:
    version: 1
    synthesized: 2026-03-17
    sources:
      - url: https://skills.sh/openai/openai-agents-python/docs-sync
        borrowed:
          - "gap analysis"
          - "feature inventory"
          - "sync report format"
        weight: 0.35
      - url: https://skills.sh/vercel/next.js/update-docs
        borrowed:
          - "code-to-docs mapping table"
          - "shared content handling"
        weight: 0.25
      - url: https://skills.sh/jezweb/claude-skills/docs-workflow
        borrowed:
          - "lifecycle commands"
          - "staleness audit"
          - "staleness indicators"
        weight: 0.20
      - local: codebase-audit
        borrowed:
          - "finding categories"
          - "time-boxing"
        weight: 0.10
      - url: https://skills.sh/plaited/development-skills/code-documentation
        borrowed:
          - "maintenance workflow"
        weight: 0.10
    enhancements:
      - "Two-pass audit (doc-first + code-first)"
      - "Structured sync report template"
      - "Lifecycle integration triggers"
      - "AskQuestion for scope selection"
  surface:
    - repo
  output: decision
  risk: safe
  posture: opinionated
  suite: tl-docs
  related:
    - tl-docs-create
    - tl-docs-viewer-create
---

# Documentation Audit

Audit existing documentation for gaps, staleness, and sync issues. Generates actionable sync reports.

## When to Use

- "audit the docs"
- "review doc coverage"
- "find outdated docs"
- "sync docs with code"
- "docs audit"
- "check documentation gaps"
- Joining a project with existing documentation
- After major refactoring
- Quarterly documentation review

For creating new docs from scratch, see `tl-docs-create`.

## Outcomes

- **Decision**: Sync report with categorized findings
- **Decision**: Code-to-docs mapping table
- **Decision**: Prioritized list of proposed edits
- **Artifact** (optional): Fixed documentation

---

## Configuration Discovery

Before auditing, gather scope through structured questions. See `references/configuration.md` for full schemas.

### Question Flow Summary

1. **Light scan** — Inventory existing docs
2. **Scope** — Full audit / Changed files only / Specific areas
3. **Output** — Report only / Report + fixes
4. **Fix confirmation** — Per-finding approval (if fixing)

---

## Phase 1: Feature Inventory

Scan the codebase for documentable elements before comparing.

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

### CLI Commands
- `pnpm dev` — Start dev server
- `pnpm build` — Production build
```

---

## Phase 2: Doc-First Pass

Walk through existing docs and check coverage against the feature inventory.

### Process

1. List all documentation files
2. For each file, extract topics and features referenced
3. Cross-reference against feature inventory
4. Flag gaps by category

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

Create a mapping table for ongoing maintenance.

| Source Path | Doc Location | Notes |
|-------------|--------------|-------|
| `src/api/users.ts` | `docs/api/users.md` | REST endpoints |
| `src/config/index.ts` | `docs/reference/config.md` | Config schema |
| `drizzle/schema.ts` | `docs/reference/database.md` | Schema definitions |

### Verification Checklist

For each code element:

- [ ] Documented somewhere?
- [ ] Documentation accurate to current implementation?
- [ ] Examples work with current API?
- [ ] Linked from appropriate index/overview page?

---

## Phase 4: Sync Report

Generate a structured report of findings.

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

### Outdated Content

| Page | Issue | Correct Info |
|------|-------|--------------|
| `docs/config.md` | Default port shown as 8080 | Default is 3000 |

## Code-First Gaps

| Feature | Evidence | Suggested Location |
|---------|----------|-------------------|
| `validateEmail` helper | Exported in `src/utils/email.ts` | `docs/reference/utils.md` |

## Proposed Edits

1. **docs/api/users.md** — Add PATCH endpoint documentation
2. **README.md** — Add "Database Setup" section
```

---

## Phase 5: Optional Fixes

If user selected "Report + fixes", implement proposed edits.

### Fix Process

1. Present each proposed edit for confirmation
2. Use `tl-docs-create` writing standards for consistency
3. Add "Last Updated" date to modified files
4. Run verification checklist

---

## Lifecycle Integration

Run audits at key moments.

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

## Shared Content Handling

When content appears in multiple places, identify the source of truth.

### Principles

1. **Edit source, not duplicates** — Find the canonical location
2. **Use links over repetition** — Reference instead of copying
3. **Sync, don't diverge** — If duplication is necessary, ensure consistency

---

## References

| File | Purpose |
|------|---------|
| `references/configuration.md` | AskQuestion flows for scope selection |
| `references/sync-report.md` | Full sync report template |

---

## Related Skills

- [tl-docs-create](../tl-docs-create/SKILL.md) — Create documentation from scratch
- [tl-docs-viewer-create](../tl-docs-viewer-create/SKILL.md) — React admin UI for browsing docs/ folder
