# Cognitive vs Cyclomatic Complexity

> Loaded on-demand by `tl-complexity-assessment` when discussing complexity metrics with the user. See `../SKILL.md` for the parent skill.

**Cyclomatic complexity** counts decision points (branches). **Cognitive complexity** measures how hard code is for humans to understand.

## Key Differences

| Aspect | Cyclomatic | Cognitive |
|--------|------------|-----------|
| Counts | Branches | Mental effort |
| Nesting | Not penalized | Penalized (+1 per level) |
| Break in flow | Not counted | Counted (early return, goto) |
| Recursion | Not counted | Counted |
| Threshold | 10-15 | 15-25 |

## Cognitive Complexity Rules

1. **+1** for each control structure (`if`, `for`, `while`, `switch`, `catch`)
2. **+1** for each break in linear flow (`else`, `elif`, early return)
3. **+1 per nesting level** when structures are nested
4. **+1** for recursion

## ESLint Integration

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
