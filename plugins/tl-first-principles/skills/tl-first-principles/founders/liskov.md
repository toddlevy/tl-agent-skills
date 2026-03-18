# Barbara Liskov

> "An abstract data type defines a class of abstract objects which is completely characterized by the operations available on those objects."

## Overview

| | |
|---|---|
| **Era** | 1970s–present |
| **Affiliation** | MIT |
| **Primary Contribution** | Data Abstraction, Liskov Substitution Principle |
| **Key Paper** | "Programming with Abstract Data Types" (1974) |
| **Award** | Turing Award, 2008 |

## The Contribution

Liskov introduced **abstract data types (ADTs)**: the idea that a type is defined by its operations, not its representation.

Before ADTs, programmers thought in terms of memory layouts. A "stack" was a particular arrangement of bytes. Liskov shifted the perspective: a "stack" is anything that supports `push`, `pop`, and `isEmpty`, regardless of how it's implemented.

This abstraction—**types as behaviors**—is the foundation of modern interface-based programming.

## Abstract Data Types (1974)

[Programming with Abstract Data Types](https://www.cs.tufts.edu/~nr/cs257/archive/barbara-liskov/data-abstraction-and-hierarchy.pdf)

The paper introduced CLU, a language designed around ADTs. Key ideas:

- Types are defined by operations, not representation
- Representation is hidden from users of the type
- Multiple implementations can satisfy the same type
- **Substitutability**: any conforming implementation works

## The Liskov Substitution Principle (1987/1994)

In her 1987 keynote (formalized with Jeannette Wing in 1994), Liskov articulated what became the "L" in SOLID:

> "If S is a subtype of T, then objects of type T may be replaced with objects of type S without altering the desirable properties of the program."

This is **behavioral subtyping**: subtypes must honor the behavioral contract of their parent types. It's not enough to have the same method signatures; the methods must *behave* compatibly.

## Key Insights

1. **Types are behaviors, not structures.** The operations define the type. The data structure is an implementation detail.

2. **Substitutability requires behavioral compatibility.** A subtype can't just have matching signatures—it must fulfill the same behavioral expectations.

3. **Encapsulation enables substitution.** Because users can't depend on representation, you can swap implementations freely.

4. **Hierarchy has costs.** Liskov later emphasized that inheritance hierarchies create coupling. Composition often serves better.

## Influence

| Modern Practice | Liskov Lineage |
|-----------------|----------------|
| Interfaces (TypeScript, Java) | ADTs |
| Duck typing | Types as behaviors |
| Dependency injection | Substitutability |
| SOLID (Liskov Substitution) | Behavioral subtyping |
| Protocol-based design (Swift, Go) | Operations define type |

## Other Notable Work

- **CLU programming language**: First language designed around ADTs
- **Argus**: Distributed computing language
- **Thor**: Object-oriented database system

## Principles Associated

- [Abstraction & Contracts](../principles/abstraction-contracts.md)
- [Information Hiding](../principles/information-hiding.md) (related)
- [Composition Over Inheritance](../principles/composition-over-inheritance.md) (related)

## Sources

- [Programming with Abstract Data Types (PDF)](https://www.cs.tufts.edu/~nr/cs257/archive/barbara-liskov/data-abstraction-and-hierarchy.pdf)
- [A Behavioral Notion of Subtyping](https://dl.acm.org/doi/10.1145/197320.197383) (Liskov & Wing, 1994)
- Turing Award lecture (2008)
