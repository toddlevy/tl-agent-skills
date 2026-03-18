# Songkick API Reference

**Role**: Gigography and event tracking - past events, upcoming shows, metro tracking

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://api.songkick.com/api/3.0` |
| Auth | API key (query parameter) |
| Rate Limit | Undocumented |
| Format | JSON |
| Docs | https://www.songkick.com/developer |

## WARNING: API Keys Suspended

**As of 2024, Songkick has suspended new API key applications.**

To obtain API access:
- Contact Songkick partnerships team
- Business use cases only
- Existing keys may still work

If you have an existing key, this documentation applies.

## Authentication

```
?apikey=your-api-key
```

## Artists

### Get Artist

```http
GET /artists/{id}.json?apikey={key}
```

### Artist Gigography (Past Events)

```http
GET /artists/{id}/gigography.json?apikey={key}
GET /artists/{id}/gigography.json?apikey={key}&page={n}&per_page={n}
```

### Artist Calendar (Upcoming Events)

```http
GET /artists/{id}/calendar.json?apikey={key}
```

### Similar Artists

```http
GET /artists/{id}/similar_artists.json?apikey={key}
```

### Search Artists

```http
GET /search/artists.json?apikey={key}&query={name}
```

### Artist Response

```json
{
  "resultsPage": {
    "status": "ok",
    "results": {
      "artist": [{
        "id": 468146,
        "displayName": "Phish",
        "uri": "https://www.songkick.com/artists/468146-phish",
        "onTourUntil": "2024-12-31"
      }]
    },
    "perPage": 50,
    "page": 1,
    "totalEntries": 1
  }
}
```

## Events

### Get Event

```http
GET /events/{id}.json?apikey={key}
```

### Search Events

```http
GET /events.json?apikey={key}&artist_name={name}
GET /events.json?apikey={key}&location=geo:{lat},{lng}
GET /events.json?apikey={key}&location=sk:{metro_area_id}
GET /events.json?apikey={key}&location=clientip
```

### Event Response

```json
{
  "resultsPage": {
    "status": "ok",
    "results": {
      "event": [{
        "id": 12345678,
        "type": "Concert",
        "uri": "https://www.songkick.com/concerts/12345678",
        "displayName": "Phish at Madison Square Garden (December 31, 2024)",
        "start": {
          "date": "2024-12-31",
          "time": "20:00:00",
          "datetime": "2024-12-31T20:00:00-0500"
        },
        "status": "ok",
        "popularity": 0.95,
        "performance": [{
          "id": 123456,
          "displayName": "Phish",
          "billing": "headline",
          "billingIndex": 1,
          "artist": {
            "id": 468146,
            "displayName": "Phish",
            "uri": "https://www.songkick.com/artists/468146-phish"
          }
        }],
        "venue": {
          "id": 17835,
          "displayName": "Madison Square Garden",
          "uri": "https://www.songkick.com/venues/17835-madison-square-garden",
          "metroArea": {
            "id": 7644,
            "displayName": "New York",
            "uri": "https://www.songkick.com/metro-areas/7644-us-new-york"
          },
          "lat": 40.7505,
          "lng": -73.9934
        },
        "location": {
          "city": "New York, NY, US",
          "lat": 40.7505,
          "lng": -73.9934
        }
      }]
    }
  }
}
```

## Venues

### Get Venue

```http
GET /venues/{id}.json?apikey={key}
```

### Venue Calendar

```http
GET /venues/{id}/calendar.json?apikey={key}
```

### Search Venues

```http
GET /search/venues.json?apikey={key}&query={name}
```

## Users

### User Calendar (Tracked Events)

```http
GET /users/{username}/calendar.json?apikey={key}
```

### User Past Events

```http
GET /users/{username}/past.json?apikey={key}
```

### User Tracked Artists

```http
GET /users/{username}/artists/tracked.json?apikey={key}
```

## Metro Areas

### Metro Calendar

```http
GET /metro_areas/{id}/calendar.json?apikey={key}
```

### Search Metro Areas

```http
GET /search/locations.json?apikey={key}&query={city}
```

## Pagination

All list endpoints return a `resultsPage` wrapper:

```json
{
  "resultsPage": {
    "status": "ok",
    "results": { ... },
    "perPage": 50,
    "page": 1,
    "totalEntries": 1247
  }
}
```

**Parameters**:
| Param | Type | Default | Max |
|-------|------|---------|-----|
| `page` | int | 1 | - |
| `per_page` | int | 50 | 50 |

## Location Filters

### By Geo Coordinates

```
location=geo:{lat},{lng}
```

### By Metro Area ID

```
location=sk:{metro_area_id}
```

### By Client IP

```
location=clientip
```

## Attribution Requirement

**Required**: Display "Concerts by Songkick" attribution when showing data.

```html
<a href="https://www.songkick.com">
  Concerts by Songkick
</a>
```

## TypeScript Implementation

```typescript
interface SongkickArtist {
  id: number;
  displayName: string;
  uri: string;
  onTourUntil: string | null;
}

interface SongkickEvent {
  id: number;
  type: string;
  displayName: string;
  uri: string;
  start: {
    date: string;
    time: string;
    datetime: string;
  };
  status: string;
  performance: Array<{
    displayName: string;
    billing: string;
    artist: SongkickArtist;
  }>;
  venue: {
    id: number;
    displayName: string;
    lat: number;
    lng: number;
  };
}

interface SongkickResponse<T> {
  resultsPage: {
    status: string;
    results: T;
    perPage: number;
    page: number;
    totalEntries: number;
  };
}

const API_KEY = process.env.SONGKICK_API_KEY;

async function searchArtists(query: string): Promise<SongkickArtist[]> {
  const response = await fetch(
    `https://api.songkick.com/api/3.0/search/artists.json?` +
    `apikey=${API_KEY}&query=${encodeURIComponent(query)}`
  );
  
  const data: SongkickResponse<{ artist: SongkickArtist[] }> = await response.json();
  return data.resultsPage.results.artist || [];
}

async function getArtistGigography(
  artistId: number,
  page: number = 1
): Promise<SongkickEvent[]> {
  const response = await fetch(
    `https://api.songkick.com/api/3.0/artists/${artistId}/gigography.json?` +
    `apikey=${API_KEY}&page=${page}`
  );
  
  const data: SongkickResponse<{ event: SongkickEvent[] }> = await response.json();
  return data.resultsPage.results.event || [];
}

async function getArtistCalendar(artistId: number): Promise<SongkickEvent[]> {
  const response = await fetch(
    `https://api.songkick.com/api/3.0/artists/${artistId}/calendar.json?` +
    `apikey=${API_KEY}`
  );
  
  const data: SongkickResponse<{ event: SongkickEvent[] }> = await response.json();
  return data.resultsPage.results.event || [];
}
```

## ID Resolution

Songkick IDs are in Wikidata (P4208):

```sparql
SELECT ?item ?itemLabel ?mbid WHERE {
  ?item wdt:P4208 "468146" .
  OPTIONAL { ?item wdt:P434 ?mbid }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
```

## Common Gotchas

1. **Keys suspended** - New applications not accepted
2. **Attribution required** - Must display "Concerts by Songkick"
3. **Gigography vs calendar** - Past events vs future events
4. **Metro areas** - Use for geo-based searches

## Event Types

| Type | Description |
|------|-------------|
| `Concert` | Standard concert |
| `Festival` | Multi-artist festival |

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist info | 7 days |
| Gigography | 30 days |
| Calendar | 1-4 hours |
| Venue info | 30 days |
| Metro areas | 90 days |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| Developer Portal | https://www.songkick.com/developer |
| API Status | Check developer portal |
| Partnership Contact | partnerships@songkick.com |

### Version Detection

URL contains version (`/api/3.0`). If available:

1. **Developer portal** - Check for announcements
2. **Response structure** - Monitor for changes
3. **New endpoints** - Test for new features

### Test Endpoint

If you have an existing API key:

```http
GET https://api.songkick.com/api/3.0/search/artists.json?query=Phish&apikey={your-key}
```

Expected: Returns `resultsPage` with artist results.

### API Access Status

**WARNING**: As of 2024, new API key applications are suspended.

- Existing keys may continue working
- Contact partnerships@songkick.com for business access
- No public timeline for reopening

### Last Verified

- **Date**: March 2026
- **Verified by**: Documentation review (limited testing due to key restrictions)
