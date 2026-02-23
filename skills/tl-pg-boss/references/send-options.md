# pg-boss Send Options

Full options when sending jobs with `boss.send()`.

## Basic Usage

```typescript
await boss.send("queue-name", payload, options);
```

## Options Reference

### Priority

```typescript
priority: 1  // Higher = processed first (default: 0)
```

### Retry Configuration

```typescript
retryLimit: 3,        // Max retry attempts (default: 2)
retryDelay: 60,       // Seconds between retries
retryBackoff: true,   // Enable exponential backoff
```

### Expiration (Job Timeout)

Job moves to `expired` state if still active after this time:

```typescript
expireInSeconds: 300,
expireInMinutes: 5,
expireInHours: 1,
```

### Retention

How long to keep completed jobs before archiving:

```typescript
retentionSeconds: 3600,
retentionMinutes: 60,
retentionHours: 24,
retentionDays: 7,
```

### Deferred Execution

```typescript
// Date object
startAfter: new Date("2026-03-01T09:00:00Z"),

// Seconds from now
startAfter: 3600,

// ISO string
startAfter: "2026-03-01T09:00:00Z",
```

### Singleton (Prevent Duplicates)

Only one job with same key can be `created` or `active`:

```typescript
singletonKey: "user-123",
useSingletonQueue: true,  // Only one can be queued at all
```

### Throttling

Rate limit job creation:

```typescript
singletonKey: "rate-limiter",
singletonSeconds: 60,      // One job per minute
singletonMinutes: 5,       // One job per 5 minutes
singletonHours: 1,         // One job per hour
singletonNextSlot: true,   // Queue for next slot if throttled
```

### Dead Letter Queue

```typescript
deadLetter: "my-queue-dlq",  // Failed jobs go here after retries exhausted
```

## Full Example

```typescript
await boss.send("critical-job", payload, {
  priority: 10,
  retryLimit: 5,
  retryDelay: 30,
  retryBackoff: true,
  expireInMinutes: 15,
  retentionDays: 7,
  singletonKey: `job-${userId}`,
  deadLetter: "critical-job-dlq",
});
```
