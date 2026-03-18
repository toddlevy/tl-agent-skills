# Explicit Over Implicit

> "Explicit is better than implicit."
> — Tim Peters, The Zen of Python, 1999

## The Principle

**Make behavior, dependencies, and intent visible in the code. Prefer clarity over cleverness, verbosity over magic.**

Implicit behavior requires knowledge not present in the code. Explicit behavior is self-documenting.

## Lineage

| Who | When | Work |
|-----|------|------|
| Tim Peters | 1999 | PEP 20 - The Zen of Python |
| Multiple | Ongoing | Readability movement, code review culture |

The Zen of Python codified principles the Python community valued. "Explicit is better than implicit" became a rallying cry against "clever" code that obscures intent.

The principle predates Peters—it's implicit (ironically) in structured programming, information hiding, and good naming practices. But the Zen gave it a memorable formulation.

## Why It Endures

Code is read far more than it's written. Every implicit element:

- **Requires context** — reader must know something not in the code
- **Hides dependencies** — changes may have invisible effects
- **Assumes knowledge** — new team members struggle
- **Breaks grep** — can't find where things are used

Explicit code trades brevity for clarity. The trade is almost always worth it.

## Modern Manifestations

| Implicit (Avoid) | Explicit (Prefer) |
|------------------|-------------------|
| Default exports | Named exports |
| Ambient types | Explicit imports |
| Global state | Dependency injection |
| Convention-based routing | Explicit route definitions |
| Implicit returns | Explicit return statements |
| Magic strings | Typed constants/enums |
| `any` type | Specific types |

## The Test

Ask: **"Can someone understand this code without reading other files or knowing project conventions?"**

If yes: explicit.

If no: implicit. Consider making it explicit.

## Anti-Patterns

### Magic Strings

```typescript
// BAD: String meaning is implicit
if (user.role === "admin") { }
await emitter.emit("user.created", user);
config.get("database.host");

// GOOD: Explicit constants
if (user.role === UserRole.Admin) { }
await emitter.emit(UserEvents.Created, user);
config.database.host;  // Typed config object
```

### Implicit Dependencies

```typescript
// BAD: Depends on global, invisible in signature
function getUsers() {
  return db.query("SELECT * FROM users");  // Where does `db` come from?
}

// GOOD: Dependencies in signature
function getUsers(db: Database) {
  return db.query("SELECT * FROM users");
}
```

### Convention Over Clarity

```typescript
// BAD: Behavior depends on file location
// routes/users/[id].ts → GET /users/:id (magic!)

// GOOD: Explicit route definition
router.get("/users/:id", getUserById);
```

### Abbreviated Names

```typescript
// BAD: Requires context to understand
const cfg = getCfg();
const usr = await getUsr(uid);
const btn = createBtn(lbl);

// GOOD: Self-documenting names
const config = getConfig();
const user = await getUser(userId);
const button = createButton(label);
```

## When Implicit Is Acceptable

| Context | Why It's OK |
|---------|-------------|
| **Well-known conventions** | `i` for loop index, `e` for event |
| **Language idioms** | Python's `self`, JS arrow function `this` |
| **Framework patterns** | React's hook rules, Express middleware signature |
| **Domain-specific** | When the team shares context |

The key: implicit is OK when the reader can reasonably be expected to know. It's not OK when it requires tribal knowledge or lucky guessing.

## Explicit Doesn't Mean Verbose

Explicitness isn't about line count—it's about clarity:

```typescript
// Verbose but not explicit (comments explain what code should show)
// Get the user from the database using their ID
const result = await db.query("SELECT * FROM users WHERE id = $1", [id]);
// Extract the first row from the result
const user = result.rows[0];

// Explicit and concise
const user = await userRepository.findById(id);
```

Good naming, good types, and good structure make code explicit without excessive verbosity.

## Connections

| Principle | Relationship |
|-----------|-------------|
| [Conceptual Integrity](conceptual-integrity.md) | Explicit patterns are learnable; integrity makes them predictable |
| [Fail Fast](fail-fast.md) | Explicit errors are actionable; implicit failures hide |
| [Single Source of Truth](single-source-of-truth.md) | Explicit references to SSOT; no implicit copies |

## Key Insight

"Explicit is better than implicit" is really about **audience**. Implicit code is written for the author who knows the context. Explicit code is written for the reader who doesn't.

The reader is often future-you, who has forgotten the context. Writing explicitly is a gift to your future self and your team.

The Zen of Python also says "readability counts." Explicitness is the mechanism; readability is the goal.
