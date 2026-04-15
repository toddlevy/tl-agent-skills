# JSONB and Array Patterns

PostgreSQL JSONB and array column handling with Kysely. The `pg` driver handles serialization automatically for parameterized queries ([node-postgres types](https://node-postgres.com/features/types)) -- objects passed via `.values()` are auto-stringified to JSON. No manual `JSON.stringify` or `JSON.parse` needed for standard CRUD.

## JSONB Columns

### When You Need JSON.stringify ([#209](https://github.com/kysely-org/kysely/issues/209), [Extending Kysely](https://kysely.dev/docs/recipes/extending-kysely))

For standard `.values()` / `.set()` inserts and updates, `pg` auto-serializes objects to JSON -- no helper needed. You **do** need explicit `JSON.stringify` when:
- Using `sql` template expressions (e.g. `sql\`CAST(${...} AS JSONB)\``)
- Building JSONB values inside `Expression` helpers
- Working with non-`pg` drivers (Bun, Deno) that may not auto-serialize

```typescript
import { sql, RawBuilder } from "kysely"

function json<T>(value: T): RawBuilder<T> {
  return sql`CAST(${JSON.stringify(value)} AS JSONB)`
}

await db
  .insertInto("user")
  .values({
    email: "test@example.com",
    metadata: { preferences: { theme: "dark" } },  // plain object works with pg
  })
  .execute()

await sql`
  UPDATE user SET metadata = ${json({ theme: "dark" })}
  WHERE id = ${userId}
`.execute(db)
```

For kysely-codegen `Json` types, a typed wrapper can help with the builder when TypeScript rejects plain objects:

```typescript
import type { Json } from "./kysely-types"

function toJsonb<T>(value: T): T {
  return JSON.stringify(value) as unknown as T
}
```

### Insert / Update / Read

```typescript
// INSERT -- pass objects directly
await db
  .insertInto("user")
  .values({
    email: "test@example.com",
    metadata: { preferences: { theme: "dark" }, count: 42 },
  })
  .execute()

// UPDATE -- pass objects directly
await db
  .updateTable("user")
  .set({ metadata: { preferences: { theme: "light" } } })
  .where("id", "=", userId)
  .execute()

// READ -- returns parsed object, not string
const user = await db
  .selectFrom("user")
  .select(["id", "metadata"])
  .executeTakeFirst()
// user.metadata.preferences.theme -> "dark"
```

### Querying JSONB

```typescript
// Key exists (?)
.where("metadata", "?", "theme")

// Any key exists (?|)
.where("metadata", "?|", sql`array['theme', 'language']`)

// All keys exist (?&)
.where("metadata", "?&", sql`array['theme', 'notifications']`)

// Contains (@>)
.where("metadata", "@>", sql`'{"notifications": true}'::jsonb`)

// Extract field as text (->>) -- type-safe
.where((eb) => eb(eb("metadata", "->>", "theme"), "=", "dark"))

// Extract nested path (#>> needs sql``)
.where(sql`metadata#>>'{preferences,theme}'`, "=", "dark")

// In SELECT -- type-safe with eb()
.select((eb) => [
  eb("metadata", "->", "preferences").as("prefs"),   // returns JSONB
  eb("metadata", "->>", "theme").as("theme"),         // returns text
])

// Nested paths in SELECT need sql``
.select(sql`metadata#>'{preferences,theme}'`.as("t"))      // JSONB
.select(sql<string>`metadata#>>'{a,b}'`.as("t"))           // text
```

### JSONPath (PostgreSQL 12+)

```typescript
// JSONPath match (@@)
.where("metadata", "@@", sql`'$.preferences.theme == "dark"'`)

// JSONPath exists -- use jsonb_path_exists() function
.where((eb) =>
  eb.fn("jsonb_path_exists", [eb.ref("metadata"), sql`'$.preferences.theme'`])
)

// Extract with JSONPath
.select((eb) => [
  "id",
  eb.fn("jsonb_path_query_first", [
    eb.ref("metadata"),
    sql`'$.preferences.theme'`,
  ]).as("theme"),
])

// JSONPath with variables
const searchValue = "dark"
.where((eb) =>
  eb.fn("jsonb_path_exists", [
    eb.ref("metadata"),
    sql`'$.preferences.theme ? (@ == $val)'`,
    sql`jsonb_build_object('val', ${searchValue}::text)`,
  ])
)
```

## Array Columns (text[], int[], etc.)

### Insert / Update / Read

```typescript
// INSERT -- pass array directly
await db
  .insertInto("product")
  .values({
    name: "Product",
    tags: ["phone", "electronics", "premium"],
  })
  .execute()

// READ -- returns native JavaScript array
const product = await db
  .selectFrom("product")
  .select(["name", "tags"])
  .executeTakeFirst()
// product.tags -> ["phone", "electronics", "premium"]

// UPDATE
await db
  .updateTable("product")
  .set({ tags: ["updated", "tags"] })
  .where("id", "=", productId)
  .execute()
```

### Querying Arrays

```typescript
// Array contains all values (@>)
.where("tags", "@>", sql`ARRAY['phone', 'premium']::text[]`)

// Arrays overlap (&&)
.where("tags", "&&", sql`ARRAY['premium', 'basic']::text[]`)

// Array contains value (ANY) -- type-safe with eb.fn
.where((eb) => eb(
  sql`${searchTerm}`, "=", eb.fn("any", [eb.ref("tags")])
))
```

## JSON Aggregation Type Drift ([#1412](https://github.com/kysely-org/kysely/issues/1412))

`Date`, `BigInt`, and other non-JSON-native types become **strings** when they pass through `json_agg`, `jsonArrayFrom`, or `jsonObjectFrom`. TypeScript types still reflect the original column type (e.g. `Date`), creating a runtime mismatch.

```typescript
const result = await db
  .selectFrom("user")
  .select((eb) => [
    "user.id",
    jsonArrayFrom(
      eb.selectFrom("order")
        .select(["order.id", "order.created_at"])
        .whereRef("order.user_id", "=", "user.id")
    ).as("orders"),
  ])
  .executeTakeFirst()

// TypeScript says: result.orders[0].created_at is Date
// Runtime reality: result.orders[0].created_at is "2025-01-15T10:30:00.000Z" (string)
```

Parse dates at the boundary after retrieving results from json aggregation helpers. This is a known limitation (koskimas: "no way to know the DB datatype of the properties").

## JSON Aggregation Helpers

Build JSON objects and arrays in queries. See also [relations-helpers.md](relations-helpers.md) for `jsonArrayFrom`/`jsonObjectFrom`.

```typescript
import { jsonBuildObject } from "kysely/helpers/postgres"

.select((eb) => [
  "task.job_id",
  eb.fn.jsonAgg(
    jsonBuildObject({
      id: eb.ref("task.id"),
      status: eb.ref("task.status"),
      assignee: jsonBuildObject({
        id: eb.ref("user.id"),
        name: eb.ref("user.name"),
      }),
    })
  )
  .filterWhere("task.id", "is not", null)
  .as("tasks"),
])
.groupBy("task.job_id")
```

`jsonAgg` is accessed via `eb.fn.jsonAgg()`, not imported.

## PostgreSQL Helpers Summary

```typescript
import {
  jsonArrayFrom,    // one-to-many (subquery -> array)
  jsonObjectFrom,   // many-to-one (subquery -> object | null)
  jsonBuildObject,  // build JSON object from expressions
  mergeAction,      // get action performed in MERGE (PostgreSQL 15+)
} from "kysely/helpers/postgres"
```
