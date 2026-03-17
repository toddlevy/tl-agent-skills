# Self-Documentation

Generate documentation from code as the single source of truth (SSOT). Patterns derived from JamBase documentation practices.

---

## Principles

1. **Code is canonical** — Documentation is generated from code, not maintained separately
2. **Source attribution** — Every generated doc includes a link to its source
3. **Freshness tracking** — Include "Last Updated" dates for staleness detection
4. **Hierarchical structure** — README files at each level point to relevant content

---

## Script Documentation

Generate documentation from script file headers.

### Header Format (Source)

Scripts should have a structured header block:

```typescript
/**
 * @script stripe-product-sync
 * @description Syncs products and prices from Stripe to local database
 * 
 * @usage pnpm script:stripe-product-sync [--dry-run] [--force]
 * 
 * @options
 *   --dry-run    Preview changes without writing to database
 *   --force      Overwrite local data even if newer
 * 
 * @envVars
 *   STRIPE_SECRET_KEY   Required - Stripe API key
 *   DATABASE_URL        Required - PostgreSQL connection
 * 
 * @prerequisites
 *   - Stripe account configured
 *   - Database running with migrations applied
 * 
 * @examples
 *   pnpm script:stripe-product-sync           # Full sync
 *   pnpm script:stripe-product-sync --dry-run # Preview only
 * 
 * @related
 *   - scripts/stripe-webhook-setup.ts
 *   - docs/stripe/integration.md
 */
```

### Generated Documentation

Parse the header and generate markdown:

```markdown
# stripe-product-sync

> **Last Updated:** 2026-03-17

Syncs products and prices from Stripe to local database.

## Usage

```bash
pnpm script:stripe-product-sync [--dry-run] [--force]
```

## Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Preview changes without writing to database |
| `--force` | Overwrite local data even if newer |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `STRIPE_SECRET_KEY` | Yes | Stripe API key |
| `DATABASE_URL` | Yes | PostgreSQL connection |

## Prerequisites

- Stripe account configured
- Database running with migrations applied

## Examples

```bash
# Full sync
pnpm script:stripe-product-sync

# Preview only
pnpm script:stripe-product-sync --dry-run
```

## Related

- [stripe-webhook-setup](./stripe-webhook-setup.md)
- [Stripe Integration Guide](../stripe/integration.md)

---
_Source: `scripts/stripe-product-sync.ts`_
```

### Generation Script Pattern

```typescript
interface ScriptDoc {
  name: string;
  description: string;
  usage: string;
  options: Array<{ flag: string; description: string }>;
  envVars: Array<{ name: string; required: boolean; description: string }>;
  prerequisites: string[];
  examples: string[];
  related: string[];
  sourcePath: string;
}

function parseScriptHeader(content: string, filePath: string): ScriptDoc {
  // Extract JSDoc block and parse @tags
}

function generateScriptMarkdown(doc: ScriptDoc): string {
  // Generate markdown from parsed structure
}
```

---

## Environment Variable Documentation

Generate environment variable reference from source files.

### Source Files to Parse

- `.env.example` — Canonical list of variables
- Config loader files — Default values and types
- Deployment manifests — Production requirements

### Generated Table Format

```markdown
# Environment Variables

> **Last Updated:** 2026-03-17

| Variable | Service(s) | Required | Default | Description |
|----------|------------|----------|---------|-------------|
| `DATABASE_URL` | api, worker | Yes | — | PostgreSQL connection string |
| `REDIS_URL` | api, worker | Yes | — | Redis connection for caching |
| `PORT` | api | No | `3000` | Server port |
| `LOG_LEVEL` | api, worker | No | `info` | Winston log level |
| `STRIPE_SECRET_KEY` | api | Yes | — | Stripe API key |
| `STRIPE_WEBHOOK_SECRET` | api | Yes | — | Stripe webhook signing secret |

## By Service

### API Server

Variables required for the API server:

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection |
| `PORT` | No | Server port (default: 3000) |
| `STRIPE_SECRET_KEY` | Yes | Stripe API key |

### Background Worker

Variables required for background job processing:

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection |
| `REDIS_URL` | Yes | Redis for job queue |

---
_Generated from: `.env.example`, `src/config/index.ts`_
```

### Detection Logic

```typescript
interface EnvVar {
  name: string;
  services: string[];
  required: boolean;
  defaultValue?: string;
  description: string;
  sources: string[];
}

function extractFromEnvExample(content: string): EnvVar[] {
  // Parse .env.example comments for descriptions
  // Example: # Database connection (required)
  //          DATABASE_URL=
}

function extractFromConfig(content: string): EnvVar[] {
  // Parse config files for defaults and required flags
  // Example: process.env.PORT || '3000'
}
```

---

## Hierarchical READMEs

Create README files at each documentation level.

### Root `docs/README.md`

```markdown
# Documentation

> **Last Updated:** 2026-03-17

Quick links to project documentation.

## Developer Guide

- [Getting Started](./developer/getting-started.md)
- [Architecture](./developer/architecture.md)
- [Scripts](./developer/scripts/README.md)

## Reference

- [API Reference](./reference/api/README.md)
- [Configuration](./reference/config.md)
- [Environment Variables](./reference/env-vars.md)

## Operations

- [Deployment](./operations/deployment.md)
- [Monitoring](./operations/monitoring.md)
```

### Section `docs/developer/scripts/README.md`

```markdown
# Scripts

> **Last Updated:** 2026-03-17

CLI scripts for development and operations tasks.

## Available Scripts

| Script | Description |
|--------|-------------|
| [stripe-product-sync](./stripe-product-sync.md) | Sync products from Stripe |
| [db-seed](./db-seed.md) | Seed development database |
| [generate-types](./generate-types.md) | Generate TypeScript types |

## Running Scripts

All scripts use pnpm:

```bash
pnpm script:<script-name> [options]
```

## Adding Scripts

See [Adding CLI Scripts](../contributing/scripts.md) for guidelines.
```

---

## Source Attribution

Every generated document includes a source footer.

### Format

```markdown
---
_Source: `path/to/source-file.ts`_
```

For multiple sources:

```markdown
---
_Generated from:_
- `scripts/stripe-product-sync.ts`
- `.env.example`
- `src/config/index.ts`
```

### Purpose

- **Traceability** — Know where to update when code changes
- **Verification** — Check if doc is stale vs source
- **Navigation** — Quick link to implementation

---

## Last Updated Pattern

Track document freshness with a blockquote at the top.

### Format

```markdown
> **Last Updated:** 2026-03-17
```

### Placement

Immediately after the H1 title:

```markdown
# Script Reference

> **Last Updated:** 2026-03-17

This document covers...
```

### Automation

Update the date when:
- Manual edits are made
- Regeneration from source occurs
- Related source files change

---

## Generation Workflow

### Manual Generation

1. Run generation script targeting specific doc type
2. Script parses source files
3. Generates markdown with templates
4. Writes to `docs/` with source attribution
5. Updates parent README if needed

### Automated Generation

Integrate with:
- Pre-commit hooks — Regenerate if source changed
- CI pipeline — Verify docs match source
- Watch mode — Regenerate on source file save

### Validation

After generation, verify:
- [ ] All sources parsed successfully
- [ ] No broken internal links
- [ ] Last Updated dates current
- [ ] Source attribution present
- [ ] Parent READMEs updated
