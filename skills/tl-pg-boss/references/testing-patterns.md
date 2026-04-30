# Testing Patterns

> Loaded on-demand by `tl-pg-boss` when writing tests for queue handlers and end-to-end flows. See `../SKILL.md` for the parent skill.

## Unit Testing Job Handlers

```typescript
describe('EmailJob', () => {
  it('sends email with correct parameters', async () => {
    const sendEmail = vi.fn();
    const handler = createEmailHandler({ sendEmail });
    
    await handler({ to: 'test@example.com', subject: 'Test' });
    
    expect(sendEmail).toHaveBeenCalledWith({
      to: 'test@example.com',
      subject: 'Test',
    });
  });
});
```

## Integration Testing with Real Database

```typescript
import { PgBoss } from 'pg-boss';

describe('Job Queue Integration', () => {
  let boss: PgBoss;
  
  beforeAll(async () => {
    boss = new PgBoss(process.env.TEST_DATABASE_URL);
    await boss.start();
    await boss.createQueue('test-queue');
  });
  
  afterAll(async () => {
    await boss.stop();
  });
  
  it('processes job end-to-end', async () => {
    const results: any[] = [];
    await boss.work('test-queue', async (job) => {
      results.push(job.data);
    });
    
    await boss.send('test-queue', { id: 1 });
    await new Promise((r) => setTimeout(r, 1000));
    
    expect(results).toEqual([{ id: 1 }]);
  });
});
```

## Mocking pg-boss

```typescript
const mockBoss = {
  start: vi.fn().mockResolvedValue(undefined),
  send: vi.fn().mockResolvedValue('job-id'),
  work: vi.fn().mockResolvedValue(undefined),
  createQueue: vi.fn().mockResolvedValue(undefined),
};

vi.mock('pg-boss', () => ({
  PgBoss: vi.fn(() => mockBoss),
}));
```
