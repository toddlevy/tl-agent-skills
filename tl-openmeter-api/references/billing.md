# OpenMeter Billing API

Comprehensive reference for billing profiles, invoices, customer overrides, and the Stripe/Sandbox/Custom Invoicing apps.

---

## Billing Profiles

Billing profiles configure how invoicing works. Typically one default profile exists per OpenMeter instance.

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/billing/profiles` |
| Create | POST | `/api/v1/billing/profiles` |
| Get | GET | `/api/v1/billing/profiles/{id}` |
| Update | PUT | `/api/v1/billing/profiles/{id}` |
| Delete | DELETE | `/api/v1/billing/profiles/{id}` |

### Create Profile Example

```json
{
  "name": "Default",
  "default": true,
  "apps": {
    "invoicing": { "type": "stripe" },
    "payment": { "type": "stripe" },
    "tax": { "type": "stripe" }
  },
  "workflow": {
    "collection": {
      "alignment": "subscription",
      "interval": "MONTH"
    },
    "invoicing": {
      "autoAdvance": true,
      "draftPeriod": "P1D",
      "dueAfter": "P7D"
    },
    "payment": {
      "collectionMethod": "charge_automatically"
    }
  }
}
```

---

## Customer Billing Overrides

Per-customer overrides for billing behavior (different collection intervals, due dates, etc.).

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/billing/profiles/{profileId}/customer-overrides` |
| Upsert | PUT | `/api/v1/billing/profiles/{profileId}/customer-overrides/{customerId}` |
| Get | GET | `/api/v1/billing/profiles/{profileId}/customer-overrides/{customerId}` |
| Delete | DELETE | `/api/v1/billing/profiles/{profileId}/customer-overrides/{customerId}` |

---

## Invoices

### Endpoints

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/billing/invoices` |
| Get | GET | `/api/v1/billing/invoices/{id}` |
| Update | PUT | `/api/v1/billing/invoices/{id}` |
| Delete | DELETE | `/api/v1/billing/invoices/{id}` |
| Simulate | POST | `/api/v1/billing/invoices/simulate` |
| Pending lines action | POST | `/api/v1/billing/customers/{customerId}/invoices/pending-lines` |

### Invoice Actions

These are POST subpaths on `/api/v1/billing/invoices/{id}`:

| Action | Path | Description |
|--------|------|-------------|
| Advance | `/advance` | Move invoice to next state in workflow |
| Approve | `/approve` | Approve invoice for payment |
| Retry | `/retry` | Retry failed invoice |
| Void | `/void` | Void an issued invoice |
| Snapshot quantities | `/snapshot-quantities` | Freeze usage quantities |
| Recalculate tax | `/recalculate-tax` | Recalculate tax amounts |

### Invoice Lifecycle

```
gathering → draft → issuing → issued → (paid | void | uncollectible)
```

| Status | Meaning | Actions Available |
|--------|---------|-------------------|
| `gathering` | Collecting usage events for billing period | Wait |
| `draft` | Usage snapshot taken, invoice assembled | Advance, Delete |
| `issuing` | Being sent to payment provider | Wait |
| `issued` | Sent to customer, awaiting payment | Void |
| `paid` | Payment received | (terminal) |
| `void` | Canceled/voided | (terminal) |
| `uncollectible` | Payment failed permanently | (terminal) |

### List Invoices Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `customer` | string | Filter by customer ID |
| `status` | string | Filter by status: `gathering`, `draft`, `issuing`, `issued`, `paid`, `void` |
| `issuedAfter` | date-time | Issued after timestamp |
| `issuedBefore` | date-time | Issued before timestamp |
| `expand` | string[] | Expand related resources (e.g., `lines`, `workflow`) |

### Create Pending Invoice Line

Used to manually add line items to a customer's next invoice.

```
POST /api/v1/billing/customers/{customerId}/invoices/pending-lines
```

```json
{
  "lines": [
    {
      "type": "flat_fee",
      "name": "Setup Fee",
      "amount": "99.00",
      "currency": "USD"
    }
  ]
}
```

### Simulate Invoice

Preview what an invoice would look like without creating it.

```
POST /api/v1/billing/invoices/simulate
```

---

## Custom Invoicing App

For third-party invoicing systems that are not Stripe:

| Operation | Method | Path |
|-----------|--------|------|
| Draft synced | POST | `/api/v1/apps/{id}/custom-invoicing/draft-synchronized` |
| Issuing synced | POST | `/api/v1/apps/{id}/custom-invoicing/issuing-synchronized` |
| Update payment | POST | `/api/v1/apps/{id}/custom-invoicing/update-payment-status` |

These endpoints let external invoicing systems report back to OpenMeter on invoice status changes.

---

## Apps (Stripe)

| Operation | Method | Path |
|-----------|--------|------|
| Update API key | PUT | `/api/v1/apps/{id}/stripe/api-key` |
| Stripe webhook | POST | `/api/v1/apps/{id}/stripe/webhook` |
| Checkout session | POST | `/api/v1/stripe/checkout/sessions` |

### Customer Stripe Data

Link OpenMeter customers to Stripe customers:

```
PUT /api/v1/customers/{id}/stripe
```

```json
{
  "stripeCustomerId": "cus_abc123"
}
```

### Stripe Portal Session

Create a Stripe Customer Portal session for a customer:

```
POST /api/v1/customers/{id}/stripe/portal
```

---

## Invoice Cleanup for Customer Deletion

When deleting a customer, you must handle invoices by status:

```
1. GET /api/v1/billing/invoices?customer={customerId}
2. For each invoice:
   - gathering → Wait (cannot be touched)
   - draft     → DELETE /api/v1/billing/invoices/{id}
   - issuing   → Wait for state change
   - issued    → POST /api/v1/billing/invoices/{id}/void
   - paid/void/uncollectible → Already terminal, OK
3. DELETE /api/v1/customers/{customerId}
```

**Gotcha:** If any invoice is in a non-terminal, non-deletable state, the customer delete will return 409. You must retry after waiting for the invoice to transition.

---

## Rate Card Types

Plans and addons use rate cards to define pricing:

### Flat Fee Rate Card

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

**Critical:** `upToAmount` must be a **string**, not a number. Tiers must include both `flatPrice` and `unitPrice` even when one is `"0.00"`.

### Tiered Pricing Modes

| Mode | Behavior |
|------|----------|
| `graduated` | Each tier applies to usage within that tier's range |
| `volume` | All usage is priced at the tier matching total usage |
