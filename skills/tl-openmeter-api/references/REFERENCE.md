# OpenMeter API — Complete Endpoint Reference

All endpoints organized by official OpenAPI tag. Derived from the OpenAPI 3.0 specification.

## Authentication

```
Authorization: Bearer <OPENMETER_API_KEY>
```

Self-hosted instances often run unauthenticated locally; cloud instances require a token from the OpenMeter dashboard.

---

## 1. Events

| Operation | Method | Path | Notes |
|-----------|--------|------|-------|
| Ingest | POST | `/api/v1/events` | Content-Type: `application/cloudevents+json` |
| List | GET | `/api/v1/events` | Params: `from`, `to`, `limit`, `subject`, `hasError` |

### CloudEvent Payload

```json
{
  "specversion": "1.0",
  "id": "unique-event-id",
  "type": "api_request",
  "source": "my-app",
  "subject": "customer_abc123",
  "time": "2026-02-14T12:00:00Z",
  "data": { "value": 1, "path": "/v1/events", "method": "GET" }
}
```

**Deduplication**: `id` is the idempotency key. Duplicates within 24h are ignored.

**Subject attribution**: Events attach to customers via `usageAttribution.subjectKeys`. The event `subject` must be one of the customer's subject keys.

---

## 2. Meters

| Operation | Method | Path | Notes |
|-----------|--------|------|-------|
| List | GET | `/api/v1/meters` | Returns all meters |
| Create | POST | `/api/v1/meters` | |
| Get | GET | `/api/v1/meters/{meterIdOrSlug}` | Supports ID or slug |
| Update | PUT | `/api/v1/meters/{meterIdOrSlug}` | Full replace |
| Delete | DELETE | `/api/v1/meters/{meterIdOrSlug}` | |
| Query | GET | `/api/v1/meters/{meterIdOrSlug}/query` | Params: `subject`, `from`, `to`, `windowSize`, `groupBy`, `filterGroupBy` |
| Query (POST) | POST | `/api/v1/meters/{meterIdOrSlug}/query` | Same params in body |
| Group-by values | GET | `/api/v1/meters/{meterIdOrSlug}/group-by/{groupBy}/values` | |
| List subjects | GET | `/api/v1/meters/{meterIdOrSlug}/subjects` | |

### Create Meter Example

```json
{
  "slug": "api_requests",
  "description": "Total API requests",
  "eventType": "api_request",
  "aggregation": "COUNT",
  "groupBy": { "path": "$.path", "method": "$.method" }
}
```

**Aggregation types**: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `UNIQUE_COUNT`

**Window sizes**: `MINUTE`, `HOUR`, `DAY`, `MONTH`

### Query Example

```
GET /api/v1/meters/api_requests/query?subject=user_abc&from=2026-02-01T00:00:00Z&to=2026-02-14T23:59:59Z&windowSize=DAY
```

---

## 3. Product Catalog

Covers **Features**, **Plans**, and **Addons**.

### Features

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/features` |
| Create | POST | `/api/v1/features` |
| Get | GET | `/api/v1/features/{featureId}` |
| Delete | DELETE | `/api/v1/features/{featureId}` |

### Plans

| Operation | Method | Path | Notes |
|-----------|--------|------|-------|
| List | GET | `/api/v1/plans` | Params: `page`, `pageSize`, `key`, `includeDeleted`, `orderBy` |
| Create | POST | `/api/v1/plans` | Creates in `draft` status |
| Get | GET | `/api/v1/plans/{planIdOrKey}` | Supports ID or key |
| Update | PUT | `/api/v1/plans/{planIdOrKey}` | Only draft plans |
| Delete | DELETE | `/api/v1/plans/{planIdOrKey}` | Only draft plans |
| Next version | POST | `/api/v1/plans/{planIdOrKey}/next` | Creates new draft from active plan |
| Publish | POST | `/api/v1/plans/{planIdOrKey}/publish` | Draft → active |
| Archive | POST | `/api/v1/plans/{planIdOrKey}/archive` | Active → archived |

### Plan Addons

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/plans/{planIdOrKey}/addons` |
| Create | POST | `/api/v1/plans/{planIdOrKey}/addons` |
| Get | GET | `/api/v1/plans/{planIdOrKey}/addons/{planAddonIdOrKey}` |
| Update | PUT | `/api/v1/plans/{planIdOrKey}/addons/{planAddonIdOrKey}` |
| Delete | DELETE | `/api/v1/plans/{planIdOrKey}/addons/{planAddonIdOrKey}` |

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

See [product-catalog.md](product-catalog.md) for versioning lifecycle, rate card schemas, and detailed examples.

---

## 4. Customers

| Operation | Method | Path | Notes |
|-----------|--------|------|-------|
| List | GET | `/api/v1/customers` | Params: `page`, `pageSize`, `key`, `name`, `primaryEmail`, `subject`, `planKey`, `includeDeleted`, `expand` |
| Create | POST | `/api/v1/customers` | |
| Get | GET | `/api/v1/customers/{customerIdOrKey}` | |
| Delete | DELETE | `/api/v1/customers/{id}` | 409 if active subscriptions or non-final invoices |
| Get access | GET | `/api/v1/customers/{id}/access` | |
| List subscriptions | GET | `/api/v1/customers/{id}/subscriptions` | |
| Get entitlement value | GET | `/api/v1/customers/{id}/entitlements/{featureKey}/value` | |
| Get app data | GET | `/api/v1/customers/{id}/apps/{appIdOrType}` | |
| Upsert app data | PUT | `/api/v1/customers/{id}/apps/{appIdOrType}` | |
| Delete app data | DELETE | `/api/v1/customers/{id}/apps/{appIdOrType}` | |
| Get Stripe data | GET | `/api/v1/customers/{id}/stripe` | |
| Upsert Stripe data | PUT | `/api/v1/customers/{id}/stripe` | |
| Stripe portal session | POST | `/api/v1/customers/{id}/stripe/portal` | |

### Create Customer Example

```json
{
  "key": "cust_abc123",
  "name": "Acme Corp",
  "primaryEmail": "billing@acme.com",
  "currency": "USD",
  "billingAddress": { "country": "US", "state": "CA" },
  "usageAttribution": { "subjectKeys": ["user_abc123"] }
}
```

---

## 5. Subscriptions

| Operation | Method | Path | Notes |
|-----------|--------|------|-------|
| Create | POST | `/api/v1/subscriptions` | |
| Get | GET | `/api/v1/subscriptions/{id}` | |
| Edit | PATCH | `/api/v1/subscriptions/{id}` | |
| Delete | DELETE | `/api/v1/subscriptions/{id}` | |
| Cancel | POST | `/api/v1/subscriptions/{id}/cancel` | |
| Change plan | POST | `/api/v1/subscriptions/{id}/change` | |
| Migrate | POST | `/api/v1/subscriptions/{id}/migrate` | |
| Restore | POST | `/api/v1/subscriptions/{id}/restore` | |
| Unschedule cancelation | POST | `/api/v1/subscriptions/{id}/unschedule-cancelation` | |
| Create addon | POST | `/api/v1/subscriptions/{id}/addons` | |
| List addons | GET | `/api/v1/subscriptions/{id}/addons` | |
| Get addon | GET | `/api/v1/subscriptions/{id}/addons/{addonId}` | |
| Update addon | PUT | `/api/v1/subscriptions/{id}/addons/{addonId}` | |

### Create Subscription Example

```json
{
  "customerId": "01ABC...",
  "plan": { "key": "pro" },
  "currency": "USD"
}
```

---

## 6. Entitlements

| Operation | Method | Path | Notes |
|-----------|--------|------|-------|
| List all | GET | `/api/v1/entitlements` | Params: `featureKey`, `featureId`, `includeDeleted` |
| Get by ID | GET | `/api/v1/entitlements/{id}` | |
| Create (subject) | POST | `/api/v1/subjects/{subjectIdOrKey}/entitlements` | |
| List (subject) | GET | `/api/v1/subjects/{subjectIdOrKey}/entitlements` | |
| Get (subject) | GET | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{id}` | |
| Delete (subject) | DELETE | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{id}` | |
| History | GET | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{idOrKey}/history` | Params: `from`, `to`, `windowSize` |
| Reset usage | POST | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{id}/reset` | |
| Override | PUT | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{idOrKey}/override` | |
| Get value | GET | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{idOrKey}/value` | |

### Entitlement Value Response

```json
{ "hasAccess": true, "balance": 950, "usage": 50, "overage": 0 }
```

### Grants

| Operation | Method | Path |
|-----------|--------|------|
| List all | GET | `/api/v1/grants` |
| Create | POST | `/api/v1/subjects/{subjectIdOrKey}/entitlements/{idOrKey}/grants` |
| Void | DELETE | `/api/v1/grants/{grantId}` |

---

## 7. Billing

| Operation | Method | Path |
|-----------|--------|------|
| List profiles | GET | `/api/v1/billing/profiles` |
| Create profile | POST | `/api/v1/billing/profiles` |
| Get profile | GET | `/api/v1/billing/profiles/{id}` |
| Update profile | PUT | `/api/v1/billing/profiles/{id}` |
| Delete profile | DELETE | `/api/v1/billing/profiles/{id}` |
| List customer overrides | GET | `/api/v1/billing/profiles/{id}/customer-overrides` |
| Upsert customer override | PUT | `/api/v1/billing/profiles/{id}/customer-overrides/{customerId}` |
| Get customer override | GET | `/api/v1/billing/profiles/{id}/customer-overrides/{customerId}` |
| Delete customer override | DELETE | `/api/v1/billing/profiles/{id}/customer-overrides/{customerId}` |
| List invoices | GET | `/api/v1/billing/invoices` |
| Get invoice | GET | `/api/v1/billing/invoices/{id}` |
| Update invoice | PUT | `/api/v1/billing/invoices/{id}` |
| Delete invoice | DELETE | `/api/v1/billing/invoices/{id}` |
| Simulate invoice | POST | `/api/v1/billing/invoices/simulate` |
| Pending lines action | POST | `/api/v1/billing/customers/{customerId}/invoices/pending-lines` |
| Advance invoice | POST | `/api/v1/billing/invoices/{id}/advance` |
| Approve invoice | POST | `/api/v1/billing/invoices/{id}/approve` |
| Retry invoice | POST | `/api/v1/billing/invoices/{id}/retry` |
| Void invoice | POST | `/api/v1/billing/invoices/{id}/void` |
| Snapshot quantities | POST | `/api/v1/billing/invoices/{id}/snapshot-quantities` |
| Recalculate tax | POST | `/api/v1/billing/invoices/{id}/recalculate-tax` |

See [billing.md](billing.md) for invoice lifecycle, customer delete flow, and rate card schemas.

---

## 8. Notifications

| Operation | Method | Path |
|-----------|--------|------|
| List channels | GET | `/api/v1/notification/channels` |
| Create channel | POST | `/api/v1/notification/channels` |
| Get channel | GET | `/api/v1/notification/channels/{channelId}` |
| Update channel | PUT | `/api/v1/notification/channels/{channelId}` |
| Delete channel | DELETE | `/api/v1/notification/channels/{channelId}` |
| List rules | GET | `/api/v1/notification/rules` |
| Create rule | POST | `/api/v1/notification/rules` |
| Get rule | GET | `/api/v1/notification/rules/{ruleId}` |
| Update rule | PUT | `/api/v1/notification/rules/{ruleId}` |
| Delete rule | DELETE | `/api/v1/notification/rules/{ruleId}` |
| Test rule | POST | `/api/v1/notification/rules/{ruleId}/test` |
| List events | GET | `/api/v1/notification/events` |
| Get event | GET | `/api/v1/notification/events/{eventId}` |
| Resend event | POST | `/api/v1/notification/events/{eventId}/resend` |

See [notifications.md](notifications.md) for channels, rules, events, and self-hosted vs cloud differences.

---

## 9. Apps

| Operation | Method | Path |
|-----------|--------|------|
| List apps | GET | `/api/v1/apps` |
| Get app | GET | `/api/v1/apps/{id}` |
| Update app | PUT | `/api/v1/apps/{id}` |
| Uninstall app | DELETE | `/api/v1/apps/{id}` |

---

## 10. App: Stripe

| Operation | Method | Path |
|-----------|--------|------|
| Update Stripe API key | PUT | `/api/v1/apps/{id}/stripe/api-key` |
| Stripe webhook | POST | `/api/v1/apps/{id}/stripe/webhook` |
| Checkout session | POST | `/api/v1/stripe/checkout/sessions` |

---

## 11. App: Custom Invoicing

| Operation | Method | Path |
|-----------|--------|------|
| Draft synchronized | POST | `/api/v1/apps/{id}/custom-invoicing/draft-synchronized` |
| Issuing synchronized | POST | `/api/v1/apps/{id}/custom-invoicing/issuing-synchronized` |
| Update payment status | POST | `/api/v1/apps/{id}/custom-invoicing/update-payment-status` |

---

## 12. Marketplace

| Operation | Method | Path |
|-----------|--------|------|
| List listings | GET | `/api/v1/marketplace/listings` |
| Get listing | GET | `/api/v1/marketplace/listings/{type}` |
| Install (generic) | POST | `/api/v1/marketplace/listings/{type}/install` |
| Install (API key) | POST | `/api/v1/marketplace/listings/{type}/install/apikey` |
| Install (OAuth2 URL) | GET | `/api/v1/marketplace/listings/{type}/install/oauth2` |
| Install (OAuth2 auth) | POST | `/api/v1/marketplace/listings/{type}/install/oauth2/authorize` |

---

## 13. Portal

| Operation | Method | Path |
|-----------|--------|------|
| Create token | POST | `/api/v1/portal/tokens` |
| List tokens | GET | `/api/v1/portal/tokens` |
| Invalidate tokens | POST | `/api/v1/portal/tokens/invalidate` |
| Query meter | GET | `/api/v1/portal/meters/{meterSlug}/query` |

---

## 14. Lookup Information

| Operation | Method | Path |
|-----------|--------|------|
| List currencies | GET | `/api/v1/currencies` |
| Get progress | GET | `/api/v1/progress` |

---

## 15. Debug

| Operation | Method | Path |
|-----------|--------|------|
| Get metrics | GET | `/api/v1/debug/metrics` |

---

## 16. Subjects (Deprecated)

Use Customers with `usageAttribution.subjectKeys` instead.

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/subjects` |
| Upsert | POST | `/api/v1/subjects` |
| Get | GET | `/api/v1/subjects/{subjectIdOrKey}` |
| Delete | DELETE | `/api/v1/subjects/{subjectIdOrKey}` |

---

## V2 Endpoints

Customer-centric entitlement endpoints (V2):

| Operation | Method | Path |
|-----------|--------|------|
| Create | POST | `/api/v2/customers/{id}/entitlements` |
| List | GET | `/api/v2/customers/{id}/entitlements` |
| Get | GET | `/api/v2/customers/{id}/entitlements/{entId}` |
| Delete | DELETE | `/api/v2/customers/{id}/entitlements/{entId}` |
| Grants list | GET | `/api/v2/customers/{id}/entitlements/{entId}/grants` |
| Grants create | POST | `/api/v2/customers/{id}/entitlements/{entId}/grants` |
| History | GET | `/api/v2/customers/{id}/entitlements/{entId}/history` |
| Override | PUT | `/api/v2/customers/{id}/entitlements/{entId}/override` |
| Reset usage | POST | `/api/v2/customers/{id}/entitlements/{entId}/reset` |
| Get value | GET | `/api/v2/customers/{id}/entitlements/{entId}/value` |
| List all entitlements | GET | `/api/v2/entitlements` |
| Get entitlement by ID | GET | `/api/v2/entitlements/{id}` |
| List events | GET | `/api/v2/events` |
| List grants | GET | `/api/v2/grants` |

---

## Pagination

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `pageSize` | int | 25 | Items per page |
| `order` | string | `ASC` | `ASC` or `DESC` |
| `orderBy` | string | varies | Sort field |

---

## Error Responses

All errors use RFC 7807 `application/problem+json`:

```json
{
  "type": "https://openmeter.io/problems/bad-request",
  "title": "Bad Request",
  "status": 400,
  "detail": "Plan key must match ^[a-z0-9]+(?:_[a-z0-9]+)*$"
}
```

| Status | Schema | Meaning |
|--------|--------|---------|
| 400 | BadRequestProblemResponse | Invalid input |
| 401 | UnauthorizedProblemResponse | Missing/invalid auth |
| 403 | ForbiddenProblemResponse | Insufficient permissions |
| 404 | NotFoundProblemResponse | Resource not found |
| 409 | ConflictProblemResponse | Resource conflict |
| 412 | PreconditionFailedProblemResponse | Precondition failed |
| 500 | InternalServerErrorProblemResponse | Server error |
| 503 | ServiceUnavailableProblemResponse | Service unavailable |
