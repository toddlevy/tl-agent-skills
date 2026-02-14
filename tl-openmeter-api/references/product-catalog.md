# OpenMeter Product Catalog

The **Product Catalog** tag covers three resource types: **Features**, **Plans**, and **Addons**. Together they define what you sell and how usage is priced.

---

## Features

Features represent capabilities or metered resources. They link meters to plan rate cards.

### Endpoints

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/features` |
| Create | POST | `/api/v1/features` |
| Get | GET | `/api/v1/features/{featureId}` |
| Delete | DELETE | `/api/v1/features/{featureId}` |

### Create Feature Example

```json
{
  "key": "api_requests",
  "name": "API Requests",
  "meterSlug": "api_requests",
  "meterGroupByFilters": {}
}
```

A feature key links to a meter slug. When used in a plan rate card, it defines the entitlement a customer receives.

---

## Plans

Plans define pricing structures and entitlement templates for customers. They follow a strict versioning lifecycle and contain phases with rate cards.

### Endpoints

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

### Plan Versioning Lifecycle

```
draft ──(publish)──→ active ──(archive)──→ archived
                       │
                       └──(next)──→ new draft (version N+1)
```

#### Key Rules

1. **Only one draft version per plan.** Creating when a draft exists returns 400: `"single draft version is allowed for Plan"`.
2. **Only draft plans can be edited/deleted.** Active and archived plans are immutable.
3. **Publishing transitions draft → active.** The previously active version is automatically archived.
4. **`next` creates a new draft** from the currently active plan, incrementing the version.
5. **Plan key is immutable** once created. Must be snake_case: `^[a-z0-9]+(?:_[a-z0-9]+)*$`

### Idempotent Catalog Sync Pattern

When syncing plans from config to OpenMeter:

```
1. GET /api/v1/plans?key={key}
2. If plan exists:
   a. If active → skip (already published)
   b. If draft → update if needed, then publish
3. If plan not found:
   a. POST /api/v1/plans (creates draft)
   b. POST /api/v1/plans/{id}/publish
```

| Existing Status | Action |
|-----------------|--------|
| Not found | Create → Publish |
| Draft | Update if changed → Publish |
| Active | Skip (log "already active") |
| Archived | Create next version → Publish |

### Plan Structure

```json
{
  "key": "pro",
  "name": "Pro Plan",
  "description": "Professional tier",
  "currency": "USD",
  "metadata": {},
  "phases": [
    {
      "key": "main",
      "name": "Main Phase",
      "description": "Monthly billing",
      "startAfter": "P0D",
      "rateCards": [
        { "...flat_fee rate card..." },
        { "...usage_based rate card..." }
      ]
    }
  ]
}
```

### Multiple Phases

Plans can have multiple phases (e.g., trial → regular):

```json
{
  "phases": [
    {
      "key": "trial",
      "name": "Trial Period",
      "startAfter": "P0D",
      "rateCards": [
        {
          "type": "flat_fee",
          "featureKey": "api_access",
          "entitlementTemplate": { "type": "boolean" },
          "price": { "type": "flat", "amount": "0.00" },
          "billingCadence": "MONTH"
        }
      ]
    },
    {
      "key": "regular",
      "name": "Regular Billing",
      "startAfter": "P14D",
      "rateCards": [
        {
          "type": "flat_fee",
          "featureKey": "api_access",
          "entitlementTemplate": { "type": "boolean" },
          "price": { "type": "flat", "amount": "29.00" },
          "billingCadence": "MONTH"
        }
      ]
    }
  ]
}
```

---

## Addons

Addons are modular rate card bundles. They follow the same versioning lifecycle as Plans (draft → published → archived).

### Endpoints

| Operation | Method | Path | Notes |
|-----------|--------|------|-------|
| List | GET | `/api/v1/addons` | Params: `includeDeleted`, `id` |
| Create | POST | `/api/v1/addons` | Creates in draft |
| Get | GET | `/api/v1/addons/{addonIdOrKey}` | |
| Update | PUT | `/api/v1/addons/{addonIdOrKey}` | Only draft |
| Delete | DELETE | `/api/v1/addons/{addonIdOrKey}` | Only draft |
| Publish | POST | `/api/v1/addons/{addonIdOrKey}/publish` | Draft → published |
| Archive | POST | `/api/v1/addons/{addonIdOrKey}/archive` | Published → archived |

### Plan Addons (attaching addons to plans)

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/plans/{planIdOrKey}/addons` |
| Create | POST | `/api/v1/plans/{planIdOrKey}/addons` |
| Get | GET | `/api/v1/plans/{planIdOrKey}/addons/{planAddonIdOrKey}` |
| Update | PUT | `/api/v1/plans/{planIdOrKey}/addons/{planAddonIdOrKey}` |
| Delete | DELETE | `/api/v1/plans/{planIdOrKey}/addons/{planAddonIdOrKey}` |

### Subscription Addons (attaching addons to subscriptions)

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/subscriptions/{id}/addons` |
| Create | POST | `/api/v1/subscriptions/{id}/addons` |
| Get | GET | `/api/v1/subscriptions/{id}/addons/{addonId}` |
| Update | PUT | `/api/v1/subscriptions/{id}/addons/{addonId}` |

---

## Rate Cards

Plan phases and addons use rate cards to define pricing.

### Flat Fee Rate Card

Fixed charge for access to a feature:

```json
{
  "type": "flat_fee",
  "featureKey": "api_access",
  "entitlementTemplate": {
    "type": "boolean"
  },
  "price": {
    "type": "flat",
    "amount": "29.00"
  },
  "billingCadence": "MONTH"
}
```

### Usage-Based Rate Card

Metered usage with tiered pricing:

```json
{
  "type": "usage_based",
  "featureKey": "api_requests",
  "entitlementTemplate": {
    "type": "metered",
    "usagePeriod": "MONTH",
    "isSoftLimit": true
  },
  "price": {
    "type": "tiered",
    "mode": "graduated",
    "tiers": [
      {
        "upToAmount": "1000",
        "flatPrice": { "amount": "0.00" },
        "unitPrice": { "amount": "0.00" }
      },
      {
        "upToAmount": "10000",
        "flatPrice": { "amount": "0.00" },
        "unitPrice": { "amount": "0.005" }
      }
    ]
  },
  "billingCadence": "MONTH"
}
```

### Rate Card Gotchas

| Issue | Resolution |
|-------|-----------|
| `upToAmount` must be a **string** | `"1000"` not `1000` |
| Tiers must include both `flatPrice` and `unitPrice` | Even if one is `"0.00"` |
| `billingCadence` is ISO 8601 duration | Common: `MONTH`, `P1M` |
| `isSoftLimit: true` | Allows overage beyond the included amount |
| `isSoftLimit: false` | Hard cap — denies access beyond limit |

### Entitlement Template Types

| Type | Usage |
|------|-------|
| `boolean` | Feature flag; on/off access |
| `metered` | Usage-tracked with quota and optional overage |
| `static` | Fixed value (e.g., number of seats) |

### Tiered Pricing Modes

| Mode | Behavior |
|------|----------|
| `graduated` | Each tier applies to usage within that tier's range |
| `volume` | All usage is priced at the tier matching total usage |

---

## Common Errors

| Error | Cause | Resolution |
|-------|-------|-----------|
| 400: `"single draft version is allowed for Plan"` | Tried to create plan when draft already exists | Use `next` on active plan, or update existing draft |
| 400: `"only Plans in [draft scheduled] can be published"` | Plan is already active or archived | Skip publish; plan is already live |
| 400: `"Plan key must match..."` | Invalid key format | Use snake_case: `pro`, `api_pro`, `enterprise_plus` |
| 400: `"plan already active"` on publish | Already published | Expected for idempotent sync; skip |
| 404 on `GET /plans/{key}` | Key doesn't exist | Create the plan first |
| 409 on delete active plan | Can't delete active plans | Archive first, then delete |
