---
name: tl-knip
description: Find and remove unused files, dependencies, and exports in TypeScript/JavaScript projects using Knip. Covers configuration-first workflow, plugin system, barrel file handling, CI integration, monorepo support, and agent-specific cleanup guidance.
license: MIT
compatibility: TypeScript, JavaScript, monorepos. Node.js 18+.
metadata:
  author: tl-agent-skills
  version: "2.0"
  suite: tl-knip
quilted:
  version: 1
  synthesized: '2026-02-22'
  platform: tl-agent-skills (manual synthesis)
  sources:
    - url: https://skills.sh/brianlovin/claude-config/knip
      weight: '0.35'
      borrowed:
        - Configuration-first workflow ordering
        - Never-use-ignore-patterns rule
        - ignoreExportsUsedInFile for types guidance
        - Production mode vs --production flag preference
    - url: https://skills.sh/laurigates/claude-plugins/knip-dead-code-detection
      weight: '0.30'
      borrowed:
        - Framework plugin detection table
        - Test runner plugin table
        - CI/CD YAML examples
        - Inline knip-ignore comment technique
        - Troubleshooting section structure
    - url: https://skills.sh/artivilla/agents-config/knip
      weight: '0.20'
      borrowed:
        - Auto-delete vs ask-first confidence categorization
        - Re-run loop workflow for agent execution
    - url: https://skills.sh/knoopx/pi/knip
      weight: '0.10'
      borrowed:
        - Concise quick command reference structure
        - trace-file and trace-export debug commands
    - url: https://skills.sh/pproenca/dot-skills/knip-deadcode-best-practices
      weight: '0.05'
      borrowed:
        - 8-category rule priority framework as organizing model
---

# Knip: Dead Code Detection & Removal

Knip finds unused files, dependencies, and exports across TypeScript and JavaScript projects. It understands your project's entry points, plugin ecosystem, and module graph — reporting only real dead code, not false positives.

**What Knip detects:**

- Unused files (not imported anywhere in the module graph)
- Unused npm dependencies and devDependencies
- Unused exports, types, enum members, and class members
- Barrel file re-exports that are never consumed externally
- Duplicate exports across files

## Suite

This is a standalone skill with no related suite members.

## When to Use

Agent triggers — activate this skill when the user says:

- "Find dead code in this project"
- "Clean up unused dependencies"
- "Why is this export showing as unused?"
- "Set up Knip for this monorepo"
- "Add Knip to CI"
- "Our barrel files are causing false positives"
- "How do I ignore this export?"
- Anything about unused imports, orphaned files, or dependency hygiene

## Resources

Load these on demand when the user's question goes deeper than SKILL.md covers:

- [references/configuration.md](references/configuration.md) — Complete knip.json / knip.ts option reference with examples
- [references/plugins.md](references/plugins.md) — Full plugin ecosystem: all frameworks, test runners, build tools
- [references/barrel-files.md](references/barrel-files.md) — Barrel file and re-export handling: false positives, public API tagging, index.ts patterns
- [references/troubleshooting.md](references/troubleshooting.md) — Systematic diagnosis: false positives, performance, monorepo issues, exit codes
- [scripts/knip-check.sh](scripts/knip-check.sh) — Health check script (bash)
- [scripts/knip-check.ps1](scripts/knip-check.ps1) — Health check script (PowerShell)

---

## Quick Commands

```bash
npx knip                              # Full analysis
npx knip --production                 # Production code only (excludes tests/devDeps)
npx knip --dependencies               # Only unused deps — fastest CI check
npx knip --exports                    # Only unused exports
npx knip --files                      # Only unused files
npx knip --fix                        # Auto-remove safe issues
npx knip --fix --allow-remove-files   # Auto-remove including file deletion
npx knip --reporter json              # JSON output for tooling/CI
npx knip --reporter compact           # Compact human-readable output
npx knip --workspace packages/api     # Specific monorepo workspace only
```

**Debug commands:**

```bash
npx knip --debug                           # Full config resolution + entry point trace
npx knip --trace-file src/utils.ts         # Why is this file included/excluded?
npx knip --trace-export myFunction         # Why is this export flagged?
```

---

## Configuration-First Workflow

**Always configure before acting on reported issues.** Cleaning up issues before fixing configuration causes churn — removed items may be re-flagged or real issues masked.

### Step 1 — Understand the project

- Check `package.json` for frameworks, test runners, build tools
- Look for existing Knip config: `knip.json`, `knip.jsonc`, `knip.ts`, or `"knip"` key in `package.json`
- Review existing config for problems before running

### Step 2 — Run and read configuration hints first

```bash
npx knip
```

**Configuration hints appear at the top of output before issue lists.** Address these first — they identify missing entry points, unrecognized plugins, and path alias gaps that cause false positives.

### Step 3 — Adjust config to eliminate false positives

Common adjustments:

| Symptom | Fix |
|---------|-----|
| Config file flagged as unused (e.g. `vite.config.ts`) | Explicitly enable/disable that plugin |
| Exported types flagged despite being used | Add `ignoreExportsUsedInFile: { interface: true, type: true }` |
| Path aliases unresolved | Add `paths` matching `tsconfig.json` |
| Test files flagging prod imports | Use `--production` instead of `ignore` patterns |
| Barrel file exports all flagged | See [references/barrel-files.md](references/barrel-files.md) |

### Step 4 — Repeat until hints are resolved

Re-run after each config change. Only address reported issues once hints are gone and false positives are minimal.

### Step 5 — Address issues in priority order

1. **Unused files** — tackle first; removing files exposes newly-unused exports downstream
2. **Unused dependencies** — remove from `package.json`
3. **Unused devDependencies** — remove from `package.json`
4. **Unused exports** — remove `export` keyword or delete the item
5. **Unused types/interfaces** — remove or add `ignoreExportsUsedInFile`

### Step 6 — Re-run and repeat

Each cleanup pass exposes more dead code. Repeat until output is clean or only intentionally-ignored items remain.

---

## Minimal Working Config

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

**Critical rules:**

| Rule | Why |
|------|-----|
| Never use `ignore` patterns | Hides real issues. Use `ignoreDependencies`, `ignoreExportsUsedInFile`, or plugin settings instead |
| Never exclude test files via `ignore` | Use `--production` flag |
| Don't repeat `.gitignore` patterns | Knip already respects `.gitignore` |
| Disable/enable plugins explicitly when needed | Clearer than ignoring the config file |

See [references/configuration.md](references/configuration.md) for all options.

---

## Barrel Files

Barrel files (`index.ts` files that re-export from multiple modules) are the most common source of Knip false positives. Knip tracks whether re-exported items are actually consumed outside the barrel — if nothing imports them externally, they're flagged.

**Barrel file patterns and fixes — see [references/barrel-files.md](references/barrel-files.md).**

Quick reference:

```json
{
  "ignoreExportsUsedInFile": true,
  "includeEntryExports": true
}
```

Tag intentional public API exports with JSDoc:

```typescript
/** @public */
export const myPublicFunction = () => {};
```

---

## Agent Cleanup Guidance

When executing a Knip cleanup as an agent, categorize before acting.

### Auto-delete without asking

- Unused internal exports (not in `index.ts`, `lib/`, `sdk/`, or `api/` paths)
- Unused exported types and interfaces
- Unused npm dependencies (run `npm uninstall <pkg>`)
- Clearly orphaned files with no dynamic import possibility

### Ask before acting

- Files that could be entry points or dynamically imported
- Exports in `index.ts`, `lib/`, `sdk/`, `api/`, or `public/` paths
- Dependencies that might be used as CLI tools or peer dependencies
- Anything the user has previously mentioned keeping

Batch all clarifying questions into a single prompt — never ask one at a time.

### Re-run loop

```
Run → Categorize → Auto-delete safe → Ask about uncertain → Re-run → Repeat
```

Stop when output is clean or only intentional suppressions remain.

---

## CI Integration

```yaml
name: Knip
on: [push, pull_request]

jobs:
  knip:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci
      - name: Unused dependencies
        run: npx knip --dependencies --max-issues 0
      - name: Unused exports (PRs only)
        if: github.event_name == 'pull_request'
        run: npx knip --exports
```

| Check | When | Rationale |
|-------|------|-----------|
| `--dependencies --max-issues 0` | Every push | High value, fast, no false positives |
| `--exports` | PRs | Prevents API surface bloat |
| `--production` | Pre-release | Full dead code audit |

---

## Issue Type Reference

| Issue Type | Meaning | Action |
|------------|---------|--------|
| Unused file | Not reachable from any entry point | Delete or add to `entry` |
| Unused dependency | In `package.json` but never imported | `npm uninstall` |
| Unused export | Exported but never imported outside this file | Remove `export` keyword |
| Unused type | Exported type/interface unused elsewhere | Remove or `ignoreExportsUsedInFile` |
| Unused enum member | Enum variant never referenced | Remove member |
| Duplicate export | Same name exported from multiple files | Consolidate |

---

## Attribution

### Knip (the tool)

This skill documents [Knip](https://knip.dev) by [webpro-nl](https://github.com/webpro-nl/knip).

> Knip is © webpro-nl and contributors, licensed under the [ISC License](https://github.com/webpro-nl/knip?tab=ISC-1-ov-file#readme).
> This skill is independent documentation and is not affiliated with or endorsed by the Knip project.

### Quilted source skills

This skill synthesizes content from 5 community Knip skills:

| Source | Weight | Key Contribution |
|--------|--------|-----------------|
| [brianlovin/claude-config](https://skills.sh/brianlovin/claude-config/knip) | 35% | Configuration-first workflow, never-use-ignore discipline |
| [laurigates/claude-plugins](https://skills.sh/laurigates/claude-plugins/knip-dead-code-detection) | 30% | Plugin tables, CI examples, troubleshooting structure |
| [artivilla/agents-config](https://skills.sh/artivilla/agents-config/knip) | 20% | Agent auto-delete vs ask-first categorization |
| [knoopx/pi](https://skills.sh/knoopx/pi/knip) | 10% | Quick command reference, trace debug commands |
| [pproenca/dot-skills](https://skills.sh/pproenca/dot-skills/knip-deadcode-best-practices) | 5% | 8-category priority framework |
