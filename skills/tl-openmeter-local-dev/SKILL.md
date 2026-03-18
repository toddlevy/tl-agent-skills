---
name: tl-openmeter-local-dev
description: Set up and troubleshoot OpenMeter for local development with Docker, ngrok, Stripe app, and webhook configuration. Covers self-hosted vs Cloud differences, catalog sync, environment-aware webhook handling, and OpenMeter Apps (Stripe, Sandbox). Use when setting up OpenMeter locally, configuring ngrok for webhooks, debugging catalog sync, or preparing local dev to match staging/production behavior.
license: MIT
compatibility: Requires Docker Desktop, Node.js 18+, PowerShell or Bash. Ngrok required for Stripe billing.
metadata:
  author: tl-agent-skills
  version: "1.0"
  suite: tl-openmeter
  related: tl-openmeter-api tl-openmeter-api-mcp-server
---

# OpenMeter Local Dev Setup

Run OpenMeter locally with full metering, billing, and webhook support. Covers the gotchas that differ between self-hosted (Docker) and Cloud (staging/production).

## When to Use

- "Set up OpenMeter locally"
- "Configure ngrok for webhooks"
- "Debug catalog sync errors"
- "Why is my webhook 500ing?"
- "Install the Stripe app in OpenMeter"
- "What works locally vs staging?"
- When user mentions OpenMeter + Docker, local dev, or webhook issues

## Suite

This skill is part of the **tl-openmeter** suite:

| Skill | Purpose |
|-------|---------|
| **tl-openmeter-api** | REST API reference (endpoints, schemas, gotchas) |
| **tl-openmeter-local-dev** | This skill: local dev setup and troubleshooting |
| **tl-openmeter-api-mcp-server** | MCP server for calling local OpenMeter from Cursor |

## Resources

- [references/REFERENCE.md](references/REFERENCE.md) — Env vars, Docker services, config files
- [references/apps.md](references/apps.md) — OpenMeter Apps deep dive (Stripe, Sandbox, Custom)
- [references/webhooks.md](references/webhooks.md) — Webhook auth modes, event types, testing
- [scripts/verify-setup.ps1](scripts/verify-setup.ps1) — Verify local OpenMeter environment health
- [assets/env-openmeter.template](assets/env-openmeter.template) — Environment variable template

---

## Step 0: Discover the User's Situation

Before proceeding, use the **AskQuestion tool** to determine what applies:

**Question 1: Environment**
- Local development (Docker) — proceed with this skill
- Staging or Production — redirect to `tl-openmeter-api` and deployment docs

**Question 2: Stripe billing needed?**
- Yes → Steps 1, 2, 3, 4, 5, 6 (full setup with ngrok)
- No → Steps 1, 4, 5 only (metering and entitlements without billing)

**Question 3: Ngrok status** (only if Stripe = yes)
- Already set up → skip ngrok install in Step 3
- Need to set it up → full Step 3
- Paid plan with static domain → note in Step 3 about skipping URL updates

---

## Self-Hosted vs Cloud: Critical Differences

| Feature | Self-Hosted (Local) | Cloud (Staging/Prod) |
|---------|--------------------|-----------------------|
| Event ingestion | Yes | Yes |
| Meters, features, plans | Yes | Yes |
| Customers, subscriptions | Yes | Yes |
| Entitlement checks | Yes | Yes |
| Billing with Stripe App | Yes (via `apps.baseURL`) | Yes |
| Webhook channels via API | **NO** ("not implemented") | Yes (Svix-backed) |
| Webhook notifications | **Yes** (YAML config only) | Yes (API channels) |
| Svix signature verification | No (plain HTTP) | Yes |

**Key insight**: Webhooks work locally via `config.local.yaml` static configuration. Cloud uses the `POST /api/v1/notification/channels` API (Svix). The catalog sync script handles this automatically.

---

## Step 1: Start Docker Services

```bash
npm run docker:up
```

Verify OpenMeter is healthy:

```bash
curl http://localhost:8888/api/v1/meters
```

Portal UI: `http://localhost:8889`

Or run the verification script:

```powershell
.\scripts\verify-setup.ps1
```

---

## Step 2: Install Stripe App

See [references/apps.md](references/apps.md) for full details on OpenMeter Apps.

```bash
npx tsx scripts/openmeter/openmeter-install-stripe-app.ts
```

This installs Stripe and creates a billing profile.

**Requires**: `STRIPE_SECRET_KEY` in `.env`

Verify: `curl http://localhost:8888/api/v1/apps` — should show Stripe (Sandbox may also be present and is irrelevant).

---

## Step 3: Set Up Ngrok

Required for Stripe App callbacks and Stripe webhooks locally.

1. Install: `choco install ngrok` (Windows) or `brew install ngrok` (macOS)
2. Auth: `ngrok config add-authtoken YOUR_TOKEN`
3. Start: `.\scripts\start-ngrok.ps1` or `ngrok http 3001`
4. Get URL: `curl http://127.0.0.1:4040/api/tunnels`

Then configure (or use the helper script):

```bash
npx tsx scripts/openmeter/set-openmeter-webhook-url.ts
```

Manual config requires updating three places — see [references/REFERENCE.md](references/REFERENCE.md) for the full list.

After config changes: `docker compose restart openmeter`

---

## Step 4: Run Catalog Sync

```bash
npx tsx scripts/openmeter/openmeter-catalog-sync.ts
```

Expected local output includes `⊘ Skipping webhook channel (not supported on self-hosted OpenMeter)` — this is normal.

See [references/REFERENCE.md](references/REFERENCE.md) for common errors and fixes.

---

## Step 5: Start API Server

```bash
npm run dev
```

For ngrok HTTP forwarding, set `API_HTTP_FOR_NGROK=true` in `.env`.

---

## Step 6: Configure Stripe Webhooks

In [Stripe Dashboard](https://dashboard.stripe.com/test/webhooks):

1. Add endpoint: `https://YOUR-NGROK-URL/webhooks/stripe`
2. Events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`
3. Copy signing secret to `.env` as `STRIPE_WEBHOOK_SECRET_DEV=whsec_...`

---

## Webhook Authentication

See [references/webhooks.md](references/webhooks.md) for full details.

| Mode | Environment | Mechanism |
|------|-------------|-----------|
| Svix signatures | Cloud (staging/prod) | `SVIX_WEBHOOK_SECRET` + Svix headers |
| x-webhook-secret | Self-hosted with secret | `OPENMETER_WEBHOOK_SECRET` header check |
| Dev passthrough | Local (no secret set) | Accepts all — self-hosted sends plain HTTP |

---

## Verification

Run the verification script to check all layers:

```powershell
.\scripts\verify-setup.ps1
```

Or manually:

```bash
# OpenMeter running
curl http://localhost:8888/api/v1/meters

# Stripe App installed
curl http://localhost:8888/api/v1/apps

# Webhook endpoint responding
curl -X POST http://127.0.0.1:3001/webhooks/openmeter \
  -H "Content-Type: application/json" \
  -d '{"type":"entitlements.balance.threshold","payload":{"customerId":"test"}}'
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| EADDRINUSE on 3001 | Kill existing process on that port |
| OpenMeter container won't start | Check Docker logs; usually Kafka/PG not ready |
| Catalog sync connection refused | OpenMeter not running — `docker ps` |
| Stripe App missing after cleanup | `npx tsx scripts/openmeter/openmeter-install-stripe-app.ts` |
| Ngrok URL changed | Update `.env`, `config.local.yaml`, Stripe Dashboard; restart OpenMeter |

See [references/REFERENCE.md](references/REFERENCE.md) for the full troubleshooting matrix.
