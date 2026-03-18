# David Parnas

> "The connections between modules are the assumptions which the modules make about each other."

## Overview

| | |
|---|---|
| **Era** | 1970s–present |
| **Affiliation** | Carnegie Mellon, McMaster University |
| **Primary Contribution** | Modularity, Information Hiding |
| **Key Paper** | "On the Criteria To Be Used in Decomposing Systems into Modules" (1972) |

## The Contribution

Parnas didn't invent modules—programmers had been dividing code into pieces since the beginning. He invented the **criterion** for deciding what goes in each module.

Before Parnas, the common approach was **flowchart decomposition**: break the system into processing steps, make each step a module. This seemed intuitive but created brittle systems where changes rippled unpredictably.

Parnas proposed **information hiding decomposition**: each module encapsulates a design decision that might change. The module's interface is stable; its internals are hidden.

## The 1972 Paper

[On the Criteria To Be Used in Decomposing Systems into Modules](https://wstomv.win.tue.nl/edu/2ip30/references/criteria_for_modularization.pdf)

Parnas compared two decompositions of the same system (a KWIC index generator):

| Decomposition 1 (Flowchart) | Decomposition 2 (Information Hiding) |
|----------------------------|--------------------------------------|
| Modules match processing steps | Modules hide design decisions |
| Changes affect multiple modules | Changes localized to one module |
| Easy to understand initially | Harder to understand initially |
| Hard to change | Easy to change |

The "harder to understand initially" was controversial. Parnas argued that **changeability matters more than initial comprehensibility** for systems that must evolve.

## Key Insights

1. **Modules should hide secrets, not steps.** A module's purpose isn't to perform a processing step—it's to encapsulate a decision that might change.

2. **Interfaces are the contract.** The connection between modules is the set of assumptions they make about each other. Minimizing assumptions minimizes coupling.

3. **Change is the design driver.** Decompose based on what might change independently, not based on what the system does.

## Influence

| Modern Practice | Parnas Lineage |
|-----------------|----------------|
| Encapsulation in OOP | Information hiding |
| API design | Stable interfaces |
| Microservices | Service boundaries hide implementation |
| Module systems (ES Modules, CommonJS) | Explicit exports, hidden internals |

## Other Notable Work

- **"Software Aging"** (1994): Systems degrade over time as changes accumulate. Architecture must plan for change.
- **Table-driven design**: Represent decisions as data, not code, for easier modification.
- **A-7E Naval Aircraft Software**: Real-world demonstration of information hiding in a safety-critical system.

## Principles Associated

- [Information Hiding](../principles/information-hiding.md)
- [Separation of Concerns](../principles/separation-of-concerns.md) (related)

## Sources

- [Original 1972 Paper (PDF)](https://wstomv.win.tue.nl/edu/2ip30/references/criteria_for_modularization.pdf)
- "Software Fundamentals: Collected Papers by David L. Parnas" (book)
