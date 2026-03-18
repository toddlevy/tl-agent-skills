# Setlist.fm API Reference

**Role**: Historical setlist data - what songs artists played at each show

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://api.setlist.fm/rest/1.0` |
| Auth | API key in `x-api-key` header |
| Rate Limit | Undocumented (request increase if needed) |
| Format | JSON (set `Accept: application/json`) |
| Docs | https://api.setlist.fm/docs/1.0/index.html |
| Swagger UI | https://api.setlist.fm/docs/1.0/ui/index.html |
| Get API Key | https://www.setlist.fm/settings/api |

## Authentication

```http
Accept: application/json
x-api-key: your-api-key-here
```

## Endpoints

### Search Artists

```http
GET /search/artists?artistName={name}
GET /search/artists?artistMbid={mbid}
```

**Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `artistName` | string | Artist name search |
| `artistMbid` | string | MusicBrainz ID |
| `p` | int | Page number (1-based) |
| `sort` | string | `sortName` or `relevance` |

### Search Setlists

```http
GET /search/setlists?artistName={name}
GET /search/setlists?artistMbid={mbid}
GET /search/setlists?date={dd-MM-yyyy}
GET /search/setlists?venueId={id}
GET /search/setlists?cityId={geoId}
GET /search/setlists?tourName={name}
```

**Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `artistName` | string | Artist name |
| `artistMbid` | string | MusicBrainz ID |
| `date` | string | Date (dd-MM-yyyy) |
| `year` | int | Year filter |
| `venueId` | string | Setlist.fm venue ID |
| `cityId` | string | Geo ID for city |
| `tourName` | string | Tour name |
| `p` | int | Page (1-based) |

### Search Venues

```http
GET /search/venues?name={name}
GET /search/venues?name={name}&cityName={city}
GET /search/venues?name={name}&state={state}&stateCode={code}
```

### Search Cities

```http
GET /search/cities?name={name}
GET /search/cities?name={name}&country={countryCode}
```

### List Countries

```http
GET /search/countries
```

### Artist Lookup

```http
GET /artist/{mbid}
GET /artist/{mbid}/setlists
GET /artist/{mbid}/setlists?p={page}
```

### Setlist Lookup

```http
GET /setlist/{setlistId}
GET /setlist/version/{versionId}
```

### Venue Lookup

```http
GET /venue/{venueId}
GET /venue/{venueId}/setlists
```

### City Lookup

```http
GET /city/{geoId}
```

### User Data

```http
GET /user/{userId}
GET /user/{userId}/attended
GET /user/{userId}/edited
```

## Response Schemas

### Artist

```json
{
  "mbid": "e01646f2-2a04-450d-8bf2-0d993082e058",
  "name": "Phish",
  "sortName": "Phish",
  "disambiguation": "",
  "url": "https://www.setlist.fm/setlists/phish-13d6ad51.html"
}
```

### Setlist

```json
{
  "id": "3bd6b098",
  "versionId": "7b3e2f1a",
  "eventDate": "31-12-2023",
  "lastUpdated": "2024-01-02T15:30:00.000+0000",
  "artist": { "mbid": "...", "name": "Phish" },
  "venue": {
    "id": "43d6a098",
    "name": "Madison Square Garden",
    "city": {
      "id": "5128581",
      "name": "New York",
      "state": "New York",
      "stateCode": "NY",
      "coords": { "lat": 40.7128, "long": -74.006 },
      "country": { "code": "US", "name": "United States" }
    }
  },
  "tour": { "name": "NYE Run 2023" },
  "sets": {
    "set": [
      {
        "name": "Set 1",
        "song": [
          { "name": "Tweezer", "info": "-> jam" },
          { "name": "Slave to the Traffic Light" }
        ]
      },
      {
        "name": "Set 2",
        "song": [
          { "name": "Down with Disease", "with": { "mbid": "...", "name": "Trey Anastasio" }},
          { "name": "Purple Rain", "cover": { "mbid": "...", "name": "Prince" }}
        ]
      },
      {
        "encore": 1,
        "song": [
          { "name": "Tweezer Reprise" }
        ]
      }
    ]
  },
  "url": "https://www.setlist.fm/setlist/phish/2023/madison-square-garden-3bd6b098.html"
}
```

### Song Object

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Song name |
| `info` | string | Notes (e.g., "-> jam", "with solo") |
| `with` | Artist | Guest performer |
| `cover` | Artist | Original artist if cover song |
| `tape` | boolean | If true, played from tape |

## Pagination

```json
{
  "type": "setlists",
  "itemsPerPage": 20,
  "page": 1,
  "total": 2847,
  "setlist": [...]
}
```

**Parameters**:
- `p` - Page number (1-based)
- `itemsPerPage` - Default 20

## Date Format

**Critical**: Dates use `dd-MM-yyyy` format, NOT ISO:
- ✅ `31-12-2023`
- ❌ `2023-12-31`

## Common Gotchas

1. **Wiki-style editing**: Setlists can be edited by users. Check `lastUpdated` for freshness
2. **Deleted setlists**: Return 404 - handle gracefully
3. **MBID integration**: Use MusicBrainz ID for reliable artist matching
4. **Multiple sets**: Shows can have Set 1, Set 2, Set 3, Encore 1, Encore 2, etc.

## Example: Get Artist's Recent Setlists

```typescript
const mbid = 'e01646f2-2a04-450d-8bf2-0d993082e058';

const response = await fetch(
  `https://api.setlist.fm/rest/1.0/artist/${mbid}/setlists?p=1`,
  {
    headers: {
      'Accept': 'application/json',
      'x-api-key': process.env.SETLISTFM_API_KEY
    }
  }
);

const data = await response.json();
// data.setlist[] contains recent shows
```

## Example: Search Setlists by Date

```typescript
const response = await fetch(
  `https://api.setlist.fm/rest/1.0/search/setlists?date=31-12-2023&p=1`,
  {
    headers: {
      'Accept': 'application/json',
      'x-api-key': process.env.SETLISTFM_API_KEY
    }
  }
);
```

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist info | 7 days |
| Recent setlists (< 30 days) | 4 hours |
| Historical setlists (> 30 days) | 30 days |
| Venue info | 30 days |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| API Docs | https://api.setlist.fm/docs/1.0/index.html |
| Swagger UI | https://api.setlist.fm/docs/1.0/ui/index.html |
| Get API Key | https://www.setlist.fm/settings/api |
| OpenAPI Spec | https://api.setlist.fm/docs/1.0/json |

### Version Detection

Check the Swagger UI for version number in header, or:

```http
GET https://api.setlist.fm/docs/1.0/json
```

Current version is `1.0`. If URL structure changes (e.g., `/rest/2.0`), major update occurred.

### Test Endpoint

Verify API is responding:

```http
GET https://api.setlist.fm/rest/1.0/artist/e01646f2-2a04-450d-8bf2-0d993082e058
Headers: Accept: application/json, x-api-key: {your-key}
```

Expected: Returns artist object with `mbid`, `name`, `url` fields.

### Last Verified

- **Date**: March 2026
- **Verified by**: Swagger UI and API probing
