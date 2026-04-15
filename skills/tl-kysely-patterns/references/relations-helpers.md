# Relations, Helpers, and CTEs

Kysely is not an ORM -- it uses PostgreSQL JSON functions for nested data, composable `Expression<T>` helpers for reuse, and CTEs for complex multi-step queries.

## Relations (jsonArrayFrom / jsonObjectFrom)

```typescript
import { jsonArrayFrom, jsonObjectFrom } from "kysely/helpers/postgres"
```

### One-to-Many

```typescript
const users = await db
  .selectFrom("user")
  .select((eb) => [
    "user.id",
    "user.email",
    jsonArrayFrom(
      eb
        .selectFrom("order")
        .select(["order.id", "order.status", "order.total_amount"])
        .whereRef("order.user_id", "=", "user.id")
        .orderBy("order.created_at", "desc")
    ).as("orders"),
  ])
  .execute()
```

### Many-to-One

```typescript
const products = await db
  .selectFrom("product")
  .select((eb) => [
    "product.id",
    "product.name",
    jsonObjectFrom(
      eb
        .selectFrom("category")
        .select(["category.id", "category.name"])
        .whereRef("category.id", "=", "product.category_id")
    ).as("category"),
  ])
  .execute()
```

### Marking Relations Non-Null ($notNull)

Kysely marks json helper results as nullable when it can't prove the related object exists. If you know it always does, use `$notNull()`:

```typescript
const persons = await db
  .selectFrom("person")
  .selectAll("person")
  .select(({ ref }) => [
    jsonArrayFrom(
      db.selectFrom("pet")
        .select(["pet.id", "pet.name"])
        .whereRef("pet.owner_id", "=", "person.id")
    ).as("pets"),
    jsonObjectFrom(
      db.selectFrom("person as mother")
        .select(["mother.id", "mother.first_name"])
        .whereRef("mother.id", "=", "person.mother_id")
    ).$notNull().as("mother"),
  ])
  .execute()

// persons[0].mother.first_name  -- no optional chaining needed
```

### Conditional Relation Loading

Use `$if` to include relations only when requested:

```typescript
const persons = await db
  .selectFrom("person")
  .selectAll("person")
  .$if(includePets, (qb) => qb.select(
    (eb) => jsonArrayFrom(
      eb.selectFrom("pet")
        .select(["pet.id", "pet.name"])
        .whereRef("pet.owner_id", "=", "person.id")
    ).as("pets")
  ))
  .$if(includeMother, (qb) => qb.select(
    (eb) => jsonObjectFrom(
      eb.selectFrom("person as mother")
        .select(["mother.id", "mother.first_name"])
        .whereRef("mother.id", "=", "person.mother_id")
    ).as("mother")
  ))
  .execute()
```

### Reusable Relation Helpers

Extract relation subqueries into functions for reuse across routes:

```typescript
import { Expression } from "kysely"
import { jsonArrayFrom, jsonObjectFrom } from "kysely/helpers/postgres"

function userOrders(userId: Expression<string>) {
  return jsonArrayFrom(
    db.selectFrom("order")
      .select(["order.id", "order.status", "order.total_amount"])
      .where("order.user_id", "=", userId)
      .orderBy("order.created_at", "desc")
  )
}

const users = await db
  .selectFrom("user")
  .select(({ ref }) => [
    "user.id",
    "user.email",
    userOrders(ref("user.id")).as("orders"),
  ])
  .execute()
```

### When Raw SQL is More Practical

For analytics-heavy codebases with complex CTEs, window functions, and multi-table aggregations, raw SQL via `sql` template tag is often more readable and maintainable than composing json helpers. The json helpers shine for API-layer queries that return nested objects; complex analytics pipelines are typically better as raw SQL.

### selectAll() Breaks Nested JSON Type Inference ([#1059](https://github.com/kysely-org/kysely/issues/1059))

Bare `.selectAll()` inside json helper subqueries merges columns from outer/joined tables into the type, causing incorrect inference. koskimas's recommended fix: use **table-qualified** `selectAll('table_name')` instead of bare `selectAll()`.

```typescript
// WRONG -- bare selectAll() breaks type inference for nested helpers
jsonObjectFrom(
  eb.selectFrom("payment_plans")
    .selectAll()                              // merges outer table columns into type
    .select((eb2) => [
      jsonArrayFrom(
        eb2.selectFrom("installments").selectAll()
          .whereRef("installments.plan_id", "=", "payment_plans.id")
      ).as("installments"),
    ])
    .whereRef("payment_plans.invoice_id", "=", "invoices.id")
).as("payment_plan")

// RIGHT (simplest) -- table-qualified selectAll
jsonObjectFrom(
  eb.selectFrom("payment_plans")
    .selectAll("payment_plans")               // scoped to this table only
    .select((eb2) => [
      jsonArrayFrom(
        eb2.selectFrom("installments").selectAll("installments")
          .whereRef("installments.plan_id", "=", "payment_plans.id")
      ).as("installments"),
    ])
    .whereRef("payment_plans.invoice_id", "=", "invoices.id")
).as("payment_plan")

// ALSO RIGHT -- explicit column list
jsonObjectFrom(
  eb.selectFrom("payment_plans")
    .select(["payment_plans.id", "payment_plans.invoice_id", "payment_plans.notes"])
    .select((eb2) => [
      jsonArrayFrom(
        eb2.selectFrom("installments").selectAll("installments")
          .whereRef("installments.plan_id", "=", "payment_plans.id")
      ).as("installments"),
    ])
    .whereRef("payment_plans.invoice_id", "=", "invoices.id")
).as("payment_plan")
```

## Reusable Expression Helpers

The recipe: take inputs as `Expression<T>`, return `Expression<T>`. Everything in Kysely is an expression -- `sql` tag output, `SelectQueryBuilder`, `eb` results.

```typescript
import { Expression, sql } from "kysely"

function upper(expr: Expression<string>) {
  return sql<string>`upper(${expr})`
}

function lower(expr: Expression<string>) {
  return sql<string>`lower(${expr})`
}

function concat(...exprs: Expression<string>[]) {
  return sql.join<string>(exprs, sql`||`)
}
```

Use in queries:

```typescript
.where(({ eb, ref }) => eb(upper(ref("last_name")), "=", "STALLONE"))

.select(({ ref, val }) => [
  concat(ref("first_name"), val(" "), ref("last_name")).as("full_name"),
])

.orderBy(({ ref }) => lower(ref("first_name")))
```

### Nullable Expression Support

```typescript
function toInt<T extends string | null>(expr: Expression<T>) {
  return sql<T extends null ? (number | null) : number>`(${expr})::integer`
}
```

### Subquery Helper with ExpressionBuilder

```typescript
import { Expression, expressionBuilder } from "kysely"

function idsOfUsersWithDogNamed(name: Expression<string>) {
  const eb = expressionBuilder<DB>()
  return eb
    .selectFrom("pet")
    .select("pet.owner_id")
    .where("pet.species", "=", "dog")
    .where("pet.name", "=", name)
}

// Usage -- compiles as a subquery, not a separate query
const users = await db
  .selectFrom("person")
  .selectAll()
  .where((eb) => eb("person.id", "in", idsOfUsersWithDogNamed(eb.val(dogName))))
  .execute()
```

### Standalone ExpressionBuilder

For reusable filters outside query callbacks:

```typescript
import { expressionBuilder } from "kysely"
import type { DB } from "./db.d.ts"

const eb = expressionBuilder<DB, "user">()

function isActiveUser() {
  return eb.and([
    eb("is_active", "=", true),
    eb("role", "!=", "banned"),
  ])
}
```

### Passing Subqueries to Helpers ($asScalar)

When a subquery returns `Expression<{ name: string }>` but a helper expects `Expression<string>`, use `$asScalar()`:

```typescript
.select((eb) => [
  upper(
    eb.selectFrom("pet")
      .select("name")
      .whereRef("person.id", "=", "pet.owner_id")
      .limit(1)
      .$asScalar()
      .$notNull()
  ).as("pet_name")
])
```

`$asScalar()` has no effect on generated SQL -- it is a type-level helper only.

## Common Table Expressions (CTEs)

```typescript
const result = await db
  .with("order_totals", (db) =>
    db.selectFrom("order")
      .innerJoin("user", "user.id", "order.user_id")
      .select((eb) => [
        "user.id as userId",
        "user.email",
        eb.fn.sum("order.total_amount").as("totalSpent"),
        eb.fn.count("order.id").as("orderCount"),
      ])
      .groupBy(["user.id", "user.email"])
  )
  .selectFrom("order_totals")
  .selectAll()
  .orderBy("totalSpent", "desc")
  .execute()
```

### "Excessively Deep Types" Fix

Complex queries with 12+ CTEs can exceed TypeScript's type depth limit. Use `$assertType<T>()` on intermediate CTEs to simplify the type chain:

```typescript
const result = await db
  .with("cte1", (qb) =>
    qb.selectFrom("user")
      .select(["id", "email"])
      .$assertType<{ id: number; email: string }>()
  )
  .with("cte2", (qb) =>
    qb.selectFrom("cte1")
      .select("email")
      .$assertType<{ email: string }>()
  )
  // ... more CTEs
  .selectFrom("cteN")
  .selectAll()
  .execute()
```

The asserted type must structurally match the actual type -- full type safety is preserved.

## Splitting Query Building and Execution

### Compile Without Executing

```typescript
let query = db.selectFrom("user").select(["id", "email"])

if (role) query = query.where("role", "=", role)
if (isActive !== undefined) query = query.where("is_active", "=", isActive)

const compiled = query.compile()
console.log(compiled.sql)         // SQL string
console.log(compiled.parameters)  // bound parameters

const results = await db.executeQuery(compiled)
```

### Infer Result Type

```typescript
import { InferResult } from "kysely"

const query = db.selectFrom("person").select("first_name").where("id", "=", id)
type QueryResult = InferResult<typeof query>  // { first_name: string }[]
```

### Cold Kysely Instances (No Database Connection)

Use `DummyDriver` to build and compile queries without a database:

```typescript
import {
  DummyDriver, Kysely, PostgresAdapter,
  PostgresIntrospector, PostgresQueryCompiler,
} from "kysely"

const db = new Kysely<Database>({
  dialect: {
    createAdapter: () => new PostgresAdapter(),
    createDriver: () => new DummyDriver(),
    createIntrospector: (db) => new PostgresIntrospector(db),
    createQueryCompiler: () => new PostgresQueryCompiler(),
  },
})
```

Executing queries on cold instances returns empty results without touching a database.
