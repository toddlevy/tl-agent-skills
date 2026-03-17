# Docs Viewer

Reference to the `tl-docs-viewer-create` skill for creating a React admin UI to browse documentation.

---

## Overview

The docs viewer is a **separate skill** (`tl-docs-viewer-create`) in the `tl-docs` suite. This skill creates documentation; the viewer skill creates a UI to browse it.

### Why Separate Skills?

| Concern | This Skill | tl-docs-viewer-create |
|---------|------------|-----------------------|
| **Focus** | Content creation, standards, templates | UI implementation, routing, rendering |
| **Output** | Markdown files in docs/ | React components, API routes |
| **Dependencies** | None (markdown only) | React, TanStack Query, Mermaid |
| **Trigger** | "create docs" | "create docs viewer", "admin docs UI" |

---

## When to Recommend

If user selects "Docs Viewer UI" in the doc types question, present options:

1. **Recommend it** — Point to `tl-docs-viewer-create` after docs are created
2. **Create it now** — Switch to `tl-docs-viewer-create` skill to build the UI
3. **Skip** — User will handle separately

### Handoff Pattern

After completing documentation:

```
Documentation created in docs/.

For a browseable admin UI, use the tl-docs-viewer-create skill:
- Creates API endpoints for doc tree and content
- Builds React components for navigation and rendering
- Supports Mermaid diagrams and syntax highlighting
```

---

## What the Viewer Provides

Reference implementation based on JamBase `data.jambase.com/client/src/pages/admin/readme/`.

### Features

| Feature | Description |
|---------|-------------|
| **Tree Navigation** | Collapsible folder structure |
| **Markdown Rendering** | Full GFM support with syntax highlighting |
| **Mermaid Diagrams** | Embedded diagram rendering |
| **On This Page** | Auto-generated TOC from headings |
| **Dark Mode** | Matches admin theme |
| **Search** | Filter docs by name (optional) |

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Admin Docs Layout                        │
├──────────┬───────────────────────────────────┬──────────────┤
│          │                                   │              │
│  DocTree │         DocContent                │ OnThisPage   │
│          │                                   │              │
│  ├─ docs │  # Document Title                 │ - Section 1  │
│  │  ├─ a │                                   │ - Section 2  │
│  │  └─ b │  Content rendered from markdown   │   - Sub 2.1  │
│  └─ ...  │                                   │ - Section 3  │
│          │                                   │              │
└──────────┴───────────────────────────────────┴──────────────┘
```

### Server API

| Endpoint | Purpose |
|----------|---------|
| `GET /admin/docs/tree` | Return folder structure as JSON tree |
| `GET /admin/docs/content/*` | Return markdown content + metadata |

### React Components

| Component | Purpose |
|-----------|---------|
| `DocTree` | Recursive tree navigation |
| `DocTreeItem` | Single tree node with expand/collapse |
| `MermaidMarkdown` | Markdown + Mermaid renderer |
| `OnThisPageNav` | TOC extracted from headings |
| `AdminDocsLayout` | Three-column layout wrapper |

---

## Suite Relationship

All skills belong to the `tl-docs` suite:

```yaml
# In tl-docs-create SKILL.md (this skill):
metadata:
  suite: tl-docs
  related:
    - tl-docs-audit
    - tl-docs-viewer-create

# In tl-docs-viewer-create SKILL.md:
metadata:
  suite: tl-docs
  related:
    - tl-docs-create
    - tl-docs-audit
```

---

## tl-docs-viewer-create AskQuestion Flow

The viewer skill has its own configuration discovery:

### Question 1: Admin Area Detection

```
prompt: "Do you have an existing admin area?"
options:
  - "Yes, show me" → Explores routes, proposes /admin/docs
  - "No, create one" → Scaffolds admin layout + docs route
  - "Not sure" → Scans for admin patterns
```

### Question 2: Frontend Stack

```
prompt: "What's your frontend stack?"
options:
  - React Router
  - Wouter
  - Next.js
  - TanStack Router
  - Remix
  - Other
```

### Question 3: Route Placement

```
prompt: "Where should the docs viewer live?"
options:
  - [Detected pattern, e.g., /admin/docs]
  - Custom path...
```

### Question 4: Layout Pattern

```
prompt: "What layout pattern?"
options:
  - Three-column (tree + content + TOC)
  - Two-column (tree + content)
  - Single column with collapsible nav
```

---

## See Also

- **JamBase implementation**: `data.jambase.com/client/src/pages/admin/readme/`
- **tl-docs-viewer-create skill**: See `tl-agent-skills/skills/tl-docs-viewer-create/`
