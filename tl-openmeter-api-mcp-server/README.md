# OpenMeter MCP Server : Agent Skill by Todd Levy w/ Cursor Agent

MCP server for your **local OpenMeter instance**: tools and resources so AI assistants (Cursor, Claude, etc.) can list meters, manage customers and subscriptions, query usage, and read the API quick reference.

Same idea as [Railway’s MCP server](https://docs.railway.com/ai/mcp-server): pair this with the **openmeter-api** skill for knowledge; use this server to run operations against your own OpenMeter.

## Prerequisites

- **Node.js 18+**
- A running OpenMeter instance (e.g. [Docker](https://openmeter.io/docs/installation/docker), default `http://localhost:8888`)

## Environment variables

| Variable            | Default                 | Description                    |
| ------------------- | ----------------------- | ------------------------------ |
| `OPENMETER_URL`     | `http://localhost:8888` | Base URL of OpenMeter API     |
| `OPENMETER_API_KEY` | _(none)_                | Optional Bearer token for auth |

Local dev often runs without `OPENMETER_API_KEY`.

## Installation

From this directory:

```bash
npm install
npm run build
```

Or run with `npx tsx src/index.ts` (no build) if you have `tsx` installed.

## Add to Cursor

**Option A — npx (when published):**

In your user-level or workspace MCP config (e.g. `~/.cursor/mcp.json` or `.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "OpenMeter": {
      "command": "npx",
      "args": ["-y", "openmeter-mcp-server"],
      "env": {
        "OPENMETER_URL": "http://localhost:8888",
        "OPENMETER_API_KEY": ""
      }
    }
  }
}
```

**Option B — local path (this repo):**

If the server lives under `.agents/@tl-agent-skills/openmeter-mcp-server`:

```json
{
  "mcpServers": {
    "OpenMeter": {
      "command": "node",
      "args": ["C:\\Users\\Todd\\.agents\\@tl-agent-skills\\openmeter-mcp-server\\dist\\index.js"],
      "env": {
        "OPENMETER_URL": "http://localhost:8888"
      }
    }
  }
}
```

Run `npm run build` in the server directory first.

## Add to VS Code

Same pattern in `.vscode/mcp.json`: use `type: "stdio"`, and set `command`, `args`, and `env` as above.

## Tools

| Tool | Purpose |
|------|--------|
| `openmeter_list_meters` | GET /api/v1/meters |
| `openmeter_get_meter` | GET /api/v1/meters/{idOrSlug} |
| `openmeter_query_usage` | GET /api/v1/meters/{idOrSlug}/query (subject, from, to, windowSize) |
| `openmeter_list_customers` | GET /api/v1/customers (paginated) |
| `openmeter_get_customer` | GET /api/v1/customers/{idOrKey} or by subject |
| `openmeter_create_customer` | POST /api/v1/customers |
| `openmeter_list_subscriptions` | List subscriptions (optional customerId) |
| `openmeter_create_subscription` | POST /api/v1/subscriptions (customerId, planKey) |
| `openmeter_cancel_subscription` | POST /api/v1/subscriptions/{id}/cancel |
| `openmeter_list_plans` | GET /api/v1/plans |
| `openmeter_list_features` | GET /api/v1/features |
| `openmeter_get_entitlements` | GET /api/v1/customers/{id}/entitlements |
| `openmeter_ingest_event` | POST /api/v1/events (CloudEvents JSON) |
| `openmeter_list_apps` | GET /api/v1/apps |
| `openmeter_list_billing_profiles` | GET /api/v1/billing/profiles |
| `openmeter_check_status` | Verify connection to OpenMeter |

## Resources

- **OpenMeter quick reference** — Markdown from the openmeter-api skill (events, customers, subscriptions, gotchas), when the server is next to `openmeter-api/`.
- **OpenMeter spec note** — Plain text with spec URL and configured base URL.

## Verify

1. Start OpenMeter (e.g. `docker run ...` or your stack).
2. In Cursor, ensure the OpenMeter MCP server is configured and enabled.
3. In a chat, ask the agent to run `openmeter_check_status` or `openmeter_list_meters`; it should call your local OpenMeter and return results.

Errors (e.g. connection refused) are returned as tool results with `error` so the agent can report them.
