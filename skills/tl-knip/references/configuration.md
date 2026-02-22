# Knip Configuration Reference

Complete reference for `knip.json` / `knip.ts` configuration options.

---

## Schema

Always include the schema reference for editor autocomplete and validation:

```json
{
  "$schema": "https://unpkg.com/knip@latest/schema.json"
}
```

---

## Entry Points (`entry`)

Tells Knip where your application starts. Everything reachable from entry points is considered "used."

```json
{
  "entry": [
    "src/index.ts",
    "src/cli.ts",
    "scripts/**/*.ts",
    "app/**/{page,layout,route}.tsx"
  ]
}
```

**Rules:**
- Use glob patterns — Knip uses micromatch syntax
- Include ALL application roots: CLI entrypoints, server entrypoints, worker files
- Do NOT include test files here — they're handled by test runner plugins or `--production` exclusion
- Framework plugins (Next.js, Vite, etc.) automatically add their own entry points — don't duplicate them

**Debugging entry points:**

```bash
npx knip --debug 2>&1 | grep "entry"
```

---

## Project Files (`project`)

The full set of files Knip should analyze. Defaults to all `.ts`/`.tsx`/`.js` files.

```json
{
  "project": [
    "src/**/*.{ts,tsx}",
    "scripts/**/*.ts",
    "!src/**/*.test.ts"
  ]
}
```

Use negation patterns (`!`) to exclude specific files from analysis.

---

## Ignore Patterns (`ignore`)

**Use sparingly — prefer other options.** `ignore` completely hides files from Knip and masks real issues.

Legitimate uses:
- Generated files (GraphQL schema, protobuf output, build artifacts)
- Vendor code checked into the repo
- Legacy directories intentionally excluded from cleanup

```json
{
  "ignore": [
    "src/generated/**",
    "src/vendor/**"
  ]
}
```

**Never use `ignore` to hide test files** — use `--production` instead.
**Never use `ignore` to suppress false positives** — fix the root cause in config.

---

## Ignore Dependencies (`ignoreDependencies`)

Suppress specific npm packages from the unused dependency report.

```json
{
  "ignoreDependencies": [
    "@types/*",
    "typescript",
    "tslib",
    "some-cli-tool"
  ]
}
```

**Common candidates:**
| Package | Why |
|---------|-----|
| `@types/*` | Type-only, no runtime import needed |
| `typescript` | Used implicitly by build tools |
| `tslib` | TypeScript helper, injected by compiler |
| `eslint`, `prettier` | CLI tools, not imported in code |
| `@biomejs/biome` | CLI tool |
| Peer dependencies | Required by dependents but not directly imported |

Supports glob patterns: `"@types/*"` matches all `@types/` packages.

---

## Ignore Exports Used in File (`ignoreExportsUsedInFile`)

Suppress exports that are only used within the same file they're defined in.

```json
{
  "ignoreExportsUsedInFile": true
}
```

Or selectively by type:

```json
{
  "ignoreExportsUsedInFile": {
    "interface": true,
    "type": true,
    "enum": false,
    "function": false
  }
}
```

**Recommendation:** Use `{ "interface": true, "type": true }` as a baseline. This eliminates the most common false positives (types used only internally in the same file) without hiding real dead code in functions and classes.

---

## Ignore Binaries (`ignoreBinaries`)

Suppress binaries used in `package.json` scripts that Knip can't auto-detect.

```json
{
  "ignoreBinaries": [
    "npm-check-updates",
    "semantic-release",
    "your-custom-cli"
  ]
}
```

---

## Include Entry Exports (`includeEntryExports`)

By default, Knip does not report exports from entry files as unused — they're assumed to be your public API. Set this to `true` to check them too.

```json
{
  "includeEntryExports": true
}
```

Useful for: private packages, internal tools, monorepo packages that should have clean exports.

---

## Path Aliases (`paths`)

Configure path aliases matching your `tsconfig.json` `paths` field.

```json
{
  "paths": {
    "@/*": ["src/*"],
    "~/*": ["app/*"],
    "@components/*": ["src/components/*"]
  }
}
```

Without this, Knip can't resolve aliased imports and will flag dependencies as unused.

---

## Plugin Configuration

Enable, disable, or override plugin settings:

```json
{
  "eslint": false,
  "prettier": false,
  "vite": {
    "entry": ["vite.config.ts", "src/worker.ts"],
    "config": ["vite.config.ts"]
  },
  "vitest": {
    "entry": ["vitest.config.ts", "test/setup.ts"]
  }
}
```

**When to disable a plugin:**
- The plugin adds incorrect entry points for your setup
- The plugin itself causes false positives

**When to override a plugin:**
- You have non-standard config file names
- You have additional entry points beyond what the plugin detects

---

## Workspace Configuration (Monorepos)

```json
{
  "workspaces": {
    ".": {
      "entry": ["scripts/**/*.ts"],
      "ignoreDependencies": ["turbo"]
    },
    "packages/web": {
      "entry": ["src/index.ts", "src/App.tsx"],
      "ignoreDependencies": ["react", "react-dom"]
    },
    "packages/api": {
      "entry": ["src/server.ts"],
      "ignoreDependencies": ["fastify"]
    },
    "packages/shared": {
      "entry": ["src/index.ts"],
      "includeEntryExports": true
    }
  }
}
```

**Workspace rules:**
- Root workspace (`.`) handles scripts, CI, and cross-workspace tooling
- Each package workspace gets its own `entry` array
- Shared packages should use `includeEntryExports: true` to check their public API
- Cross-workspace dependencies are resolved automatically if packages are linked

---

## TypeScript Config (`knip.ts`)

Use TypeScript for full type safety and dynamic configuration:

```typescript
import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  entry: ['src/index.ts', 'src/cli.ts'],
  project: ['src/**/*.{ts,tsx}'],
  ignoreDependencies: ['@types/*', 'typescript'],
  ignoreExportsUsedInFile: {
    interface: true,
    type: true,
  },
  workspaces: {
    '.': { entry: ['scripts/**/*.ts'] },
    'packages/*': { entry: ['src/index.ts'] },
  },
};

export default config;
```

---

## Production Mode

`--production` tells Knip to analyze only production code:

- Excludes test files and test runner entry points
- Excludes `devDependencies` from the dependency check
- Focuses only on what ships in production

```bash
npx knip --production
```

Use `--production` in pre-release audits and CI pipelines where you only care about shipping clean code.

---

## Max Issues (`--max-issues`)

Allow a specific number of issues before failing. Useful for gradual adoption:

```bash
npx knip --max-issues 10     # Fail only if > 10 issues
npx knip --max-issues 0      # Zero tolerance (strict)
```

---

## Reporters

```bash
npx knip                          # Default (human-readable)
npx knip --reporter compact       # One line per issue
npx knip --reporter json          # Machine-readable JSON
npx knip --reporter github-actions # GitHub Actions annotations
```

JSON output schema:

```json
{
  "files": ["src/orphan.ts"],
  "dependencies": { "lodash": ["package.json"] },
  "devDependencies": {},
  "exports": {
    "src/utils.ts": [{ "name": "unusedFn", "line": 42, "col": 17 }]
  },
  "types": {},
  "enumMembers": {},
  "classMembers": {},
  "duplicates": []
}
```
