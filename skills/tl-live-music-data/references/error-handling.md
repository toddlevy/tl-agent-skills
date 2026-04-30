# Error Handling Matrix

> Loaded on-demand by `tl-live-music-data` when handling API errors and retries. See `../SKILL.md` for the parent skill.

## Retry Strategies

| HTTP Code | Meaning | Strategy |
|-----------|---------|----------|
| 429 | Rate limited | Exponential backoff, respect `Retry-After` |
| 503 | Service unavailable | Retry 3x with backoff |
| 500 | Server error | Retry 1x, then fail |
| 400 | Bad request | Do not retry, log for debugging |
| 401 | Unauthorized | Refresh token, then retry 1x |
| 403 | Forbidden | Do not retry, check scopes |
| 404 | Not found | Do not retry, return null |

## Implementation

```typescript
async function fetchWithRetry(
  url: string,
  options: RequestInit,
  maxRetries = 3
): Promise<Response> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const response = await fetch(url, options);
    
    if (response.ok) return response;
    
    if (response.status === 429) {
      const retryAfter = parseInt(response.headers.get('Retry-After') || '60');
      await sleep(retryAfter * 1000);
      continue;
    }
    
    if (response.status >= 500 && attempt < maxRetries - 1) {
      await sleep(Math.pow(2, attempt) * 1000);
      continue;
    }
    
    throw new ApiError(response.status, await response.text());
  }
  
  throw new Error('Max retries exceeded');
}
```

## API-Specific Error Codes

**MusicBrainz:**
- `503` with `Rate limit exceeded` → Back off 1+ seconds

**JamBase:**
- `400` with `INVALID_ID_FORMAT` → Check ID prefix
- `404` with `ARTIST_NOT_FOUND` → Try name search instead

**Setlist.fm:**
- `404` for artists without setlists → Normal, not an error

**Spotify:**
- `401` with `token_expired` → Refresh token
- `403` with `insufficient_scope` → Re-authorize with more scopes
