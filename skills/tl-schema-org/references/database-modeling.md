# Schema.org Database Modeling

Schema.org is a vocabulary, not a database schema. Use it as design inspiration -- naming conventions, type relationships, property semantics -- then optimize your tables for your specific query patterns and performance requirements.

## Core Principle

Steal the vocabulary. Design the schema.

Schema.org types map loosely to tables. Schema.org properties map loosely to columns. But relational databases need primary keys, foreign keys, indexes, and normalization that Schema.org's RDF model doesn't address.

---

## Type-to-Table Mapping

### Strategy

Each major Schema.org type becomes a table. Subtypes that share the same structure can merge into a parent table with a discriminator column. Subtypes with significantly different properties get their own table.

### Example: Concert Listings

| Schema.org Type | Table | Discriminator | Notes |
|----------------|-------|---------------|-------|
| Event | `events` | `event_type` (concert, festival) | Base event data |
| Place / MusicVenue | `venues` | -- | Location data |
| PostalAddress | `addresses` | -- | Shared by venues, organizations |
| GeoCoordinates | columns on `venues` | -- | `latitude`, `longitude` directly on venue |
| Person / MusicGroup | `artists` | `artist_type` (person, group) | Merged: similar enough structure |
| Organization | `organizations` | `org_type` (seller, promoter, label) | Ticket sellers, promoters |
| Offer | `offers` | -- | Ticket offers linked to events |

### Example: Collectibles Catalog

| Schema.org Type | Table | Notes |
|----------------|-------|-------|
| Product | `products` | Sellable variants with specific year, finish, weight |
| ProductModel | `base_products` | Canonical product definitions |
| Offer | `offers` | Pricing from multiple sellers |
| Brand / Organization | `issuers` | Mints and manufacturers |
| ProductCollection | `series` | Product lines and series |
| QuantitativeValue | `measurement_types`, `units_of_measure` | Metadata tables for dimensions |

---

## Product Variant Architecture

A pattern for products that exist as a canonical definition (ProductModel) with multiple sellable variants (Product):

```sql
CREATE TABLE base_products (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  content_excerpt TEXT,
  material TEXT,
  image_url TEXT,
  issuer_id UUID REFERENCES issuers(id),
  series_id UUID REFERENCES series(id),
  year INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE products (
  id UUID PRIMARY KEY,
  base_product_id UUID REFERENCES base_products(id),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  year INTEGER,
  weight_id UUID REFERENCES weights(id),
  finish_id UUID REFERENCES finishes(id),
  purity_level_id UUID REFERENCES purity_levels(id),
  mintage INTEGER,
  mintage_is_approximate BOOLEAN DEFAULT FALSE,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

The `isVariantOf` relationship maps to `base_product_id`. At serialization time:

```json
{
  "@type": "Product",
  "isVariantOf": {
    "@type": "ProductModel",
    "@id": "https://example.com/base-products/american-silver-eagle"
  }
}
```

---

## Enum Mapping Tables

Store domain-specific values in the database. Map them to Schema.org enumeration URIs at serialization time.

### Availability Mapping

```sql
-- The database stores descriptive availability values
-- The serializer maps them to Schema.org ItemAvailability URIs
```

| DB Value | Normalized | Schema.org URI |
|----------|-----------|---------------|
| `in_stock` | `instock` | `https://schema.org/InStock` |
| `In Stock` | `instock` | `https://schema.org/InStock` |
| `out_of_stock` | `outofstock` | `https://schema.org/OutOfStock` |
| `pre-order` | `preorder` | `https://schema.org/PreOrder` |
| `back-order` | `backorder` | `https://schema.org/BackOrder` |
| `discontinued` | `discontinued` | `https://schema.org/Discontinued` |
| `limited_availability` | `limitedavailability` | `https://schema.org/LimitedAvailability` |
| `sold_out` | `soldout` | `https://schema.org/SoldOut` |
| `ships_immediately` | `shipsimmediately` | `https://schema.org/InStock` |
| `coming_soon` | `comingsoon` | `https://schema.org/PreOrder` |
| `waitlist` | `waitlist` | `https://schema.org/PreOrder` |

Normalize input before lookup: lowercase, strip hyphens, underscores, and spaces. This handles variant spellings from different data sources without maintaining separate entries for each format.

### Item Condition Mapping

| DB Value | Schema.org URI |
|----------|---------------|
| `new` | `https://schema.org/NewCondition` |
| `bu` / `brilliant-uncirculated` | `https://schema.org/NewCondition` |
| `proof` | `https://schema.org/NewCondition` |
| `used` / `circulated` | `https://schema.org/UsedCondition` |
| `refurbished` | `https://schema.org/RefurbishedCondition` |
| `damaged` | `https://schema.org/DamagedCondition` |

### Event Status Mapping

| DB Value | Schema.org URI |
|----------|---------------|
| `scheduled` | `https://schema.org/EventScheduled` |
| `cancelled` | `https://schema.org/EventCancelled` |
| `postponed` | `https://schema.org/EventPostponed` |
| `rescheduled` | `https://schema.org/EventRescheduled` |
| `moved_online` | `https://schema.org/EventMovedOnline` |

---

## DB-Driven Property Routing

For measurements and dimensions, let the database define which Schema.org property each measurement type maps to.

### Measurement Types Table

```sql
CREATE TABLE measurement_types (
  id UUID PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  schema_org_property TEXT,  -- 'width', 'height', 'depth', or NULL
  display_order INTEGER DEFAULT 0
);
```

When `schema_org_property` is set, the measurement serializes to that Schema.org property directly (e.g., `"width": { "@type": "QuantitativeValue", ... }`).

When `schema_org_property` is `NULL`, the measurement goes into the generic `hasMeasurement` array.

This keeps the mapping data-driven rather than hardcoded in serialization logic.

### Units of Measure Table

```sql
CREATE TABLE units_of_measure (
  code TEXT PRIMARY KEY,       -- UN/CEFACT code (APZ, GRM, MMT, etc.)
  name TEXT NOT NULL,          -- "Troy Ounce", "Gram", "Millimeter"
  symbol TEXT NOT NULL,        -- "oz t", "g", "mm"
  size_system TEXT,            -- 'imperial' or 'metric'
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

The `code` column uses UN/CEFACT recommendation 20 codes, which map directly to `QuantitativeValue.unitCode`:

| Code | Name | Symbol | System |
|------|------|--------|--------|
| APZ | Troy ounce | oz t | imperial |
| GRM | Gram | g | metric |
| KGM | Kilogram | kg | metric |
| ONZ | Ounce (avoirdupois) | oz | imperial |
| LBR | Pound | lb | imperial |
| MMT | Millimeter | mm | metric |
| CMT | Centimeter | cm | metric |
| INH | Inch | in | imperial |
| MTR | Meter | m | metric |

---

## Handling Polymorphic Relationships

Schema.org properties often accept multiple types. `performer` can be a Person or an Organization. `location` can be a Place or a VirtualLocation.

### Discriminator Column Pattern

```sql
CREATE TABLE event_performers (
  id UUID PRIMARY KEY,
  event_id UUID NOT NULL REFERENCES events(id),
  performer_type TEXT NOT NULL,  -- 'person' or 'group'
  performer_id UUID NOT NULL,    -- FK to artists table
  performance_rank INTEGER DEFAULT 0,
  is_headliner BOOLEAN DEFAULT FALSE
);
```

At serialization, the `performer_type` determines the `@type` value:

```json
{
  "performer": [
    { "@type": "MusicGroup", "name": "The Silver Notes" },
    { "@type": "Person", "name": "Diana Monroe" }
  ]
}
```

### Merged Table with Type Discriminator

When Person and MusicGroup share enough structure:

```sql
CREATE TABLE artists (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  artist_type TEXT NOT NULL,  -- 'person' or 'group'
  genre TEXT,
  founding_date DATE,
  founding_location_id UUID REFERENCES places(id),
  image_url TEXT,
  website TEXT
);
```

---

## Identifier Strategy

| Column | Purpose | Schema.org Mapping |
|--------|---------|--------------------|
| `id` | Internal primary key (UUID v7) | Not exposed directly |
| `slug` | URL-friendly identifier | `identifier`, `sku` |
| `url` | Canonical web URL | `url` |
| `same_as` | Array of URLs on other platforms | `sameAs` |

### External Identifier Pattern

For entities that exist across multiple external systems:

```sql
CREATE TABLE external_identifiers (
  id UUID PRIMARY KEY,
  entity_type TEXT NOT NULL,     -- 'artist', 'venue', 'event'
  entity_id UUID NOT NULL,
  source TEXT NOT NULL,          -- 'ticketmaster', 'musicbrainz', 'spotify'
  external_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(entity_type, entity_id, source)
);
```

Serializes to:

```json
"x-externalIdentifiers": [
  { "source": "ticketmaster", "identifier": "K8vZ9175st0" },
  { "source": "musicbrainz", "identifier": "f59c5520-5f46-4d2c-b2c4-822eabf53419" }
]
```

---

## Column Naming Conventions

Prefer Schema.org property names for columns where the mapping is direct:

| Schema.org Property | Column Name | Notes |
|--------------------|-------------|-------|
| `name` | `name` | Direct match |
| `description` | `description` | Direct match |
| `startDate` | `start_date` | Snake_case adaptation |
| `endDate` | `end_date` | Snake_case adaptation |
| `streetAddress` | `street_address` | Snake_case adaptation |
| `addressLocality` | `address_locality` | Snake_case adaptation |
| `postalCode` | `postal_code` | Snake_case adaptation |
| `priceCurrency` | `currency_code` | Adapted for DB conventions |
| `eventStatus` | `status` | Simplified when context is clear |
| `eventAttendanceMode` | `attendance_mode` | Simplified |

This makes the mapping between database and JSON-LD output transparent and reduces cognitive overhead.
