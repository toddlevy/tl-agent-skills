# Output Format Template

> Loaded on-demand by `tl-agent-plan-audit` when producing the audit report. See `../SKILL.md` for the parent skill.

Produce a unified audit report. Group findings by **subject matter** (e.g., by phase, by system component, by risk area) — NOT by audit type.

```markdown
# Plan Audit: [Plan Name]

## Summary

[2-3 sentences: Overall assessment, biggest risk, key recommendation]

**Verdict**: [Ready to execute | Changes recommended | Rework needed]

---

## Findings

### [Subject Area 1: e.g., "Phase 1: Database Setup"]

**Issues**:
- [Finding with analysis]
- [Finding with analysis]

**Recommendations**:
- [Specific fix]

---

### [Subject Area 2: e.g., "Cross-Phase Dependencies"]

**Issues**:
- [Finding with analysis]

**Recommendations**:
- [Specific fix]

---

### [Subject Area N: e.g., "Execution Strategy"]

**Parallelization opportunities**:
- Tasks X and Y can run in parallel (no dependencies)
- Phase 2 exploration work: spawn 2 agents

**Critical path**:
- Task A → Task B → Task C (blocking, ~60% of timeline)

**Agent allocation**:
```
Agent 1: Tasks 1.1, 1.3, 2.1 (critical path)
Agent 2: Tasks 1.2, 2.2, 2.3 (parallel work)
```

---

## Recommendations

Actionable list for plan revision:

1. **[Action]** — [Brief rationale]
2. **[Action]** — [Brief rationale]
3. **[Action]** — [Brief rationale]
...
```
