# Knip Troubleshooting Guide

Systematic diagnosis for false positives, missed issues, performance problems, and CI failures.

---

## Diagnostic First Step

Before diving into specific issues, always start with:

```bash
npx knip --debug
```

This outputs:
- Resolved configuration (entry, project, ignore patterns)
- Detected plugins and their contributed entry points
- Path alias resolution
- File counts

Read the configuration hints at the top of normal output too — these call out the most common problems.

---

## False Positives

### Everything is flagged as unused

**Cause:** Entry points misconfigured. Knip doesn't know where your app starts.

**Diagnosis:**
```bash
npx knip --debug 2>&1 | findstr "entry"
```

**Fix:** Add your actual entry points:
```json
{
  "entry": ["src/index.ts", "src/server.ts", "scripts/**/*.ts"]
}
```

---

### A config file is flagged as unused (e.g. `vite.config.ts`)

**Cause:** The corresponding plugin wasn't detected.

**Fix:** Explicitly enable the plugin:
```json
{
  "vite": {}
}
```

Or check that your config file is in the project root (not a subdirectory).

---

### All exports from a barrel file are flagged

**Cause:** Path aliases not configured, so Knip can't resolve imports through the barrel.

**Diagnosis:**
```bash
npx knip --trace-export MyComponent
```

**Fix:** Add path aliases matching `tsconfig.json`:
```json
{
  "paths": {
    "@/*": ["src/*"],
    "~/*": ["app/*"]
  }
}
```

See [barrel-files.md](barrel-files.md) for detailed barrel troubleshooting.

---

### Exported types are flagged despite being used

**Cause:** Types consumed only within the same file as the definition.

**Fix:**
```json
{
  "ignoreExportsUsedInFile": {
    "interface": true,
    "type": true
  }
}
```

---

### A dependency is flagged but it IS used

**Common reasons:**

| Reason | Fix |
|--------|-----|
| Used as CLI tool in `package.json` scripts | Add to `ignoreBinaries` |
| Used as peer dependency | Add to `ignoreDependencies` |
| Used only in type imports | Add to `ignoreDependencies` if `@types/` package |
| Used via dynamic `require()` | Add to `ignoreDependencies` or ensure it's in `project` |
| Imported with path alias Knip can't resolve | Add `paths` to config |

```json
{
  "ignoreDependencies": ["my-cli-tool", "@types/node"],
  "ignoreBinaries": ["my-cli-tool"]
}
```

---

### Test files flagging production imports as unused

**Cause:** Test files reference code that's only used in tests.

**Fix:** Use `--production` for production-only checks. Don't use `ignore` to hide test files.

```bash
npx knip --production
```

---

### Dynamic imports not tracked

Knip can't statically analyze `require(variable)` or `import(expression)` where the path is computed at runtime.

**Fix:** Add dynamically-imported files to `entry`:
```json
{
  "entry": [
    "src/index.ts",
    "src/plugins/**/*.ts"
  ]
}
```

---

## False Negatives (Missing Issues)

### Knip isn't finding real dead code

**Possible causes:**

1. `ignore` patterns too broad — hiding real issues
2. `ignoreDependencies` suppressing packages that are actually unused
3. Entry points too broad — too many files treated as roots

**Diagnosis:** Review your config for over-suppression. Run without config first:
```bash
npx knip --config /dev/null
```
(Windows: temporarily rename `knip.json` to see baseline)

---

## Monorepo Issues

### Only root workspace is analyzed

**Fix:** Ensure workspaces are configured:
```json
{
  "workspaces": {
    ".": {},
    "packages/*": {}
  }
}
```

Or use glob patterns matching your workspace structure.

---

### Cross-workspace imports flagged as unused

**Cause:** Knip treats workspace packages as external if they're not linked correctly.

**Fix:** Ensure workspace packages are linked in `node_modules` (run `npm install` at root). For pnpm, ensure `shamefully-hoist` or workspace protocol is correctly configured.

---

### Wrong workspace analyzed

```bash
# Scope to a specific workspace
npx knip --workspace packages/web
```

---

### Plugin not detected in workspace

Configure plugins per workspace:
```json
{
  "workspaces": {
    "packages/web": {
      "next": {}
    }
  }
}
```

---

## CI Failures

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | No issues found |
| `1` | Issues found (expected failure) |
| `2` | Unexpected error (config problem, file not found) |

Exit code `2` almost always means a configuration error:
- `knip.json` has a syntax error
- Referenced file in config doesn't exist
- Plugin config references unknown option

**Diagnosis:**
```bash
npx knip --debug
```

---

### CI passes locally but fails in CI

**Common causes:**

| Cause | Fix |
|-------|-----|
| Different Node.js version | Pin Node version in CI |
| `node_modules` not installed | Ensure `npm ci` runs before Knip |
| Local config file vs CI config file differ | Check for `.knip.local.json` or env-specific configs |
| Symlinks not followed in CI | Check monorepo workspace linking |

---

### Too many issues in CI, gradual adoption needed

Use `--max-issues` to set a threshold:
```bash
npx knip --dependencies --max-issues 5
```

Reduce the threshold over time as you clean up.

---

## Performance

### Analysis is slow

```bash
# Scope to one workspace
npx knip --workspace packages/web

# Check only one issue type
npx knip --dependencies

# Increase memory
$env:NODE_OPTIONS = "--max-old-space-size=4096"
npx knip
```

### Large codebase taking minutes

```bash
# Filter to specific issue types
npx knip --include exports,dependencies

# Use cache (experimental)
npx knip --cache
```

---

## Specific Error Messages

### `Cannot find module 'X'`

Knip encountered an import it can't resolve.

**Fixes:**
1. Add `paths` to match your `tsconfig.json`
2. Add the package to `ignoreDependencies` if it's optional/conditional
3. Check that the package is installed (`npm install`)

---

### `error loading file: X`

Config file has a syntax or runtime error.

**Fix:** Validate `knip.json` syntax. If using `knip.ts`, ensure it compiles cleanly.

---

### `No workspaces found`

Your workspace glob patterns don't match any directories.

**Fix:** Check that `workspaces` globs match actual directory names:
```json
{
  "workspaces": {
    "apps/*": {},
    "packages/*": {}
  }
}
```

---

### Sink worker / partition instability (not a Knip issue)

If you see messages about Kafka partitions or sink workers while using Knip — you've hit a separate infrastructure issue. See `tl-openmeter-api` for OpenMeter/Kafka troubleshooting.

---

## Quick Diagnostic Checklist

```
□ Read configuration hints at top of npx knip output
□ Run npx knip --debug to see resolved config
□ Check path aliases match tsconfig.json
□ Check entry points include all app roots
□ Check plugins are detected (or explicitly enabled)
□ Verify node_modules is fully installed
□ Trace specific issues with --trace-file or --trace-export
□ Review ignore* settings for over-suppression
```
