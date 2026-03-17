# Doc Viewer Page Template

Main page component for the documentation viewer.

## Overview

The `DocsViewerPage` component:

1. Fetches the docs tree on mount
2. Fetches content when path changes
3. Handles navigation between documents
4. Renders the three-column layout

## Configuration

Before using, configure:

- `basePath` — Route base path (default: `/admin/docs`)
- `apiBase` — API endpoint base (default: `/admin/docs`)
- Data fetching library (TanStack Query, SWR, or native fetch)

## Usage

### With React Router

```tsx
import { DocsViewerPage } from './doc-viewer-page';

<Route path="/admin/docs/*" element={<DocsViewerPage />} />
```

### With Wouter

```tsx
import { DocsViewerPage } from './doc-viewer-page';

<Route path="/admin/docs/:path*" component={DocsViewerPage} />
```

### With Next.js App Router

Place in `app/admin/docs/[[...path]]/page.tsx`:

```tsx
import { DocsViewerPage } from '@/components/docs-viewer-page';

export default function DocsPage() {
  return <DocsViewerPage />;
}
```

## Customization Points

| Prop | Type | Description |
|------|------|-------------|
| `basePath` | `string` | Route base path |
| `apiBase` | `string` | API endpoint base |
| `defaultDoc` | `string` | Path to load by default |
| `layout` | `'three-column' \| 'two-column' \| 'single'` | Layout variant |

## See Also

- [doc-viewer-page.tsx](./doc-viewer-page.tsx) — Full implementation
- [react-components.md](../react-components.md) — Component architecture
