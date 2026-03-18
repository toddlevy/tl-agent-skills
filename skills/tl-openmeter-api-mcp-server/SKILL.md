---
name: tl-openmeter-api-mcp-server
description: MCP server providing tools to interact with a local OpenMeter instance. Enables AI assistants to list meters, manage customers, create subscriptions, query usage, and ingest events. Use when working with OpenMeter locally and you need to call the API directly from the agent.
license: MIT
compatibility: Node.js 18+, local or remote OpenMeter instance
metadata:
  author: tl-agent-skills
  version: "1.0"
  suite: tl-openmeter
  related: tl-openmeter-api tl-openmeter-local-dev
  type: mcp-server
---

# tl-openmeter-api-mcp-server

MCP server for your **local OpenMeter instance**: tools and resources so AI assistants (Cursor, Claude, etc.) can list meters, manage customers and subscriptions, query usage, and read the API quick reference.

Pair this with the **tl-openmeter-api** skill for knowledge; use this server to run operations against your OpenMeter.

## Suite

| Skill | Purpose |
|-------|---------|
| **tl-openmeter-api** | REST API reference (knowledge) |
| **tl-openmeter-local-dev** | Local dev setup: Docker, ngrok, Stripe App, webhooks |
| **tl-openmeter-api-mcp-server** | This skill: MCP server for calling OpenMeter from Cursor |

## When to Use

- "List my OpenMeter meters"
- "Create a customer in OpenMeter"
- "Query usage for this meter"
- "Ingest a test event"
- "Check if OpenMeter is running"
- When you need the agent to actually call OpenMeter API (not just provide documentation)

## Prerequisites

- **Node.js 18+**
- A running OpenMeter instance (e.g. [Docker](https://openmeter.io/docs/installation/docker), default `http://localhost:8888`)

## Installation

### Step 1: Build the Server

From the skill directory:

```bash
npm install
npm run build
```

### Step 2: Register in Cursor MCP Config

Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "OpenMeter": {
      "command": "node",
      "args": ["C:\\Users\\Todd\\.cursor\\skills\\@tl-agent-skills\\skills\\tl-openmeter-api-mcp-server\\dist\\index.js"],
      "env": {
        "OPENMETER_URL": "http://localhost:8888",
        "OPENMETER_API_KEY": ""
      }
    }
  }
}
```

Adjust the path to match your installation location.

### Step 3: Restart Cursor

Cursor needs to restart to pick up MCP config changes.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENMETER_URL` | `http://localhost:8888` | Base URL of OpenMeter API |
| `OPENMETER_API_KEY` | _(none)_ | Optional Bearer token for auth |

Local dev often runs without `OPENMETER_API_KEY`.

## Available Tools

| Tool | Purpose |
|------|---------|
| `openmeter_list_meters` | GET /api/v1/meters |
| `openmeter_get_meter` | GET /api/v1/meters/{idOrSlug} |
| `openmeter_query_usage` | GET /api/v1/meters/{idOrSlug}/query |
| `openmeter_list_customers` | GET /api/v1/customers (paginated) |
| `openmeter_get_customer` | GET /api/v1/customers/{idOrKey} |
| `openmeter_create_customer` | POST /api/v1/customers |
| `openmeter_list_subscriptions` | List subscriptions (optional customerId) |
| `openmeter_create_subscription` | POST /api/v1/subscriptions |
| `openmeter_cancel_subscription` | POST /api/v1/subscriptions/{id}/cancel |
| `openmeter_list_plans` | GET /api/v1/plans |
| `openmeter_list_features` | GET /api/v1/features |
| `openmeter_get_entitlements` | GET /api/v1/customers/{id}/entitlements |
| `openmeter_ingest_event` | POST /api/v1/events (CloudEvents JSON) |
| `openmeter_list_apps` | GET /api/v1/apps |
| `openmeter_list_billing_profiles` | GET /api/v1/billing/profiles |
| `openmeter_check_status` | Verify connection to OpenMeter |

## Resources

- **OpenMeter quick reference** — Markdown from the tl-openmeter-api skill
- **OpenMeter spec note** — Plain text with spec URL and configured base URL

## Verification

1. Start OpenMeter (e.g. `docker compose up` or your stack)
2. Ensure the OpenMeter MCP server is configured and enabled in Cursor
3. In a chat, ask: "Check the OpenMeter status" or "List OpenMeter meters"
4. The agent should call `openmeter_check_status` or `openmeter_list_meters` and return results

Errors (e.g. connection refused) are returned as tool results so the agent can report them.

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Tools not available | Server not in `mcp.json` | Add config entry, restart Cursor |
| Connection refused | OpenMeter not running | Start OpenMeter (`docker compose up`) |
| 401 Unauthorized | Missing API key | Set `OPENMETER_API_KEY` in env |
| Server won't start | Not built | Run `npm run build` in skill directory |
