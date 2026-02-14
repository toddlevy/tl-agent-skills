# tl-openmeter-api

Agent skill for working with the OpenMeter REST API. Covers the full OSS API surface: events, meters, features, plans, customers, subscriptions, entitlements, grants, notifications, billing, invoices, apps, addons, and the Stripe marketplace.

## Structure

```
tl-openmeter-api/
├── SKILL.md                         # Main skill (lean, <500 lines)
├── README.md                        # This file
├── references/
│   ├── REFERENCE.md                 # Complete endpoint table by tag
│   ├── billing.md                   # Invoice lifecycle, customer delete, rate cards
│   ├── notifications.md             # Channels, rules, events, testing
│   └── product-catalog.md           # Plans, features, addons: versioning, rate cards
└── assets/
    └── openapi-spec.json            # Full OpenAPI 3.0 spec (source of truth)
```

## Suite: tl-openmeter

| Skill | Purpose |
|-------|---------|
| **tl-openmeter-api** | This skill: REST API reference |
| **tl-openmeter-local-dev** | Local dev setup: Docker, ngrok, Stripe App, webhooks |
| **tl-openmeter-api-mcp-server** | MCP server for calling local OpenMeter from Cursor |

## Author

tl-agent-skills | MIT License
