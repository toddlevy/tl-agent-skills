---
name: tl-pg-boss
description: PostgreSQL-backed job queue with exactly-once delivery using SKIP LOCKED. Use when adding background jobs, task scheduling, cron jobs, or async processing to Node.js apps already using Postgres.
version: "1.1"
license: MIT
quilted:
  - source: triggerdotdev/skills/trigger-tasks
    weight: 0.15
    description: Async workflow patterns, retry strategies, cron scheduling
  - source: omer-metin/skills-for-antigravity/pg-boss
    weight: 0.10
    description: SKIP LOCKED principles, archiving patterns
metadata:
  moment: implement
  surface:
    - api
    - db
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

### When to Consider Alternatives

For **managed background jobs with dashboard UI**, consider [Trigger.dev](https://trigger.dev) instead. pg-boss is best when:
- You want self-hosted, PostgreSQL-native job queues
- You already have Postgres and don't want external dependencies
- You need transactional job enqueuing (same transaction as your data writes)
- Cost matters (pg-boss is free, managed services charge per job)

Trigger.dev is better when:
- You need a polished dashboard out of the box
- You want managed infrastructure with auto-scaling
- Your team prefers a hosted SaaS experience
- You need complex workflows with visual orchestration

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

## Observability

### Prometheus Metrics

Expose queue metrics for monitoring:

```typescript
import { register, Gauge, Counter } from 'prom-client';

const queueSize = new Gauge({
  name: 'pgboss_queue_size',
  help: 'Number of jobs in queue',
  labelNames: ['queue', 'state'],
});

const jobsProcessed = new Counter({
  name: 'pgboss_jobs_processed_total',
  help: 'Total jobs processed',
  labelNames: ['queue', 'status'],
});

async function collectMetrics(boss: PgBoss) {
  const queues = await boss.getQueues();
  for (const queue of queues) {
    const stats = await boss.getQueueSize(queue.name);
    queueSize.set({ queue: queue.name, state: 'active' }, stats.active);
    queueSize.set({ queue: queue.name, state: 'created' }, stats.created);
  }
}

boss.on('job', (job) => jobsProcessed.inc({ queue: job.name, status: 'completed' }));
boss.on('fail', (job) => jobsProcessed.inc({ queue: job.name, status: 'failed' }));
```

### Alerting Rules

```yaml
groups:
  - name: pgboss
    rules:
      - alert: JobQueueBacklog
        expr: pgboss_queue_size{state="created"} > 1000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Job queue {{ $labels.queue }} has backlog"

      - alert: JobFailureRate
        expr: rate(pgboss_jobs_processed_total{status="failed"}[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
```

---

## Testing Patterns

### Unit Testing Job Handlers

```typescript
describe('EmailJob', () => {
  it('sends email with correct parameters', async () => {
    const sendEmail = vi.fn();
    const handler = createEmailHandler({ sendEmail });
    
    await handler({ to: 'test@example.com', subject: 'Test' });
    
    expect(sendEmail).toHaveBeenCalledWith({
      to: 'test@example.com',
      subject: 'Test',
    });
  });
});
```

### Integration Testing with Real Database

```typescript
import { PgBoss } from 'pg-boss';

describe('Job Queue Integration', () => {
  let boss: PgBoss;
  
  beforeAll(async () => {
    boss = new PgBoss(process.env.TEST_DATABASE_URL);
    await boss.start();
    await boss.createQueue('test-queue');
  });
  
  afterAll(async () => {
    await boss.stop();
  });
  
  it('processes job end-to-end', async () => {
    const results: any[] = [];
    await boss.work('test-queue', async (job) => {
      results.push(job.data);
    });
    
    await boss.send('test-queue', { id: 1 });
    await new Promise((r) => setTimeout(r, 1000));
    
    expect(results).toEqual([{ id: 1 }]);
  });
});
```

### Mocking pg-boss

```typescript
const mockBoss = {
  start: vi.fn().mockResolvedValue(undefined),
  send: vi.fn().mockResolvedValue('job-id'),
  work: vi.fn().mockResolvedValue(undefined),
  createQueue: vi.fn().mockResolvedValue(undefined),
};

vi.mock('pg-boss', () => ({
  PgBoss: vi.fn(() => mockBoss),
}));
```

---

## Kubernetes Deployment

### Worker Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: job-worker
spec:
  replicas: 3
  selector:
    matchLabels:
      app: job-worker
  template:
    metadata:
      labels:
        app: job-worker
    spec:
      terminationGracePeriodSeconds: 60
      containers:
        - name: worker
          image: app:latest
          command: ["node", "dist/worker.js"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: url
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 10"]
```

### Graceful Shutdown Handler

```typescript
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, stopping gracefully...');
  await boss.stop({ graceful: true, timeout: 30000 });
  process.exit(0);
});
```

---

## Verification

1. [ ] `boss.start()` completes without error
2. [ ] `boss.createQueue()` succeeds
3. [ ] `boss.send()` returns a job ID
4. [ ] Worker processes the job
5. [ ] Job state changes to `completed`

---

## References

### Quilted Skills

- [triggerdotdev/skills/trigger-tasks](https://skills.sh/triggerdotdev/skills/trigger-tasks) — Workflow patterns
- [omer-metin/skills-for-antigravity/pg-boss](https://playbooks.com/skills/omer-metin/skills-for-antigravity/pg-boss) — SKIP LOCKED principles

### First-Party Documentation

- [pg-boss GitHub](https://github.com/timgit/pg-boss) — Official repository
- [pg-boss API Docs](https://timgit.github.io/pg-boss/) — API reference
- [pg-boss Dashboard](https://github.com/timgit/pg-boss/tree/master/packages/dashboard) — Web UI

### PostgreSQL Resources

- [PostgreSQL SKIP LOCKED](https://www.postgresql.org/docs/current/sql-select.html#SQL-FOR-UPDATE-SHARE) — Locking semantics
- [PostgreSQL Advisory Locks](https://www.postgresql.org/docs/current/explicit-locking.html#ADVISORY-LOCKS) — Application-level locks
- [Connection Pooling with PgBouncer](https://www.pgbouncer.org/) — Connection management

### Alternative Solutions

- [Graphile Worker](https://worker.graphile.org/) — PostgreSQL queue alternative
- [Trigger.dev](https://trigger.dev/docs/) — Managed background jobs
- [BullMQ](https://docs.bullmq.io/) — Redis-based alternative

### Skill References

- `references/send-options.md` — Full send options
- `references/typescript-patterns.md` — BaseJob, JobManager
- `references/monitoring.md` — Dashboard + SQL queries
- `references/advanced-patterns.md` — Singleton, throttling, pub/sub
- `references/schedule-management.md` — Cron schedules, unschedule, pause patterns
- `references/wordpress-migration.md` — WP-Cron & Action Scheduler mapping

---

## Attribution

| Source | Author | Contribution |
|--------|--------|--------------|
| [pg-boss](https://github.com/timgit/pg-boss) | Tim Gilbert (@timgit) | Core library, official docs |
| [TypeScript Deep Dive](https://logsnag.com/blog/deep-dive-into-background-jobs-with-pg-boss-and-typescript) | Shayan (@ImSh4yy) | BaseJob class, JobManager pattern |
| [pg-boss-admin-dashboard](https://github.com/lpetrov/pg-boss-admin-dashboard) | Lyubomir Petrov (@lpetrov) | Alternative dashboard with JMESPath |
