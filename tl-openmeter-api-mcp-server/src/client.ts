/**
 * Minimal OpenMeter API client for the MCP server.
 * Reads OPENMETER_URL (default http://localhost:8888) and optional OPENMETER_API_KEY from env.
 */

const baseUrl = (process.env.OPENMETER_URL || "http://localhost:8888").replace(/\/$/, "");
const apiKey = process.env.OPENMETER_API_KEY || "";

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
  contentType = "application/json"
): Promise<T> {
  const url = `${baseUrl}${path}`;
  const headers: Record<string, string> = { "Content-Type": contentType };
  if (apiKey) headers["Authorization"] = `Bearer ${apiKey}`;

  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OpenMeter API ${res.status}: ${text}`);
  }
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export async function listMeters(): Promise<unknown> {
  return request("GET", "/api/v1/meters");
}

export async function getMeter(idOrSlug: string): Promise<unknown> {
  return request("GET", `/api/v1/meters/${encodeURIComponent(idOrSlug)}`);
}

export async function queryUsage(
  meterIdOrSlug: string,
  params: { subject?: string; from?: string; to?: string; windowSize?: string }
): Promise<unknown> {
  const q = new URLSearchParams();
  if (params.subject) q.set("subject", params.subject);
  if (params.from) q.set("from", params.from);
  if (params.to) q.set("to", params.to);
  if (params.windowSize) q.set("windowSize", params.windowSize);
  const query = q.toString();
  return request("GET", `/api/v1/meters/${encodeURIComponent(meterIdOrSlug)}/query${query ? `?${query}` : ""}`);
}

export async function listCustomers(params?: { page?: number; pageSize?: number; subject?: string }): Promise<unknown> {
  const q = new URLSearchParams();
  if (params?.page != null) q.set("page", String(params.page));
  if (params?.pageSize != null) q.set("pageSize", String(params.pageSize));
  if (params?.subject) q.set("subject", params.subject);
  const query = q.toString();
  return request("GET", `/api/v1/customers${query ? `?${query}` : ""}`);
}

export async function getCustomer(idOrKey: string): Promise<unknown> {
  return request("GET", `/api/v1/customers/${encodeURIComponent(idOrKey)}`);
}

export async function createCustomer(body: {
  externalId?: string;
  name?: string;
  email?: string;
  timezone?: string;
  usageAttribution?: { subjectKeys: string[] };
}): Promise<unknown> {
  return request("POST", "/api/v1/customers", body);
}

export async function listSubscriptions(customerId?: string): Promise<unknown> {
  if (customerId) {
    return request("GET", `/api/v1/customers/${encodeURIComponent(customerId)}/subscriptions`);
  }
  return request("GET", "/api/v1/subscriptions");
}

export async function createSubscription(customerId: string, planKey: string): Promise<unknown> {
  const key = planKey.replace(/([a-z])([A-Z])/g, "$1_$2").toLowerCase();
  return request("POST", "/api/v1/subscriptions", { customerId, plan: { key } });
}

export async function cancelSubscription(
  subscriptionId: string,
  options?: { timing?: string; effectiveDate?: string }
): Promise<unknown> {
  const timing = options?.timing || "immediate";
  const effectiveDate = options?.effectiveDate || new Date().toISOString();
  return request("POST", `/api/v1/subscriptions/${encodeURIComponent(subscriptionId)}/cancel`, {
    timing,
    effectiveDate,
  });
}

export async function listPlans(): Promise<unknown> {
  return request("GET", "/api/v1/plans");
}

export async function listFeatures(): Promise<unknown> {
  return request("GET", "/api/v1/features");
}

export async function getEntitlements(customerId: string): Promise<unknown> {
  return request("GET", `/api/v1/customers/${encodeURIComponent(customerId)}/entitlements`);
}

export async function ingestEvent(event: Record<string, unknown>): Promise<unknown> {
  return request("POST", "/api/v1/events", event, "application/cloudevents+json");
}

export async function listApps(): Promise<unknown> {
  return request("GET", "/api/v1/apps");
}

export async function listBillingProfiles(): Promise<unknown> {
  return request("GET", "/api/v1/billing/profiles");
}

export async function checkStatus(): Promise<unknown> {
  const meters = await request<{ items?: unknown[] }>("GET", "/api/v1/meters");
  return { ok: true, metersCount: meters?.items?.length ?? 0, baseUrl };
}

export function getBaseUrl(): string {
  return baseUrl;
}
