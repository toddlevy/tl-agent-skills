# Advanced Patterns

Production patterns for multi-tenancy, session management, type narrowing, streaming, views, and PostgreSQL-specific features.

## Dynamic Columns and Tables ([DynamicModule API](https://kysely-org.github.io/kysely-apidoc/classes/DynamicModule.html))

For runtime user-provided column or table names, use `db.dynamic.ref()` and `db.dynamic.table()`. These are **not escaped** -- always validate against an allowlist.

```typescript
const { ref, table } = db.dynamic

const sortCol = validateSortColumn(userInput)
await db
  .selectFrom("user")
  .selectAll()
  .orderBy(ref(sortCol), "desc")
  .execute()

await db
  .selectFrom(table(tableName).as("t"))
  .where(ref(columnName), "=", value)
  .selectAll()
  .execute()
```

`sql.ref()` is for **static** identifiers inside `sql` template tags. `db.dynamic.ref()` is the canonical API for **runtime** column names (e.g. user-selected sort).

## Multi-Tenant / Schema Namespaces ([Schemas Recipe](https://kysely.dev/docs/recipes/schemas))

### Approach 1: Qualified table names in Database interface

```typescript
interface Database {
  "tenant_a.user": UserTable
  "tenant_b.user": UserTable
  "public.permission": PermissionTable
}
```

### Approach 2: withSchema() for runtime tenant selection

```typescript
function getTenantDb(tenantSchema: string) {
  return db.withSchema(tenantSchema)
}

const tenantDb = getTenantDb("tenant_42")
const users = await tenantDb
  .selectFrom("user")
  .selectAll()
  .execute()
```

`withSchema()` sets the default schema for unqualified table names. Explicitly qualified names (e.g. `public.permission` declared on `Database`) still work.

## Connection Pinning ([API](https://kysely-org.github.io/kysely-apidoc/classes/Kysely.html#connection), [#330](https://github.com/kysely-org/kysely/issues/330))

Each query may use a different pooled connection. For operations requiring session state persistence (RLS, advisory locks, `SET LOCAL`), pin to one connection:

### db.connection() -- single connection, no transaction

```typescript
await db.connection().execute(async (db) => {
  await sql`SELECT set_config('app.tenant_id', ${tenantId}, false)`.execute(db)
  return db.selectFrom("user").selectAll().execute()
})
```

### db.transaction() -- single connection + transaction semantics

```typescript
await db.transaction().execute(async (trx) => {
  await sql`SELECT set_config('app.tenant_id', ${tenantId}, true)`.execute(trx)
  return trx.selectFrom("user").selectAll().execute()
})
```

Use `set_config(..., true)` for transaction-local settings (cleared on commit/rollback). Use `set_config(..., false)` for session-local settings with `db.connection()`.

### Row-Level Security pattern

```typescript
await db.transaction().execute(async (trx) => {
  await sql`SELECT set_config('app.tenant_id', ${tenantId}, true)`.execute(trx)
  const posts = await trx.selectFrom("post").selectAll().execute()
  return posts
})
```

Postgres RLS policies using `current_setting('app.tenant_id', true)` see the tenant context. Kysely has no built-in RLS support; this is the community pattern.

### Advisory locks

Transaction-scoped locks are released automatically at commit/rollback:

```typescript
await db.transaction().execute(async (trx) => {
  await sql`SELECT pg_advisory_xact_lock(${lockKey})`.execute(trx)
  // critical section
})
```

Session-scoped locks (`pg_advisory_lock`) require `db.connection()` to ensure acquire and release happen on the same physical connection.

## $narrowType ([#310](https://github.com/kysely-org/kysely/issues/310), [API](https://kysely-org.github.io/kysely-apidoc/interfaces/SelectQueryBuilder.html))

`.where('col', 'is not', null)` does **not** narrow the result type. TypeScript cannot prove SQL semantics. Use `$narrowType` to manually assert the shape:

```typescript
const result = await db
  .selectFrom("user")
  .selectAll()
  .where("deleted_at", "is not", null)
  .$narrowType<{ deleted_at: Date }>()
  .execute()
```

`$narrowType` narrows individual fields. It works on `SelectQueryBuilder`, `InsertQueryBuilder`, `UpdateQueryBuilder`, and `DeleteQueryBuilder` (added via [PR #380](https://github.com/kysely-org/kysely/pull/380)).

## Controlled Transactions ([Docs](https://kysely.dev/docs/examples/transactions/controlled-transaction))

For manual commit/rollback control instead of the auto-rollback callback pattern:

```typescript
const trx = await db.startTransaction().execute()

try {
  await trx.insertInto("user")
    .values({ email: "test@example.com", name: "Test" })
    .execute()

  await trx.commit().execute()
} catch (error) {
  await trx.rollback().execute()
  throw error
}
```

### Savepoints ([Docs](https://kysely.dev/docs/examples/transactions/controlled-transaction-w-savepoints))

```typescript
const trx = await db.startTransaction().execute()

await trx.insertInto("user")
  .values({ email: "a@example.com", name: "A" })
  .execute()

await trx.savepoint("after_first_insert").execute()

try {
  await trx.insertInto("user")
    .values({ email: "b@example.com", name: "B" })
    .execute()
} catch {
  await trx.rollbackToSavepoint("after_first_insert").execute()
}

await trx.releaseSavepoint("after_first_insert").execute()
await trx.commit().execute()
```

### Isolation levels

```typescript
await db.transaction().setIsolationLevel("serializable").execute(async (trx) => {
  // runs at SERIALIZABLE isolation
})
```

## DISTINCT ON ([Docs](https://kysely.dev/docs/examples/select/distinct-on))

PostgreSQL-specific. Select the first row per group based on sort order:

```typescript
const latestOrderPerUser = await db
  .selectFrom("order")
  .innerJoin("user", "user.id", "order.user_id")
  .distinctOn("user.id")
  .selectAll("order")
  .orderBy("user.id")
  .orderBy("order.created_at", "desc")
  .execute()
```

`DISTINCT ON` requires the `distinctOn` columns to appear first in `ORDER BY`.

## Streaming ([API](https://kysely-org.github.io/kysely-apidoc/interfaces/SelectQueryBuilder.html), [PostgresDialectConfig](https://kysely-org.github.io/kysely-apidoc/interfaces/PostgresDialectConfig.html))

Server-side cursors for processing large result sets without loading everything into memory:

```typescript
import Cursor from "pg-cursor"

const db = new Kysely<Database>({
  dialect: new PostgresDialect({
    pool,
    cursor: Cursor,
  }),
})

for await (const row of db.selectFrom("big_table").selectAll().stream()) {
  processRow(row)
}

for await (const chunk of db.selectFrom("big_table").selectAll().stream(1000)) {
  processChunk(chunk)
}
```

Server cursors are transaction/session-bound. For API pagination, use keyset/cursor pagination libraries instead (see [ecosystem.md](ecosystem.md)).

## MERGE Statement ([API](https://kysely-org.github.io/kysely-apidoc/classes/Kysely.html#mergeInto))

PostgreSQL 15+ supports SQL `MERGE`. Kysely models it with `mergeInto`:

```typescript
import { mergeAction } from "kysely/helpers/postgres"

await db
  .mergeInto("wine")
  .using("wine_stock_change", "wine.id", "wine_stock_change.wine_id")
  .whenMatched()
  .thenUpdateSet((eb) => ({
    stock: eb("wine.stock", "+", eb.ref("wine_stock_change.delta")),
  }))
  .whenNotMatched()
  .thenInsertValues((eb) => ({
    id: eb.ref("wine_stock_change.wine_id"),
    name: eb.ref("wine_stock_change.wine_name"),
    stock: eb.ref("wine_stock_change.delta"),
  }))
  .execute()
```

`whenNotMatchedBySource()` and `thenDelete()` are also available for sync-style merges.

## Runtime Introspection ([Docs](https://kysely.dev/docs/recipes/introspecting-relation-metadata), [API](https://kysely-org.github.io/kysely-apidoc/interfaces/DatabaseIntrospector.html))

Query database metadata at runtime:

```typescript
const tables = await db.introspection.getTables()

for (const table of tables) {
  console.log(table.name, table.schema, table.isView)
  for (const col of table.columns) {
    console.log(`  ${col.name}: ${col.dataType} (nullable: ${col.isNullable})`)
  }
}
```

Returns `TableMetadata[]` including tables and views. Useful for admin UIs, code generation, and validation tooling.

## Views and Materialized Views ([API](https://kysely-org.github.io/kysely-apidoc/classes/SchemaModule.html))

### Create view

```typescript
await db.schema
  .createView("active_users")
  .orReplace()
  .as(
    db.selectFrom("user")
      .selectAll()
      .where("is_active", "=", true)
  )
  .execute()
```

### Refresh materialized view

```typescript
await db.schema
  .refreshMaterializedView("user_stats")
  .concurrently()
  .execute()
```

### Typing views

Model views as entries in your `Database` interface. For materialized views, manually declare the row type -- `kysely-codegen` may not pick them up automatically ([kysely-codegen#72](https://github.com/RobinBlomberg/kysely-codegen/issues/72)).

```typescript
interface Database {
  user: UserTable
  active_users: Pick<Selectable<UserTable>, "id" | "email" | "name">
  user_stats: UserStatsView
}
```

## Full-Text Search

Kysely has no first-class `tsvector` DSL. Use `sql` fragments with GIN-indexed `tsvector` columns:

```typescript
const results = await db
  .selectFrom("product")
  .where(
    sql`search_vector @@ websearch_to_tsquery(${sql.lit("english")}, ${searchTerm})`
  )
  .selectAll()
  .orderBy(
    sql`ts_rank(search_vector, websearch_to_tsquery(${sql.lit("english")}, ${searchTerm}))`,
    "desc"
  )
  .execute()
```

Store a generated `tsvector` column with a GIN index rather than computing it per-query.

## Optimistic Locking

Standard pattern using a `version` column:

```typescript
const updated = await db
  .updateTable("product")
  .set((eb) => ({
    name: newName,
    version: eb("version", "+", 1),
  }))
  .where("id", "=", productId)
  .where("version", "=", expectedVersion)
  .executeTakeFirst()

if (updated.numUpdatedRows === 0n) {
  throw new Error("Conflict: row was modified by another process")
}
```

## Soft Delete

Nullable `deleted_at` column. Reads filter by default; "delete" is an update:

```typescript
await db
  .updateTable("user")
  .set({ deleted_at: new Date() })
  .where("id", "=", userId)
  .execute()

const activeUsers = await db
  .selectFrom("user")
  .selectAll()
  .where("deleted_at", "is", null)
  .execute()
```

For automatic filtering, use a database view or a custom plugin. Partial indexes on `WHERE deleted_at IS NULL` keep queries fast.

## Database Testing (Transactional Rollback)

Run each test inside a transaction, then roll back to keep the database clean:

```typescript
import { Transaction } from "kysely"

let trx: Transaction<Database>

beforeEach(async () => {
  trx = await db.startTransaction().execute()
})

afterEach(async () => {
  await trx.rollback().execute()
})

test("creates a user", async () => {
  const user = await trx
    .insertInto("user")
    .values({ email: "test@example.com", name: "Test" })
    .returningAll()
    .executeTakeFirstOrThrow()

  expect(user.email).toBe("test@example.com")
})
```

Accept `Kysely<DB> | Transaction<DB>` in repository/service functions so they work with both the normal instance and test transactions.

## Logging ([Docs](https://kysely.dev/docs/recipes/logging))

### LogEvent structure

```typescript
const db = new Kysely<Database>({
  dialect: new PostgresDialect({ pool }),
  log(event) {
    if (event.level === "query") {
      console.log(event.query.sql)
      console.log(event.query.parameters)
      console.log(`Duration: ${event.queryDurationMillis}ms`)
    }
    if (event.level === "error") {
      console.error(event.error)
    }
  },
})
```

`LogEvent` fields: `level` (`"query"` | `"error"`), `query` (`CompiledQuery` with `sql`, `parameters`), `queryDurationMillis`, and `error` (when `level === "error"`).
