# Ecosystem and Integrations

Community packages, adapters, and dialect extensions for Kysely.

## Pagination

### kysely-paginate (offset-based)

```bash
npm install kysely-paginate
```

```typescript
import { paginateQuery } from "kysely-paginate"

const page = await paginateQuery(
  db.selectFrom("user").selectAll().where("is_active", "=", true),
  { page: 1, perPage: 25 }
)

// page.data     -- User[]
// page.total    -- total matching rows
// page.lastPage -- total pages
```

### kysely-cursor (cursor-based)

For infinite scroll, real-time feeds, or large datasets where offset pagination degrades:

```bash
npm install kysely-cursor
```

```typescript
import { cursorPaginate } from "kysely-cursor"

const page = await cursorPaginate(
  db.selectFrom("post").selectAll().orderBy("created_at", "desc"),
  {
    after: lastCursor,
    first: 20,
    cursorColumn: "created_at",
  }
)

// page.edges    -- { node: Post, cursor: string }[]
// page.pageInfo -- { hasNextPage, endCursor }
```

Use cursor-based for APIs and feeds; offset-based for admin tables with page numbers.

## Auth Adapters

### Auth.js / NextAuth

```bash
npm install @auth/kysely-adapter
```

```typescript
import { KyselyAdapter } from "@auth/kysely-adapter"

export const authOptions = {
  adapter: KyselyAdapter(db),
  // ...providers
}
```

The adapter manages users, accounts, sessions, and verification tokens automatically. Requires the standard Auth.js tables in your schema.

## Fastify

### fastify-kysely

```bash
npm install fastify-kysely
```

```typescript
import fp from "fastify-plugin"
import kyselyPlugin from "fastify-kysely"

app.register(kyselyPlugin, {
  kysely: db,
})

app.get("/users", async (request, reply) => {
  const users = await request.server.kysely
    .selectFrom("user")
    .selectAll()
    .execute()
  return users
})
```

Decorates the Fastify instance with a `kysely` property.

## Supabase ([Docs](https://kysely.dev/docs/integrations/supabase))

```bash
npm install kysely-supabase
```

Uses Supabase's PostgREST under the hood while keeping Kysely's query builder API. Useful when you want Kysely's type-safe builder but deploy on Supabase without direct Postgres connections.

## Multi-Tenant / Access Control

### kysely-access-control

```bash
npm install kysely-access-control
```

Plugin for row-level filtering based on application-defined rules. Automatically injects `WHERE` clauses. Useful as an alternative to database-level RLS when you need application-side policy logic.

### Kysera Plugin Ecosystem

[Kysera](https://kysera.dev) provides a suite of plugins:

| Plugin | Purpose |
|--------|---------|
| `@kysera/soft-delete` | Automatic `deleted_at` filtering, restore, hard delete |
| `@kysera/audit` | Operation logging via plugin hooks |
| `@kysera/rls` | Application-level row-level security |
| `@kysera/testing` | `testInTransaction`, savepoints, truncation, seed helpers |

## Community Dialects

| Dialect | Package | Use Case |
|---------|---------|----------|
| PostgreSQL | Built-in (`PostgresDialect`) | Standard `pg` driver |
| Neon (HTTP) | `kysely-neon` | Edge/serverless (no persistent connections) |
| PlanetScale | `kysely-planetscale` | Serverless MySQL |
| D1 (Cloudflare) | `kysely-d1` | Cloudflare Workers with D1 |
| LibSQL / Turso | `kysely-libsql` | Edge SQLite |
| SQLite (better-sqlite3) | Built-in (`SqliteDialect`) | Local / embedded |
| MySQL | Built-in (`MysqlDialect`) | Standard mysql2 driver |

All dialects share the same Kysely query builder API. Dialect-specific SQL features (e.g., PostgreSQL JSONB) may not be available across all dialects.
