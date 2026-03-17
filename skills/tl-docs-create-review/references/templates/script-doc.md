# Script Documentation Template

Documentation template for CLI scripts generated from source headers.

---

## Template

```markdown
# {{SCRIPT_NAME}}

> **Last Updated:** {{DATE}}

{{DESCRIPTION}}

## Usage

```bash
pnpm script:{{SCRIPT_NAME}} [options]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--{{OPTION_1}}` | {{OPTION_1_DESC}} | {{DEFAULT_1}} |
| `--{{OPTION_2}}` | {{OPTION_2_DESC}} | {{DEFAULT_2}} |
| `-h, --help` | Show help | — |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `{{ENV_VAR_1}}` | Yes | {{ENV_VAR_1_DESC}} |
| `{{ENV_VAR_2}}` | No | {{ENV_VAR_2_DESC}} |

## Prerequisites

- {{PREREQ_1}}
- {{PREREQ_2}}

## Examples

```bash
# {{EXAMPLE_1_DESC}}
pnpm script:{{SCRIPT_NAME}} {{EXAMPLE_1_ARGS}}

# {{EXAMPLE_2_DESC}}
pnpm script:{{SCRIPT_NAME}} {{EXAMPLE_2_ARGS}}

# {{EXAMPLE_3_DESC}}
pnpm script:{{SCRIPT_NAME}} {{EXAMPLE_3_ARGS}}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| {{CODE}} | {{CODE_MEANING}} |

## Troubleshooting

### {{ISSUE_1}}

{{ISSUE_1_SOLUTION}}

### {{ISSUE_2}}

{{ISSUE_2_SOLUTION}}

## Related

- [{{RELATED_SCRIPT}}](./{{related-script}}.md)
- [{{RELATED_DOC}}]({{RELATED_DOC_PATH}})

---
_Source: `scripts/{{SCRIPT_NAME}}.ts`_
```

---

## Usage Notes

### Section Requirements

| Section | Required | Notes |
|---------|----------|-------|
| Usage | Yes | Basic invocation |
| Options | If any | All CLI flags |
| Environment Variables | If any | Required for script to work |
| Prerequisites | If any | What must exist before running |
| Examples | Yes | At least 2-3 common uses |
| Exit Codes | Recommended | Non-obvious codes |
| Troubleshooting | Optional | Common issues |

### Source Header Format

Scripts should have a structured header for parsing:

```typescript
/**
 * @script stripe-product-sync
 * @description Syncs products and prices from Stripe
 * 
 * @usage pnpm script:stripe-product-sync [--dry-run]
 * 
 * @options
 *   --dry-run    Preview changes
 *   --force      Overwrite existing
 * 
 * @envVars
 *   STRIPE_SECRET_KEY   Required
 *   DATABASE_URL        Required
 */
```

---

## Example

```markdown
# db-seed

> **Last Updated:** 2026-03-17

Seeds the development database with sample data.

## Usage

```bash
pnpm script:db-seed [options]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--clean` | Drop existing data before seeding | false |
| `--count` | Number of records per table | 10 |
| `--tables` | Specific tables to seed (comma-separated) | all |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |

## Prerequisites

- Database running (`docker compose up db`)
- Migrations applied (`pnpm db:migrate`)

## Examples

```bash
# Seed all tables with defaults
pnpm script:db-seed

# Clean slate with 50 records per table
pnpm script:db-seed --clean --count 50

# Seed only users and posts
pnpm script:db-seed --tables users,posts
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Database connection failed |
| 2 | Migration not applied |

## Related

- [db-migrate](./db-migrate.md)
- [Database Setup](../developer/setup.md#database)

---
_Source: `scripts/db-seed.ts`_
```

---

## Source Attribution

Based on JamBase script documentation patterns with structured headers.
