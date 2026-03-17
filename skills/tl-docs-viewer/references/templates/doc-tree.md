# Doc Tree Template

Recursive tree navigation component for browsing documentation structure.

## Overview

The `DocTree` component:

1. Renders a hierarchical folder/file tree
2. Handles expand/collapse for folders
3. Tracks and highlights the current document
4. Triggers navigation on file selection

## Features

- Recursive rendering for nested structures
- Auto-expand to current document
- Keyboard navigation support
- Customizable icons
- Accessible with ARIA labels

## Usage

```tsx
import { DocTree } from './doc-tree';

<DocTree
  nodes={treeData}
  currentPath="docs/developer/architecture.md"
  onSelect={(path) => navigate(path)}
/>
```

## Props

| Prop | Type | Description |
|------|------|-------------|
| `nodes` | `DocNode[]` | Tree structure from API |
| `currentPath` | `string` | Currently selected document path |
| `onSelect` | `(path: string) => void` | Callback when file is selected |

## Customization

### Icons

Replace emoji icons with your icon library:

```tsx
import { Folder, FolderOpen, File } from 'lucide-react';

const icon = node.type === 'folder'
  ? (expanded ? <FolderOpen /> : <Folder />)
  : <File />;
```

### Styling

Override CSS classes:

- `.doc-tree` — Container
- `.doc-tree-item__button` — Item button
- `.doc-tree-item__button--active` — Active state
- `.doc-tree-item__children` — Nested list

## See Also

- [doc-tree.tsx](./doc-tree.tsx) — Full implementation
- [react-components.md](../react-components.md) — Component architecture
