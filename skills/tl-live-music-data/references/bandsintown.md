# Bandsintown API Reference

**Role**: Artist events and tour dates - simple artist-centric event lookup

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://rest.bandsintown.com` |
| Auth | App ID (query parameter) |
| Rate Limit | Undocumented |
| Format | JSON |
| Docs | https://help.artists.bandsintown.com/en/articles/9186477-api-documentation |
| OpenAPI | 3.0 spec available via apis.guru |

## Authentication

Request an App ID from Bandsintown, then pass as query param:

```
?app_id=your-app-id
```

## Artist Lookup Methods

### By Artist Name

```http
GET /artists/{artist_name}?app_id={id}
```

**URL Encoding**: Artist names must be URL-encoded:
- `The Black Keys` → `The%20Black%20Keys`
- `AC/DC` → `AC%2FDC`
- `Guns N' Roses` → `Guns%20N%27%20Roses`

### By Bandsintown ID

```http
GET /artists/id_{artist_id}?app_id={id}
```

Example: `/artists/id_1234567?app_id=myapp`

### By Facebook Page ID

```http
GET /artists/fbid_{facebook_id}?app_id={id}
```

Example: `/artists/fbid_159736697498?app_id=myapp`

## Artist Response

```json
{
  "id": "1234567",
  "name": "Phish",
  "url": "https://www.bandsintown.com/a/1234567",
  "image_url": "https://...",
  "thumb_url": "https://...",
  "facebook_page_url": "https://www.facebook.com/phish",
  "mbid": "e01646f2-2a04-450d-8bf2-0d993082e058",
  "tracker_count": 125000,
  "upcoming_event_count": 15,
  "support_url": "https://...",
  "links": [
    {
      "type": "website",
      "url": "https://phish.com"
    }
  ]
}
```

## Events Endpoints

### All Events

```http
GET /artists/{name}/events?app_id={id}
```

### Upcoming Events Only

```http
GET /artists/{name}/events?app_id={id}&date=upcoming
```

### Past Events Only

```http
GET /artists/{name}/events?app_id={id}&date=past
```

### All Events (Past + Future)

```http
GET /artists/{name}/events?app_id={id}&date=all
```

### Date Range

```http
GET /artists/{name}/events?app_id={id}&date=2024-01-01,2024-12-31
```

## Event Response

```json
[
  {
    "id": "123456789",
    "artist_id": "1234567",
    "url": "https://www.bandsintown.com/e/123456789",
    "on_sale_datetime": "2023-10-01T10:00:00",
    "datetime": "2024-12-31T20:00:00",
    "description": "New Year's Eve Run",
    "venue": {
      "name": "Madison Square Garden",
      "latitude": "40.7505",
      "longitude": "-73.9934",
      "city": "New York",
      "region": "NY",
      "country": "United States",
      "location": "New York, NY"
    },
    "offers": [
      {
        "type": "Tickets",
        "url": "https://...",
        "status": "available"
      }
    ],
    "lineup": [
      "Phish"
    ],
    "starts_at": "2024-12-31T20:00:00",
    "ends_at": "2024-12-31T23:59:00",
    "festival_start_date": null,
    "festival_end_date": null,
    "festival_datetime_display_rule": null,
    "title": "Phish NYE Run"
  }
]
```

## Venue Object

```json
{
  "name": "Madison Square Garden",
  "latitude": "40.7505",
  "longitude": "-73.9934",
  "city": "New York",
  "region": "NY",
  "country": "United States",
  "location": "New York, NY",
  "street_address": "4 Pennsylvania Plaza",
  "postal_code": "10001"
}
```

## Virtual Events (Livestreams)

Check `venue.type` for virtual events:

```typescript
const isLivestream = event.venue.type === 'Virtual';
```

Virtual venue response:
```json
{
  "venue": {
    "name": "Online Event",
    "type": "Virtual",
    "city": "",
    "region": "",
    "country": ""
  }
}
```

## TypeScript Implementation

```typescript
interface BandsintownArtist {
  id: string;
  name: string;
  url: string;
  image_url: string;
  thumb_url: string;
  facebook_page_url: string;
  mbid: string | null;
  tracker_count: number;
  upcoming_event_count: number;
}

interface BandsintownVenue {
  name: string;
  type?: string;
  latitude: string;
  longitude: string;
  city: string;
  region: string;
  country: string;
  location: string;
}

interface BandsintownEvent {
  id: string;
  artist_id: string;
  url: string;
  datetime: string;
  venue: BandsintownVenue;
  offers: Array<{
    type: string;
    url: string;
    status: string;
  }>;
  lineup: string[];
  title: string;
}

const APP_ID = process.env.BANDSINTOWN_APP_ID;

async function getArtist(name: string): Promise<BandsintownArtist> {
  const encoded = encodeURIComponent(name);
  const response = await fetch(
    `https://rest.bandsintown.com/artists/${encoded}?app_id=${APP_ID}`
  );
  return response.json();
}

async function getArtistEvents(
  name: string, 
  dateFilter: 'upcoming' | 'past' | 'all' | string = 'upcoming'
): Promise<BandsintownEvent[]> {
  const encoded = encodeURIComponent(name);
  const response = await fetch(
    `https://rest.bandsintown.com/artists/${encoded}/events?app_id=${APP_ID}&date=${dateFilter}`
  );
  return response.json();
}

async function getArtistByMbid(mbid: string): Promise<BandsintownArtist | null> {
  // Bandsintown doesn't support MBID lookup directly
  // Artist response includes mbid field if available
  // Must search by name first
  return null;
}
```

## Limitations

1. **No geographic search** - Cannot search events by location without specifying artist
2. **No MBID lookup** - Must search by name (response may include `mbid` field)
3. **Rate limit undocumented** - Use conservative delays

## ID Resolution

Bandsintown includes MBID in artist response when available:

```typescript
const artist = await getArtist('Phish');
if (artist.mbid) {
  // Can use MBID with other services
}
```

For reverse lookup (MBID → Bandsintown), search by artist name.

## Common Errors

| Code | Cause | Fix |
|------|-------|-----|
| 404 | Artist not found | Check spelling, try variations |
| 403 | Invalid app_id | Verify app_id is correct |

## Empty Responses

- Artist with no events returns `[]`
- Unrecognized artist returns 404

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist info | 7 days |
| Upcoming events | 1-4 hours |
| Past events | 30 days |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| API Docs | https://help.artists.bandsintown.com/en/articles/9186477-api-documentation |
| OpenAPI Spec | https://apis.guru/apis/bandsintown.com |
| Artist Portal | https://artists.bandsintown.com |
| Status | https://status.bandsintown.com (if available) |

### Version Detection

Bandsintown API doesn't use explicit versioning in URL. Monitor:

1. **Response structure** - Check for new/deprecated fields
2. **Documentation page** - Watch for updates
3. **Error messages** - May indicate deprecated endpoints

### Test Endpoint

Verify API is responding:

```http
GET https://rest.bandsintown.com/artists/Phish?app_id={your-app-id}
```

Expected: Returns artist object with `id`, `name`, `upcoming_event_count` fields.

### Last Verified

- **Date**: March 2026
- **Verified by**: API probing and documentation review
