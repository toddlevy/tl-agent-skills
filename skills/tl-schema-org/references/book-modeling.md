# Book Modeling (Work, Edition, Series)

Books are the canonical case where Schema.org deliberately splits one real-world "book" into more than one entity. Modeling them as a single flat row is the root of most book-catalog defects: merged volumes, format ambiguity, and lost editions. This reference is the full treatment.

## Core Principle

One title is at least two things:

- **The work** -- the abstract creation (title, author, subject). It persists across every printing, translation, and format.
- **The edition** -- a specific manifestation (ISBN, format, publisher, page count, publication year). One work has many editions.

Schema.org models both with the `Book` type, distinguished by relationship:

| Concept | Schema.org | LSC-style table |
|---------|-----------|-----------------|
| Work | `Book` (the abstract one) | `book` |
| Edition | `Book` linked via `bookEdition` | `book_edition` |
| Work -> editions | `workExample` | (reverse of `book_edition.book_id`) |
| Edition -> work | `exampleOfWork` | `book_edition.book_id` FK |
| Series | `BookSeries` | `book_series` |
| Volume membership | `hasPart` / `isPartOf` + `position` | `book.series_id` + `book.volume_position` |
| Contributor | `author`/`editor`/`illustrator`/`about` | `book_contributor` (typed edge) |
| Acquisition | `offers` -> `Offer` | `book_availability` |

This is the `Book`-domain parallel of the `ProductModel`/`Product` + `isVariantOf` pattern in [Database Modeling](database-modeling.md).

---

## 1. The Work / Edition Split

### Why two levels

*The Grateful Dead Family Discography* published in 1984 (hardcover, ISBN A) and reissued in 2003 (paperback, ISBN B) is **one work, two editions**. The author, subject, and title are identical; the ISBN, format, publisher, and page count differ. Flattening this into one row forces you to pick one ISBN and silently discard the other -- or duplicate the work and lose that they are the same book.

### JSON-LD

```json
{
  "@context": "https://schema.org",
  "@type": "Book",
  "@id": "https://example.com/books/family-discography#work",
  "name": "The Grateful Dead Family Discography",
  "author": { "@type": "Person", "name": "Scott W. Allen" },
  "about": { "@type": "MusicGroup", "name": "Grateful Dead" },
  "workExample": [
    {
      "@type": "Book",
      "bookEdition": "1st hardcover",
      "bookFormat": "https://schema.org/Hardcover",
      "isbn": "9780000000001",
      "datePublished": "1984",
      "numberOfPages": 320,
      "publisher": { "@type": "Organization", "name": "Example Press" }
    },
    {
      "@type": "Book",
      "bookEdition": "2003 paperback",
      "bookFormat": "https://schema.org/Paperback",
      "isbn": "9780000000002",
      "datePublished": "2003",
      "numberOfPages": 352
    }
  ]
}
```

Rule: **edition-only properties never appear on the work.** `isbn`, `bookFormat`, `bookEdition`, `numberOfPages`, per-printing `datePublished`, and per-printing `publisher` belong on the edition. `name`, `author`, `about`, and the enduring subject belong on the work.

### DB layout

```sql
CREATE TABLE book (
  id              uuid PRIMARY KEY,
  slug            text UNIQUE NOT NULL,
  title           text NOT NULL,
  subtitle        text,
  category        text NOT NULL,       -- domain enum
  first_published_year integer,        -- earliest edition; the work's "birth"
  subject_summary text,
  series_id       uuid REFERENCES book_series(id),
  volume_position integer,             -- position within the series (1, 2, ...)
  same_as         jsonb,               -- OpenLibrary work key, Wikidata Q, etc.
  created_at_utc  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE book_edition (
  id             uuid PRIMARY KEY,
  book_id        uuid NOT NULL REFERENCES book(id) ON DELETE CASCADE,  -- exampleOfWork
  edition_label  text NOT NULL,        -- bookEdition ("1st", "2003 paperback")
  isbn_10        text,                 -- nullable: pre-ISBN books have none
  isbn_13        text,
  asin           text,                 -- Kindle/ASIN-only editions
  book_format    text,                 -- BookFormatType slug (see section 3)
  publisher      text,
  published_year integer,
  page_count     integer,
  UNIQUE (book_id, edition_label)
);
```

`isbn_10`/`isbn_13`/`asin` are **nullable and never guessed** -- a pre-ISBN or self-published book simply has none. Fabricating an identifier to fill the column is the honesty anti-pattern.

---

## 2. Series & Volumes

A multi-volume set (Vol. I / Vol. II, or "Book One" / "Book Two") is a `BookSeries` whose members are individual `Book` works. Each volume is its own work with its own editions -- **not** one row with "Vols. I-II" in the title.

### JSON-LD

```json
{
  "@context": "https://schema.org",
  "@type": "BookSeries",
  "@id": "https://example.com/series/deadology#series",
  "name": "Deadology",
  "author": { "@type": "Person", "name": "Howard F. Weiner" },
  "hasPart": [
    {
      "@type": "Book",
      "name": "Deadology: The 33 Essential Dates of Grateful Dead History",
      "position": 1,
      "datePublished": "2019"
    },
    {
      "@type": "Book",
      "name": "Deadology Volume II: The Evolution of 33 Grateful Dead Jam Anthems",
      "position": 2,
      "datePublished": "2020"
    }
  ]
}
```

Each volume also carries the inverse:

```json
{
  "@type": "Book",
  "name": "Deadology Volume II: ...",
  "isPartOf": { "@id": "https://example.com/series/deadology#series" },
  "position": 2
}
```

### DB layout

```sql
CREATE TABLE book_series (
  id          uuid PRIMARY KEY,
  slug        text UNIQUE NOT NULL,
  name        text NOT NULL,
  description text
);
```

Each volume's `book.series_id` -> `book_series.id` and `book.volume_position` gives the order. `position`/`volumeNumber` in Schema.org maps to `volume_position`. Serialize the series' `hasPart` by selecting member books ordered by `volume_position`.

**When NOT to use a series:** a single standalone book, or two thematically related but independently-titled books by the same author that were never marketed as a numbered set. `BookSeries` is for an explicit, ordered set (the publisher numbered them), not "books that go together."

---

## 3. Format (BookFormatType)

`bookFormat` is an enumeration on the **edition**, not the work:

| DB value | Schema.org URI |
|----------|---------------|
| `hardcover` | `https://schema.org/Hardcover` |
| `paperback` | `https://schema.org/Paperback` |
| `ebook` | `https://schema.org/EBook` |
| `audiobook` | `https://schema.org/AudiobookFormat` |
| `graphic_novel` | `https://schema.org/GraphicNovel` |

Normalize before lookup (lowercase, strip spaces/hyphens). An audiobook is a format of the same work -- model it as another `book_edition` row with `book_format = 'audiobook'` and (optionally) an `Audiobook`-typed offer, not as a separate work.

---

## 4. Contributors (typed maker/subject edge)

Schema.org gives books several contributor properties. Model them as one typed edge table rather than a column per role, so the set is open and a person can hold multiple roles:

| Role | Schema.org property | Meaning |
|------|--------------------|---------|
| author | `author` | Wrote the work |
| co-author | `author` (multiple) | One of several authors |
| editor | `editor` | Edited an anthology/collection |
| illustrator | `illustrator` | Illustrated it |
| foreword | `contributor` (+ role note) | Wrote the foreword/introduction |
| photographer | `contributor` | Photo books |
| **subject** | `about` | The person the book is **about** (biographies) |

The `subject`/`about` distinction is critical: a biography of Jerry Garcia has Garcia as `about`, not `author`. Conflating "about" with "by" corrupts author facets and attribution.

```sql
CREATE TABLE book_contributor (
  id           uuid PRIMARY KEY,
  book_id      uuid NOT NULL REFERENCES book(id) ON DELETE CASCADE,
  role         text NOT NULL,          -- author | editor | illustrator | foreword | subject | ...
  display_name text NOT NULL,          -- free-text (honest when no linked entity)
  person_id    uuid REFERENCES person(id) ON DELETE SET NULL,  -- linked only when a canonical row exists
  sort_name    text,
  UNIQUE (book_id, role, display_name)
);
```

`person_id` is nullable: link to a canonical `person` only when one exists; otherwise the free-text `display_name` is the honest representation. A person merge sets it null rather than orphaning the book.

---

## 5. Acquisition (Offers), incl. library borrow & read-free

Book acquisition maps to `offers` -> `Offer`, but books have channels beyond "buy" that a naive e-commerce model misses:

| Channel | Schema.org | Notes |
|---------|-----------|-------|
| buy | `Offer` (price + `availability`) | Retail/used purchase |
| borrow | `Offer` with `businessFunction` `LeaseOut`, or a library `lendingLibrary`/`OfferItemCondition` | Controlled digital lending (CDL); the reader borrows, does not own |
| read free | `Offer` with `price` `0` | Public-domain or author-authorized full-text |
| preview | not a full offer | Limited preview only -- model as a plain link, not an availability that implies you can read it |

Model each as one row keyed by `(book_id, channel, host)` so idempotent re-seeds and enrichment sweeps are a no-op, not a duplicate. Include a per-row honesty state (does the URL resolve? was it human-curated or machine-discovered?) so an unverified citation renders differently from a confirmed live link.

```sql
CREATE TABLE book_availability (
  id           uuid PRIMARY KEY,
  book_id      uuid NOT NULL REFERENCES book(id) ON DELETE CASCADE,
  edition_id   uuid REFERENCES book_edition(id) ON DELETE SET NULL,  -- narrow to an edition when known
  channel      text NOT NULL,          -- buy | borrow | read_free | preview
  host         text NOT NULL,          -- display site (openlibrary, archive.org, ...)
  url          text,                   -- nullable: honest absence until confirmed
  existence    text NOT NULL DEFAULT 'unchecked',  -- resolves | absent | unchecked
  basis        text NOT NULL,          -- human | data | none (who/what confirmed it)
  UNIQUE (book_id, channel, host)
);
```

Present only offers that actually resolve as live acquisition paths; keep unconfirmed rows as honest citations rather than promising a reader they can click through.

---

## 6. Structured SSOT over prose (authoring discipline)

If a book catalog's source of truth is prose (Markdown entries scraped by regex into rows), it **will** silently drop books. The failure is structural: any entry shape the scraper does not anticipate -- a grouped multi-title line, unusual punctuation, a volume set -- falls through and is absorbed as body text of the previous entry, with no error.

The durable fix is a **structured SSOT**: author each book as a validated data object (JSON/YAML under a schema, e.g. Zod), then emit seeds deterministically.

- **No silent skips.** A malformed object fails validation loudly; it cannot vanish.
- **Series/volumes are explicit.** `series_slug` + `volume_position` fields, not prose the parser must infer.
- **Diff-reviewable.** Adding a book is adding an object, not hoping a regex matches your sentence.
- **Fail-loud emitter.** The emitter that turns the SSOT into SQL should throw on any object it cannot classify -- never emit a partial/empty seed.

A human-readable prose narrative can remain as research/provenance, but it must not be the machine SSOT.

---

## Anti-Patterns

| Anti-pattern | Why it breaks | Fix |
|--------------|--------------|-----|
| Grouped multi-title entry (`**Book A** and **Book B**` as one record) | A regex scraper grabs one title and silently drops the rest | One object/record per work; validate the count |
| `isbn`/`bookFormat` on the work | ISBN and format are per-edition; the work has many | Put them on the edition (`bookEdition`) |
| Volumes as one row ("Vols. I-II") | Loses per-volume ISBN, year, and orderability | One `Book` per volume + a `BookSeries` with `position` |
| `about` person modeled as `author` | Corrupts author facets and attribution | Typed contributor edge; biography subject is `about` |
| Fabricated ISBN to fill a NOT NULL column | Publishes a false identifier | Make identifier columns nullable; never guess |
| Preview link presented as a readable offer | Implies full access that does not exist | Model preview as a plain link, not an `Offer` |
| Prose Markdown as the machine SSOT | Silent drops on any unanticipated shape | Structured, schema-validated SSOT + fail-loud emitter |

---

## Verification

- [ ] Work and edition are distinct entities (`workExample`/`exampleOfWork` or FK)
- [ ] Edition-only properties (`isbn`, `bookFormat`, `numberOfPages`, per-printing year/publisher) live on the edition
- [ ] Multi-volume sets are a `BookSeries` with one `Book` per volume + `position`
- [ ] `bookFormat` uses `BookFormatType` URIs, on the edition
- [ ] Contributor roles are typed; biography subject is `about`, not `author`
- [ ] Identifier columns are nullable and never fabricated
- [ ] Offers distinguish buy / borrow (CDL) / read-free / preview
- [ ] The catalog SSOT is structured + schema-validated, not prose scraped by regex
- [ ] The seed emitter fails loud on an unclassifiable entry (no silent skip)
