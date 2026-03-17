/**
 * Docs Viewer API Routes
 *
 * Server-side routes for the documentation viewer.
 * Provides tree structure and content endpoints.
 *
 * @example Fastify
 * ```typescript
 * import { registerDocsRoutes } from './api-routes';
 * registerDocsRoutes(app, path.join(process.cwd(), 'docs'));
 * ```
 *
 * @example Express
 * ```typescript
 * import { createDocsRouter } from './api-routes';
 * app.use('/admin/docs', createDocsRouter(path.join(process.cwd(), 'docs')));
 * ```
 */

import fs from 'fs/promises';
import path from 'path';

// Types
export interface DocNode {
  name: string;
  path: string;
  type: 'file' | 'folder';
  children?: DocNode[];
}

export interface DocContent {
  content: string;
  title: string;
  lastUpdated?: string;
  path: string;
}

// Tree building
async function buildTree(dirPath: string, basePath: string): Promise<DocNode[]> {
  const entries = await fs.readdir(dirPath, { withFileTypes: true });
  const nodes: DocNode[] = [];

  const sorted = entries
    .filter(e => !e.name.startsWith('.') && e.name !== 'node_modules')
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

// Metadata extraction
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

// Path validation
function isValidDocPath(requestedPath: string, docsRoot: string): boolean {
  const resolved = path.resolve(docsRoot, requestedPath);
  return resolved.startsWith(path.resolve(docsRoot));
}

// Fastify implementation
export function registerDocsRoutes(
  app: { get: (path: string, handler: (req: unknown, reply: unknown) => Promise<unknown>) => void },
  docsPath: string
) {
  // GET /tree
  app.get('/tree', async () => {
    return buildTree(docsPath, 'docs');
  });

  // GET /content/*
  app.get('/content/*', async (request: { params: { '*': string } }, reply: { status: (code: number) => { send: (data: unknown) => void } }) => {
    const filePath = request.params['*'];

    if (!filePath || filePath.includes('..')) {
      return reply.status(400).send({ error: 'Invalid path' });
    }

    if (!isValidDocPath(filePath, docsPath)) {
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
    } catch {
      return reply.status(404).send({ error: 'File not found' });
    }
  });
}

// Express implementation
export function createDocsRouter(docsPath: string) {
  // Using dynamic import pattern for Express compatibility
  const router = {
    routes: [] as Array<{ method: string; path: string; handler: (req: unknown, res: unknown) => Promise<void> }>,

    get(routePath: string, handler: (req: unknown, res: unknown) => Promise<void>) {
      this.routes.push({ method: 'GET', path: routePath, handler });
    },

    async handleRequest(req: { path: string; params: Record<string, string> }, res: { json: (data: unknown) => void; status: (code: number) => { json: (data: unknown) => void } }) {
      // GET /tree
      if (req.path === '/tree') {
        const tree = await buildTree(docsPath, 'docs');
        res.json(tree);
        return;
      }

      // GET /content/*
      if (req.path.startsWith('/content/')) {
        const filePath = req.path.replace('/content/', '');

        if (!filePath || filePath.includes('..')) {
          res.status(400).json({ error: 'Invalid path' });
          return;
        }

        if (!isValidDocPath(filePath, docsPath)) {
          res.status(400).json({ error: 'Invalid path' });
          return;
        }

        const fullPath = path.join(docsPath, filePath.replace(/^docs\//, ''));

        try {
          const content = await fs.readFile(fullPath, 'utf-8');
          const { title, lastUpdated } = extractMetadata(content);

          res.json({
            content,
            title,
            lastUpdated,
            path: filePath,
          });
        } catch {
          res.status(404).json({ error: 'File not found' });
        }
      }
    },
  };

  return router;
}

// Exports for direct use
export { buildTree, extractMetadata, isValidDocPath };
