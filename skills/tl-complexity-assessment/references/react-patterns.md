# React Complexity Patterns

Detailed guidance for identifying and resolving React-specific complexity.

## Component Size Indicators

### Line Count Thresholds

| Lines | Assessment | Action |
|-------|------------|--------|
| <150 | Healthy | Monitor |
| 150-300 | Warning | Consider splitting |
| 300-500 | Problem | Plan refactor |
| >500 | Critical | Immediate action |

### What Inflates Component Size

1. **Inline styles** - Move to CSS/styled-components
2. **Inline handlers** - Extract to named functions
3. **Conditional rendering blocks** - Extract sub-components
4. **Data transformation** - Move to hooks or utils
5. **Form handling** - Use form libraries or custom hooks

---

## Hook Complexity

### useEffect Count

| Count | Assessment | Typical Cause |
|-------|------------|---------------|
| 0-1 | Healthy | Single concern |
| 2 | Acceptable | Related side effects |
| 3 | Warning | Multiple concerns |
| 4+ | Problem | God component |

### useEffect Red Flags

```tsx
// RED FLAG: Multiple unrelated effects
useEffect(() => { /* fetch user */ }, [userId]);
useEffect(() => { /* setup websocket */ }, []);
useEffect(() => { /* track analytics */ }, [page]);
useEffect(() => { /* sync form state */ }, [formData]);
```

**Solution**: Extract to custom hooks:

```tsx
const user = useUser(userId);
const socket = useWebSocket();
useAnalytics(page);
const form = useFormSync(formData);
```

### useState Count

| Count | Assessment | Action |
|-------|------------|--------|
| 0-3 | Healthy | - |
| 4-5 | Acceptable | Consider useReducer |
| 6-8 | Warning | Extract to custom hook |
| 9+ | Problem | State management needed |

**Pattern**: Related state should be grouped:

```tsx
// BEFORE: 6 useState calls
const [name, setName] = useState('');
const [email, setEmail] = useState('');
const [phone, setPhone] = useState('');
const [errors, setErrors] = useState({});
const [touched, setTouched] = useState({});
const [submitting, setSubmitting] = useState(false);

// AFTER: 1 custom hook
const form = useForm({ name: '', email: '', phone: '' });
```

---

## Inline Sub-Components

### Detection

```tsx
// RED FLAG: Component defined inside another component
function ParentComponent() {
  // This gets recreated every render
  const ChildComponent = ({ item }) => (
    <div>{item.name}</div>
  );
  
  return items.map(item => <ChildComponent item={item} />);
}
```

### Why It's Bad

1. Component recreated every render
2. Breaks React.memo optimizations
3. Loses component state on parent re-render
4. Harder to test in isolation

### Solution

```tsx
// Extract to module scope or separate file
const ItemCard = ({ item }) => (
  <div>{item.name}</div>
);

function ParentComponent() {
  return items.map(item => <ItemCard key={item.id} item={item} />);
}
```

---

## Props Complexity

### Prop Count Thresholds

| Count | Assessment | Action |
|-------|------------|--------|
| 1-4 | Healthy | - |
| 5-7 | Acceptable | Consider grouping |
| 8-10 | Warning | Refactor interface |
| 11+ | Problem | Component doing too much |

### Prop Drilling Depth

| Depth | Assessment | Solution |
|-------|------------|----------|
| 1-2 | Normal | Direct props |
| 3 | Acceptable | Consider context |
| 4+ | Problem | Use context or composition |

### Fixing Prop Explosion

**Pattern 1: Object Props**

```tsx
// BEFORE: 8 props
<UserCard 
  name={name}
  email={email}
  avatar={avatar}
  role={role}
  department={department}
  location={location}
  joinDate={joinDate}
  status={status}
/>

// AFTER: 1 prop
<UserCard user={user} />
```

**Pattern 2: Composition**

```tsx
// BEFORE: Props for every slot
<Card 
  header={<Header />}
  body={<Body />}
  footer={<Footer />}
  sidebar={<Sidebar />}
/>

// AFTER: Children composition
<Card>
  <Card.Header>...</Card.Header>
  <Card.Body>...</Card.Body>
  <Card.Footer>...</Card.Footer>
</Card>
```

---

## Page Component Anti-Patterns

### Business Logic in Pages

```tsx
// RED FLAG: Page doing data transformation
function UsersPage() {
  const [users, setUsers] = useState([]);
  const [sortField, setSortField] = useState('name');
  const [filterRole, setFilterRole] = useState('all');
  
  // Business logic in page component
  const filteredUsers = users
    .filter(u => filterRole === 'all' || u.role === filterRole)
    .sort((a, b) => a[sortField].localeCompare(b[sortField]));
  
  const activeCount = filteredUsers.filter(u => u.active).length;
  const adminCount = filteredUsers.filter(u => u.role === 'admin').length;
  
  // ...render
}
```

**Solution**: Extract to hooks and utilities:

```tsx
function UsersPage() {
  const { users, isLoading } = useUsers();
  const { filtered, sort, filter } = useUserFilters(users);
  const stats = useUserStats(filtered);
  
  return <UsersList users={filtered} stats={stats} />;
}
```

### Page as Orchestrator

Pages should:
- Compose components
- Connect to data sources
- Handle routing concerns
- Define layout

Pages should NOT:
- Transform data
- Contain business logic
- Define reusable UI
- Manage complex state

---

## Form Component Complexity

### Form Anti-Pattern

```tsx
// RED FLAG: Form doing everything
function ContactForm() {
  const [values, setValues] = useState({});
  const [errors, setErrors] = useState({});
  const [touched, setTouched] = useState({});
  const [submitting, setSubmitting] = useState(false);
  
  const validate = (field, value) => {
    // 50 lines of validation logic
  };
  
  const handleSubmit = async (e) => {
    // 30 lines of submission logic
  };
  
  const handleBlur = (field) => {
    // validation on blur
  };
  
  // 200 lines of JSX with inline validation messages
}
```

### Form Solution Patterns

**Option 1: Form Library**

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

function ContactForm() {
  const form = useForm({
    resolver: zodResolver(contactSchema),
  });
  
  return (
    <Form {...form} onSubmit={handleSubmit}>
      <FormField name="email" />
      <FormField name="message" />
    </Form>
  );
}
```

**Option 2: Custom Hook Extraction**

```tsx
function ContactForm() {
  const { fields, errors, handleSubmit, isSubmitting } = useContactForm();
  
  return (
    <form onSubmit={handleSubmit}>
      <Input {...fields.email} error={errors.email} />
      <TextArea {...fields.message} error={errors.message} />
      <Button loading={isSubmitting}>Send</Button>
    </form>
  );
}
```

---

## Detection Commands

### Find Components with Many Hooks

```bash
# Count useEffect per file
rg "useEffect\(" --type tsx -c | sort -t: -k2 -rn | head -20

# Count useState per file
rg "useState\(" --type tsx -c | sort -t: -k2 -rn | head -20

# Find files with both many useEffect AND useState
rg "use(Effect|State)\(" --type tsx -c | awk -F: '$2 > 5 {print}'
```

### Find Inline Components

```bash
# Look for const Component = inside functions
rg "const \w+ = \([^)]*\) =>" --type tsx -l
```

### Find Props Explosion

```bash
# Files with many prop destructuring
rg "^\s*\{[^}]{100,}\}" --type tsx -l
```

---

## Refactoring Checklist

Before splitting a React component:

- [ ] Identify distinct responsibilities
- [ ] Map state to responsibilities
- [ ] Identify shared state (needs lifting or context)
- [ ] Plan custom hooks for logic extraction
- [ ] Determine component boundaries
- [ ] Consider data flow after split
- [ ] Verify no prop drilling introduced
- [ ] Plan test coverage for new components
