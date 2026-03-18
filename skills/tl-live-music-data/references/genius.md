# Genius API Reference

**Role**: Song metadata and annotations - crowdsourced lyrics explanations

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://api.genius.com` |
| Auth | OAuth 2.0 (Bearer token) |
| Rate Limit | Undocumented |
| Format | JSON |
| Docs | https://docs.genius.com |
| Create App | https://genius.com/api-clients |

## Important Limitations

1. **Lyrics NOT available via API** - Only annotations/referents
2. **Commercial use requires license** - Contact api-sales@genius.com
3. **OAuth required** - No API key-only access

## Authentication

### Get Access Token

1. Create app at https://genius.com/api-clients
2. Use client credentials flow or redirect flow
3. Include token in Authorization header

```http
Authorization: Bearer your-access-token
```

### Token Types

| Type | Use Case |
|------|----------|
| Client Access Token | Read-only, no user context |
| User Access Token | Write operations, user-specific data |

## Endpoints

### Search

```http
GET /search?q={query}
```

**Response**:
```json
{
  "meta": {
    "status": 200
  },
  "response": {
    "hits": [
      {
        "highlights": [],
        "index": "song",
        "type": "song",
        "result": {
          "id": 378195,
          "title": "Tweezer",
          "full_title": "Tweezer by Phish",
          "url": "https://genius.com/Phish-tweezer-lyrics",
          "header_image_url": "https://...",
          "song_art_image_url": "https://...",
          "primary_artist": {
            "id": 13585,
            "name": "Phish",
            "url": "https://genius.com/artists/Phish",
            "image_url": "https://..."
          },
          "release_date_for_display": "March 1994",
          "stats": {
            "pageviews": 12345
          }
        }
      }
    ]
  }
}
```

### Get Song

```http
GET /songs/{id}
GET /songs/{id}?text_format=plain
GET /songs/{id}?text_format=html
GET /songs/{id}?text_format=dom
```

**Response**:
```json
{
  "meta": { "status": 200 },
  "response": {
    "song": {
      "id": 378195,
      "title": "Tweezer",
      "full_title": "Tweezer by Phish",
      "url": "https://genius.com/Phish-tweezer-lyrics",
      "path": "/Phish-tweezer-lyrics",
      "header_image_url": "https://...",
      "song_art_image_url": "https://...",
      "release_date": "1994-03-29",
      "release_date_for_display": "March 29, 1994",
      "apple_music_id": "...",
      "apple_music_player_url": "https://...",
      "primary_artist": {
        "id": 13585,
        "name": "Phish",
        "url": "https://genius.com/artists/Phish",
        "image_url": "https://..."
      },
      "featured_artists": [],
      "producer_artists": [],
      "writer_artists": [
        {"id": 13586, "name": "Trey Anastasio"}
      ],
      "album": {
        "id": 14367,
        "name": "Hoist",
        "url": "https://genius.com/albums/Phish/Hoist",
        "cover_art_url": "https://..."
      },
      "description": {
        "plain": "Description text...",
        "html": "<p>Description text...</p>",
        "dom": {"tag": "root", "children": [...]}
      },
      "media": [
        {"provider": "youtube", "url": "https://youtube.com/..."},
        {"provider": "spotify", "url": "https://open.spotify.com/..."}
      ],
      "stats": {
        "pageviews": 12345,
        "contributors": 23,
        "iq_earners": 5,
        "verified_annotations": 3,
        "unreviewed_annotations": 2,
        "accepted_annotations": 10
      }
    }
  }
}
```

### Get Artist

```http
GET /artists/{id}
```

**Response**:
```json
{
  "meta": { "status": 200 },
  "response": {
    "artist": {
      "id": 13585,
      "name": "Phish",
      "url": "https://genius.com/artists/Phish",
      "image_url": "https://...",
      "header_image_url": "https://...",
      "followers_count": 1234,
      "description": {...},
      "facebook_name": "phish",
      "twitter_name": "phish",
      "instagram_name": "phish"
    }
  }
}
```

### Artist's Songs

```http
GET /artists/{id}/songs
GET /artists/{id}/songs?sort=title
GET /artists/{id}/songs?sort=popularity
GET /artists/{id}/songs?per_page=20&page=1
```

**Sort Options**:
- `title` - Alphabetical
- `popularity` - By pageviews (default)

### Get Annotation

```http
GET /annotations/{id}
GET /annotations/{id}?text_format=plain
```

### Get Referents (Annotations for a Song)

```http
GET /referents?song_id={id}
GET /referents?web_page_id={id}
GET /referents?song_id={id}&text_format=plain
```

**Response**:
```json
{
  "meta": { "status": 200 },
  "response": {
    "referents": [
      {
        "id": 123456,
        "fragment": "Some lyric fragment",
        "range": {"start": 0, "end": 20},
        "annotations": [
          {
            "id": 789012,
            "body": {...},
            "state": "accepted",
            "verified": true,
            "votes_total": 25
          }
        ]
      }
    ]
  }
}
```

## Text Format Options

| Value | Description |
|-------|-------------|
| `plain` | Plain text |
| `html` | HTML markup |
| `dom` | DOM structure (nested objects) |

## OAuth Scopes

| Scope | Permission |
|-------|------------|
| `me` | Read user profile |
| `create_annotation` | Create annotations |
| `manage_annotation` | Edit/delete annotations |
| `vote` | Vote on annotations |

## TypeScript Implementation

```typescript
interface GeniusSong {
  id: number;
  title: string;
  full_title: string;
  url: string;
  song_art_image_url: string;
  release_date: string;
  primary_artist: {
    id: number;
    name: string;
    url: string;
  };
  album?: {
    id: number;
    name: string;
    cover_art_url: string;
  };
  media: Array<{
    provider: string;
    url: string;
  }>;
}

interface GeniusSearchResult {
  meta: { status: number };
  response: {
    hits: Array<{
      type: string;
      result: GeniusSong;
    }>;
  };
}

const ACCESS_TOKEN = process.env.GENIUS_ACCESS_TOKEN;

async function geniusApi<T>(endpoint: string, params: Record<string, string> = {}): Promise<T> {
  const url = new URL(`https://api.genius.com${endpoint}`);
  
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }
  
  const response = await fetch(url.toString(), {
    headers: {
      'Authorization': `Bearer ${ACCESS_TOKEN}`
    }
  });
  
  return response.json();
}

async function searchSongs(query: string): Promise<GeniusSong[]> {
  const data = await geniusApi<GeniusSearchResult>('/search', { q: query });
  return data.response.hits
    .filter(hit => hit.type === 'song')
    .map(hit => hit.result);
}

async function getSong(id: number): Promise<GeniusSong> {
  const data = await geniusApi<{ response: { song: GeniusSong } }>(`/songs/${id}`);
  return data.response.song;
}

async function getArtistSongs(artistId: number, page: number = 1): Promise<GeniusSong[]> {
  const data = await geniusApi<{ response: { songs: GeniusSong[] } }>(
    `/artists/${artistId}/songs`,
    { page: String(page), per_page: '50', sort: 'popularity' }
  );
  return data.response.songs;
}
```

## Lyrics Workaround

Lyrics are NOT in the API. Options:

1. **Web scraping** - Parse from song page HTML (may violate ToS)
2. **LyricFind API** - Licensed lyrics provider
3. **Musixmatch API** - Alternative lyrics API
4. **Link to Genius** - Redirect users to song URL

## ID Resolution

Genius uses its own IDs. Cross-reference via:

1. **Search by song title + artist name**
2. **Check `media` array for Spotify/YouTube IDs**
3. **No direct MBID support**

## Pagination

```json
{
  "response": {
    "songs": [...],
    "next_page": 2
  }
}
```

**Parameters**:
| Param | Type | Default | Max |
|-------|------|---------|-----|
| `page` | int | 1 | - |
| `per_page` | int | 20 | 50 |

## Error Responses

```json
{
  "meta": {
    "status": 404,
    "message": "Song not found"
  }
}
```

| Code | Meaning |
|------|---------|
| 401 | Invalid/expired token |
| 403 | Insufficient scope |
| 404 | Resource not found |
| 429 | Rate limited |

## Common Gotchas

1. **No lyrics via API** - Only annotations/metadata
2. **OAuth required** - Can't use API key alone
3. **Commercial license** - Contact sales for commercial use
4. **Search is song-focused** - Artist search via song results

## Caching Recommendations

| Data | TTL |
|------|-----|
| Song metadata | 7 days |
| Artist info | 7 days |
| Search results | 24 hours |
| Annotations | 24 hours |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| API Docs | https://docs.genius.com |
| Create App | https://genius.com/api-clients |
| Commercial License | api-sales@genius.com |
| Main Site | https://genius.com |

### Version Detection

Genius API doesn't use versioned URLs. Monitor:

1. **Docs page** - Check for deprecation notices
2. **OAuth scopes** - New scopes may indicate new features
3. **Response structure** - Watch for new fields

### Test Endpoint

Verify API is responding:

```http
GET https://api.genius.com/search?q=Tweezer%20Phish
Authorization: Bearer {your-token}
```

Expected: Returns `response.hits` array with song results.

### Important Limitations

- **No lyrics via API** - Only annotations/referents
- **Commercial use requires license** - Contact api-sales@genius.com
- **OAuth required** - Cannot use simple API key

### Last Verified

- **Date**: March 2026
- **Verified by**: API probing and documentation review
