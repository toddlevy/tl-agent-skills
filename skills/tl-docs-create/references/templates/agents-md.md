# AGENTS.md Template

Minimal AI assistant context file. Under 60 lines.

---

## Template

```markdown
# AGENTS.md

## Commands

Test: `pnpm test`
Lint: `pnpm lint`
Type check: `pnpm typecheck`
Build: `pnpm build`
Dev server: `pnpm dev`

## File-Scoped Commands

Test single file: `pnpm test path/to/file.test.ts`
Lint single file: `pnpm lint path/to/file.ts`

## Conventions

- TypeScript strict mode
- Prefer named exports over default
- Co-locate tests with source (`*.test.ts` next to `*.ts`)
- Use path aliases (`@/` for `src/`)

## Architecture

- `src/` — Source code
- `src/routes/` — API routes
- `src/lib/` — Shared utilities
- `src/components/` — React components (if applicable)

## Do NOT

- Add dependencies without checking existing ones
- Modify `package.json` scripts without discussion
- Skip TypeScript types (no `any` without justification)
- Commit without running `pnpm typecheck && pnpm lint`

## Commit Format

Use conventional commits:
- `feat:` — New feature
- `fix:` — Bug fix
- `docs:` — Documentation only
- `refactor:` — Code change that neither fixes nor adds
- `test:` — Adding or updating tests

AI commits MUST include:
```
Co-Authored-By: cursor <cursor@cursor.com>
```

## References

- [README](./README.md) — Project overview
- [Architecture](./docs/developer/architecture.md) — Detailed design
```

---

## Usage Notes

### Line Budget

Keep AGENTS.md under 60 lines. Instruction quality degrades with length.

### What to Include

| Include | Why |
|---------|-----|
| Commands | Frequently needed |
| File-scoped commands | More useful than project-wide |
| Key conventions | Project-specific rules |
| Do NOT list | Prevent common mistakes |
| Commit format | Consistency |

### What to Exclude

| Exclude | Why |
|---------|-----|
| Full linter rules | Lives in config files |
| Detailed architecture | Link to docs instead |
| Setup instructions | Lives in README |
| Long explanations | Brevity is critical |

### Anti-Patterns

- Don't duplicate what linters enforce
- Don't restate README content
- Don't include generic advice
- Don't pad with pleasantries

---

## Source Attribution

Based on getsentry agents-md skill with brevity and file-scoped command patterns.
