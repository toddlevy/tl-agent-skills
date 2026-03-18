---
name: tl-complexity-assessment
description: Find large files, god modules, and refactoring candidates in TypeScript/JavaScript/React codebases. Use when files feel "too big", planning a refactor sprint, onboarding to legacy code, or asking "what should I split up?"
license: MIT
version: "1.2"
quilted:
  - source: trailofbits/skills/code-maturity-assessor
    weight: 0.30
    description: Assessment framework, rating system (0-4), phase structure
  - source: tl-agent-skills/codebase-audit
    weight: 0.25
    description: Severity/Effort ROI matrix, time-boxing, discovery commands
  - source: obra/superpowers/systematic-debugging
    weight: 0.20
    description: Iron Law pattern, phase gates, red flags
  - source: obra/superpowers/verification-before-completion
    weight: 0.15
    description: Evidence before claims, rationalization prevention
  - source: rmyndharis/antigravity-skills/code-refactoring-refactor-clean
    weight: 0.10
    description: SOLID assessment criteria, code smell categories
metadata:
  version: 1.1.0
  author: Todd Levy <toddlevy@gmail.com>
  moment: review
  surface:
    - repo
  output: analysis
  risk: safe
  effort: moderate
  posture: guided
  agentFit: repo-read
  dryRun: none
---

# tl-complexity-assessment

Find the files that need to be split up. Get a ranked, evidence-based list of complexity hotspots with specific refactoring recommendations.

## Quick Start

**For experienced users** — run the scanner and get a report:

```bash
# Bash
./scripts/complexity-scan.sh src/

# PowerShell
.\scripts\complexity-scan.ps1 -TargetDir src/
```

**For guided assessment** — follow the phases below.

---

## When to Use

- "find complex files"
- "what needs to be split up"
- "assess complexity" / "code health check"
- "find monoliths" / "find god files"
- "identify refactoring candidates"
- "this file is too big"
- Before major refactoring efforts
- When onboarding to a new codebase
- Sprint planning for tech debt reduction

## Do Not Use When

- Looking for **bugs** (use debugging skills instead)
- Assessing **security** vulnerabilities (use security audit)
- Reviewing **code style** (use linting/formatting tools)
- File is already small and focused (<150 lines, single responsibility)

## Outcomes

- **Analysis**: Ranked list of complexity hotspots with evidence and recommendations
- **Decision**: Which files/modules to refactor first (ROI-based prioritization)
- **Artifact**: Optional findings register (markdown) for tracking remediation
- **Next Steps**: Clear refactoring recommendations for each finding

---

## The Iron Law

```
NO COMPLEXITY CLAIMS WITHOUT EVIDENCE
```

Every finding must include file path, line count or metric, and specific observation.

### What Good Looks Like

```
❌ BAD: "UserService.ts is too complex and should be refactored"

✅ GOOD: "UserService.ts (847 lines, 23 exports) mixes 4 concerns:
   - Authentication (lines 1-150)
   - Validation (lines 151-320)  
   - API calls (lines 321-600)
   - Formatting (lines 601-847)
   
   Recommendation: Split into auth.ts, validation.ts, api.ts, formatters.ts
   Effort: E2 (4-8 hours) | Impact: High (imported by 12 files)"
```

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

### Example Real Output

```markdown
## Complexity Assessment Summary

| Rank | File | Score | Severity | Recommendation |
|------|------|-------|----------|----------------|
| 1 | `src/lib/api-client.ts` | 9 | Critical | Split by domain |
| 2 | `src/pages/Dashboard.tsx` | 8 | High | Extract widgets |
| 3 | `src/hooks/useForm.ts` | 6 | Medium | Separate validation |

### #1 File: `src/lib/api-client.ts`

**Score:** 9/10 | **Severity:** Critical | **Effort:** E2 (4-8h)

**Metrics:**
- Lines: 1,247
- Exports: 34
- Imports: 22 (from 8 domains)

**Observations:**
- Handles ALL API endpoints in one file
- Mixes auth, users, products, orders, analytics
- Contains retry logic duplicated 6 times
- No separation between fetch and transform

**Recommendation:**
Split into domain-specific clients:
- `api/auth.ts` - Login, logout, refresh
- `api/users.ts` - CRUD + search
- `api/products.ts` - Catalog operations
- `api/orders.ts` - Order management
- `api/http.ts` - Shared fetch wrapper with retry

**Evidence:**
- Lines 1-180: Auth functions (login, logout, refresh, verify)
- Lines 181-450: User CRUD (getUser, updateUser, searchUsers...)
- Lines 451-780: Product operations
- Lines 781-1100: Order management
- Lines 1101-1247: Analytics tracking
```

---

## What To Do After Assessment

Once you have findings, here's how to act on them:

### Immediate (This Sprint)
1. **Fix 🔥 Critical findings** (ROI ≥ 9) - These block velocity
2. Run `tl-knip` to remove dead exports before splitting
3. Add tests for files you're about to split

### Plan (Next Sprint)
1. Create tickets for High-priority findings (score 7-8)
2. Group related splits (e.g., all API files together)
3. Estimate using the Effort column

### Monitor (Ongoing)
1. Re-run assessment monthly to catch new complexity
2. Add complexity checks to PR reviews
3. Set team threshold: "No new files over 300 lines without review"

---

## Cognitive vs Cyclomatic Complexity

**Cyclomatic complexity** counts decision points (branches). **Cognitive complexity** measures how hard code is for humans to understand.

### Key Differences

| Aspect | Cyclomatic | Cognitive |
|--------|------------|-----------|
| Counts | Branches | Mental effort |
| Nesting | Not penalized | Penalized (+1 per level) |
| Break in flow | Not counted | Counted (early return, goto) |
| Recursion | Not counted | Counted |
| Threshold | 10-15 | 15-25 |

### Cognitive Complexity Rules

1. **+1** for each control structure (`if`, `for`, `while`, `switch`, `catch`)
2. **+1** for each break in linear flow (`else`, `elif`, early return)
3. **+1 per nesting level** when structures are nested
4. **+1** for recursion

### ESLint Integration

```json
{
  "rules": {
    "complexity": ["warn", { "max": 10 }],
    "sonarjs/cognitive-complexity": ["warn", 15]
  }
}
```

Install SonarJS for cognitive complexity:

```bash
pnpm add -D eslint-plugin-sonarjs
```

---

## Code Review Metrics

Integrate complexity into PR reviews:

### Optimal PR Size

| Lines Changed | Review Effectiveness |
|---------------|---------------------|
| < 200 | Optimal |
| 200-400 | Good |
| 400-800 | Reduced |
| > 800 | Poor (split recommended) |

### Review Time Budget

- **200 LOC**: 15-20 minutes
- **400 LOC**: 30-45 minutes  
- **800 LOC**: 60+ minutes (diminishing returns)

### CI Complexity Gate

```yaml
# .github/workflows/complexity.yml
jobs:
  complexity-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npx eslint --rule 'complexity: [error, 15]' src/
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

## Skill Resources

### Automated Discovery

Run the scanner script for quick assessment:

```bash
# Bash
./scripts/complexity-scan.sh src/

# PowerShell
.\scripts\complexity-scan.ps1 -TargetDir src/
```

### Reference Documentation

| Document | Purpose |
|----------|---------|
| `references/react-patterns.md` | React hook limits, component size, inline sub-components |
| `references/coupling-analysis.md` | Import analysis, circular deps, dependency direction |
| `references/refactoring-strategies.md` | Extract function/module/component patterns |

Load these references when deeper analysis is needed for a specific category.

---

## Related Skills

- `tl-knip` - Find unused exports (reduces false positives in export counts)
- `codebase-audit` - Broader code health assessment
- `ui-audit` - UI-specific complexity and drift detection
- `semgrep/skills/code-security` - Security vulnerability detection (complementary to structural complexity)

---

## References

### Quilted Sources

- [trailofbits/skills/code-maturity-assessor](https://skills.sh/trailofbits/skills/code-maturity-assessor) — Assessment framework
- [obra/superpowers/systematic-debugging](https://skills.sh/obra/superpowers/systematic-debugging) — Iron Law pattern
- [obra/superpowers/verification-before-completion](https://skills.sh/obra/superpowers/verification-before-completion) — Evidence principles
- [rmyndharis/antigravity-skills/code-refactoring-refactor-clean](https://skills.sh/rmyndharis/antigravity-skills/code-refactoring-refactor-clean) — SOLID assessment

### Official Skills

- [semgrep/skills/semgrep](https://skills.sh/semgrep/skills/semgrep) — Static analysis and custom rule creation
- [semgrep/skills/code-security](https://skills.sh/semgrep/skills/code-security) — Security vulnerability patterns
- [jwynia/agent-skills/code-review](https://skills.sh/jwynia/agent-skills/code-review) — Review metrics

### First-Party Documentation

- [ESLint Complexity Rule](https://eslint.org/docs/rules/complexity) — Cyclomatic complexity linting
- [SonarQube Cognitive Complexity](https://www.sonarsource.com/docs/cognitive-complexity/) — Cognitive complexity definition
- [Semgrep Rule Writing](https://semgrep.dev/docs/writing-rules/overview/) — Custom complexity rules
- [TypeScript Compiler API](https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API) — AST analysis

### Academic/Industry

- [Cognitive Complexity Paper](https://www.sonarsource.com/docs/CognitiveComplexity.pdf) — Original SonarSource definition
- [Code Complete 2](https://www.oreilly.com/library/view/code-complete-2nd/0735619670/) — McConnell complexity guidance
