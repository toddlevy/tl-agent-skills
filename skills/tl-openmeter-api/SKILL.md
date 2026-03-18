---
name: tl-openmeter-api
description: Works with the OpenMeter REST API for usage metering, billing, and entitlements. Covers CloudEvents ingestion, meters, features, plans, customers, subscriptions, entitlements, notifications, billing profiles, invoices, apps, addons, grants, and the Stripe marketplace. Use when integrating OpenMeter, debugging metering, building catalog sync scripts, or when the user mentions OpenMeter API.
license: MIT
compatibility: Requires HTTP client. OpenMeter OSS or Cloud instance.
metadata:
  author: tl-agent-skills
  version: "2.1"
  suite: tl-openmeter
  related: tl-openmeter-local-dev tl-openmeter-api-mcp-server
---

# OpenMeter API

Project-agnostic reference for the OpenMeter REST API. Organized by the official API tags from the OpenAPI 3.0 spec.

## Suite

| Skill | Purpose |
|-------|---------|
| **tl-openmeter-api** | This skill: REST API reference |
| **tl-openmeter-local-dev** | Local dev setup: Docker, ngrok, Stripe App, webhooks |
| **tl-openmeter-api-mcp-server** | MCP server for calling local OpenMeter from Cursor |

## When to Use

- "How do I ingest events into OpenMeter?"
- "Create an OpenMeter customer with subscription"
- "Query usage for a meter"
- "Set up notification rules for threshold alerts"
- "Manage billing invoices"
- "Install the Stripe marketplace app"
- Debugging metering, billing, or subscription lifecycle

## Resources

- [references/REFERENCE.md](references/REFERENCE.md) — Complete endpoint table by official tag
- [references/billing.md](references/billing.md) — Invoice lifecycle, customer delete flow, rate cards
- [references/notifications.md](references/notifications.md) — Channels, rules, events, testing
- [references/product-catalog.md](references/product-catalog.md) — Plans, features, addons: versioning, rate cards, publish lifecycle
- [assets/openapi-spec.json](assets/openapi-spec.json) — Full OpenAPI 3.0 spec (source of truth)

## Official API Tags

The OpenMeter API organizes endpoints into these 15 tags:

| # | Tag | Description |
|---|-----|-------------|
| 1 | **Apps** | Manage app integrations (list, get, update, uninstall) |
| 2 | **App: Custom Invoicing** | Interface third-party invoicing and payment systems |
| 3 | **App: Stripe** | Stripe billing support (API key, webhook, checkout) |
| 4 | **Billing** | Billing profiles, invoices, customer overrides, pending lines |
| 5 | **Customers** | Customer lifecycle, app data, Stripe linking, entitlement values |
| 6 | **Debug** | Internal metrics (Prometheus format) |
| 7 | **Entitlements** | Usage limits, quota-based pricing, feature access |
| 8 | **Events** | CloudEvents ingestion and listing |
| 9 | **Lookup Information** | Static data (currencies, progress) |
| 10 | **Meters** | Aggregation rules, usage queries, group-by |
| 11 | **Notifications** | Channels, rules, events for threshold alerts |
| 12 | **Portal** | Consumer-facing usage dashboards via scoped tokens |
| 13 | **Product Catalog** | Plans, features, addons (versioning, rate cards, publish lifecycle) |
| 14 | **Subjects** | **Deprecated** — use Customers with `usageAttribution.subjectKeys` |
| 15 | **Subscriptions** | Customer plan assignments, cancel, change, migrate, restore |

---

## Base URL and Auth

- **Base URL:** `OPENMETER_URL` (e.g. `http://localhost:8888` for local, or your deployed URL)
- **Auth:** `Authorization: Bearer <OPENMETER_API_KEY>`. Local self-hosted often runs unauthenticated.
- **Content-Type:** `application/json` for most endpoints; `application/cloudevents+json` for `POST /api/v1/events`

---

## Concepts

```
Meter (aggregates events) → Feature (metered entitlement) → Plan (limits + pricing)
                                                                    ↓
Customer (subject keys) ←→ Subscription (customer + plan = active entitlements)
                                    ↓
                              Billing Profile → Invoices (via Stripe/Sandbox/Custom App)
```

- **Meter:** Aggregation rule for events (COUNT, SUM, etc.). Events reference a meter via `type` matching `eventType`.
- **Feature:** Tied to a meter or boolean; used in plan rate cards for quotas and overage.
- **Plan:** Contains phases and rate cards. Part of the **Product Catalog** alongside Features and Addons.
- **Addon:** Modular rate card bundle, attachable to plans or subscriptions.
- **Customer:** Has `usageAttribution.subjectKeys`; event `subject` must match for usage to attach.
- **Subscription:** Links customer to plan; active subscription grants entitlements.
- **Entitlement:** Per-customer access to a feature with usage tracking and limits.
- **Grant:** One-time credit or usage allocation against an entitlement.
- **Notification:** Automated alert when entitlement thresholds are reached.
- **App:** Billing provider integration (Stripe, Sandbox, Custom Invoicing).

---

## 1. Events

**Ingest:** `POST /api/v1/events` | **Content-Type:** `application/cloudevents+json`

```json
{
  "specversion": "1.0",
  "id": "unique-event-id",
  "type": "api_request",
  "source": "my-app",
  "subject": "user_abc123",
  "time": "2026-02-14T12:00:00Z",
  "data": { "value": 1, "path": "/v1/events", "method": "GET" }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `type` | Yes | Must match meter's `eventType` |
| `subject` | Yes | Must match customer's `usageAttribution.subjectKeys` |
| `source` | Yes | Identifies the producing system |
| `id` | Yes | Idempotency key (deduplication within 24h) |
| `time` | Recommended | ISO 8601 timestamp |
| `data` | Recommended | Arbitrary payload; meters use `$.path` for groupBy |

**List events:** `GET /api/v1/events?from=...&to=...&subject=...&hasError=...`

---

## 2. Meters

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/meters` |
| Create | POST | `/api/v1/meters` |
| Get | GET | `/api/v1/meters/{meterIdOrSlug}` |
| Update | PUT | `/api/v1/meters/{meterIdOrSlug}` |
| Delete | DELETE | `/api/v1/meters/{meterIdOrSlug}` |
| Query usage | GET | `/api/v1/meters/{meterIdOrSlug}/query?subject=...&from=...&to=...&windowSize=HOUR` |
| Query (POST) | POST | `/api/v1/meters/{meterIdOrSlug}/query` |
| Group-by values | GET | `/api/v1/meters/{meterIdOrSlug}/group-by/{groupBy}/values` |
| List subjects | GET | `/api/v1/meters/{meterIdOrSlug}/subjects` |

**Aggregation types:** `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `UNIQUE_COUNT`

**Window sizes:** `MINUTE`, `HOUR`, `DAY`, `MONTH`

---

## 3. Product Catalog

Plans, Features, and Addons all live under this tag. See [references/product-catalog.md](references/product-catalog.md) for versioning lifecycle, rate cards, and detailed examples.

### Features

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/features` |
| Create | POST | `/api/v1/features` |
| Get | GET | `/api/v1/features/{featureId}` |
| Delete | DELETE | `/api/v1/features/{featureId}` |

### Plans

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/plans` |
| Create | POST | `/api/v1/plans` |
| Get | GET | `/api/v1/plans/{planIdOrKey}` |
| Update | PUT | `/api/v1/plans/{planIdOrKey}` |
| Delete | DELETE | `/api/v1/plans/{planIdOrKey}` |
| Next version | POST | `/api/v1/plans/{planIdOrKey}/next` |
| Publish | POST | `/api/v1/plans/{planIdOrKey}/publish` |
| Archive | POST | `/api/v1/plans/{planIdOrKey}/archive` |
| Plan Addons | CRUD | `/api/v1/plans/{planIdOrKey}/addons/...` |

### Addons

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/addons` |
| Create | POST | `/api/v1/addons` |
| Get | GET | `/api/v1/addons/{addonIdOrKey}` |
| Update | PUT | `/api/v1/addons/{addonIdOrKey}` |
| Delete | DELETE | `/api/v1/addons/{addonIdOrKey}` |
| Publish | POST | `/api/v1/addons/{addonIdOrKey}/publish` |
| Archive | POST | `/api/v1/addons/{addonIdOrKey}/archive` |

**Critical:** Plan/addon keys must be snake_case (`^[a-z0-9]+(?:_[a-z0-9]+)*$`). Rate card `upToAmount` must be a string. Subscription creation uses `plan: { "key": "plan_key" }`, not a raw planId. Plans follow a draft -> published -> archived lifecycle.

---

## 4. Customers

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/customers?page=...&pageSize=...&subject=...&planKey=...` |
| Create | POST | `/api/v1/customers` |
| Get | GET | `/api/v1/customers/{customerIdOrKey}` |
| Delete | DELETE | `/api/v1/customers/{id}` |
| Get access | GET | `/api/v1/customers/{id}/access` |
| Subscriptions | GET | `/api/v1/customers/{id}/subscriptions` |
| Entitlement value | GET | `/api/v1/customers/{id}/entitlements/{featureKey}/value` |
| Stripe data | GET/PUT | `/api/v1/customers/{id}/stripe` |
| Stripe portal | POST | `/api/v1/customers/{id}/stripe/portal` |
| App data | GET/PUT/DELETE | `/api/v1/customers/{id}/apps/{appIdOrType}` |

**Gotcha:** DELETE returns 409 if customer has active subscriptions or non-final invoices. See [references/billing.md](references/billing.md) for the customer delete flow.

---

## 5. Subscriptions

| Operation | Method | Path |
|-----------|--------|------|
| Create | POST | `/api/v1/subscriptions` |
| Get | GET | `/api/v1/subscriptions/{id}` |
| Edit | PATCH | `/api/v1/subscriptions/{id}` |
| Delete | DELETE | `/api/v1/subscriptions/{id}` |
| Cancel | POST | `/api/v1/subscriptions/{id}/cancel` |
| Change plan | POST | `/api/v1/subscriptions/{id}/change` |
| Migrate | POST | `/api/v1/subscriptions/{id}/migrate` |
| Restore | POST | `/api/v1/subscriptions/{id}/restore` |
| Unschedule cancel | POST | `/api/v1/subscriptions/{id}/unschedule-cancelation` |
| Subscription addons | GET/POST | `/api/v1/subscriptions/{id}/addons` |

### PATCH Subscription Customizations

The `PATCH /api/v1/subscriptions/{id}` endpoint supports a `customizations` array for modifying subscription items without changing plans. This is useful for admin operations like adding bonus quota.

**Request body:**

```json
{
  "customizations": [
    {
      "op": "add_item",
      "path": "/phases/0/items/{featureKey}",
      "value": {
        "createInput": {
          "type": "boolean" | "static" | "metered",
          "issueAfterReset": 55000,
          "isSoftLimit": false
        }
      }
    }
  ]
}
```

**Use cases:**

- **Add quota bonus:** Increase `issueAfterReset` to give extra API calls for the current period
- **Revert quota:** Reset `issueAfterReset` to plan base value at period end

**Key fields:**

| Field | Description |
|-------|-------------|
| `op` | Operation type: `add_item`, `remove_item` |
| `path` | JSONPath to the item, e.g. `/phases/0/items/api_requests` |
| `value.createInput.issueAfterReset` | Quota issued at start of each period |
| `value.createInput.isSoftLimit` | `false` = hard limit, `true` = overage allowed |

**Response includes:**

- `items[].entitlement.currentUsagePeriod` — Start/end of current billing period
- `items[].entitlement.issueAfterReset` — Updated quota value

**Verified behavior:** When `issueAfterReset` is modified via PATCH, the change is immediately reflected in `totalAvailableGrantAmount` balance without requiring a period reset.

### stretch_phase Operation

The `stretch_phase` operation extends a subscription phase duration without affecting quota periods. Useful for trial extensions.

**Request body:**

```json
{
  "customizations": [
    {
      "op": "stretch_phase",
      "phaseKey": "trial",
      "extendBy": "P7D"
    }
  ]
}
```

**Critical: Phase key must match exactly.** The `phaseKey` must match the subscription's actual phase key:

```bash
# Check subscription's phase keys first
curl http://localhost:8888/api/v1/subscriptions/{id} | jq '.phases[].key'
```

**Common pitfall:** If you update your plan to have different phase keys (e.g., changing from `"standard"` to `"trial"`), existing subscriptions retain their original phase keys. The `stretch_phase` operation will fail with a 400 error if the phase key doesn't exist.

### Subscription State Limitations

| Status | Allowed Operations |
|--------|-------------------|
| `active` | PATCH, cancel, change, migrate |
| `inactive` | None (must create new subscription) |
| `canceled` | restore, then other operations |

**Key insight:** Inactive subscriptions (e.g., ended trials) cannot be modified. To "reactivate" an expired trial, create a new subscription on the current plan version.

### Legacy Subscription Migration Pattern

When plan versions change (e.g., adding new phases), existing subscriptions are NOT automatically migrated. For admin tools that modify subscriptions:

```typescript
const omStatus = await getSubscriptionStatus(subscriptionId);

if (omStatus.status === "inactive" || omStatus.phaseKey !== expectedPhaseKey) {
  // Create new subscription on current plan version
  const newSub = await createSubscription(customerId, planKey);
  // Update local DB with new OpenMeter subscription ID
} else {
  // Use normal modification (stretch_phase, add_item, etc.)
  await patchSubscription(subscriptionId, customizations);
}
```

---

## 6. Entitlements

| Operation | Method | Path |
|-----------|--------|------|
| List all | GET | `/api/v1/entitlements` |
| Get by id | GET | `/api/v1/entitlements/{id}` |
| Per-customer value | GET | `/api/v1/customers/{id}/entitlements/{featureKey}/value` |
| History | GET | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{idOrKey}/history` |
| Reset usage | POST | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{id}/reset` |
| Override | PUT | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{idOrKey}/override` |
| Grants | POST/GET/DELETE | `/api/v1/subjects/.../entitlements/.../grants`, `/api/v1/grants/...` |

---

## 7. Billing

See [references/billing.md](references/billing.md) for invoice lifecycle, customer delete flow, and rate card schemas.

| Resource | Operations | Base Path |
|----------|-----------|-----------|
| Profiles | List, Create, Get, Update, Delete | `/api/v1/billing/profiles` |
| Customer overrides | List, Upsert, Get, Delete | `/api/v1/billing/profiles/{id}/customer-overrides` |
| Invoices | List, Get, Update, Delete, Simulate | `/api/v1/billing/invoices` |
| Invoice actions | Advance, Approve, Retry, Void, Snapshot, Recalculate tax | POST on `/api/v1/billing/invoices/{id}/{action}` |
| Pending lines | Create, Invoice | `/api/v1/billing/customers/{id}/invoices/pending-lines` |

**Invoice lifecycle:** `gathering → draft → issuing → issued → (paid | void | uncollectible)`

---

## 8. Notifications

See [references/notifications.md](references/notifications.md) for channels, rules, and event details.

| Resource | Operations | Base Path |
|----------|-----------|-----------|
| Channels | List, Create, Get, Update, Delete | `/api/v1/notification/channels` |
| Rules | List, Create, Get, Update, Delete, Test | `/api/v1/notification/rules` |
| Events | List, Get, Resend | `/api/v1/notification/events` |

**Note:** Channel creation via API is Cloud-only (Svix-backed). Self-hosted uses YAML config.

---

## 9. Apps

| Operation | Method | Path |
|-----------|--------|------|
| List apps | GET | `/api/v1/apps` |
| Get app | GET | `/api/v1/apps/{id}` |
| Update app | PUT | `/api/v1/apps/{id}` |
| Uninstall | DELETE | `/api/v1/apps/{id}` |

### App: Stripe

| Operation | Method | Path |
|-----------|--------|------|
| Update Stripe key | PUT | `/api/v1/apps/{id}/stripe/api-key` |
| Stripe webhook | POST | `/api/v1/apps/{id}/stripe/webhook` |
| Checkout session | POST | `/api/v1/stripe/checkout/sessions` |

### App: Custom Invoicing

| Operation | Method | Path |
|-----------|--------|------|
| Draft synced | POST | `/api/v1/apps/{id}/custom-invoicing/draft-synchronized` |
| Issuing synced | POST | `/api/v1/apps/{id}/custom-invoicing/issuing-synchronized` |
| Update payment | POST | `/api/v1/apps/{id}/custom-invoicing/update-payment-status` |

### Marketplace

| Operation | Method | Path |
|-----------|--------|------|
| List listings | GET | `/api/v1/marketplace/listings` |
| Get listing | GET | `/api/v1/marketplace/listings/{type}` |
| Install (generic) | POST | `/api/v1/marketplace/listings/{type}/install` |
| Install (API key) | POST | `/api/v1/marketplace/listings/{type}/install/apikey` |
| Install (OAuth2 URL) | GET | `/api/v1/marketplace/listings/{type}/install/oauth2` |
| Install (OAuth2 auth) | POST | `/api/v1/marketplace/listings/{type}/install/oauth2/authorize` |

---

## 10. Portal

| Operation | Method | Path |
|-----------|--------|------|
| Create token | POST | `/api/v1/portal/tokens` |
| List tokens | GET | `/api/v1/portal/tokens` |
| Invalidate tokens | POST | `/api/v1/portal/tokens/invalidate` |
| Query meter | GET | `/api/v1/portal/meters/{meterSlug}/query` |

---

## 11. Lookup Information

| Operation | Method | Path |
|-----------|--------|------|
| List currencies | GET | `/api/v1/currencies` |
| Get progress | GET | `/api/v1/progress` |

---

## 12. Debug

| Operation | Method | Path |
|-----------|--------|------|
| Get metrics | GET | `/api/v1/debug/metrics` |

---

## 13. Subjects (Deprecated)

Use Customers with `usageAttribution.subjectKeys` instead.

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/subjects` |
| Upsert | POST | `/api/v1/subjects` |
| Get | GET | `/api/v1/subjects/{subjectIdOrKey}` |
| Delete | DELETE | `/api/v1/subjects/{subjectIdOrKey}` |

---

## Gotchas and Errors

| Symptom | Cause | Fix |
|---------|-------|-----|
| 409 on DELETE customer | Active subscriptions or non-final invoices | Cancel subs, void/delete invoices first |
| 400 "single draft version" | Duplicate plan draft | Skip creation if plan key exists |
| 400 "only Plans in [draft scheduled] can be published" | Plan already active | Expected — skip publish |
| 500 on POST /notification/channels | Self-hosted: not implemented | Use YAML config for local; API for Cloud only |
| 405 on PATCH invoice | PATCH not supported | Use POST subpaths: `/advance`, `/approve`, `/void` |
| Usage not attributed | Subject mismatch | Event `subject` must match `usageAttribution.subjectKeys` |
| Plan not found | Wrong key format | Use snake_case: `pro`, `pro_plus` |
| Event not metered | Type mismatch | Event `type` must equal meter's `eventType` |
| Overage not billed | Tier format | `upToAmount` must be string; include both `flatPrice` and `unitPrice` |
| IDs look like `01G65Z...` | ULID format | Standard; regex: `^[0-7][0-9A-HJKMNP-TV-Za-hjkmnp-tv-z]{25}$` |

---

## Self-Hosted Troubleshooting: Railway/Kafka

### Events Not Metering (0 Usage, Empty `/api/v1/events`)

**Root Cause:** Kafka has no persistent volume. Topics are lost on every Kafka restart.

**Symptoms:**
- OpenMeter logs: `kafka delivery failed: Broker: Unknown topic or partition`
- Sink worker logs: `no topics found to be subscribed to` or `partitions=[]`
- ClickHouse has 0 tables
- `/api/v1/events` returns `[]`

**Architecture:**
```
Event → OpenMeter API → Kafka → Sink Worker → ClickHouse → Meters
```

If any link breaks, events don't meter.

**Fix:**

1. **Add Kafka volume** at `/var/lib/kafka/data`
   - Railway: Service → Settings → Volumes → Add
   - For Confluent images: Set `RAILWAY_RUN_UID=0` for volume permissions

2. **Provision topics explicitly** (if `KAFKA_AUTO_CREATE_TOPICS_ENABLE=false`):
   ```
   om_default_events (namespace events - sink worker consumes)
   om_sys.api_events
   om_sys.ingest_events
   ```

3. **Restart OpenMeter + sink-worker** after Kafka restarts to refresh metadata

4. **Verify:**
   - Restart Kafka twice → topics persist
   - Send test event → appears in `/api/v1/events`

**Kafka Environment Variables (Railway):**
```bash
KAFKA_AUTO_CREATE_TOPICS_ENABLE=true  # Or provision topics explicitly
KAFKA_LOG_DIRS=/var/lib/kafka/data/logs-v2  # Use subdirectory if cluster ID conflicts
RAILWAY_RUN_UID=0  # Confluent images need root for volume permissions
```

### Sink Worker Partition Instability

**Symptom:** Sink worker gets partition assignment, loses it within seconds.

**Cause:** Multiple sink-worker instances competing for single partition (Railway rolling deploys).

**Fix:** Ensure only 1 sink-worker instance runs. Check Kafka logs for `"group ... with N members"` where N > 1.

---

## References

### First-Party Documentation

- [OpenMeter API Reference](https://openmeter.io/docs/api) — Official API documentation
- [OpenMeter GitHub](https://github.com/openmeterio/openmeter) — Source code and examples
- [CloudEvents Specification](https://cloudevents.io/) — Event format specification
- [OpenMeter Cloud](https://openmeter.cloud/) — Managed service

### SDKs

- [Node.js SDK](https://www.npmjs.com/package/@openmeter/sdk) — Official Node.js client
- [Python SDK](https://pypi.org/project/openmeter/) — Official Python client
- [Go SDK](https://pkg.go.dev/github.com/openmeterio/openmeter/api/client/go) — Official Go client

### Related Skills

- [tl-openmeter-local-dev](../tl-openmeter-local-dev/SKILL.md) — Local development setup
- [tl-openmeter-api-mcp-server](../tl-openmeter-api-mcp-server/SKILL.md) — MCP server for Cursor

### Reference

The full OpenAPI 3.0 spec is bundled at [assets/openapi-spec.json](assets/openapi-spec.json). Use it as the source of truth for request/response schemas, query parameters, and error codes.
