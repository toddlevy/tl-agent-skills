---
name: tl-knip
description: Find and remove unused files, dependencies, and exports in TypeScript/JavaScript projects using Knip. Covers configuration-first workflow, plugin system, CI integration, monorepo support, agent-specific auto-delete guidance, and troubleshooting.
license: MIT
compatibility: TypeScript, JavaScript, monorepos. Node.js 18+.
metadata:
  author: tl-agent-skills
  version: "1.0"
  suite: tl-knip
quilted:
  version: 1
  synthesized: 2026-02-22
  platform: tl-agent-skills (manual synthesis)
  sources:
    - url: https://skills.sh/brianlovin/claude-config/knip
      borrowed:
        - Configuration-first workflow (Step 1–6 ordering)
        - "Never use ignore patterns" rule
        - ignoreExportsUsedInFile for types guidance
        - Production mode vs --production flag preference
      weight: 0.35
    - url: https://skills.sh/laurigates/claude-plugins/knip-dead-code-detection
      borrowed:
        - Framework plugin detection table
        - Test runner plugin table
        - CI/CD YAML examples
        - Inline @knip-ignore comment technique
        - Troubleshooting section structure
      weight: 0.30
    - url: https://skills.sh/artivilla/agents-config/knip
      borrowed:
        - Auto-delete vs ask-first confidence categorization
        - Re-run loop workflow for agent execution
      weight: 0.20
    - url: https://skills.sh/knoopx/pi/knip
      borrowed:
        - Concise quick command reference structure
        - --trace-file and --trace-export debug commands
      weight: 0.10
    - url: https://skills.sh/pproenca/dot-skills/knip-deadcode-best-practices
      borrowed:
        - 8-category rule priority framework (used as organizing model)
      weight: 0.05
---

# Knip: Dead Code Detection & Removal

Find and remove unused files, dependencies, and exports from TypeScript/JavaScript projects.

**What Knip detects:**
- Unused files (not imported anywhere)
- Unused npm dependencies and devDependencies
- Unused exports, types, enum members, and class members
- Duplicate re-exports

## When to Use

- Running a cleanup pass on an existing codebase
- Pre-release audit to eliminate dead code
- Enforcing dependency hygiene in CI
- Identifying orphaned files after refactors

---

## Quick Commands

```bash
npx knip                          # Full analysis
npx knip --production             # Production code only (no tests/devDeps)
npx knip --dependencies           # Only unused deps (fastest)
npx knip --exports                # Only unused exports
npx knip --files                  # Only unused files
npx knip --fix                    # Auto-remove safe issues
npx knip --fix --allow-remove-files  # Auto-remove including files
npx knip --reporter json          # JSON output for tooling
npx knip --reporter compact       # Compact output
npx knip --workspace packages/api # Specific workspace
```

**Debugging:**

```bash
npx knip --debug                  # Full debug output
npx knip --trace-file src/utils.ts    # Trace why file is included/excluded
npx knip --trace-export myFunction    # Trace why export is flagged
```

---

## Configuration-First Workflow

Always configure before acting on issues. Fixing configuration eliminates false positives and prevents churn.

### Step 1: Understand the project

- Check `package.json` for frameworks and tools in use
- Check for existing knip config (`knip.json`, `knip.jsonc`, `knip.ts`, or `knip` key in `package.json`)
- If config exists, review it before running

### Step 2: Run and read configuration hints first

```bash
npx knip
```

**Configuration hints appear at the top of output.** Address these before touching reported issues.

### Step 3: Adjust `knip.json` to eliminate false positives

Common adjustments:
- Enable/disable plugins for detected frameworks
- Add `paths` aliases matching `tsconfig.json`
- Add `entry` patterns for non-standard entry points
- Add `ignoreExportsUsedInFile` for types-only files

### Step 4: Repeat steps 2–3

Re-run after each config change until hints are resolved and false positives are minimal.

### Step 5: Address actual issues (priority order)

1. **Unused files** — address first; removing files exposes more unused exports
2. **Unused dependencies** — remove from `package.json`
3. **Unused devDependencies** — remove from `package.json`
4. **Unused exports** — remove export keyword or delete function
5. **Unused types** — remove, or add `ignoreExportsUsedInFile`

### Step 6: Re-run and repeat

After each batch of fixes, re-run. Removing files exposes newly-unused exports. Repeat until clean.

---

## Configuration Reference

### Recommended `knip.json`

```json
{
  "$schema": "https://unpkg.com/knip@latest/schema.json",
  "entry": ["src/index.ts", "src/cli.ts", "scripts/**/*.ts"],
  "project": ["src/**/*.{ts,tsx}", "scripts/**/*.ts"],
  "ignoreDependencies": ["@types/*", "typescript", "tslib"],
  "ignoreExportsUsedInFile": {
    "interface": true,
    "type": true
  }
}
```

### Critical Rules

| Rule | Rationale |
|------|-----------|
| **Never use `ignore` patterns** | Hides real issues. Use `ignoreDependencies`, `ignoreExportsUsedInFile`, or plugin settings instead |
| **Don't exclude test files via `ignore`** | Use `--production` flag instead |
| **Don't duplicate gitignored patterns** | Knip already respects `.gitignore` |
| **Use `ignoreExportsUsedInFile: { interface: true, type: true }`** | Eliminates most type-only false positives without broad ignoring |

### Monorepo / Workspace Configuration

```json
{
  "workspaces": {
    ".": {
      "entry": ["scripts/**/*.ts"]
    },
    "packages/web": {
      "entry": ["src/index.ts", "src/App.tsx"]
    },
    "packages/api": {
      "entry": ["src/server.ts"]
    }
  }
}
```

### Inline Suppression (use sparingly)

```typescript
// @knip-ignore-export
export const unusedButIntentional = () => {};
```

---

## Plugin System

Knip auto-detects plugins from config files. No setup needed for standard projects.

### Framework Plugins (Auto-detected)

| Framework | Detected Via | Entry Points Added |
|-----------|-------------|-------------------|
| Next.js | `next.config.js` | `pages/`, `app/`, `middleware.ts` |
| Vite | `vite.config.ts` | `index.html`, config plugins |
| Remix | `remix.config.js` | `app/root.tsx`, `app/entry.*` |
| Astro | `astro.config.mjs` | `src/pages/`, integrations |
| SvelteKit | `svelte.config.js` | `src/routes/`, `src/app.html` |

### Test Runner Plugins (Auto-detected)

| Tool | Detected Via | Entry Points Added |
|------|-------------|-------------------|
| Vitest | `vitest.config.ts` | `**/*.test.ts`, setup files |
| Jest | `jest.config.js` | `**/*.test.js`, setup files |
| Playwright | `playwright.config.ts` | `tests/**/*.spec.ts` |
| Cypress | `cypress.config.ts` | `cypress/e2e/**/*.cy.ts` |

### Disabling or Overriding a Plugin

```json
{
  "eslint": false,
  "vite": {
    "entry": ["vite.config.ts", "src/worker.ts"]
  }
}
```

If a config file shows as unused (e.g. `vite.config.ts`), disable the plugin explicitly rather than ignoring the file.

---

## Agent Cleanup Guidance

When acting on Knip output as an agent, categorize issues before acting:

### Auto-delete (act immediately)

- Unused internal exports (not in `index.ts`, `lib/`, or public API files)
- Unused type exports
- Unused npm dependencies (remove from `package.json`)
- Clearly orphaned files (no dynamic import possibility, no public API role)

### Ask before acting

- Files that might be entry points or dynamically imported
- Exports in `index.ts`, `lib/`, or files named `public`, `api`, `sdk`
- Dependencies that may be used via CLI or as peer dependencies
- Any file path containing `public`, `api`, or `lib`

Batch all clarifying questions in a single prompt rather than asking one at a time.

### Re-run loop

```
Run knip → Categorize → Auto-delete safe items → Ask about uncertain items → Re-run → Repeat
```

Stop when output is clean or only intentionally-ignored items remain.

---

## CI Integration

### GitHub Actions

```yaml
name: Knip
on:
  push:
    branches: [main]
  pull_request:

jobs:
  knip:
    name: Dead code check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - name: Check unused dependencies
        run: npx knip --dependencies --max-issues 0
      - name: Check unused exports (PR only)
        if: github.event_name == 'pull_request'
        run: npx knip --exports
```

### Recommended CI Strategy

| Check | When | Command |
|-------|------|---------|
| Unused dependencies | Every push | `npx knip --dependencies --max-issues 0` |
| Unused exports | PRs | `npx knip --exports` |
| Full production scan | Pre-release | `npx knip --production` |

---

## Troubleshooting

### Too many false positives

1. Read configuration hints from `npx knip` output
2. Enable the correct framework plugin
3. Add missing `entry` patterns
4. Add `ignoreExportsUsedInFile: { interface: true, type: true }`

### Entry points not detected

```bash
npx knip --debug    # Shows resolved config and entry points
```

Manually specify if needed: `npx knip --entry src/index.ts`

### Path aliases unresolved

```json
{
  "paths": {
    "@/*": ["src/*"],
    "~/*": ["app/*"]
  }
}
```

### Exit code 2 (unexpected error)

- Ensure a `knip.json` exists in the project root
- Check for syntax errors in config
- Run `npx knip --debug` for details

### Performance on large codebases

```bash
NODE_OPTIONS=--max-old-space-size=4096 npx knip
npx knip --workspace packages/target  # Scope to one workspace
```

---

## Issue Type Reference

| Issue Type | Meaning | Action |
|------------|---------|--------|
| Unused file | Not imported anywhere | Delete or add to `entry` |
| Unused dependency | In `package.json` but never imported | `npm uninstall` |
| Unused export | Exported but never imported externally | Remove `export` keyword |
| Unused type | Exported type/interface unused elsewhere | Remove or `ignoreExportsUsedInFile` |
| Unused enum member | Enum value never referenced | Remove member |
| Duplicate export | Same export from multiple files | Consolidate |

---

## References

- [knip.dev](https://knip.dev) — Official documentation
- [Configuration reference](https://knip.dev/reference/configuration)
- [Plugin reference](https://knip.dev/reference/plugins)
- [CLI reference](https://knip.dev/reference/cli)
- [FAQ](https://knip.dev/reference/faq)
