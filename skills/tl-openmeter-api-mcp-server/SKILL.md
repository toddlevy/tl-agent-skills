---
name: tl-openmeter-api-mcp-server
description: MCP server providing tools to interact with a local OpenMeter instance. Enables AI assistants to list meters, manage customers, create subscriptions, query usage, and ingest events. Use when working with OpenMeter locally and you need to call the API directly from the agent.
version: "1.1"
license: MIT
compatibility: Node.js 18+, local or remote OpenMeter instance
quilted:
  - source: anthropics/skills/mcp-builder
    weight: 0.25
    description: 4-phase MCP workflow, tool naming conventions, error handling, pagination patterns
metadata:
  author: tl-agent-skills
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

---

## MCP Design Principles

From anthropics/skills/mcp-builder:

### Tool Naming

Use consistent, action-oriented prefixes:

```
openmeter_list_meters     ✓ (list action)
openmeter_get_customer    ✓ (get action)
openmeter_create_subscription ✓ (create action)
meters                    ✗ (no action prefix)
```

### API Coverage vs Workflow Tools

Balance comprehensive API endpoint coverage with specialized workflow tools:

- **Comprehensive coverage** gives agents flexibility to compose operations
- **Workflow tools** (e.g., `openmeter_provision_customer`) combine multiple calls for common tasks

When uncertain, prioritize comprehensive API coverage.

### Actionable Error Messages

Error messages should guide agents toward solutions:

```typescript
// Bad
throw new Error('Request failed');

// Good
throw new Error(
  `OpenMeter customer not found: ${customerId}. ` +
  `Use openmeter_list_customers to find valid customer IDs.`
);
```

---

## Pagination

All list operations support cursor-based pagination:

```typescript
interface PaginationParams {
  page?: number;
  pageSize?: number;  // default: 100, max: 1000
}

interface PaginatedResponse<T> {
  items: T[];
  page: number;
  pageSize: number;
  totalCount: number;
}
```

### Tool Implementation

```typescript
server.registerTool({
  name: 'openmeter_list_customers',
  description: 'List customers with pagination. Returns page info and total count.',
  inputSchema: z.object({
    page: z.number().optional().describe('Page number (1-indexed)'),
    pageSize: z.number().max(1000).optional().describe('Items per page, max 1000'),
  }),
  async handler({ page = 1, pageSize = 100 }) {
    const response = await fetch(
      `${baseUrl}/api/v1/customers?page=${page}&pageSize=${pageSize}`
    );
    return {
      content: [{ type: 'text', text: JSON.stringify(await response.json()) }],
    };
  },
});
```

---

## Batch Operations

### Batch Event Ingestion

```typescript
server.registerTool({
  name: 'openmeter_batch_ingest',
  description: 'Ingest multiple CloudEvents in a single request',
  inputSchema: z.object({
    events: z.array(z.object({
      type: z.string(),
      subject: z.string(),
      data: z.record(z.unknown()),
    })),
  }),
  async handler({ events }) {
    const cloudEvents = events.map(e => ({
      specversion: '1.0',
      id: crypto.randomUUID(),
      source: 'mcp-server',
      type: e.type,
      subject: e.subject,
      time: new Date().toISOString(),
      data: e.data,
    }));
    
    const response = await fetch(`${baseUrl}/api/v1/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/cloudevents-batch+json' },
      body: JSON.stringify(cloudEvents),
    });
    
    return { content: [{ type: 'text', text: `Ingested ${events.length} events` }] };
  },
});
```

---

## Tool Annotations

Mark tools with hints for agent behavior:

```typescript
server.registerTool({
  name: 'openmeter_create_customer',
  annotations: {
    readOnlyHint: false,      // Modifies state
    destructiveHint: false,   // Does not delete data
    idempotentHint: false,    // Creates new resource each time
    openWorldHint: true,      // External service interaction
  },
  // ...
});

server.registerTool({
  name: 'openmeter_list_meters',
  annotations: {
    readOnlyHint: true,       // Only reads data
    destructiveHint: false,
    idempotentHint: true,     // Same result for same input
    openWorldHint: true,
  },
  // ...
});
```

---

## Testing

### MCP Inspector

Test tools interactively:

```bash
npx @modelcontextprotocol/inspector
```

### Mock Server for Tests

```typescript
import { createMockMcpServer } from './test-utils';

const mockServer = createMockMcpServer({
  tools: {
    openmeter_list_meters: async () => ({
      content: [{ type: 'text', text: JSON.stringify([
        { id: 'test-meter', slug: 'api-calls', aggregation: 'COUNT' }
      ]) }],
    }),
  },
});
```

### Integration Test Pattern

```typescript
describe('OpenMeter MCP Server', () => {
  it('lists meters from running OpenMeter', async () => {
    const result = await server.callTool('openmeter_list_meters', {});
    expect(result.content[0].type).toBe('text');
    const meters = JSON.parse(result.content[0].text);
    expect(Array.isArray(meters)).toBe(true);
  });

  it('returns actionable error for invalid customer', async () => {
    const result = await server.callTool('openmeter_get_customer', { 
      idOrKey: 'nonexistent' 
    });
    expect(result.content[0].text).toContain('openmeter_list_customers');
  });
});
```

---

## References

### Quilted Skills

- [anthropics/skills/mcp-builder](https://skills.sh/anthropics/skills/mcp-builder) — MCP server development guide

### First-Party Documentation

- [MCP Specification](https://modelcontextprotocol.io/) — Protocol specification
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk) — SDK reference
- [OpenMeter API](https://openmeter.io/docs/api) — API endpoints

### MCP Resources

- [MCP Server Examples](https://github.com/modelcontextprotocol/servers) — Reference implementations
- [MCP Inspector](https://github.com/modelcontextprotocol/inspector) — Debugging tool
- [MCP Best Practices](https://github.com/anthropics/skills/blob/HEAD/skills/mcp-builder/reference/mcp_best_practices.md) — Universal guidelines
