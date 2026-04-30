# Example Real Output

> Loaded on-demand by `tl-complexity-assessment` to show what an assessment report looks like in practice. See `../SKILL.md` for the parent skill.

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
