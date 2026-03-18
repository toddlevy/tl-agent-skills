# Ticketmaster Discovery API Reference

**Role**: Events and ticketing - venues, attractions, classifications

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://app.ticketmaster.com/discovery/v2` |
| Auth | API key (query parameter) |
| Rate Limit | 5,000 requests/day (free tier) |
| Format | JSON |
| Docs | https://developer.ticketmaster.com/products-and-docs/apis/discovery-api/v2/ |
| OpenAPI | https://github.com/konfig-sdks/openapi-examples/ticketmaster/discovery/openapi.yaml |

## Authentication

```
?apikey=your-api-key
```

Get API key from https://developer.ticketmaster.com

## Events

### Search Events

```http
GET /events?apikey={key}
GET /events?apikey={key}&keyword={search}
GET /events?apikey={key}&attractionId={id}
GET /events?apikey={key}&venueId={id}
```

**Search Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `keyword` | string | Text search |
| `attractionId` | string | Filter by attraction (artist) |
| `venueId` | string | Filter by venue |
| `classificationName` | string | Music, Sports, etc. |
| `classificationId` | string | Classification ID |

**Date Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `startDateTime` | datetime | Start range (ISO 8601) |
| `endDateTime` | datetime | End range (ISO 8601) |
| `localStartDateTime` | string | Local time range |

**Geo Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `latlong` | string | "40.7128,-74.0060" |
| `radius` | int | Search radius |
| `unit` | string | `miles` or `km` |
| `city` | string | City name |
| `stateCode` | string | State code (NY) |
| `countryCode` | string | Country code (US) |
| `postalCode` | string | Postal/ZIP code |
| `geoPoint` | string | Encoded geohash |

**Sorting**:
| Value | Description |
|-------|-------------|
| `date,asc` | Chronological |
| `date,desc` | Reverse chronological |
| `name,asc` | Alphabetical |
| `relevance,desc` | Most relevant |

### Get Event

```http
GET /events/{id}?apikey={key}
```

### Event Response

```json
{
  "id": "G5diZfkn0B-bh",
  "name": "Phish",
  "type": "event",
  "url": "https://www.ticketmaster.com/event/G5diZfkn0B-bh",
  "locale": "en-us",
  "dates": {
    "start": {
      "localDate": "2024-12-31",
      "localTime": "20:00:00",
      "dateTime": "2025-01-01T01:00:00Z",
      "dateTBD": false,
      "dateTBA": false,
      "timeTBA": false
    },
    "end": {
      "localDate": "2024-12-31",
      "localTime": "23:59:00"
    },
    "status": {
      "code": "onsale"
    }
  },
  "classifications": [{
    "primary": true,
    "segment": {"id": "KZFzniwnSyZfZ7v7nJ", "name": "Music"},
    "genre": {"id": "KnvZfZ7vAeA", "name": "Rock"},
    "subGenre": {"id": "KZazBEonSMnZfZ7v6F1", "name": "Alternative Rock"}
  }],
  "priceRanges": [{
    "type": "standard",
    "currency": "USD",
    "min": 75.00,
    "max": 250.00
  }],
  "_embedded": {
    "venues": [{
      "id": "KovZpZAFnIEA",
      "name": "Madison Square Garden",
      "city": {"name": "New York"},
      "state": {"name": "New York", "stateCode": "NY"},
      "country": {"name": "United States", "countryCode": "US"},
      "location": {
        "longitude": "-73.9934",
        "latitude": "40.7505"
      }
    }],
    "attractions": [{
      "id": "K8vZ9175st0",
      "name": "Phish",
      "type": "attraction",
      "url": "https://www.ticketmaster.com/phish-tickets/artist/K8vZ9175st0"
    }]
  }
}
```

## Attractions (Artists)

### Search Attractions

```http
GET /attractions?apikey={key}&keyword={search}
GET /attractions?apikey={key}&classificationName=music
```

**Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `keyword` | string | Search term |
| `classificationName` | string | Classification filter |
| `classificationId` | string | Classification ID |
| `sort` | string | Sort order |

### Get Attraction

```http
GET /attractions/{id}?apikey={key}
```

### Attraction Response

```json
{
  "id": "K8vZ9175st0",
  "name": "Phish",
  "type": "attraction",
  "url": "https://www.ticketmaster.com/phish-tickets/artist/K8vZ9175st0",
  "images": [{
    "url": "https://...",
    "width": 640,
    "height": 360,
    "ratio": "16_9"
  }],
  "classifications": [{
    "primary": true,
    "segment": {"id": "KZFzniwnSyZfZ7v7nJ", "name": "Music"},
    "genre": {"id": "KnvZfZ7vAeA", "name": "Rock"}
  }],
  "externalLinks": {
    "musicbrainz": [{"id": "e01646f2-2a04-450d-8bf2-0d993082e058"}],
    "homepage": [{"url": "https://phish.com"}],
    "wiki": [{"url": "https://en.wikipedia.org/wiki/Phish"}]
  },
  "upcomingEvents": {
    "_total": 15,
    "ticketmaster": 15
  }
}
```

## Venues

### Search Venues

```http
GET /venues?apikey={key}&keyword={search}
GET /venues?apikey={key}&city={city}&stateCode={state}
GET /venues?apikey={key}&latlong={lat},{lng}&radius={radius}
```

### Get Venue

```http
GET /venues/{id}?apikey={key}
```

### Venue Response

```json
{
  "id": "KovZpZAFnIEA",
  "name": "Madison Square Garden",
  "type": "venue",
  "url": "https://www.ticketmaster.com/madison-square-garden-tickets/venue/KovZpZAFnIEA",
  "city": {"name": "New York"},
  "state": {"name": "New York", "stateCode": "NY"},
  "country": {"name": "United States", "countryCode": "US"},
  "address": {"line1": "4 Pennsylvania Plaza"},
  "postalCode": "10001",
  "location": {
    "longitude": "-73.9934",
    "latitude": "40.7505"
  },
  "boxOfficeInfo": {
    "phoneNumberDetail": "212-465-6741",
    "openHoursDetail": "Mon-Sat 10am-6pm"
  },
  "generalInfo": {
    "generalRule": "No cameras, no recording devices...",
    "childRule": "Children under 2 free on lap"
  },
  "upcomingEvents": {
    "_total": 127,
    "ticketmaster": 127
  }
}
```

## Classifications

### Search Classifications

```http
GET /classifications?apikey={key}
GET /classifications?apikey={key}&keyword={search}
```

### Get Classification

```http
GET /classifications/{id}?apikey={key}
GET /classifications/genres/{id}?apikey={key}
GET /classifications/segments/{id}?apikey={key}
GET /classifications/subgenres/{id}?apikey={key}
```

## Pagination

```json
{
  "page": {
    "size": 20,
    "totalElements": 1500,
    "totalPages": 75,
    "number": 0
  },
  "_links": {
    "self": {"href": "..."},
    "next": {"href": "..."},
    "prev": {"href": "..."}
  }
}
```

**Parameters**:
| Param | Type | Description |
|-------|------|-------------|
| `page` | int | Page number (0-based) |
| `size` | int | Items per page (max 500) |

## Sources

Events can come from multiple sources:
- `ticketmaster`
- `universe`
- `frontgate`
- `tmr`

Filter by source:
```
?source=ticketmaster
```

## TypeScript Implementation

```typescript
interface TicketmasterEvent {
  id: string;
  name: string;
  url: string;
  dates: {
    start: {
      localDate: string;
      localTime: string;
      dateTime: string;
    };
    status: {
      code: string;
    };
  };
  _embedded?: {
    venues: TicketmasterVenue[];
    attractions: TicketmasterAttraction[];
  };
}

interface TicketmasterAttraction {
  id: string;
  name: string;
  externalLinks?: {
    musicbrainz?: Array<{ id: string }>;
  };
}

interface TicketmasterVenue {
  id: string;
  name: string;
  city: { name: string };
  state: { stateCode: string };
  location: {
    latitude: string;
    longitude: string;
  };
}

const API_KEY = process.env.TICKETMASTER_API_KEY;

async function searchEvents(params: {
  keyword?: string;
  latlong?: string;
  radius?: number;
  startDateTime?: string;
  size?: number;
}): Promise<TicketmasterEvent[]> {
  const url = new URL('https://app.ticketmaster.com/discovery/v2/events');
  url.searchParams.set('apikey', API_KEY);
  
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined) {
      url.searchParams.set(key, String(value));
    }
  }
  
  const response = await fetch(url.toString());
  const data = await response.json();
  
  return data._embedded?.events || [];
}

async function getAttraction(id: string): Promise<TicketmasterAttraction> {
  const response = await fetch(
    `https://app.ticketmaster.com/discovery/v2/attractions/${id}?apikey=${API_KEY}`
  );
  return response.json();
}
```

## ID Resolution

Attractions may include MusicBrainz IDs in `externalLinks`:

```typescript
const attraction = await getAttraction('K8vZ9175st0');
const mbid = attraction.externalLinks?.musicbrainz?.[0]?.id;
// "e01646f2-2a04-450d-8bf2-0d993082e058"
```

## Rate Limiting

5,000 requests/day on free tier.

**Headers**:
```
Rate-Limit: 5000
Rate-Limit-Available: 4832
Rate-Limit-Over: 0
Rate-Limit-Reset: 1704067200
```

## Common Errors

| Code | Cause | Fix |
|------|-------|-----|
| 401 | Invalid/missing API key | Check apikey param |
| 404 | Resource not found | Verify ID |
| 429 | Rate limit exceeded | Wait for reset |

## Caching Recommendations

| Data | TTL |
|------|-----|
| Attraction info | 7 days |
| Venue info | 30 days |
| Event search | 1-4 hours |
| Classifications | 30 days |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| API Docs | https://developer.ticketmaster.com/products-and-docs/apis/discovery-api/v2/ |
| Developer Portal | https://developer.ticketmaster.com |
| OpenAPI Spec | https://github.com/konfig-sdks/openapi-examples/tree/main/ticketmaster/discovery |
| Changelog | https://developer.ticketmaster.com/products-and-docs/changelog/ |
| Status | https://status.ticketmaster.com |
| Forum | https://developer.ticketmaster.com/community/ |

### Version Detection

URL contains version (`/discovery/v2`). Check:

1. **Changelog page** - https://developer.ticketmaster.com/products-and-docs/changelog/
2. **Developer portal announcements** - Banner notifications
3. **Response headers** - May include deprecation warnings

```typescript
async function checkTMVersion(): Promise<string> {
  const response = await fetch('https://app.ticketmaster.com/discovery/v2/events?apikey=...');
  // Check for deprecation headers
  const deprecation = response.headers.get('Deprecation');
  const sunset = response.headers.get('Sunset');
  return { deprecation, sunset };
}
```

### Test Endpoint

Verify API is responding:

```http
GET https://app.ticketmaster.com/discovery/v2/attractions/K8vZ9175st0?apikey={your-key}
```

Expected: Returns Phish attraction with `id`, `name`, `externalLinks` fields.

### Rate Limit Headers

Monitor in responses:

```
Rate-Limit: 5000
Rate-Limit-Available: 4832
Rate-Limit-Reset: 1704067200
```

### Last Verified

- **Date**: March 2026
- **Verified by**: API probing and changelog review
