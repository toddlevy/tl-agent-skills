# Mermaid Markdown Template

Markdown renderer with Mermaid diagram support.

## Overview

The `MermaidMarkdown` component:

1. Renders markdown content with syntax highlighting
2. Detects and renders Mermaid diagram code blocks
3. Supports dark mode
4. Handles render errors gracefully

## Library Options

### @uiw/react-markdown-preview (Recommended)

Full-featured, includes syntax highlighting out of the box.

```bash
pnpm add @uiw/react-markdown-preview mermaid
```

### react-markdown

Lightweight, more customizable.

```bash
pnpm add react-markdown react-syntax-highlighter mermaid
```

## Usage

```tsx
import { MermaidMarkdown } from './mermaid-markdown';

<MermaidMarkdown content={markdownContent} />
```

## Props

| Prop | Type | Description |
|------|------|-------------|
| `content` | `string` | Markdown content |
| `className` | `string` | Additional CSS class |
| `enableMermaid` | `boolean` | Enable Mermaid rendering (default: true) |

## Mermaid Configuration

Customize Mermaid initialization:

```tsx
mermaid.initialize({
  startOnLoad: false,
  theme: 'default', // or 'dark', 'forest', 'neutral'
  securityLevel: 'loose',
  fontFamily: 'inherit',
});
```

## Dark Mode

The component detects `[data-theme="dark"]` on `document.documentElement` and applies the appropriate Mermaid theme.

## Error Handling

Invalid Mermaid syntax displays an error message instead of breaking the render:

```tsx
try {
  const { svg } = await mermaid.render(id, code);
  element.innerHTML = svg;
} catch (error) {
  element.innerHTML = `<pre class="mermaid-error">${error.message}</pre>`;
}
```

## See Also

- [mermaid-markdown.tsx](./mermaid-markdown.tsx) — Full implementation
- [react-components.md](../react-components.md) — Component architecture
