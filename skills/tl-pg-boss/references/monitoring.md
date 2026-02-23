# pg-boss Monitoring

Dashboard setup and SQL queries for monitoring jobs.

## Dashboards

### Official Dashboard (`@pg-boss/dashboard`)

```bash
pnpm add @pg-boss/dashboard
DATABASE_URL="postgres://..." npx pg-boss-dashboard
```

Open http://localhost:3000

**With auth:**
```bash
PGBOSS_DASHBOARD_AUTH_USERNAME=admin \
PGBOSS_DASHBOARD_AUTH_PASSWORD=secret \
DATABASE_URL="postgres://..." npx pg-boss-dashboard
```

**Multi-database:**
```bash
DATABASE_URL="Production=postgres://prod/db|Staging=postgres://stage/db" \
npx pg-boss-dashboard
```

### Alternative: pg-boss-admin-dashboard

Third-party dashboard with charts and advanced filtering.

```bash
npm install -g pg-boss-admin-dashboard
PGBOSS_DATABASE_URL="postgres://..." pg-boss-admin-dashboard
```

Open http://localhost:8671

**Features:**
- Chart.js time-series visualization
- JMESPath queries: `jq:data.userId == "123"`
- Dark theme
- Auto-refresh

**Trade-offs:**
- No built-in auth (DIY middleware)
- No multi-database support

Source: [lpetrov/pg-boss-admin-dashboard](https://github.com/lpetrov/pg-boss-admin-dashboard)

---

## SQL Queries

Jobs are rows - query directly for custom monitoring.

### Queue Sizes

```sql
SELECT 
  name,
  SUM(CASE WHEN state = 'created' THEN 1 ELSE 0 END) as pending,
  SUM(CASE WHEN state = 'active' THEN 1 ELSE 0 END) as active,
  SUM(CASE WHEN state = 'completed' THEN 1 ELSE 0 END) as completed,
  SUM(CASE WHEN state = 'failed' THEN 1 ELSE 0 END) as failed
FROM pgboss.job
GROUP BY name
ORDER BY pending DESC;
```

### Pending Jobs by Queue

```sql
SELECT name, COUNT(*) as count
FROM pgboss.job 
WHERE state = 'created'
GROUP BY name
ORDER BY count DESC;
```

### Active Jobs

```sql
SELECT id, name, data, startedon, 
  EXTRACT(EPOCH FROM (NOW() - startedon)) as running_seconds
FROM pgboss.job 
WHERE state = 'active'
ORDER BY startedon ASC;
```

### Failed Jobs

```sql
SELECT id, name, data, output, completedon, retrycount
FROM pgboss.job 
WHERE state = 'failed'
ORDER BY completedon DESC
LIMIT 50;
```

### Stuck Jobs (Running Too Long)

```sql
SELECT id, name, data, startedon,
  EXTRACT(EPOCH FROM (NOW() - startedon))/60 as minutes_running
FROM pgboss.job
WHERE state = 'active'
AND startedon < NOW() - INTERVAL '5 minutes'
ORDER BY startedon ASC;
```

### Job Throughput (Last Hour)

```sql
SELECT 
  date_trunc('minute', completedon) as minute,
  COUNT(*) as completed
FROM pgboss.job
WHERE state = 'completed'
AND completedon > NOW() - INTERVAL '1 hour'
GROUP BY minute
ORDER BY minute DESC;
```

### Archive Old Jobs

```sql
DELETE FROM pgboss.job 
WHERE state IN ('completed', 'cancelled', 'failed')
AND completedon < NOW() - INTERVAL '30 days';
```

### List Schedules

```sql
SELECT name, cron, timezone, created_on 
FROM pgboss.schedule 
ORDER BY name;
```

### Delete All Schedules (Pause All)

```sql
DELETE FROM pgboss.schedule;
```

---

## Alerting Queries

### Queue Backlog Alert

```sql
SELECT name, COUNT(*) as backlog
FROM pgboss.job 
WHERE state = 'created'
AND createdon < NOW() - INTERVAL '5 minutes'
GROUP BY name
HAVING COUNT(*) > 100;
```

### High Failure Rate

```sql
WITH stats AS (
  SELECT 
    name,
    SUM(CASE WHEN state = 'completed' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN state = 'failed' THEN 1 ELSE 0 END) as failed
  FROM pgboss.job
  WHERE completedon > NOW() - INTERVAL '1 hour'
  GROUP BY name
)
SELECT name, completed, failed,
  ROUND(failed::numeric / NULLIF(completed + failed, 0) * 100, 2) as failure_rate
FROM stats
WHERE failed > 0
ORDER BY failure_rate DESC;
```

---

## Job States Reference

| State | Description |
|-------|-------------|
| `created` | Queued, waiting for worker |
| `active` | Currently being processed |
| `completed` | Finished successfully |
| `failed` | Error occurred, may retry |
| `expired` | Exceeded time limit |
| `cancelled` | Manually cancelled |
