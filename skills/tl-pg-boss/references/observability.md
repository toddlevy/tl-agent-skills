# Observability

> Loaded on-demand by `tl-pg-boss` when adding metrics and alerts to a queue. See `../SKILL.md` for the parent skill.

## Prometheus Metrics

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

## Alerting Rules

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
