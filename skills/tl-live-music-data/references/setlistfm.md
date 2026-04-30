# Setlist.fm API Reference

**Role**: Historical setlist data — the songs artists played at each show, with venue, tour, and per-song annotations (covers, guests, segues, tape).

This is the deep reference for the Setlist.fm REST API v1.0. Treat this file as the single source of truth for endpoints, parameters, response shapes, headers, limits, and integration patterns. Prefer it over re-fetching the upstream HTML docs.

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://api.setlist.fm/rest/1.0` |
| Auth | API key in `x-api-key` header |
| Rate Limit | **2 req/sec, 1,440 req/day** (per key) |
| Format | JSON (set `Accept: application/json`) — XML also available |
| Localization | `Accept-Language` header (`en`, `es`, `fr`, `de`, `pt`, `tr`, `it`, `pl`) |
| Versioning | Only `/rest/1.0/` is published. No v2. |
| Docs | https://api.setlist.fm/docs/1.0/index.html |
| Swagger UI | https://api.setlist.fm/docs/1.0/ui/index.html |
| Get API Key | https://www.setlist.fm/settings/api |
| Personal vs Commercial | Personal keys free; commercial use requires explicit approval |
| Attribution | **Mandatory** — every artist/venue/city/setlist response includes a `url` you must link back to |

## Authentication

```http
GET /rest/1.0/search/artists?artistName=Phish HTTP/1.1
Host: api.setlist.fm
x-api-key: your-api-key-here
Accept: application/json
Accept-Language: en
User-Agent: YourApp/1.0 (+https://your-site.example)
```

Send a descriptive `User-Agent`. Missing/invalid `x-api-key` → `401`.

## Rate Limits & Etiquette

- **2 req/sec** sustained, **1,440 req/day** per key. `429` on overage. There is **no documented `Retry-After`** — back off with jitter.
- Build clients with a token-bucket limiter at 2 rps and a daily budget cap.
- Retry `429`/`500`/`502`/`503`/`504` with exponential backoff (1s → 60s, max ~6 retries).
- Cache GETs locally; setlists rarely change. Use `lastUpdated` to invalidate.
- For backfills, prefer `/search/setlists?artistMbid=...` paginated cold loads over per-show fetches.

## Endpoints

All paths are relative to `https://api.setlist.fm/rest/1.0`. All endpoints are `GET`.

### Artists

#### `GET /artist/{mbid}`
Single artist by MusicBrainz MBID.

| Param | In | Type | Notes |
|-------|----|------|-------|
| `mbid` | path | string | MusicBrainz UUID |

Returns: [`artist`](#artist) (single object). 404 if unknown.

#### `GET /artist/{mbid}/setlists`
Paginated list of an artist's setlists, sorted by `eventDate` descending. Primary entry point for full-discography backfills.

| Param | In | Type | Default | Notes |
|-------|----|------|---------|-------|
| `mbid` | path | string |  | MusicBrainz UUID |
| `p` | query | int | `1` | Page number (1-indexed) |

Returns: [`setlists`](#setlists) envelope.

#### `GET /search/artists`
Search artists by name, MBID, or (deprecated) TMID.

| Param | In | Type | Default | Notes |
|-------|----|------|---------|-------|
| `artistMbid` | query | string |  | MusicBrainz MBID |
| `artistName` | query | string |  | Substring/fuzzy name search |
| `artistTmid` | query | int |  | Ticketmaster ID (**deprecated**) |
| `p` | query | int | `1` | Page number |
| `sort` | query | string | `sortName` | `sortName` or `relevance` |

Returns: [`artists`](#artists) envelope. Use `relevance` for human queries; `sortName` for alphabetical lists.

### Setlists

#### `GET /setlist/{setlistId}`
Returns the **current** version of a setlist (reflects latest wiki edit).

| Param | In | Type | Notes |
|-------|----|------|-------|
| `setlistId` | path | string | Short hex (e.g. `63de4613`) |

Returns: [`setlist`](#setlist). Compare `versionId` to detect edits.

#### `GET /setlist/version/{versionId}` — **DEPRECATED**
Always returns `404`. Do not call.

#### `GET /search/setlists`
The most flexible endpoint. Combine any of the filters below.

| Param | In | Type | Notes |
|-------|----|------|-------|
| `artistMbid` | query | string | Artist MBID |
| `artistName` | query | string | Artist name |
| `artistTmid` | query | int | Ticketmaster id (**deprecated**) |
| `cityId` | query | string | City `geoId` |
| `cityName` | query | string | City name |
| `countryCode` | query | string | ISO country code (e.g. `US`) |
| `date` | query | string | Event date, **`dd-MM-yyyy`** (not ISO) |
| `lastFm` | query | int | Last.fm Event ID (**deprecated**) |
| `lastUpdated` | query | string | UTC `yyyyMMddHHmmss`. Returns setlists updated on/after this. **Server enforces a hard floor of `2008-09-22T00:00:00Z`** — earlier values return HTTP `400` with body `last modified must not be before 2008-09-22T00:00:00Z, was YYYY-MM-DD`. **Critical for incremental sync.** |
| `p` | query | int | Page (default `1`) |
| `state` | query | string | State name |
| `stateCode` | query | string | State code; combine with `countryCode` for uniqueness |
| `tourName` | query | string | Tour name (e.g. `Summer Tour 2024`) |
| `venueId` | query | string | Venue id |
| `venueName` | query | string | Venue name |
| `year` | query | int | Event year (4-digit) |

Returns: [`setlists`](#setlists) envelope.

Notes:
- `date` is **`dd-MM-yyyy`** — wrong format → `400`.
- `lastUpdated` is the only mechanism for **incremental delta sync** — store the watermark per source.
- When using `lastUpdated` for incremental sync, **clamp the watermark to `>= 20080922000000`**. For pre-2008 history, use `?artistMbid=` + `?year=` chunked pagination instead.
- `artistMbid` + `year` cleanly chunks a large artist's history.

### Venues

#### `GET /venue/{venueId}`
Single venue.

| Param | In | Type | Notes |
|-------|----|------|-------|
| `venueId` | path | string | Short hex (e.g. `6bd6ca6e`) |

Returns: [`venue`](#venue).

#### `GET /venue/{venueId}/setlists`
Paginated setlists for a venue.

| Param | In | Type | Default |
|-------|----|------|---------|
| `venueId` | path | string |  |
| `p` | query | int | `1` |

Returns: [`setlists`](#setlists) envelope.

#### `GET /search/venues`
Search venues.

| Param | In | Type | Notes |
|-------|----|------|-------|
| `cityId` | query | string | City `geoId` |
| `cityName` | query | string | City name |
| `country` | query | string | Country (name or code; prefer `cityId` when known) |
| `name` | query | string | Venue name |
| `p` | query | int | Page (default `1`) |
| `state` | query | string | State name |
| `stateCode` | query | string | State code |

Returns: [`venues`](#venues) envelope.

### Geo

#### `GET /city/{geoId}`
Single city by Geonames-derived `geoId`.

| Param | In | Type |
|-------|----|------|
| `geoId` | path | string (numeric) |

Returns: [`city`](#city).

#### `GET /search/cities`
Search cities.

| Param | In | Type | Notes |
|-------|----|------|-------|
| `country` | query | string | Country |
| `name` | query | string | City name |
| `p` | query | int | Page (default `1`) |
| `state` | query | string | State name |
| `stateCode` | query | string | State code |

Returns: envelope with `cities[]`. **Note: array key is `cities`, not `city`** — unique among list endpoints.

#### `GET /search/countries`
Full list of supported countries. No query params.

Returns: envelope with `country[]`. Useful as a one-time bootstrap for normalized country tables.

### Users

The `fullname`, `lastFm`, `mySpace`, `twitter`, `flickr`, `website`, `about` fields on the `user` type are all **deprecated and never set**. Treat user data as effectively `{ userId, url }`.

#### `GET /user/{userId}` — **DEPRECATED**
Always returns a result, even if the user doesn't exist. Do not rely on it for existence checks.

| Param | In | Type |
|-------|----|------|
| `userId` | path | string |

Returns: [`user`](#user).

#### `GET /user/{userId}/attended`
Setlists for shows a user marked as attended.

| Param | In | Type | Default |
|-------|----|------|---------|
| `userId` | path | string |  |
| `p` | query | int | `1` |

Returns: [`setlists`](#setlists) envelope.

#### `GET /user/{userId}/edited`
Setlists a user has edited (returns current version, not the user's edit).

| Param | In | Type | Default |
|-------|----|------|---------|
| `userId` | path | string |  |
| `p` | query | int | `1` |

Returns: [`setlists`](#setlists) envelope.

## Pagination Model

All list endpoints share the same envelope shape:

```json
{
  "<itemKey>": [ /* items */ ],
  "total": 1234,
  "page": 1,
  "itemsPerPage": 20
}
```

- `<itemKey>` is the singular form: `artist`, `venue`, `setlist`, `country`. **Exception: `/search/cities` uses `cities`.**
- `itemsPerPage` is **server-controlled** and varies per endpoint (commonly 20 or 30). Always read it from the response — do not assume.
- Pagination uses `?p=<n>` (1-indexed). There is **no per-page size parameter**.
- `total` is authoritative — compute `pages = ceil(total / itemsPerPage)`.
- Pages can shift mid-crawl as wiki data is edited. For consistent backfills, capture `total` at the start, walk pages, and dedupe by `id` (setlists) or `mbid` (artists).

## Response Schemas

### artist
| Field | Type | Notes |
|-------|------|-------|
| `mbid` | string | MusicBrainz UUID. Stable primary key. |
| `tmid` | number | Ticketmaster id. **Deprecated**. |
| `name` | string | Display name. |
| `sortName` | string | Sort form (e.g. `Beatles, The`). |
| `disambiguation` | string | Distinguishes artists with same name. |
| `url` | string | Attribution URL. **Required for display.** |

```json
{
  "mbid": "e01646f2-2a04-450d-8bf2-0d993082e058",
  "name": "Phish",
  "sortName": "Phish",
  "disambiguation": "American rock band formed in Burlington, Vermont, in 1983",
  "url": "https://www.setlist.fm/setlists/phish-13d6ad51.html"
}
```

### artists
Envelope: `{ "artist": artist[], "total", "page", "itemsPerPage" }`.

### setlist
| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Setlist identity (stable across edits). |
| `versionId` | string | Version identity (changes on every edit). Use to detect changes. |
| `eventDate` | string | **`dd-MM-yyyy`** (not ISO). Convert before storing. |
| `lastUpdated` | string | ISO-ish: `yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ`. |
| `info` | string | Free-text concert notes ([guidelines](https://www.setlist.fm/guidelines)). |
| `url` | string | Canonical attribution URL. |
| `artist` | [`artist`](#artist) | Performing artist. |
| `venue` | [`venue`](#venue) | Venue (may be sparse if unknown). |
| `tour` | [`tour`](#tour) | Optional; absent on ~15-20% of shows (festivals, one-offs, pre-tour-naming dates). |
| `sets` | object | Wrapper containing a single `set[]` array — see below. |
| `sets.set` | [`set[]`](#set) | One or more sets, in performance order. **Songs nest under `setlist.sets.set[]` — the wrapping `sets` object is canonical.** Tolerant readers should still accept a top-level `setlist.set[]` if it ever appears, but no live response uses that shape today. May be `[]` for announced-but-unplayed shows. |
| `lastFmEventId` | number | **Deprecated**. |

```json
{
  "id": "63de4613",
  "versionId": "7be1aaa0",
  "eventDate": "23-08-1964",
  "lastUpdated": "2013-10-20T05:18:08.000+0000",
  "info": "Recorded and published as 'The Beatles at the Hollywood Bowl'",
  "url": "https://www.setlist.fm/setlist/the-beatles/1964/hollywood-bowl-hollywood-ca-63de4613.html",
  "artist": {
    "mbid": "b10bbbfc-cf9e-42e0-be17-e2c3e1d2600d",
    "name": "The Beatles",
    "sortName": "Beatles, The",
    "disambiguation": "John, Paul, George and Ringo",
    "url": "https://www.setlist.fm/setlists/the-beatles-23d6a88b.html"
  },
  "venue": {
    "id": "6bd6ca6e",
    "name": "Hollywood Bowl",
    "url": "https://www.setlist.fm/venue/...",
    "city": {
      "id": "5357527",
      "name": "Hollywood",
      "stateCode": "CA",
      "state": "California",
      "coords": { "lat": 34.0983425, "long": -118.3267434 },
      "country": { "code": "US", "name": "United States" }
    }
  },
  "tour": { "name": "North American Tour 1964" },
  "sets": {
    "set": [
      {
        "name": "Main Set",
        "song": [
          { "name": "Yesterday" },
          { "name": "Twist and Shout", "cover": { "mbid": "...", "name": "The Top Notes" } }
        ]
      },
      {
        "encore": 1,
        "song": [
          { "name": "Long Tall Sally", "with": { "mbid": "...", "name": "Guest" } }
        ]
      }
    ]
  }
}
```

#### Response states

A returned setlist is always envelope-shaped the same way, but its content lives in one of three states. Ingestion code must distinguish these or it will mis-classify legitimate responses as bugs.

| State | Trigger | `sets.set[]` | `eventDate` | Typical handling |
|---|---|---|---|---|
| Fully populated | Played show, wiki edited | Non-empty, songs present | Past | Ingest normally. |
| Skeletal | Played show, wiki not yet edited | Empty `[]`, OR a single set with empty `song[]` | Past | Ingest with `setlistKnown=false`; refetch later when `versionId` advances. |
| Announced-only | Future tour date entered ahead of show | Empty `[]` | Future | Ingest as placeholder OR drop, depending on whether the consumer surfaces upcoming shows. |

For an active touring artist, expect 5–10% of returned records to be in the announced-only state at any point in time.

#### Field-presence reality

The schema is fixed but field presence varies widely by artist and by show vintage. The ranges below are the practical bounds observed across multi-artist live probes; design ingestion against the low end of each range.

| Field | Typical presence | Notes |
|---|---|---|
| `setlist.tour` | 80–95% | Festival, one-off, and pre-tour-naming shows lack it. |
| `setlist.info` | 5–25% | Free-text concert notes; expect sparsity. |
| `artist.disambiguation` | 0–100% | Always present for popular artists; absent for some side-projects. |
| `venue.city.coords` | 95–100% | Sparse only for very obscure or just-added venues. |
| `song.cover` | 20–90% | Wildly artist-dependent; cover-heavy projects approach 90%. |
| `song.with` (guests) | 0–10% | Typically <2% for primary acts; higher for jam-band side projects. |
| `song.info` | 5–35% | Per-song annotations (segues, teases, jams). |
| `song.tape` | <0.1% | Very rare; intermission tapes only. |

### setlists
Envelope: `{ "setlist": setlist[], "total", "page", "itemsPerPage" }`. Each item in `setlist[]` nests its songs under `sets.set[]`.

### set
Members of `setlist.sets.set[]`. A "set" is a contiguous group of songs (main set, second set, encore).

| Field | Type | Notes |
|-------|------|-------|
| `name` | string | Optional set label (e.g. `Acoustic set`). |
| `encore` | number | If present, encore index (1-based). Absent = main set. |
| `song` | [`song[]`](#song) | Songs in performance order. |

### song
| Field | Type | Notes |
|-------|------|-------|
| `name` | string | Song title. |
| `with` | [`artist`](#artist) | Guest joining for this song. |
| `cover` | [`artist`](#artist) | Original artist if this is a cover. |
| `info` | string | Per-song annotation (transitions, jam tags, teases). For Phish-style content, expect `>`, `->`, `tease`, `jam`, etc. |
| `tape` | boolean | True = pre-recorded tape, not live performance. |

### tour
| Field | Type | Notes |
|-------|------|-------|
| `name` | string | Tour name (e.g. `Summer Tour 2024`). |

### venue
| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Stable venue id (short hex). |
| `name` | string | Venue name (without city/country). |
| `url` | string | Attribution URL. |
| `city` | [`city`](#city) | Optional; may be empty for sparsely-recorded venues. |

### venues
Envelope: `{ "venue": venue[], "total", "page", "itemsPerPage" }`.

### city
| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Geonames `geoId`. |
| `name` | string | Localized name. |
| `state` | string | State name. |
| `stateCode` | string | Combine with country code for uniqueness (e.g. `US.CA`). |
| `coords` | [`coords`](#coords) | Lat/long. |
| `country` | [`country`](#country) | Country. |

### cities
Envelope: `{ "cities": city[], "total", "page", "itemsPerPage" }`. **Array key is `cities`, not `city`.**

### country
| Field | Type | Notes |
|-------|------|-------|
| `code` | string | ISO code (e.g. `US`, `IE`). |
| `name` | string | Localized country name. |

### countries
Envelope: `{ "country": country[], "total", "page", "itemsPerPage" }`.

### coords
| Field | Type | Notes |
|-------|------|-------|
| `lat` | number | Latitude. |
| `long` | number | Longitude. **Field is `long`, not `lng`** — easy footgun. |

### user
| Field | Type | Notes |
|-------|------|-------|
| `userId` | string | User identifier. |
| `url` | string | Attribution URL. |
| `fullname`, `lastFm`, `mySpace`, `twitter`, `flickr`, `website`, `about` | string | All **deprecated and never set**. |

### error
| Field | Type | Notes |
|-------|------|-------|
| `code` | number | HTTP status code. |
| `status` | string | HTTP status message. |
| `message` | string | Human-readable detail. |
| `timestamp` | string | Server timestamp. |

```json
{
  "code": 404,
  "status": "Not Found",
  "message": "unknown mbid",
  "timestamp": "2016-12-08T17:52:48.817+0000"
}
```

## Error Model

| HTTP | Meaning | Handling |
|------|---------|----------|
| `400` | Bad Request — malformed params (e.g. bad `date` format) | Fix params; do not retry. |
| `401` | Unauthorized — missing/invalid `x-api-key` | Surface loudly; do not retry. |
| `403` | Forbidden — key not licensed for the requested action | Escalate to setlist.fm. |
| `404` | Not Found — unknown id/mbid OR deprecated endpoint | Treat as a hard miss; cache the negative. Normal for artists with no setlists. |
| `429` | Too Many Requests | Backoff + retry. |
| `5xx` | Upstream error | Backoff + retry. |

## Date & Time Formats (Read Carefully)

| Field / Param | Format | Example |
|---------------|--------|---------|
| `setlist.eventDate` | `dd-MM-yyyy` | `23-08-1964` |
| `setlist.lastUpdated` | `yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ` | `2013-10-20T05:18:08.000+0000` |
| `?date=` (search query) | `dd-MM-yyyy` | `?date=31-12-2023` |
| `?lastUpdated=` (search query) | `yyyyMMddHHmmss` (UTC, no separators) | `?lastUpdated=20260429213000` |

Always parse `eventDate` explicitly — never hand it to `Date.parse`. Store as ISO `yyyy-MM-dd` internally.

## Common Gotchas

1. **Songs nest under a wrapping `sets` object.** Read `setlist.sets.set[]`. Older docs and third-party examples sometimes show `setlist.set[]` directly — that shape is **not** what the API returns today. Tolerant readers can fall back to a top-level `set[]` if it ever surfaces, but never write code that assumes it.
2. **`?date=` uses `dd-MM-yyyy`**, not ISO. Wrong format → `400`.
3. **`coords.long`, not `lng`** — easy to typo and silently get `undefined`.
4. **`/search/cities` envelope key is `cities`** (plural), unique among list endpoints. All other list endpoints use the singular form.
5. **`/setlist/version/{versionId}` is deprecated** and always returns `404`. Use `/setlist/{id}` and compare `versionId` instead.
6. **`/user/{userId}` always returns a body** even for non-existent users. Don't use it for existence checks.
7. **Wiki-style editing** means setlists mutate. Compare `versionId` to detect changes; use `lastUpdated` watermarks for incremental sync.
8. **`itemsPerPage` is server-controlled** and varies (20 or 30 typical). Don't assume 20.
9. **Attribution is mandatory** — every consumer-facing surface must link back to the response's `url`.
10. **Hammering past 2 rps** burns through the daily 1,440 budget fast — throttle proactively.
11. **`?lastUpdated=` has a hard server floor of `2008-09-22T00:00:00Z`.** Earlier values return `400`. Clamp your watermark before sending.
12. **Empty `sets.set[]` is normal**, not a bug. Treat such records as announced-but-unplayed shows (future `eventDate`) or skeletal placeholders awaiting wiki edit (past `eventDate`). See [Response states](#response-states).

## Caching Recommendations

| Data | TTL |
|------|-----|
| Artist info | 7 days |
| Recent setlists (< 30 days old) | 4 hours |
| Historical setlists (> 30 days old) | 30 days |
| Venue / city / country info | 30 days |
| Negative lookups (404 by mbid/id) | 7 days |

Invalidate sooner if you detect a `versionId` change on `/setlist/{id}`.

## Backfill & Incremental Sync Strategy

Recommended pattern for large-artist histories (e.g. Phish, Grateful Dead, Dead & Company):

1. **Bootstrap**: `GET /artist/{mbid}/setlists?p=1`. Read `total` and `itemsPerPage`. Compute total pages.
2. **Cold backfill**: Walk pages 1..N at ≤ 2 rps with backoff. Persist raw JSON per setlist keyed by `id` + `versionId`.
3. **Dedupe**: Within a single crawl, dedupe by `id` (keep the highest `versionId`).
4. **Watermark**: Store the maximum `lastUpdated` seen. This is your sync watermark. Clamp the value sent on the wire to `max(observed_lastUpdated, 20080922000000)` — see Gotcha #11.
5. **Incremental**: `GET /search/setlists?artistMbid={mbid}&lastUpdated={watermarkYYYYMMDDHHMMSS}&p=1..N`. Repeat daily. Newly-announced future shows surface here as soon as the wiki gets them, with empty `sets.set[]` — see [Response states](#response-states).
6. **On-demand refresh**: `GET /setlist/{id}` and compare `versionId` for known shows you suspect have changed.
7. **Announced-show handling**: decide policy up front. Either (a) drop records where `sets.set.length === 0` and `eventDate` is future, or (b) ingest them as placeholders with a `setlistKnown=false` marker so the UI can show "TBD" until the show is played and the wiki is updated. Re-fetch placeholders on the next watermark cycle and check for `versionId` advancement.

Daily budget math: 1,440 reqs/day. A 2,000-show artist at 20/page = ~100 pages = trivially within one day's budget for cold backfills. Reserve at least 25% of the daily budget for incremental + on-demand traffic.

## Environment Variables

```bash
SETLISTFM_API_KEY=""
SETLISTFM_BASE_URL="https://api.setlist.fm/rest/1.0"   # optional override
SETLISTFM_USER_AGENT="YourApp/1.0 (+https://example.com)"   # optional
SETLISTFM_ACCEPT_LANGUAGE="en"   # optional
```

## Examples

### Get an artist's most recent setlists

```typescript
const mbid = 'e01646f2-2a04-450d-8bf2-0d993082e058'; // Phish

const response = await fetch(
  `https://api.setlist.fm/rest/1.0/artist/${mbid}/setlists?p=1`,
  {
    headers: {
      Accept: 'application/json',
      'x-api-key': process.env.SETLISTFM_API_KEY!,
      'Accept-Language': 'en',
      'User-Agent': 'YourApp/1.0 (+https://example.com)',
    },
  }
);

const data = await response.json();
// data.setlist[] contains recent shows; each item nests songs under sets.set[]
// data.total / data.itemsPerPage drive pagination
```

### Search by date

```typescript
// dd-MM-yyyy — NOT ISO
const response = await fetch(
  `https://api.setlist.fm/rest/1.0/search/setlists?date=31-12-2023&p=1`,
  { headers: { Accept: 'application/json', 'x-api-key': process.env.SETLISTFM_API_KEY! } }
);
```

### Incremental sync since watermark

```typescript
// Watermark format: yyyyMMddHHmmss (UTC, no separators).
// Server enforces a hard floor of 2008-09-22T00:00:00Z — clamp before sending.
const FLOOR = '20080922000000';
const stored = '20260429213000';
const watermark = stored < FLOOR ? FLOOR : stored;
const mbid = 'e01646f2-2a04-450d-8bf2-0d993082e058';

const response = await fetch(
  `https://api.setlist.fm/rest/1.0/search/setlists?artistMbid=${mbid}&lastUpdated=${watermark}&p=1`,
  { headers: { Accept: 'application/json', 'x-api-key': process.env.SETLISTFM_API_KEY! } }
);
```

### Detect a setlist edit using `versionId`

`setlist.id` is immutable; `setlist.versionId` advances on every wiki edit. Compare against your stored copy to decide whether to invalidate downstream caches without doing a deep diff.

```typescript
async function refreshIfChanged(setlistId: string, storedVersionId: string) {
  const res = await fetch(
    `https://api.setlist.fm/rest/1.0/setlist/${setlistId}`,
    {
      headers: {
        Accept: 'application/json',
        'x-api-key': process.env.SETLISTFM_API_KEY!,
      },
    },
  );
  if (res.status === 404) return { changed: false, gone: true } as const;
  if (!res.ok) throw new Error(`setlist.fm ${res.status}`);

  const setlist = await res.json();
  if (setlist.versionId === storedVersionId) {
    return { changed: false, setlist } as const;
  }
  return { changed: true, setlist } as const;
  // Caller persists setlist (including new versionId) and invalidates derived caches.
}
```

## Quick Reference Cheat Sheet

```
BASE   https://api.setlist.fm/rest/1.0
AUTH   x-api-key: $SETLISTFM_API_KEY
ACCEPT application/json
RATE   2 rps, 1440/day

ARTISTS
  GET /artist/{mbid}
  GET /artist/{mbid}/setlists?p=
  GET /search/artists?artistMbid|artistName|artistTmid&sort=sortName|relevance&p=

SETLISTS
  GET /setlist/{setlistId}                                # songs at setlist.sets.set[]
  GET /search/setlists?artistMbid|artistName|cityId|cityName|countryCode
                      |date(dd-MM-yyyy)|lastUpdated(yyyyMMddHHmmss)
                      |state|stateCode|tourName|venueId|venueName|year&p=
                      # lastUpdated must be >= 20080922000000

VENUES
  GET /venue/{venueId}
  GET /venue/{venueId}/setlists?p=
  GET /search/venues?cityId|cityName|country|name|state|stateCode&p=

GEO
  GET /city/{geoId}
  GET /search/cities?country|name|state|stateCode&p=     # array key: "cities"
  GET /search/countries

USERS (mostly deprecated)
  GET /user/{userId}                 [deprecated, always 200]
  GET /user/{userId}/attended?p=
  GET /user/{userId}/edited?p=

DEPRECATED
  GET /setlist/version/{versionId}   [always 404]
```

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

Current version is `1.0`. If URL structure changes (e.g. `/rest/2.0`), major update occurred.

### Test Endpoint

```http
GET https://api.setlist.fm/rest/1.0/artist/e01646f2-2a04-450d-8bf2-0d993082e058
Headers: Accept: application/json, x-api-key: {your-key}
```

Expected: `200` with an `artist` object.

### Last Verified

- **Date**: April 2026
- **Verification scope**: Multi-artist live API probe (full-discography artist walk + cross-artist sanity sample + setlist detail refetch + `lastUpdated` watermark probe), totaling ~150 requests; all schema claims, sparsity ranges, and the `2008-09-22` `lastUpdated` floor confirmed against live responses.
