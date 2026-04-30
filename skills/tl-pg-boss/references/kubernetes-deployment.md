# Kubernetes Deployment

> Loaded on-demand by `tl-pg-boss` when deploying queue workers to Kubernetes. See `../SKILL.md` for the parent skill.

## Worker Deployment

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

## Graceful Shutdown Handler

```typescript
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, stopping gracefully...');
  await boss.stop({ graceful: true, timeout: 30000 });
  process.exit(0);
});
```
