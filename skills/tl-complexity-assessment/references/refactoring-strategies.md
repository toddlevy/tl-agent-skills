# Refactoring Strategies

How to split identified complexity hotspots safely and effectively.

## Pre-Refactoring Checklist

Before starting any split:

- [ ] Tests exist for current behavior
- [ ] Git working directory is clean
- [ ] IDE/editor supports safe refactoring
- [ ] Team is aware (avoid merge conflicts)
- [ ] Clear acceptance criteria defined

---

## Strategy 1: Extract Function

**When**: Logic is reusable or obscures the main flow.

**Before**:

```typescript
function processOrder(order: Order) {
  // 20 lines of validation
  if (!order.items.length) throw new Error('Empty order');
  if (order.total < 0) throw new Error('Invalid total');
  for (const item of order.items) {
    if (!item.productId) throw new Error('Missing product');
    if (item.quantity < 1) throw new Error('Invalid quantity');
  }
  
  // 30 lines of processing
  const subtotal = order.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const tax = subtotal * 0.1;
  const shipping = calculateShipping(order);
  const total = subtotal + tax + shipping;
  
  // Save and notify
  await db.orders.insert({ ...order, total });
  await sendConfirmation(order.customer);
}
```

**After**:

```typescript
function processOrder(order: Order) {
  validateOrder(order);
  const total = calculateOrderTotal(order);
  await saveAndNotify(order, total);
}

function validateOrder(order: Order): void {
  if (!order.items.length) throw new Error('Empty order');
  // ... validation logic
}

function calculateOrderTotal(order: Order): number {
  const subtotal = order.items.reduce(/*...*/);
  // ... calculation logic
  return total;
}
```

---

## Strategy 2: Extract Module

**When**: File has multiple unrelated responsibilities.

**Identification**: Look for comment "sections" or logical groupings.

**Before** (`utils.ts` - 500 lines):

```typescript
// ===== String Utilities =====
export function capitalize(s: string) { /*...*/ }
export function slugify(s: string) { /*...*/ }
export function truncate(s: string, len: number) { /*...*/ }

// ===== Date Utilities =====
export function formatDate(d: Date) { /*...*/ }
export function parseDate(s: string) { /*...*/ }
export function addDays(d: Date, n: number) { /*...*/ }

// ===== Array Utilities =====
export function chunk<T>(arr: T[], size: number) { /*...*/ }
export function unique<T>(arr: T[]) { /*...*/ }
```

**After** (folder structure):

```
utils/
  index.ts          # Re-exports
  string.ts         # String utilities
  date.ts           # Date utilities
  array.ts          # Array utilities
```

**Migration steps**:

1. Create new files with functions
2. Update `index.ts` to re-export
3. Run tests (should pass without import changes)
4. Optionally update imports to direct paths

---

## Strategy 3: Extract Component

**When**: React component handles multiple UI concerns.

**Identification**: Component renders distinct "sections" that could be independent.

**Before** (`Dashboard.tsx` - 400 lines):

```tsx
function Dashboard() {
  const [user, setUser] = useState();
  const [stats, setStats] = useState();
  const [notifications, setNotifications] = useState();
  
  // Effects for each concern
  useEffect(() => { /* fetch user */ }, []);
  useEffect(() => { /* fetch stats */ }, []);
  useEffect(() => { /* fetch notifications */ }, []);
  
  return (
    <div>
      <header>{/* 50 lines of user info */}</header>
      <main>
        <section>{/* 100 lines of stats */}</section>
        <aside>{/* 80 lines of notifications */}</aside>
      </main>
    </div>
  );
}
```

**After**:

```tsx
function Dashboard() {
  return (
    <div>
      <DashboardHeader />
      <main>
        <StatsPanel />
        <NotificationsSidebar />
      </main>
    </div>
  );
}

// Each component manages its own data
function DashboardHeader() {
  const { user } = useUser();
  return <header>...</header>;
}

function StatsPanel() {
  const { stats } = useStats();
  return <section>...</section>;
}
```

---

## Strategy 4: Extract Custom Hook

**When**: Component has complex state logic that obscures the UI.

**Before**:

```tsx
function ProductForm() {
  const [name, setName] = useState('');
  const [price, setPrice] = useState(0);
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  
  const validate = useCallback(() => {
    const errs = {};
    if (!name) errs.name = 'Required';
    if (price < 0) errs.price = 'Must be positive';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }, [name, price]);
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;
    setSubmitting(true);
    try {
      await api.createProduct({ name, price });
    } finally {
      setSubmitting(false);
    }
  };
  
  // 100 lines of JSX
}
```

**After**:

```tsx
function ProductForm() {
  const { 
    values, 
    errors, 
    submitting, 
    handleChange, 
    handleSubmit 
  } = useProductForm();
  
  return (
    <form onSubmit={handleSubmit}>
      <Input 
        value={values.name} 
        onChange={handleChange('name')}
        error={errors.name} 
      />
      {/* Clean, focused JSX */}
    </form>
  );
}

// hooks/useProductForm.ts
function useProductForm() {
  // All the complex logic lives here
}
```

---

## Strategy 5: Extract Service/Class

**When**: Logic needs to be shared across components or tested independently.

**Before** (logic scattered in components):

```tsx
// Component A
const filteredUsers = users
  .filter(u => u.active)
  .filter(u => u.role === selectedRole)
  .sort((a, b) => a.name.localeCompare(b.name));

// Component B (duplicate logic)
const filteredUsers = users
  .filter(u => u.active)
  .filter(u => u.department === dept)
  .sort((a, b) => a.name.localeCompare(b.name));
```

**After**:

```typescript
// services/user-filter.ts
export class UserFilter {
  constructor(private users: User[]) {}
  
  active() {
    return new UserFilter(this.users.filter(u => u.active));
  }
  
  byRole(role: string) {
    return new UserFilter(this.users.filter(u => u.role === role));
  }
  
  byDepartment(dept: string) {
    return new UserFilter(this.users.filter(u => u.department === dept));
  }
  
  sorted(field: keyof User = 'name') {
    return new UserFilter([...this.users].sort((a, b) => 
      String(a[field]).localeCompare(String(b[field]))
    ));
  }
  
  toArray() {
    return this.users;
  }
}

// Usage
const filtered = new UserFilter(users)
  .active()
  .byRole(selectedRole)
  .sorted()
  .toArray();
```

---

## Strategy 6: Vertical Slice

**When**: Feature code is spread across layers (components, hooks, api, types).

**Before** (horizontal layers):

```
components/
  UserList.tsx
  UserForm.tsx
  ProductList.tsx
  ProductForm.tsx
hooks/
  useUsers.ts
  useProducts.ts
api/
  users.ts
  products.ts
types/
  user.ts
  product.ts
```

**After** (vertical slices):

```
features/
  users/
    components/
      UserList.tsx
      UserForm.tsx
    hooks/
      useUsers.ts
    api.ts
    types.ts
    index.ts
  products/
    components/
      ProductList.tsx
      ProductForm.tsx
    hooks/
      useProducts.ts
    api.ts
    types.ts
    index.ts
```

**Benefits**:
- Feature changes touch one folder
- Easier to understand feature scope
- Better code ownership
- Simpler deletion when feature removed

---

## Safe Refactoring Process

### 1. Characterization Tests

If tests don't exist, add them before refactoring:

```typescript
// Capture current behavior
it('processes order correctly', () => {
  const order = createTestOrder();
  const result = processOrder(order);
  
  // Snapshot the result
  expect(result).toMatchSnapshot();
});
```

### 2. Small Commits

Each refactoring step should be its own commit:

```bash
git commit -m "extract: validateOrder function"
git commit -m "extract: calculateOrderTotal function"
git commit -m "extract: order-processing.ts module"
```

### 3. Verify After Each Step

```bash
npm test
npm run lint
npm run typecheck
```

### 4. Update Imports Gradually

Use IDE refactoring tools to update imports automatically, or:

```bash
# Find usages before moving
rg "from ['\"].*oldPath" --type ts

# After moving, update imports
# (IDE usually handles this)
```

---

## When NOT to Refactor

- **No tests**: Add tests first
- **Deadline pressure**: Schedule for after release
- **Unclear requirements**: Understand the domain first
- **Active development**: Coordinate with team
- **Working code**: "If it ain't broke, don't fix it" (unless blocking velocity)

---

## Measuring Success

After refactoring, verify:

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| File lines | 500 | <200 each | ✓ |
| Exports per file | 15 | <8 | ✓ |
| Test coverage | 40% | 80%+ | ✓ |
| Cyclomatic complexity | 25 | <10 | ✓ |
| Import count | 20 | <10 | ✓ |

Run complexity assessment after refactoring to confirm improvement.
