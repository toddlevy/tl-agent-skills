---
name: tl-pg-boss
description: PostgreSQL-backed job queue with exactly-once delivery using SKIP LOCKED. Use when adding background jobs, task scheduling, cron jobs, or async processing to Node.js apps already using Postgres.
version: 1.0.0
license: MIT
author: Todd Levy <toddlevy@gmail.com>
metadata:
  moment: implement
  surface: [api, db]
  output: patch
  risk: low
  posture: guided
  agentFit: repo-write
  dryRun: partial
---

# tl-pg-boss

PostgreSQL-backed job queue for Node.js with exactly-once delivery, cron scheduling, and transactional safety.

## When to Use

- "Add background jobs to my app"
- "I need a job queue but already use Postgres"
- "Set up cron jobs / scheduled tasks"
- "Process async work with retries"
- User mentions: job queue, background processing, task scheduling, worker

## Outcomes

- **Patch**: pg-boss installed and configured with typed job handlers
- **Artifact**: Job definitions with proper queue setup
- **Decision**: Queue structure, job patterns, monitoring approach

---

## Requirements

| Requirement | Version |
|-------------|---------|
| Node.js | 22.12+ |
| PostgreSQL | 13+ |
| Privilege | CREATE on database |

---

## Installation

```bash
pnpm add pg-boss
```

Auto-creates `pgboss` schema on first `start()`. No manual migrations needed.

---

## Core Concepts

### SKIP LOCKED

PostgreSQL's `SKIP LOCKED` provides exactly-once delivery without distributed transactions.

### Always Call `start()`

**Critical**: Every process must call `start()`, even producers.

```typescript
const boss = new PgBoss(connectionString);
await boss.start(); // Required in EVERY process
```

Even with multiple processes calling `start()`, only one runs supervision.

### One Queue Per Job Type

```typescript
await boss.createQueue("send-email");
await boss.createQueue("process-image");
```

---

## Basic Setup

```typescript
import { PgBoss } from "pg-boss";

const boss = new PgBoss({
  connectionString: process.env.DATABASE_URL,
  schema: "pgboss",
});

boss.on("error", console.error);
await boss.start();
await boss.createQueue("my-queue");
```

---

## Job Patterns

### Send a Job

```typescript
const jobId = await boss.send("my-queue", { userId: "123" });
```

### Send with Options

```typescript
await boss.send("my-queue", payload, {
  retryLimit: 3,
  retryDelay: 60,
  expireInMinutes: 30,
  priority: 1,
});
```

> **Full options**: See `references/send-options.md`

### Delayed Job

```typescript
await boss.send("my-queue", payload, {
  startAfter: new Date(Date.now() + 60000),
});
```

### Cron Scheduling

```typescript
await boss.schedule("daily-report", "0 9 * * *", { type: "daily" });
```

### Unschedule (Remove Cron)

```typescript
await boss.unschedule("daily-report");
```

> **Schedule management**: See `references/schedule-management.md`

---

## Worker Patterns

### Basic Worker

```typescript
await boss.work("my-queue", async ([job]) => {
  console.log(`Processing ${job.id}`);
  // Auto-completes on return, throw to fail
});
```

**Note**: Callback receives an **array** even with `batchSize: 1`.

### Batch Processing

```typescript
await boss.work("bulk-import", { batchSize: 10 }, async (jobs) => {
  for (const job of jobs) {
    await processItem(job.data);
  }
});
```

### Typed Jobs

```typescript
interface EmailJob {
  to: string;
  subject: string;
}

await boss.send<EmailJob>("send-email", { to: "user@example.com", subject: "Hi" });

await boss.work<EmailJob>("send-email", async ([job]) => {
  await sendEmail(job.data.to, job.data.subject);
});
```

> **TypeScript patterns**: See `references/typescript-patterns.md`

---

## Queue Configuration

### Dead Letter Queue

```typescript
await boss.createQueue("my-queue", { deadLetter: "my-queue-dlq" });
await boss.createQueue("my-queue-dlq");
```

### Retention

```typescript
await boss.createQueue("my-queue", { retentionMinutes: 60 * 24 });
```

---

## Fastify Integration

```typescript
import Fastify from "fastify";
import { PgBoss } from "pg-boss";

const fastify = Fastify();
const boss = new PgBoss(process.env.DATABASE_URL);

fastify.decorate("boss", boss);

fastify.addHook("onReady", async () => {
  boss.on("error", fastify.log.error.bind(fastify.log));
  await boss.start();
  await boss.createQueue("my-queue");
  await boss.work("my-queue", handler);
});

fastify.addHook("onClose", async () => {
  await boss.stop({ graceful: true });
});
```

---

## Monitoring

### Dashboard

```bash
pnpm add @pg-boss/dashboard
DATABASE_URL="postgres://..." npx pg-boss-dashboard
```

### Quick SQL

```sql
-- Pending by queue
SELECT name, COUNT(*) FROM pgboss.job WHERE state = 'created' GROUP BY name;

-- Failed jobs
SELECT * FROM pgboss.job WHERE state = 'failed' ORDER BY completedon DESC LIMIT 20;
```

> **Full monitoring**: See `references/monitoring.md`

---

## Sharp Edges

| Gotcha | Solution |
|--------|----------|
| Must call `start()` everywhere | Even producers need it |
| Jobs array in worker | Use `([job])` not `(job)` |
| No LISTEN/NOTIFY | Polling only, set `pollingIntervalSeconds` |
| Schema needs CREATE privilege | Or use CLI: `npx pg-boss migrate --dry-run` |
| Once completed, can't fail | Don't mix `work()` with manual `fail()` |
| No `pauseQueue()` in v10 | Use `unschedule()` + direct SQL |
| Schedules re-register on restart | Code calls `schedule()` on init; unschedule is temporary |

---

## Best Practices

1. **Set expiration** to prevent zombies: `expireInMinutes: 30`
2. **Archive aggressively** with retention policies
3. **Idempotent handlers** using upserts
4. **Graceful shutdown**: `boss.stop({ graceful: true })`

---

## Verification

1. [ ] `boss.start()` completes without error
2. [ ] `boss.createQueue()` succeeds
3. [ ] `boss.send()` returns a job ID
4. [ ] Worker processes the job
5. [ ] Job state changes to `completed`

---

## Reference

- [GitHub](https://github.com/timgit/pg-boss)
- [Documentation](https://timgit.github.io/pg-boss/)
- [Dashboard](https://github.com/timgit/pg-boss/tree/master/packages/dashboard)

### Skill References

- `references/send-options.md` - Full send options
- `references/typescript-patterns.md` - BaseJob, JobManager
- `references/monitoring.md` - Dashboard + SQL queries
- `references/advanced-patterns.md` - Singleton, throttling, pub/sub
- `references/schedule-management.md` - Cron schedules, unschedule, pause patterns
- `references/wordpress-migration.md` - WP-Cron & Action Scheduler mapping

---

## Attribution

This skill synthesizes patterns and insights from:

| Source | Author | Contribution |
|--------|--------|--------------|
| [pg-boss](https://github.com/timgit/pg-boss) | Tim Gilbert (@timgit) | Core library, official docs, Discussion #416 clarifications |
| [TypeScript Deep Dive](https://logsnag.com/blog/deep-dive-into-background-jobs-with-pg-boss-and-typescript) | Shayan (@ImSh4yy) | BaseJob class, JobManager pattern |
| [pg-boss skill](https://playbooks.com/skills/omer-metin/skills-for-antigravity/pg-boss) | Omer Metin | SKIP LOCKED principles, archiving best practices |
| [pg-boss-admin-dashboard](https://github.com/lpetrov/pg-boss-admin-dashboard) | Lyubomir Petrov (@lpetrov) | Alternative dashboard with JMESPath |
