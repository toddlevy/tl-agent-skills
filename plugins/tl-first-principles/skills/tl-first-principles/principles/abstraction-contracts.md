# Abstraction & Contracts

> "An abstract data type defines a class of abstract objects which is completely characterized by the operations available on those objects."
> — Barbara Liskov, 1974

> "An axiomatic basis for computer programming... preconditions, postconditions, and invariants."
> — C.A.R. Hoare, 1969

## The Principle

**Interfaces are behavioral promises. Consumers depend on what the interface guarantees, not how it's implemented.**

An abstraction hides irrelevant details. A contract specifies what the abstraction promises to do. Together, they enable substitution: any implementation satisfying the contract can replace another.

## Lineage

| Who | When | Work |
|-----|------|------|
| [Barbara Liskov](../founders/liskov.md) | 1974 | [Programming with Abstract Data Types](https://www.cs.tufts.edu/~nr/cs257/archive/barbara-liskov/data-abstraction-and-hierarchy.pdf) |
| [C.A.R. Hoare](../founders/hoare.md) | 1969 | [An Axiomatic Basis for Computer Programming](https://sunnyday.mit.edu/16.355/Hoare-CACM-69.pdf) |
| Liskov & Wing | 1994 | Liskov Substitution Principle formalization |

Liskov introduced **abstract data types** (ADTs): define a type by its operations, not its representation. This was radical in 1974—most programmers thought in terms of memory layouts.

Hoare provided the **formal foundation**: preconditions (what must be true before), postconditions (what will be true after), invariants (what's always true). This let programmers reason about code without reading every line.

## Why It Endures

Systems composed of interchangeable parts are:

- **Testable**: Mock implementations substitute for real ones
- **Evolvable**: Swap implementations without changing consumers
- **Understandable**: Reason about behavior without reading internals

The contract is the specification. If two implementations satisfy the same contract, they're interchangeable from the consumer's perspective.

## The Liskov Substitution Principle

Liskov's 1987 keynote (formalized with Jeannette Wing in 1994) crystallized the insight:

> If S is a subtype of T, then objects of type T may be replaced with objects of type S without altering the desirable properties of the program.

In practice: **subtypes must honor the behavioral contract of their parent type**.

```typescript
// Contract: withdraw() reduces balance, never goes negative
class BankAccount {
  withdraw(amount: number): void {
    if (amount > this.balance) throw new InsufficientFundsError();
    this.balance -= amount;
  }
}

// VIOLATES LSP: changes behavior consumers depend on
class OverdraftAccount extends BankAccount {
  withdraw(amount: number): void {
    this.balance -= amount;  // Can go negative — breaks contract
  }
}
```

## Modern Manifestations

| Pattern | Abstraction | Contract |
|---------|-------------|----------|
| **TypeScript interfaces** | Shape definition | Type signature |
| **Dependency injection** | Interface type | Expected behavior |
| **API versioning** | Endpoint path | Request/response schema |
| **Database repositories** | Repository interface | CRUD operations |
| **React component props** | Props interface | Render contract |
| **OpenAPI/GraphQL schemas** | Operation definitions | Input/output types |

## The Test

Ask: **"Can I substitute this implementation with another, and will consumers still work correctly?"**

If yes, the abstraction and contract are sound.

If no, either the contract isn't explicit enough, or an implementation violates it.

## Anti-Patterns

### Marker Interface

```typescript
// BAD: Interface promises nothing
interface Serializable {}

// GOOD: Interface specifies behavior
interface Serializable {
  serialize(): string;
  deserialize(data: string): void;
}
```

### Implementation Leak

```typescript
// BAD: Return type exposes implementation
interface UserService {
  getUser(id: string): Promise<PostgresRow>;  // ← Leaks DB choice
}

// GOOD: Return type is domain abstraction
interface UserService {
  getUser(id: string): Promise<User>;
}
```

### Covariant Return Violation

```typescript
// Contract: Cache.get() returns T | null
interface Cache<T> {
  get(key: string): T | null;
}

// VIOLATES: Sometimes throws instead of returning null
class RedisCache<T> implements Cache<T> {
  get(key: string): T | null {
    if (!this.connected) throw new Error("Not connected");  // ← Breaks contract
    // ...
  }
}
```

## Connections

| Principle | Relationship |
|-----------|-------------|
| [Information Hiding](information-hiding.md) | Abstraction IS information hiding; contract IS the interface |
| [Composition Over Inheritance](composition-over-inheritance.md) | Composition works because contracts enable substitution |
| [Separation of Concerns](separation-of-concerns.md) | Each concern gets its own abstraction with its own contract |

## Key Insight

Liskov and Hoare approached the same problem from different angles:

- **Liskov**: What operations define this type? (behavioral)
- **Hoare**: What does this operation promise? (contractual)

Together, they established that **types are behaviors, not representations**. An `int` isn't "32 bits in memory"—it's "a value that supports arithmetic operations within certain bounds."

This shift from representation to behavior is the foundation of all modern interface-based design.
