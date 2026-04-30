# Pagination Patterns

> Loaded on-demand by `tl-live-music-data` when iterating paginated API responses. See `../SKILL.md` for the parent skill.

## Cursor-Based (Preferred)

Used by: JamBase, Spotify

```typescript
async function* paginateCursor<T>(
  fetchPage: (cursor?: string) => Promise<{ items: T[]; nextCursor?: string }>
): AsyncGenerator<T> {
  let cursor: string | undefined;
  do {
    const page = await fetchPage(cursor);
    for (const item of page.items) yield item;
    cursor = page.nextCursor;
  } while (cursor);
}

// Usage
for await (const event of paginateCursor(cursor => 
  jambase.getEvents({ cursor, pageSize: 100 })
)) {
  processEvent(event);
}
```

## Offset-Based

Used by: MusicBrainz, Setlist.fm, Discogs

```typescript
async function* paginateOffset<T>(
  fetchPage: (offset: number) => Promise<{ items: T[]; total: number }>,
  pageSize = 100
): AsyncGenerator<T> {
  let offset = 0;
  let total = Infinity;
  
  while (offset < total) {
    const page = await fetchPage(offset);
    total = page.total;
    for (const item of page.items) yield item;
    offset += pageSize;
  }
}
```

## Per-API Pagination

| API | Style | Parameter | Max Page Size |
|-----|-------|-----------|---------------|
| MusicBrainz | Offset | `offset`, `limit` | 100 |
| Setlist.fm | Page | `p` (1-indexed) | 20 |
| JamBase | Cursor | `cursor`, `perPage` | 100 |
| Spotify | Offset | `offset`, `limit` | 50 |
| Ticketmaster | Page | `page`, `size` | 200 |
| Discogs | Page | `page`, `per_page` | 100 |
