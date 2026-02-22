# Conceptual Integrity

> "I will contend that conceptual integrity is the most important consideration in system design. It is better to have a system omit certain anomalous features and improvements, but to reflect one set of design ideas, than to have one that contains many good but independent and uncoordinated ideas."
> — Frederick Brooks, 1975

## The Principle

**A system should embody one coherent vision, one consistent way of doing things, even if that means omitting good ideas that don't fit.**

Conceptual integrity is about the user's (or developer's) mental model. A system with integrity feels like one mind designed it. A system without integrity feels like a committee compromise.

## Lineage

| Who | When | Work |
|-----|------|------|
| [Frederick Brooks](../founders/brooks.md) | 1975 | [The Mythical Man-Month](https://web.eecs.umich.edu/~weimerw/2018-481/readings/mythical-man-month.pdf) |
| [Melvin Conway](https://www.melconway.com/Home/pdf/committees.pdf) | 1968 | "How Do Committees Invent?" (Conway's Law) |

Brooks observed that adding people to a late project made it later. But his deeper insight was about *design coherence*: the OS/360 project suffered from too many designers with too many ideas, all incorporated.

Conway provided the structural explanation: systems mirror the communication structure of the organization that builds them. A fragmented org produces a fragmented system.

## Why It Endures

Users learn a system by building a mental model. Every inconsistency—every place where "the way we do X" differs—creates cognitive load.

- **Two ways to do the same thing** → user confusion
- **Inconsistent naming** → translation burden
- **Mixed paradigms** → context switching
- **Special cases everywhere** → model breakdown

A system with conceptual integrity is learnable because patterns transfer. Learn how one part works, predict how other parts work.

## Modern Manifestations

| Pattern | Integrity Mechanism |
|---------|---------------------|
| **Design systems** | Consistent components, spacing, colors |
| **API style guides** | Uniform naming, error formats, pagination |
| **Framework conventions** | Rails: convention over configuration |
| **Monorepo standards** | Shared tooling, consistent structure |
| **Architecture Decision Records** | Document and enforce design choices |

## The Test

Ask: **"Could a newcomer predict how this part works based on how other parts work?"**

If yes, the system has conceptual integrity.

If no, the system is a collection of independent decisions.

## Conway's Law

Conway's Law is the organizational counterpart:

> "Any organization that designs a system will produce a design whose structure is a copy of the organization's communication structure."

**Implications:**

- Siloed teams → siloed services with awkward boundaries
- Cross-functional teams → cohesive features
- Unclear ownership → ambiguous interfaces
- One architect → one coherent vision

The "inverse Conway maneuver": structure your organization to produce the system structure you want.

## Anti-Patterns

### The Frankenstein System

Multiple teams add features independently. Each feature is internally coherent, but the whole is disjointed:

- Three different date pickers
- Two authentication flows
- Inconsistent error messages
- Some pages use modals, others use full-page forms

### Design by Committee

Every stakeholder's idea is incorporated. The result satisfies no one's vision:

```
"We need both REST and GraphQL"
"Let's support JSON and XML"
"Some endpoints use camelCase, some snake_case"
"We have both service classes and helper functions doing the same thing"
```

### Accidental Architecture

No one ever decided the architecture. It emerged from accumulated decisions:

```
"Why is user auth in lib/ but org auth in services/?"
"Why do some routes use middleware and others use guards?"
"Why are some configs in .env and others in config files?"
```

## Achieving Integrity

Brooks's controversial recommendation: **one chief architect** with final authority over design decisions.

Modern alternatives:

| Approach | How It Works |
|----------|-------------|
| **ADRs** | Document decisions; new work must fit or explicitly supersede |
| **RFCs** | Proposals reviewed for consistency with existing patterns |
| **Design system** | Constrain UI choices to a coherent vocabulary |
| **Style guides** | Codify "how we do X" decisions |
| **Architecture reviews** | Check new work against established patterns |

## Connections

| Principle | Relationship |
|-----------|-------------|
| [Single Source of Truth](single-source-of-truth.md) | SSOT for facts; integrity for approach |
| [Separation of Concerns](separation-of-concerns.md) | Each concern should have ONE coherent approach |
| [Explicit Over Implicit](explicit-over-implicit.md) | Integrity makes patterns learnable; explicitness reinforces |

## Key Insight

Brooks distinguished between *essential* and *accidental* complexity. Conceptual integrity doesn't reduce essential complexity—the problem is still hard. But it eliminates accidental complexity from inconsistent design choices.

A system with integrity is simpler than the sum of its parts because patterns compound. A system without integrity is more complex than the sum because every deviation is a special case to remember.

The cost of integrity is saying "no" to good ideas that don't fit. The benefit is a system that can be understood, extended, and maintained by humans.
