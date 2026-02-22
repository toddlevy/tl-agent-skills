# Andy Hunt & Dave Thomas

> "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."

## Overview

| | |
|---|---|
| **Era** | 1990s–present |
| **Affiliation** | Pragmatic Programmers |
| **Primary Contribution** | DRY, Pragmatic Practice |
| **Key Book** | "The Pragmatic Programmer" (1999) |

## The Contribution

Hunt and Thomas codified practical wisdom that experienced developers had accumulated. Their book became a standard reference for professional software development.

They coined **DRY** (Don't Repeat Yourself) and **SSOT** (Single Source of Truth), giving names to concepts that practitioners recognized but hadn't articulated.

## The Pragmatic Programmer (1999)

The book distills decades of collective experience into actionable principles:

| Principle | Summary |
|-----------|---------|
| **DRY** | Every piece of knowledge in one place |
| **Orthogonality** | Components should be independent |
| **Tracer bullets** | Build end-to-end early, iterate |
| **Broken windows** | Fix small problems before they spread |
| **Good enough software** | Know when to stop |
| **Programming by coincidence** | Don't rely on accidental behavior |

## DRY: Knowledge, Not Code

Hunt and Thomas were explicit that DRY is about **knowledge**, not code:

> "DRY is about the duplication of knowledge, of intent. It's about expressing the same thing in two different places, possibly in two totally different ways."

Two identical code blocks aren't necessarily DRY violations if they represent different knowledge. Two different-looking values ARE violations if they represent the same fact.

This distinction prevents over-extraction. Not every repeated pattern needs a utility function. Only repeated **knowledge** needs a single source.

## Orthogonality

Related to but distinct from separation of concerns:

> "Two or more things are orthogonal if changes in one do not affect any of the others."

Orthogonal systems are:
- **Easier to change** — changes are localized
- **Easier to test** — components isolated
- **Easier to reuse** — no hidden dependencies
- **Lower risk** — bugs are contained

## Tracer Bullets

Build a minimal end-to-end path early:

```
UI → API → Service → Database

All integrated from day one, even if bare-bones.
```

Benefits:
- Integration problems surface early
- Visible progress to stakeholders
- Framework for iteration
- Target for testing

## Key Insights

1. **Pragmatism over dogma.** Rules have contexts. Know when to break them.

2. **Knowledge, not code.** DRY is about facts, not syntax.

3. **Continuous improvement.** Small, frequent refactoring beats big rewrites.

4. **Own your craft.** Invest in learning. Sharpen the saw.

## Influence

| Modern Practice | Hunt/Thomas Lineage |
|-----------------|---------------------|
| SSOT patterns | DRY principle |
| Microservices independence | Orthogonality |
| Walking skeleton / MVP | Tracer bullets |
| Boy Scout rule | Broken windows |
| Pragmatic estimation | Good enough software |

## The 20th Anniversary Edition (2019)

The 2019 edition updated examples and added new material while preserving core principles. The longevity demonstrates that fundamental practices don't become obsolete even as technologies change.

New additions:
- Concurrency and parallelism
- Security consciousness
- Agile practices integration

## Principles Associated

- [Single Source of Truth](../principles/single-source-of-truth.md)
- [Separation of Concerns](../principles/separation-of-concerns.md) (orthogonality)
- [Explicit Over Implicit](../principles/explicit-over-implicit.md) (related)

## Sources

- "The Pragmatic Programmer" (1999, 20th anniversary edition 2019)
- [Pragmatic Programmers website](https://pragprog.com/)
