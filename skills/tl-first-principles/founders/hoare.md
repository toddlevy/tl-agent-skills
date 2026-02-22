# C.A.R. Hoare (Tony Hoare)

> "There are two ways of constructing a software design: One way is to make it so simple that there are obviously no deficiencies, and the other way is to make it so complicated that there are no obvious deficiencies."

## Overview

| | |
|---|---|
| **Era** | 1960s–present |
| **Affiliation** | Oxford, Microsoft Research |
| **Primary Contribution** | Formal Methods, Contracts (Pre/Postconditions) |
| **Key Paper** | "An Axiomatic Basis for Computer Programming" (1969) |
| **Award** | Turing Award, 1980 |

## The Contribution

Hoare created the formal foundation for reasoning about programs. His **Hoare logic** uses preconditions, postconditions, and invariants to prove program correctness.

He also invented **Quicksort**, **CSP (Communicating Sequential Processes)**, and the concept of the **null pointer** (which he called his "billion-dollar mistake").

## Axiomatic Basis (1969)

[An Axiomatic Basis for Computer Programming](https://sunnyday.mit.edu/16.355/Hoare-CACM-69.pdf)

The paper introduced **Hoare triples**: `{P} C {Q}`

- **P** (Precondition): What must be true before code runs
- **C** (Command): The code itself
- **Q** (Postcondition): What will be true after code runs

Example:
```
{x = 5}           // Precondition
x := x + 1        // Command
{x = 6}           // Postcondition
```

This created a way to **prove** programs correct, not just test them.

## Contracts in Practice

While full formal proof remains specialized, Hoare's ideas permeate everyday programming:

| Concept | Hoare Origin |
|---------|--------------|
| Function signatures | Partial contract specification |
| Type systems | Mechanized precondition checking |
| Assertions | Runtime precondition/postcondition checks |
| Design by Contract (Eiffel) | Direct application of Hoare logic |
| Zod/Yup validation | Precondition validation at boundaries |
| Database constraints | Invariant enforcement |

## Key Insights

1. **Programs are specifications.** A program specifies a relationship between inputs and outputs. That specification should be verifiable.

2. **Interfaces are contracts.** The interface specifies what the implementation promises. Violations are bugs.

3. **Correctness is provable.** Not just testable—provable. Testing shows presence of bugs; proof shows absence.

4. **Simplicity enables proof.** Complex programs are hard to reason about. Simple programs can be understood and verified.

## The Billion-Dollar Mistake

Hoare invented the null reference in 1965 for ALGOL W. He later called it his "billion-dollar mistake":

> "I call it my billion-dollar mistake. It was the invention of the null reference... This has led to innumerable errors, vulnerabilities, and system crashes."

This self-criticism led to widespread adoption of:
- Optional types (`Option<T>`, `Maybe<T>`)
- Null safety features (TypeScript strict null checks)
- The "fail fast" principle for null handling

## Influence

| Modern Practice | Hoare Lineage |
|-----------------|---------------|
| TypeScript strict mode | Mechanized invariant checking |
| Zod/Yup schemas | Precondition specification |
| Database constraints | Invariant enforcement |
| Design by Contract (Eiffel, D) | Direct application |
| Formal verification tools | Hoare logic implementations |

## Other Notable Work

- **Quicksort** (1960): The most widely used sorting algorithm
- **CSP** (1978): Foundation for concurrent programming (influenced Go channels, Erlang)
- **Null reference**: Invented and later regretted

## Principles Associated

- [Abstraction & Contracts](../principles/abstraction-contracts.md)
- [Fail Fast](../principles/fail-fast.md) (related)
- [Explicit Over Implicit](../principles/explicit-over-implicit.md) (related)

## Sources

- [An Axiomatic Basis for Computer Programming (PDF)](https://sunnyday.mit.edu/16.355/Hoare-CACM-69.pdf)
- [Communicating Sequential Processes (Book)](http://www.usingcsp.com/cspbook.pdf)
- Turing Award lecture (1980)
