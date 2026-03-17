# Environment Variables Template

Documentation template for environment variable reference.

---

## Template

```markdown
# Environment Variables

> **Last Updated:** {{DATE}}

Configuration via environment variables. Copy `.env.example` to `.env` and customize.

## Overview

| Variable | Service(s) | Required | Default |
|----------|------------|----------|---------|
| `DATABASE_URL` | api, worker | Yes | — |
| `REDIS_URL` | api, worker | Yes | — |
| `PORT` | api | No | `3000` |
| {{ENV_VAR}} | {{SERVICES}} | {{REQUIRED}} | {{DEFAULT}} |

## Core

### DATABASE_URL

PostgreSQL connection string.

```
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
```

- **Required:** Yes
- **Services:** api, worker
- **Format:** `postgresql://user:pass@host:port/database`

### REDIS_URL

Redis connection for caching and job queue.

```
REDIS_URL=redis://localhost:6379
```

- **Required:** Yes
- **Services:** api, worker

## Server

### PORT

HTTP server port.

```
PORT=3000
```

- **Required:** No
- **Default:** `3000`
- **Services:** api

### HOST

Server bind address.

```
HOST=0.0.0.0
```

- **Required:** No
- **Default:** `localhost`
- **Services:** api

## Authentication

### {{AUTH_VAR}}

{{AUTH_VAR_DESCRIPTION}}

```
{{AUTH_VAR}}={{EXAMPLE_VALUE}}
```

- **Required:** {{REQUIRED}}
- **Services:** {{SERVICES}}
- **Notes:** {{NOTES}}

## External Services

### {{SERVICE}}_API_KEY

API key for {{SERVICE_NAME}}.

```
{{SERVICE}}_API_KEY=sk_live_...
```

- **Required:** {{REQUIRED}}
- **Services:** {{SERVICES}}
- **Obtain from:** {{WHERE_TO_GET}}

## By Service

### API Server

Variables required for the main API server.

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection |
| `PORT` | No | Server port |
| {{VAR}} | {{REQ}} | {{DESC}} |

### Background Worker

Variables for background job processing.

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection |
| `REDIS_URL` | Yes | Job queue connection |

## Development vs Production

| Variable | Development | Production |
|----------|-------------|------------|
| `NODE_ENV` | `development` | `production` |
| `LOG_LEVEL` | `debug` | `info` |
| `{{VAR}}` | {{DEV_VALUE}} | {{PROD_VALUE}} |

## Example .env

```bash
# Core
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/myapp
REDIS_URL=redis://localhost:6379

# Server
PORT=3000
NODE_ENV=development

# Auth
JWT_SECRET=dev-secret-change-in-production

# External
STRIPE_SECRET_KEY=sk_test_...
```

---
_Generated from: `.env.example`, `src/config/index.ts`_
```

---

## Usage Notes

### Structure

| Section | Purpose |
|---------|---------|
| Overview | Quick reference table |
| Category sections | Grouped by function |
| By Service | What each service needs |
| Dev vs Prod | Environment differences |
| Example .env | Copy-paste starting point |

### Per-Variable Format

Each variable should include:
- Name and example value
- Required or optional
- Which services use it
- Default value if any
- Where to obtain (for API keys)

### Source Files

Generate from:
- `.env.example` — Variable names and comments
- Config loader — Defaults and required flags
- Service files — Which vars each service uses

---

## Source Attribution

Based on JamBase environment variable documentation with service mapping.
