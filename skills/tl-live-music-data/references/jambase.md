# JamBase API Reference

**Role**: Most comprehensive events API - events, venues, artists with multi-source ID support

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://www.jambase.com/jb-api/v1` |
| Alt Gateway | `https://jb-zuplo-monetization-v1-main-c3376d1.zuplo.app` |
| Auth | API key (query param or header) |
| Rate Limit | 3,600 requests/hour |
| Format | JSON (Schema.org compatible) |
| Docs | https://apidocs.jambase.com |
| OpenAPI | 3.1 spec available |

## Authentication

API key via query param:
```
?apikey=your-api-key
```

Or header:
```
Authorization: Bearer your-api-key
```

## Key Feature: Multi-Source ID Lookup

JamBase accepts **12 different ID sources** for artist lookup:

```http
GET /artists/id/{source}:{id}
```

**Supported Sources**:
| Source | Example |
|--------|---------|
| `jambase` | `jambase:12345` |
| `musicbrainz` | `musicbrainz:e01646f2-2a04-450d-8bf2-0d993082e058` |
| `spotify` | `spotify:6rqhFgbbKwnb9MLmUQDhG6` |
| `ticketmaster` | `ticketmaster:K8vZ9175st0` |
| `seatgeek` | `seatgeek:12345` |
| `eventbrite` | `eventbrite:12345` |
| `axs` | `axs:12345` |
| `dice` | `dice:12345` |
| `etix` | `etix:12345` |
| `seated` | `seated:12345` |
| `viagogo` | `viagogo:12345` |
| `eventim-de` | `eventim-de:12345` |

## Endpoints

### Events

```http
GET /events
GET /events/id/{source}:{id}
```

**Event Filters**:
| Param | Type | Description |
|-------|------|-------------|
| `artistId` | string | Artist ID (source:id format) |
| `artistName` | string | Artist name search |
| `venueId` | string | Venue ID |
| `venueName` | string | Venue name search |
| `genreSlug` | string | Genre filter |
| `eventType` | string | `concerts` or `festivals` |

**Date Filters**:
| Param | Type | Description |
|-------|------|-------------|
| `eventDateFrom` | date | Start date (YYYY-MM-DD) |
| `eventDateTo` | date | End date |
| `eventDatePreset` | string | See presets below |

**Date Presets**:
- `today`, `tomorrow`, `thisWeek`, `thisWeekend`
- `nextWeek`, `nextWeekend`, `thisMonth`, `nextMonth`

**Geo Filters**:
| Param | Type | Description |
|-------|------|-------------|
| `geoLatitude` | float | Latitude |
| `geoLongitude` | float | Longitude |
| `geoRadiusAmount` | int | 1-5000 |
| `geoRadiusUnits` | string | `mi` or `km` |
| `geoCityId` | string | JamBase city ID |
| `geoCityName` | string | City name |
| `geoStateIso` | string | State code (US-NY) |
| `geoMetroId` | string | Metro area ID |
| `geoCountryIso2` | string | Country code (US) |
| `geoIp` | string | IP address for geo |

### Streams (Livestreams)

```http
GET /streams
GET /streams/id/{source}:{id}
```

Same filters as events.

### Artists

```http
GET /artists?artistName={name}
GET /artists?genreSlug={genre}
GET /artists/id/{source}:{id}
```

**Required**: Either `artistName` or `genreSlug`

**Expand Options**:
| Param | Effect |
|-------|--------|
| `expandExternalIdentifiers=true` | Include MBID, Spotify, TM IDs |
| `expandPastEvents=true` | Include historical events |
| `expandUpcomingEvents=true` | Include upcoming events |

### Venues

```http
GET /venues?venueName={name}
GET /venues?geoLatitude={lat}&geoLongitude={lng}
GET /venues/id/{source}:{id}
```

**Required**: Either `venueName` or geo params

**Venue ID Sources**:
- jambase, ticketmaster, seatgeek, eventbrite, axs, dice, etix, seated, viagogo

### Geographies

```http
GET /geographies/cities?cityName={name}
GET /geographies/metros?metroName={name}
GET /geographies/metros?expandMetroCities=true
GET /geographies/states              # US/CA/AU only
GET /geographies/countries
```

### Genres

```http
GET /genres
```

Returns 18 genres: bluegrass, blues, country, edm, folk, funk, hiphop, indie, jamband, jazz, latin, metal, pop, punk, reggae, rock, rnb, soul

### Lookup Endpoints

```http
GET /lookups/artist-data-sources
GET /lookups/venue-data-sources
GET /lookups/event-data-sources
```

## Multi-Value Parameters

Use pipe `|` for multiple values:

```http
GET /events?artistId=jambase:123|ticketmaster:456|spotify:789
```

## Response Schema

JamBase uses Schema.org-compatible responses:

### Event Response

```json
{
  "events": [{
    "@type": "MusicEvent",
    "identifier": "jambase:12345",
    "name": "Phish at MSG",
    "startDate": "2024-12-31T20:00:00-05:00",
    "endDate": "2024-12-31T23:59:00-05:00",
    "eventStatus": "https://schema.org/EventScheduled",
    "performer": [{
      "@type": "MusicGroup",
      "identifier": "jambase:67890",
      "name": "Phish",
      "sameAs": [
        "https://musicbrainz.org/artist/e01646f2-2a04-450d-8bf2-0d993082e058",
        "https://open.spotify.com/artist/6rqhFgbbKwnb9MLmUQDhG6"
      ]
    }],
    "location": {
      "@type": "MusicVenue",
      "identifier": "jambase:11111",
      "name": "Madison Square Garden",
      "address": {
        "@type": "PostalAddress",
        "addressLocality": "New York",
        "addressRegion": "NY",
        "postalCode": "10001",
        "addressCountry": "US"
      },
      "geo": {
        "@type": "GeoCoordinates",
        "latitude": 40.7505,
        "longitude": -73.9934
      }
    },
    "offers": [{
      "@type": "Offer",
      "url": "https://...",
      "priceCurrency": "USD",
      "availability": "https://schema.org/InStock"
    }]
  }],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "totalItems": 150,
    "totalPages": 8
  }
}
```

### Artist Response (with expandExternalIdentifiers)

```json
{
  "artists": [{
    "@type": "MusicGroup",
    "identifier": "jambase:67890",
    "name": "Phish",
    "description": "...",
    "genre": ["jamband", "rock"],
    "image": "https://...",
    "sameAs": [
      "https://musicbrainz.org/artist/e01646f2-2a04-450d-8bf2-0d993082e058",
      "https://open.spotify.com/artist/6rqhFgbbKwnb9MLmUQDhG6",
      "https://www.ticketmaster.com/artist/K8vZ9175st0"
    ],
    "externalIdentifiers": {
      "musicbrainz": "e01646f2-2a04-450d-8bf2-0d993082e058",
      "spotify": "6rqhFgbbKwnb9MLmUQDhG6",
      "ticketmaster": "K8vZ9175st0"
    }
  }]
}
```

## Coverage Stats

- **400k+** artists
- **170k+** venues
- **100k+** upcoming events
- **3M+** historical events

## Rate Limiting

3,600 requests/hour = 1 request/second sustained

```typescript
const JB_DELAY = 1000;
let lastRequest = 0;

async function jbFetch(path: string): Promise<Response> {
  const now = Date.now();
  const wait = Math.max(0, JB_DELAY - (now - lastRequest));
  if (wait > 0) await sleep(wait);
  
  lastRequest = Date.now();
  
  const url = new URL(`https://www.jambase.com/jb-api/v1${path}`);
  url.searchParams.set('apikey', process.env.JAMBASE_API_KEY);
  
  return fetch(url);
}
```

## Error Handling

JamBase returns errors in an array:

```json
{
  "errors": [{
    "errorCode": "INVALID_PARAMETER",
    "errorMessage": "artistName or genreSlug is required"
  }]
}
```

## Example: Get Events by Artist MBID

```typescript
const mbid = 'e01646f2-2a04-450d-8bf2-0d993082e058';

const response = await fetch(
  `https://www.jambase.com/jb-api/v1/events?` +
  `artistId=musicbrainz:${mbid}&` +
  `eventDatePreset=thisMonth&` +
  `apikey=${process.env.JAMBASE_API_KEY}`
);

const data = await response.json();
// data.events[] contains upcoming shows
```

## Example: Geo Search

```typescript
const response = await fetch(
  `https://www.jambase.com/jb-api/v1/events?` +
  `geoLatitude=40.7128&` +
  `geoLongitude=-74.0060&` +
  `geoRadiusAmount=25&` +
  `geoRadiusUnits=mi&` +
  `eventDatePreset=thisWeekend&` +
  `apikey=${process.env.JAMBASE_API_KEY}`
);
```

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist info | 7 days |
| Venue info | 30 days |
| Upcoming events | 1-4 hours |
| Historical events | 30+ days |
| Geographies | 90 days |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| API Docs | https://apidocs.jambase.com |
| Developer Portal | https://developer.jambase.com |
| OpenAPI Spec | Available via developer portal |
| Support | https://help.jambase.com |

### Version Detection

JamBase uses `/jb-api/v1` in URL. Check:

1. **URL path** - Version number in path (`v1`, `v2`, etc.)
2. **Response headers** - May include `X-Api-Version`
3. **Developer portal** - Announcements section

```typescript
async function checkJamBaseVersion(): Promise<string> {
  const response = await fetch('https://www.jambase.com/jb-api/v1/genres?apikey=...');
  return response.headers.get('X-Api-Version') || 'v1';
}
```

### Test Endpoint

Verify API is responding:

```http
GET https://www.jambase.com/jb-api/v1/genres?apikey={your-key}
```

Expected: Returns array of 18 genre objects.

### Changelog

JamBase announces changes via:
- Developer portal changelog
- Email to registered developers

### Last Verified

- **Date**: March 2026
- **Verified by**: API probing and OpenAPI spec review
