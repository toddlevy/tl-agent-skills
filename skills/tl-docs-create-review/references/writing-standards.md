# Writing Standards

Standards for documentation voice, tone, formatting, and language. Synthesized from gemini-cli, remotion, and markdown-documentation skills.

---

## Voice and Tone

### Address the Reader Directly

- Use "you" to address the reader
- Avoid "we" (implies team membership)
- Avoid passive voice when active is clearer

| Avoid | Prefer |
|-------|--------|
| "We recommend using..." | "Use..." |
| "The function can be called..." | "Call the function..." |
| "It is suggested that..." | "Consider..." |

### Professional but Not Stiff

- Direct and helpful, not condescending
- Confident without being dismissive
- Technical accuracy over friendliness

### No Blame

Never blame the user for errors or misunderstandings.

| Avoid | Prefer |
|-------|--------|
| "You provided an invalid input" | "The input is invalid" |
| "You forgot to configure..." | "Configuration required:..." |
| "If you had read the docs..." | Never write this |

### No Assumptions

Avoid words that assume simplicity or prior knowledge.

| Avoid | Why |
|-------|-----|
| "simply" | Implies task is trivial |
| "just" | Dismisses complexity |
| "obviously" | Condescending |
| "of course" | Assumes shared knowledge |
| "easy" | Subjective |

---

## Language Rules

### No Latin Abbreviations

Use full English phrases. Latin abbreviations are ambiguous.

| Avoid | Use |
|-------|-----|
| e.g. | for example |
| i.e. | that is |
| etc. | and so on |
| N.B. | note |
| viz. | namely |

### Serial Comma (Oxford Comma)

Always use the serial comma before the final item in a list.

| Avoid | Prefer |
|-------|--------|
| "red, white and blue" | "red, white, and blue" |
| "setup, build and deploy" | "setup, build, and deploy" |

### Sentence Case for Headings

Use sentence case (capitalize first word only) for headings, titles, and bolded text.

| Avoid | Prefer |
|-------|--------|
| "Getting Started With the API" | "Getting started with the API" |
| "Installation And Setup" | "Installation and setup" |

Exception: Proper nouns retain capitalization ("Working with PostgreSQL").

### Present Tense

Use present tense for descriptions of current behavior.

| Avoid | Prefer |
|-------|--------|
| "This will create a file" | "This creates a file" |
| "The function would return..." | "The function returns..." |

### Active Voice

Active voice is more direct and easier to understand.

| Passive (avoid) | Active (prefer) |
|-----------------|-----------------|
| "The config is read by the server" | "The server reads the config" |
| "Files are created in the output dir" | "The tool creates files in the output dir" |

---

## Formatting

### 80-Character Wrap

Wrap text at 80 characters for readability in editors and diffs.

```markdown
This is a sentence that demonstrates proper line wrapping. When your sentence
approaches 80 characters, wrap to the next line at a natural break point.
```

### Overview After Every Heading

Every heading needs an introductory paragraph before any subheadings or lists.

**Wrong:**
```markdown
## Configuration

### Required Options

- `port`: The server port
```

**Correct:**
```markdown
## Configuration

Configure the server using environment variables or a config file. All options
have sensible defaults except where noted.

### Required options

- `port`: The server port
```

### Heading Levels

- Use `#` for the document title (once per file)
- Use `##` for major sections
- Use `###` for subsections
- Avoid going beyond `####`

### Code Blocks

- Always specify language for syntax highlighting
- Use appropriate language tags: `bash`, `typescript`, `json`, etc.
- Use `console` for mixed command/output

```typescript
const config = loadConfig();
```

### Lists

- Use `-` for unordered lists (not `*`)
- Use `1.` for ordered lists (sequential numbering)
- Include blank line before and after lists
- Keep list items parallel in structure

---

## Brevity

### Developers Don't Read

From remotion skill: **Extra words are information loss.** Every unnecessary word makes essential information harder to find.

| Verbose | Concise |
|---------|---------|
| "In order to..." | "To..." |
| "It is important to note that..." | (Delete, just state it) |
| "Please be aware that..." | (Delete, just state it) |
| "The following is a list of..." | (Just show the list) |

### One Concept Per Paragraph

Don't combine multiple ideas. Split into separate paragraphs or use lists.

### Tables Over Prose

When comparing options or listing attributes, use tables instead of prose descriptions.

---

## Links and References

### Descriptive Link Text

Links should describe their destination. Avoid "click here" or "this link."

| Avoid | Prefer |
|-------|--------|
| "Click [here](./config.md) for config" | "See [Configuration](./config.md)" |
| "[This](./api.md) explains the API" | "See the [API reference](./api.md)" |

### Relative Paths

Use relative paths for internal documentation links to work across environments.

```markdown
See [Configuration](./config.md)
See [API Reference](../api/README.md)
```

### External Links

For external links, include the domain or source for clarity.

```markdown
See the [PostgreSQL documentation](https://postgresql.org/docs/)
```

---

## Accessibility

### Alt Text for Images

All images require descriptive alt text.

```markdown
![Architecture diagram showing client, API, and database layers](./arch.png)
```

### Color Independence

Don't rely solely on color to convey information. Use text labels, patterns, or shapes in addition to color.

### Semantic Structure

Use headings in proper hierarchy. Don't skip levels for visual styling.

---

## Do/Don't Quick Reference

### Do

- Address reader as "you"
- Use present tense
- Use active voice
- Use serial comma
- Use sentence case for headings
- Provide overview after each heading
- Keep paragraphs focused on one idea
- Use tables for comparisons
- Use relative links for internal docs

### Don't

- Use Latin abbreviations (e.g., i.e., etc.)
- Use "we" or passive voice unnecessarily
- Blame the user for errors
- Use "simply," "just," "obviously"
- Start with filler phrases
- Skip heading levels
- Use "click here" for links
- Omit alt text for images
