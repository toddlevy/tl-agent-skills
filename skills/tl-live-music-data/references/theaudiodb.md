# TheAudioDB API Reference

**Role**: Artist and album metadata with images - alternative to Fanart.tv

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL (v1) | `https://www.theaudiodb.com/api/v1/json/{apikey}` |
| Base URL (v2) | `https://www.theaudiodb.com/api/v2/json` |
| Auth | API key in URL (v1) or header (v2) |
| Rate Limit | 2 req/sec (free tier) |
| Format | JSON |
| Docs | https://www.theaudiodb.com/api_guide.php |
| Free Key | `"2"` (limited features) |
| Premium | $8/month |

## Authentication

### Free Tier (v1)

Use API key `"2"` in URL path:

```http
GET https://www.theaudiodb.com/api/v1/json/2/search.php?s=coldplay
```

### Premium Tier (v2)

Use header authentication:

```http
GET https://www.theaudiodb.com/api/v2/json/search.php?s=coldplay
X-API-KEY: your-premium-key
```

## Free vs Premium Features

| Feature | Free (key="2") | Premium |
|---------|----------------|---------|
| Artist search by name | ✅ | ✅ |
| Album search | ✅ | ✅ |
| Track search | ✅ | ✅ |
| Lookup by TADB ID | ✅ | ✅ |
| Lookup by MBID | ❌ | ✅ |
| High-res images | Limited | ✅ |
| Rate limit | 2/sec | Higher |
| v2 API | ❌ | ✅ |

## Search Endpoints

### Search Artist by Name

```http
GET /search.php?s={artist_name}
```

**Response**:
```json
{
  "artists": [{
    "idArtist": "111239",
    "strArtist": "Phish",
    "strArtistStripped": "Phish",
    "strArtistAlternate": "",
    "strLabel": "Elektra Records",
    "idLabel": "45114",
    "intFormedYear": "1983",
    "intBornYear": null,
    "intDiedYear": null,
    "strDisbanded": null,
    "strStyle": "Jam",
    "strGenre": "Rock",
    "strMood": "Happy",
    "strWebsite": "www.phish.com",
    "strFacebook": "www.facebook.com/phish",
    "strTwitter": "www.twitter.com/phaborant",
    "strBiographyEN": "Phish is an American rock band...",
    "strBiographyDE": "...",
    "strBiographyFR": "...",
    "strGender": "Male",
    "intMembers": "4",
    "strCountry": "Burlington, Vermont, USA",
    "strCountryCode": "US",
    "strArtistThumb": "https://www.theaudiodb.com/images/media/artist/thumb/...",
    "strArtistLogo": "https://www.theaudiodb.com/images/media/artist/logo/...",
    "strArtistClearart": null,
    "strArtistWideThumb": "https://www.theaudiodb.com/images/media/artist/widethumb/...",
    "strArtistFanart": "https://www.theaudiodb.com/images/media/artist/fanart/...",
    "strArtistFanart2": "...",
    "strArtistFanart3": "...",
    "strArtistFanart4": null,
    "strArtistBanner": "https://www.theaudiodb.com/images/media/artist/banner/...",
    "strMusicBrainzID": "e01646f2-2a04-450d-8bf2-0d993082e058",
    "strLastFMChart": "...",
    "intCharted": "3",
    "strLocked": "unlocked"
  }]
}
```

### Search Album

```http
GET /searchalbum.php?s={artist}&a={album}
```

### Search Track

```http
GET /searchtrack.php?s={artist}&t={track}
```

### Search All Tracks (by artist)

```http
GET /searchtrack.php?s={artist}
```

## Lookup Endpoints

### Artist by TheAudioDB ID

```http
GET /artist.php?i={tadb_artist_id}
```

### Artist by MusicBrainz ID (Premium Only)

```http
GET /artist-mb.php?i={mbid}
```

### Albums by Artist ID

```http
GET /album.php?i={tadb_artist_id}
```

### Album by TheAudioDB Album ID

```http
GET /album.php?m={tadb_album_id}
```

### Tracks on Album

```http
GET /track.php?m={tadb_album_id}
```

### Track by ID

```http
GET /track.php?h={tadb_track_id}
```

### Artist Discography

```http
GET /discography.php?s={artist_name}
```

### Music Videos

```http
GET /mvid.php?i={tadb_artist_id}
```

### Top 10 Tracks

```http
GET /track-top10.php?s={artist_name}
```

## Image Fields

### Artist Images

| Field | Description |
|-------|-------------|
| `strArtistThumb` | Square thumbnail |
| `strArtistLogo` | Logo (transparent) |
| `strArtistClearart` | Clearart |
| `strArtistWideThumb` | Wide thumbnail |
| `strArtistFanart` | Fanart background 1 |
| `strArtistFanart2` | Fanart background 2 |
| `strArtistFanart3` | Fanart background 3 |
| `strArtistFanart4` | Fanart background 4 |
| `strArtistBanner` | Banner |

### Album Images

| Field | Description |
|-------|-------------|
| `strAlbumThumb` | Album cover |
| `strAlbumThumbHQ` | HQ album cover |
| `strAlbumThumbBack` | Back cover |
| `strAlbumCDart` | CD art |
| `strAlbumSpine` | Spine art |
| `strAlbum3DCase` | 3D case render |
| `strAlbum3DFlat` | 3D flat render |
| `strAlbum3DFace` | 3D face render |
| `strAlbum3DThumb` | 3D thumbnail |

## Biography Languages

Biographies are available in multiple languages:

```
strBiographyEN - English
strBiographyDE - German
strBiographyFR - French
strBiographyIT - Italian
strBiographyES - Spanish
strBiographyPT - Portuguese
strBiographyJP - Japanese
strBiographyCN - Chinese
strBiographyRU - Russian
strBiographyHU - Hungarian
strBiographyNL - Dutch
strBiographyPL - Polish
strBiographySE - Swedish
strBiographyNO - Norwegian
```

## TypeScript Implementation

```typescript
interface TADBArtist {
  idArtist: string;
  strArtist: string;
  strGenre: string;
  strStyle: string;
  strCountry: string;
  strBiographyEN: string;
  strMusicBrainzID: string;
  strArtistThumb: string | null;
  strArtistLogo: string | null;
  strArtistFanart: string | null;
  strArtistBanner: string | null;
}

interface TADBAlbum {
  idAlbum: string;
  idArtist: string;
  strAlbum: string;
  strArtist: string;
  intYearReleased: string;
  strAlbumThumb: string | null;
  strAlbumThumbHQ: string | null;
  strMusicBrainzID: string;
}

const API_KEY = process.env.THEAUDIODB_API_KEY || '2';
const BASE_URL = `https://www.theaudiodb.com/api/v1/json/${API_KEY}`;

// Rate limiting
const TADB_DELAY = 500; // 2 req/sec = 500ms between
let lastRequest = 0;

async function tadbFetch<T>(endpoint: string): Promise<T> {
  const now = Date.now();
  const wait = Math.max(0, TADB_DELAY - (now - lastRequest));
  if (wait > 0) await sleep(wait);
  
  lastRequest = Date.now();
  
  const response = await fetch(`${BASE_URL}${endpoint}`);
  return response.json();
}

async function searchArtist(name: string): Promise<TADBArtist | null> {
  const data = await tadbFetch<{ artists: TADBArtist[] | null }>(
    `/search.php?s=${encodeURIComponent(name)}`
  );
  return data.artists?.[0] || null;
}

async function getArtistById(id: string): Promise<TADBArtist | null> {
  const data = await tadbFetch<{ artists: TADBArtist[] | null }>(
    `/artist.php?i=${id}`
  );
  return data.artists?.[0] || null;
}

async function getArtistAlbums(artistId: string): Promise<TADBAlbum[]> {
  const data = await tadbFetch<{ album: TADBAlbum[] | null }>(
    `/album.php?i=${artistId}`
  );
  return data.album || [];
}
```

## Rate Limiting

Free tier: 2 requests/second

```typescript
const TADB_DELAY = 500;
let lastRequest = 0;

async function rateLimitedFetch(url: string): Promise<Response> {
  const now = Date.now();
  const wait = Math.max(0, TADB_DELAY - (now - lastRequest));
  if (wait > 0) await new Promise(r => setTimeout(r, wait));
  
  lastRequest = Date.now();
  return fetch(url);
}
```

## ID Resolution

### TheAudioDB → MusicBrainz

Response includes `strMusicBrainzID`:

```typescript
const artist = await searchArtist('Phish');
const mbid = artist?.strMusicBrainzID;
// "e01646f2-2a04-450d-8bf2-0d993082e058"
```

### MusicBrainz → TheAudioDB (Premium Only)

```http
GET /artist-mb.php?i=e01646f2-2a04-450d-8bf2-0d993082e058
```

## Common Gotchas

1. **MBID lookup is premium** - Free tier cannot lookup by MBID
2. **Rate limit** - 2 req/sec on free tier, enforce delays
3. **Null images** - Many fields can be null, check before using
4. **String numbers** - IDs and years are strings
5. **Empty arrays** - `null` instead of `[]` for no results

## Error Handling

No results return `null` for the array:

```json
{
  "artists": null
}
```

Check for null before accessing:

```typescript
const data = await tadbFetch<{ artists: TADBArtist[] | null }>('/search.php?s=xyznotfound');
if (!data.artists) {
  // No results
}
```

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist info | 7 days |
| Album info | 30 days |
| Track info | 30 days |
| Images | 30 days |
| Discography | 7 days |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| API Guide | https://www.theaudiodb.com/api_guide.php |
| Free API Info | https://www.theaudiodb.com/free_music_api |
| Premium Info | https://www.theaudiodb.com/premium |
| Main Site | https://www.theaudiodb.com |

### Version Detection

Two API versions exist:

- **v1**: `https://www.theaudiodb.com/api/v1/json/{apikey}/...`
- **v2**: `https://www.theaudiodb.com/api/v2/json/...` (header auth, premium only)

Monitor:
1. **API guide page** - Check for new endpoints
2. **Response fields** - New metadata fields added over time
3. **Premium features** - MBID lookup currently premium-only

### Test Endpoint

Verify API is responding (free tier):

```http
GET https://www.theaudiodb.com/api/v1/json/2/search.php?s=Phish
```

Expected: Returns `artists` array with artist object containing `strArtist`, `idArtist` fields.

### Free vs Premium Changes

Premium features (currently $8/mo):
- MBID direct lookup (`artist-mb.php`)
- Higher rate limits
- v2 API access
- High-res images

### Last Verified

- **Date**: March 2026
- **Verified by**: API probing and documentation review
