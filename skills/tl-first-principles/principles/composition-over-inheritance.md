# Composition Over Inheritance

> "Favor object composition over class inheritance."
> — Gang of Four, 1994

## The Principle

**Build complex behavior by combining simple, independent pieces rather than extending through class hierarchies.**

Inheritance creates tight coupling between parent and child. Composition creates loose coupling between peers. Loose coupling enables change.

## Lineage

| Who | When | Work |
|-----|------|------|
| [Gang of Four](../founders/gang-of-four.md) | 1994 | [Design Patterns: Elements of Reusable Object-Oriented Software](https://www.amazon.com/Design-Patterns-Elements-Reusable-Object-Oriented/dp/0201633612) |

Gamma, Helm, Johnson, and Vlissides documented 23 patterns from experienced OOP practitioners. Nearly every pattern favors composition. The book's second major principle (after "program to an interface"): favor composition over inheritance.

## Why It Endures

Inheritance promises reuse but delivers coupling:

| Inheritance Problem | Why It Hurts |
|---------------------|--------------|
| **Fragile base class** | Parent changes break children unpredictably |
| **Single inheritance limit** | Can only extend one class (in most languages) |
| **Forced structure** | Child inherits ALL of parent, even unwanted parts |
| **Leaky abstraction** | Child often needs parent implementation details |
| **Rigid hierarchy** | Hard to reorganize after the fact |

Composition avoids these:

| Composition Benefit | How It Works |
|---------------------|--------------|
| **Independent pieces** | Each component changes separately |
| **Multiple compositions** | Combine any number of behaviors |
| **Selective use** | Include only what you need |
| **Encapsulation** | Components interact via interface, not internals |
| **Runtime flexibility** | Swap components without changing structure |

## Modern Manifestations

| Pattern | Composition Mechanism |
|---------|----------------------|
| **React hooks** | Compose behaviors: `useState`, `useEffect`, `useQuery` |
| **Middleware** | Stack independent transformations |
| **Higher-order functions** | Wrap/enhance functions |
| **Mixins/traits** | Add behaviors without hierarchy |
| **Dependency injection** | Compose services at runtime |
| **Entity-Component-System** | Game objects = collection of components |

## The Test

Ask: **"If I need to change or swap this behavior, what else must change?"**

With inheritance: the entire class hierarchy may need revision.

With composition: swap the component, interface stays the same.

## Anti-Patterns

### Deep Inheritance Hierarchies

```typescript
// BAD: Deep hierarchy, fragile base class problem
class Animal { }
class Mammal extends Animal { }
class Canine extends Mammal { }
class Dog extends Canine { }
class GermanShepherd extends Dog { }

// Change to Animal affects every descendant
// What if we need a "RobotDog" that's Canine but not Mammal?
```

### God Class Through Inheritance

```typescript
// BAD: BaseController accumulates everything
class BaseController {
  protected validateRequest() { }
  protected authenticate() { }
  protected authorize() { }
  protected logRequest() { }
  protected handleError() { }
  protected sendResponse() { }
  protected cache() { }
  // ... 20 more methods
}

class UserController extends BaseController {
  // Inherits everything, uses 3 methods
}
```

### The "Util" Base Class

```typescript
// BAD: Inheritance for code reuse, not specialization
class StringUtils {
  protected capitalize(s: string) { }
  protected trim(s: string) { }
}

class UserService extends StringUtils {  // ← Not an "is-a" relationship
  createUser(name: string) {
    return this.capitalize(this.trim(name));
  }
}

// GOOD: Import utilities
import { capitalize, trim } from "@/utils/string";

class UserService {
  createUser(name: string) {
    return capitalize(trim(name));
  }
}
```

## When Inheritance Is Appropriate

Inheritance isn't always wrong. Use it when:

| Condition | Example |
|-----------|---------|
| True "is-a" relationship | `Square` is a `Rectangle` (with caveats) |
| Framework requires it | Some ORMs, UI frameworks |
| Template method pattern | Define algorithm skeleton, let children fill steps |
| Truly invariant base | `Error` subclasses, event types |

But even then, consider: could interfaces + composition achieve the same thing with more flexibility?

## Composition in Practice

```typescript
// Instead of inheritance, compose behaviors

// Behaviors as functions
const withTimestamps = {
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at"),
};

const withSoftDelete = {
  deletedAt: timestamp("deleted_at"),
};

const withAudit = {
  createdBy: uuid("created_by"),
  updatedBy: uuid("updated_by"),
};

// Compose what you need
const users = pgTable("users", {
  id: uuid("id").primaryKey(),
  email: varchar("email"),
  ...withTimestamps,
  ...withSoftDelete,
});

const posts = pgTable("posts", {
  id: uuid("id").primaryKey(),
  title: varchar("title"),
  ...withTimestamps,
  ...withAudit,  // Different composition
});
```

## Connections

| Principle | Relationship |
|-----------|-------------|
| [Abstraction & Contracts](abstraction-contracts.md) | Components interact via interfaces (contracts) |
| [Separation of Concerns](separation-of-concerns.md) | Each component handles one concern |
| [Information Hiding](information-hiding.md) | Components hide implementation behind interface |

## Key Insight

The Gang of Four observed that experienced OOP developers use inheritance sparingly and composition extensively. The book documented this pattern.

**Inheritance is not reuse.** Inheritance is specialization—creating subtypes. Reuse comes from composition: assembling capabilities from independent parts.

The functional programming community reached the same conclusion from different origins: compose small functions rather than build inheritance hierarchies. The principle transcends paradigms.
