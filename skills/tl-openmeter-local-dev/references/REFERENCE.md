# OpenMeter Local Dev — Reference

Quick-lookup tables for environment variables, Docker services, config files, and scripts.

## Environment Variables by Environment

| Variable | Local | Staging | Production | Purpose |
|----------|-------|---------|------------|---------|
| `OPENMETER_URL` | `http://localhost:8888` | Railway URL | Railway URL | OpenMeter API base |
| `OPENMETER_API_KEY` | (optional, often blank) | Required | Required | API auth token |
| `OPENMETER_WEBHOOK_URL` | ngrok URL or `http://host.docker.internal:3001/webhooks/openmeter` | App URL | App URL | Where OpenMeter sends notifications |
| `OPENMETER_WEBHOOK_SECRET` | (optional) | Set | Set | `x-webhook-secret` header verification |
| `SVIX_WEBHOOK_SECRET` | (not used) | `whsec_...` | `whsec_...` | Svix signature verification (Cloud only) |
| `API_HTTP_FOR_NGROK` | `true` | (not set) | (not set) | HTTP mode for ngrok forwarding |
| `STRIPE_SECRET_KEY` | `sk_test_...` | `sk_test_...` | `sk_live_...` | Stripe API key (for Stripe App install) |
| `STRIPE_WEBHOOK_SECRET_DEV` | `whsec_...` | — | — | Stripe webhook signing secret (local) |

## Docker Services

| Service | Port | Purpose |
|---------|------|---------|
| `openmeter` | 8888 (API), 8889 (Portal) | OpenMeter server |
| `postgres-openmeter` | 5433 | OpenMeter's PostgreSQL |
| `kafka` | 9092 | Event streaming |
| `clickhouse` | 9000 | Analytics storage |
| `redis` | 6379 | Rate limiting, caching |
| `mailpit` | 8025 (UI), 1025 (SMTP) | Email testing |
| `postgres` | 5432 | App PostgreSQL |

## Config Files

| File | Purpose | When to Edit |
|------|---------|--------------|
| `infra/openmeter/config.local.yaml` | OpenMeter Docker config | Ngrok URL changes, adding event types |
| `.env` | App environment variables | Any env var change |
| `.env.example` | Template for new developers | Adding new env vars |
| `.env.staging` | Staging overrides | Staging-specific config |
| `docker-compose.yml` | Docker service definitions | Adding/modifying services |
| `ngrok.yml` | Ngrok configuration | Tunneling config |

## Ngrok URL Update Checklist

When ngrok URL changes (free plan gives new URL each restart):

1. `.env` → `OPENMETER_WEBHOOK_URL`
2. `infra/openmeter/config.local.yaml` → `apps.baseURL`
3. `infra/openmeter/config.local.yaml` → `notification.webhook.url`
4. Stripe Dashboard → webhook endpoint URL
5. Restart OpenMeter: `docker compose restart openmeter`

Or use the helper: `npx tsx scripts/openmeter/set-openmeter-webhook-url.ts`

## Key Config Sections in config.local.yaml

```yaml
# apps.baseURL: Where Stripe App callbacks go (must be public)
apps:
  baseURL: https://YOUR-NGROK-URL

# notification.webhook: Where OpenMeter sends threshold alerts
notification:
  enabled: true
  webhook:
    url: https://YOUR-NGROK-URL/webhooks/openmeter
    eventTypes:
      - entitlement.balance.threshold
      - meter.event
```

Both `apps.baseURL` and `notification.webhook.url` must be reachable from Docker:
- **With ngrok**: Use the ngrok public URL
- **Without ngrok**: Use `http://host.docker.internal:3001` (Docker's host access)

## Scripts Reference

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `scripts/openmeter/openmeter-catalog-sync.ts` | Sync meters, features, plans | After Docker up, after plan changes |
| `scripts/openmeter/openmeter-install-stripe-app.ts` | Install Stripe app, remove Sandbox | First-time setup, after `--openmeter-all` cleanup |
| `scripts/openmeter/set-openmeter-webhook-url.ts` | Update webhook URL from ngrok | After ngrok restart |
| `scripts/start-ngrok.ps1` | Start ngrok tunnel | Before starting dev with Stripe |

## Catalog Sync Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `"only a single draft version is allowed"` | Plan draft already exists | Script handles this — skips existing plans |
| `"only Plans in [draft scheduled] can be published"` | Plan already published | Script handles this — logs "already active" |
| `500 on POST /notification/channels` | Self-hosted doesn't implement this | Script skips for local (uses YAML config) |
| `OPENMETER_URL required` | Missing env var | Add `OPENMETER_URL=http://localhost:8888` to `.env` |
| `Connection refused` | OpenMeter not running | Check `docker ps`, restart if needed |

## Full Troubleshooting Matrix

| Symptom | Check | Fix |
|---------|-------|-----|
| `500` on webhook channel creation | Expected locally | Script auto-skips; use YAML config |
| Stripe App install fails | `curl /api/v1/apps` — Sandbox still there? | Remove Sandbox first |
| Webhook not received locally | Is ngrok running? `http://127.0.0.1:4040` | Start ngrok, update URLs |
| `host.docker.internal` not resolving | Docker Desktop DNS issue | Use ngrok instead, or add `extra_hosts` to Docker |
| Events not metering | `curl /api/v1/meters/{slug}/query?subject=...` | Event `type` must match meter `eventType` |
| Customer has no entitlements | `curl /api/v1/customers/{id}/entitlements` | Ensure active subscription exists |
| Billing profile missing | `curl /api/v1/billing/profiles` | Reinstall Stripe app with `createBillingProfile: true` |
| EADDRINUSE on 3001 | Another process on port | `netstat -ano | findstr :3001` then `taskkill /PID <pid> /F` |
| OpenMeter container crash | Check logs | `docker logs <openmeter-container-name> 2>&1 | tail -30` |
