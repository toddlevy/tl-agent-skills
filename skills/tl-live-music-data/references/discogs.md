# Discogs API Reference

**Role**: Discography data - releases, labels, formats, marketplace

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://api.discogs.com` |
| Auth | User-Agent required, token optional |
| Rate Limit | 60/min auth, 25/min unauth |
| Format | JSON |
| Docs | https://www.discogs.com/developers |

## Authentication

### Required: User-Agent

```
User-Agent: AppName/Version +https://yoursite.com
```

### Optional: Personal Access Token

```
Authorization: Discogs token=your-token-here
```

Or query param:
```
?token=your-token-here
```

### Optional: OAuth 1.0a

For user-specific actions (collection, wantlist).

## Rate Limiting

**Monitor these headers**:
```
X-Discogs-Ratelimit: 60
X-Discogs-Ratelimit-Used: 23
X-Discogs-Ratelimit-Remaining: 37
```

**Implementation**:
```typescript
async function discogsFetch(path: string): Promise<Response> {
  const response = await fetch(`https://api.discogs.com${path}`, {
    headers: {
      'User-Agent': 'MyApp/1.0 +https://myapp.com',
      'Authorization': `Discogs token=${process.env.DISCOGS_TOKEN}`
    }
  });
  
  const remaining = parseInt(response.headers.get('X-Discogs-Ratelimit-Remaining') || '60');
  if (remaining < 5) {
    await sleep(1000);
  }
  
  return response;
}
```

## Endpoints

### Database Search

```http
GET /database/search?q={query}
GET /database/search?q={query}&type=artist
GET /database/search?q={query}&type=release
GET /database/search?q={query}&type=master
GET /database/search?q={query}&type=label
```

**Search Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `q` | string | Search query |
| `type` | string | `artist`, `release`, `master`, `label` |
| `title` | string | Title search |
| `release_title` | string | Release title |
| `credit` | string | Artist credit |
| `artist` | string | Artist name |
| `anv` | string | Artist name variation |
| `label` | string | Label name |
| `genre` | string | Genre |
| `style` | string | Style |
| `country` | string | Country |
| `year` | string | Year or range (1990-2000) |
| `format` | string | Format (CD, Vinyl, etc.) |
| `catno` | string | Catalog number |
| `barcode` | string | Barcode |

### Artists

```http
GET /artists/{id}
GET /artists/{id}/releases
GET /artists/{id}/releases?sort=year&sort_order=desc
```

**Artist Response**:
```json
{
  "id": 45,
  "name": "Aphex Twin",
  "realname": "Richard David James",
  "profile": "Electronic musician...",
  "data_quality": "Needs Vote",
  "namevariations": ["AFX", "Richard D. James"],
  "aliases": [{"id": 12345, "name": "AFX"}],
  "members": [],
  "urls": [
    "https://aphextwin.warp.net/",
    "https://en.wikipedia.org/wiki/Aphex_Twin"
  ],
  "images": [
    {
      "type": "primary",
      "uri": "https://...",
      "width": 600,
      "height": 600
    }
  ]
}
```

**Artist Releases Params**:
| Param | Type | Description |
|-------|------|-------------|
| `sort` | string | `year`, `title`, `format` |
| `sort_order` | string | `asc`, `desc` |
| `page` | int | Page number |
| `per_page` | int | Items per page (max 100) |

### Releases

```http
GET /releases/{id}
GET /releases/{id}?curr_abbr=USD
```

**Release Response**:
```json
{
  "id": 249504,
  "title": "Selected Ambient Works 85-92",
  "artists": [{"id": 45, "name": "Aphex Twin"}],
  "labels": [{"id": 1234, "name": "Apollo", "catno": "AMB 3922"}],
  "formats": [
    {
      "name": "Vinyl",
      "qty": "2",
      "descriptions": ["LP", "Album", "Reissue"]
    }
  ],
  "genres": ["Electronic"],
  "styles": ["Ambient", "IDM"],
  "year": 1992,
  "country": "UK",
  "tracklist": [
    {
      "position": "A1",
      "title": "Xtal",
      "duration": "4:54"
    }
  ],
  "images": [...],
  "videos": [...],
  "community": {
    "have": 12345,
    "want": 6789,
    "rating": {
      "count": 1234,
      "average": 4.5
    }
  },
  "lowest_price": 25.00
}
```

### Master Releases

```http
GET /masters/{id}
GET /masters/{id}/versions
GET /masters/{id}/versions?format=Vinyl&country=US
```

**Master** = Canonical album, **Versions** = Specific pressings

### Labels

```http
GET /labels/{id}
GET /labels/{id}/releases
```

## Pagination

All list endpoints support:
```
?page=1&per_page=50
```

**Response includes**:
```json
{
  "pagination": {
    "page": 1,
    "pages": 10,
    "per_page": 50,
    "items": 500,
    "urls": {
      "next": "https://api.discogs.com/...",
      "last": "https://api.discogs.com/..."
    }
  }
}
```

## Image Access

**Images require authentication**. Unauthenticated requests return 401.

Image response includes multiple sizes:
```json
{
  "images": [
    {
      "type": "primary",
      "uri": "https://i.discogs.com/...",
      "uri150": "https://i.discogs.com/.../150",
      "width": 600,
      "height": 600
    }
  ]
}
```

## ID Resolution from MusicBrainz

Use MusicBrainz url-rels to get Discogs ID:

```typescript
// From MusicBrainz url-rels
const discogsUrl = "https://www.discogs.com/artist/45-Aphex-Twin";
const discogsId = discogsUrl.match(/\/artist\/(\d+)/)?.[1]; // "45"
```

## Common Use Cases

### Get Artist Discography

```typescript
const artistId = 45;

const response = await fetch(
  `https://api.discogs.com/artists/${artistId}/releases?` +
  `sort=year&sort_order=desc&per_page=100`,
  {
    headers: {
      'User-Agent': 'MyApp/1.0 +https://myapp.com',
      'Authorization': `Discogs token=${process.env.DISCOGS_TOKEN}`
    }
  }
);

const data = await response.json();
// data.releases[] contains discography
```

### Search for Artist

```typescript
const response = await fetch(
  `https://api.discogs.com/database/search?` +
  `type=artist&q=${encodeURIComponent('Aphex Twin')}`,
  {
    headers: {
      'User-Agent': 'MyApp/1.0 +https://myapp.com'
    }
  }
);
```

## Formats Reference

Common format values:
- `Vinyl` - LP, 12", 7", 10"
- `CD` - CD, CDr, CD-ROM
- `Cassette` - Cass
- `Digital` - File, MP3, FLAC
- `DVD` - DVD, DVD-Audio

## Common Errors

| Code | Cause | Fix |
|------|-------|-----|
| 401 | Missing/bad auth | Add User-Agent, check token |
| 404 | Resource not found | Verify ID |
| 429 | Rate limited | Check X-Discogs-Ratelimit headers |

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist info | 7 days |
| Release info | 30 days |
| Master info | 30 days |
| Search results | 24 hours |
| Images | 90 days |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| API Docs | https://www.discogs.com/developers |
| Developer Forum | https://www.discogs.com/forum/topics/15 |
| API Changelog | https://www.discogs.com/developers/changelog |
| Status Page | https://status.discogs.com/ |
| OAuth Guide | https://www.discogs.com/developers/#page:authentication |

### Version Detection

Discogs API doesn't use explicit versioning. Monitor:

1. **Changelog page** - https://www.discogs.com/developers/changelog
2. **Forum announcements** - Developer forum for breaking changes
3. **Response headers** - Check for deprecation warnings

### Test Endpoint

Verify API is responding:

```http
GET https://api.discogs.com/artists/45
Headers: User-Agent: TestApp/1.0
```

Expected: Returns Aphex Twin artist object with `id`, `name`, `profile` fields.

### Rate Limit Headers

Monitor these in every response:

```
X-Discogs-Ratelimit: 60
X-Discogs-Ratelimit-Used: 1
X-Discogs-Ratelimit-Remaining: 59
```

### Last Verified

- **Date**: March 2026
- **Verified by**: API probing and changelog review
