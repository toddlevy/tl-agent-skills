# pg-boss for WordPress Developers

Mapping WP-Cron and Action Scheduler concepts to pg-boss for developers transitioning from WordPress to Node.js.

## Concept Mapping

| WP-Cron | Action Scheduler | pg-boss | Notes |
|---------|------------------|---------|-------|
| `wp_schedule_event()` | `as_schedule_recurring_action()` | `boss.schedule()` | Recurring jobs |
| `wp_schedule_single_event()` | `as_schedule_single_action()` | `boss.send()` + `startAfter` | One-time delayed |
| `wp_schedule_single_event(time())` | `as_enqueue_async_action()` | `boss.send()` | Run ASAP |
| `add_action()` | `add_action()` | `boss.work()` | Register handler |
| `do_action()` | — | `boss.send()` | Trigger immediately |
| `wp_next_scheduled()` | `as_has_scheduled_action()` | `singletonKey` | Check/prevent duplicates |
| `wp_unschedule_event()` | `as_unschedule_action()` | `boss.cancel()` | Cancel job |
| `wp_clear_scheduled_hook()` | `as_unschedule_all_actions()` | `boss.cancel(queueName)` | Cancel all |
| — | Action groups | Queue names | Organize by type |
| — | `$unique` param | `singletonKey` | Prevent duplicates |
| — | `$priority` param | `priority` option | Job ordering |
| Cron intervals | Interval (seconds) | Cron expression | Scheduling syntax |
| Page load trigger | WP-Cron + shutdown | Polling (2s default) | How jobs start |
| — | Claim system | SKIP LOCKED | Exactly-once delivery |
| — | `actionscheduler_logs` | `pgboss.job` table | Job history |
| — | Admin UI (Tools) | Dashboard package | Monitoring |

---

## WP-Cron → pg-boss

### Scheduling a Recurring Event

**WordPress (WP-Cron):**
```php
// Register the hook
add_action('my_hourly_event', 'do_hourly_task');

function do_hourly_task() {
    // Task logic
    error_log('Hourly task ran');
}

// Schedule it (usually in plugin activation)
if (!wp_next_scheduled('my_hourly_event')) {
    wp_schedule_event(time(), 'hourly', 'my_hourly_event');
}
```

**pg-boss:**
```typescript
// Register the handler
await boss.work("my-hourly-event", async ([job]) => {
    console.log("Hourly task ran");
});

// Schedule it (idempotent - safe to call on startup)
await boss.schedule("my-hourly-event", "0 * * * *"); // Every hour
```

### One-Time Delayed Event

**WordPress:**
```php
// Schedule to run in 1 hour
wp_schedule_single_event(time() + 3600, 'send_reminder', ['user_id' => 123]);

add_action('send_reminder', function($user_id) {
    wp_mail(get_user_email($user_id), 'Reminder', 'Don\'t forget!');
});
```

**pg-boss:**
```typescript
// Schedule to run in 1 hour
await boss.send("send-reminder", { userId: "123" }, {
    startAfter: 3600, // seconds from now
});

await boss.work("send-reminder", async ([job]) => {
    await sendEmail(job.data.userId, "Reminder", "Don't forget!");
});
```

### Unscheduling

**WordPress:**
```php
$timestamp = wp_next_scheduled('my_hourly_event');
wp_unschedule_event($timestamp, 'my_hourly_event');
```

**pg-boss:**
```typescript
await boss.unschedule("my-hourly-event");
```

---

## Action Scheduler → pg-boss

Action Scheduler is the closer equivalent to pg-boss - both are scalable job queues built on database storage.

### Key Similarities

| Feature | Action Scheduler | pg-boss |
|---------|-----------------|---------|
| Database-backed | Custom tables | `pgboss` schema |
| Batch processing | Yes (25/batch) | Yes (configurable) |
| Retry on failure | Yes | Yes |
| Async loopback | WP-Cron + shutdown | Polling |
| Admin UI | Built-in | Dashboard package |
| Logging | `actionscheduler_logs` | `pgboss.job` table |
| Claim system | Yes | Yes (SKIP LOCKED) |

### Schedule Single Action

**Action Scheduler:**
```php
as_schedule_single_action(
    time() + 3600,           // When
    'process_order',         // Hook
    ['order_id' => 123],     // Args
    'orders'                 // Group
);

add_action('process_order', function($order_id) {
    // Process the order
}, 10, 1);
```

**pg-boss:**
```typescript
await boss.send(
    "process-order",           // Queue (like group)
    { orderId: 123 },          // Data (like args)
    { startAfter: 3600 }       // When
);

await boss.work("process-order", async ([job]) => {
    // Process the order
    await processOrder(job.data.orderId);
});
```

### Schedule Recurring Action

**Action Scheduler:**
```php
as_schedule_recurring_action(
    time(),                  // Start
    3600,                    // Interval (seconds)
    'hourly_sync',           // Hook
    [],                      // Args
    'sync'                   // Group
);
```

**pg-boss:**
```typescript
await boss.schedule(
    "hourly-sync",           // Queue
    "0 * * * *"              // Cron expression (more flexible)
);
```

### Async Action (Run ASAP)

**Action Scheduler:**
```php
as_enqueue_async_action('send_email', ['to' => 'user@example.com']);
```

**pg-boss:**
```typescript
await boss.send("send-email", { to: "user@example.com" });
// Runs on next worker poll (default 2 seconds)
```

### Check If Action Exists

**Action Scheduler:**
```php
if (as_has_scheduled_action('my_action', ['id' => 123], 'my_group')) {
    // Already scheduled
}
```

**pg-boss:**
```typescript
// Use singletonKey to prevent duplicates automatically
await boss.send("my-action", { id: 123 }, {
    singletonKey: "my-action-123",
});
// Returns null if already exists
```

### Cancel Actions

**Action Scheduler:**
```php
as_unschedule_action('process_order', ['order_id' => 123], 'orders');
as_unschedule_all_actions('bulk_process', [], 'bulk');
```

**pg-boss:**
```typescript
await boss.cancel(jobId);           // Cancel specific job
await boss.cancel("process-order"); // Cancel all in queue
```

---

## Unique/Singleton Actions

Both systems support preventing duplicate jobs.

**Action Scheduler:**
```php
as_schedule_single_action(
    time() + 3600,
    'sync_user',
    ['user_id' => 123],
    'sync',
    true  // $unique parameter
);
```

**pg-boss:**
```typescript
await boss.send("sync-user", { userId: 123 }, {
    singletonKey: "sync-user-123",
});
```

---

## Error Handling & Retries

**Action Scheduler:**
```php
add_action('my_action', function() {
    if ($error) {
        throw new Exception('Failed');
        // AS will retry based on settings
    }
});
```

**pg-boss:**
```typescript
await boss.send("my-action", data, {
    retryLimit: 3,
    retryDelay: 60,
    retryBackoff: true, // Exponential backoff
});

await boss.work("my-action", async ([job]) => {
    if (error) {
        throw new Error("Failed");
        // pg-boss will retry automatically
    }
});
```

---

## Admin UI Comparison

### Action Scheduler
- Built into WooCommerce/WordPress
- Tools → Scheduled Actions
- Filter by status, group, hook

### pg-boss
- Separate dashboard package
- `npx pg-boss-dashboard`
- Filter by queue, state, date

---

## Key Differences

| Aspect | WP-Cron / Action Scheduler | pg-boss |
|--------|---------------------------|---------|
| Trigger | Page load (pseudo-cron) | Polling (true background) |
| Language | PHP | Node.js/TypeScript |
| Database | WordPress tables | PostgreSQL |
| Concurrency | Single-threaded PHP | Multiple workers |
| LISTEN/NOTIFY | No | No (polling) |
| Exactly-once | Best effort | Yes (SKIP LOCKED) |

### Why pg-boss is Better for Node.js

1. **True background processing** - Not dependent on page loads
2. **SKIP LOCKED** - Database-level exactly-once guarantee
3. **Multiple workers** - Scale horizontally
4. **TypeScript** - Type-safe job definitions
5. **Simpler** - No WordPress overhead

---

## Migration Checklist

When migrating scheduled tasks from WordPress to Node.js:

- [ ] Map `add_action()` hooks to `boss.work()` handlers
- [ ] Convert `wp_schedule_event()` intervals to cron expressions
- [ ] Replace `as_schedule_single_action()` with `boss.send()`
- [ ] Replace `as_schedule_recurring_action()` with `boss.schedule()`
- [ ] Replace action groups with queue names
- [ ] Update `$unique` to `singletonKey`
- [ ] Set up retry configuration (pg-boss is explicit, AS has defaults)
- [ ] Install dashboard for monitoring

---

## Attribution

WordPress Cron documentation: [developer.wordpress.org/plugins/cron/](https://developer.wordpress.org/plugins/cron/)

Action Scheduler: [actionscheduler.org](https://actionscheduler.org/) - developed by Automattic
