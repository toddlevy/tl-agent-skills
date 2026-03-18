# Frederick Brooks

> "The bearing of a child takes nine months, no matter how many women are assigned."

## Overview

| | |
|---|---|
| **Era** | 1960s–2000s |
| **Affiliation** | IBM, UNC Chapel Hill |
| **Primary Contribution** | Conceptual Integrity, System Design |
| **Key Book** | "The Mythical Man-Month" (1975) |
| **Award** | Turing Award, 1999 |

## The Contribution

Brooks managed the IBM System/360 project, one of the largest software efforts of its era. From this experience, he extracted hard-won insights about large-system design and team organization.

His central thesis: **adding people to a late software project makes it later** (Brooks's Law). But his deeper contribution was identifying **conceptual integrity** as the most important quality of a system.

## The Mythical Man-Month (1975)

[The Mythical Man-Month](https://web.eecs.umich.edu/~weimerw/2018-481/readings/mythical-man-month.pdf)

Key insights from the book:

| Insight | Implication |
|---------|-------------|
| Brooks's Law | Communication overhead grows n² with team size |
| Surgical team model | Small elite teams, not large democratic ones |
| Conceptual integrity | One coherent vision, even at cost of features |
| Second-system effect | Designers overload their second design |
| Plan to throw one away | First version is always prototype |

## Conceptual Integrity

Brooks argued that conceptual integrity is **the most important consideration in system design**:

> "It is better to have a system omit certain anomalous features and improvements, but to reflect one set of design ideas, than to have one that contains many good but independent and uncoordinated ideas."

This was controversial. Brooks advocated for a **chief architect** with final authority—a single mind to ensure coherence. Democratic design, he argued, produces systems with no coherent vision.

## No Silver Bullet (1986)

The "No Silver Bullet" essay distinguished:

- **Essential complexity**: Inherent in the problem domain
- **Accidental complexity**: Introduced by our tools and methods

Brooks argued that most "breakthroughs" (OOP, AI, better tools) only address accidental complexity. Essential complexity is irreducible. There is no 10x improvement waiting to be discovered.

This framing remains influential: engineers ask "is this essential or accidental complexity?" when evaluating designs.

## Key Insights

1. **Conceptual integrity over feature count.** A coherent system that does less is better than an incoherent system that does more.

2. **Communication costs dominate.** As team size grows, coordination time explodes. Keep teams small.

3. **Plan to iterate.** First designs are learning exercises. Build one to throw away.

4. **Essential vs. accidental.** Know which complexity is inherent and which you introduced.

## Influence

| Modern Practice | Brooks Lineage |
|-----------------|----------------|
| "Two-pizza teams" | Small team efficiency |
| Architecture Decision Records | Maintaining conceptual integrity |
| Technical leadership roles | Chief architect model |
| "That's not MVP" | Integrity over features |
| Iterative development | Plan to throw one away |

## Principles Associated

- [Conceptual Integrity](../principles/conceptual-integrity.md)
- [Separation of Concerns](../principles/separation-of-concerns.md) (related)

## Sources

- [The Mythical Man-Month (PDF)](https://web.eecs.umich.edu/~weimerw/2018-481/readings/mythical-man-month.pdf)
- "No Silver Bullet" (1986)
- "The Design of Design" (2010)
