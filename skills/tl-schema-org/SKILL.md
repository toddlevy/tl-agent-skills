---
name: tl-schema-org
description: >
  The full Schema.org vocabulary -- all 800+ types, 1500+ properties -- with production patterns
  for JSON-LD rendering, database modeling, API interoperability, extension governance, and rich results.
  Not just SEO markup. Use when working with structured data, Schema.org types, JSON-LD, or
  designing data models and APIs grounded in Schema.org.
license: MIT
metadata:
  author: tl-agent-skills
  version: "1.0"
quilted:
  version: 1
  synthesized: 2026-03-21
  sources:
    - url: https://playbooks.com/skills/openclaw/skills/schema-markup
      borrowed: ["Validation checklist", "Common errors table", "React component pattern"]
      weight: 0.25
    - url: https://playbooks.com/skills/openclaw/skills/schema-markup-generator
      borrowed: ["Schema type decision tree", "Rich result eligibility matrix", "Implementation workflow"]
      weight: 0.25
    - url: https://schema.org/docs/
      borrowed: ["Data model", "Extension docs", "Conformance guidance", "Machine-readable files"]
      weight: 0.25
    - url: https://developers.google.com/search/docs/appearance/structured-data
      borrowed: ["Required vs recommended properties", "Quality guidelines"]
      weight: 0.10
    - url: https://w3c.github.io/json-ld-bp/
      borrowed: ["@id/@graph patterns", "Vocabulary reuse", "API integration"]
      weight: 0.15
  enhancements:
    - "Full taxonomy coverage via machine-readable data files (1245 core types, 1532 core properties, plus 632 enum members and 460 pending terms)"
    - "Database modeling patterns for Schema.org-grounded relational design"
    - "API interoperability patterns with OpenAPI type hierarchy mirroring"
    - "Two-tier extension system (x- public / _x- internal) with field ordering and stripping"
    - "Enum mapping tables for availability/condition with normalization"
    - "DB-driven schemaOrgProperty for measurement-to-property routing"
    - "Version tracking and governance workflow"
---

# Schema.org

Work fluently with the entire Schema.org vocabulary -- types, properties, enumerations, and their relationships -- across every surface where structured data matters: web pages, databases, APIs, and data interchange.

## When to Use

- "Add structured data to a page"
- "Map Schema.org types to a database"
- "Design an API using Schema.org vocabulary"
- "Extend Schema.org with custom properties"
- "Which Schema.org type should I use for X?"
- "Validate structured data markup"
- Working with JSON-LD, RDFa, or any semantic/linked-data integration
- Building data models grounded in a shared vocabulary

## Outcomes

- **Artifact**: JSON-LD markup, database schemas, API type definitions, or extension specifications aligned to Schema.org
- **Decision**: Type selection, extension strategy, rendering approach, or validation plan

---

## 1. Schema.org Fundamentals

Schema.org is a collaborative vocabulary of **800+ types and 1500+ properties** maintained by Google, Microsoft, Yahoo, and Yandex. It is not a rigid ontology -- it follows Postel's Law: be liberal in what you accept, conservative in what you produce.

### Data Model

- **Types** form a hierarchy rooted at `Thing`. A type can have multiple parent types (multiple inheritance).
- **Properties** have one or more domain types (where they can appear) and one or more range types (what values they accept).
- **Enumerations** are types whose instances are a fixed set of members (e.g., `ItemAvailability` has `InStock`, `OutOfStock`, etc.).
- Conformance is pragmatic: search engines accept text strings where a type is expected, and properties can appear on types outside their declared domain.

### Hierarchy at a Glance

Everything descends from `Thing`. The major branches:

| Branch | Key Types | Typical Use |
|--------|-----------|-------------|
| Action | AchieveAction, TradeAction, SearchAction | User interactions, deep linking |
| CreativeWork | Article, Book, MusicComposition, SoftwareApplication | Content, media, publications |
| Event | MusicEvent, SportsEvent, Festival | Happenings with dates and locations |
| Intangible | Offer, Order, Rating, StructuredValue | Commerce, measurements, abstract concepts |
| MedicalEntity | MedicalCondition, Drug, MedicalProcedure | Health and medical content |
| Organization | Corporation, LocalBusiness, SportsTeam | Entities with structure and identity |
| Person | -- | People with roles and relationships |
| Place | MusicVenue, Restaurant, City, Country | Physical and administrative locations |
| Product | ProductModel, ProductGroup, Vehicle | Tangible goods and variants |
| BioChemEntity | Gene, Protein, MolecularEntity | Life sciences |

For the complete hierarchy, see `data/tree.jsonld`. For type/property lookup, query `data/schemaorg-current-https-types.csv` and `data/schemaorg-current-https-properties.csv`.

See: `references/taxonomy-guide.md`

### Domain Clusters

Common verticals and their Schema.org type constellations:

| Vertical | Primary Types | Supporting Types |
|----------|---------------|------------------|
| E-commerce | Product, Offer, AggregateOffer | Brand, Organization, QuantitativeValue, SizeSpecification |
| Events | Event, MusicEvent, Festival | Place, PostalAddress, GeoCoordinates, Offer, Person |
| Publishing | Article, BlogPosting, NewsArticle | Person, Organization, ImageObject, WebPage |
| Jobs | JobPosting | Organization, Place, MonetaryAmount |
| Local Business | LocalBusiness, Restaurant | PostalAddress, GeoCoordinates, OpeningHoursSpecification |
| Education | Course, LearningResource | Organization, Person, Offer |
| Recipes | Recipe | NutritionInformation, HowToStep, ImageObject |
| Collectibles | Product, ProductModel, ProductGroup | Offer, Brand, QuantitativeValue, PropertyValue |
| Music | MusicGroup, MusicEvent, MusicComposition | Person, Place, Offer, MusicAlbum |

---

## 2. JSON-LD Rendering

JSON-LD is the recommended format for structured data on web pages. It separates structured data from HTML, making it easier to maintain and less coupled to markup changes.

### Core Patterns

**Single entity:**

```json
{
  "@context": "https://schema.org",
  "@type": "Event",
  "name": "Summer Jazz Festival",
  "startDate": "2026-07-15T19:00:00-05:00",
  "location": {
    "@type": "MusicVenue",
    "name": "Riverside Amphitheater",
    "address": {
      "@type": "PostalAddress",
      "streetAddress": "100 River Road",
      "addressLocality": "Austin",
      "addressRegion": "TX",
      "postalCode": "78701",
      "addressCountry": "US"
    }
  }
}
```

**Multi-entity with `@graph` and `@id` cross-references:**

```json
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://example.com/#org",
      "name": "Riverside Concerts",
      "url": "https://example.com"
    },
    {
      "@type": "WebSite",
      "@id": "https://example.com/#site",
      "name": "Riverside Concerts",
      "url": "https://example.com",
      "publisher": { "@id": "https://example.com/#org" }
    },
    {
      "@type": "Event",
      "name": "Summer Jazz Festival",
      "organizer": { "@id": "https://example.com/#org" }
    }
  ]
}
```

**Multi-type entities** (an item that is simultaneously two types):

```json
{
  "@context": "https://schema.org",
  "@type": ["Book", "Product"],
  "name": "The Complete Jazz Standards",
  "isbn": "978-0-123456-78-9",
  "offers": { "@type": "Offer", "price": "29.95", "priceCurrency": "USD" }
}
```

### Enumeration Values

Always use full Schema.org URIs for enumeration values:

```json
"availability": "https://schema.org/InStock",
"eventStatus": "https://schema.org/EventScheduled",
"itemCondition": "https://schema.org/NewCondition",
"eventAttendanceMode": "https://schema.org/OfflineEventAttendanceMode"
```

### Placement and Rendering

- Place JSON-LD in `<head>` or before `</body>` inside `<script type="application/ld+json">`
- For SSR: build the structured data object in your route handler or `getMetaTags`-style function, then inject it into the HTML template as a single script tag
- For SPAs: inject dynamically via `useEffect` or equivalent lifecycle hook
- One `<script type="application/ld+json">` tag per page is cleanest; use `@graph` to combine multiple entities

See: `references/json-ld-patterns.md`

---

## 3. Extension Patterns

Schema.org is intentionally incomplete. Real-world domains always have properties that the vocabulary doesn't cover. The question is how to handle them.

### Decision Framework

Before extending, work through this hierarchy:

1. **Use an existing property.** Check the CSV data files -- Schema.org has 1500+ properties. The one you need may already exist under a different name.
2. **Use `additionalProperty` with `PropertyValue`.** For domain-specific attributes that don't justify a custom field (purity, mintage, face value, finish):
   ```json
   "additionalProperty": [
     { "@type": "PropertyValue", "name": "Purity", "value": ".9999" },
     { "@type": "PropertyValue", "name": "Mintage", "value": 50000 }
   ]
   ```
3. **Use `x-` prefixed extensions** for properties that consumers of your data need but Schema.org doesn't define. These are public, part of your API contract.
4. **Use `_x-` prefixed extensions** for internal/admin-only fields that should never reach external consumers.

### Two-Tier Extension Convention

| Prefix | Visibility | Purpose | Example |
|--------|-----------|---------|---------|
| `x-` | Public | Consumer-facing domain extensions | `x-abstract`, `x-slug`, `x-headliner` |
| `_x-` | Internal | Admin, debug, pipeline metadata | `_x-displayOrder`, `_x-lastChecked`, `_x-sellerId` |

### Field Ordering

Schema.org-grounded JSON responses should order fields predictably:

| Priority | Category | Example |
|----------|----------|---------|
| 0 | `@context` | `"https://schema.org"` |
| 1 | `@type` | `"Product"` |
| 2 | Standard Schema.org properties | `name`, `description`, `offers` |
| 3 | `x-` public extensions | `x-slug`, `x-abstract` |
| 4 | `_x-` internal extensions | `_x-displayOrder` |
| 5 | Other hidden fields | `_internal`, `_hidden` |

### Stripping Internal Fields

For public API responses, recursively remove `_x-` prefixed fields. This keeps your internal metadata (display order, pipeline timestamps, seller IDs) out of consumer-facing payloads while preserving them for admin/debug endpoints.

### External Vocabularies

When Schema.org genuinely lacks coverage for your domain, consider established external vocabularies (e.g., `gs1.org/voc` for supply chain, `musicontology.com` for music) before inventing your own. These can coexist with Schema.org in a JSON-LD context.

### Pending Terms

Schema.org uses a "pending" label for experimental terms. These are safe to use but may be renamed, restructured, or dropped. Pin to a specific Schema.org version if stability matters.

See: `references/extension-patterns.md`

---

## 4. Database Modeling

Schema.org is a vocabulary, not a database schema. Use it as design inspiration and naming convention, not as a direct table mapping. Relational databases need primary keys, foreign keys, and normalized structures that Schema.org's RDF-based model doesn't address.

### Type-to-Table Mapping

Map Schema.org types to tables, but optimize for your query patterns:

| Schema.org Type | Table | Key Columns |
|----------------|-------|-------------|
| Product | `products` | `id`, `name`, `slug`, `sku`, `description`, `material`, `production_date` |
| ProductModel | `base_products` | `id`, `name`, `slug`, `description` (canonical product definition) |
| Offer | `offers` | `id`, `product_id`, `price`, `currency_code`, `availability`, `condition_slug` |
| Organization | `sellers`, `issuers` | `id`, `name`, `slug`, `url`, `country_code` |
| Place / MusicVenue | `venues` | `id`, `name`, `address_id`, `latitude`, `longitude`, `capacity` |
| Event / MusicEvent | `events` | `id`, `name`, `start_date`, `end_date`, `venue_id`, `status` |
| Person / MusicGroup | `artists` | `id`, `name`, `slug`, `type` (person or group) |

### Product Variant Architecture

Use `ProductModel` as the canonical/base product and `Product` as the sellable variant. Link them with `isVariantOf`:

- `base_products` table: canonical definition (name, description, material, weight)
- `products` table: sellable variants with `base_product_id` FK, year, finish, specific weight
- JSON-LD output uses `"isVariantOf": { "@type": "ProductModel", "@id": "..." }`

### Enum Mapping Tables

Store domain-specific values in the database and map them to Schema.org enumeration URIs at serialization time:

```sql
-- Availability values mapped to Schema.org ItemAvailability
-- DB stores: 'instock', 'preorder', 'backorder', 'soldout', etc.
-- Serializer maps to: 'https://schema.org/InStock', 'https://schema.org/PreOrder', etc.
```

Normalize input values before lookup (lowercase, strip hyphens/underscores/spaces) to handle variant spellings from different data sources.

### DB-Driven Property Routing

For measurements and dimensions, let the database define which Schema.org property each measurement maps to. A `measurement_types` table with a `schema_org_property` column (`width`, `height`, `depth`, or `null` for generic `hasMeasurement`) keeps this mapping data-driven rather than hardcoded.

### Unit Codes

Use UN/CEFACT codes for `QuantitativeValue.unitCode`:

| Unit | Code | unitText |
|------|------|----------|
| Troy ounce | APZ | oz t |
| Gram | GRM | g |
| Kilogram | KGM | kg |
| Millimeter | MMT | mm |
| Centimeter | CMT | cm |
| Inch | INH | in |

### Identifier Strategy

| Column | Purpose | Schema.org Mapping |
|--------|---------|--------------------|
| `id` | Internal primary key (UUID) | -- |
| `slug` | URL-friendly identifier | `identifier`, `sku` |
| `external_ids` | IDs from other systems | `sameAs`, `identifier` with PropertyValue |
| `url` | Canonical web URL | `url` |

See: `references/database-modeling.md`

---

## 5. API Interoperability

Schema.org provides a shared vocabulary that makes APIs interoperable without requiring full JSON-LD compliance. The spectrum runs from "Schema.org-inspired property names" to "full JSON-LD responses."

### OpenAPI Type Hierarchy

Mirror Schema.org's inheritance in OpenAPI using `allOf`:

```yaml
Thing:
  type: object
  properties:
    name: { type: string }
    identifier: { type: string }
    url: { type: string }
    image: { type: string }
    sameAs: { type: array, items: { type: string } }
    datePublished: { type: string, format: date-time }
    dateModified: { type: string, format: date-time }

Event:
  allOf:
    - $ref: '#/components/schemas/Thing'
    - type: object
      properties:
        startDate: { type: string, format: date-time }
        endDate: { type: string, format: date-time }
        eventStatus: { type: string }
        location: { $ref: '#/components/schemas/Place' }
        offers: { type: array, items: { $ref: '#/components/schemas/Offer' } }
        performer: { type: array, items: { $ref: '#/components/schemas/Person' } }
```

### Response Format Spectrum

| Approach | `@context` | `@type` | When to Use |
|----------|-----------|---------|-------------|
| Full JSON-LD | Yes | Yes | Public APIs consumed by search engines, AI systems, or linked-data clients |
| Schema.org-inspired | No | Yes | Internal/partner APIs that benefit from shared vocabulary without RDF overhead |
| Property names only | No | No | APIs that use Schema.org naming conventions for interoperability |

### Cross-System Identifier Mapping

When your entities exist in multiple systems, use structured external identifiers:

```json
"x-externalIdentifiers": [
  { "source": "ticketmaster", "identifier": "K8vZ9175st0" },
  { "source": "musicbrainz", "identifier": "f59c5520-5f46-4d2c-b2c4-822eabf53419" }
]
```

This enables cross-service resolution without coupling to any single provider's ID scheme. Use `sameAs` for canonical web URLs of the same entity on other platforms.

See: `references/api-interoperability.md`

---

## 6. Rich Results and SEO

Structured data enables rich results in search engines -- FAQ dropdowns, star ratings, product cards, event listings. This is the most visible consumer of Schema.org markup.

### Required vs Recommended

Each rich result type has required and recommended properties. Missing a required property suppresses the entire rich result. The more recommended properties you include, the higher quality the result.

| Type | Required | Recommended |
|------|----------|-------------|
| Product | name, image, offers (with price + availability) | brand, aggregateRating, review, sku |
| Article | headline, image, datePublished, author | dateModified, publisher, description |
| Event | name, startDate, location | endDate, offers, performer, image, eventStatus |
| FAQPage | mainEntity (Question/Answer array) | -- |
| LocalBusiness | name, address | geo, openingHours, telephone, aggregateRating |
| Recipe | name, image | cookTime, nutrition, recipeIngredient, recipeInstructions |

### Validation Workflow

1. **Build**: Generate JSON-LD from your data model
2. **Validate syntax**: Ensure valid JSON (no trailing commas, proper quoting)
3. **Validate schema**: Use https://validator.schema.org/ for Schema.org compliance
4. **Validate rich results**: Use Google Rich Results Test for search eligibility
5. **Monitor**: Watch Search Console Enhancement reports for ongoing issues

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Missing required field | Required property omitted | Check per-type requirements |
| Invalid URL | Relative path or malformed | Use fully qualified `https://` URLs |
| Invalid date | Not ISO 8601 | Use `YYYY-MM-DDTHH:MM:SS+00:00` |
| Invalid enum value | Bare string instead of URI | Use `https://schema.org/InStock`, not `InStock` |
| Content mismatch | Schema data doesn't match visible page content | Ensure schema reflects what users see |
| Invalid price | Currency symbol or commas | Use numeric string only (`"149.99"`) |

### Quality Rules

- Schema must accurately represent visible page content
- Do not mark up content that doesn't exist on the page
- Keep dynamic values (prices, availability, ratings) current
- Do not use structured data to deceive or mislead

See: `references/rich-results.md`

---

## 7. Version Tracking and Governance

Schema.org publishes numbered releases every few weeks. The vocabulary grows but rarely removes terms -- deprecated types move to an "attic" rather than being deleted.

### Tracking Releases

Run `scripts/update-schema-data.sh` (or `.ps1`) to download the latest release files into `data/`. The script writes a `data/VERSION` file with the version number and date.

### Diffing Changes

Compare CSV files between versions to identify:
- New types or properties added
- Properties gaining new domain or range types
- Terms moving from "pending" to core (or to attic)

### Impact Assessment

| Change Type | Risk | Action |
|-------------|------|--------|
| New type added | None | Evaluate for relevance to your domain |
| New property on existing type | Low | Consider adopting if it replaces an `x-` extension |
| Property range expanded | Low | May enable richer data modeling |
| Term moved to attic | Medium | Plan migration if you use it |
| Property renamed | High | Rare, but requires coordinated update |

### When Your Extension Becomes Official

If Schema.org adds a property that matches one of your `x-` extensions, migrate: emit both the standard property and the `x-` extension during a transition period, then drop the extension.

See: `references/version-tracking.md`

---

## Verification

### Structured Data Implementation

- [ ] JSON-LD is valid JSON (syntax check)
- [ ] `@context` is `"https://schema.org"`
- [ ] `@type` uses correct Schema.org type name
- [ ] Enumeration values use full URIs
- [ ] All required properties for target rich results are present
- [ ] Dates use ISO 8601 format
- [ ] URLs are fully qualified
- [ ] Content matches visible page content
- [ ] Validates in Schema.org Validator without errors

### Database Model Alignment

- [ ] Table names correspond to Schema.org types
- [ ] Column names use Schema.org property names where applicable
- [ ] Enum mapping tables cover all domain values
- [ ] Polymorphic relationships handled (e.g., performer: Person | Organization)
- [ ] Identifier strategy supports internal IDs, slugs, and external system IDs

### API Interoperability

- [ ] Response types mirror Schema.org type hierarchy
- [ ] Property names match Schema.org vocabulary
- [ ] Extension fields use `x-` prefix convention
- [ ] Internal fields use `_x-` prefix and are stripped from public responses
- [ ] Field ordering follows convention (@context > @type > standard > x- > _x-)

### Extension Governance

- [ ] Existing Schema.org properties checked before creating extensions
- [ ] `additionalProperty` used for one-off domain attributes
- [ ] `x-` prefix used for recurring public extensions
- [ ] `_x-` prefix used for internal-only fields
- [ ] External vocabularies considered for domain-specific gaps
