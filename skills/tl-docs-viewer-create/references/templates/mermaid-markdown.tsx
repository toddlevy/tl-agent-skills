/**
 * Mermaid Markdown Renderer
 *
 * Renders markdown content with Mermaid diagram support.
 * Includes syntax highlighting and dark mode support.
 *
 * @example
 * ```tsx
 * <MermaidMarkdown content={markdownContent} />
 * ```
 *
 * @requires @uiw/react-markdown-preview or react-markdown
 * @requires mermaid
 */

import { useEffect, useRef, useState } from 'react';

// Uncomment ONE of the following imports based on your library choice:

// Option 1: @uiw/react-markdown-preview
// import MarkdownPreview from '@uiw/react-markdown-preview';

// Option 2: react-markdown
// import ReactMarkdown from 'react-markdown';
// import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
// import { oneDark, oneLight } from 'react-syntax-highlighter/dist/esm/styles/prism';

// Mermaid (optional - only if enableMermaid is true)
// import mermaid from 'mermaid';

interface MermaidMarkdownProps {
  content: string;
  className?: string;
  enableMermaid?: boolean;
}

// Detect dark mode
function isDarkMode(): boolean {
  if (typeof document === 'undefined') return false;
  return document.documentElement.getAttribute('data-theme') === 'dark';
}

// Initialize Mermaid (call once)
let mermaidInitialized = false;

async function initMermaid() {
  if (mermaidInitialized) return;

  try {
    const mermaid = await import('mermaid');
    mermaid.default.initialize({
      startOnLoad: false,
      theme: isDarkMode() ? 'dark' : 'default',
      securityLevel: 'loose',
      fontFamily: 'inherit',
    });
    mermaidInitialized = true;
  } catch (error) {
    console.warn('[TLDOCS] Mermaid not available:', error);
  }
}

// Render Mermaid diagrams in a container
async function renderMermaidDiagrams(container: HTMLElement) {
  try {
    const mermaid = await import('mermaid');
    const blocks = container.querySelectorAll('pre code.language-mermaid, .language-mermaid');

    for (let i = 0; i < blocks.length; i++) {
      const block = blocks[i] as HTMLElement;
      const code = block.textContent || '';
      const id = `mermaid-diagram-${Date.now()}-${i}`;

      try {
        const { svg } = await mermaid.default.render(id, code);
        const wrapper = document.createElement('div');
        wrapper.className = 'mermaid-diagram';
        wrapper.innerHTML = svg;
        block.parentElement?.replaceWith(wrapper);
      } catch (renderError) {
        console.error('[TLDOCS] Mermaid render error:', renderError);
        block.innerHTML = `<span class="mermaid-error">Diagram error: ${renderError}</span>`;
      }
    }
  } catch (error) {
    console.warn('[TLDOCS] Mermaid rendering skipped:', error);
  }
}

// Main component - using @uiw/react-markdown-preview
export function MermaidMarkdown({
  content,
  className = '',
  enableMermaid = true,
}: MermaidMarkdownProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [mounted, setMounted] = useState(false);

  // Initialize Mermaid on mount
  useEffect(() => {
    if (enableMermaid) {
      initMermaid();
    }
    setMounted(true);
  }, [enableMermaid]);

  // Render Mermaid diagrams after content updates
  useEffect(() => {
    if (mounted && enableMermaid && containerRef.current) {
      const timeoutId = setTimeout(() => {
        renderMermaidDiagrams(containerRef.current!);
      }, 100);
      return () => clearTimeout(timeoutId);
    }
  }, [content, mounted, enableMermaid]);

  // Simple markdown rendering (replace with your chosen library)
  // This is a placeholder - use MarkdownPreview or ReactMarkdown in production
  return (
    <div ref={containerRef} className={`markdown-content ${className}`}>
      <MarkdownRenderer content={content} />
    </div>
  );
}

// Placeholder renderer - replace with actual library
function MarkdownRenderer({ content }: { content: string }) {
  // For @uiw/react-markdown-preview:
  // return <MarkdownPreview source={content} />;

  // For react-markdown:
  // return (
  //   <ReactMarkdown
  //     components={{
  //       code({ node, inline, className, children, ...props }) {
  //         const match = /language-(\w+)/.exec(className || '');
  //         const language = match ? match[1] : '';
  //
  //         if (!inline && language) {
  //           return (
  //             <SyntaxHighlighter
  //               style={isDarkMode() ? oneDark : oneLight}
  //               language={language}
  //               {...props}
  //             >
  //               {String(children).replace(/\n$/, '')}
  //             </SyntaxHighlighter>
  //           );
  //         }
  //
  //         return <code className={className} {...props}>{children}</code>;
  //       },
  //     }}
  //   >
  //     {content}
  //   </ReactMarkdown>
  // );

  // Fallback: dangerouslySetInnerHTML (not recommended for production)
  return (
    <div
      className="markdown-body"
      dangerouslySetInnerHTML={{
        __html: simpleMarkdownToHtml(content),
      }}
    />
  );
}

// Very basic markdown to HTML (for demo only - use a real library)
function simpleMarkdownToHtml(markdown: string): string {
  let html = markdown
    // Headers
    .replace(/^### (.*$)/gim, '<h3>$1</h3>')
    .replace(/^## (.*$)/gim, '<h2>$1</h2>')
    .replace(/^# (.*$)/gim, '<h1>$1</h1>')
    // Bold and italic
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    // Code blocks
    .replace(/```(\w+)?\n([\s\S]*?)```/g, '<pre><code class="language-$1">$2</code></pre>')
    // Inline code
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    // Links
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>')
    // Paragraphs
    .replace(/\n\n/g, '</p><p>')
    // Line breaks
    .replace(/\n/g, '<br>');

  return `<p>${html}</p>`;
}

// Styles
export const styles = `
.markdown-content {
  line-height: 1.7;
  color: var(--text-primary, #1f2937);
}

.markdown-content h1,
.markdown-content h2,
.markdown-content h3,
.markdown-content h4 {
  margin-top: 1.5em;
  margin-bottom: 0.5em;
  font-weight: 600;
  line-height: 1.3;
}

.markdown-content h1 { font-size: 2rem; }
.markdown-content h2 { font-size: 1.5rem; }
.markdown-content h3 { font-size: 1.25rem; }
.markdown-content h4 { font-size: 1rem; }

.markdown-content p {
  margin: 1em 0;
}

.markdown-content code {
  padding: 0.2em 0.4em;
  background: var(--bg-code, #f3f4f6);
  border-radius: 0.25rem;
  font-size: 0.875em;
  font-family: ui-monospace, monospace;
}

.markdown-content pre {
  padding: 1rem;
  background: var(--bg-code-block, #1f2937);
  border-radius: 0.5rem;
  overflow-x: auto;
}

.markdown-content pre code {
  padding: 0;
  background: transparent;
  color: var(--text-code, #e5e7eb);
}

.markdown-content a {
  color: var(--link, #3b82f6);
  text-decoration: none;
}

.markdown-content a:hover {
  text-decoration: underline;
}

.markdown-content ul,
.markdown-content ol {
  padding-left: 1.5em;
  margin: 1em 0;
}

.markdown-content li {
  margin: 0.25em 0;
}

.markdown-content blockquote {
  margin: 1em 0;
  padding: 0.5em 1em;
  border-left: 4px solid var(--border, #e5e7eb);
  background: var(--bg-blockquote, #f9fafb);
  color: var(--text-secondary, #4b5563);
}

.markdown-content table {
  width: 100%;
  border-collapse: collapse;
  margin: 1em 0;
}

.markdown-content th,
.markdown-content td {
  padding: 0.5rem;
  border: 1px solid var(--border, #e5e7eb);
  text-align: left;
}

.markdown-content th {
  background: var(--bg-table-header, #f3f4f6);
  font-weight: 600;
}

/* Mermaid diagrams */
.mermaid-diagram {
  margin: 1em 0;
  display: flex;
  justify-content: center;
}

.mermaid-diagram svg {
  max-width: 100%;
  height: auto;
}

.mermaid-error {
  padding: 1rem;
  background: var(--bg-error, #fef2f2);
  color: var(--text-error, #dc2626);
  border-radius: 0.5rem;
  font-family: ui-monospace, monospace;
  font-size: 0.875rem;
}

/* Dark mode */
[data-theme="dark"] .markdown-content {
  color: var(--text-primary, #f3f4f6);
}

[data-theme="dark"] .markdown-content code {
  background: var(--bg-code, #374151);
}

[data-theme="dark"] .markdown-content blockquote {
  background: var(--bg-blockquote, #1f2937);
  border-left-color: var(--border, #374151);
}

[data-theme="dark"] .markdown-content th {
  background: var(--bg-table-header, #374151);
}
`;

export default MermaidMarkdown;
