# Coupling Analysis

Techniques for analyzing and reducing coupling in TypeScript/JavaScript codebases.

## Import Analysis

### Import Count Thresholds

| Imports | Assessment | Indicates |
|---------|------------|-----------|
| 1-5 | Healthy | Focused module |
| 6-10 | Acceptable | Normal complexity |
| 11-15 | Warning | Potential orchestrator |
| 16-20 | Problem | Too many concerns |
| 21+ | Critical | God module |

### Cross-Domain Import Detection

A module importing from many unrelated domains signals mixed concerns.

**Domain identification** - Group imports by top-level directory:

```typescript
// imports from 4 different domains - WARNING
import { User } from '@/features/users';      // domain: users
import { Product } from '@/features/products'; // domain: products  
import { Order } from '@/features/orders';     // domain: orders
import { sendEmail } from '@/services/email';  // domain: services
```

**Acceptable cross-domain patterns:**
- Pages importing from multiple feature domains
- Shared utilities imported everywhere
- Infrastructure code (logging, analytics)

**Problematic cross-domain patterns:**
- Feature module importing from unrelated features
- Service importing from multiple feature domains
- Utility importing from feature domains (inverted dependency)

---

## Circular Dependencies

### Why They're Critical

1. Unpredictable module initialization order
2. Partial module evaluation bugs
3. Memory leaks in hot reload
4. Build tool confusion
5. Testing isolation failures

### Detection Commands

```bash
# Using madge (install: npm i -g madge)
madge --circular src/

# Using dpdm (install: npm i -g dpdm)
dpdm --circular src/index.ts

# Manual check with TypeScript compiler
tsc --listFiles | xargs -I {} sh -c 'echo "=== {} ===" && rg "from ['\''\"](\.\.?/)" {}'
```

### Common Circular Patterns

**Pattern 1: Feature ↔ Shared**

```
features/users/index.ts → shared/utils.ts → features/users/types.ts
```

**Solution**: Move shared types to shared module:

```
shared/types/user.ts ← features/users/index.ts
                     ← shared/utils.ts
```

**Pattern 2: Parent ↔ Child Components**

```
components/Form.tsx → components/FormField.tsx → components/Form.tsx
```

**Solution**: Extract shared context:

```
components/FormContext.tsx ← components/Form.tsx
                           ← components/FormField.tsx
```

**Pattern 3: Service ↔ Service**

```
services/auth.ts → services/api.ts → services/auth.ts
```

**Solution**: Extract shared dependency or use dependency injection:

```
services/http-client.ts ← services/auth.ts
                        ← services/api.ts
```

---

## Afferent & Efferent Coupling

### Definitions

- **Afferent (Ca)**: How many modules depend on this one (incoming arrows)
- **Efferent (Ce)**: How many modules this one depends on (outgoing arrows)

### Coupling Metrics

| Ca | Ce | Module Type | Stability |
|----|----| ------------|-----------|
| High | Low | Abstract/Interface | Stable (hard to change) |
| Low | High | Implementation | Unstable (easy to change) |
| High | High | Hub/God module | Problem (everything depends on everything) |
| Low | Low | Leaf | Isolated (safe to change) |

### Identifying Hubs

```bash
# Find most imported files (high Ca)
rg "from ['\"]\.\.?/.*['\"]" --type ts -o | \
  sed "s/from ['\"]//;s/['\"]$//" | \
  sort | uniq -c | sort -rn | head -20

# Find files with most imports (high Ce)
rg "^import " --type ts -c | sort -t: -k2 -rn | head -20
```

### Hub Remediation

When a file has both high Ca and Ce:

1. **Split by responsibility** - Create focused modules
2. **Extract interfaces** - Depend on abstractions
3. **Introduce facade** - Single entry point to subsystem
4. **Apply dependency inversion** - High-level shouldn't depend on low-level

---

## Dependency Direction

### The Dependency Rule

Dependencies should point inward toward stable abstractions:

```
UI Components → Features → Domain → Core
     ↓             ↓          ↓       ↓
(unstable)                        (stable)
```

### Detecting Violations

```bash
# Core importing from features (BAD)
rg "from ['\"].*features" core/ --type ts

# Domain importing from UI (BAD)  
rg "from ['\"].*components" domain/ --type ts

# Infrastructure importing from features (BAD)
rg "from ['\"].*features" infrastructure/ --type ts
```

### Fixing Direction Violations

**Before** (domain depends on infrastructure):

```typescript
// domain/user.ts
import { sendEmail } from '@/infrastructure/email';

export function createUser(data: UserData) {
  const user = new User(data);
  sendEmail(user.email, 'Welcome!');  // Coupling to infrastructure
  return user;
}
```

**After** (dependency inversion):

```typescript
// domain/user.ts
export interface NotificationService {
  notify(email: string, message: string): Promise<void>;
}

export function createUser(
  data: UserData, 
  notifier: NotificationService
) {
  const user = new User(data);
  notifier.notify(user.email, 'Welcome!');
  return user;
}

// infrastructure/email-notifier.ts
export class EmailNotifier implements NotificationService {
  async notify(email: string, message: string) {
    await sendEmail(email, message);
  }
}
```

---

## Barrel File Analysis

### Barrel File Thresholds

| Re-exports | Assessment | Action |
|------------|------------|--------|
| 1-10 | Healthy | - |
| 11-25 | Acceptable | Monitor |
| 26-50 | Warning | Consider splitting |
| 51+ | Problem | Barrel bloat |

### Barrel Bloat Detection

```bash
# Count exports in index files
rg "^export" --type ts -g "index.ts" -c | sort -t: -k2 -rn

# Find re-export chains
rg "export \* from" --type ts -l
```

### Barrel Splitting Strategy

**Before** (one mega-barrel):

```typescript
// components/index.ts - 50+ exports
export * from './Button';
export * from './Input';
export * from './Modal';
// ... 47 more
```

**After** (categorical barrels):

```typescript
// components/index.ts
export * from './forms';
export * from './layout';
export * from './feedback';

// components/forms/index.ts
export * from './Button';
export * from './Input';
export * from './Select';
```

---

## Practical Analysis Workflow

### Step 1: Generate Dependency Graph

```bash
# Visual graph (requires graphviz)
madge --image deps.svg src/

# Text output
madge --json src/ > deps.json
```

### Step 2: Identify Hotspots

Look for:
- Nodes with many incoming edges (high Ca)
- Nodes with many outgoing edges (high Ce)  
- Bidirectional edges (circular)
- Cross-layer edges (architectural violations)

### Step 3: Prioritize Fixes

| Issue | Priority | Effort |
|-------|----------|--------|
| Circular dependency | Critical | Medium |
| Layer violation | High | Low-Medium |
| Hub with high Ca+Ce | High | High |
| Barrel bloat | Medium | Low |

### Step 4: Incremental Refactoring

1. Add dependency lint rules to prevent new violations
2. Fix critical (circular) first
3. Extract interfaces for high-Ca modules
4. Split high-Ce modules by responsibility
5. Review barrel file organization

---

## Tooling Reference

| Tool | Purpose | Install |
|------|---------|---------|
| madge | Dependency graphs, circular detection | `npm i -g madge` |
| dpdm | Circular dependency detection | `npm i -g dpdm` |
| dependency-cruiser | Dependency rules/validation | `npm i -D dependency-cruiser` |
| knip | Unused exports/dependencies | `npm i -D knip` |

### dependency-cruiser Rules Example

```javascript
// .dependency-cruiser.js
module.exports = {
  forbidden: [
    {
      name: 'no-circular',
      severity: 'error',
      from: {},
      to: { circular: true }
    },
    {
      name: 'no-domain-to-ui',
      severity: 'error',
      from: { path: '^src/domain' },
      to: { path: '^src/components' }
    }
  ]
};
```
