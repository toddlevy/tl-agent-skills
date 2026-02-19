# OpenMeter Notifications API

Notifications provide automated triggers when entitlement thresholds are reached. The system is built around three concepts: **channels**, **rules**, and **events**.

---

## Architecture

```
Rule (threshold condition) → Channel (delivery target) → Event (fired instance)
```

- **Channel**: Where notifications are sent (webhook URL).
- **Rule**: Defines the condition (e.g., 75%, 100%, 150% of feature usage) and which channels to notify.
- **Event**: A single fired notification instance, with status and delivery tracking.

---

## Channels

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/notification/channels` |
| Create | POST | `/api/v1/notification/channels` |
| Get | GET | `/api/v1/notification/channels/{channelId}` |
| Update | PUT | `/api/v1/notification/channels/{channelId}` |
| Delete | DELETE | `/api/v1/notification/channels/{channelId}` |

### List Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `includeDeleted` | boolean | Include deleted channels |
| `includeDisabled` | boolean | Include disabled channels |
| `page` | int | Page number |
| `pageSize` | int | Items per page |

### Create Channel Example

```json
{
  "type": "WEBHOOK",
  "name": "Usage Alerts",
  "webhook": {
    "url": "https://my-app.example.com/webhooks/openmeter",
    "customHeaders": {
      "x-webhook-secret": "my-secret-value"
    },
    "signingKey": "whsec_..."
  }
}
```

### Self-Hosted vs Cloud

| Feature | Self-Hosted | Cloud |
|---------|------------|-------|
| Channel creation via API | **500 error** — not implemented | Works (backed by Svix) |
| Channel configuration | `config.local.yaml` only | API + Dashboard |
| Webhook delivery | OpenMeter sends directly | Svix handles delivery, retries |
| Signing | `customHeaders` or none | Svix signatures (`svix-id`, `svix-timestamp`, `svix-signature`) |

**Self-hosted YAML config:**

```yaml
notification:
  webhook:
    eventTypeRegistrationTimeout: 30s
    skipEventTypeRegistration: true
    channels:
      - id: "my-channel-01"
        type: WEBHOOK
        name: "Local Webhook"
        webhook:
          url: "http://host.docker.internal:3000/webhooks/openmeter"
          customHeaders:
            x-webhook-secret: "my-secret"
```

---

## Rules

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/notification/rules` |
| Create | POST | `/api/v1/notification/rules` |
| Get | GET | `/api/v1/notification/rules/{ruleId}` |
| Update | PUT | `/api/v1/notification/rules/{ruleId}` |
| Delete | DELETE | `/api/v1/notification/rules/{ruleId}` |
| Test | POST | `/api/v1/notification/rules/{ruleId}/test` |

### List Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `includeDeleted` | boolean | Include deleted rules |
| `includeDisabled` | boolean | Include disabled rules |
| `feature` | string | Filter by feature ID |
| `channel` | string | Filter by channel ID |

### Create Rule Example

```json
{
  "type": "entitlements.balance.threshold",
  "name": "API Usage 75%",
  "channels": ["channel-id-01"],
  "config": {
    "features": ["feature-id-01"],
    "thresholds": [
      { "value": 75, "type": "PERCENT" },
      { "value": 100, "type": "PERCENT" },
      { "value": 150, "type": "PERCENT" }
    ]
  }
}
```

### Rule Types

| Type | Description |
|------|-------------|
| `entitlements.balance.threshold` | Fires when entitlement usage reaches specified percentage thresholds |

### Test Rule

Send a test notification event through the rule:

```
POST /api/v1/notification/rules/{ruleId}/test
```

No request body required. Returns a test notification event.

---

## Events

| Operation | Method | Path |
|-----------|--------|------|
| List | GET | `/api/v1/notification/events` |
| Get | GET | `/api/v1/notification/events/{eventId}` |
| Resend | POST | `/api/v1/notification/events/{eventId}/resend` |

### List Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `feature` | string | Filter by feature ID |
| `subject` | string | Filter by subject |
| `from` | date-time | Events after timestamp |
| `to` | date-time | Events before timestamp |
| `deduplicationState` | string | Filter by dedup state |
| `rule` | string[] | Filter by rule ID |
| `channel` | string[] | Filter by channel ID |

### Event Response

```json
{
  "id": "01ABC...",
  "type": "entitlements.balance.threshold",
  "createdAt": "2026-02-14T12:00:00Z",
  "rule": {
    "id": "01XYZ..."
  },
  "deliveryStatus": [
    {
      "channel": "01DEF...",
      "state": "SUCCESS",
      "updatedAt": "2026-02-14T12:00:01Z"
    }
  ],
  "payload": {
    "id": "01ABC...",
    "type": "entitlements.balance.threshold",
    "timestamp": "2026-02-14T12:00:00Z",
    "subject": {
      "id": "customer-id"
    },
    "feature": {
      "id": "feature-id",
      "key": "api_requests"
    },
    "entitlement": {
      "id": "entitlement-id"
    },
    "threshold": {
      "value": 75,
      "type": "PERCENT"
    },
    "value": {
      "balance": 250,
      "usage": 750,
      "overage": 0
    }
  }
}
```

---

## Webhook Payload

When a notification rule fires, OpenMeter sends a POST to each configured channel URL:

```json
{
  "id": "01ABC...",
  "type": "entitlements.balance.threshold",
  "timestamp": "2026-02-14T12:00:00Z",
  "subject": {
    "id": "customer-key"
  },
  "feature": {
    "id": "feature-id",
    "key": "api_requests"
  },
  "entitlement": {
    "id": "entitlement-id"
  },
  "threshold": {
    "value": 100,
    "type": "PERCENT"
  },
  "value": {
    "balance": 0,
    "usage": 1000,
    "overage": 0
  }
}
```

### Webhook Verification

**Cloud (Svix):**

Headers include `svix-id`, `svix-timestamp`, `svix-signature`. Verify using the [Svix verification library](https://github.com/svix/svix-webhooks).

**Self-hosted:**

If `customHeaders` are configured (e.g., `x-webhook-secret`), check the header value matches your expected secret. No cryptographic signing is available for self-hosted.

### Testing Webhooks

```bash
# Test a rule fires correctly
curl -X POST http://localhost:8888/api/v1/notification/rules/{ruleId}/test

# Resend a failed event
curl -X POST http://localhost:8888/api/v1/notification/events/{eventId}/resend
```
