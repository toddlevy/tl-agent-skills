# Barrel Files & Re-export Handling

Barrel files are the most common source of Knip false positives. Understanding how Knip tracks re-exports is essential for accurate dead code detection in any project that uses index.ts patterns.

---

## What Is a Barrel File?

A barrel file (usually `index.ts`) re-exports from multiple modules to provide a clean public API:

```typescript
// src/components/index.ts
export { Button } from './Button';
export { Input } from './Input';
export { Modal } from './Modal';
export type { ButtonProps } from './Button';
```

Consumers import from the barrel instead of individual files:

```typescript
import { Button, Input } from '@/components';
```

---

## How Knip Analyzes Barrels

Knip traces the full module graph. For each export in a barrel, it checks:

1. Is this export imported by any other file in the project?
2. If the barrel is an entry point, are these exports part of the public API?

**The false positive trap:** If `Button` is exported from `src/components/index.ts` but only used within `src/components/` itself (e.g., in a `ComponentShowcase.tsx`), Knip may still flag it as unused if no external file imports it from the barrel.

---

## Common Barrel File Scenarios

### Scenario 1: Public library / package boundary

Your `src/index.ts` is the public API of a package. All exports should be considered "used" even if internal consumers reference the same barrel.

**Fix:** Add `includeEntryExports: true` to have Knip check these — or set it to `false` (default) to skip checking entry file exports entirely.

```json
{
  "entry": ["src/index.ts"],
  "includeEntryExports": false
}
```

Default behavior (`false`) means entry file exports are assumed public and not flagged. This is correct for libraries.

### Scenario 2: Internal barrel used for organization only

```
src/utils/
  index.ts      ← re-exports date.ts, string.ts, number.ts
  date.ts
  string.ts
  number.ts
```

If `src/utils/index.ts` is not in your `entry` array, Knip tracks whether each re-export is actually consumed outside `src/utils/`. Unused ones are flagged.

**Fix options:**

1. Add the barrel to `entry` if it's a real module boundary
2. Use `ignoreExportsUsedInFile` if exports are consumed within the same directory
3. Remove the barrel and import directly from source files

### Scenario 3: Re-exporting types

```typescript
// src/types/index.ts
export type { User } from './user';
export type { Event } from './event';
```

Types are often used only in the same codebase and Knip may flag them if the consumer imports them differently.

**Fix:**

```json
{
  "ignoreExportsUsedInFile": {
    "interface": true,
    "type": true
  }
}
```

### Scenario 4: Everything in a barrel is flagged

Symptom: Running Knip reports every export from `src/index.ts` as unused.

**Diagnosis:**
1. Is `src/index.ts` in your `entry` array?
2. Are there external consumers (tests, other packages) that import from it?
3. Is the barrel imported via a path alias that Knip can't resolve?

**Fix path alias resolution:**

```json
{
  "paths": {
    "@/*": ["src/*"]
  }
}
```

---

## Tagging Public API Exports

Use JSDoc `@public` to tag exports that are intentionally part of your public API. Knip respects this annotation and will not flag tagged exports as unused.

```typescript
/**
 * Primary button component.
 * @public
 */
export const Button = ({ children }: ButtonProps) => {
  return <button>{children}</button>;
};
```

This is the cleanest long-term solution for library code — makes your public API explicit and machine-readable.

---

## Inline Suppression

For one-off cases where an export must stay but Knip flags it:

```typescript
// @knip-ignore-export
export const unusedButRequired = () => {};
```

Use sparingly. Prefer fixing configuration over adding suppressions.

---

## Handling Re-exports in Configuration

### Allow re-exports to pass through without flagging consumers

```json
{
  "ignoreExportsUsedInFile": true
}
```

This broadly ignores whether exports are used in the same file they're defined in — useful if your barrel pattern collapses many files' exports into one.

### Exclude entire barrel directories from export checking

```json
{
  "ignore": ["src/legacy/index.ts"]
}
```

Use only for intentionally frozen code.

### Check a barrel's exports strictly (library mode)

```json
{
  "entry": ["src/index.ts"],
  "includeEntryExports": true
}
```

This tells Knip to check even entry file exports. Every export in `src/index.ts` that nothing imports will be flagged. Use for strict library API hygiene.

---

## Debugging Barrel Issues

```bash
# Trace why a specific export is flagged
npx knip --trace-export MyComponent

# Trace why a file is included or excluded
npx knip --trace-file src/components/index.ts

# Show all resolved entry points
npx knip --debug 2>&1 | Select-String "entry"
```

The `--trace-export` command shows the full import chain (or lack thereof) that led to the export being flagged. This is the fastest way to diagnose barrel false positives.

---

## Decision Matrix

| Situation | Solution |
|-----------|----------|
| Library entry `index.ts` — exports are public API | `includeEntryExports: false` (default) or `@public` JSDoc |
| Internal barrel — some exports genuinely unused | Fix by removing unused exports |
| Internal barrel — all exports used but Knip disagrees | Check path alias config, use `--trace-export` |
| Type-only barrel flagging types | `ignoreExportsUsedInFile: { interface: true, type: true }` |
| Everything in barrel flagged | Path alias misconfigured — add `paths` to knip config |
| Legacy barrel, don't want to touch it | `ignore` the specific file |
