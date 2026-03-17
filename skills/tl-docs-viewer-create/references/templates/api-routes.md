# API Routes Template

Server-side routes for the docs viewer.

## Overview

Two endpoints are required:

| Endpoint | Purpose |
|----------|---------|
| `GET /admin/docs/tree` | Returns folder structure |
| `GET /admin/docs/content/:path*` | Returns markdown content |

## Configuration

Before using, configure:

- `DOCS_PATH` — Path to docs folder (default: `docs/`)
- Route prefix — Adjust `/admin/docs` as needed

## Usage

### Fastify

```typescript
import { registerDocsRoutes } from './docs-routes';

app.register(async (fastify) => {
  registerDocsRoutes(fastify, path.join(process.cwd(), 'docs'));
}, { prefix: '/admin/docs' });
```

### Express

```typescript
import docsRouter from './docs-routes';

app.use('/admin/docs', docsRouter);
```

## Security Notes

- Path traversal prevention is included
- Consider adding authentication middleware for admin routes
- Rate limiting recommended for public endpoints

## See Also

- [api-routes.ts](./api-routes.ts) — Full implementation
- [server-api.md](../server-api.md) — Detailed API documentation
