# Migrations, Type Generation, and Plugins

Kysely migration setup with kysely-ctl, recommended PostgreSQL column types, type generation, plugins, Neon dialect, and common schema gotchas.

## kysely-ctl Configuration

```typescript
// kysely.config.ts
import { PostgresDialect } from "kysely"
import { defineConfig } from "kysely-ctl"
import pg from "pg"

export default defineConfig({
  dialect: new PostgresDialect({
    pool: new pg.Pool({
      connectionString: process.env.DATABASE_URL,
    }),
  }),
  migrations: {
    migrationFolder: "src/db/migrations",
  },
  seeds: {
    seedFolder: "src/db/seeds",
  },
})
```

## Migration Commands

```bash
npx kysely migrate:make migration-name   # create migration file
npx kysely migrate:latest                # run all pending migrations
npx kysely migrate:down                  # rollback last migration
npx kysely seed make seed-name           # create seed file
npx kysely seed run                      # run all seeds
```

## Migrator Configuration ([Docs](https://kysely.dev/docs/migrations), [API](https://kysely-org.github.io/kysely-apidoc/classes/Migrator.html))

### allowUnorderedMigrations ([#697](https://github.com/kysely-org/kysely/issues/697))

When team branches add migrations concurrently, merging can produce out-of-order migration names. By default the Migrator rejects this. Enable permissive ordering:

```typescript
import { Migrator, FileMigrationProvider } from "kysely"
import path from "path"
import { promises as fs } from "fs"

const migrator = new Migrator({
  db,
  provider: new FileMigrationProvider({
    fs,
    path,
    migrationFolder: path.join(__dirname, "migrations"),
  }),
  allowUnorderedMigrations: true,
})

const { error, results } = await migrator.migrateToLatest()

results?.forEach((result) => {
  if (result.status === "Success") {
    console.log(`Migration "${result.migrationName}" executed`)
  } else if (result.status === "Error") {
    console.error(`Migration "${result.migrationName}" failed`)
  }
})

if (error) {
  console.error("Migration failed", error)
  process.exit(1)
}
```

### Migration locks

The Migrator acquires a database-level lock before running migrations. Parallel callers are serialized. Locks are released on crash or connection loss.

### Custom MigrationProvider

For non-filesystem migration sources (bundled, database-stored, etc.):

```typescript
import { MigrationProvider, Migration } from "kysely"

class CustomMigrationProvider implements MigrationProvider {
  async getMigrations(): Promise<Record<string, Migration>> {
    return {
      "2025_01_01_create_user": {
        up: async (db) => { /* ... */ },
        down: async (db) => { /* ... */ },
      },
    }
  }
}
```

## Migration File Structure

Always use `Kysely<any>` -- migrations are frozen in time and should not depend on current schema types.

```typescript
import type { Kysely } from "kysely"
import { sql } from "kysely"

export async function up(db: Kysely<any>): Promise<void> {
  await db.schema
    .createTable("user")
    .addColumn("id", "bigint", (col) => col.primaryKey().generatedAlwaysAsIdentity())
    .addColumn("email", "text", (col) => col.notNull().unique())
    .addColumn("name", "text", (col) => col.notNull())
    .addColumn("metadata", "jsonb")
    .addColumn("created_at", "timestamptz", (col) => col.notNull().defaultTo(sql`now()`))
    .execute()

  await db.schema
    .createIndex("idx_user_email")
    .on("user")
    .column("email")
    .execute()
}

export async function down(db: Kysely<any>): Promise<void> {
  await db.schema.dropTable("user").execute()
}
```

## Recommended Column Types

| Use Case | Type | Rationale |
|----------|------|-----------|
| Primary key | `"bigint"` + `.generatedAlwaysAsIdentity()` | SQL standard; prevents accidental manual ID inserts (unlike serial/bigserial) |
| Timestamps | `"timestamptz"` | Stores UTC, converts to client timezone. Never use `timestamp` (loses timezone) |
| Money / decimals | `"numeric(10, 2)"` | Exact decimal math. Never use float/real/double (rounding errors) |
| Strings | `"text"` | Same performance as varchar, no length limit. Use `varchar(n)` only for hard constraints |
| JSON data | `"jsonb"` | Binary, indexable, faster queries. Never use `json` (stored as text, no indexing) |
| Foreign keys | Match the referenced column type | **Always create an index manually** -- PostgreSQL does not auto-index FKs |

### Foreign Key Indexes

```typescript
// Always add after creating tables with FK columns
await db.schema
  .createIndex("idx_order_user_id")
  .on("order")
  .column("user_id")
  .execute()
```

### Data Type Gotcha

```typescript
// CORRECT -- space after comma
.addColumn("price", "numeric(10, 2)")

// WRONG -- fails with "invalid column data type"
.addColumn("price", "numeric(10,2)")

// For complex types, use sql template
.addColumn("price", sql`numeric(10, 2)`)
```

## Type Generation

### kysely-codegen (recommended)

Generate TypeScript types from your live database schema:

```bash
npx kysely-codegen --url "postgresql://..." --out-file src/db/db.d.ts
```

Generated types use:
- `Generated<T>` for auto-increment / identity columns (optional on insert)
- `ColumnType<Select, Insert, Update>` for different operation types
- `Timestamp` for timestamptz columns

#### Config file approach

For projects with JSONB columns or custom type overrides, use a `.kysely-codegenrc.json`:

```json
{
  "dialect": "postgres",
  "camelCase": false,
  "outFile": "./src/db/kysely-types.ts",
  "customImports": {
    "./json-types": ["MyJsonType", "MyEnum"]
  },
  "overrides": {
    "columns": {
      "users.metadata": "MyJsonType",
      "users.status": "MyEnum"
    }
  }
}
```

```bash
npx kysely-codegen --config-file .kysely-codegenrc.json
```

The `customImports` and `overrides.columns` fields let you map JSONB columns to specific TypeScript types rather than generic `Json`.

#### DATE as String

```bash
npx kysely-codegen \
  --url="$DATABASE_URL" \
  --out-file=server/db/db.d.ts \
  --dialect=postgres \
  --date-parser=string
```

### Alternative type generators

| Generator | Source of Truth | Best For |
|-----------|-----------------|----------|
| `kysely-codegen` | Live database | Standard approach; database is source of truth |
| `prisma-kysely` | `schema.prisma` | Teams using Prisma migrations but wanting Kysely queries |
| `kanel-kysely` | Live database | PostgreSQL-specific; extends the mature kanel generator |

## DATE Column Timezone Fix

By default, the `pg` driver converts DATE columns to JavaScript `Date` objects, causing timezone issues:

```
Database: 2025-01-01 (just a date)
JS Date:  2025-01-01T00:00:00.000Z (UTC midnight)
User in NYC sees: Dec 31, 2024 (5 hours behind UTC)
```

Configure `pg` to return DATE as string:

```typescript
import pg from "pg"

const DATE_OID = 1082
pg.types.setTypeParser(DATE_OID, (val: string) => val)
```

Now DATE columns return strings like `"2025-01-01"` and the frontend handles formatting respecting the user's timezone.

TIMESTAMPTZ columns already handle timezones correctly -- this fix applies to DATE only.

## Plugins

```typescript
const db = new Kysely<Database>({
  dialect: new PostgresDialect({ pool }),
  plugins: [new CamelCasePlugin()],
})
```

### Built-in Plugins

| Plugin | Purpose | Notes |
|--------|---------|-------|
| `CamelCasePlugin` | Converts snake_case DB columns to camelCase in JS | **Warning below** |
| `DeduplicateJoinsPlugin` | Removes duplicate joins from dynamic queries | Useful with helper functions that add joins |
| `ParseJSONResultsPlugin` | Auto-parses JSON columns returned as strings | Needed for some third-party dialects; `pg` driver parses JSON natively |
| `HandleEmptyInListsPlugin` | Handles empty `IN ()` / `NOT IN ()` gracefully | Prevents SQL syntax errors from empty arrays |

### CamelCasePlugin Warning

`CamelCasePlugin` converts snake_case identifiers to camelCase in the builder layer. However, raw `sql` template queries **bypass the plugin entirely**. If your codebase uses significant raw SQL alongside the builder, you end up with inconsistent naming:

```typescript
// Builder: camelCase (via plugin)
await db.selectFrom("user").select("firstName").execute()

// Raw SQL: still snake_case (plugin doesn't transform)
await sql<{first_name: string}>`SELECT first_name FROM user`.execute(db)
```

**Recommendation**: If you use raw SQL for analytics, CTEs, or complex queries, avoid `CamelCasePlugin` and keep snake_case throughout. Set `"camelCase": false` in your kysely-codegen config.

## Connection Setup

### Standard PostgresDialect (pg)

```typescript
import { Kysely, PostgresDialect } from "kysely"
import pg from "pg"
import type { Database } from "./db.d.ts"

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,
})

export const db = new Kysely<Database>({
  dialect: new PostgresDialect({ pool }),
})
```

### Neon Serverless (HTTP)

For edge/serverless environments (Vercel Edge, Cloudflare Workers) where persistent connections are not available:

```typescript
import { Kysely } from "kysely"
import { NeonHTTPDialect } from "kysely-neon"

const db = new Kysely<Database>({
  dialect: new NeonHTTPDialect({
    connectionString: process.env.DATABASE_URL!,
  }),
})
```

```bash
npm install kysely kysely-neon @neondatabase/serverless
```

The HTTP dialect is stateless -- it does not support interactive transactions. For traditional Node.js servers connecting to Neon, use the standard `PostgresDialect` with `pg` Pool instead (Neon is pg-compatible via WebSockets).

### Logging

```typescript
const db = new Kysely<Database>({
  dialect: new PostgresDialect({ pool }),
  log: ["query", "error"],
})
```
