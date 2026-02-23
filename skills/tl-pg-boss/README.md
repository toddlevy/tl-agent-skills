# tl-pg-boss

PostgreSQL-backed job queue for Node.js with exactly-once delivery, cron scheduling, and transactional safety — using [pg-boss](https://github.com/timgit/pg-boss).

Part of [tl-agent-skills](https://github.com/toddlevy/tl-agent-skills).

## What This Skill Covers

- Installation and core concepts (SKIP LOCKED, `start()` discipline)
- Job patterns: send, delayed, cron scheduling, typed jobs
- Worker patterns: basic, batch, typed
- Queue configuration: dead letter queues, retention
- Fastify integration
- Monitoring: dashboard setup, SQL queries
- Sharp edges and best practices
- WordPress/WP-Cron/Action Scheduler migration guide

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill: patterns, integration, sharp edges |
| `references/send-options.md` | Full `boss.send()` options reference |
| `references/typescript-patterns.md` | BaseJob class, JobManager registry pattern |
| `references/monitoring.md` | Dashboard setup and SQL monitoring queries |
| `references/advanced-patterns.md` | Singleton, throttling, pub/sub, transactional jobs |
| `references/schedule-management.md` | Cron schedules, unschedule, pause patterns, admin API |
| `references/wordpress-migration.md` | WP-Cron and Action Scheduler concept mapping |

## Attribution

| Source | Author | Contribution |
|--------|--------|--------------|
| [pg-boss](https://github.com/timgit/pg-boss) | Tim Gilbert (@timgit) | Core library, official docs, Discussion #416 clarifications |
| [TypeScript Deep Dive](https://logsnag.com/blog/deep-dive-into-background-jobs-with-pg-boss-and-typescript) | Shayan (@ImSh4yy) | BaseJob class, JobManager pattern |
| [pg-boss skill](https://playbooks.com/skills/omer-metin/skills-for-antigravity/pg-boss) | Omer Metin | SKIP LOCKED principles, archiving best practices |
| [pg-boss-admin-dashboard](https://github.com/lpetrov/pg-boss-admin-dashboard) | Lyubomir Petrov (@lpetrov) | Alternative dashboard with JMESPath |

## Links

- [pg-boss — GitHub](https://github.com/timgit/pg-boss) (MIT License)
- [pg-boss — Documentation](https://timgit.github.io/pg-boss/)
- [pg-boss — Dashboard](https://github.com/timgit/pg-boss/tree/master/packages/dashboard)
