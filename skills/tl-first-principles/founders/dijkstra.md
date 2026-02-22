# Edsger Dijkstra

> "The competent programmer is fully aware of the strictly limited size of his own skull; he therefore approaches the programming task in full humility."

## Overview

| | |
|---|---|
| **Era** | 1960s–2000s |
| **Affiliation** | Eindhoven, UT Austin |
| **Primary Contribution** | Structured Programming, Separation of Concerns |
| **Key Paper** | "Go To Statement Considered Harmful" (1968) |

## The Contribution

Dijkstra championed **structured programming**: the idea that programs should be built from simple, composable control structures (sequence, selection, iteration) rather than arbitrary jumps.

His deeper contribution was recognizing that **human cognition is the limiting factor** in programming. Programs must be written to be understood by humans, not just executed by machines.

## The "Goto" Letter

[Go To Statement Considered Harmful](https://homepages.cwi.nl/~storm/teaching/reader/Dijkstra68.pdf) (1968)

The letter argued that `goto` statements make programs nearly impossible to reason about. With `goto`, you can't look at a line of code and know how you got there.

The controversy generated attention, but the real point was about **reasoning**:

- With structured control flow, you can trace execution mentally
- With arbitrary jumps, the number of possible paths explodes
- **Programs should be provably correct**, and that requires structure

## Separation of Concerns

Dijkstra coined the term "separation of concerns" in a 1974 manuscript:

> "Let me try to explain to you, what to my taste is characteristic for all intelligent thinking. It is, that one is willing to study in depth an aspect of one's subject matter in isolation for the sake of its own consistency."

The key insight: **human attention is finite**. We can only think about one thing deeply at a time. Software should be organized to enable this focused thinking.

## Key Insights

1. **Programs are proofs.** A program is an argument that, given certain inputs, certain outputs will result. The argument must be readable.

2. **The humble programmer.** Acknowledge cognitive limits. Don't write "clever" code that exceeds your ability to reason about.

3. **One thing at a time.** Study each concern in isolation. Don't mix concerns that can be thought about separately.

4. **Testing shows presence, not absence, of bugs.** You can't test your way to correctness. Structure enables reasoning; reasoning enables correctness.

## Influence

| Modern Practice | Dijkstra Lineage |
|-----------------|-----------------|
| Structured control flow | No goto |
| Layered architecture | Separation of concerns |
| Pure functions | Reasoning about code |
| Code review | Programs must be readable |
| Static analysis | Formal methods in practice |

## The EWD Manuscripts

Dijkstra wrote over 1,300 numbered manuscripts (EWD series), distributed as handwritten photocopies. They cover algorithms, philosophy, education, and computing culture.

Notable EWDs:
- **EWD 215**: "A Case against the GO TO Statement" (precursor to the letter)
- **EWD 447**: "On the role of scientific thought" (introduces separation of concerns)
- **EWD 1036**: "On the Cruelty of Really Teaching Computing Science"

## Principles Associated

- [Separation of Concerns](../principles/separation-of-concerns.md)
- [Explicit Over Implicit](../principles/explicit-over-implicit.md) (related)
- [Conceptual Integrity](../principles/conceptual-integrity.md) (related)

## Sources

- [Go To Statement Considered Harmful (PDF)](https://homepages.cwi.nl/~storm/teaching/reader/Dijkstra68.pdf)
- [EWD Archive](https://www.cs.utexas.edu/~EWD/)
- "A Discipline of Programming" (book)
