# Last.fm API Reference

**Role**: Social music data - scrobbles, similar artists, tags, listening stats

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `http://ws.audioscrobbler.com/2.0/` |
| Auth | API key (query parameter) |
| Rate Limit | Soft limit (no hard cap) |
| Format | JSON or XML |
| Docs | https://www.last.fm/api |
| Unofficial Docs | https://lastfm-docs.github.io/api-docs/ |
| Get API Key | https://www.last.fm/api/account/create |

## Authentication

### Read Operations

API key as query param:
```
?api_key=your-api-key
```

### Write Operations

Requires method signature:
```
?api_key=your-key&api_sig={signature}&sk={session_key}
```

Signature = MD5 of sorted params + shared secret.

## Common Parameters

| Param | Type | Description |
|-------|------|-------------|
| `api_key` | string | Your API key (required) |
| `format` | string | `json` (default is XML) |
| `autocorrect` | int | `1` to fix misspellings |
| `lang` | string | ISO 639-2 language code |

## Artist Endpoints

### Get Artist Info

```http
GET /?method=artist.getInfo&artist={name}&api_key={key}&format=json
GET /?method=artist.getInfo&mbid={mbid}&api_key={key}&format=json
```

**Response**:
```json
{
  "artist": {
    "name": "Phish",
    "mbid": "e01646f2-2a04-450d-8bf2-0d993082e058",
    "url": "https://www.last.fm/music/Phish",
    "image": [
      {"#text": "https://...", "size": "small"},
      {"#text": "https://...", "size": "medium"},
      {"#text": "https://...", "size": "large"},
      {"#text": "https://...", "size": "extralarge"},
      {"#text": "https://...", "size": "mega"}
    ],
    "streamable": "0",
    "ontour": "1",
    "stats": {
      "listeners": "423456",
      "playcount": "12345678"
    },
    "similar": {
      "artist": [
        {"name": "Grateful Dead", "url": "..."},
        {"name": "Widespread Panic", "url": "..."}
      ]
    },
    "tags": {
      "tag": [
        {"name": "jam", "url": "..."},
        {"name": "psychedelic", "url": "..."}
      ]
    },
    "bio": {
      "links": {...},
      "published": "01 Jan 2006, 00:00",
      "summary": "Phish is an American...",
      "content": "Full biography text..."
    }
  }
}
```

**Note**: Biography `summary` is truncated at 300 characters. Use `content` for full bio.

### Get Similar Artists

```http
GET /?method=artist.getSimilar&artist={name}&api_key={key}&format=json
GET /?method=artist.getSimilar&artist={name}&limit={n}&api_key={key}&format=json
```

### Get Top Albums

```http
GET /?method=artist.getTopAlbums&artist={name}&api_key={key}&format=json
GET /?method=artist.getTopAlbums&artist={name}&page={n}&limit={n}&api_key={key}&format=json
```

### Get Top Tracks

```http
GET /?method=artist.getTopTracks&artist={name}&api_key={key}&format=json
```

### Search Artists

```http
GET /?method=artist.search&artist={name}&api_key={key}&format=json
GET /?method=artist.search&artist={name}&page={n}&limit={n}&api_key={key}&format=json
```

## Album Endpoints

### Get Album Info

```http
GET /?method=album.getInfo&artist={artist}&album={album}&api_key={key}&format=json
GET /?method=album.getInfo&mbid={mbid}&api_key={key}&format=json
```

### Search Albums

```http
GET /?method=album.search&album={name}&api_key={key}&format=json
```

## Track Endpoints

### Get Track Info

```http
GET /?method=track.getInfo&artist={artist}&track={track}&api_key={key}&format=json
```

### Get Similar Tracks

```http
GET /?method=track.getSimilar&artist={artist}&track={track}&api_key={key}&format=json
```

### Search Tracks

```http
GET /?method=track.search&track={name}&api_key={key}&format=json
```

## Tag Endpoints

### Get Top Artists by Tag

```http
GET /?method=tag.getTopArtists&tag={tag}&api_key={key}&format=json
```

### Get Top Tracks by Tag

```http
GET /?method=tag.getTopTracks&tag={tag}&api_key={key}&format=json
```

### Get Top Tags

```http
GET /?method=tag.getTopTags&api_key={key}&format=json
```

## User Endpoints (Requires User Auth)

### Get User Info

```http
GET /?method=user.getInfo&user={username}&api_key={key}&format=json
```

### Get User's Recent Tracks

```http
GET /?method=user.getRecentTracks&user={username}&api_key={key}&format=json
```

### Get User's Top Artists

```http
GET /?method=user.getTopArtists&user={username}&period={period}&api_key={key}&format=json
```

**Period values**: `overall`, `7day`, `1month`, `3month`, `6month`, `12month`

## Pagination

```json
{
  "@attr": {
    "page": "1",
    "perPage": "50",
    "totalPages": "10",
    "total": "500"
  }
}
```

**Parameters**:
| Param | Type | Default |
|-------|------|---------|
| `page` | int | 1 |
| `limit` | int | 50 |

## TypeScript Implementation

```typescript
interface LastfmArtist {
  name: string;
  mbid: string;
  url: string;
  image: Array<{ '#text': string; size: string }>;
  stats: {
    listeners: string;
    playcount: string;
  };
  similar: {
    artist: Array<{ name: string; url: string }>;
  };
  tags: {
    tag: Array<{ name: string; url: string }>;
  };
  bio: {
    summary: string;
    content: string;
  };
}

const API_KEY = process.env.LASTFM_API_KEY;
const BASE_URL = 'http://ws.audioscrobbler.com/2.0/';

async function lastfmApi<T>(method: string, params: Record<string, string> = {}): Promise<T> {
  const url = new URL(BASE_URL);
  url.searchParams.set('method', method);
  url.searchParams.set('api_key', API_KEY);
  url.searchParams.set('format', 'json');
  
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }
  
  const response = await fetch(url.toString());
  return response.json();
}

async function getArtistInfo(artist: string): Promise<LastfmArtist> {
  const data = await lastfmApi<{ artist: LastfmArtist }>('artist.getInfo', {
    artist,
    autocorrect: '1'
  });
  return data.artist;
}

async function getArtistInfoByMbid(mbid: string): Promise<LastfmArtist> {
  const data = await lastfmApi<{ artist: LastfmArtist }>('artist.getInfo', { mbid });
  return data.artist;
}

async function getSimilarArtists(artist: string, limit: number = 10) {
  const data = await lastfmApi<{ similarartists: { artist: Array<{ name: string; match: string }> } }>(
    'artist.getSimilar',
    { artist, limit: String(limit) }
  );
  return data.similarartists.artist;
}
```

## Image Sizes

| Size | Typical Dimensions |
|------|-------------------|
| `small` | 34x34 |
| `medium` | 64x64 |
| `large` | 174x174 |
| `extralarge` | 300x300 |
| `mega` | 600x600 |

**Note**: Image URLs may be empty strings if no image available.

## Autocorrect

Use `autocorrect=1` to fix common misspellings:
- "Metalica" → "Metallica"
- "Led Zepplin" → "Led Zeppelin"

## Error Responses

```json
{
  "error": 6,
  "message": "Artist not found",
  "links": []
}
```

| Code | Meaning |
|------|---------|
| 2 | Invalid service |
| 3 | Invalid method |
| 4 | Authentication failed |
| 6 | Not found |
| 8 | Operation failed |
| 10 | Invalid API key |
| 11 | Service offline |
| 13 | Invalid signature |
| 26 | Suspended API key |
| 29 | Rate limit exceeded |

## MBID Support

Last.fm accepts MusicBrainz IDs directly:

```http
?method=artist.getInfo&mbid=e01646f2-2a04-450d-8bf2-0d993082e058
```

Works for: `artist.getInfo`, `album.getInfo`, `track.getInfo`

## Common Gotchas

1. **XML default** - Always add `&format=json`
2. **Biography truncation** - `summary` is 300 chars, use `content` for full
3. **Empty images** - Check for empty strings in image array
4. **String numbers** - Stats come as strings, not numbers

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist info | 7 days |
| Similar artists | 7 days |
| Top tracks/albums | 24 hours |
| Tags | 7 days |
| User data | 1 hour |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| Official API Docs | https://www.last.fm/api |
| Unofficial Docs (better) | https://lastfm-docs.github.io/api-docs/ |
| API Account | https://www.last.fm/api/account/create |
| Status | https://twitter.com/lastfmstatus |

### Version Detection

Last.fm API doesn't use versioned URLs. Monitor:

1. **Official docs** - Check for deprecation notices
2. **Unofficial docs** - Community-maintained, often more current
3. **Response errors** - Watch for method deprecation warnings

### Test Endpoint

Verify API is responding:

```http
GET http://ws.audioscrobbler.com/2.0/?method=artist.getInfo&artist=Phish&api_key={your-key}&format=json
```

Expected: Returns artist object with `name`, `mbid`, `stats`, `bio` fields.

### Known Issues

- Biography `summary` truncated at 300 chars (use `content` for full)
- Images may be empty strings
- Stats are strings, not numbers

### Last Verified

- **Date**: March 2026
- **Verified by**: API probing and documentation review
