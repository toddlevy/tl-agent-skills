# Server API

Two endpoints power the docs viewer: tree structure and content retrieval.

---

## Endpoints Overview

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `GET /admin/docs/tree` | Folder structure | `DocNode[]` |
| `GET /admin/docs/content/:path*` | Markdown content | `DocContent` |

---

## GET /admin/docs/tree

Returns the documentation folder structure as a JSON tree.

### Response Type

```typescript
interface DocNode {
  name: string;
  path: string;
  type: 'file' | 'folder';
  children?: DocNode[];
}

type TreeResponse = DocNode[];
```

### Example Response

```json
[
  {
    "name": "docs",
    "path": "docs",
    "type": "folder",
    "children": [
      {
        "name": "README.md",
        "path": "docs/README.md",
        "type": "file"
      },
      {
        "name": "developer",
        "path": "docs/developer",
        "type": "folder",
        "children": [
          {
            "name": "architecture.md",
            "path": "docs/developer/architecture.md",
            "type": "file"
          }
        ]
      }
    ]
  }
]
```

### Implementation Notes

1. **Root path**: Configure the docs folder path (default: `docs/`)
2. **Filter**: Only include `.md` files
3. **Sort**: Folders first, then alphabetically by name
4. **Exclude**: Hidden files (starting with `.`), `node_modules`

### Fastify Implementation

```typescript
import { FastifyInstance } from 'fastify';
import fs from 'fs/promises';
import path from 'path';

interface DocNode {
  name: string;
  path: string;
  type: 'file' | 'folder';
  children?: DocNode[];
}

async function buildTree(dirPath: string, basePath: string): Promise<DocNode[]> {
  const entries = await fs.readdir(dirPath, { withFileTypes: true });
  const nodes: DocNode[] = [];

  const sorted = entries
    .filter(e => !e.name.startsWith('.'))
    .sort((a, b) => {
      if (a.isDirectory() && !b.isDirectory()) return -1;
      if (!a.isDirectory() && b.isDirectory()) return 1;
      return a.name.localeCompare(b.name);
    });

  for (const entry of sorted) {
    const fullPath = path.join(dirPath, entry.name);
    const relativePath = path.join(basePath, entry.name);

    if (entry.isDirectory()) {
      const children = await buildTree(fullPath, relativePath);
      if (children.length > 0) {
        nodes.push({
          name: entry.name,
          path: relativePath.replace(/\\/g, '/'),
          type: 'folder',
          children,
        });
      }
    } else if (entry.name.endsWith('.md')) {
      nodes.push({
        name: entry.name,
        path: relativePath.replace(/\\/g, '/'),
        type: 'file',
      });
    }
  }

  return nodes;
}

export function registerDocsRoutes(app: FastifyInstance, docsPath: string) {
  app.get('/admin/docs/tree', async () => {
    return buildTree(docsPath, 'docs');
  });
}
```

### Express Implementation

```typescript
import { Router } from 'express';
import fs from 'fs/promises';
import path from 'path';

const router = Router();

router.get('/tree', async (req, res) => {
  const docsPath = path.join(process.cwd(), 'docs');
  const tree = await buildTree(docsPath, 'docs');
  res.json(tree);
});

export default router;
```

---

## GET /admin/docs/content/:path*

Returns markdown content and extracted metadata for a specific file.

### Response Type

```typescript
interface DocContent {
  content: string;
  title: string;
  lastUpdated?: string;
  path: string;
}
```

### Example Response

```json
{
  "content": "# Architecture\n\n> **Last Updated:** 2026-03-17\n\nThis document covers...",
  "title": "Architecture",
  "lastUpdated": "2026-03-17",
  "path": "docs/developer/architecture.md"
}
```

### Implementation Notes

1. **Path validation**: Ensure path stays within docs folder (prevent path traversal)
2. **Title extraction**: Parse first `# ` heading
3. **Last Updated**: Parse `> **Last Updated:** YYYY-MM-DD` blockquote
4. **404 handling**: Return appropriate error for missing files

### Metadata Extraction

```typescript
function extractMetadata(content: string): { title: string; lastUpdated?: string } {
  let title = 'Untitled';
  let lastUpdated: string | undefined;

  const titleMatch = content.match(/^#\s+(.+)$/m);
  if (titleMatch) {
    title = titleMatch[1].trim();
  }

  const lastUpdatedMatch = content.match(/>\s*\*\*Last Updated:\*\*\s*(\d{4}-\d{2}-\d{2})/);
  if (lastUpdatedMatch) {
    lastUpdated = lastUpdatedMatch[1];
  }

  return { title, lastUpdated };
}
```

### Fastify Implementation

```typescript
app.get('/admin/docs/content/*', async (request, reply) => {
  const filePath = (request.params as { '*': string })['*'];
  
  if (!filePath || filePath.includes('..')) {
    return reply.status(400).send({ error: 'Invalid path' });
  }

  const fullPath = path.join(docsPath, filePath.replace(/^docs\//, ''));

  try {
    const content = await fs.readFile(fullPath, 'utf-8');
    const { title, lastUpdated } = extractMetadata(content);

    return {
      content,
      title,
      lastUpdated,
      path: filePath,
    };
  } catch (error) {
    return reply.status(404).send({ error: 'File not found' });
  }
});
```

### Express Implementation

```typescript
router.get('/content/*', async (req, res) => {
  const filePath = req.params[0];
  
  if (!filePath || filePath.includes('..')) {
    return res.status(400).json({ error: 'Invalid path' });
  }

  const fullPath = path.join(process.cwd(), filePath);

  try {
    const content = await fs.readFile(fullPath, 'utf-8');
    const { title, lastUpdated } = extractMetadata(content);

    res.json({
      content,
      title,
      lastUpdated,
      path: filePath,
    });
  } catch (error) {
    res.status(404).json({ error: 'File not found' });
  }
});
```

---

## Security Considerations

### Path Traversal Prevention

```typescript
function isValidDocPath(requestedPath: string, docsRoot: string): boolean {
  const resolved = path.resolve(docsRoot, requestedPath);
  return resolved.startsWith(path.resolve(docsRoot));
}
```

### Rate Limiting

Consider adding rate limiting for public docs viewers:

```typescript
import rateLimit from '@fastify/rate-limit';

app.register(rateLimit, {
  max: 100,
  timeWindow: '1 minute',
});
```

---

## Caching

### Response Caching

For production, add cache headers:

```typescript
app.get('/admin/docs/tree', async (request, reply) => {
  reply.header('Cache-Control', 'public, max-age=60');
  return buildTree(docsPath, 'docs');
});
```

### File Watching (Development)

For hot-reload during development, consider watching the docs folder:

```typescript
import chokidar from 'chokidar';

const watcher = chokidar.watch(docsPath);
let treeCache: DocNode[] | null = null;

watcher.on('all', () => {
  treeCache = null;
});
```

---

## Error Responses

| Status | Condition | Response |
|--------|-----------|----------|
| 200 | Success | Data |
| 400 | Invalid path | `{ "error": "Invalid path" }` |
| 404 | File not found | `{ "error": "File not found" }` |
| 500 | Server error | `{ "error": "Internal server error" }` |
