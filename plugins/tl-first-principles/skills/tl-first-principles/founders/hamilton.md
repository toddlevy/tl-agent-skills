# Margaret Hamilton

> "There was no second chance. We had to get it right the first time."

## Overview

| | |
|---|---|
| **Era** | 1960s–present |
| **Affiliation** | MIT Instrumentation Laboratory, NASA |
| **Primary Contribution** | Software Engineering, Reliability |
| **Key Project** | Apollo Guidance Computer |
| **Award** | Presidential Medal of Freedom, 2016 |

## The Contribution

Hamilton led the team that developed the flight software for NASA's Apollo missions. In doing so, she helped establish **software engineering as a discipline**.

The term "software engineering" was considered tongue-in-cheek when Hamilton first used it—software wasn't taken seriously as an engineering discipline. Her work on Apollo proved that software required the same rigor as hardware.

## Apollo and Reliability

The Apollo Guidance Computer (AGC) had:
- 74 KB of memory
- No remote debugging
- No patches after launch
- Astronaut lives at stake

Under these constraints, Hamilton's team developed practices we now consider fundamental:

| Practice | Modern Form |
|----------|-------------|
| Asynchronous executive | Event-driven architecture |
| Priority scheduling | Task queues, job systems |
| Error detection and recovery | Fail-safe design |
| Human-in-the-loop design | User-centered error handling |
| Extensive testing | CI/CD, test automation |

## The Apollo 11 Moment

Three minutes before lunar landing, the AGC triggered 1202 and 1203 alarms—computer overload. Hamilton's priority-based architecture saved the mission:

The computer was overloaded with radar data, but the priority scheduler shed lower-priority tasks to maintain essential guidance. The landing continued safely.

This wasn't luck—it was design. Hamilton's team had anticipated overload conditions and built recovery into the system.

## Fail Fast, Recover Gracefully

Hamilton's approach combined:

1. **Detection**: Catch errors immediately
2. **Prioritization**: Know what matters most
3. **Recovery**: Graceful degradation, not total failure
4. **Human awareness**: Surface problems to operators

This is the ancestor of modern reliability engineering: circuit breakers, graceful degradation, observability, incident response.

## Key Insights

1. **Software is engineering.** It requires rigor, discipline, and accountability—just like building bridges.

2. **Anticipate failure.** Design for the scenario where things go wrong, not just the happy path.

3. **Priorities matter.** Not all tasks are equal. Shed load intelligently when overloaded.

4. **Test exhaustively.** With no second chances, everything must work the first time.

## Influence

| Modern Practice | Hamilton Lineage |
|-----------------|-----------------|
| Reliability engineering | Fail-safe design |
| Chaos engineering | Testing failure modes |
| SRE practices | Error budgets, prioritization |
| Circuit breakers | Graceful degradation |
| Priority queues | Task scheduling |

## Other Notable Work

- **Universal Systems Language (USL)**: Formal language for defining reliable systems
- **001 Tool Suite**: Development environment based on USL
- **Hamilton Technologies, Inc.**: Founded 1986, applies Apollo lessons

## Principles Associated

- [Fail Fast](../principles/fail-fast.md)
- [Explicit Over Implicit](../principles/explicit-over-implicit.md) (related)
- [Separation of Concerns](../principles/separation-of-concerns.md) (related)

## Sources

- [NASA: Margaret Hamilton](https://science.nasa.gov/people/margaret-hamilton/)
- "What the Errors Tell Us" (Hamilton, 1972)
- MIT Oral History interview
