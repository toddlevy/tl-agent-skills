# Subscriptions Deep Dive

> Loaded on-demand by `tl-openmeter-api` when modifying subscriptions, applying customizations, or migrating across plan versions. See `../SKILL.md` for the parent skill.

## PATCH Subscription Customizations

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

## stretch_phase Operation

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

## Subscription State Limitations

| Status | Allowed Operations |
|--------|-------------------|
| `active` | PATCH, cancel, change, migrate |
| `inactive` | None (must create new subscription) |
| `canceled` | restore, then other operations |

**Key insight:** Inactive subscriptions (e.g., ended trials) cannot be modified. To "reactivate" an expired trial, create a new subscription on the current plan version.

## Legacy Subscription Migration Pattern

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
