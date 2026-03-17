/**
 * Documentation Tree Navigation
 *
 * Recursive tree component for browsing documentation structure.
 * Handles expand/collapse, current path highlighting, and selection.
 *
 * @example
 * ```tsx
 * <DocTree
 *   nodes={treeData}
 *   currentPath="docs/developer/architecture.md"
 *   onSelect={(path) => navigate(path)}
 * />
 * ```
 */

import { useState, useCallback, useEffect } from 'react';

// Types
export interface DocNode {
  name: string;
  path: string;
  type: 'file' | 'folder';
  children?: DocNode[];
}

interface DocTreeProps {
  nodes: DocNode[];
  currentPath: string;
  onSelect: (path: string) => void;
}

interface DocTreeItemProps {
  node: DocNode;
  currentPath: string;
  onSelect: (path: string) => void;
  depth?: number;
}

// Icons - replace with your icon library if desired
function ChevronIcon({ expanded }: { expanded: boolean }) {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 16 16"
      fill="none"
      style={{
        transform: expanded ? 'rotate(90deg)' : 'rotate(0deg)',
        transition: 'transform 0.15s ease',
      }}
    >
      <path
        d="M6 4L10 8L6 12"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function FileIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
      <path
        d="M9 1H4C3.44772 1 3 1.44772 3 2V14C3 14.5523 3.44772 15 4 15H12C12.5523 15 13 14.5523 13 14V5L9 1Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M9 1V5H13"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function FolderIcon({ open }: { open: boolean }) {
  if (open) {
    return (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
        <path
          d="M14 13H2V5H14V13Z"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M2 5V3H6L8 5H14"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    );
  }

  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
      <path
        d="M14 5V13H2V3H6L8 5H14Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

// Main tree component
export function DocTree({ nodes, currentPath, onSelect }: DocTreeProps) {
  return (
    <nav className="doc-tree" aria-label="Documentation navigation">
      <ul className="doc-tree__list" role="tree">
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

// Tree item component
export function DocTreeItem({
  node,
  currentPath,
  onSelect,
  depth = 0,
}: DocTreeItemProps) {
  const isActive = currentPath === node.path;
  const isAncestor = currentPath.startsWith(node.path + '/');
  const [expanded, setExpanded] = useState(isAncestor || isActive);

  // Auto-expand when navigating to a nested document
  useEffect(() => {
    if (isAncestor && !expanded) {
      setExpanded(true);
    }
  }, [isAncestor, expanded]);

  const handleClick = useCallback(() => {
    if (node.type === 'folder') {
      setExpanded(prev => !prev);
    } else {
      onSelect(node.path);
    }
  }, [node, onSelect]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      switch (e.key) {
        case 'Enter':
        case ' ':
          e.preventDefault();
          handleClick();
          break;
        case 'ArrowRight':
          if (node.type === 'folder' && !expanded) {
            e.preventDefault();
            setExpanded(true);
          }
          break;
        case 'ArrowLeft':
          if (node.type === 'folder' && expanded) {
            e.preventDefault();
            setExpanded(false);
          }
          break;
      }
    },
    [node, expanded, handleClick]
  );

  const displayName = node.name.replace('.md', '');
  const indent = depth * 16 + 8;

  return (
    <li
      className="doc-tree-item"
      role="treeitem"
      aria-expanded={node.type === 'folder' ? expanded : undefined}
      aria-selected={isActive}
    >
      <button
        className={`doc-tree-item__button ${isActive ? 'doc-tree-item__button--active' : ''}`}
        onClick={handleClick}
        onKeyDown={handleKeyDown}
        style={{ paddingLeft: `${indent}px` }}
        aria-current={isActive ? 'page' : undefined}
      >
        <span className="doc-tree-item__toggle">
          {node.type === 'folder' ? (
            <ChevronIcon expanded={expanded} />
          ) : (
            <span style={{ width: 16 }} />
          )}
        </span>
        <span className="doc-tree-item__icon">
          {node.type === 'folder' ? (
            <FolderIcon open={expanded} />
          ) : (
            <FileIcon />
          )}
        </span>
        <span className="doc-tree-item__name">{displayName}</span>
      </button>

      {node.type === 'folder' && expanded && node.children && (
        <ul className="doc-tree-item__children" role="group">
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

// Styles
export const styles = `
.doc-tree {
  font-size: 0.875rem;
}

.doc-tree__list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.doc-tree-item__button {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  width: 100%;
  padding: 0.375rem 0.5rem;
  border: none;
  background: none;
  cursor: pointer;
  text-align: left;
  border-radius: 0.375rem;
  color: var(--text-secondary, #4b5563);
  transition: background-color 0.15s, color 0.15s;
}

.doc-tree-item__button:hover {
  background: var(--bg-hover, #f3f4f6);
  color: var(--text-primary, #1f2937);
}

.doc-tree-item__button:focus-visible {
  outline: 2px solid var(--focus-ring, #3b82f6);
  outline-offset: -2px;
}

.doc-tree-item__button--active {
  background: var(--bg-active, #e5e7eb);
  color: var(--text-primary, #1f2937);
  font-weight: 500;
}

.doc-tree-item__toggle {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 16px;
  height: 16px;
  flex-shrink: 0;
  color: var(--text-muted, #9ca3af);
}

.doc-tree-item__icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 16px;
  height: 16px;
  flex-shrink: 0;
  color: var(--text-muted, #9ca3af);
}

.doc-tree-item__button:hover .doc-tree-item__icon,
.doc-tree-item__button--active .doc-tree-item__icon {
  color: var(--text-secondary, #4b5563);
}

.doc-tree-item__name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.doc-tree-item__children {
  list-style: none;
  padding: 0;
  margin: 0;
}

/* Dark mode */
[data-theme="dark"] .doc-tree-item__button {
  color: var(--text-secondary, #a1a1aa);
}

[data-theme="dark"] .doc-tree-item__button:hover {
  background: var(--bg-hover, #27272a);
  color: var(--text-primary, #fafafa);
}

[data-theme="dark"] .doc-tree-item__button--active {
  background: var(--bg-active, #3f3f46);
  color: var(--text-primary, #fafafa);
}
`;

export default DocTree;
