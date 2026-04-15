# Query Patterns

Full code examples for Kysely query building with PostgreSQL.

## SELECT

```typescript
const users = await db.selectFrom("user").selectAll().execute()

const users = await db
  .selectFrom("user")
  .select(["id", "email", "first_name as firstName"])
  .execute()

// Single row (returns T | undefined)
const user = await db.selectFrom("user").selectAll()
  .where("id", "=", userId).executeTakeFirst()

// Single row that must exist (throws if not found)
const user = await db.selectFrom("user").selectAll()
  .where("id", "=", userId).executeTakeFirstOrThrow()
```

## WHERE

```typescript
.where("status", "=", "active")
.where("price", ">", 100)
.where("role", "in", ["admin", "manager"])
.where("name", "like", "%search%")
.where("deleted_at", "is", null)

// Chained = AND
.where("is_active", "=", true)
.where("role", "=", "admin")

// OR conditions
.where((eb) => eb.or([
  eb("role", "=", "admin"),
  eb("role", "=", "manager"),
]))

// Complex AND/OR
.where((eb) => eb.and([
  eb("is_active", "=", true),
  eb.or([
    eb("price", "<", 50),
    eb("stock", ">", 100),
  ]),
]))
```

### Dynamic Filters with Arrays

Build conditional filters by collecting expressions:

```typescript
import { Expression, SqlBool } from "kysely"

.where((eb) => {
  const filters: Expression<SqlBool>[] = []

  if (firstName) filters.push(eb("first_name", "=", firstName))
  if (lastName) filters.push(eb("last_name", "=", lastName))
  if (minAge) filters.push(eb("age", ">=", minAge))

  return eb.and(filters)
})
```

## JOINs

### Simple Joins

```typescript
.innerJoin("order", "order.user_id", "user.id")
.leftJoin("category", "category.id", "product.category_id")

// Self-join with alias
.selectFrom("category as c")
.leftJoin("category as parent", "parent.id", "c.parent_id")

// Multiple joins
.innerJoin("order", "order.id", "order_item.order_id")
.innerJoin("product", "product.id", "order_item.product_id")
```

### Complex Joins (Callback Format)

Use callbacks for composite keys, mixed conditions, OR logic, or subquery joins.

Join builder methods:
- `onRef(col1, op, col2)` -- column-to-column
- `on(col, op, value)` -- column-to-literal
- `on((eb) => ...)` -- complex expressions

```typescript
// Composite key + filter
.leftJoin("invoice as i", (join) =>
  join
    .onRef("sp.provider_id", "=", "i.provider_id")
    .onRef("sp.year", "=", "i.year")
    .on("i.status", "!=", "invalidated")
)

// Join with OR
.leftJoin("order as o", (join) =>
  join
    .onRef("o.user_id", "=", "u.id")
    .on((eb) =>
      eb.or([
        eb("o.status", "=", "completed"),
        eb("o.status", "=", "shipped"),
      ])
    )
)

// Subquery join (derived table) -- two callbacks
.leftJoin(
  (eb) =>
    eb
      .selectFrom("order")
      .select((eb) => [
        "user_id",
        eb.fn.count("id").as("order_count"),
        eb.fn.max("created_at").as("last_order_at"),
      ])
      .groupBy("user_id")
      .as("order_stats"),
  (join) => join.onRef("order_stats.user_id", "=", "u.id")
)
```

## Aggregations

```typescript
.select((eb) => [
  "status",
  eb.fn.count("id").as("count"),
  eb.fn.sum("total_amount").as("totalAmount"),
  eb.fn.avg("total_amount").as("avgAmount"),
])
.groupBy("status")
.having((eb) => eb.fn.count("id"), ">", 5)
```

## ORDER BY

```typescript
.orderBy("created_at", "desc")
.orderBy("name", "asc")

// NULLS FIRST / NULLS LAST
.orderBy("category_id", (ob) => ob.asc().nullsLast())
.orderBy("priority", (ob) => ob.desc().nullsFirst())

// Multiple columns -- chain calls (array syntax is deprecated)
.orderBy("category_id", "asc")
.orderBy("price", "desc")
```

## DISTINCT

```typescript
.selectFrom("user").select("role").distinct().execute()
```

## Mutations

### INSERT

```typescript
// Single insert with returning
const user = await db
  .insertInto("user")
  .values({ email: "test@example.com", first_name: "Test", last_name: "User" })
  .returning(["id", "email"])
  .executeTakeFirst()

// Multiple rows
await db
  .insertInto("user")
  .values([
    { email: "a@example.com", first_name: "A", last_name: "User" },
    { email: "b@example.com", first_name: "B", last_name: "User" },
  ])
  .execute()

// Upsert (ON CONFLICT)
await db
  .insertInto("product")
  .values({ sku: "ABC123", name: "Product", stock_quantity: 10 })
  .onConflict((oc) =>
    oc.column("sku").doUpdateSet((eb) => ({
      stock_quantity: eb("product.stock_quantity", "+", eb.ref("excluded.stock_quantity")),
    }))
  )
  .execute()

// Insert from SELECT
await db
  .insertInto("archive")
  .columns(["user_id", "data", "archived_at"])
  .expression(
    db.selectFrom("user")
      .select(["id", "metadata", sql`now()`.as("archived_at")])
      .where("is_active", "=", false)
  )
  .execute()
```

### UPDATE

```typescript
await db
  .updateTable("user")
  .set({ is_active: false })
  .where("id", "=", userId)
  .execute()

// Update with expression
await db
  .updateTable("product")
  .set((eb) => ({
    stock_quantity: eb("stock_quantity", "+", 10),
  }))
  .where("sku", "=", "ABC123")
  .returning(["id", "stock_quantity"])
  .executeTakeFirst()
```

### DELETE

```typescript
await db
  .deleteFrom("user")
  .where("id", "=", userId)
  .execute()
```

## Conditional Queries ($if)

Use `$if()` for runtime-conditional query modifications. Columns added via `$if` become optional in the result type.

```typescript
const result = await db
  .selectFrom("user")
  .selectAll()
  .$if(!includeInactive, (qb) => qb.where("is_active", "=", true))
  .$if(includeMetadata, (qb) => qb.select("metadata"))
  .$if(!!searchTerm, (qb) => qb.where("name", "like", `%${searchTerm}%`))
  .$if(!!roleFilter, (qb) => qb.where("role", "in", roleFilter!))
  .execute()
```

## Subqueries

```typescript
// Subquery in WHERE
.where("id", "in",
  db.selectFrom("order").select("user_id").where("status", "=", "completed")
)

// EXISTS subquery
.where((eb) =>
  eb.exists(
    db.selectFrom("review")
      .select(sql`1`.as("one"))
      .whereRef("review.product_id", "=", eb.ref("product.id"))
  )
)
```

## Transactions

```typescript
await db.transaction().execute(async (trx) => {
  const user = await trx.insertInto("user")
    .values({ name: "Bob", email: "bob@example.com" })
    .returningAll()
    .executeTakeFirstOrThrow()

  await trx.insertInto("post")
    .values({ title: "First Post", body: "Hello!", author_id: user.id, published: true })
    .execute()
})
```

## Dynamic Columns and Tables ([DynamicModule API](https://kysely-org.github.io/kysely-apidoc/classes/DynamicModule.html))

### db.dynamic.ref() for dynamic column references

Use `db.dynamic.ref()` for user-selectable sort columns. Always validate against an allowlist -- dynamic identifiers are **not escaped** and unchecked input is an injection risk.

```typescript
const ALLOWED_SORT_COLUMNS = ["created_at", "email", "name", "status"] as const

function validateSortColumn(col: string): string {
  if (!ALLOWED_SORT_COLUMNS.includes(col as any)) {
    throw new Error(`Invalid sort column: ${col}`)
  }
  return col
}

const { ref } = db.dynamic
const sortCol = validateSortColumn(userInput)
const results = await db
  .selectFrom("user")
  .selectAll()
  .orderBy(ref(sortCol), sortOrder)
  .limit(limit)
  .offset(offset)
  .execute()
```

### db.dynamic.table() for dynamic table references

```typescript
const { ref, table } = db.dynamic

await db
  .selectFrom(table(tableName).as("t"))
  .where(ref(columnName), "=", value)
  .selectAll()
  .execute()
```

`sql.ref()` is for building SQL fragments with **known** identifiers inside `sql` template tags. `db.dynamic.ref()` is the canonical API for **runtime** user-provided column/table names.

## Dynamic SQL Fragments (sql.raw, sql.join)

### sql.raw() for validated dynamic fragments

`sql.raw()` injects raw SQL without parameterization. Only use with values from a closed allowlist -- never with user input directly.

```typescript
const VALID_INTERVALS = { day: "1 day", week: "7 days", month: "30 days" }
const interval = VALID_INTERVALS[userChoice]
if (!interval) throw new Error("Invalid interval")

const results = await sql<Row>`
  SELECT * FROM events
  WHERE created_at >= NOW() - INTERVAL ${sql.raw(`'${interval}'`)}
`.execute(db)
```

### sql.join() for dynamic array building

```typescript
const uuids = ["a1b2...", "c3d4...", "e5f6..."]
const arrayFragment = sql.join(
  uuids.map((id) => sql`${id}::uuid`),
  sql`, `
)

await sql`
  UPDATE user SET status = 'active'
  WHERE id = ANY(ARRAY[${arrayFragment}])
`.execute(db)
```

## clearSelect() for Count Queries

Reuse a base query but swap its SELECT clause for a count:

```typescript
let baseQuery = db
  .selectFrom("user")
  .where("is_active", "=", true)

if (role) baseQuery = baseQuery.where("role", "=", role)

const rows = await baseQuery.selectAll().limit(20).execute()

const countResult = await baseQuery
  .clearSelect()
  .select((eb) => eb.fn.countAll().as("total"))
  .executeTakeFirstOrThrow()
```

## String Concatenation

```typescript
// sql template with eb.ref() -- clean and type-safe
.select((eb) => [
  sql<string>`${eb.ref("first_name")} || ' ' || ${eb.ref("last_name")}`.as("full_name"),
])

// eb() chaining -- parameterized
.select((eb) => [
  eb(eb("first_name", "||", " "), "||", eb.ref("last_name")).as("full_name"),
])
```

`||` propagates NULL. Use `concat()` only when you want NULL-as-empty-string behavior.
