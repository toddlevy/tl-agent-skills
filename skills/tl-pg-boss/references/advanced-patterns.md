# pg-boss Advanced Patterns

Singleton, throttling, pub/sub, transactional jobs, and API methods.

## Job State Machine

```
┌─────────┐     worker      ┌────────┐     success     ┌───────────┐
│ created │ ──────────────► │ active │ ──────────────► │ completed │
└─────────┘                 └────────┘                 └───────────┘
     │                           │
     │ startAfter                │ error
     ▼                           ▼
┌──────────┐                ┌────────┐     retry      ┌─────────┐
│ deferred │                │ failed │ ─────────────► │  retry  │
└──────────┘                └────────┘                └─────────┘
                                 │
                                 │ retryLimit exhausted
                                 ▼
                            ┌─────────┐
                            │  dead   │
                            │ letter  │
                            └─────────┘
```

---

## Singleton (Prevent Duplicates)

Only one job with same `singletonKey` can be `created` or `active`:

```typescript
await boss.send("sync-user", { userId: "123" }, {
  singletonKey: "user-123",
});

// Second call is ignored while first is pending/active
await boss.send("sync-user", { userId: "123" }, {
  singletonKey: "user-123",
}); // Returns null
```

---

## Rate Limiting / Throttling

Only one job per time window:

```typescript
// Max one job per minute
await boss.send("rate-limited", data, {
  singletonKey: "global-limiter",
  singletonMinutes: 1,
});

// If throttled, queue for next available slot
await boss.send("rate-limited", data, {
  singletonKey: "global-limiter",
  singletonMinutes: 1,
  singletonNextSlot: true,
});
```

---

## Debouncing

Combine singleton with delayed start - only last job runs:

```typescript
await boss.send("process-changes", data, {
  singletonKey: "changes-batch",
  startAfter: 5, // Wait 5 seconds, newer calls replace this
});
```

---

## Pub/Sub (Fan-Out)

Distribute events to multiple independent subscribers:

```typescript
// Publisher
await boss.publish("user-created", { userId: "123" });

// Subscribers (each receives independently)
await boss.subscribe("user-created", async ([job]) => {
  await sendWelcomeEmail(job.data.userId);
});

await boss.subscribe("user-created", async ([job]) => {
  await createDefaultSettings(job.data.userId);
});

await boss.subscribe("user-created", async ([job]) => {
  await trackAnalytics(job.data.userId);
});
```

---

## Transactional Jobs

Create jobs atomically with business data:

```typescript
import { Pool } from "pg";

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const client = await pool.connect();
try {
  await client.query("BEGIN");
  
  // Business logic
  const result = await client.query(
    "INSERT INTO orders (user_id, total) VALUES ($1, $2) RETURNING id",
    [userId, total]
  );
  
  // Job in same transaction
  await boss.send(
    "order-notification", 
    { orderId: result.rows[0].id }, 
    { db: client }
  );
  
  await client.query("COMMIT");
} catch (err) {
  await client.query("ROLLBACK");
  throw err;
} finally {
  client.release();
}
```

---

## Completion Handlers

Listen for job completions (requires `onComplete: true`):

```typescript
const boss = new PgBoss({
  connectionString: process.env.DATABASE_URL,
  onComplete: true,
});

await boss.start();

await boss.onComplete("*", (job) => {
  if (job.data.failed) {
    console.error("Job failed:", job.data.request);
  } else {
    console.log("Job completed:", job.data.response);
  }
});
```

---

## API Methods

### Job Management

```typescript
// Send
const jobId = await boss.send("queue", data, options);

// Get job
const job = await boss.getJobById(jobId);

// Cancel
await boss.cancel(jobId);
await boss.cancel("queue"); // Cancel all in queue

// Complete manually (with fetch)
await boss.complete(jobId);
await boss.complete(jobId, { result: "data" });

// Fail manually
await boss.fail(jobId, new Error("Reason"));

// Resume failed/cancelled
await boss.resume(jobId);
```

### Queue Management

```typescript
// Queue size
const size = await boss.getQueueSize("my-queue");

// Delete queue
await boss.deleteQueue("my-queue");
```

### Schedule Management

```typescript
// Create schedule
await boss.schedule("daily-report", "0 9 * * *", { type: "daily" });

// Remove schedule (no pauseQueue in v10)
await boss.unschedule("daily-report");
```

> **Full schedule patterns**: See `schedule-management.md`

### Manual Fetch

For custom processing loops:

```typescript
const [job] = await boss.fetch("my-queue");
if (job) {
  try {
    await processJob(job);
    await boss.complete(job.id);
  } catch (err) {
    await boss.fail(job.id, err);
  }
}
```

---

## Constructor Options

```typescript
const boss = new PgBoss({
  connectionString: process.env.DATABASE_URL,
  
  // Schema
  schema: "pgboss",
  
  // Behavior
  supervise: true,      // Enable maintenance
  schedule: true,       // Enable cron jobs
  onComplete: false,    // Enable completion events
  
  // Custom connection
  db: { executeSql },   // For ORMs
});
```

---

## Work Options

```typescript
await boss.work(
  "my-queue",
  {
    batchSize: 10,              // Jobs per fetch
    pollingIntervalSeconds: 2,  // How often to poll
    includeMetadata: true,      // Include job metadata
  },
  handler
);
```

### Concurrency

```typescript
// Batch with parallel processing
await boss.work("queue", { batchSize: 5 }, async (jobs) => {
  await Promise.allSettled(jobs.map(processJob));
});

// Multiple workers
await boss.work("queue", handler);
await boss.work("queue", handler);
await boss.work("queue", handler);
```
