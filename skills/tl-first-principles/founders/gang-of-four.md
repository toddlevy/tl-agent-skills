# Gang of Four (GoF)

> "Favor object composition over class inheritance."

## Overview

| | |
|---|---|
| **Authors** | Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides |
| **Era** | 1990s |
| **Primary Contribution** | Design Patterns |
| **Key Book** | "Design Patterns: Elements of Reusable Object-Oriented Software" (1994) |

## The Contribution

The Gang of Four (nicknamed for the four authors) documented **23 design patterns** observed in successful object-oriented systems. They didn't invent these patterns—they **discovered** and **named** them.

By giving patterns names, they created a vocabulary. Developers could say "that's a Factory" or "use the Observer pattern" and be immediately understood.

## Design Patterns (1994)

[Design Patterns: Elements of Reusable Object-Oriented Software](https://www.amazon.com/Design-Patterns-Elements-Reusable-Object-Oriented/dp/0201633612)

The 23 patterns, organized by purpose:

### Creational Patterns (How objects are created)

| Pattern | Purpose |
|---------|---------|
| **Abstract Factory** | Create families of related objects |
| **Builder** | Construct complex objects step by step |
| **Factory Method** | Defer instantiation to subclasses |
| **Prototype** | Clone existing objects |
| **Singleton** | Ensure one instance |

### Structural Patterns (How objects are composed)

| Pattern | Purpose |
|---------|---------|
| **Adapter** | Convert interface to another |
| **Bridge** | Separate abstraction from implementation |
| **Composite** | Treat tree structures uniformly |
| **Decorator** | Add behavior dynamically |
| **Facade** | Simplify complex subsystem |
| **Flyweight** | Share common state |
| **Proxy** | Control access to object |

### Behavioral Patterns (How objects interact)

| Pattern | Purpose |
|---------|---------|
| **Chain of Responsibility** | Pass request along chain |
| **Command** | Encapsulate request as object |
| **Interpreter** | Define grammar and interpreter |
| **Iterator** | Access elements sequentially |
| **Mediator** | Centralize complex communication |
| **Memento** | Capture and restore state |
| **Observer** | Notify dependents of changes |
| **State** | Alter behavior when state changes |
| **Strategy** | Encapsulate interchangeable algorithms |
| **Template Method** | Define skeleton, defer steps |
| **Visitor** | Add operations without changing classes |

## The Two Core Principles

More important than any single pattern:

1. **Program to an interface, not an implementation.**
   Depend on abstractions. Concrete types are implementation details.

2. **Favor composition over inheritance.**
   Build behavior by combining objects, not by extending classes.

Nearly every pattern in the book exemplifies these principles.

## Composition Over Inheritance

The book observed that experienced OOP developers use inheritance sparingly:

| Inheritance Problems | Composition Solutions |
|---------------------|----------------------|
| Fragile base class | Components change independently |
| Single inheritance limit | Compose any number of components |
| Forced interface | Include only what you need |
| Compile-time binding | Runtime flexibility |

Patterns like Strategy, Decorator, and Composite demonstrate composition in action.

## Key Insights

1. **Patterns are discovered, not invented.** Good solutions recur. Name them.

2. **Vocabulary enables communication.** "That's a Strategy" conveys more than a paragraph of explanation.

3. **Interface over implementation.** Depend on what something does, not how.

4. **Composition over inheritance.** Assemble behaviors from parts.

## Influence

| Modern Practice | GoF Lineage |
|-----------------|-------------|
| React hooks | Composition patterns |
| Middleware | Chain of Responsibility, Decorator |
| Event emitters | Observer |
| State machines | State pattern |
| Dependency injection | Factory + Interface principle |
| Functional programming adoption | Strategy, Command as functions |

## Criticism and Evolution

The book has been criticized for:
- **Over-engineering**: Applying patterns where simple code suffices
- **Java-centrism**: Some patterns are language workarounds
- **Verbosity**: Modern languages express patterns more concisely

Modern developers often implement patterns in lighter forms:
- Functions instead of Strategy classes
- Closures instead of Command objects
- Hooks instead of Template Method

The patterns remain valid; their expressions have evolved.

## Principles Associated

- [Composition Over Inheritance](../principles/composition-over-inheritance.md)
- [Abstraction & Contracts](../principles/abstraction-contracts.md) (program to interface)
- [Information Hiding](../principles/information-hiding.md) (related)

## Sources

- [Design Patterns Book](https://www.amazon.com/Design-Patterns-Elements-Reusable-Object-Oriented/dp/0201633612)
- "Design Patterns Explained" (Shalloway & Trott) — accessible introduction
- [Refactoring.Guru Patterns](https://refactoring.guru/design-patterns) — modern examples
