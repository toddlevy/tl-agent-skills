# MusicBrainz API Reference

**Role**: Central ID hub - source of truth for artist MBIDs and external ID mappings

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://musicbrainz.org/ws/2` |
| Auth | User-Agent header (required) |
| Rate Limit | 1 request/second per IP |
| Format | JSON (`fmt=json`) or XML (default) |
| Docs | https://musicbrainz.org/doc/MusicBrainz_API |

## Authentication

**User-Agent is mandatory**. Requests without proper User-Agent get 503 errors.

```
User-Agent: AppName/Version (contact@email.com)
```

Example:
```
User-Agent: NugsTracker/1.0 (dev@example.com)
```

## Endpoints

### Search

```http
GET /artist?query={name}&fmt=json
GET /release?query=artist:{name}&fmt=json
GET /recording?query={name}&fmt=json
```

**Search Syntax** (Lucene):
- `artist:name` - field-specific
- `"exact phrase"` - quoted phrase
- `name AND country:US` - boolean
- `name*` - wildcard

**Response Fields**:
```json
{
  "artists": [{
    "id": "mbid-uuid",
    "name": "Artist Name",
    "sort-name": "Name, Artist",
    "disambiguation": "US rock band",
    "type": "Group",
    "country": "US",
    "score": 100
  }]
}
```

### Lookup by MBID

```http
GET /artist/{mbid}?fmt=json
GET /artist/{mbid}?inc=url-rels&fmt=json
GET /artist/{mbid}?inc=releases&fmt=json
GET /artist/{mbid}?inc=url-rels+releases&fmt=json
```

### External ID Resolution (url-rels)

**This is the key feature** - get external IDs for other services:

```http
GET /artist/{mbid}?inc=url-rels&fmt=json
```

**Response includes URLs for**:
- Spotify (`https://open.spotify.com/artist/...`)
- Discogs (`https://www.discogs.com/artist/...`)
- Wikidata (`https://www.wikidata.org/wiki/Q...`)
- AllMusic (`https://www.allmusic.com/artist/...`)
- Last.fm (`https://www.last.fm/music/...`)
- IMDb (`https://www.imdb.com/name/nm...`)
- Bandcamp, SoundCloud, YouTube, etc.

**Parsing External IDs**:
```typescript
function extractExternalIds(relations: MBRelation[]): Record<string, string> {
  const ids: Record<string, string> = {};
  
  for (const rel of relations) {
    if (rel.type !== 'url') continue;
    const url = rel.url.resource;
    
    if (url.includes('spotify.com/artist/')) {
      ids.spotify = url.split('/artist/')[1].split('?')[0];
    } else if (url.includes('discogs.com/artist/')) {
      ids.discogs = url.split('/artist/')[1].split('-')[0];
    } else if (url.includes('wikidata.org/wiki/Q')) {
      ids.wikidata = url.match(/Q\d+/)?.[0];
    }
    // ... etc
  }
  
  return ids;
}
```

### INC Options

Combine with `+` for multiple:

| Option | Description |
|--------|-------------|
| `url-rels` | External URLs (Spotify, Discogs, etc.) |
| `artist-rels` | Related artists |
| `releases` | All releases |
| `release-groups` | Albums/EPs grouped |
| `recordings` | Track info |
| `labels` | Label relationships |
| `tags` | User tags |
| `ratings` | User ratings |

### Entity Types

| Entity | Description | Example MBID |
|--------|-------------|--------------|
| `artist` | Performer | `e01646f2-2a04-450d-8bf2-0d993082e058` |
| `release` | Specific version | `b84ee12a-09ef-421b-82de-0441a926375b` |
| `release-group` | Album concept | `1b022e01-4da6-387b-8658-8678046e4cef` |
| `recording` | Track | `b23e7e4c-1c4b-4d9f-9b8e-3e7d8e7e8e7e` |
| `work` | Song composition | `c1e7e7e7-e7e7-e7e7-e7e7-e7e7e7e7e7e7` |
| `label` | Record label | `d1e7e7e7-e7e7-e7e7-e7e7-e7e7e7e7e7e7` |

## Rate Limiting

**Hard limit**: 1 request per second per IP

**Implementation**:
```typescript
const MB_DELAY = 1000; // 1 second between requests
let lastRequest = 0;

async function mbFetch(path: string): Promise<Response> {
  const now = Date.now();
  const wait = Math.max(0, MB_DELAY - (now - lastRequest));
  if (wait > 0) await sleep(wait);
  
  lastRequest = Date.now();
  
  return fetch(`https://musicbrainz.org/ws/2${path}`, {
    headers: {
      'User-Agent': 'AppName/1.0 (contact@email.com)',
      'Accept': 'application/json'
    }
  });
}
```

## Common Errors

| Code | Cause | Fix |
|------|-------|-----|
| 400 | Invalid query syntax | Check Lucene syntax |
| 404 | MBID not found | Verify MBID format (UUID) |
| 503 | Missing/bad User-Agent | Add proper User-Agent header |
| 503 | Rate limit exceeded | Slow down to 1 req/sec |

## Example: Artist Lookup with External IDs

```typescript
const mbid = 'e01646f2-2a04-450d-8bf2-0d993082e058';
const response = await fetch(
  `https://musicbrainz.org/ws/2/artist/${mbid}?inc=url-rels&fmt=json`,
  {
    headers: {
      'User-Agent': 'MyApp/1.0 (me@example.com)',
      'Accept': 'application/json'
    }
  }
);

const data = await response.json();
// data.relations contains external URLs
```

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist metadata | 7 days |
| External IDs (url-rels) | 30 days |
| Search results | 24 hours |
| Releases | 7 days |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| API Docs | https://musicbrainz.org/doc/MusicBrainz_API |
| Development Wiki | https://wiki.musicbrainz.org/Development |
| Schema Changes | https://musicbrainz.org/doc/MusicBrainz_Database/Schema |
| Blog (announcements) | https://blog.metabrainz.org/ |
| Status Page | https://status.metabrainz.org/ |

### Version Detection

MusicBrainz doesn't version the API traditionally. Monitor:

1. **Schema version** - Check database schema docs for entity changes
2. **Blog posts** - Major changes announced on MetaBrainz blog
3. **Wiki changelog** - https://wiki.musicbrainz.org/History:MusicBrainz_API

### Test Endpoint

Verify API is responding correctly:

```http
GET https://musicbrainz.org/ws/2/artist/e01646f2-2a04-450d-8bf2-0d993082e058?fmt=json
```

Expected: Returns Phish artist data with `id`, `name`, `type` fields.

### Last Verified

- **Date**: March 2026
- **Verified by**: API probing and documentation review
