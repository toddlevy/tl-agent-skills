# tl-complexity-assessment

Systematic complexity assessment for TypeScript/JavaScript codebases. Identifies monoliths, god files, coupling hotspots, and component smells.

## Quick Start

```bash
# Run automated scan
./scripts/complexity-scan.sh src/

# Or on Windows
.\scripts\complexity-scan.ps1 -TargetDir src/
```

## What It Detects

| Category | Indicators |
|----------|------------|
| **Size** | Large files (>300 lines), large components, long functions |
| **Responsibility** | High export count, multiple classes per file |
| **Coupling** | High import count, cross-domain imports, circular deps |
| **Cyclomatic** | Nested conditionals, switch complexity, callback depth |
| **React-specific** | Multiple hooks, inline sub-components, props explosion |
| **Structural** | God files (utils.ts), barrel bloat, mixed concerns |

## Resources

| File | Purpose |
|------|---------|
| `SKILL.md` | Full methodology with thresholds and workflow |
| `references/react-patterns.md` | React-specific complexity patterns |
| `references/coupling-analysis.md` | Import/dependency analysis techniques |
| `references/refactoring-strategies.md` | How to split identified hotspots |
| `scripts/complexity-scan.sh` | Automated discovery (bash) |
| `scripts/complexity-scan.ps1` | Automated discovery (PowerShell) |

## ROI Prioritization

Findings are prioritized by **ROI = Severity × (4 - Effort)**:

| Severity | E0 (<1h) | E1 (1-4h) | E2 (4-8h) | E3 (>8h) |
|----------|----------|-----------|-----------|----------|
| Critical | 12 🔥 | 9 🔥 | 6 | 3 |
| High | 8 | 6 | 4 | 2 |
| Medium | 4 | 3 | 2 | 1 |

Address 🔥 findings first.

## Quilted Skill

This skill synthesizes best practices from:

- [trailofbits/code-maturity-assessor](https://skills.sh/trailofbits/skills/code-maturity-assessor) - Assessment framework
- [obra/superpowers](https://skills.sh/obra/superpowers/systematic-debugging) - Evidence-based methodology
- [codebase-audit](local) - ROI prioritization matrix

See SKILL.md frontmatter for full attribution.
