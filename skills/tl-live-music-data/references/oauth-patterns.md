# OAuth 2.0 Patterns

> Loaded on-demand by `tl-live-music-data` when integrating an OAuth-protected API. See `../SKILL.md` for the parent skill.

## Spotify Authorization Code + PKCE

Required for Spotify Web API production use.

```typescript
import { createHash, randomBytes } from 'crypto';

function generateCodeVerifier(): string {
  return randomBytes(64).toString('base64url');
}

function generateCodeChallenge(verifier: string): string {
  return createHash('sha256').update(verifier).digest('base64url');
}

const codeVerifier = generateCodeVerifier();
const codeChallenge = generateCodeChallenge(codeVerifier);

const authUrl = new URL('https://accounts.spotify.com/authorize');
authUrl.searchParams.set('client_id', CLIENT_ID);
authUrl.searchParams.set('response_type', 'code');
authUrl.searchParams.set('redirect_uri', REDIRECT_URI);
authUrl.searchParams.set('code_challenge_method', 'S256');
authUrl.searchParams.set('code_challenge', codeChallenge);
authUrl.searchParams.set('scope', 'user-read-private user-top-read');
```

## Token Refresh Pattern

```typescript
interface TokenStorage {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
}

async function getAccessToken(storage: TokenStorage): Promise<string> {
  if (Date.now() < storage.expiresAt - 60000) {
    return storage.accessToken;
  }

  const response = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: storage.refreshToken,
      client_id: CLIENT_ID,
    }),
  });

  const data = await response.json();
  storage.accessToken = data.access_token;
  storage.expiresAt = Date.now() + data.expires_in * 1000;
  if (data.refresh_token) storage.refreshToken = data.refresh_token;
  
  return storage.accessToken;
}
```

## Recommended Scopes

| Provider | Common Scopes |
|----------|--------------|
| Spotify | `user-read-private`, `user-top-read`, `playlist-read-private` |
| Discogs | Read-only by default, no scopes needed |
| Genius | Varies — most endpoints don't require user auth |
