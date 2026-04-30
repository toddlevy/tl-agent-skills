---
name: tl-kysely-patterns
description: >-
  Type-safe SQL query building with Kysely for PostgreSQL. Covers query patterns,
  ExpressionBuilder, JSONB/arrays, migrations, and common pitfalls. Use when writing
  Kysely queries, creating migrations, debugging type issues, or working with a Kysely codebase.
license: MIT
metadata:
  version: "2.0"
  moment: implement
  surface:
    - db
  output: patch
  risk: low
  effort: low
  posture: guided
  agentFit: repo-write
  dryRun: full
  author: Todd Levy <toddlevy@gmail.com>
  homepage: https://github.com/toddlevy/tl-agent-skills
  suite: database
  portability: high
  related:
    - tl-pg-boss
  quilted:
    version: 2
    synthesized: 2026-04-15
    sources:
      - url: https://github.com/gallop-systems/claude-skills/skills/kysely-postgres/SKILL.md
        borrowed:
          - "ExpressionBuilder cheat sheet"
          - "eb.val vs eb.lit"
          - "Pitfalls section"
          - "Query patterns (references)"
          - "JSONB/array patterns (references)"
          - "Relations and json helpers (references)"
          - "Migration patterns and column types (references)"
          - "Type generation with kysely-codegen (references)"
        weight: 0.45
      - url: https://kysely.dev/llms.txt
        borrowed:
          - "Expression<T> composability recipe (references)"
          - "compile/InferResult splitting (references)"
          - "DummyDriver cold instances (references)"
          - "Schemas/withSchema recipe"
          - "Extending Kysely recipe (json helper, Expression patterns)"
          - "Data types recipe (driver as source of truth)"
          - "Logging recipe (LogEvent structure)"
          - "DISTINCT ON, controlled transactions, savepoints examples"
          - "Introspection recipe"
          - "Migrations (allowUnorderedMigrations, locks, FileMigrationProvider)"
        weight: 0.30
      - url: https://github.com/TerminalSkills/skills/skills/kysely/SKILL.md
        borrowed:
          - "Overview positioning"
          - "Selectable/Insertable/Updateable framing"
        weight: 0.05
      - url: https://github.com/kysely-org/kysely/issues
        borrowed:
          - "#310, #577: $narrowType for WHERE null narrowing"
          - "#330: RLS + connection pinning patterns"
          - "#697: allowUnorderedMigrations for team branches"
          - "#1036: CamelCasePlugin + custom pg parser interaction"
          - "#1059: selectAll('table') fix for json helper typing"
          - "#1412: JSON aggregation type drift (Date -> string)"
          - "#209: JSONB insert serialization patterns"
        weight: 0.15
      - url: https://kysely-org.github.io/kysely-apidoc
        borrowed:
          - "DynamicModule (db.dynamic.ref/table) API"
          - "Kysely#connection API"
          - "SelectQueryBuilder#stream API"
          - "SchemaModule (createView, refreshMaterializedView)"
          - "Kysely#mergeInto API"
          - "Migrator + MigrationProvider API"
          - "DatabaseIntrospector API"
        weight: 0.05
    excluded:
      - url: https://agentskills.so/skills/bobmatnyc-claude-mpm-skills-kysely
        reason: "Content unreachable; appears to be a subset of gallop-systems"
    enhancements:
      - "Decision flowchart matching drizzle-patterns style"
      - "Lean SKILL.md with progressive disclosure via reference files"
      - "PostgreSQL-primary dialect focus"
      - "Official resources section (llms-full.txt, playground, API docs)"
      - "Real-world patterns: sql.raw/sql.join, CamelCasePlugin warning, toJsonb scoping"
      - "Ecosystem reference file (pagination, auth adapter, Fastify plugin, Supabase, Kysera)"
      - "v2: Corrected sql.ref -> db.dynamic.ref for runtime columns"
      - "v2: Corrected toJsonb scope (pg auto-serializes; helper only for sql templates)"
      - "v2: Corrected selectAll fix to use selectAll('table') per maintainer"
      - "v2: Added 4 expert pitfalls (pool sessions, $narrowType, migration ordering, JSON type drift)"
      - "v2: Advanced patterns reference (multi-tenant, RLS, streaming, MERGE, views, FTS, testing)"
      - "v2: Migration reference expanded (Migrator API, allowUnorderedMigrations, custom providers)"
      - "v2: All additions sourced to official docs, API docs, or GitHub issues"
---

<!-- Copyright (c) 2026 Todd Levy. Licensed under MIT. SPDX-License-Identifier: MIT -->

# Kysely: Type-Safe SQL Patterns

Kysely (pronounced "Key-Seh-Lee") is a type-safe TypeScript SQL query builder. It generates plain SQL with zero runtime ORM overhead. Every query is validated at compile time with full autocompletion.

Kysely is **not an ORM** -- no relations, no lazy loading, no magic. Just SQL with types.

## When to Use

- "write a Kysely query"
- "create database migration"
- "add a new table"
- "query with joins / subqueries / CTEs"
- "JSONB or array column operations"
- Working with an existing Kysely + PostgreSQL codebase
- Debugging Kysely type inference issues

## Outcomes

- **Artifact**: Type-safe queries using ExpressionBuilder patterns
- **Artifact**: Migration files via kysely-ctl
- **Decision**: When to use query builder vs `sql` template tag

## Core Philosophy

Prefer Kysely's query builder for everything it can express. Fall back to `sql` template tag only when the builder lacks support.

| Use Case | Approach |
|----------|----------|
| **Schema definitions** | Kysely migrations (`db.schema.createTable`) |
| **Simple CRUD** | Query builder (`selectFrom`, `insertInto`, `updateTable`, `deleteFrom`) |
| **JOINs (any complexity)** | Query builder (callback format for complex joins) |
| **Aggregations / GROUP BY** | Query builder with `eb.fn` |
| **CTEs** | Query builder (`.with()`) |
| **Relations / nested JSON** | `jsonArrayFrom` / `jsonObjectFrom` helpers |
| **Conditional queries** | `$if()` or dynamic filter arrays |
| **Reusable fragments** | `Expression<T>` helper functions |
| **Dynamic columns/tables** | `db.dynamic.ref()` / `db.dynamic.table()` with allowlisted values |
| **Dynamic SQL fragments** | `sql.raw()` with allowlisted values, `sql.join()` for arrays |
| **Dialect-specific syntax** | `sql` template tag |
| **Unsupported operators** | `sql` template tag |

```
Need a query?
  Can Kysely's builder express it?
    YES -> Use the query builder (type-safe, composable)
    NO  -> Use sql`` template tag (always type your output: sql<Type>`...`)
```

## ExpressionBuilder (eb) Cheat Sheet

The `eb` callback parameter is the foundation of type-safe query building:

| Method | Purpose | Example |
|--------|---------|---------|
| `eb.ref("col")` | Column reference | `eb.ref("user.email")` |
| `eb.val(value)` | Parameterized value ($1) | `eb.val("hello")` |
| `eb.lit(value)` | SQL literal (numbers, bools, null only) | `eb.lit(0)`, `eb.lit(null)` |
| `eb.fn<T>("name", [...])` | Typed function call | `eb.fn<string>("upper", [eb.ref("email")])` |
| `eb.fn.count("col")` | COUNT aggregate | `eb.fn.count("id").as("count")` |
| `eb.fn.sum / avg / min / max` | Other aggregates | `eb.fn.sum("amount").as("total")` |
| `eb.fn.coalesce(col, fallback)` | COALESCE | `eb.fn.coalesce("col", eb.val(0))` |
| `eb.case().when().then().else().end()` | CASE expression | see [query-patterns.md](references/query-patterns.md) |
| `eb.and([...])` / `eb.or([...])` | Combine conditions | `eb.or([eb("a","=",1), eb("b","=",2)])` |
| `eb.exists(subquery)` | EXISTS check | `eb.exists(db.selectFrom(...))` |
| `eb.not(expr)` | Negate expression | `eb.not(eb.exists(...))` |
| `eb.cast(expr, "type")` | SQL CAST | `eb.cast(eb.val("x"), "text")` |
| `eb(left, op, right)` | Binary expression | `eb("qty", "*", eb.ref("price"))` |

For full query examples, see [references/query-patterns.md](references/query-patterns.md).

## Database Types

```typescript
import { Generated, Insertable, Selectable, Updateable } from "kysely"

interface Database {
  users: UsersTable
  posts: PostsTable
}

interface UsersTable {
  id: Generated<number>
  email: string
  name: string
  created_at: Generated<Date>
}

// Helper types make Generated fields optional for inserts/updates
type NewUser = Insertable<UsersTable>
type UserUpdate = Updateable<UsersTable>
type User = Selectable<UsersTable>
```

Use `kysely-codegen` to generate these types from your database. See [references/migrations.md](references/migrations.md).

## Pitfalls

These are the most common mistakes when writing Kysely code.

### 1. eb.val() vs eb.lit() confusion

`eb.val()` creates parameterized values ($1) -- use for user input. `eb.lit()` creates SQL literals -- **only accepts numbers, booleans, null** (not strings). For string literals, use `sql\`'value'\``.

```typescript
eb.val("safe input")              // $1 -- parameterized, safe
eb.lit(42)                        // 42 -- literal in SQL
eb.lit("text")                    // THROWS "unsafe immediate value"
eb.cast(eb.val("text"), "text")   // $1::text -- workaround for typed string params
```

### 2. Forgetting .execute()

Queries are lazy builders. Without an execute method, nothing runs.

```typescript
db.selectFrom("user").selectAll()                  // does nothing
await db.selectFrom("user").selectAll().execute()   // runs the query
```

### 3. .where() vs .whereRef() for column comparisons

`.where("a", "=", "b")` compares column `a` to the **string** `"b"`. Use `.whereRef()` for column-to-column comparisons.

```typescript
.where("table.col", "=", "other.col")       // compares to string literal
.whereRef("table.col", "=", "other.col")    // compares two columns
```

### 4. Always type sql`` template literals

`sql` template literals infer as `unknown`. Always provide an explicit type parameter.

```typescript
sql`now()`                      // Expression<unknown> -- bad
sql<Date>`now()`                // Expression<Date> -- good
```

### 5. selectAll() breaks nested json helper type inference ([#1059](https://github.com/kysely-org/kysely/issues/1059))

Bare `.selectAll()` inside json helper subqueries merges outer table columns into the type. Use table-qualified `.selectAll("table_name")` instead. See [references/relations-helpers.md](references/relations-helpers.md).

### 6. DATE columns cause timezone drift

The `pg` driver converts DATE to JS `Date`, causing timezone issues. Parse DATE as string instead. See [references/migrations.md](references/migrations.md).

### 7. "Type instantiation is excessively deep"

Complex queries with many CTEs can exceed TypeScript's type depth. Use `$assertType<T>()` on intermediate CTEs. See [references/relations-helpers.md](references/relations-helpers.md).

### 8. PostgreSQL does NOT auto-index foreign keys

Always create indexes on FK columns manually in migrations. See [references/migrations.md](references/migrations.md).

### 9. CamelCasePlugin causes drift with raw SQL

`CamelCasePlugin` converts snake_case DB columns to camelCase in the builder. But raw `sql` template queries bypass the plugin, creating inconsistent naming between builder and raw queries in the same codebase. If you use significant raw SQL alongside the builder, avoid this plugin and keep snake_case throughout. See [references/migrations.md](references/migrations.md).

### 10. JSONB inserts need JSON.stringify only in sql templates ([#209](https://github.com/kysely-org/kysely/issues/209))

The `pg` driver auto-serializes objects for `.values()`/`.set()` JSONB params ([pg types](https://node-postgres.com/features/types)). You only need explicit `JSON.stringify` inside `sql` template expressions or with non-pg drivers. See [references/jsonb-arrays.md](references/jsonb-arrays.md).

### 11. Pool queries use different connections ([API](https://kysely-org.github.io/kysely-apidoc/classes/Kysely.html#connection), [#330](https://github.com/kysely-org/kysely/issues/330))

Each query may use a different pooled connection. `SET`, session variables, and RLS context do not persist across queries. Use `db.transaction()` or `db.connection()` to pin multiple statements to one connection. See [references/advanced-patterns.md](references/advanced-patterns.md).

### 12. WHERE does not narrow result types ([#310](https://github.com/kysely-org/kysely/issues/310))

`.where('col', 'is not', null)` does **not** remove `null` from the result type. Use `$narrowType` to manually assert the narrowed shape. See [references/advanced-patterns.md](references/advanced-patterns.md).

### 13. Team migration ordering ([#697](https://github.com/kysely-org/kysely/issues/697))

Migrations added on parallel branches may fail strict ordering when merged. Set `allowUnorderedMigrations: true` on the `Migrator`. See [references/migrations.md](references/migrations.md).

### 14. JSON aggregation changes runtime types ([#1412](https://github.com/kysely-org/kysely/issues/1412))

`Date` columns inside `jsonArrayFrom`/`jsonObjectFrom`/`json_agg` results become **strings** at runtime because JSON has no Date type. TypeScript types still say `Date`. Parse dates manually at the boundary. See [references/jsonb-arrays.md](references/jsonb-arrays.md).

## Official Resources

| Resource | URL |
|----------|-----|
| LLM-friendly docs (full) | `https://kysely.dev/llms-full.txt` |
| API documentation | `https://kysely-org.github.io/kysely-apidoc` |
| Playground | `https://kyse.link` |
| GitHub | `https://github.com/kysely-org/kysely` |
| Awesome Kysely (ecosystem) | `https://github.com/kysely-org/awesome-kysely` |

When using Cursor `@Docs`, reference `https://kysely.dev/llms-full.txt` for the most complete context.

## Reference Files

Consult these for detailed code patterns:

| Reference | When to Use |
|-----------|-------------|
| [query-patterns.md](references/query-patterns.md) | SELECT, WHERE, JOINs, aggregations, ORDER BY, mutations, $if, subqueries, transactions |
| [jsonb-arrays.md](references/jsonb-arrays.md) | JSONB columns, array columns, JSONPath, querying JSON/array data |
| [relations-helpers.md](references/relations-helpers.md) | jsonArrayFrom, jsonObjectFrom, reusable Expression<T> helpers, CTEs, compile/InferResult |
| [migrations.md](references/migrations.md) | kysely-ctl setup, migration files, column types, type generation, plugins, Neon dialect, DATE fix |
| [advanced-patterns.md](references/advanced-patterns.md) | Dynamic columns, withSchema, connection pinning, RLS, $narrowType, streaming, MERGE, views, FTS, testing |
| [ecosystem.md](references/ecosystem.md) | Pagination, auth adapters, Fastify plugin, community dialects |
