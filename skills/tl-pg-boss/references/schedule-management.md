# pg-boss Schedule Management

Managing cron schedules, pausing jobs, and admin patterns.

## Creating Schedules

```typescript
await boss.schedule("daily-report", "0 9 * * *", { type: "daily" });
await boss.schedule("hourly-sync", "0 * * * *");
await boss.schedule("every-15-min", "*/15 * * * *");
```

Schedules are stored in `pgboss.schedule` table.

---

## Removing Schedules

### Using the API

```typescript
await boss.unschedule("daily-report");
```

### Using SQL

```sql
DELETE FROM pgboss.schedule WHERE name = 'daily-report';
```

---

## No Native Pause in v10

**Critical**: pg-boss v10 does **not** have `pauseQueue()` or `resumeQueue()`.

To "pause" scheduled jobs:

1. **Unschedule** - removes the cron trigger
2. **Cancel pending jobs** - clears queued work

```typescript
await boss.unschedule("my-queue");
```

```sql
DELETE FROM pgboss.job 
WHERE state IN ('created', 'retry') 
  AND name = 'my-queue';
```

---

## Schedules Re-Register on Restart

If your initialization code calls `boss.schedule()`:

```typescript
async function registerJobs() {
  await boss.schedule("sync-contacts", "*/15 * * * *");
  await boss.schedule("daily-report", "0 9 * * *");
}
```

These schedules will be **re-created every time the server starts**.

### Implications

- `unschedule()` is temporary - restart brings schedules back
- To permanently disable, comment out or remove `schedule()` calls
- Or use environment-based conditionals:

```typescript
if (env.ENABLE_SCHEDULED_JOBS) {
  await boss.schedule("sync-contacts", "*/15 * * * *");
}
```

---

## Admin API Patterns

Expose schedule management via API for runtime control.

### Fastify Example

```typescript
import { boss, JOB_NAMES } from "./jobs/boss.js";

app.post("/admin/jobs/unschedule-all", async () => {
  const queueNames = Object.values(JOB_NAMES);
  await Promise.all(queueNames.map((name) => boss.unschedule(name)));
  return { success: true, unscheduled: queueNames };
});

app.post("/admin/jobs/:queueName/unschedule", async (request, reply) => {
  const { queueName } = request.params as { queueName: string };
  
  if (!Object.values(JOB_NAMES).includes(queueName)) {
    return reply.badRequest("Invalid queue name");
  }

  await boss.unschedule(queueName);
  return { success: true, queue: queueName, status: "unscheduled" };
});

app.delete("/admin/jobs/cancel-pending", async () => {
  const result = await pool.query(`
    DELETE FROM pgboss.job 
    WHERE state IN ('created', 'retry') 
      AND name = ANY($1)
    RETURNING id
  `, [Object.values(JOB_NAMES)]);
  return { success: true, cancelled: result.rowCount };
});
```

---

## SQL Queries

### List All Schedules

```sql
SELECT name, cron, timezone, created_on, updated_on 
FROM pgboss.schedule 
ORDER BY name;
```

### Delete All Schedules

```sql
DELETE FROM pgboss.schedule;
```

### Delete Specific Schedule

```sql
DELETE FROM pgboss.schedule WHERE name = 'my-queue';
```

### Cancel All Pending Jobs

```sql
DELETE FROM pgboss.job 
WHERE state IN ('created', 'retry');
```

### Cancel Pending Jobs for Queue

```sql
DELETE FROM pgboss.job 
WHERE state IN ('created', 'retry') 
  AND name = 'my-queue';
```

---

## Complete "Pause All" Pattern

When you need to stop all scheduled work:

```typescript
async function pauseAllJobs(boss: PgBoss, pool: pg.Pool, jobNames: string[]) {
  await Promise.all(jobNames.map((name) => boss.unschedule(name)));
  
  await pool.query(`
    DELETE FROM pgboss.job 
    WHERE state IN ('created', 'retry') 
      AND name = ANY($1)
  `, [jobNames]);
  
  return { unscheduled: jobNames.length };
}
```

To resume, restart the server (schedules re-register from code).

---

## Testing Without Schedules

For local development or testing, disable schedules:

```typescript
const boss = new PgBoss({
  connectionString: process.env.DATABASE_URL,
  schedule: process.env.NODE_ENV !== "test",
});
```

Or skip schedule registration:

```typescript
if (process.env.DISABLE_CRON !== "true") {
  await boss.schedule("sync-contacts", "*/15 * * * *");
}
```
