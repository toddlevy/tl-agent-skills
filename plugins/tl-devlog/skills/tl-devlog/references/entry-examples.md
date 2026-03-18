# Devlog Entry Examples

Real-world examples for each category to guide entry writing.

---

## Architecture

Technical design decisions, data models, stack choices, API design.

```markdown
## [2026-03-10] Adopted event sourcing for audit subsystem

**Category:** `architecture`
**Tags:** `audit`, `events`, `compliance`, `postgresql`

### Summary
Chose event sourcing pattern over traditional logging for the audit trail, enabling full state reconstruction and compliance reporting.

### Detail
- **Decision**: Use event sourcing with PostgreSQL JSONB storage
- **Why**: Compliance requires ability to reconstruct exact state at any point in time
- **Rejected alternatives**:
  - Simple append-only logs — can't replay or reconstruct state
  - CDC (Change Data Capture) — adds operational complexity, still lossy
  - Audit tables with triggers — tight coupling, migration headaches
- **Trade-offs accepted**: Higher storage cost, eventual consistency for projections
- **Implementation**: Events table + projection workers + snapshot optimization

### Related
- [2026-03-08] PostgreSQL selection for primary database
- PR #142: Event store implementation
```

---

## Milestone

Completed work, version releases, phase transitions.

```markdown
## [2026-03-10] Shipped v2.0 billing system

**Category:** `milestone`
**Tags:** `billing`, `stripe`, `release`, `v2.0`

### Summary
Billing v2.0 is live in production. All customers migrated from legacy system.

### Detail
- **Scope**: Complete Stripe integration with usage-based billing
- **Key features**:
  - Metered billing with OpenMeter
  - Self-service subscription management
  - Invoice generation and PDF export
  - Dunning automation for failed payments
- **Migration**: 847 customers migrated, zero payment disruptions
- **Metrics**: Checkout conversion up 12% vs v1

### Related
- [2026-02-15] Billing v2 architecture decision
- [2026-03-01] Stripe sandbox testing complete
- Epic: BILL-100
```

---

## Incident

Production issues, root cause, resolution.

```markdown
## [2026-03-10] Resolved 45-minute API outage

**Category:** `incident`
**Tags:** `outage`, `database`, `connection-pool`, `postmortem`

### Summary
Production API returned 503s for 45 minutes due to connection pool exhaustion. Root cause: long-running analytics query blocked connections.

### Detail
- **Timeline**:
  - 14:32 UTC — Alerts fire for elevated 5xx rates
  - 14:35 UTC — Identified: all pg connections in "idle in transaction"
  - 14:45 UTC — Found: analytics cron job running 3-hour query
  - 14:50 UTC — Killed query, connections recovered
  - 15:17 UTC — All services healthy
- **Root cause**: Analytics query without statement timeout ran against production replica, but connection pool was shared
- **Fix applied**: Killed runaway query
- **Prevention**:
  - [ ] Separate connection pool for analytics
  - [ ] Statement timeout of 5 minutes on all queries
  - [ ] Move analytics to dedicated read replica

### Related
- Incident ticket: INC-2026-0310-001
- [2026-03-11] Implemented connection pool separation
```

---

## Bug

Non-production bugs, debugging sessions.

```markdown
## [2026-03-10] Fixed race condition in WebSocket reconnection

**Category:** `bug`
**Tags:** `websocket`, `race-condition`, `frontend`, `reconnect`

### Summary
Users reported duplicate messages after network interruptions. Caused by overlapping reconnection attempts creating multiple socket instances.

### Detail
- **Symptom**: Messages appeared 2-4x after wifi toggle or laptop wake
- **Investigation**:
  - Reproduced by throttling network in DevTools
  - Found: `reconnect()` called before `disconnect` event processed
  - Result: Multiple active WebSocket instances, each receiving messages
- **Fix**: Added connection state machine with mutex lock
  - States: `disconnected` → `connecting` → `connected` → `disconnecting`
  - Reconnect blocked unless in `disconnected` state
- **Verification**: Stress tested with 100 rapid reconnects, no duplicates

### Related
- Issue #789: Duplicate notifications
- PR #801: WebSocket state machine
```

---

## Ops

Infrastructure, deployment, monitoring changes.

```markdown
## [2026-03-10] Migrated CI/CD from CircleCI to GitHub Actions

**Category:** `ops`
**Tags:** `ci-cd`, `github-actions`, `migration`, `devops`

### Summary
Completed migration from CircleCI to GitHub Actions. Build times reduced 40%, monthly cost reduced $800.

### Detail
- **Why migrate**:
  - CircleCI credit model expensive for our build patterns
  - GitHub Actions native integration with repo
  - Better caching for pnpm monorepo
- **Migration scope**:
  - 12 workflows converted
  - Matrix builds for Node 18/20/22
  - Docker layer caching implemented
  - Secrets migrated to GitHub environment secrets
- **Results**:
  - Average build: 8m → 4.5m (44% faster)
  - Monthly cost: $1,200 → $400 (67% reduction)
  - Developer experience: unified in GitHub UI

### Related
- [2026-02-28] CI/CD evaluation decision
- PR #156: GitHub Actions workflows
```

---

## Design

UX decisions, UI patterns, feature specifications.

```markdown
## [2026-03-10] Adopted skeleton loading pattern for dashboard

**Category:** `design`
**Tags:** `ux`, `loading`, `skeleton`, `perceived-performance`

### Summary
Replaced spinner loading states with skeleton screens across dashboard components. User testing showed 23% improvement in perceived speed.

### Detail
- **Problem**: Users perceived dashboard as slow despite fast API responses
- **Hypothesis**: Spinner → content flash feels jarring; skeleton → content feels continuous
- **Implementation**:
  - Created `<Skeleton>` component matching each widget shape
  - Shimmer animation on gray rectangles
  - Graceful reveal with 200ms fade transition
- **User testing results**:
  - Perceived load time: 2.1s → 1.6s (23% improvement)
  - "Smoothness" rating: 3.2 → 4.1 (out of 5)
  - Actual load time unchanged (1.2s)
- **Applied to**: Dashboard, settings, user profile, analytics pages

### Related
- Figma: Skeleton component library
- PR #445: Skeleton implementation
```

---

## Strategy

Business decisions, positioning, go-to-market.

```markdown
## [2026-03-10] Pivoted from self-serve to sales-led growth

**Category:** `strategy`
**Tags:** `gtm`, `sales`, `pivot`, `enterprise`

### Summary
Shifting from self-serve freemium to sales-led enterprise motion. Self-serve will remain but deprioritized.

### Detail
- **Trigger**: Analysis showed 80% of revenue from 12% of customers (enterprise)
- **Self-serve challenges**:
  - High support cost per dollar revenue
  - 2% conversion, 4% monthly churn
  - Features needed for enterprise don't help self-serve
- **New strategy**:
  - Enterprise sales team (hiring 2 AEs)
  - Self-serve becomes "try before you buy" funnel
  - Pricing restructured: $0 → $99 → Custom (was $0 → $29 → $99 → $299)
  - Product focus shifts to admin/compliance features
- **Risks**: Alienate small customer base, longer sales cycles

### Related
- [2026-02-20] Customer segmentation analysis
- Board deck: March 2026 strategy update
```

---

## Takeaway

Key insights, lessons learned, context for future.

```markdown
## [2026-03-10] Bulk imports need progress indicators

**Category:** `takeaway`
**Tags:** `ux`, `bulk-import`, `feedback`, `lesson-learned`

### Summary
Users abandon bulk imports without progress feedback. Even inaccurate progress is better than none.

### Detail
- **Context**: Built CSV import for 10k+ row uploads
- **Initial design**: Spinner with "Processing..." message
- **User behavior observed**:
  - 40% refreshed page (killing the import)
  - Support tickets asking "is it working?"
  - Users preferred slower UI with progress bar
- **Lesson**: Uncertainty is worse than slowness
- **Applied fix**:
  - Chunked processing with progress callback
  - Progress bar showing rows processed / total
  - "Estimated time remaining" even if approximate
  - Result: Abandonment dropped from 40% to 3%

### Related
- Issue #234: Import timeout reports
- Applies to: Export feature, report generation, any async batch job
```

---

## Writing Tips

### Good Entries

- **Specific**: Include versions, file paths, numbers, names
- **Why-focused**: The rationale outlasts the decision
- **Searchable**: Tags that future-you would search for
- **Connected**: Link related entries to build context

### Common Mistakes

| Mistake | Fix |
|---------|-----|
| "Fixed the bug" | "Fixed race condition in WebSocket reconnection (issue #789)" |
| "Decided on approach" | "Chose event sourcing over CDC for audit compliance" |
| "Updated config" | "Increased connection pool from 20→50 after outage analysis" |
| No tags | Add 3-5 searchable keywords |
| No "why" | Always explain the reasoning, not just the outcome |
