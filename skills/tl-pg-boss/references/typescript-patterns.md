# pg-boss TypeScript Patterns

Reusable patterns for type-safe job management.

> **Attribution**: BaseJob and JobManager patterns adapted from [Shayan's TypeScript Deep Dive](https://logsnag.com/blog/deep-dive-into-background-jobs-with-pg-boss-and-typescript).

## Typed Jobs (Simple)

```typescript
interface EmailJobData {
  to: string;
  subject: string;
  body: string;
}

await boss.send<EmailJobData>("send-email", {
  to: "user@example.com",
  subject: "Welcome",
  body: "Hello!",
});

await boss.work<EmailJobData>("send-email", async ([job]) => {
  const { to, subject, body } = job.data;
  await sendEmail(to, subject, body);
});
```

## Job Base Class Pattern

Abstract base for consistent job handling:

```typescript
import PgBoss from "pg-boss";

type JobType = "welcome-email" | "sync-contacts" | "process-order";

interface Job<T extends object> {
  type: JobType;
  options: PgBoss.SendOptions;
  start: () => Promise<void>;
  work: (job: PgBoss.Job<T>) => Promise<void>;
  emit: (data: T) => Promise<void>;
}

abstract class BaseJob<T extends object> implements Job<T> {
  protected boss: PgBoss;
  abstract readonly type: JobType;
  readonly options: PgBoss.SendOptions = { retryLimit: 3, retryDelay: 60 };

  constructor(boss: PgBoss) {
    this.boss = boss;
  }

  async start(): Promise<void> {
    await this.boss.work(this.type, ([job]) => this.work(job));
  }

  abstract work(job: PgBoss.Job<T>): Promise<void>;

  async emit(data: T): Promise<void> {
    await this.boss.send(this.type, data, this.options);
  }
}
```

## Concrete Job Implementation

```typescript
interface WelcomeEmailData {
  email: string;
  name: string;
}

class WelcomeEmailJob extends BaseJob<WelcomeEmailData> {
  readonly type = "welcome-email" as const;
  readonly options = { 
    retryLimit: 3, 
    retryDelay: 60,
    expireInMinutes: 10,
  };

  async work(job: PgBoss.Job<WelcomeEmailData>): Promise<void> {
    const { email, name } = job.data;
    await emailService.sendWelcome(email, name);
    console.log(`[WelcomeEmailJob] Sent to ${email}`);
  }
}
```

## Job Manager (Type-Safe Registry)

```typescript
type JobTypeMapping = {
  "welcome-email": WelcomeEmailJob;
  "sync-contacts": SyncContactsJob;
  "process-order": ProcessOrderJob;
};

class JobManager {
  private readonly boss: PgBoss;
  private jobs = new Map<string, Job<any>>();

  constructor(boss: PgBoss) {
    this.boss = boss;
  }

  register<T extends Job<any>>(JobClass: new (boss: PgBoss) => T): this {
    const job = new JobClass(this.boss);
    this.jobs.set(job.type, job);
    return this;
  }

  async start(): Promise<void> {
    await this.boss.start();
    for (const job of this.jobs.values()) {
      await job.start();
    }
  }

  async stop(): Promise<void> {
    await this.boss.stop({ graceful: true });
  }

  async emit<K extends keyof JobTypeMapping>(
    type: K,
    data: Parameters<JobTypeMapping[K]["emit"]>[0]
  ): Promise<string | null> {
    const job = this.jobs.get(type);
    if (!job) throw new Error(`Job ${type} not registered`);
    return job.emit(data);
  }
}
```

## Usage

```typescript
const boss = new PgBoss(process.env.DATABASE_URL);

const jobs = new JobManager(boss)
  .register(WelcomeEmailJob)
  .register(SyncContactsJob)
  .register(ProcessOrderJob);

await jobs.start();

// Type-safe emit
await jobs.emit("welcome-email", { email: "user@example.com", name: "John" });

// Graceful shutdown
process.on("SIGTERM", () => jobs.stop());
```

## Benefits

- **Type safety**: Compile-time checks for job data
- **Encapsulation**: Each job is self-contained
- **Testability**: Jobs can be unit tested independently
- **Consistency**: Shared options and error handling
