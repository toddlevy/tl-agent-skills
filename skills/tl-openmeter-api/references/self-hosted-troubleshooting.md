# Self-Hosted Troubleshooting: Railway/Kafka

> Loaded on-demand by `tl-openmeter-api` when debugging self-hosted OpenMeter on Railway or other Kafka-backed deployments. See `../SKILL.md` for the parent skill.

## Events Not Metering (0 Usage, Empty `/api/v1/events`)

**Root Cause:** Kafka has no persistent volume. Topics are lost on every Kafka restart.

**Symptoms:**
- OpenMeter logs: `kafka delivery failed: Broker: Unknown topic or partition`
- Sink worker logs: `no topics found to be subscribed to` or `partitions=[]`
- ClickHouse has 0 tables
- `/api/v1/events` returns `[]`

**Architecture:**
```
Event → OpenMeter API → Kafka → Sink Worker → ClickHouse → Meters
```

If any link breaks, events don't meter.

**Fix:**

1. **Add Kafka volume** at `/var/lib/kafka/data`
   - Railway: Service → Settings → Volumes → Add
   - For Confluent images: Set `RAILWAY_RUN_UID=0` for volume permissions

2. **Provision topics explicitly** (if `KAFKA_AUTO_CREATE_TOPICS_ENABLE=false`):
   ```
   om_default_events (namespace events - sink worker consumes)
   om_sys.api_events
   om_sys.ingest_events
   ```

3. **Restart OpenMeter + sink-worker** after Kafka restarts to refresh metadata

4. **Verify:**
   - Restart Kafka twice → topics persist
   - Send test event → appears in `/api/v1/events`

**Kafka Environment Variables (Railway):**
```bash
KAFKA_AUTO_CREATE_TOPICS_ENABLE=true  # Or provision topics explicitly
KAFKA_LOG_DIRS=/var/lib/kafka/data/logs-v2  # Use subdirectory if cluster ID conflicts
RAILWAY_RUN_UID=0  # Confluent images need root for volume permissions
```

## Sink Worker Partition Instability

**Symptom:** Sink worker gets partition assignment, loses it within seconds.

**Cause:** Multiple sink-worker instances competing for single partition (Railway rolling deploys).

**Fix:** Ensure only 1 sink-worker instance runs. Check Kafka logs for `"group ... with N members"` where N > 1.
