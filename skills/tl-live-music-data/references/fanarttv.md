# Fanart.tv API Reference

**Role**: High-resolution artist and album artwork using MusicBrainz IDs

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://webservice.fanart.tv/v3` |
| Auth | API key (query parameter) |
| Rate Limit | Undocumented |
| Format | JSON |
| Docs | https://fanarttv.docs.apiary.io |
| Get API Key | https://fanart.tv/get-an-api-key/ |

## Authentication

```
?api_key=your-api-key
```

Optional VIP key for higher limits:
```
?api_key=your-api-key&client_key=your-vip-key
```

## Key Feature: MusicBrainz ID Required

Fanart.tv uses **MusicBrainz IDs** exclusively:
- Artist images: Artist MBID
- Album images: Release-group MBID (NOT release MBID)
- Label images: Label MBID

## Endpoints

### Artist Images

```http
GET /music/{artist_mbid}?api_key={key}
```

**Example**:
```http
GET /music/e01646f2-2a04-450d-8bf2-0d993082e058?api_key={key}
```

**Response**:
```json
{
  "name": "Phish",
  "mbid_id": "e01646f2-2a04-450d-8bf2-0d993082e058",
  "artistbackground": [
    {
      "id": "123456",
      "url": "https://assets.fanart.tv/fanart/music/.../background.jpg",
      "likes": "3"
    }
  ],
  "artistthumb": [
    {
      "id": "234567",
      "url": "https://assets.fanart.tv/fanart/music/.../thumb.jpg",
      "likes": "5"
    }
  ],
  "musiclogo": [
    {
      "id": "345678",
      "url": "https://assets.fanart.tv/fanart/music/.../logo.png",
      "likes": "2"
    }
  ],
  "hdmusiclogo": [
    {
      "id": "456789",
      "url": "https://assets.fanart.tv/fanart/music/.../hdlogo.png",
      "likes": "4"
    }
  ],
  "musicbanner": [
    {
      "id": "567890",
      "url": "https://assets.fanart.tv/fanart/music/.../banner.jpg",
      "likes": "1"
    }
  ]
}
```

### Album Images

```http
GET /music/albums/{release_group_mbid}?api_key={key}
```

**Important**: Use release-group MBID, NOT release MBID.

**Response**:
```json
{
  "name": "A Live One",
  "mbid_id": "1b022e01-4da6-387b-8658-8678046e4cef",
  "albumcover": [
    {
      "id": "123456",
      "url": "https://assets.fanart.tv/fanart/music/.../cover.jpg",
      "likes": "10",
      "disc": "1"
    }
  ],
  "cdart": [
    {
      "id": "234567",
      "url": "https://assets.fanart.tv/fanart/music/.../cd.png",
      "likes": "3",
      "disc": "1",
      "size": "1000"
    }
  ]
}
```

### Label Images

```http
GET /music/labels/{label_mbid}?api_key={key}
```

**Response**:
```json
{
  "name": "Elektra Records",
  "mbid_id": "abc123...",
  "musiclabel": [
    {
      "id": "123456",
      "url": "https://assets.fanart.tv/fanart/music/.../label.png",
      "likes": "5",
      "colour": "colour"
    }
  ]
}
```

### Latest Updates

#### Latest Artist Updates

```http
GET /music/latest?api_key={key}&date={unix_timestamp}
```

#### Latest Album Updates

```http
GET /music/albums/latest?api_key={key}&date={unix_timestamp}
```

Returns artists/albums updated since the given timestamp.

## Image Types

### Artist Images

| Type | Description | Dimensions |
|------|-------------|------------|
| `artistbackground` | Background/fanart | 1920x1080 |
| `artistthumb` | Square thumbnail | 1000x1000 |
| `musiclogo` | Logo (transparent) | 800x310 |
| `hdmusiclogo` | HD logo | 800x310 |
| `musicbanner` | Banner | 1000x185 |

### Album Images

| Type | Description | Dimensions |
|------|-------------|------------|
| `albumcover` | Album cover art | 1000x1000 |
| `cdart` | CD artwork (circular) | 1000x1000 |

### Label Images

| Type | Description |
|------|-------------|
| `musiclabel` | Record label logo |

## Sorting by Likes

Images are NOT pre-sorted. Sort by `likes` for best quality:

```typescript
function getBestImage(images: Array<{ url: string; likes: string }>): string | null {
  if (!images || images.length === 0) return null;
  
  const sorted = [...images].sort((a, b) => 
    parseInt(b.likes) - parseInt(a.likes)
  );
  
  return sorted[0].url;
}
```

## TypeScript Implementation

```typescript
interface FanartImage {
  id: string;
  url: string;
  likes: string;
}

interface FanartArtist {
  name: string;
  mbid_id: string;
  artistbackground?: FanartImage[];
  artistthumb?: FanartImage[];
  musiclogo?: FanartImage[];
  hdmusiclogo?: FanartImage[];
  musicbanner?: FanartImage[];
}

interface FanartAlbum {
  name: string;
  mbid_id: string;
  albumcover?: Array<FanartImage & { disc: string }>;
  cdart?: Array<FanartImage & { disc: string; size: string }>;
}

const API_KEY = process.env.FANARTTV_API_KEY;

async function getArtistImages(mbid: string): Promise<FanartArtist | null> {
  const response = await fetch(
    `https://webservice.fanart.tv/v3/music/${mbid}?api_key=${API_KEY}`
  );
  
  if (response.status === 404) return null;
  return response.json();
}

async function getAlbumImages(releaseGroupMbid: string): Promise<FanartAlbum | null> {
  const response = await fetch(
    `https://webservice.fanart.tv/v3/music/albums/${releaseGroupMbid}?api_key=${API_KEY}`
  );
  
  if (response.status === 404) return null;
  return response.json();
}

async function getBestArtistThumb(mbid: string): Promise<string | null> {
  const data = await getArtistImages(mbid);
  if (!data?.artistthumb?.length) return null;
  
  const sorted = [...data.artistthumb].sort((a, b) => 
    parseInt(b.likes) - parseInt(a.likes)
  );
  
  return sorted[0].url;
}
```

## ID Resolution

### Get Release-Group MBID from Release MBID

If you have a release MBID, get the release-group from MusicBrainz:

```http
GET https://musicbrainz.org/ws/2/release/{release_mbid}?inc=release-groups&fmt=json
```

Response includes `release-group.id`.

### From Album Name

Search MusicBrainz for release-group:

```http
GET https://musicbrainz.org/ws/2/release-group?query=release:{album}%20AND%20artist:{artist}&fmt=json
```

## API Versions

| Version | Notes |
|---------|-------|
| v3 | Current, documented |
| v3.1 | Minor updates |
| v3.2 | Latest minor updates |

All versions use same base URL format.

## Error Handling

```typescript
const response = await fetch(`https://webservice.fanart.tv/v3/music/${mbid}?api_key=${API_KEY}`);

if (response.status === 404) {
  // No images available for this artist/album
  return null;
}

if (response.status === 401) {
  // Invalid API key
  throw new Error('Invalid Fanart.tv API key');
}
```

## Common Gotchas

1. **Release-group vs Release** - Albums use release-group MBID
2. **Empty responses** - Not all artists have fanart
3. **Likes as strings** - Parse to int for sorting
4. **Multiple images** - Pick best by likes, not first
5. **No search endpoint** - Must have MBID first

## Coverage

Fanart.tv has better coverage for:
- Popular mainstream artists
- Classic rock bands
- Major label releases

Less coverage for:
- Indie artists
- Jam bands
- Live recordings

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist images | 30 days |
| Album images | 90 days |
| Label images | 90 days |
| Latest updates | 1 hour |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| API Docs (Apiary) | https://fanarttv.docs.apiary.io |
| Main Site | https://fanart.tv |
| Get API Key | https://fanart.tv/get-an-api-key/ |
| VIP Membership | https://fanart.tv/vip/ |

### Version Detection

URL contains version (`/v3`). Monitor:

1. **Apiary docs** - Check for version changes in header
2. **Response structure** - New image types may be added
3. **Error responses** - Watch for deprecation warnings

### Test Endpoint

Verify API is responding:

```http
GET https://webservice.fanart.tv/v3/music/e01646f2-2a04-450d-8bf2-0d993082e058?api_key={your-key}
```

Expected: Returns artist images with `artistthumb`, `artistbackground` arrays (if available).

### Coverage Check

Not all artists have images. Check response:

```typescript
const data = await getArtistImages(mbid);
const hasImages = data && (
  data.artistthumb?.length ||
  data.artistbackground?.length ||
  data.musiclogo?.length
);
```

### Last Verified

- **Date**: March 2026
- **Verified by**: API probing and Apiary docs review
