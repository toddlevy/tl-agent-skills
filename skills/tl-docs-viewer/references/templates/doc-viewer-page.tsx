/**
 * Documentation Viewer Page
 *
 * Main page component for browsing documentation.
 * Fetches tree structure and content, renders three-column layout.
 *
 * @example
 * ```tsx
 * // React Router
 * <Route path="/admin/docs/*" element={<DocsViewerPage />} />
 *
 * // Wouter
 * <Route path="/admin/docs/:path*" component={DocsViewerPage} />
 * ```
 */

import { useState, useEffect } from 'react';
// Uncomment for TanStack Query:
// import { useQuery } from '@tanstack/react-query';
// Uncomment for SWR:
// import useSWR from 'swr';

// Types
interface DocNode {
  name: string;
  path: string;
  type: 'file' | 'folder';
  children?: DocNode[];
}

interface DocContent {
  content: string;
  title: string;
  lastUpdated?: string;
  path: string;
}

interface DocsViewerPageProps {
  basePath?: string;
  apiBase?: string;
  defaultDoc?: string;
  layout?: 'three-column' | 'two-column' | 'single';
}

// Fetcher for SWR
const fetcher = (url: string) => fetch(url).then(r => r.json());

export function DocsViewerPage({
  basePath = '/admin/docs',
  apiBase = '/admin/docs',
  defaultDoc = 'docs/README.md',
  layout = 'three-column',
}: DocsViewerPageProps) {
  // Get current path from URL
  const [currentPath, setCurrentPath] = useState<string>(defaultDoc);

  // Update path from URL on mount and navigation
  useEffect(() => {
    const urlPath = window.location.pathname.replace(basePath, '').replace(/^\//, '');
    if (urlPath) {
      setCurrentPath(urlPath);
    }
  }, [basePath]);

  // --- Data Fetching ---

  // Option 1: Native fetch (default)
  const [tree, setTree] = useState<DocNode[]>([]);
  const [content, setContent] = useState<DocContent | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${apiBase}/tree`)
      .then(r => r.json())
      .then(data => {
        setTree(data);
        setLoading(false);
      })
      .catch(err => {
        console.error('[TLDOCS] Failed to fetch tree:', err);
        setLoading(false);
      });
  }, [apiBase]);

  useEffect(() => {
    if (currentPath) {
      setLoading(true);
      fetch(`${apiBase}/content/${currentPath}`)
        .then(r => r.json())
        .then(data => {
          setContent(data);
          setLoading(false);
        })
        .catch(err => {
          console.error('[TLDOCS] Failed to fetch content:', err);
          setLoading(false);
        });
    }
  }, [apiBase, currentPath]);

  // Option 2: TanStack Query (uncomment to use)
  /*
  const { data: tree = [], isLoading: treeLoading } = useQuery({
    queryKey: ['docs', 'tree'],
    queryFn: () => fetch(`${apiBase}/tree`).then(r => r.json()),
  });

  const { data: content, isLoading: contentLoading } = useQuery({
    queryKey: ['docs', 'content', currentPath],
    queryFn: () => fetch(`${apiBase}/content/${currentPath}`).then(r => r.json()),
    enabled: !!currentPath,
  });

  const loading = treeLoading || contentLoading;
  */

  // Option 3: SWR (uncomment to use)
  /*
  const { data: tree = [] } = useSWR<DocNode[]>(`${apiBase}/tree`, fetcher);
  const { data: content, isLoading: loading } = useSWR<DocContent>(
    currentPath ? `${apiBase}/content/${currentPath}` : null,
    fetcher
  );
  */

  // --- Navigation ---

  const handleSelect = (path: string) => {
    setCurrentPath(path);
    window.history.pushState(null, '', `${basePath}/${path}`);
  };

  // --- Render ---

  const layoutClass = `admin-docs-layout admin-docs-layout--${layout}`;

  return (
    <div className={layoutClass}>
      {/* Tree Navigation */}
      <aside className="admin-docs-layout__tree">
        <DocTree
          nodes={tree}
          currentPath={currentPath}
          onSelect={handleSelect}
        />
      </aside>

      {/* Main Content */}
      <main className="admin-docs-layout__content">
        {loading ? (
          <div className="docs-loading">Loading...</div>
        ) : content ? (
          <article className="docs-content">
            <MermaidMarkdown content={content.content} />
          </article>
        ) : (
          <div className="docs-empty">Select a document</div>
        )}
      </main>

      {/* Table of Contents (three-column only) */}
      {layout === 'three-column' && content && (
        <aside className="admin-docs-layout__toc">
          <OnThisPageNav content={content.content} />
        </aside>
      )}
    </div>
  );
}

// --- Supporting Components ---
// These are simplified versions. See separate template files for full implementations.

function DocTree({
  nodes,
  currentPath,
  onSelect,
}: {
  nodes: DocNode[];
  currentPath: string;
  onSelect: (path: string) => void;
}) {
  return (
    <nav className="doc-tree" aria-label="Documentation">
      <ul className="doc-tree__list">
        {nodes.map(node => (
          <DocTreeItem
            key={node.path}
            node={node}
            currentPath={currentPath}
            onSelect={onSelect}
          />
        ))}
      </ul>
    </nav>
  );
}

function DocTreeItem({
  node,
  currentPath,
  onSelect,
  depth = 0,
}: {
  node: DocNode;
  currentPath: string;
  onSelect: (path: string) => void;
  depth?: number;
}) {
  const [expanded, setExpanded] = useState(currentPath.startsWith(node.path));
  const isActive = currentPath === node.path;

  const handleClick = () => {
    if (node.type === 'folder') {
      setExpanded(!expanded);
    } else {
      onSelect(node.path);
    }
  };

  return (
    <li className="doc-tree-item">
      <button
        className={`doc-tree-item__button ${isActive ? 'doc-tree-item__button--active' : ''}`}
        onClick={handleClick}
        style={{ paddingLeft: `${depth * 12 + 8}px` }}
      >
        <span className="doc-tree-item__icon">
          {node.type === 'folder' ? (expanded ? '📂' : '📁') : '📄'}
        </span>
        <span className="doc-tree-item__name">
          {node.name.replace('.md', '')}
        </span>
      </button>

      {node.type === 'folder' && expanded && node.children && (
        <ul className="doc-tree-item__children">
          {node.children.map(child => (
            <DocTreeItem
              key={child.path}
              node={child}
              currentPath={currentPath}
              onSelect={onSelect}
              depth={depth + 1}
            />
          ))}
        </ul>
      )}
    </li>
  );
}

function MermaidMarkdown({ content }: { content: string }) {
  // Simplified version - see mermaid-markdown.tsx for full implementation
  return (
    <div
      className="markdown-content"
      dangerouslySetInnerHTML={{ __html: content }}
    />
  );
}

function OnThisPageNav({ content }: { content: string }) {
  const headings = extractHeadings(content);

  if (headings.length === 0) return null;

  return (
    <nav className="on-this-page" aria-label="On this page">
      <h4 className="on-this-page__title">On this page</h4>
      <ul className="on-this-page__list">
        {headings.map(h => (
          <li
            key={h.id}
            className="on-this-page__item"
            style={{ paddingLeft: `${(h.level - 2) * 12}px` }}
          >
            <a href={`#${h.id}`} className="on-this-page__link">
              {h.text}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  );
}

function extractHeadings(content: string) {
  const headings: { id: string; text: string; level: number }[] = [];
  const lines = content.split('\n');

  for (const line of lines) {
    const match = line.match(/^(#{2,4})\s+(.+)$/);
    if (match) {
      const level = match[1].length;
      const text = match[2].trim();
      const id = text.toLowerCase().replace(/[^\w\s-]/g, '').replace(/\s+/g, '-');
      headings.push({ id, text, level });
    }
  }

  return headings;
}

// --- Styles ---
// Include these in your CSS or use CSS-in-JS

export const styles = `
.admin-docs-layout {
  display: flex;
  min-height: 100vh;
}

.admin-docs-layout__tree {
  width: 250px;
  flex-shrink: 0;
  border-right: 1px solid var(--border, #e5e7eb);
  overflow-y: auto;
  padding: 1rem;
}

.admin-docs-layout__content {
  flex: 1;
  padding: 2rem;
  overflow-y: auto;
}

.admin-docs-layout__toc {
  width: 200px;
  flex-shrink: 0;
  padding: 1rem;
  border-left: 1px solid var(--border, #e5e7eb);
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
}

.admin-docs-layout--two-column .admin-docs-layout__toc {
  display: none;
}

.admin-docs-layout--single {
  flex-direction: column;
}

.admin-docs-layout--single .admin-docs-layout__tree {
  width: 100%;
  border-right: none;
  border-bottom: 1px solid var(--border, #e5e7eb);
}

.doc-tree__list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.doc-tree-item__button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  width: 100%;
  padding: 0.5rem;
  border: none;
  background: none;
  cursor: pointer;
  text-align: left;
  border-radius: 0.25rem;
}

.doc-tree-item__button:hover {
  background: var(--bg-hover, #f3f4f6);
}

.doc-tree-item__button--active {
  background: var(--bg-active, #e5e7eb);
  font-weight: 500;
}

.doc-tree-item__children {
  list-style: none;
  padding: 0;
  margin: 0;
}

.on-this-page__title {
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted, #6b7280);
  margin-bottom: 0.5rem;
}

.on-this-page__list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.on-this-page__link {
  display: block;
  padding: 0.25rem 0;
  color: var(--text-secondary, #6b7280);
  text-decoration: none;
  font-size: 0.875rem;
}

.on-this-page__link:hover {
  color: var(--text-primary, #1a1a1a);
}
`;

export default DocsViewerPage;
