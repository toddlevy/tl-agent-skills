# Fail Fast

> "There was no second chance. We had to get it right the first time."
> — Margaret Hamilton, on Apollo flight software

## The Principle

**Detect errors as early as possible and surface them immediately. Don't let invalid state propagate through the system.**

Fail fast is about **error locality**: the closer an error is caught to its source, the easier it is to diagnose and fix.

## Lineage

| Who | When | Work |
|-----|------|------|
| [Margaret Hamilton](../founders/hamilton.md) | 1960s | Apollo Guidance Computer software |
| Jim Shore | 2004 | "Fail Fast" (IEEE Software) |

Hamilton's Apollo team pioneered reliability-first software engineering. With astronaut lives at stake and no remote debugging, errors had to be caught before flight—or handled gracefully in flight.

Shore later articulated the principle explicitly: failing fast in development prevents failing mysteriously in production.

## Why It Endures

The further an error travels from its source:

1. **More state is corrupted** — error compounds
2. **Harder to diagnose** — symptom far from cause
3. **More expensive to fix** — debugging time increases exponentially
4. **Higher blast radius** — more users/systems affected

A validation error caught in the form is trivial. The same bad data caught three services later is a production incident.

## The Error Distance Pyramid

```
                    ┌─────────┐
                    │   Prod  │  ← Expensive, visible, stressful
                    │ Incident│
                   ─┴─────────┴─
                 ┌───────────────┐
                 │   CI/CD       │  ← Cheap, automated
                 │   Failure     │
                ─┴───────────────┴─
              ┌───────────────────────┐
              │   Local Test          │  ← Instant feedback
              │   Failure             │
             ─┴───────────────────────┴─
           ┌───────────────────────────────┐
           │   Type Error / Lint           │  ← Before you finish typing
           │                               │
          ─┴───────────────────────────────┴─
        ┌───────────────────────────────────────┐
        │   Design-Time Prevention              │  ← Error is impossible
        │   (types, constraints, invariants)    │
       ─┴───────────────────────────────────────┴─
```

Fail fast means pushing detection toward the bottom of the pyramid.

## Modern Manifestations

| Layer | Fail-Fast Mechanism |
|-------|---------------------|
| **Types** | TypeScript catches null access at compile time |
| **Validation** | Zod/Yup validate input at boundary |
| **Database** | Constraints prevent invalid data |
| **Tests** | Assertions catch logic errors |
| **Monitoring** | Alerts fire before users notice |
| **Circuit breakers** | Fail immediately vs. queue failures |

## The Test

Ask: **"Where in the system would this error be caught? How far could it travel?"**

If caught at entry (API boundary, form submission, function call): good.

If caught later (in a different service, during nightly batch, by user report): fail-fast violation.

## Anti-Patterns

### Silent Swallowing

```typescript
// BAD: Error disappears, caller thinks success
async function processOrder(order: Order) {
  try {
    await chargeCard(order);
  } catch (error) {
    console.error("Payment failed:", error);  // ← Logged but not surfaced
  }
  await shipOrder(order);  // ← Executes even if payment failed!
}

// GOOD: Error surfaces immediately
async function processOrder(order: Order) {
  await chargeCard(order);  // ← Throws if fails, caller handles
  await shipOrder(order);
}
```

### Defensive Null Returns

```typescript
// BAD: Null hides failure, caller may not check
function getUserById(id: string): User | null {
  if (!isValidId(id)) return null;  // ← Bad input silently returns null
  // ...
}

// GOOD: Invalid input throws
function getUserById(id: string): User {
  if (!isValidId(id)) {
    throw new InvalidIdError(`Invalid user ID format: ${id}`);
  }
  // ...
}
```

### Catch-All Error Handlers

```typescript
// BAD: Every error becomes generic 500
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "Something went wrong" });
});

// GOOD: Specific errors, actionable messages
app.use((err, req, res, next) => {
  if (err instanceof ValidationError) {
    return res.status(400).json({ error: err.message, fields: err.fields });
  }
  if (err instanceof NotFoundError) {
    return res.status(404).json({ error: err.message });
  }
  // Unexpected errors: log full details, return generic message
  logger.error({ err, req }, "Unhandled error");
  res.status(500).json({ error: "Internal server error", requestId: req.id });
});
```

## Fail Fast vs. Fault Tolerance

These aren't opposites:

| Context | Strategy |
|---------|----------|
| **Development** | Fail fast, loudly. Surface all errors. |
| **Input validation** | Fail fast. Reject bad input immediately. |
| **Transient failures** | Retry with backoff. Circuit breaker. |
| **Graceful degradation** | Partial functionality vs. total failure. |

Fail fast is about **not hiding errors**. Fault tolerance is about **continuing despite errors**. They complement each other.

## Connections

| Principle | Relationship |
|-----------|-------------|
| [Abstraction & Contracts](abstraction-contracts.md) | Contracts define what's valid; fail fast enforces |
| [Explicit Over Implicit](explicit-over-implicit.md) | Fail fast makes errors explicit instead of hidden |
| [Separation of Concerns](separation-of-concerns.md) | Error handling is a concern—don't mix with business logic |

## Key Insight

Hamilton's Apollo work established that **reliable systems aren't accident-free—they're error-aware**.

The goal isn't to prevent all errors (impossible). It's to ensure errors are:

1. **Detected** — not silently ignored
2. **Localized** — caught near source
3. **Actionable** — provide enough context to fix

Fail fast is defensive programming done right: not defensively hiding errors, but defensively exposing them.
