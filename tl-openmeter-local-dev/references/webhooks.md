# OpenMeter Webhooks Deep Dive

How webhook notifications work across local, staging, and production environments.

## Two Webhook Systems

OpenMeter has **two completely different** mechanisms for sending webhooks depending on the deployment:

| System | Used By | Configuration | Signing |
|--------|---------|--------------|---------|
| **Static YAML** | Self-hosted (Docker) | `config.local.yaml` | None (plain HTTP) |
| **Svix channels** | Cloud (staging/prod) | API: `POST /notification/channels` | Svix signatures |

### Why This Matters

If you try to create a webhook channel via the API on self-hosted OpenMeter, you get:

```
500 Internal Server Error
"failed to create channel: failed to create webhook for channel: not implemented"
```

This is **expected**. The catalog sync script detects the environment and skips this call locally.

## Static YAML Webhooks (Local)

Configured in `infra/openmeter/config.local.yaml`:

```yaml
notification:
  enabled: true
  webhook:
    url: https://YOUR-NGROK-URL/webhooks/openmeter
    eventTypes:
      - entitlement.balance.threshold
      - meter.event
```

- OpenMeter sends plain HTTP POST to the URL
- No signatures, no Svix headers
- URL must be reachable from the Docker container
- Changes require `docker compose restart openmeter`

## Svix Channel Webhooks (Cloud)

Created via API during catalog sync:

```bash
POST /api/v1/notification/channels
{
  "type": "WEBHOOK",
  "name": "My App Webhook",
  "url": "https://your-app.railway.app/webhooks/openmeter"
}
```

- OpenMeter Cloud wraps webhook delivery in Svix
- Every request includes `svix-id`, `svix-timestamp`, `svix-signature` headers
- Signature verification uses `SVIX_WEBHOOK_SECRET` (a `whsec_...` value from OpenMeter Cloud)

## Webhook Handler Authentication Modes

The handler in `server/webhook-routes.ts` auto-detects which mode to use:

### Mode 1: Svix Signature Verification (Cloud)

**Triggers when**: `svix-id` and `svix-signature` headers present AND `SVIX_WEBHOOK_SECRET` configured.

```
Incoming request → Check for svix-id header → Verify with svix library → Accept/Reject
```

Uses the `svix` npm package to verify payload signature.

### Mode 2: x-webhook-secret Header (Self-hosted with secret)

**Triggers when**: No Svix headers AND `OPENMETER_WEBHOOK_SECRET` is set.

```
Incoming request → Compare x-webhook-secret header → Accept/Reject
```

Simple string comparison.

### Mode 3: Dev Passthrough (Local, no secret)

**Triggers when**: No Svix headers AND no webhook secret configured AND `isDevelopment()` is true.

```
Incoming request → Log warning → Accept (no auth)
```

Accepts all requests. Logs a warning that authentication is disabled.

### Mode 4: Rejection (Deployed, no secret)

**Triggers when**: Deployed environment AND no secrets configured.

```
Incoming request → Reject with 500
```

Fails safe — refuses to accept unauthenticated webhooks in non-dev environments.

## Webhook Event Types

| Event Type | Trigger | Payload Fields |
|------------|---------|---------------|
| `entitlement.balance.threshold` | Usage reaches configured threshold % | `customerId`, `featureKey`, `threshold`, `currentUsage`, `limit` |
| `meter.event` | New metering event recorded | Event details |

## Environment Variable Summary

| Variable | Local | Staging | Production |
|----------|-------|---------|------------|
| `OPENMETER_WEBHOOK_SECRET` | Optional (skip = passthrough) | Set | Set |
| `SVIX_WEBHOOK_SECRET` | Not used | `whsec_...` from OpenMeter Cloud | `whsec_...` from OpenMeter Cloud |
| `OPENMETER_WEBHOOK_URL` | ngrok URL | App URL | App URL |

## Testing Webhooks

### Local Dev (no auth)

```bash
curl -X POST http://127.0.0.1:3001/webhooks/openmeter \
  -H "Content-Type: application/json" \
  -d '{"type":"entitlements.balance.threshold","payload":{"customerId":"test-user","featureKey":"api_requests","threshold":95,"currentUsage":950,"limit":1000}}'
```

Expected response: `{"received":true}`

### Via Ngrok

```bash
curl -X POST https://YOUR-NGROK-URL/webhooks/openmeter \
  -H "Content-Type: application/json" \
  -d '{"type":"entitlements.balance.threshold","payload":{"customerId":"test-user"}}'
```

### With x-webhook-secret

```bash
curl -X POST http://127.0.0.1:3001/webhooks/openmeter \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: YOUR_SECRET_VALUE" \
  -d '{"type":"test","payload":{}}'
```

## Startup Logs

The webhook handler logs which auth mode is active at startup:

```
[Webhooks] OpenMeter webhook auth: Svix signature verification (SVIX_WEBHOOK_SECRET set)
```
or
```
[Webhooks] OpenMeter webhook auth: x-webhook-secret header verification
```
or
```
[Webhooks] OpenMeter webhook auth: Development passthrough (no secrets configured)
```

Check these logs to confirm the expected mode is active.
