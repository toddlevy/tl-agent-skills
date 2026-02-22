# Primary Sources

Annotated bibliography of foundational texts, organized by principle area. Links to freely available PDFs where possible.

## Modularity & Information Hiding

### Parnas, "On the Criteria To Be Used in Decomposing Systems into Modules" (1972)

**[PDF](https://wstomv.win.tue.nl/edu/2ip30/references/criteria_for_modularization.pdf)**

The paper that established information hiding as a design principle. Compares two decompositions of the same system—one based on processing steps, one based on design decisions—and shows why the latter enables change.

**Key quote**: "The connections between modules are the assumptions which the modules make about each other."

**Read this when**: Understanding why microservices have boundaries where they do, or why API design matters.

---

## Structured Programming & Separation of Concerns

### Dijkstra, "Go To Statement Considered Harmful" (1968)

**[PDF](https://homepages.cwi.nl/~storm/teaching/reader/Dijkstra68.pdf)**

A letter arguing that goto statements make programs impossible to reason about. The deeper point: programs should be structured for human comprehension.

**Key quote**: "Our intellectual powers are rather geared to master static relations and... our powers to visualize processes evolving in time are relatively poorly developed."

**Read this when**: Debating code readability vs. cleverness.

### Dijkstra, "On the role of scientific thought" (EWD 447, 1974)

**[Transcript](https://www.cs.utexas.edu/~EWD/transcriptions/EWD04xx/EWD447.html)**

Introduces the term "separation of concerns" and explains why studying one aspect in isolation is essential for intellectual progress.

**Key quote**: "It is what I sometimes have called 'the separation of concerns'... Let me try to explain to you, what to my taste is characteristic for all intelligent thinking."

**Read this when**: Justifying why UI shouldn't contain business logic.

---

## Abstraction & Contracts

### Liskov, "Programming with Abstract Data Types" (1974)

**[PDF](https://www.cs.tufts.edu/~nr/cs257/archive/barbara-liskov/data-abstraction-and-hierarchy.pdf)**

Introduces abstract data types: types defined by operations, not representation. The conceptual foundation of interfaces.

**Key quote**: "An abstract data type defines a class of abstract objects which is completely characterized by the operations available on those objects."

**Read this when**: Designing APIs or understanding why TypeScript interfaces work.

### Hoare, "An Axiomatic Basis for Computer Programming" (1969)

**[PDF](https://sunnyday.mit.edu/16.355/Hoare-CACM-69.pdf)**

Introduces preconditions, postconditions, and invariants—the formal basis for "contracts."

**Key quote**: "Computer programming is an exact science in that all the properties of a program and all the consequences of executing it in any given environment can, in principle, be found out from the text of the program."

**Read this when**: Understanding why validation belongs at boundaries.

### Liskov & Wing, "A Behavioral Notion of Subtyping" (1994)

**[ACM DL](https://dl.acm.org/doi/10.1145/197320.197383)**

Formalizes the Liskov Substitution Principle: subtypes must honor the behavioral contract of their parent type.

**Read this when**: Debugging why a subclass breaks something that worked with the parent.

---

## Conceptual Integrity & Large Systems

### Brooks, "The Mythical Man-Month" (1975)

**[PDF](https://web.eecs.umich.edu/~weimerw/2018-481/readings/mythical-man-month.pdf)**

Lessons from IBM System/360. Introduces Brooks's Law ("adding people to a late project makes it later") and conceptual integrity as the supreme design virtue.

**Key quote**: "Conceptual integrity is the most important consideration in system design."

**Read this when**: Leading architecture decisions or arguing against "design by committee."

### Conway, "How Do Committees Invent?" (1968)

**[PDF](https://www.melconway.com/Home/pdf/committees.pdf)**

The original statement of Conway's Law: organizations produce systems that mirror their communication structure.

**Key quote**: "Any organization that designs a system will produce a design whose structure is a copy of the organization's communication structure."

**Read this when**: Understanding why your microservices look like your org chart.

---

## Process & Quality

### Royce, "Managing the Development of Large Software Systems" (1970)

**[PDF](https://www.praxisframework.org/files/royce1970.pdf)**

Often cited as the origin of "waterfall," though Royce actually advocated for iteration. Worth reading to see how his ideas were misinterpreted.

**Key quote**: "If the computer program in question is being developed for the first time, arrange matters so that the version finally delivered... is actually the second version."

**Read this when**: Understanding the history of iterative development.

### Boehm, "A Spiral Model of Software Development and Enhancement" (1988)

**[PDF](https://www.cse.msu.edu/~cse435/Homework/HW3/boehm.pdf)**

Introduces risk-driven iterative development. Each cycle addresses highest risks first.

**Read this when**: Prioritizing what to build first.

---

## DRY & Pragmatic Practice

### Hunt & Thomas, "The Pragmatic Programmer" (1999/2019)

**[Book](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/)**

Codified DRY, orthogonality, tracer bullets, and dozens of other pragmatic principles. The 20th anniversary edition updates examples while preserving core wisdom.

**Key quote**: "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."

**Read this when**: Starting a new project or mentoring developers.

---

## Design Patterns & Composition

### Gamma et al., "Design Patterns" (1994)

**[Book](https://www.amazon.com/Design-Patterns-Elements-Reusable-Object-Oriented/dp/0201633612)**

The "Gang of Four" book. Documents 23 patterns and establishes "favor composition over inheritance" as a core principle.

**Key quote**: "Favor object composition over class inheritance."

**Read this when**: Recognizing recurring design problems or communicating solutions.

---

## Reliability & Fail-Fast

### Shore, "Fail Fast" (2004)

**[IEEE Software](https://www.martinfowler.com/ieeeSoftware/failFast.pdf)**

Articulates the fail-fast principle: bugs are easier to find when they surface close to their origin.

**Key quote**: "Failing fast is a nonintuitive technique: 'failing immediately and visibly' sounds like a bad thing, but it's not."

**Read this when**: Designing error handling strategies.

---

## Modern Synthesis

### Martin, "Clean Architecture" (2017)

**[Book](https://www.amazon.com/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164)**

Synthesizes SOLID principles, dependency rules, and architectural patterns. Builds on Parnas, Liskov, and the GoF.

### Fowler, "Refactoring" (1999/2018)

**[Website](https://martinfowler.com/books/refactoring.html)**

Systematic approach to improving code design without changing behavior. The second edition uses JavaScript examples.

**Key quote**: "Any fool can write code that a computer can understand. Good programmers write code that humans can understand."

---

## Reading Order

For those wanting to trace the intellectual lineage:

1. **Dijkstra (1968)** — Structured thinking
2. **Parnas (1972)** — Modular decomposition
3. **Liskov (1974)** — Abstract data types
4. **Brooks (1975)** — Large system design
5. **GoF (1994)** — Patterns vocabulary
6. **Hunt & Thomas (1999)** — Pragmatic synthesis

For practitioners who want immediately applicable wisdom:

1. **Hunt & Thomas** — Pragmatic principles
2. **GoF** — Pattern vocabulary
3. **Martin** — Clean architecture
4. **Fowler** — Refactoring techniques
