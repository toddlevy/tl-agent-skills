# Knip Plugin Reference

Knip uses plugins to understand 80+ frameworks and tools. Each plugin knows:
- Where configuration files live
- What entry points the framework adds
- Which dependencies are consumed implicitly

Plugins are **auto-detected** — no configuration needed for standard projects. You only need to configure a plugin if auto-detection fails or gives incorrect results.

---

## How Auto-detection Works

Knip scans for framework-specific config files in your project root:

1. Finds `vite.config.ts` → enables Vite plugin → adds `index.html`, workers as entry points
2. Finds `next.config.js` → enables Next.js plugin → adds `pages/`, `app/`, `middleware.ts`
3. Finds `vitest.config.ts` → enables Vitest plugin → adds `**/*.test.ts`, setup files

Run `npx knip --debug` to see which plugins were detected and what entry points they added.

---

## Framework Plugins

| Framework | Config File Detected | Entry Points Added |
|-----------|---------------------|-------------------|
| **Next.js** | `next.config.{js,ts,mjs}` | `pages/**/*.{tsx,ts}`, `app/**/*.{tsx,ts}`, `middleware.ts`, `instrumentation.ts` |
| **Vite** | `vite.config.{ts,js}` | `index.html`, workers, config plugins |
| **Remix** | `remix.config.js` | `app/root.tsx`, `app/entry.{client,server}.tsx`, `app/routes/**` |
| **Astro** | `astro.config.{mjs,ts}` | `src/pages/**`, `src/layouts/**`, config integrations |
| **SvelteKit** | `svelte.config.js` | `src/routes/**`, `src/app.html`, `src/hooks.{server,client}.ts` |
| **Nuxt** | `nuxt.config.{ts,js}` | `app.vue`, `pages/**`, `layouts/**`, `middleware/**`, `plugins/**` |
| **Gatsby** | `gatsby-config.{js,ts}` | `gatsby-{browser,node,ssr}.{ts,js}`, `src/pages/**` |
| **Create React App** | `react-scripts` in deps | `src/index.{tsx,ts}`, `src/setupTests.ts` |
| **Angular** | `angular.json` | Configured entry points, `main.ts`, `polyfills.ts` |
| **Expo** | `app.json` with `expo` | `app/{index,_layout}.{tsx,ts}` |
| **React Native** | `@react-native` in deps | `index.{tsx,ts}` |

---

## Test Runner Plugins

| Tool | Config File | Entry Points Added |
|------|-------------|-------------------|
| **Vitest** | `vitest.config.{ts,js}` | `**/*.{test,spec}.{ts,tsx}`, setup files from config |
| **Jest** | `jest.config.{js,ts,json}` | `**/*.{test,spec}.{js,ts,tsx}`, `setupFilesAfterFramework` |
| **Playwright** | `playwright.config.{ts,js}` | `tests/**/*.spec.{ts,js}`, `e2e/**/*.spec.{ts,js}` |
| **Cypress** | `cypress.config.{ts,js}` | `cypress/e2e/**/*.cy.{ts,js}`, `cypress/support/**` |
| **Mocha** | `.mocharc.{js,yml,json}` | `test/**/*.{spec,test}.{js,ts}` |
| **Jasmine** | `jasmine.json` | `spec/**/*.spec.{js,ts}` |
| **AVA** | `ava.config.{js,ts}` or `package.json` | `test.{js,ts}`, `test-*.{js,ts}`, `**/*.spec.js` |
| **Bun Test** | `bun` in deps | `**/*.test.{ts,js}` |

---

## Build Tool & Config Plugins

| Tool | Config File | What It Detects |
|------|-------------|----------------|
| **TypeScript** | `tsconfig.json` | Files in `include`, path aliases |
| **ESLint** | `.eslintrc.*`, `eslint.config.{js,ts}` | Config plugins and extends |
| **Prettier** | `.prettierrc`, `prettier.config.js` | Config plugins |
| **PostCSS** | `postcss.config.{js,ts}` | Config plugins |
| **Tailwind CSS** | `tailwind.config.{js,ts}` | Config plugins, content patterns |
| **Rollup** | `rollup.config.{js,ts}` | Input files, plugins |
| **Webpack** | `webpack.config.{js,ts}` | Entry points, loaders, plugins |
| **esbuild** | `esbuild.config.{js,ts}` | Entry points, plugins |
| **Turbopack** | `turbo.json` | Pipeline tasks |
| **tsup** | `tsup.config.{ts,js}` | Entry points |
| **unbuild** | `build.config.ts` | Entry points |
| **Storybook** | `.storybook/main.{ts,js}` | Story files, addons |
| **Ava** | `ava.config.{js,ts}` | Test files |

---

## Linting & Code Quality Plugins

| Tool | Detected Via |
|------|-------------|
| **Biome** | `biome.json` |
| **Stylelint** | `.stylelintrc.*` |
| **commitlint** | `commitlint.config.{js,ts}` |
| **lint-staged** | `lint-staged` in `package.json` or `.lintstagedrc` |
| **Husky** | `.husky/` directory |
| **Release It** | `.release-it.{json,js}` |
| **Semantic Release** | `.releaserc` |
| **Changesets** | `.changeset/config.json` |

---

## Runtime & Infrastructure Plugins

| Tool | Detected Via |
|------|-------------|
| **Docker** | `Dockerfile` |
| **GitHub Actions** | `.github/workflows/*.yml` |
| **Bun** | `bun.lockb` |
| **Nx** | `nx.json` |
| **Turborepo** | `turbo.json` |

---

## Overriding Plugin Configuration

### Disable a plugin

```json
{
  "eslint": false,
  "prettier": false
}
```

Use when a plugin adds incorrect entry points or causes false positives.

### Override a plugin's entry points

```json
{
  "vite": {
    "entry": ["vite.config.ts", "vite.config.worker.ts", "src/service-worker.ts"],
    "config": ["vite.config.ts"]
  }
}
```

### Override Vitest setup files

```json
{
  "vitest": {
    "entry": ["vitest.config.ts", "vitest.setup.ts", "test/global-setup.ts"]
  }
}
```

### Override Next.js to include custom entry patterns

```json
{
  "next": {
    "entry": [
      "next.config.js",
      "pages/**/*.{tsx,ts}",
      "app/**/*.{tsx,ts}",
      "middleware.ts",
      "src/instrumentation.ts"
    ]
  }
}
```

---

## Plugin Not Auto-Detected

If Knip doesn't detect a framework you're using:

1. Check that the config file is in the project root (or workspace root for monorepos)
2. Check if the plugin name matches — run `npx knip --debug` to see detected plugins
3. Explicitly enable the plugin with minimal config:

```json
{
  "vite": {}
}
```

An empty plugin config tells Knip to enable the plugin with all defaults.

---

## Debugging Plugin Detection

```bash
# See all detected plugins and their entry points
npx knip --debug 2>&1 | findstr /i "plugin"

# PowerShell
npx knip --debug 2>&1 | Select-String -Pattern "plugin" -CaseSensitive:$false

# Trace a specific file to see which plugin claims it
npx knip --trace-file vite.config.ts
```

---

## Per-Workspace Plugin Config (Monorepos)

```json
{
  "workspaces": {
    "packages/web": {
      "next": {},
      "vitest": {
        "entry": ["vitest.config.ts", "src/test/setup.ts"]
      }
    },
    "packages/api": {
      "vitest": {}
    },
    "packages/shared": {
      "eslint": false
    }
  }
}
```
