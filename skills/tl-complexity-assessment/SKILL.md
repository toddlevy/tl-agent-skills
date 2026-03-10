---
name: tl-complexity-assessment
description: Systematic complexity assessment for TypeScript/JavaScript codebases. Identifies monoliths, god files, coupling hotspots, and component smells. Use when auditing complexity, planning refactors, or finding files to split up.
version: 1.0.0
license: MIT
author: Todd Levy <toddlevy@gmail.com>
metadata:
  moment: review
  surface:
    - repo
  output: analysis
  risk: safe
  effort: moderate
  posture: guided
  agentFit: repo-read
  dryRun: none
  quilted:
    version: 1
    synthesized: 2026-03-10
    sources:
      - url: https://skills.sh/trailofbits/skills/code-maturity-assessor
        borrowed:
          - 9-category assessment framework
          - Rating system (0-4)
          - Phase structure
          - Rationalizations table
        weight: 0.30
      - url: local://tl-agent-skills/codebase-audit
        borrowed:
          - Severity/Effort ROI matrix
          - Time-boxing guidelines
          - Discovery commands
          - Evidence requirements
        weight: 0.25
      - url: https://skills.sh/obra/superpowers/systematic-debugging
        borrowed:
          - Iron Law pattern
          - Phase gates
          - Red flags section
        weight: 0.20
      - url: https://skills.sh/obra/superpowers/verification-before-completion
        borrowed:
          - Evidence before claims principle
          - Rationalization prevention
        weight: 0.15
      - url: https://skills.sh/rmyndharis/antigravity-skills/code-refactoring-refactor-clean
        borrowed:
          - SOLID assessment criteria
          - Code smell categories
        weight: 0.10
    enhancements:
      - TypeScript/React-specific heuristics with numeric thresholds
      - Automated detection commands with ripgrep/find
      - Unified complexity scoring (0-10 scale)
      - Split-recommendation output format
---

# Complexity Assessment

Systematic detection of complexity hotspots, monoliths, and refactoring candidates in TypeScript/JavaScript codebases.

## When to Use

- "find complex files"
- "what needs to be split up"
- "assess complexity"
- "find monoliths"
- "identify refactoring candidates"
- "code health check"
- Before major refactoring efforts
- When onboarding to a new codebase

## Outcomes

- **Analysis**: Ranked list of complexity hotspots with evidence and recommendations
- **Decision**: Which files/modules to refactor first (ROI-based prioritization)
- **Artifact**: Optional findings register (markdown) for tracking remediation

---

## The Iron Law

```
NO COMPLEXITY CLAIMS WITHOUT EVIDENCE
```

Every finding must include file path, line count or metric, and specific observation.

---

## Assessment Categories

### Category 1: Size Indicators

| Indicator | Threshold | Severity |
|-----------|-----------|----------|
| **File lines** | >500 | High |
| **File lines** | 300-500 | Medium |
| **Function lines** | >50 | High |
| **Function lines** | 30-50 | Medium |
| **Component lines** | >300 | High |
| **Component lines** | 150-300 | Medium |

### Category 2: Responsibility Indicators

| Indicator | Threshold | Severity |
|-----------|-----------|----------|
| **Exports per file** | >10 | High |
| **Exports per file** | 6-10 | Medium |
| **Classes per file** | >2 | High |
| **Functions per file** | >15 | Medium |

### Category 3: Coupling Indicators

| Indicator | Threshold | Severity |
|-----------|-----------|----------|
| **Import statements** | >20 | High |
| **Import statements** | 10-20 | Medium |
| **Cross-domain imports** | >5 distinct domains | High |
| **Circular dependencies** | Any | Critical |

### Category 4: Cyclomatic Complexity Proxies

| Indicator | Threshold | Severity |
|-----------|-----------|----------|
| **Nested conditionals** | >3 levels deep | High |
| **Switch cases** | >7 cases | Medium |
| **Ternary chains** | >2 chained | Medium |
| **Callback depth** | >3 levels | High |

### Category 5: React-Specific Smells

| Indicator | Threshold | Severity |
|-----------|-----------|----------|
| **useEffect hooks** | >3 per component | High |
| **useEffect hooks** | 2-3 per component | Medium |
| **useState hooks** | >5 per component | Medium |
| **Inline sub-components** | Any | Medium |
| **Props count** | >7 props | Medium |
| **Business logic in page** | Non-trivial | High |

### Category 6: Structural Smells

| Indicator | Pattern | Severity |
|-----------|---------|----------|
| **God files** | `utils.ts`, `helpers.ts`, `common.ts`, `shared.ts` | High |
| **Catch-all routers** | >10 routes inline | High |
| **Mega schemas** | >10 unrelated tables | High |
| **Mixed concerns** | API + UI in same file | Medium |
| **Barrel bloat** | `index.ts` >50 re-exports | Medium |

---

## Assessment Phases

### Phase 1: Automated Discovery

Run these commands to gather metrics. Adapt paths to your project structure.

**Find large files:**
```bash
find src/ -name "*.ts" -o -name "*.tsx" | xargs wc -l 2>/dev/null | sort -rn | head -30
```

**Count exports per file:**
```bash
rg "^export " --type ts -c | sort -t: -k2 -rn | head -20
```

**Count imports per file:**
```bash
rg "^import " --type ts -c | sort -t: -k2 -rn | head -20
```

**Find god files:**
```bash
rg -l "utils|helpers|common|shared" --type ts --glob "!node_modules" | head -20
```

**Find React components with many hooks:**
```bash
rg "useEffect\(" --type tsx -c | sort -t: -k2 -rn | head -20
```

**Find deeply nested conditionals:**
```bash
rg "if.*if.*if" --type ts -l | head -20
```

**Find files with many functions:**
```bash
rg "^(export )?(async )?(function |const \w+ = )" --type ts -c | sort -t: -k2 -rn | head -20
```

### Phase 2: Manual Analysis

For each candidate file from Phase 1:

1. **Read the file** - Understand what it does
2. **Identify responsibilities** - List distinct concerns
3. **Check coupling** - What does it import from? What imports it?
4. **Assess cohesion** - Do all parts serve a single purpose?
5. **Document evidence** - File path, line count, specific observations

### Phase 3: Scoring

Score each finding 0-10:

| Score | Meaning |
|-------|---------|
| 0-2 | Acceptable - monitor only |
| 3-4 | Low priority - refactor when convenient |
| 5-6 | Medium priority - plan for refactor |
| 7-8 | High priority - refactor soon |
| 9-10 | Critical - blocking quality/velocity |

**Score Formula:**
```
Score = (Severity × 2) + (Impact × 2) + (Effort_Inverse)
```

Where:
- Severity: 1 (Low) to 3 (Critical)
- Impact: 1 (isolated) to 3 (affects many files)
- Effort_Inverse: 3 (easy fix) to 1 (hard fix)

### Phase 4: Report

For each finding, report:

```markdown
### [Rank] File: `path/to/file.ts`

**Score:** 8/10 | **Severity:** High | **Effort:** Medium

**Metrics:**
- Lines: 847
- Exports: 23
- Imports: 18 (from 6 domains)

**Observations:**
- Contains 4 unrelated responsibilities: auth, validation, API calls, formatting
- 3 useEffect hooks managing different concerns
- Imported by 12 other files

**Recommendation:**
Split into:
- `auth.ts` - Authentication utilities
- `validation.ts` - Form validation
- `api.ts` - API client functions
- `formatters.ts` - Display formatting

**Evidence:**
Lines 1-150: Auth functions
Lines 151-320: Validation schemas
Lines 321-600: API calls
Lines 601-847: Formatting utilities
```

---

## Priority Matrix

**ROI = Severity × (4 - Effort)**

| Severity | E0 (<1h) | E1 (1-4h) | E2 (4-8h) | E3 (>8h) |
|----------|----------|-----------|-----------|----------|
| Critical | 12 🔥 | 9 🔥 | 6 | 3 |
| High | 8 | 6 | 4 | 2 |
| Medium | 4 | 3 | 2 | 1 |

🔥 = Address first (ROI ≥ 9)

---

## Red Flags - Stop and Reassess

If you catch yourself:
- Claiming "this file is complex" without metrics
- Recommending splits without identifying responsibilities
- Skipping files because they "look fine"
- Using vague terms like "too big" or "messy"
- Recommending refactors without considering import impact

**Return to Phase 1. Gather evidence.**

---

## Rationalizations (Do Not Skip)

| Rationalization | Why It's Wrong | Required Action |
|-----------------|----------------|-----------------|
| "File is large but organized" | Organization doesn't fix responsibility sprawl | Identify distinct responsibilities, recommend splits |
| "It's a utility file, expected to be big" | Utility files are complexity magnets | Break into domain-specific utilities |
| "Would take too long to refactor" | Note effort, still report finding | Document with E3 effort, let prioritization decide |
| "Tests would break" | Tests prove the split points | Note as consideration, not blocker |
| "Team knows this code" | Tribal knowledge is tech debt | Document for bus factor mitigation |

---

## Time-Boxing Guidelines

| Codebase Size | Discovery | Analysis | Total |
|---------------|-----------|----------|-------|
| Small (<10k LOC) | 30 min | 30 min | 1 hour |
| Medium (10-50k LOC) | 1 hour | 1 hour | 2 hours |
| Large (50k+ LOC) | 2 hours | 2 hours | 4 hours |

**When time expires:** Document what you found. Mark incomplete areas with next actions.

---

## Output Format

Provide a summary table followed by detailed findings:

```markdown
## Complexity Assessment Summary

| Rank | File | Score | Severity | Recommendation |
|------|------|-------|----------|----------------|
| 1 | `src/utils/helpers.ts` | 9 | Critical | Split into 4 domain files |
| 2 | `src/components/Dashboard.tsx` | 8 | High | Extract 3 sub-components |
| 3 | `src/api/client.ts` | 7 | High | Separate by API domain |

### Top Finding Details
[Detailed findings for top 5-10 items]
```

---

## Verification Checklist

Before completing assessment:

- [ ] Ran automated discovery commands
- [ ] Every finding has file path and line count
- [ ] Every finding has specific observations (not vague)
- [ ] Responsibilities identified for each split recommendation
- [ ] Effort estimated for each recommendation
- [ ] Priority calculated using ROI formula
- [ ] Time-boxing respected
- [ ] Summary table provided with top findings

---

## Related Skills

- `tl-knip` - Find unused exports (reduces false positives in export counts)
- `codebase-audit` - Broader code health assessment
- `ui-audit` - UI-specific complexity and drift detection
