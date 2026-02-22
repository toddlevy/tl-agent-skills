# Information Hiding

> "The connections between modules are the assumptions which the modules make about each other."
> — David Parnas, 1972

## The Principle

**Decompose systems by the decisions likely to change, and hide those decisions behind stable interfaces.**

Each module should conceal its internal workings. Other modules interact only through a defined interface, unaware of implementation details.

## Lineage

| Who | When | Work |
|-----|------|------|
| [David Parnas](../founders/parnas.md) | 1972 | [On the Criteria To Be Used in Decomposing Systems into Modules](https://wstomv.win.tue.nl/edu/2ip30/references/criteria_for_modularization.pdf) |

Parnas wrote this paper at Carnegie Mellon, contrasting two ways to decompose the same system:

1. **Flowchart decomposition** — modules based on processing steps
2. **Information hiding decomposition** — modules based on design decisions

The flowchart approach created brittle systems where changes rippled across modules. Information hiding localized change: modify the secret, keep the interface stable.

## Why It Endures

The insight is about **change management**, not abstraction for its own sake.

Software systems live far longer than anticipated. Requirements evolve. Technologies shift. The question isn't "will this change?" but "when it changes, how much else breaks?"

Information hiding answers: **nothing breaks, if the secret stays inside**.

## Modern Manifestations

| Pattern | Hidden Secret |
|---------|--------------|
| **Encapsulation** (OOP) | Object state, internal methods |
| **APIs** | Service implementation behind endpoint contract |
| **Microservices** | Entire subsystem behind service boundary |
| **React hooks** | State management logic behind `useX()` interface |
| **Database abstraction** | SQL dialect, connection pooling, caching |
| **Feature flags** | Rollout state, user segmentation logic |

## The Test

Ask: **"If I change this implementation detail, what else must change?"**

If the answer is "nothing outside this module," you've hidden the information well.

If the answer is "several other files," you've exposed a secret that should be hidden.

## Anti-Patterns

### Leaky Abstraction

```typescript
// BAD: Implementation detail exposed
interface UserRepository {
  getUserById(id: string): Promise<User>;
  executeRawSql(query: string): Promise<any>;  // ← Leaks database assumption
}

// GOOD: Clean interface
interface UserRepository {
  getUserById(id: string): Promise<User>;
  findByEmail(email: string): Promise<User | null>;
}
```

### Distributed Monolith

Services that share databases or internal data structures aren't hiding information—they're just physically separated. The "microservice" boundary provides no change isolation.

### Config Sprawl

When configuration values appear in multiple places, the "secret" of the config source isn't hidden. Changes require hunting across files.

## Connections

| Principle | Relationship |
|-----------|-------------|
| [Separation of Concerns](separation-of-concerns.md) | Complementary: SoC says *what* to separate; information hiding says *how* |
| [Abstraction & Contracts](abstraction-contracts.md) | The interface IS the contract; the hidden part IS the abstraction |
| [Single Source of Truth](single-source-of-truth.md) | Hidden secrets should have one authoritative location |

## Key Insight

Parnas didn't invent modules. He invented the *criterion* for deciding what goes in each module: **hide the decisions that are likely to change**.

This shifts decomposition from "what does the system do?" (steps) to "what might the system become?" (change vectors).
