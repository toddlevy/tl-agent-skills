# Separation of Concerns

> "Let me try to explain to you, what to my taste is characteristic for all intelligent thinking. It is, that one is willing to study in depth an aspect of one's subject matter in isolation for the sake of its own consistency."
> — Edsger Dijkstra, 1974

## The Principle

**Address one concern at a time. Each module, function, or layer should have a single reason to change.**

A "concern" is an aspect of the system that can be thought about independently: rendering, data access, validation, logging, authentication.

## Lineage

| Who | When | Work |
|-----|------|------|
| [Edsger Dijkstra](../founders/dijkstra.md) | 1974 | "On the role of scientific thought" (EWD 447) |
| Dijkstra | 1968 | [Go To Statement Considered Harmful](https://homepages.cwi.nl/~storm/teaching/reader/Dijkstra68.pdf) |

Dijkstra coined the term in 1974, but the idea flows from his structured programming work. The "goto" letter was really about **legibility**: code should be readable as a sequence of concerns, not a tangle of jumps.

Separation of concerns is structured programming's natural extension: not just legible control flow, but legible responsibility allocation.

## Why It Endures

Different concerns change for different reasons and at different rates:

- **UI** changes when design evolves or users give feedback
- **Business logic** changes when requirements change
- **Data access** changes when storage technology changes
- **Validation** changes when data models change

Mixing concerns means changes for one reason force edits in code that handles other reasons. This creates:

- Harder testing (must mock unrelated concerns)
- Harder reasoning (must hold multiple contexts in mind)
- Higher change risk (unrelated code might break)

## Modern Manifestations

| Pattern | Separated Concerns |
|---------|-------------------|
| **MVC/MVP/MVVM** | Model (data), View (presentation), Controller (flow) |
| **Layered architecture** | Presentation, Domain, Infrastructure |
| **React hooks** | State (useState), Effects (useEffect), Data (useQuery) |
| **Middleware** | Auth, logging, validation as separate pipeline stages |
| **CSS Modules/BEM** | Structure (HTML), Style (CSS), Behavior (JS) |
| **Event-driven architecture** | Producers don't know consumers |

## The Test

Ask: **"If this one aspect of the system changes, how many files do I touch?"**

If the answer is "one" (or a cohesive set), concerns are separated.

If the answer is "many unrelated files," concerns are entangled.

## Anti-Patterns

### Fat Controller

```typescript
// BAD: Controller handles HTTP, validation, business logic, AND persistence
app.post("/users", async (req, res) => {
  if (!req.body.email?.includes("@")) {
    return res.status(400).json({ error: "Invalid email" });
  }
  const existing = await db.query("SELECT id FROM users WHERE email = $1", [req.body.email]);
  if (existing.rows.length > 0) {
    return res.status(409).json({ error: "Email exists" });
  }
  const hash = await bcrypt.hash(req.body.password, 10);
  const result = await db.query(
    "INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING *",
    [req.body.email, hash]
  );
  await sendWelcomeEmail(result.rows[0].email);
  res.status(201).json(result.rows[0]);
});
```

```typescript
// GOOD: Each concern isolated
// Route: HTTP concern only
app.post("/users", validateRequest(createUserSchema), async (req, res) => {
  const user = await userService.create(req.body);
  res.status(201).json(user);
});

// Service: Business logic only
const userService = {
  async create(data: CreateUserInput): Promise<User> {
    await this.ensureUniqueEmail(data.email);
    const user = await userRepository.insert(data);
    await emailService.sendWelcome(user);
    return user;
  }
};

// Repository: Data access only
const userRepository = {
  insert: (data) => db.insert(users).values(data).returning()
};
```

### God Component

React components that fetch data, manage state, handle forms, render UI, AND contain business logic. Each concern should be its own hook or component.

### Cross-Cutting Spaghetti

Authentication checks scattered throughout code instead of handled by middleware. Logging inline instead of via aspect-oriented patterns.

## Connections

| Principle | Relationship |
|-----------|-------------|
| [Information Hiding](information-hiding.md) | SoC says *what* to separate; information hiding says *how to protect* each concern |
| [Conceptual Integrity](conceptual-integrity.md) | SoC within a system; conceptual integrity across the system |
| [Composition Over Inheritance](composition-over-inheritance.md) | Composition lets you assemble separated concerns |

## Key Insight

"Concern" isn't about code organization—it's about **reason for change**.

A module has one concern if it has one reason to change. A module has multiple concerns if it could change for multiple independent reasons.

Dijkstra's genius was recognizing that human cognition works best when focused on one thing at a time. Separation of concerns is a cognitive tool, not just an architectural pattern.
