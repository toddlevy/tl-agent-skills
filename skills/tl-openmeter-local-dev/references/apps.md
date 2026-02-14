# OpenMeter Apps Deep Dive

OpenMeter uses an **Apps** architecture for billing provider integrations. This reference covers all app types, lifecycle, and the critical Stripe App setup.

## What Are OpenMeter Apps?

Apps connect OpenMeter to external billing providers. They handle:
- Invoice creation and delivery
- Payment collection
- Customer billing profile linking

## App Types

| App Type | ID in API | Billing | Payment | Invoicing |
|----------|-----------|---------|---------|-----------|
| **Sandbox** | `sandbox` | Simulated | None | Fake invoices |
| **Stripe** | `stripe` | Real | Stripe | Stripe Invoicing |
| **Custom Invoicing** | `custom_invoicing` | External | External | BYO |

## App Lifecycle

```
Install App → Create Billing Profile → Link Customers → Generate Invoices
     ↓                  ↓                    ↓                  ↓
  POST /marketplace   Auto-created by     PUT /customers/     Automatic on
  /listings/stripe/   install script      {id}/stripe         billing cycle
  install/apikey
```

## API Endpoints

| Operation | Method | Path |
|-----------|--------|------|
| List installed apps | GET | `/api/v1/apps` |
| Get app details | GET | `/api/v1/apps/{id}` |
| Uninstall app | DELETE | `/api/v1/apps/{id}` |
| List marketplace | GET | `/api/v1/marketplace/listings` |
| Install Stripe (API key) | POST | `/api/v1/marketplace/listings/stripe/install/apikey` |
| Install Stripe (OAuth) | POST | `/api/v1/marketplace/listings/stripe/install/oauth2` |

## The Sandbox App Problem

OpenMeter installs a **Sandbox** app by default. This causes critical issues:

- Sandbox and Stripe apps **conflict** when both are installed
- Subscriptions created with Sandbox **can't be migrated** to Stripe
- Billing profiles reference the **wrong app**
- Invoice generation silently uses Sandbox instead of Stripe

**Rule**: For any environment that uses Stripe, remove Sandbox first.

## Stripe App Install

### Via Script (Recommended)

```bash
npx tsx scripts/openmeter/openmeter-install-stripe-app.ts
```

The script:
1. Lists existing apps
2. Removes the Sandbox app if present
3. Installs the Stripe app with your `STRIPE_SECRET_KEY`
4. Creates a billing profile linked to Stripe

### Via API (Manual)

```bash
# Remove Sandbox (get ID first)
curl http://localhost:8888/api/v1/apps
curl -X DELETE http://localhost:8888/api/v1/apps/{sandbox-app-id}

# Install Stripe
curl -X POST http://localhost:8888/api/v1/marketplace/listings/stripe/install/apikey \
  -H "Content-Type: application/json" \
  -d '{"apiKey":"sk_test_...","name":"Stripe","createBillingProfile":true}'
```

### Stripe App Install Body

```json
{
  "apiKey": "sk_test_...",
  "name": "Stripe",
  "createBillingProfile": true
}
```

## Stripe App Requirements

| Requirement | Local | Staging/Production |
|-------------|-------|--------------------|
| `apps.baseURL` publicly accessible | Via ngrok | Via deployed URL |
| `STRIPE_SECRET_KEY` valid | `sk_test_...` | `sk_test_...` or `sk_live_...` |
| Sandbox app removed | Yes | Yes |
| Billing profile exists | Auto-created by script | Auto-created by script |

## How the Stripe App Works

The Stripe App needs a public URL to receive callbacks:

```
Stripe → apps.baseURL (your server) → OpenMeter
```

Locally, `apps.baseURL` in `config.local.yaml` must be your **ngrok URL**.

In staging/production, it's your deployed server URL.

## Linking Customers to Stripe

After creating a customer in OpenMeter, link their Stripe customer ID:

```bash
# Convenience endpoint
curl -X PUT http://localhost:8888/api/v1/customers/{customerIdOrKey}/stripe \
  -H "Content-Type: application/json" \
  -d '{"stripeCustomerID":"cus_xxx"}'

# Or the apps-style endpoint
curl -X PUT http://localhost:8888/api/v1/customers/{customerIdOrKey}/apps/stripe \
  -H "Content-Type: application/json" \
  -d '{"stripeCustomerID":"cus_xxx"}'
```

## Stripe App Recovery

The Stripe app can disappear when:
- Running `--openmeter-all` cleanup (removes all customers, can unlink app)
- Manually deleting all billing profiles
- Database reset

To recover:

```bash
npx tsx scripts/openmeter/openmeter-install-stripe-app.ts
```

Then re-link any existing customers to their Stripe customer IDs.
