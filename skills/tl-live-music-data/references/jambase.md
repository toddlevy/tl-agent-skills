# JamBase Data API v3 Reference

**Role**: The most comprehensive live music data API — concerts, festivals, livestreams, artists, venues, and geographies — with normalized cross-platform IDs across 15+ ticketing and music sources.

## Quick Facts

| Property | Value |
|----------|-------|
| Base URL | `https://api.jambase.com/v3` |
| Version | `v3.0.0` (released Mar 5, 2026) |
| Auth | Bearer token (HTTP `Authorization` header) |
| Format | JSON (Schema.org-compatible types) |
| OpenAPI | 3.1 — [`https://data.jambase.com/openapi.json`](https://data.jambase.com/openapi.json) |
| LLM reference | [`https://data.jambase.com/llms-full.txt`](https://data.jambase.com/llms-full.txt) |
| Plugin manifest | [`https://data.jambase.com/.well-known/ai-plugin.json`](https://data.jambase.com/.well-known/ai-plugin.json) |
| Rate-limit headers | IETF `RateLimit-Policy` + `RateLimit` (hour and minute windows) |
| Endpoints | 17 across 7 categories |
| Contact | `developer@jambase.com` |
| Account / keys | `https://data.jambase.com` |

### Coverage

- 500,000+ artists
- 170,000+ venues
- 5M+ historical performances
- 25+ years of continuous data (since 1999)
- 60+ upstream data feeds (Ticketmaster, AXS, DICE, Eventbrite, SeatGeek, See Tickets, Sofar Sounds, Tixr, viagogo, etc.); v3 currently surfaces ~17 distinct slugs across events/artists/venues/streams as cross-platform IDs

---

## Authentication

All requests use a Bearer token in the `Authorization` header. There is no query-string fallback.

```http
GET /v3/genres HTTP/1.1
Host: api.jambase.com
Authorization: Bearer YOUR_API_KEY
```

Get your key from your account dashboard at [`https://data.jambase.com`](https://data.jambase.com).

---

## Plans, Quotas, and Tier-Gated Features

| Plan | Per-hour | Per-minute (RPM) | Monthly | Key gated features |
|------|---------:|-----------------:|--------:|--------------------|
| **Trial** (free, 14 days) | 3,600 | — | 1,000 total | All features unlocked for evaluation; 1-year historical window; not for commercial use |
| **Developer** (free) | 3,600 | 10 | 1,000 | Future events ≤ 6 months; **no** external IDs, ticket pricing, or capacity; attribution required |
| **Startup** ($600/mo) | 7,200 | 50 | 20,000 | All future events; external IDs (Spotify, MusicBrainz, Ticketmaster); ticket pricing; venue capacity |
| **Pro** ($1,800/mo) | 18,000 | 250 | 50,000 | Door times, street addresses, geo coordinates; 48-hr support SLA; data feeds + MCP add-ons |
| **Pro+** ($3,000/mo) | 36,000 | 500 | 150,000 | Historical archive (per artist/venue); historical ticket pricing; 24-hr SLA; whitelisted attribution |
| **Enterprise** | 120,000+ | custom | unlimited | Unlimited historical access; dedicated AM; custom SLA; data feeds included |

> **Quota note**: `llms-full.txt` (the dated v3 spec) and `ai-plugin.json` disagree on Startup/Pro/Pro+ monthly caps. The values above follow `llms-full.txt` because it is versioned and dated to the v3.0.0 release. The plugin manifest reports lower caps (Startup 3k / Pro 15k / Pro+ 50k) — verify against the live `/pricing` page if quota matters operationally.

Overage pricing is per-call ($0.05 Dev → $0.02 Pro+) and billed monthly. Free tiers also enforce attribution requirements.

---

## Rate-Limit Headers (IETF draft)

Every response carries machine-readable rate-limit headers per [`draft-ietf-httpapi-ratelimit-headers`](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-ratelimit-headers):

```http
RateLimit-Policy: hour;q=18000;w=3600, minute;q=250;w=60
RateLimit:        hour;r=17999;t=1,    minute;r=249;t=1
```

- `q` = quota for the window
- `r` = remaining requests
- `t` = seconds until the window resets
- `w` = window size in seconds

When throttled, the API returns **HTTP 429** with a `Retry-After` header (seconds). Honor it with exponential back-off — see the client wrapper below.

---

## Response Envelope

Every successful response shares the same shape:

```json
{
  "success": true,
  "pagination": { "page": 1, "perPage": 40, "totalItems": 1250, "totalPages": 32 },
  "events":     [/* ... */],
  "request":    { "url": "/v3/events?geoStateIso=US-NY&perPage=40" }
}
```

The payload key (`events`, `artists`, `venues`, `cities`, `metros`, `states`, `countries`, `genres`, `dataSources`, `ticketVendors`) varies by endpoint. Single-item endpoints return `event`, `artist`, or `venue` (singular).

### Error envelope

Per the OpenAPI `BadRequest` schema, error payloads return a plural `errors` array of structured items:

```json
{
  "success": false,
  "errors": [
    {
      "errorCode": "parameter_invalid",
      "errorMessage": "Description of what went wrong"
    }
  ]
}
```

`llms-full.txt` documents an alternate singular shape (`error: { code, message }`). The TypeScript client below defends against both. See the Spec Inconsistencies appendix.

#### `errorCode` values

| Code | Meaning |
|------|---------|
| `no_lookup_results` | Query returned no matches |
| `lookup_error` | Internal lookup failure |
| `parameter_missing` | A required query/path param is absent |
| `parameter_invalid` | A param has the wrong type or value |
| `parameter_out_of_range` | A param is outside accepted bounds (e.g. `perPage` > 100) |
| `identifier_missing` | A `{source}:{id}` slug is incomplete |
| `identifier_invalid` | The `{source}:{id}` slug is malformed |
| `general_error` | Catch-all for unclassified errors |

| HTTP | Meaning | Action |
|------|---------|--------|
| 400 | Bad Request — missing/invalid params | Fix params; do not retry |
| 401 | Missing/invalid API key | Fix auth; do not retry |
| 403 | Feature not available on your plan | Upgrade or remove the gated `expand*` flag |
| 404 | Not Found | Check the `{source}:{id}` slug |
| 429 | Rate limited | Honor `Retry-After`; exponential back-off |
| 500 | Internal Server Error | Retry with jittered back-off (max 3) |

---

## Pagination

| Param | Default | Max |
|-------|--------:|----:|
| `page` | 1 | — |
| `perPage` | 40 | 100 |

The `pagination` block also returns `nextPage` and `previousPage` URLs when applicable — prefer those over recomputing `page+1` so you inherit any server-side cursor changes. The OpenAPI spec types both as `format: url` but does not pin whether they are absolute (e.g. `https://api.jambase.com/v3/events?page=2`) or path-relative (`/v3/events?page=2`); handle both shapes defensively.

---

## Common Query Parameters

These appear on multiple search endpoints. Parameters that accept multiple values use the pipe `|` separator (e.g. `genreSlug=bluegrass|jamband`).

### Geographic filters

| Param | Type | Notes |
|-------|------|-------|
| `geoLatitude` | number | e.g. `40.7505` |
| `geoLongitude` | number | e.g. `-73.9934` |
| `geoRadiusAmount` | int | default 60, max 5000 |
| `geoRadiusUnits` | enum | `mi` or `km` (default `mi`) |
| `geoCityId` | string | e.g. `jambase:4223296`. Pipe-delimited |
| `geoCityName` | string | Keyword search |
| `geoMetroId` | string | e.g. `jambase:1`. Pipe-delimited |
| `geoStateIso` | string | ISO 3166-2, US/CA/AU only (e.g. `US-NY`) |
| `geoCountryIso2` | string | e.g. `US` |
| `geoCountryIso3` | string | e.g. `USA` |
| `geoIp` | string | IPv4 or IPv6 |

### Date filters

| Param | Notes |
|-------|-------|
| `eventDatePreset` | One of: `today`, `tomorrow`, `thisWeekend`, `nextWeekend`, `halloween`, `newYears`, `july4th`. Overrides the `From`/`To` pair |
| `eventDateFrom` | RFC 3339 date, e.g. `2026-05-01` |
| `eventDateTo` | RFC 3339 date |
| `dateModifiedFrom` | RFC 3339 datetime — useful for incremental sync |
| `datePublishedFrom` | RFC 3339 datetime — first-published filter |

### Entity filters

| Param | Notes |
|-------|-------|
| `artistId` | `{source}:{id}` — pipe-delimited. Mutually exclusive with `artistName` |
| `artistName` | URL-encoded keyword. Pipe-delimited |
| `venueId` | `{source}:{id}` — pipe-delimited |
| `venueName` | Keyword. Pipe-delimited |
| `genreSlug` | One of the 18 genre slugs (see Genres). Pipe-delimited |
| `eventType` | `concerts` or `festivals`. Omit for both |

### Expansion flags (boolean)

| Param | Notes |
|-------|-------|
| `expandExternalIdentifiers` | Adds Spotify/MusicBrainz/Ticketmaster IDs. Plan-gated |
| `expandArtistSameAs` | Adds artist social/external links |
| `expandPastEvents` | Historical events. OpenAPI requires the apikey-enhancement plus `artistId` or `venueId` on `/events` search; the by-ID `/artists/id/{...}` and `/venues/id/{...}` endpoints accept it without those filters. The Pro+ tier requirement is documented in `llms-full.txt`, not in the OpenAPI spec |
| `expandUpcomingEvents` | (`/artists/id/{...}`, `/venues/id/{...}`) Adds upcoming `events[]` (array of `Concert | Festival`, plus `Stream` on artists when combined with `expandUpcomingStreams`) |
| `expandUpcomingStreams` | (`/artists/id/{...}`) Adds upcoming streams |
| `expandMetroCities` | (`/geographies/metros`) Adds member cities |
| `excludeEventPerformers` | Drops the `performer[]` block from event responses |

---

## Endpoints

### Events

#### `GET /events` — Search Events

Supports every common parameter above plus the `/events`-only filter:

| Param | Notes |
|-------|-------|
| `eventDataSource` | Filter results to one or more source slugs from `enumEventDataSource` (`axs`, `dice`, `etix`, `eventbrite`, `eventim-de`, `jambase`, `seated`, `seatgeek`, `see-tickets`, `see-tickets-uk`, `sofar-sounds`, `suitehop`, `ticketmaster`, `tixr`, `viagogo`). Pipe-delimit for multiple values |

Returns concerts and festivals.

```bash
curl "https://api.jambase.com/v3/events?geoStateIso=US-NY&eventDatePreset=thisWeekend&perPage=10" \
  -H "Authorization: Bearer $JAMBASE_API_KEY"
```

Response: `{ success, pagination, events: [Concert | Festival], request }`.

#### `GET /events/id/{eventDataSource}:{eventId}` — Get an Upcoming Event

| Path param | Allowed values |
|------------|----------------|
| `eventDataSource` | `axs`, `dice`, `etix`, `eventbrite`, `eventim-de`, `jambase`, `seated`, `see-tickets`, `see-tickets-uk`, `sofar-sounds`, `seatgeek`, `suitehop`, `ticketmaster`, `tixr`, `viagogo` |
| `eventId` | The provider's unique ID |

Query: `expandExternalIdentifiers`, `expandArtistSameAs`.
Response: `{ success, event: Concert | Festival, request }`.

```bash
curl "https://api.jambase.com/v3/events/id/jambase:12345678" \
  -H "Authorization: Bearer $JAMBASE_API_KEY"
```

---

### Streams

Music livestreams and webcasts. **Past streams are not available** — search returns upcoming only.

#### `GET /streams` — Search Upcoming Streams

Params: `page`, `perPage`, `eventDatePreset`, `eventDateFrom`, `eventDateTo`, `streamDataSource`, `dateModifiedFrom`, `datePublishedFrom`, `expandExternalIdentifiers`, `expandArtistSameAs`.

Response: `{ success, pagination, streams: [Stream], request }`.

> **Wire-format note**: The OpenAPI spec is authoritative for payload keys. `llms-full.txt` examples currently show `events: []` here — see the Spec Inconsistencies appendix.

```bash
curl "https://api.jambase.com/v3/streams?eventDatePreset=thisWeekend&perPage=10" \
  -H "Authorization: Bearer $JAMBASE_API_KEY"
```

#### `GET /streams/id/{streamDataSource}:{streamId}` — Get an Upcoming Stream

`streamDataSource` is currently restricted to `jambase` only. On the `/streams` search endpoint it is typed `pipeDelimited` per the OpenAPI spec — pipe-delimit syntax remains supported even though the formal enum is single-valued today. The `Stream` payload links back to the underlying physical event via `broadcastOfEvent`.

Response: `{ success, stream: Stream, request }`.

---

### Artists

#### `GET /artists` — Search Artists

At least one of `artistName` or `genreSlug` is required.

Params: `page`, `perPage`, `artistName`, `genreSlug`, `artistHasUpcomingEvents`, `dateModifiedFrom`, `datePublishedFrom`, `expandExternalIdentifiers`.

```bash
curl "https://api.jambase.com/v3/artists?artistName=Billie%20Eilish" \
  -H "Authorization: Bearer $JAMBASE_API_KEY"
```

#### `GET /artists/id/{artistDataSource}:{artistId}` — Get an Artist

| Path param | Allowed values |
|------------|----------------|
| `artistDataSource` | `axs`, `dice`, `etix`, `eventbrite`, `eventim-de`, `jambase`, `musicbrainz`, `seated`, `seatgeek`, `spotify`, `ticketmaster`, `viagogo` |

Query: `expandUpcomingEvents`, `expandUpcomingStreams`, `excludeEventPerformers`, `expandExternalIdentifiers`, `expandPastEvents`.

```bash
curl "https://api.jambase.com/v3/artists/id/spotify:3WrFJ7ztbogyGnTHbHJFl2?expandUpcomingEvents=true" \
  -H "Authorization: Bearer $JAMBASE_API_KEY"
```

---

### Venues

#### `GET /venues` — Search Venues

At least `venueName` or one geo parameter is required.

Params: `page`, `perPage`, `venueName`, all geo params, `venueHasUpcomingEvents`, `dateModifiedFrom`, `datePublishedFrom`, `expandExternalIdentifiers`.

```bash
curl "https://api.jambase.com/v3/venues?venueName=Brooklyn%20Bowl" \
  -H "Authorization: Bearer $JAMBASE_API_KEY"
```

#### `GET /venues/id/{venueDataSource}:{venueId}` — Get a Venue

| Path param | Allowed values |
|------------|----------------|
| `venueDataSource` | `axs`, `dice`, `etix`, `eventbrite`, `eventim-de`, `jambase`, `seated`, `seatgeek`, `suitehop`, `ticketmaster`, `viagogo` |

Query: `expandUpcomingEvents`, `excludeEventPerformers`, `expandExternalIdentifiers`, `expandArtistSameAs`.

---

### Geographies

These endpoints power the `geoCityId`, `geoMetroId`, `geoStateIso`, and `geoCountryIso2/Iso3` filters used by `/events`, `/venues`, etc. The standard pattern is **search → use returned `identifier` as a filter on a search endpoint**.

| Endpoint | Notes |
|----------|-------|
| `GET /geographies/cities` | Requires at least one geo param. Ordered by `x-numUpcomingEvents` desc, then alphabetical. Use returned `identifier` as `geoCityId`. Also accepts `geoMetroName` (mentioned in OpenAPI prose but not declared as a formal parameter — verify against live response before relying on it) |
| `GET /geographies/metros` | Returns `AdministrativeArea[]` alphabetically. `expandMetroCities=true` adds member cities. Use `identifier` as `geoMetroId` |
| `GET /geographies/states` | US, Canada, Australia only. Use `identifier` (e.g. `US-NY`) as `geoStateIso` |
| `GET /geographies/countries` | Returns ISO 3166-1 alpha-2 codes. Use `identifier` (e.g. `US`) as `geoCountryIso2` |

All four accept the corresponding `*HasUpcomingEvents` boolean to filter to entities with active inventory.

---

### Genres

#### `GET /genres`

Returns the complete v3 genre taxonomy (18 entries). Use the `identifier` as `genreSlug` on any search endpoint; pipe-delimit to combine.

| Slug | Display name |
|------|--------------|
| `bluegrass` | Bluegrass |
| `blues` | Blues |
| `christian` | Christian |
| `classical` | Classical |
| `country-music` | Country |
| `edm` | EDM |
| `folk` | Folk |
| `hip-hop-rap` | Hip-Hop / Rap |
| `indie` | Indie |
| `jamband` | Jam Band |
| `jazz` | Jazz |
| `latin` | Latin |
| `metal` | Metal |
| `pop` | Pop |
| `punk` | Punk |
| `reggae` | Reggae |
| `rhythm-and-blues-soul` | R&B / Soul |
| `rock` | Rock |

> **Breaking change from v1**: `country` → `country-music`, `hiphop` → `hip-hop-rap`, separate `rnb` and `soul` collapsed into `rhythm-and-blues-soul`. Standalone `funk` was removed; `christian` and `classical` are new.

---

### Lookups

Discover the supported source slugs for each ID family.

| Endpoint | Payload key | Returns |
|----------|-------------|---------|
| `GET /lookups/event-data-sources` | `dataSources` | 15 sources for events (see table below) |
| `GET /lookups/stream-data-sources` | `ticketVendors` (verify against live response — other lookups use `dataSources`) | Stream sources (currently `jambase` only) |
| `GET /lookups/artist-data-sources` | `dataSources` | 12 artist sources |
| `GET /lookups/venue-data-sources` | `dataSources` | 11 venue sources |

> The cross-platform-ID coverage is the JamBase Data differentiator — call the right lookup endpoint to discover sources, then use any `{source}:{id}` slug as a filter or path segment.

---

## Multi-Source ID Lookup

JamBase normalizes the same artist/venue/event across many third-party catalogs. Use `{source}:{id}` everywhere an ID is accepted.

### Event ID sources (15)

| Source | Example |
|--------|---------|
| `jambase` | `jambase:12345678` |
| `axs` | `axs:<axsId>` |
| `dice` | `dice:<diceId>` |
| `etix` | `etix:<etixId>` |
| `eventbrite` | `eventbrite:<eventbriteId>` |
| `eventim-de` | `eventim-de:<eventimDeId>` |
| `seated` | `seated:<seatedId>` |
| `seatgeek` | `seatgeek:<seatgeekId>` |
| `see-tickets` | `see-tickets:<seeTicketsId>` |
| `see-tickets-uk` | `see-tickets-uk:<seeTicketsUkId>` |
| `sofar-sounds` | `sofar-sounds:<sofarSoundsId>` |
| `suitehop` | `suitehop:<suitehopId>` |
| `ticketmaster` | `ticketmaster:K8vZ9175st0` |
| `tixr` | `tixr:<tixrId>` |
| `viagogo` | `viagogo:<viagogoId>` |

> ID format varies by source — only the slug prefix (and the `:` separator) is enforced. Use the `/lookups/event-data-sources` endpoint to discover currently supported slugs.

### Artist ID sources (12)

| Source | Example |
|--------|---------|
| `jambase` | `jambase:228924` |
| `spotify` | `spotify:3WrFJ7ztbogyGnTHbHJFl2` |
| `musicbrainz` | `musicbrainz:e01646f2-2a04-450d-8bf2-0d993082e058` |
| `ticketmaster` | `ticketmaster:K8vZ9175st0` |
| `axs`, `dice`, `etix`, `eventbrite`, `eventim-de`, `seated`, `seatgeek`, `viagogo` | `{source}:{id}` |

### Venue ID sources (11)

| Source | Example |
|--------|---------|
| `jambase` | `jambase:62108` |
| `ticketmaster` | `ticketmaster:k7vGF99ORYpnS` |
| `axs`, `dice`, `etix`, `eventbrite`, `eventim-de`, `seated`, `seatgeek`, `suitehop`, `viagogo` | `{source}:{id}` |

### Stream ID sources (1)

`jambase` only (as of v3.0.0).

### Multi-value pipe pattern

```http
GET /events?artistId=jambase:228924|spotify:3WrFJ7ztbogyGnTHbHJFl2|musicbrainz:e01646f2-...
GET /events?genreSlug=bluegrass|jamband&geoStateIso=US-CO|US-CA
```

---

## Schemas

All responses use Schema.org-compatible JSON-LD types with vendor-namespaced extensions prefixed `x-`.

### Event-level extensions (apply to Concert, Festival, and Stream)

These fields are declared on the OpenAPI `Event` base type and are inherited by `Concert`, `Festival`, and `Stream`. Listed once here to avoid duplication in each derived schema.

| Field | Type | Notes |
|-------|------|-------|
| `isAccessibleForFree` | bool (default `false`) | True when the event is free to attend |
| `x-promoImage` | URL | Secondary "admat" promotional image, distinct from the primary `image` field |

### Performer block extensions

The OpenAPI Event `performer` items add JamBase-specific fields beyond the Schema.org `MusicGroup` base:

| Field | Type | Notes |
|-------|------|-------|
| `x-performanceDate` | ISO 8601 | The date this performer is on stage (Festival use case — sort lineup by day) |
| `x-performanceRank` | integer | Lineup ordering rank (lower = higher billing) |
| `x-isHeadliner` | bool | True for headlining performers |
| `x-dateIsConfirmed` | bool | Festival-only. When `false`, the performer appears on day 1 by convention pending confirmation |

### Concert

Schema.org type: `MusicEvent`. Discriminated by `"type": "Concert"` (bare `type`, not `@type`).

> **Discriminator asymmetry**: Per the OpenAPI required block, Event-derived schemas (`Concert`, `Festival`, `Stream`) use bare `type` as the discriminator. Standalone Schema.org types in the same payload (`MusicGroup`, `MusicVenue`, `Organization`, `PostalAddress`, `GeoCoordinates`, `Offer`, `PriceSpecification`, `City`, `AdministrativeArea`) use `@type`. `llms-full.txt` examples show `@type` for everything; the OpenAPI required block is authoritative for Event-derived types.

> **Required vs optional**: Per the OpenAPI `required` block, `Concert` requires `type, name, identifier, url, eventStatus, startDate, location, performer`. `Festival` adds `endDate` and `x-lineupDisplay` (the latter is a spec-typo reference to `x-lineupDisplayOption`). `Stream` matches Concert's required set but omits `endDate`. Everything else — `image`, `offers`, `previousStartDate`, `doorTime`, all `x-*` extensions, etc. — is optional.

| Field | Type | Notes |
|-------|------|-------|
| `type` | `"Concert"` | Discriminator (bare `type`, required) |
| `identifier` | string | JamBase event ID, e.g. `jambase:12345678` |
| `name`, `url`, `image` | string | Event name / canonical URL (typically `www.jambase.com/...`) / image URL |
| `startDate`, `endDate`, `previousStartDate`, `doorTime` | ISO 8601 | **Local time, no offset** — see timezone note below |
| `eventStatus` | enum | `scheduled`, `postponed`, `rescheduled`, `cancelled` |
| `eventAttendanceMode` | enum | `offline`, `online`, `mixed` |
| `location` | `MusicVenue` | Where it happens |
| `performer` | `MusicGroup[]` | Performing artists |
| `offers` | `Offer[]` | Ticket offers (pricing gated by plan) |
| `x-genre` | string | Primary genre slug |
| `x-customTitle` | string | Optional override for the default `name` (used for special-billed shows) |
| `x-subtitle` | string | Supplementary description, e.g. `"Album Release Party"` |
| `x-headlinerInSupport` | bool | When true, list headlining performers alongside support acts in the lineup |
| `x-streamIds` | `string[]` | IDs of associated `Stream` records — the inverse of `Stream.broadcastOfEvent` |
| `x-externalIdentifiers` | `ExternalIdentifier[]` | Cross-platform IDs (Spotify, MusicBrainz, Ticketmaster, etc.) when `expandExternalIdentifiers=true` |
| `datePublished`, `dateModified` | ISO 8601 | First-indexed and last-updated timestamps (inherited from Schema.org `Thing`) |

### Festival

Same shape as Concert, with `"type": "Festival"` (bare `type`) plus:

- `subEvent` — `Event[]` of individual day/stage events
- `x-lineupDisplayOption` — `full` or `daybyday`. (Note: the OpenAPI Festival `required` block lists this property as `x-lineupDisplay` — that's a spec typo; the canonical property name is `x-lineupDisplayOption`. See the Spec Inconsistencies appendix.)

### Stream

| Field | Type | Notes |
|-------|------|-------|
| `type` | `"Stream"` | Discriminator (bare `type`, required) |
| `identifier`, `name`, `url`, `image`, `startDate`, `endDate` | | |
| `eventAttendanceMode` | enum | Typically `"online"` for streams; the field accepts `mixed`, `offline`, or `online` (inherited from `Event`, default `offline`) |
| `isLiveBroadcast` | bool | |
| `performer` | `MusicGroup[]` | |
| `broadcastOfEvent` | `Event[]` | Links back to the underlying physical concert(s) |
| `offers` | `Offer[]` | Stream purchase URL(s) |

### MusicGroup (Artist)

Schema.org type: `MusicGroup`.

- `name`, `identifier`, `url`, `image`
- `genre` — array of genre slugs
- `member` — array of `{ type, name, identifier, image, url }` (band members)
- `memberOf` — array of bands the musician belongs to
- `foundingLocation` — `{ type: "Place", name }`
- `foundingDate` — string (year, e.g. `"1983"`)
- `x-bandOrMusician` — enum: `band` or `musician`
- `sameAs` — array of `URL` objects (typed by `enumUrlType`) when `expandArtistSameAs=true`
- `x-numUpcomingEvents` — count
- `x-externalIdentifiers` — `ExternalIdentifier[]` when `expandExternalIdentifiers=true`
- `events` — array of `Concert | Festival | Stream` items (`oneOf` per OpenAPI), populated when `expandUpcomingEvents=true` and/or `expandUpcomingStreams=true`

### MusicVenue

Schema.org type: `MusicVenue`.

- `name`, `identifier`, `url`
- `address` — `PostalAddress`
- `geo` — `GeoCoordinates`
- `maximumAttendeeCapacity` — integer (Startup plan and above)
- `x-isPermanentlyClosed` — bool (default `false`). Useful for filtering closed venues out of search results
- `x-numUpcomingEvents` — count
- `x-externalIdentifiers` — `ExternalIdentifier[]` when `expandExternalIdentifiers=true`
- `events` — array of `Concert | Festival` items (`oneOf` per OpenAPI), populated when `expandUpcomingEvents=true`

### City / State / Country / AdministrativeArea (Metro)

| Type | Key fields |
|------|-----------|
| `City` | `identifier`, `name`, `geo`, `address.{addressRegion, addressCountry}`, `x-timezone`, `containedInPlace` (Metro — populated only on `/geographies/cities` responses, not on `City` objects embedded inside `Concert`/`Festival`/`Stream`), `x-numUpcomingEvents` |
| `State` | `identifier` (e.g. `US-NY`), `name`, `alternateName` (postal abbreviation, e.g. `"AL"`, `"NY"`, `"QC"`), `country`, `x-numUpcomingEvents` |
| `Country` | `identifier` (ISO 3166-1 alpha-2), `name`, `alternateName` (ISO 3166-1 alpha-3, typed against `enumCountryIso3`), `x-numUpcomingEvents` |
| `AdministrativeArea` (Metro) | `identifier`, `name`, `geo`, `address`, `x-primaryCityId`, `x-numUpcomingEvents`, `containsPlace` (City[]) when `expandMetroCities=true` |

### PostalAddress

`streetAddress`, `addressLocality`, `addressRegion`, `postalCode`, `addressCountry`, plus extensions `x-streetAddress2`, `x-timezone`, `x-jamBaseMetroId`, `x-jamBaseCityId`.

### Offer

`identifier`, `url`, `name`, `category`, `seller` (`Organization`), `validFrom`, `priceSpecification`.

The `category` field carries convention values (not enum-enforced but commonly keyed by consumers): `ticketingLinkPrimary`, `ticketingLinkSecondary`. Use these to surface the canonical "buy tickets" link vs alternates.

### PriceSpecification

`price`, `priceCurrency` (ISO 4217), and `minPrice` / `maxPrice` for ranges.

### Organization

`identifier` (slug), `name`, `disambiguatingDescription` (e.g. `eventDataSource`, `artistDataSource`, `eventTicketVendorPrimary`).

> **Note**: OpenAPI examples show `x-createdOnDate` and `x-updatedOnDate` on `Organization` payloads returned by the `/lookups/*-data-sources` endpoints. Those `x-*` indexing-timestamp variants do **not** appear on `Concert`, `Festival`, or `Stream` — those types use Schema.org-inherited `datePublished` and `dateModified` instead.

### ExternalIdentifier

Per the OpenAPI spec:

| Field | Type | Notes |
|-------|------|-------|
| `source` | string (enum) | A data-source slug (`spotify`, `musicbrainz`, `ticketmaster`, etc.) |
| `identifier` | `string[]` | Array of one or more IDs from that source — note this is an **array**, not a single string |

There is no `@type` field on `ExternalIdentifier` per the OpenAPI schema. `llms-full.txt` documents `@type: "ExternalIdentifier"` and a scalar `identifier` — both differ from the OpenAPI contract; the OpenAPI shape is authoritative. See the Spec Inconsistencies appendix.

Returned as `x-externalIdentifiers: ExternalIdentifier[]` on `Concert`, `MusicGroup`, and `MusicVenue` when `expandExternalIdentifiers=true`.

### URL

Used as the item type inside `MusicGroup.sameAs[]` when `expandArtistSameAs=true`.

| Field | Type | Notes |
|-------|------|-------|
| `@type` | `"URL"` | |
| `identifier` | enum (`enumUrlType`) | One of: `officialSite`, `facebook`, `twitter`, `instagram`, `youtube`, `musicbrainz`, `spotify`, `androidApp`, `iosApp` |
| `url` | string | The actual URL |

Note: `MusicGroup.sameAs[]` is typed as `URL[]` (objects with `enumUrlType` identifiers, suitable for human-facing link lists). For raw cross-platform IDs, use `expandExternalIdentifiers=true` instead, which returns `ExternalIdentifier[]` with raw ID strings — better for ID-to-ID mapping.

### Genre, GeoCoordinates, Pagination

Standard shapes — see endpoint examples.

### Timezone handling (important)

`startDate`, `endDate`, `previousStartDate`, and `doorTime` are returned in **the venue's local time without an offset**. Read `event.location.address.x-timezone` (a tz-database name like `America/New_York`) to convert to UTC or to the user's local time. Do not assume the strings are RFC 3339-compliant for offset arithmetic.

---

## Example Responses

### Concert

Single-event response from `GET /events/id/{eventDataSource}:{eventId}`:

```json
{
  "success": true,
  "event": {
    "type": "Concert",
    "identifier": "jambase:12345678",
    "name": "Phish at Madison Square Garden",
    "url": "https://www.jambase.com/show/phish-msg-2026",
    "startDate": "2026-12-31T20:00:00",
    "endDate":   "2027-01-01T01:00:00",
    "eventStatus": "scheduled",
    "eventAttendanceMode": "offline",
    "x-genre": "jamband",
    "performer": [
      {
        "@type": "MusicGroup",
        "identifier": "jambase:5572",
        "name": "Phish"
      }
    ],
    "location": {
      "@type": "MusicVenue",
      "identifier": "jambase:1234",
      "name": "Madison Square Garden",
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "4 Pennsylvania Plaza",
        "addressLocality": "New York",
        "addressRegion": "US-NY",
        "postalCode": "10001",
        "addressCountry": "US",
        "x-timezone": "America/New_York"
      },
      "geo": { "@type": "GeoCoordinates", "latitude": 40.7505, "longitude": -73.9934 }
    },
    "offers": [
      {
        "@type": "Offer",
        "url": "https://...",
        "category": "ticketingLinkPrimary",
        "seller": { "@type": "Organization", "identifier": "ticketmaster", "name": "Ticketmaster" },
        "priceSpecification": { "@type": "PriceSpecification", "minPrice": 89.50, "maxPrice": 350.00, "priceCurrency": "USD" }
      }
    ]
  }
}
```

### Festival

```json
{
  "type": "Festival",
  "identifier": "jambase:99887",
  "name": "Newport Folk Festival",
  "startDate": "2026-07-24T12:00:00",
  "endDate":   "2026-07-26T23:00:00",
  "x-lineupDisplayOption": "daybyday",
  "subEvent": [
    { "type": "Concert", "identifier": "jambase:99887-d1", "name": "Day 1", "startDate": "2026-07-24T12:00:00" },
    { "type": "Concert", "identifier": "jambase:99887-d2", "name": "Day 2", "startDate": "2026-07-25T12:00:00" }
  ]
}
```

### Stream

```json
{
  "type": "Stream",
  "identifier": "jambase:str_8821001",
  "name": "Phish Webcast — Madison Square Garden",
  "startDate": "2026-05-02T23:00:00-04:00",
  "eventStatus": "scheduled",
  "eventAttendanceMode": "online",
  "isLiveBroadcast": true,
  "performer": [{ "@type": "MusicGroup", "identifier": "jambase:5572", "name": "Phish" }],
  "broadcastOfEvent": [
    { "type": "Concert", "identifier": "jambase:12345678", "name": "Phish at MSG" }
  ],
  "offers": [
    {
      "@type": "Offer",
      "name": "LivePhish",
      "url": "https://livephish.com/checkout/2026-05-02",
      "priceSpecification": { "@type": "PriceSpecification", "price": 24.99, "priceCurrency": "USD" }
    }
  ]
}
```

### City + Metro

```json
{
  "@type": "City",
  "identifier": "jambase:4223296",
  "name": "Brooklyn",
  "geo": { "@type": "GeoCoordinates", "latitude": 40.6782, "longitude": -73.9442 },
  "address": { "addressRegion": "US-NY", "addressCountry": "US" },
  "x-timezone": "America/New_York",
  "containedInPlace": {
    "@type": "AdministrativeArea",
    "identifier": "jambase:1",
    "name": "New York Area"
  },
  "x-numUpcomingEvents": 1842
}
```

---

## Caching Recommendations

| Data | TTL | Notes |
|------|-----|-------|
| Genres | 30 days | Effectively static |
| Lookups (data sources) | 7 days | Source list grows occasionally |
| Countries / States | 30 days | |
| Cities / Metros | 7 days | `x-numUpcomingEvents` drifts |
| Artist info | 7 days | Refresh sooner if the user is actively touring |
| Venue info | 30 days | Refresh capacity yearly |
| Upcoming events | 1–4 hours | Use `dateModifiedFrom` for incremental sync |
| Streams | 1 hour | Often added/removed close to broadcast |
| Historical events | 30+ days | Stable once past |

---

## TypeScript Client (Bearer + IETF rate-limit aware)

Centralizes auth, parses both rate-limit windows, and respects `Retry-After` on 429.

```typescript
const BASE = "https://api.jambase.com/v3";
const KEY = process.env.JAMBASE_API_KEY!;

interface RateState {
  hourRemaining: number;
  hourResetSec: number;
  minuteRemaining: number;
  minuteResetSec: number;
}

const rate: RateState = {
  hourRemaining: Infinity,
  hourResetSec: 0,
  minuteRemaining: Infinity,
  minuteResetSec: 0,
};

function parseRateLimit(header: string | null): void {
  if (!header) return;
  for (const part of header.split(",").map((s) => s.trim())) {
    const [window, ...kv] = part.split(";").map((s) => s.trim());
    const map = Object.fromEntries(kv.map((p) => p.split("=")));
    const remaining = Number(map.r);
    const resetSec = Number(map.t);
    if (Number.isNaN(remaining) || Number.isNaN(resetSec)) continue;
    if (window === "hour") {
      rate.hourRemaining = remaining;
      rate.hourResetSec = resetSec;
    } else if (window === "minute") {
      rate.minuteRemaining = remaining;
      rate.minuteResetSec = resetSec;
    }
  }
}

async function preflightThrottle(): Promise<void> {
  if (rate.minuteRemaining <= 0) {
    await new Promise((r) => setTimeout(r, (rate.minuteResetSec + 1) * 1000));
  }
}

export async function jb<T>(path: string, query: Record<string, string | number | boolean> = {}): Promise<T> {
  await preflightThrottle();

  const url = new URL(`${BASE}${path}`);
  for (const [k, v] of Object.entries(query)) url.searchParams.set(k, String(v));

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${KEY}`, Accept: "application/json" },
  });

  parseRateLimit(res.headers.get("RateLimit"));

  if (res.status === 429) {
    const retryAfter = Number(res.headers.get("Retry-After") ?? rate.minuteResetSec ?? 1);
    await new Promise((r) => setTimeout(r, retryAfter * 1000));
    return jb<T>(path, query);
  }

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const reason = body?.errors?.[0]?.errorMessage
      ?? body?.error?.message
      ?? res.statusText;
    throw new Error(`[JamBase] ${res.status} ${reason}`);
  }

  return res.json() as Promise<T>;
}
```

### Paginate-all helper

```typescript
export async function* jbPaginate<T>(
  path: string,
  payloadKey: string,
  query: Record<string, string | number | boolean> = {},
): AsyncGenerator<T, void, unknown> {
  let page = 1;
  let totalPages = 1;
  do {
    const res = await jb<{ pagination: { totalPages: number }; [k: string]: unknown }>(path, {
      ...query,
      page,
      perPage: 100,
    });
    totalPages = res.pagination.totalPages;
    for (const item of (res[payloadKey] as T[]) ?? []) yield item;
    page++;
  } while (page <= totalPages);
}
```

### Look up events by MBID

```typescript
const events = jbPaginate<unknown>("/events", "events", {
  artistId: `musicbrainz:${mbid}`,
  eventDatePreset: "thisWeekend",
});
for await (const event of events) {
  console.log(event);
}
```

### Look up events by Spotify ID

```typescript
const data = await jb<{ events: unknown[] }>("/events", {
  artistId: "spotify:3WrFJ7ztbogyGnTHbHJFl2",
  expandExternalIdentifiers: true,
});
```

### Geo-radius search

```typescript
const data = await jb<{ events: unknown[] }>("/events", {
  geoLatitude: 40.7128,
  geoLongitude: -74.0060,
  geoRadiusAmount: 25,
  geoRadiusUnits: "mi",
  eventDatePreset: "thisWeekend",
});
```

---

## Python (requests)

```python
import os
import requests

BASE = "https://api.jambase.com/v3"
HEADERS = {"Authorization": f"Bearer {os.environ['JAMBASE_API_KEY']}"}

response = requests.get(
    f"{BASE}/venues",
    params={
        "geoLatitude": 40.7505,
        "geoLongitude": -73.9934,
        "geoRadiusAmount": 25,
        "geoRadiusUnits": "mi",
        "venueHasUpcomingEvents": True,
    },
    headers=HEADERS,
)
response.raise_for_status()
for venue in response.json()["venues"]:
    print(f"{venue['name']} — capacity: {venue.get('maximumAttendeeCapacity', 'N/A')}")
```

---

## Keeping Current

### Authoritative sources (priority order)

1. [`https://data.jambase.com/llms-full.txt`](https://data.jambase.com/llms-full.txt) — dated, versioned LLM-tuned reference
2. [`https://data.jambase.com/openapi.json`](https://data.jambase.com/openapi.json) — OpenAPI 3.1 spec (param names, enums, schemas)
3. [`https://data.jambase.com/.well-known/ai-plugin.json`](https://data.jambase.com/.well-known/ai-plugin.json) — discoverable AI plugin manifest (coverage stats, RPM caps, contact, logo)
4. [`https://data.jambase.com/llms.txt`](https://data.jambase.com/llms.txt) — short summary

### Version detection

```typescript
const spec = await fetch("https://data.jambase.com/openapi.json").then((r) => r.json());
console.log(spec.info.version, spec.servers[0].url);
```

### Test endpoint

```http
GET https://api.jambase.com/v3/genres
Authorization: Bearer YOUR_API_KEY
```

Expected: 18 genres, alphabetical by display name.

### Spec Inconsistencies

JamBase's published v3 artifacts (`openapi.json`, `llms-full.txt`, `ai-plugin.json`) disagree internally on a handful of fields. This appendix documents the **runtime stance** this skill takes for each disagreement so consumers know what to expect at the wire.

| # | Topic | Skill stance (what to expect at runtime) | Severity |
|---|-------|------------------------------------------|---------:|
| 1 | Stream search payload key | Expect `streams: []` (OpenAPI authority); legacy `events: []` may appear in older docs | High |
| 2 | Stream by-id payload key | Expect `stream:` (OpenAPI authority); legacy `event:` may appear in older docs | High |
| 3 | Error envelope shape | Expect `errors: [{ errorCode, errorMessage }]` (OpenAPI authority); the TS client also defends against the singular `error: { code, message }` shape | High |
| 4 | Concert / Festival / Stream discriminator | Expect bare `type` (OpenAPI required-block authority); standalone Schema.org types like `MusicGroup` use `@type` | High |
| 5 | Festival lineup-display field | Expect `x-lineupDisplayOption` (property-name authority); the OpenAPI required-block typo `x-lineupDisplay` is non-canonical | Medium |
| 6 | `ExternalIdentifier` shape | Expect `{ source, identifier: string[] }` with no `@type` (OpenAPI authority) | Medium |
| 7 | `PostalAddress.addressRegion` | Handle both shapes: live responses return a bare ISO 3166-2 string, while OpenAPI declares a `State` object. Type-narrow defensively | Medium |
| 8 | `streamDataSource` enum | Expect `[jambase]` only at runtime, even though the OpenAPI parameter description text mentions Mandolin / StageIt | Medium |

> **Upstream-facing version**: For the JamBase-team-facing report with full file:line evidence for every disagreement and suggested upstream fixes, see `jambase-v3-spec-feedback-for-jambase-team.md` (April 30, 2026 — lives in the platform `.cursor/plans/` directory, not in this skill repo). When that document is delivered and JamBase resolves an item, update both this appendix and any affected schema rows above.

### Last verified

- **Date**: April 30, 2026 — reciprocal audit of `references/jambase.md` vs `llms-full.txt` and `openapi.json`
- **API version**: `v3.0.0` (released Mar 5, 2026)
- **Skill repo SHA**: `38e5476`
- **Verified against**: `llms-full.txt` + `openapi.json` (both pulled from `data.jambase.com`)
