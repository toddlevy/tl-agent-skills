# Single Source of Truth (SSOT) / DRY

> "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."
> — Andy Hunt & Dave Thomas, 1999

## The Principle

**Each fact, rule, or piece of knowledge should be defined exactly once. All other usages should reference that definition.**

Duplication isn't about identical code—it's about duplicated *knowledge*. Two functions with similar code but different purposes aren't violations. One fact defined in two places is.

## Lineage

| Who | When | Work |
|-----|------|------|
| [Andy Hunt & Dave Thomas](../founders/hunt-thomas.md) | 1999 | [The Pragmatic Programmer](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/) |

Hunt and Thomas coined "DRY" (Don't Repeat Yourself) and SSOT, but they were explicit that it's about **knowledge**, not code:

> "DRY is about the duplication of knowledge, of intent. It's about expressing the same thing in two different places, possibly in two totally different ways."

This distinction matters: extracting every three-line pattern into a function is *not* DRY—it's premature abstraction. But having the same business rule in two places *is* a DRY violation.

## Why It Endures

When knowledge exists in multiple places:

1. **Changes require multiple edits** — easy to miss one
2. **Copies drift** — they start the same but diverge over time
3. **Truth becomes ambiguous** — which copy is authoritative?
4. **Bugs hide** — fix one place, forget another

SSOT eliminates these problems by ensuring each fact has exactly one home.

## What Counts as "Knowledge"?

| Knowledge Type | Example | SSOT Location |
|----------------|---------|---------------|
| Configuration | API base URL | Environment variable or config file |
| Business rule | "Trial lasts 14 days" | Constant or domain service |
| Data shape | User entity structure | Type definition or schema |
| Validation | Email format rules | Validation schema |
| Calculation | Discount logic | Domain function |
| UI text | Error messages | i18n translation files |

## Modern Manifestations

| Pattern | SSOT Mechanism |
|---------|---------------|
| **Database schema** | Schema defines data shape; ORM generates types |
| **OpenAPI/GraphQL** | Spec defines contract; codegen creates clients |
| **Design tokens** | Single JSON defines colors, spacing, typography |
| **i18n files** | Translation keys are single source for UI text |
| **Feature flags** | Flag service is single source for feature state |
| **Redux/Zustand stores** | Store is single source for UI state |

## The Test

Ask: **"If this fact changes, how many places do I update?"**

If the answer is "one," you have SSOT.

If the answer is "several," you have duplicated knowledge.

## Anti-Patterns

### Copy-Paste Constants

```typescript
// BAD: Magic number in multiple files
// service/billing.ts
const TRIAL_DAYS = 14;

// components/PricingPage.tsx
const trialLength = 14;  // ← Duplicated knowledge

// GOOD: Single source
// constants/plans.ts
export const TRIAL_DAYS = 14;

// Used everywhere via import
```

### Parallel Hierarchies

Two structures that must change together:

```typescript
// BAD: Type and validation must stay in sync manually
interface User {
  email: string;
  age: number;
}

const userSchema = z.object({
  email: z.string().email(),
  age: z.number().min(0),  // ← Must match interface
});

// GOOD: Derive one from the other
const userSchema = z.object({
  email: z.string().email(),
  age: z.number().min(0),
});
type User = z.infer<typeof userSchema>;  // ← Single source
```

### Documentation Drift

Comments or READMEs that duplicate what code already says. When code changes, docs don't. Prefer self-documenting code and auto-generated docs.

## When Duplication Is Acceptable

Not all similar code is duplicated knowledge:

```typescript
// These look similar but serve different purposes
function validateUserInput(data: unknown): User { ... }
function validateApiResponse(data: unknown): User { ... }

// Input validation and response validation may diverge:
// - Input: strict, user-facing errors
// - Response: defensive, log-and-recover
// Extracting a shared function couples things that should vary independently
```

The rule of three: wait until you have three instances before extracting. Two similar things might be coincidence; three is a pattern.

## Connections

| Principle | Relationship |
|-----------|-------------|
| [Information Hiding](information-hiding.md) | The single source should be behind a stable interface |
| [Separation of Concerns](separation-of-concerns.md) | Each concern has its own SSOT |
| [Conceptual Integrity](conceptual-integrity.md) | SSOT ensures consistency; integrity ensures coherence |

## Key Insight

Hunt and Thomas shifted focus from **code duplication** (syntactic) to **knowledge duplication** (semantic).

Two identical-looking functions aren't necessarily duplicates if they represent different knowledge. Two different-looking values ARE duplicates if they represent the same fact.

The question isn't "does this code appear elsewhere?" It's "if this knowledge changes, where else must change?"
