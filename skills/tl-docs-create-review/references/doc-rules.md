# Documentation Rules

Create Cursor rules (`.cursor/rules/*.mdc`) to enforce documentation standards. Rules are project-level and trigger on file changes.

---

## Overview

Documentation rules automate maintenance tasks:
- Prompt updates when code changes
- Enforce writing standards
- Track freshness
- Validate links

### When to Create Rules

Rules are created during Phase 5 (Execution) if the user selected rule creation. The AskQuestion flow determines which rules to create.

---

## Available Rule Templates

| Rule | File | Purpose |
|------|------|---------|
| README Sync | `readme-sync.mdc` | Update README when features change |
| CHANGELOG Commits | `changelog-commits.mdc` | Prompt CHANGELOG entry for feat/fix commits |
| API Doc Sync | `api-doc-sync.mdc` | Keep API docs in sync with code |
| AGENTS.md Maintain | `agents-md-maintain.mdc` | Update AGENTS.md when commands change |
| Doc Style | `doc-style.mdc` | Enforce voice, tone, formatting |
| Last Updated | `last-updated.mdc` | Track Last Updated dates |
| Link Check | `link-check.mdc` | Validate internal doc links |

---

## Rule Structure

Rules follow the cursor-rule-create XML schema.

### Basic Template

```xml
---
description: Brief description of what this rule enforces
globs:
  - "pattern/**/*.ext"
  - "other/pattern.ext"
alwaysApply: false
---

<rule>
<meta>
  <title>Rule Title</title>
  <priority>enforce</priority>
  <applies-to>
    <file-matcher glob="pattern/**/*.ext">Description</file-matcher>
  </applies-to>
</meta>

<requirements>
  <non-negotiable priority="critical">
    <description>What MUST happen</description>
    <examples>
      <example type="correct">Good example</example>
      <example type="incorrect">Bad example</example>
    </examples>
  </non-negotiable>
  
  <guideline priority="moderate">
    <description>What SHOULD happen</description>
  </guideline>
</requirements>

<references>
  <reference as="related" href="docs/file.md">Related doc</reference>
</references>
</rule>
```

### Priority Levels

| Priority | Use For |
|----------|---------|
| `enforce` | Must follow, blocks merge |
| `recommend` | Should follow, warn on deviation |
| `suggest` | Nice to have |

---

## Rule Templates

### readme-sync.mdc

Triggers when `package.json` or major source files change.

```xml
---
description: Update README.md when features change
globs:
  - "package.json"
  - "src/**/*.ts"
alwaysApply: false
---

<rule>
<meta>
  <title>README Sync</title>
  <priority>recommend</priority>
  <applies-to>
    <file-matcher glob="package.json">Package changes</file-matcher>
    <file-matcher glob="src/**/*.ts">Source changes</file-matcher>
  </applies-to>
</meta>

<requirements>
  <guideline priority="moderate">
    <description>
      When adding, removing, or significantly changing features, update README.md
      to reflect the changes. Check these sections:
      - Features list
      - Usage examples
      - Configuration options
      - Scripts/commands
    </description>
    <examples>
      <example type="correct">
        Added new `--verbose` flag to CLI.
        Updated README.md Usage section to document the flag.
      </example>
      <example type="incorrect">
        Added new `--verbose` flag to CLI.
        README.md still shows old usage without the flag.
      </example>
    </examples>
  </guideline>
</requirements>

<references>
  <reference as="related" href="README.md">Project README</reference>
</references>
</rule>
```

### changelog-commits.mdc

Prompts for CHANGELOG entry on conventional commits.

```xml
---
description: Add CHANGELOG entry for feat/fix commits
globs:
  - "**/*"
alwaysApply: false
---

<rule>
<meta>
  <title>CHANGELOG from Commits</title>
  <priority>recommend</priority>
</meta>

<requirements>
  <guideline priority="moderate">
    <description>
      When committing with `feat:` or `fix:` prefix, add corresponding entry
      to CHANGELOG.md under [Unreleased] section.
      
      - feat: → Added section
      - fix: → Fixed section
      
      Use human-readable descriptions, not commit message verbatim.
    </description>
    <examples>
      <example type="correct">
        Commit: "feat: add magic link authentication"
        CHANGELOG: "### Added\n- Magic link authentication for passwordless login"
      </example>
      <example type="incorrect">
        Commit: "feat: add magic link authentication"
        No CHANGELOG entry added.
      </example>
    </examples>
  </guideline>
</requirements>

<references>
  <reference as="related" href="CHANGELOG.md">Project CHANGELOG</reference>
</references>
</rule>
```

### api-doc-sync.mdc

Triggers on API route changes.

```xml
---
description: Keep API docs in sync with code changes
globs:
  - "src/routes/**/*.ts"
  - "src/api/**/*.ts"
  - "app/routes/**/*.ts"
alwaysApply: false
---

<rule>
<meta>
  <title>API Doc Sync</title>
  <priority>recommend</priority>
  <applies-to>
    <file-matcher glob="**/routes/**/*.ts">Route handlers</file-matcher>
    <file-matcher glob="**/api/**/*.ts">API endpoints</file-matcher>
  </applies-to>
</meta>

<requirements>
  <guideline priority="moderate">
    <description>
      When adding or modifying API endpoints, update corresponding documentation:
      - Request/response schemas
      - Error codes
      - Examples
      - Required headers/auth
      
      API docs live in docs/reference/api/ or similar.
    </description>
  </guideline>
</requirements>

<references>
  <reference as="related" href="docs/reference/api/">API documentation</reference>
</references>
</rule>
```

### agents-md-maintain.mdc

Triggers when scripts or commands change.

```xml
---
description: Keep AGENTS.md current with project commands
globs:
  - "package.json"
  - "AGENTS.md"
alwaysApply: false
---

<rule>
<meta>
  <title>AGENTS.md Maintenance</title>
  <priority>recommend</priority>
  <applies-to>
    <file-matcher glob="package.json">Script changes</file-matcher>
  </applies-to>
</meta>

<requirements>
  <guideline priority="moderate">
    <description>
      When adding or modifying npm scripts in package.json, update AGENTS.md
      Commands section to reflect the changes.
      
      Keep AGENTS.md under 60 lines. If adding detail, remove something.
    </description>
    <examples>
      <example type="correct">
        Added `test:e2e` script to package.json.
        Added to AGENTS.md: "E2E tests: `pnpm test:e2e`"
      </example>
    </examples>
  </guideline>
</requirements>

<references>
  <reference as="related" href="AGENTS.md">AI assistant context</reference>
</references>
</rule>
```

### doc-style.mdc

Enforces writing standards on all docs.

```xml
---
description: Enforce documentation style standards
globs:
  - "docs/**/*.md"
  - "*.md"
alwaysApply: false
---

<rule>
<meta>
  <title>Documentation Style</title>
  <priority>recommend</priority>
  <applies-to>
    <file-matcher glob="**/*.md">Markdown files</file-matcher>
  </applies-to>
</meta>

<requirements>
  <guideline priority="moderate">
    <description>
      Follow documentation writing standards:
      - Address reader as "you" (not "we")
      - Use "for example" not "e.g."
      - Use serial comma (Oxford comma)
      - Sentence case for headings
      - Overview paragraph after each heading
      - Avoid "simply", "just", "obviously"
    </description>
    <examples>
      <example type="correct">
        "You can configure the server using environment variables."
      </example>
      <example type="incorrect">
        "We can simply configure the server using env vars, e.g. PORT."
      </example>
    </examples>
  </guideline>
</requirements>

<references>
  <reference as="related" href="docs/writing-standards.md">Writing standards</reference>
</references>
</rule>
```

### last-updated.mdc

Tracks freshness with Last Updated dates.

```xml
---
description: Add/update Last Updated dates on doc changes
globs:
  - "docs/**/*.md"
alwaysApply: false
---

<rule>
<meta>
  <title>Last Updated Tracking</title>
  <priority>recommend</priority>
  <applies-to>
    <file-matcher glob="docs/**/*.md">Documentation files</file-matcher>
  </applies-to>
</meta>

<requirements>
  <guideline priority="moderate">
    <description>
      When editing documentation, update the Last Updated blockquote at the
      top of the file (after the H1 title):
      
      > **Last Updated:** YYYY-MM-DD
      
      If not present, add it.
    </description>
    <examples>
      <example type="correct">
        # Configuration
        
        > **Last Updated:** 2026-03-17
        
        Configure the server...
      </example>
    </examples>
  </guideline>
</requirements>
</rule>
```

### link-check.mdc

Validates internal documentation links.

```xml
---
description: Validate internal doc links on save
globs:
  - "docs/**/*.md"
alwaysApply: false
---

<rule>
<meta>
  <title>Link Validation</title>
  <priority>recommend</priority>
  <applies-to>
    <file-matcher glob="docs/**/*.md">Documentation files</file-matcher>
  </applies-to>
</meta>

<requirements>
  <guideline priority="moderate">
    <description>
      When adding or editing links in documentation:
      - Use relative paths for internal docs
      - Verify linked files exist
      - Check anchor links point to valid headings
      - Use descriptive link text (not "click here")
    </description>
    <examples>
      <example type="correct">
        See [Configuration](./config.md) for options.
        See [API Reference](../reference/api/README.md).
      </example>
      <example type="incorrect">
        Click [here](./config.md) for more info.
        See [docs](/absolute/path/breaks.md).
      </example>
    </examples>
  </guideline>
</requirements>
</rule>
```

---

## Integration with Workflow

Rules are created as part of the documentation execution phase:

1. User selects rule creation (Question 6)
2. If "Yes, let me pick" → show rule selection (Question 6b)
3. For each selected rule:
   - Copy template to `.cursor/rules/`
   - Customize globs for project structure
   - Add references to created docs

### Rule Placement

```
.cursor/
└── rules/
    ├── readme-sync.mdc
    ├── changelog-commits.mdc
    └── doc-style.mdc
```

### Customization Points

When creating rules, adjust:
- Glob patterns for project structure
- References to actual doc locations
- Examples relevant to the project
