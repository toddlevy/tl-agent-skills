# Sync Report Template

Use this template for generating documentation audit reports.

---

## Full Report Template

```markdown
# Documentation Sync Report

Generated: YYYY-MM-DD
Scope: [Full codebase / Changed files / Specific areas]
Auditor: AI Assistant (tl-docs-audit skill)

---

## Executive Summary

| Category | Count | Severity |
|----------|-------|----------|
| Missing | 0 | High |
| Outdated | 0 | Medium |
| Structural | 0 | Low |
| Orphaned | 0 | Low |
| Incomplete | 0 | Medium |
| **Total** | **0** | — |

### Overall Health

[Brief assessment: Good / Needs attention / Significant gaps]

---

## Feature Inventory

Total documentable features found: N

### By Category

| Category | Count | Documented | Coverage |
|----------|-------|------------|----------|
| Public API | 0 | 0 | 100% |
| Configuration | 0 | 0 | 100% |
| CLI Commands | 0 | 0 | 100% |
| API Endpoints | 0 | 0 | 100% |
| Components | 0 | 0 | 100% |

---

## Doc-First Findings

### Missing Content

| Page | Missing | Evidence | Priority |
|------|---------|----------|----------|
| `path/to/doc.md` | [Description] | `path/to/code.ts:line` | High/Medium/Low |

### Outdated Content

| Page | Issue | Correct Info | Evidence |
|------|-------|--------------|----------|
| `path/to/doc.md` | [What's wrong] | [What it should say] | `path/to/code.ts` |

### Structural Issues

| Page | Issue | Recommendation |
|------|-------|----------------|
| `path/to/doc.md` | [Problem] | [Suggested fix] |

### Orphaned Pages

| Page | Last Modified | Linked From |
|------|---------------|-------------|
| `path/to/doc.md` | YYYY-MM-DD | None found |

---

## Code-First Gaps

| Feature | Location | Evidence | Suggested Doc Location |
|---------|----------|----------|------------------------|
| `functionName` | `src/path.ts` | Exported, used in N places | `docs/reference/path.md` |

---

## Code-to-Docs Mapping

| Source Path | Doc Location | Status | Notes |
|-------------|--------------|--------|-------|
| `src/api/users.ts` | `docs/api/users.md` | OK | — |
| `src/config/index.ts` | `docs/reference/config.md` | Outdated | Port default wrong |
| `src/utils/email.ts` | — | Missing | No docs exist |

---

## Staleness Indicators

| Page | Last Updated | Days Stale | Issue |
|------|--------------|------------|-------|
| `path/to/doc.md` | YYYY-MM-DD | N | [Indicator] |

### Staleness Criteria Used

- [ ] Not updated in 90+ days
- [ ] References deprecated APIs
- [ ] Links to removed files
- [ ] Mentions outdated dependency versions

---

## Proposed Edits

### Priority: High

1. **[file path]** — [Change summary]
   - Evidence: [Link to code]
   - Effort: [Small/Medium/Large]

### Priority: Medium

1. **[file path]** — [Change summary]

### Priority: Low

1. **[file path]** — [Change summary]

---

## New Documents Needed

| Document | Purpose | Suggested Location | Content Source |
|----------|---------|-------------------|----------------|
| [Name] | [Why needed] | `docs/path.md` | `src/path.ts` |

---

## Recommendations

### Immediate Actions

1. [First priority fix]
2. [Second priority fix]

### Process Improvements

1. [Suggestion for preventing future gaps]
2. [Suggestion for maintenance workflow]

---

## Appendix: Files Scanned

### Documentation Files

- `README.md`
- `docs/...`

### Code Files

- `src/...`
- `config/...`
```

---

## Compact Report Template

For quick audits or changed-files-only scope:

```markdown
# Quick Doc Sync Report

Generated: YYYY-MM-DD
Scope: Changed files (last commit / PR / N days)

## Summary

- **Missing docs**: N features need documentation
- **Outdated docs**: N docs need updating
- **OK**: N docs are current

## Action Items

1. [ ] [First fix]
2. [ ] [Second fix]

## Details

### Missing

| Feature | Code | Suggested Doc |
|---------|------|---------------|
| ... | ... | ... |

### Outdated

| Doc | Issue | Fix |
|-----|-------|-----|
| ... | ... | ... |
```

---

## Staleness-Only Report Template

```markdown
# Documentation Staleness Report

Generated: YYYY-MM-DD

## Stale Documents

| Document | Last Updated | Staleness Reason |
|----------|--------------|------------------|
| ... | ... | ... |

## Broken Links

| Document | Broken Link | Suggestion |
|----------|-------------|------------|
| ... | ... | ... |

## Deprecated References

| Document | Deprecated API | Current API |
|----------|----------------|-------------|
| ... | ... | ... |
```
