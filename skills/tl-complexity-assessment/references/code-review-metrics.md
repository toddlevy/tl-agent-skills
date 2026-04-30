# Code Review Metrics

> Loaded on-demand by `tl-complexity-assessment` when integrating complexity gates into code review. See `../SKILL.md` for the parent skill.

Integrate complexity into PR reviews:

## Optimal PR Size

| Lines Changed | Review Effectiveness |
|---------------|---------------------|
| < 200 | Optimal |
| 200-400 | Good |
| 400-800 | Reduced |
| > 800 | Poor (split recommended) |

## Review Time Budget

- **200 LOC**: 15-20 minutes
- **400 LOC**: 30-45 minutes  
- **800 LOC**: 60+ minutes (diminishing returns)

## CI Complexity Gate

```yaml
# .github/workflows/complexity.yml
jobs:
  complexity-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npx eslint --rule 'complexity: [error, 15]' src/
```
