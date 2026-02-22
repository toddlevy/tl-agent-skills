---
name: tl-first-principles
description: Foundational software design principles traced to their intellectual origins. Covers information hiding, separation of concerns, abstraction, SSOT/DRY, conceptual integrity, and composition. Use when making architectural decisions, evaluating trade-offs, or understanding *why* best practices exist.
license: MIT
compatibility: Universal. Language and framework agnostic.
metadata:
  author: tl-agent-skills
  version: "1.0"
  suite: tl-first-principles
---

# First Principles of Software Design

The foundational axioms of quality software, traced to their intellectual origins.

**"First Principles"** carries a deliberate double meaning:

1. **Epistemological** — Reasoning from irreducible truths rather than by analogy
2. **Historical** — The *first* people who articulated these principles; the founders

This skill provides the *why* behind best practices by connecting modern conventions to their intellectual lineage.

## When to Use

- Making architectural decisions with trade-offs
- Evaluating whether code violates design principles
- Understanding *why* a pattern exists, not just *how*
- Teaching or explaining software design
- Code review with principled reasoning

## Principles Index

| Principle | Founder(s) | Key Work | Link |
|-----------|------------|----------|------|
| [Information Hiding](principles/information-hiding.md) | Parnas | 1972 | Decompose by secrets |
| [Separation of Concerns](principles/separation-of-concerns.md) | Dijkstra | 1974 | One thing at a time |
| [Abstraction & Contracts](principles/abstraction-contracts.md) | Liskov, Hoare | 1974, 1969 | Interfaces as promises |
| [Single Source of Truth](principles/single-source-of-truth.md) | Hunt & Thomas | 1999 | Every fact once |
| [Conceptual Integrity](principles/conceptual-integrity.md) | Brooks | 1975 | One coherent vision |
| [Fail Fast](principles/fail-fast.md) | Hamilton, Shore | 1960s, 2004 | Early detection |
| [Composition Over Inheritance](principles/composition-over-inheritance.md) | GoF | 1994 | Flexible assembly |
| [Explicit Over Implicit](principles/explicit-over-implicit.md) | Peters | 1999 | Clarity always |

## Founders Index

| Name | Era | Primary Contribution | Link |
|------|-----|---------------------|------|
| [David Parnas](founders/parnas.md) | 1970s | Modularity, information hiding |
| [Edsger Dijkstra](founders/dijkstra.md) | 1960s-70s | Structured programming, SoC |
| [Barbara Liskov](founders/liskov.md) | 1970s-90s | Data abstraction, substitutability |
| [C.A.R. Hoare](founders/hoare.md) | 1960s-70s | Contracts, formal reasoning |
| [Frederick Brooks](founders/brooks.md) | 1970s | Conceptual integrity, system design |
| [Margaret Hamilton](founders/hamilton.md) | 1960s | Software engineering, reliability |
| [Andy Hunt & Dave Thomas](founders/hunt-thomas.md) | 1990s | DRY, pragmatic practice |
| [Gang of Four](founders/gang-of-four.md) | 1990s | Design patterns |

## How to Use This Skill

### For Decision-Making

When evaluating a design choice, identify which principles are at stake:

```
"Should we duplicate this validation logic in both services?"

→ Principle: Single Source of Truth (Hunt & Thomas)
→ Risk: Drift when one copy changes but the other doesn't
→ Decision: Extract to shared module or single service
```

### For Code Review

Cite the principle and its lineage when explaining why something matters:

```
"This component fetches data AND renders AND handles errors.
 That's three concerns in one place.

→ Principle: Separation of Concerns (Dijkstra, 1974)
→ Why it matters: Each concern changes for different reasons
→ Suggestion: Extract data fetching to a hook"
```

### For Learning

Trace modern patterns back to their origins:

```
React hooks → Composition over Inheritance → GoF (1994)
TypeScript interfaces → Contracts → Hoare (1969), Liskov (1987)
Redux single store → SSOT → Hunt & Thomas (1999)
Microservices → Information Hiding → Parnas (1972)
```

## Convergence Map

These principles emerged from different lineages but converge on the same goal: **managing complexity in systems that must change over time**.

```
                         ┌─────────────────────────────────────┐
                         │   MANAGING COMPLEXITY IN SYSTEMS    │
                         │       THAT MUST CHANGE OVER TIME    │
                         └───────────────┬─────────────────────┘
                                         │
          ┌──────────────┬───────────────┼───────────────┬──────────────┐
          ▼              ▼               ▼               ▼              ▼
   ┌─────────────┐ ┌───────────┐ ┌─────────────┐ ┌─────────────┐ ┌──────────┐
   │ MODULARITY  │ │ LEGIBILITY│ │ ABSTRACTION │ │  INTEGRITY  │ │ FEEDBACK │
   │   Parnas    │ │  Dijkstra │ │Liskov/Hoare │ │   Brooks    │ │ Hamilton │
   └─────────────┘ └───────────┘ └─────────────┘ └─────────────┘ └──────────┘
          │              │               │               │              │
          ▼              ▼               ▼               ▼              ▼
   Information     Separation      Contracts &     Conceptual      Fail Fast
     Hiding        of Concerns    Substitution      Integrity
          │              │               │               │              │
          └──────────────┴───────────────┴───────────────┴──────────────┘
                                         │
                         ┌───────────────┼───────────────┐
                         ▼               ▼               ▼
                  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
                  │    SOLID    │ │     DRY     │ │   PATTERNS  │
                  │ Uncle Bob   │ │ Hunt/Thomas │ │     GoF     │
                  └─────────────┘ └─────────────┘ └─────────────┘
                         │               │               │
                         └───────────────┼───────────────┘
                                         ▼
                         ┌─────────────────────────────────────┐
                         │        MODERN PRACTICE              │
                         │  Clean Architecture, Microservices, │
                         │  Functional Core, React Composition │
                         └─────────────────────────────────────┘
```

## Primary Sources

See [sources/primary-sources.md](sources/primary-sources.md) for annotated bibliography with links to original papers and books.

## Related Skills

This skill provides the *theory*. For *practice*, see:

| Need | Skill |
|------|-------|
| Database patterns | `drizzle-patterns` |
| Code quality setup | `code-quality-setup` |
| Codebase audit | `codebase-audit` |

## References

- [sources/primary-sources.md](sources/primary-sources.md) — Annotated bibliography
- [principles/](principles/) — Individual principle deep-dives
- [founders/](founders/) — Biographical context for key figures
