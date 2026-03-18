# tl-first-principles

Foundational software design principles traced to their intellectual origins.

## What This Is

A reference skill that connects modern best practices to their historical lineage. When you ask "why do we separate concerns?" or "where does DRY come from?", this skill provides the answer—complete with the original papers and the people who wrote them.

## Structure

```
tl-first-principles/
├── SKILL.md                    # Hub: index and usage guide
├── principles/                 # Individual principle deep-dives
│   ├── information-hiding.md
│   ├── separation-of-concerns.md
│   ├── abstraction-contracts.md
│   ├── single-source-of-truth.md
│   ├── conceptual-integrity.md
│   ├── fail-fast.md
│   ├── composition-over-inheritance.md
│   └── explicit-over-implicit.md
├── founders/                   # Key figures in software design
│   ├── parnas.md
│   ├── dijkstra.md
│   ├── liskov.md
│   ├── hoare.md
│   ├── brooks.md
│   ├── hamilton.md
│   ├── hunt-thomas.md
│   └── gang-of-four.md
└── sources/
    └── primary-sources.md      # Annotated bibliography with links
```

## The Double Meaning

"First Principles" is intentional:

1. **Epistemological** — Reason from irreducible truths, not analogy
2. **Historical** — The *first* people who articulated these principles

## Quick Links

| Principle | Founder | Year |
|-----------|---------|------|
| Information Hiding | Parnas | 1972 |
| Separation of Concerns | Dijkstra | 1974 |
| Abstraction & Contracts | Liskov, Hoare | 1974, 1969 |
| Single Source of Truth | Hunt & Thomas | 1999 |
| Conceptual Integrity | Brooks | 1975 |
| Fail Fast | Hamilton | 1960s |
| Composition Over Inheritance | GoF | 1994 |

## Usage

Reference this skill when:
- Making architectural decisions with trade-offs
- Explaining *why* a pattern matters in code review
- Teaching software design fundamentals
- Understanding the intellectual history of our craft
