# README Section Template

Template for section index files like `docs/developer/README.md`.

---

## Template

```markdown
# {{SECTION_NAME}}

> **Last Updated:** {{DATE}}

{{SECTION_DESCRIPTION}}

## Contents

| Document | Description |
|----------|-------------|
| [{{DOC_1_NAME}}](./{{doc-1}}.md) | {{DOC_1_DESCRIPTION}} |
| [{{DOC_2_NAME}}](./{{doc-2}}.md) | {{DOC_2_DESCRIPTION}} |
| [{{DOC_3_NAME}}](./{{doc-3}}.md) | {{DOC_3_DESCRIPTION}} |

## Subsections

- [{{SUBSECTION_NAME}}](./{{subsection}}/README.md) — {{SUBSECTION_DESCRIPTION}}

## Quick Reference

{{QUICK_REFERENCE_CONTENT}}

## See Also

- [Parent Section](../README.md)
- [Related Section](../{{related}}/README.md)
```

---

## Usage Notes

- Replace placeholders with actual content
- Use table format for document listings
- Include "See Also" for navigation context
- Keep description to 1-2 sentences
- Add Quick Reference for commonly needed info

---

## Example: Developer Section

```markdown
# Developer Guide

> **Last Updated:** 2026-03-17

Resources for developers working on this codebase.

## Contents

| Document | Description |
|----------|-------------|
| [Architecture](./architecture.md) | System design and component overview |
| [Local Setup](./setup.md) | Development environment configuration |
| [Testing](./testing.md) | Test guidelines and commands |
| [Code Style](./code-style.md) | Conventions and formatting |

## Subsections

- [Scripts](./scripts/README.md) — CLI script documentation

## Quick Reference

```bash
# Start development
pnpm dev

# Run tests
pnpm test

# Type check
pnpm typecheck
```

## See Also

- [Documentation Home](../README.md)
- [Reference](../reference/README.md)
```

---

## Source Attribution

Based on JamBase hierarchical documentation structure.
