# tl-docs-viewer-create

Create a React admin UI for browsing documentation folders with tree navigation, markdown rendering, Mermaid diagrams, and TOC generation.

## What This Skill Does

- **Discovers** existing admin areas or scaffolds new ones
- **Creates** server API endpoints for docs tree and content
- **Builds** React components for browsing documentation
- **Supports** Mermaid diagrams, syntax highlighting, and dark mode
- **Configures** library choices via AskQuestion (markdown renderer, data fetching)

## When to Use

- "create docs viewer"
- "add documentation browser"
- "admin docs UI"
- "browse docs folder"
- Adding a docs/ viewer to an existing admin interface

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill with workflow and architecture |
| `references/configuration.md` | AskQuestion flows (5 questions) |
| `references/server-api.md` | API endpoint patterns |
| `references/react-components.md` | Component architecture |
| `references/templates/` | 8 template files (4 docs + 4 code) |

## Templates

| Template | Description |
|----------|-------------|
| `api-routes.md` / `.ts` | Server endpoints for tree and content |
| `doc-viewer-page.md` / `.tsx` | Main page component |
| `doc-tree.md` / `.tsx` | Tree navigation component |
| `mermaid-markdown.md` / `.tsx` | Markdown renderer with Mermaid |

## AskQuestion Flow

5 questions gather project context:

1. **Admin Area** — Existing admin? (yes/no/scan)
2. **Frontend Stack** — React Router / Wouter / Next.js / TanStack Router / Remix
3. **Route Placement** — /admin/docs or custom
4. **Layout Pattern** — Three-column / Two-column / Single
5. **Libraries** — Markdown renderer + data fetching choices

## Dependencies

Configurable via AskQuestion:

| Category | Default | Alternatives |
|----------|---------|--------------|
| Markdown | @uiw/react-markdown-preview | react-markdown |
| Data fetching | @tanstack/react-query | swr, native fetch |
| Diagrams | mermaid | Optional |

## Suite

Part of the `tl-docs` suite.

### Related Skills

- [tl-docs-create](../tl-docs-create/) — Create documentation from scratch
- [tl-docs-audit](../tl-docs-audit/) — Audit docs coverage, find gaps, generate sync reports

## Source Attribution

Primary implementation reference: JamBase `data.jambase.com/client/src/pages/admin/readme/`

## License

MIT
