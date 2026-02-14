#!/usr/bin/env node
/**
 * OpenMeter MCP Server — tools and resources for your local OpenMeter instance.
 * Env: OPENMETER_URL (default http://localhost:8888), OPENMETER_API_KEY (optional).
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import * as client from "./client.js";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));

const server = new McpServer({
  name: "openmeter-mcp-server",
  version: "1.0.0",
  description: "Tools and resources for local OpenMeter (meters, customers, subscriptions, usage, plans, features, billing, apps).",
});

function jsonContent(obj: unknown): { type: "text"; text: string } {
  return { type: "text" as const, text: JSON.stringify(obj, null, 2) };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function wrapTool<T>(fn: (params?: any) => Promise<T>) {
  return async (params?: any): Promise<{ content: { type: "text"; text: string }[]; isError?: boolean }> => {
    try {
      const data = await fn(params);
      return { content: [jsonContent(data)] };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      return { content: [jsonContent({ error: message })], isError: true };
    }
  };
}

// --- Tools ---

server.tool("openmeter_list_meters", {}, wrapTool(() => client.listMeters()));

server.tool(
  "openmeter_get_meter",
  { meterIdOrSlug: z.string() },
  wrapTool(({ meterIdOrSlug }: { meterIdOrSlug: string }) => client.getMeter(meterIdOrSlug))
);

server.tool(
  "openmeter_query_usage",
  {
    meterIdOrSlug: z.string(),
    subject: z.string().optional(),
    from: z.string().optional(),
    to: z.string().optional(),
    windowSize: z.enum(["MINUTE", "HOUR", "DAY", "MONTH"]).optional(),
  },
  wrapTool((params: { meterIdOrSlug: string; subject?: string; from?: string; to?: string; windowSize?: "MINUTE" | "HOUR" | "DAY" | "MONTH" }) =>
    client.queryUsage(params.meterIdOrSlug, {
      subject: params.subject,
      from: params.from,
      to: params.to,
      windowSize: params.windowSize,
    })
  )
);

server.tool(
  "openmeter_list_customers",
  {
    page: z.number().optional(),
    pageSize: z.number().optional(),
    subject: z.string().optional(),
  },
  wrapTool((params: { page?: number; pageSize?: number; subject?: string }) => client.listCustomers(params))
);

server.tool(
  "openmeter_get_customer",
  { customerIdOrKey: z.string() },
  wrapTool((params: { customerIdOrKey: string }) => client.getCustomer(params.customerIdOrKey))
);

server.tool(
  "openmeter_create_customer",
  {
    externalId: z.string().optional(),
    name: z.string(),
    email: z.string().optional(),
    subjectKeys: z.array(z.string()).optional(),
  },
  wrapTool((params: { externalId?: string; name: string; email?: string; subjectKeys?: string[] }) => {
    const body: Record<string, unknown> = {
      name: params.name,
      externalId: params.externalId,
      email: params.email,
      timezone: "UTC",
    };
    if (params.subjectKeys?.length) {
      body.usageAttribution = { subjectKeys: params.subjectKeys };
    } else if (params.externalId) {
      body.usageAttribution = { subjectKeys: [params.externalId] };
    }
    return client.createCustomer(body as Parameters<typeof client.createCustomer>[0]);
  })
);

server.tool(
  "openmeter_list_subscriptions",
  { customerId: z.string().optional() },
  wrapTool((params: { customerId?: string }) => client.listSubscriptions(params.customerId))
);

server.tool(
  "openmeter_create_subscription",
  { customerId: z.string(), planKey: z.string() },
  wrapTool((params: { customerId: string; planKey: string }) =>
    client.createSubscription(params.customerId, params.planKey)
  )
);

server.tool(
  "openmeter_cancel_subscription",
  {
    subscriptionId: z.string(),
    timing: z.enum(["immediate", "at_date"]).optional(),
    effectiveDate: z.string().optional(),
  },
  wrapTool(async (params: { subscriptionId: string; timing?: "immediate" | "at_date"; effectiveDate?: string }) => {
    const data = await client.cancelSubscription(params.subscriptionId, {
      timing: params.timing,
      effectiveDate: params.effectiveDate,
    });
    return data ?? { ok: true };
  })
);

server.tool("openmeter_list_plans", {}, wrapTool(() => client.listPlans()));
server.tool("openmeter_list_features", {}, wrapTool(() => client.listFeatures()));
server.tool(
  "openmeter_get_entitlements",
  { customerId: z.string() },
  wrapTool((params: { customerId: string }) => client.getEntitlements(params.customerId))
);
server.tool(
  "openmeter_ingest_event",
  {
    type: z.string(),
    source: z.string(),
    subject: z.string(),
    data: z.record(z.unknown()).optional(),
    time: z.string().optional(),
    id: z.string().optional(),
  },
  wrapTool(async (params: { type: string; source: string; subject: string; data?: Record<string, unknown>; time?: string; id?: string }) => {
    const event = {
      specversion: "1.0",
      id: params.id ?? crypto.randomUUID(),
      type: params.type,
      source: params.source,
      subject: params.subject,
      time: params.time ?? new Date().toISOString(),
      data: params.data ?? {},
    };
    await client.ingestEvent(event);
    return { ingested: true, event };
  })
);
server.tool("openmeter_list_apps", {}, wrapTool(() => client.listApps()));
server.tool("openmeter_list_billing_profiles", {}, wrapTool(() => client.listBillingProfiles()));
server.tool("openmeter_check_status", {}, wrapTool(() => client.checkStatus()));

// --- Resources ---

const quickRefPath = join(__dirname, "..", "..", "openmeter-api", "SKILL.md");
let quickRefText = "# OpenMeter API quick reference\n\nSee openmeter-api skill or openmeter.io/docs for full docs.\n";

try {
  quickRefText = readFileSync(quickRefPath, "utf-8");
} catch {
  // optional: skill may not be alongside server
}

server.resource(
  "OpenMeter quick reference",
  "openmeter:///quick-reference",
  async () => ({
    contents: [
      {
        uri: "openmeter:///quick-reference",
        mimeType: "text/markdown",
        text: quickRefText,
      },
    ],
  })
);

server.resource(
  "OpenMeter spec note",
  "openmeter:///spec-note",
  async () => ({
    contents: [
      {
        uri: "openmeter:///spec-note",
        mimeType: "text/plain",
        text: `OpenMeter OpenAPI 3.0 spec: https://openmeter.io/docs/api or a local api-1.json. Base URL for this server: ${client.getBaseUrl()}`,
      },
    ],
  })
);

// --- Run ---

const transport = new StdioServerTransport();
await server.connect(transport);
