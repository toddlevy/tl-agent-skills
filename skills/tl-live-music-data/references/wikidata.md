# Wikidata SPARQL Reference

**Role**: Cross-reference data - link IDs across platforms via structured queries

## Quick Facts

| Property | Value |
|----------|-------|
| Endpoint | `https://query.wikidata.org/sparql` |
| Auth | None (public) |
| Rate Limit | Reasonable use (no hard limits) |
| Format | SPARQL results JSON |
| Docs | https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service |
| Query Builder | https://query.wikidata.org |

## Request Format

```http
GET https://query.wikidata.org/sparql?query={SPARQL_QUERY}
Accept: application/sparql-results+json
```

Or POST for long queries:
```http
POST https://query.wikidata.org/sparql
Content-Type: application/x-www-form-urlencoded

query={SPARQL_QUERY}
```

## Music ID Properties

| Property | Platform | Example |
|----------|----------|---------|
| `P434` | MusicBrainz artist ID | `e01646f2-2a04-450d-8bf2-0d993082e058` |
| `P435` | MusicBrainz work ID | UUID |
| `P436` | MusicBrainz release group ID | UUID |
| `P966` | MusicBrainz label ID | UUID |
| `P1953` | Discogs artist ID | `45` |
| `P1954` | Discogs master ID | `123456` |
| `P1955` | Discogs label ID | `1234` |
| `P1902` | Spotify artist ID | `6rqhFgbbKwnb9MLmUQDhG6` |
| `P1728` | AllMusic artist ID | `mn0000070043` |
| `P2722` | Deezer artist ID | `892` |
| `P4208` | Songkick artist ID | `468146` |
| `P3040` | SoundCloud ID | `aphex-twin` |
| `P3478` | Songkick ID (deprecated) | - |
| `P1827` | ISNI | `0000000121400736` |
| `P345` | IMDb ID | `nm0417649` |
| `P2397` | YouTube channel ID | `UC...` |

## Common Queries

### Artist by MusicBrainz ID

```sparql
SELECT ?item ?itemLabel ?birthDate ?deathDate ?country ?countryLabel WHERE {
  ?item wdt:P434 "e01646f2-2a04-450d-8bf2-0d993082e058" .
  OPTIONAL { ?item wdt:P569 ?birthDate }
  OPTIONAL { ?item wdt:P570 ?deathDate }
  OPTIONAL { ?item wdt:P27 ?country }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
```

### Get All External IDs for Artist

```sparql
SELECT ?item ?itemLabel ?mbid ?discogs ?spotify ?allmusic ?songkick WHERE {
  ?item wdt:P434 "e01646f2-2a04-450d-8bf2-0d993082e058" .
  OPTIONAL { ?item wdt:P434 ?mbid }
  OPTIONAL { ?item wdt:P1953 ?discogs }
  OPTIONAL { ?item wdt:P1902 ?spotify }
  OPTIONAL { ?item wdt:P1728 ?allmusic }
  OPTIONAL { ?item wdt:P4208 ?songkick }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
```

### Artist by Discogs ID

```sparql
SELECT ?item ?itemLabel ?mbid WHERE {
  ?item wdt:P1953 "45" .
  OPTIONAL { ?item wdt:P434 ?mbid }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
```

### Artist by Spotify ID

```sparql
SELECT ?item ?itemLabel ?mbid ?discogs WHERE {
  ?item wdt:P1902 "6rqhFgbbKwnb9MLmUQDhG6" .
  OPTIONAL { ?item wdt:P434 ?mbid }
  OPTIONAL { ?item wdt:P1953 ?discogs }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
```

### Search Artist by Name

```sparql
SELECT ?item ?itemLabel ?mbid ?description WHERE {
  ?item wdt:P31 wd:Q5 .              # Instance of human
  ?item wdt:P106 wd:Q177220 .        # Occupation: singer
  ?item rdfs:label ?label .
  FILTER(LANG(?label) = "en")
  FILTER(CONTAINS(LCASE(?label), "trey anastasio"))
  OPTIONAL { ?item wdt:P434 ?mbid }
  OPTIONAL { ?item schema:description ?description . FILTER(LANG(?description) = "en") }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
LIMIT 10
```

### Search Band by Name

```sparql
SELECT ?item ?itemLabel ?mbid ?inception WHERE {
  ?item wdt:P31 wd:Q215380 .         # Instance of musical group
  ?item rdfs:label ?label .
  FILTER(LANG(?label) = "en")
  FILTER(CONTAINS(LCASE(?label), "phish"))
  OPTIONAL { ?item wdt:P434 ?mbid }
  OPTIONAL { ?item wdt:P571 ?inception }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
LIMIT 10
```

### Get Band Members

```sparql
SELECT ?item ?itemLabel ?member ?memberLabel ?instrument ?instrumentLabel WHERE {
  ?item wdt:P434 "e01646f2-2a04-450d-8bf2-0d993082e058" .
  ?item wdt:P527 ?member .           # Has part (members)
  OPTIONAL { ?member wdt:P1303 ?instrument }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
```

## Response Format

```json
{
  "head": {
    "vars": ["item", "itemLabel", "mbid", "discogs"]
  },
  "results": {
    "bindings": [
      {
        "item": {
          "type": "uri",
          "value": "http://www.wikidata.org/entity/Q217346"
        },
        "itemLabel": {
          "type": "literal",
          "value": "Phish",
          "xml:lang": "en"
        },
        "mbid": {
          "type": "literal",
          "value": "e01646f2-2a04-450d-8bf2-0d993082e058"
        },
        "discogs": {
          "type": "literal",
          "value": "15885"
        }
      }
    ]
  }
}
```

## TypeScript Implementation

```typescript
interface WikidataResult {
  head: { vars: string[] };
  results: {
    bindings: Array<{
      [key: string]: {
        type: string;
        value: string;
        'xml:lang'?: string;
      };
    }>;
  };
}

async function wikidataQuery(sparql: string): Promise<WikidataResult> {
  const url = new URL('https://query.wikidata.org/sparql');
  url.searchParams.set('query', sparql);
  
  const response = await fetch(url.toString(), {
    headers: {
      'Accept': 'application/sparql-results+json',
      'User-Agent': 'MyApp/1.0 (contact@example.com)'
    }
  });
  
  return response.json();
}

async function getExternalIdsByMbid(mbid: string) {
  const sparql = `
    SELECT ?discogs ?spotify ?allmusic ?songkick WHERE {
      ?item wdt:P434 "${mbid}" .
      OPTIONAL { ?item wdt:P1953 ?discogs }
      OPTIONAL { ?item wdt:P1902 ?spotify }
      OPTIONAL { ?item wdt:P1728 ?allmusic }
      OPTIONAL { ?item wdt:P4208 ?songkick }
    }
  `;
  
  const result = await wikidataQuery(sparql);
  const binding = result.results.bindings[0];
  
  return {
    discogs: binding?.discogs?.value,
    spotify: binding?.spotify?.value,
    allmusic: binding?.allmusic?.value,
    songkick: binding?.songkick?.value
  };
}
```

## Useful Entity Types

| Q-ID | Type |
|------|------|
| `Q5` | Human |
| `Q215380` | Musical group |
| `Q482994` | Album |
| `Q134556` | Single |
| `Q7366` | Song |
| `Q18127` | Record label |
| `Q177220` | Singer |
| `Q639669` | Musician |
| `Q488205` | Singer-songwriter |

## SPARQL Tips

### Label Service

Always include for human-readable names:
```sparql
SERVICE wikibase:label { bd:serviceParam wikibase:language "en,de,fr" }
```

### Optional Fields

Use OPTIONAL for properties that may not exist:
```sparql
OPTIONAL { ?item wdt:P569 ?birthDate }
```

### Filtering

```sparql
FILTER(LANG(?label) = "en")
FILTER(CONTAINS(LCASE(?label), "searchterm"))
FILTER(?year >= 1990 && ?year <= 2000)
```

### Limit Results

Always limit for safety:
```sparql
LIMIT 100
```

## Common Gotchas

1. **Not all artists have Wikidata entries** - fallback to other resolution methods
2. **Multiple entries possible** - same artist may have duplicate entries
3. **Property completeness varies** - some artists have all IDs, others have few
4. **Query timeout** - complex queries may timeout; simplify or add limits

## Caching Recommendations

| Data | TTL |
|------|-----|
| External ID mappings | 30 days |
| Artist metadata | 7 days |
| Search results | 24 hours |

---

## Keeping Current

### Authoritative Documentation

| Resource | URL |
|----------|-----|
| SPARQL Service | https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service |
| Query Builder | https://query.wikidata.org/ |
| Property List | https://www.wikidata.org/wiki/Wikidata:List_of_properties |
| Music Properties | https://www.wikidata.org/wiki/Wikidata:WikiProject_Music |
| Status | https://www.wikidata.org/wiki/Wikidata:Status_updates |

### Version Detection

SPARQL endpoint doesn't version traditionally. Monitor:

1. **Property changes** - New music ID properties added regularly
2. **Service status** - https://www.wikidata.org/wiki/Wikidata:Status_updates
3. **Query timeout changes** - May affect complex queries

### Property Discovery

Find new music-related properties:

```sparql
SELECT ?prop ?propLabel WHERE {
  ?prop wdt:P31 wd:Q19847637 .  # External identifier property
  ?prop wdt:P1629 ?subject .
  ?subject wdt:P31/wdt:P279* wd:Q482994 .  # Related to music
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
LIMIT 50
```

### Test Endpoint

Verify SPARQL service:

```http
GET https://query.wikidata.org/sparql?query=SELECT%20%3Fitem%20WHERE%20%7B%20%3Fitem%20wdt%3AP434%20%22e01646f2-2a04-450d-8bf2-0d993082e058%22%20%7D
Accept: application/sparql-results+json
```

Expected: Returns Phish entity (Q217346).

### Last Verified

- **Date**: March 2026
- **Verified by**: SPARQL query testing
