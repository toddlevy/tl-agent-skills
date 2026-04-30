# Schema.org Extension Patterns

## When to Extend

Schema.org has 1500+ properties. Before creating an extension, search the properties CSV -- the property you need may already exist under a different name.

## Decision Framework

Work through this hierarchy before adding custom fields:

### Level 1: Use an Existing Property

Check `assets/schemaorg-current-https-properties.csv` for properties that match your need. Schema.org property names are often more generic than you'd expect:

| You need | Schema.org already has |
|----------|----------------------|
| "SKU" | `sku` (on Product) |
| "Stock status" | `availability` (on Offer, with ItemAvailability enum) |
| "Dimensions" | `width`, `height`, `depth` (on Product, VisualArtwork) |
| "Weight" | `weight` (on Product, Person) |
| "Color" | `color` (on Product) |
| "Release year" | `productionDate` or `datePublished` |
| "Headliner" | `performer` (first in array, by convention) |
| "Support acts" | `performer` (subsequent array entries) |

### Level 2: Use `additionalProperty` with PropertyValue

For domain-specific attributes that don't recur often enough to justify a named extension field. This is Schema.org's built-in escape hatch:

```json
"additionalProperty": [
  { "@type": "PropertyValue", "name": "Purity", "value": ".9999" },
  { "@type": "PropertyValue", "name": "Mintage", "value": 50000 },
  { "@type": "PropertyValue", "name": "Face Value", "value": "USD 1.00" },
  { "@type": "PropertyValue", "name": "Finish", "value": "Proof" },
  { "@type": "PropertyValue", "name": "Certification", "value": "NGC MS70" }
]
```

Advantages: fully Schema.org-compliant, no custom vocabulary needed, works with validators.
Disadvantage: less ergonomic for frequently-accessed fields.

### Level 3: `x-` Prefixed Public Extensions

For properties that your API consumers need regularly but Schema.org doesn't define. These become part of your public API contract:

```json
{
  "@type": "Product",
  "name": "2024 American Silver Eagle 1oz",
  "sku": "ase-2024-1oz-bu",
  "x-slug": "american-silver-eagle-2024-1oz",
  "x-abstract": "The flagship US Mint silver bullion coin in brilliant uncirculated finish."
}
```

```json
{
  "@type": "MusicEvent",
  "name": "LCD Soundsystem at Brooklyn Steel",
  "startDate": "2026-09-15T20:00:00-04:00",
  "performer": [
    {
      "@type": "MusicGroup",
      "name": "LCD Soundsystem",
      "x-performanceRank": 1,
      "x-isHeadliner": true
    },
    {
      "@type": "MusicGroup",
      "name": "Automatic",
      "x-performanceRank": 2,
      "x-isHeadliner": false
    }
  ]
}
```

### Level 4: `_x-` Prefixed Internal Extensions

For metadata that internal systems need but should never reach external consumers:

```json
{
  "@type": "Offer",
  "price": "29.95",
  "priceCurrency": "USD",
  "availability": "https://schema.org/InStock",
  "_x-sellerId": "dealer-42",
  "_x-lastChecked": "2026-03-21T04:30:00Z",
  "_x-displayOrder": 3,
  "_x-isActive": true
}
```

These are stripped before public API responses. See the stripping pattern below.

---

## Field Ordering Convention

Schema.org-grounded JSON should order fields predictably. This makes responses scannable and debuggable:

```
Priority 0: @context
Priority 1: @type
Priority 2: Standard Schema.org properties (name, description, url, etc.)
Priority 3: x- prefixed public extensions
Priority 4: _x- prefixed internal extensions
Priority 5: Other underscore-prefixed hidden fields
```

Within each priority tier, maintain original insertion order.

### Implementation (TypeScript)

```typescript
function getFieldPriority(key: string): number {
  if (key === "@context") return 0;
  if (key === "@type") return 1;
  if (key.startsWith("x-")) return 3;
  if (key.startsWith("_x-")) return 4;
  if (key.startsWith("_")) return 5;
  return 2;
}

function orderFields<T extends Record<string, unknown>>(obj: T): T {
  const entries = Object.entries(obj);
  entries.sort((a, b) => getFieldPriority(a[0]) - getFieldPriority(b[0]));
  return Object.fromEntries(entries) as T;
}
```

---

## Stripping Internal Fields

For public API responses, recursively remove `_x-` prefixed fields:

```typescript
function stripInternalFields<T extends Record<string, unknown>>(obj: T): T {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    if (key.startsWith("_x-")) continue;
    if (value !== null && typeof value === "object") {
      if (Array.isArray(value)) {
        result[key] = value.map((item) =>
          item !== null && typeof item === "object" && !Array.isArray(item)
            ? stripInternalFields(item as Record<string, unknown>)
            : item
        );
      } else {
        result[key] = stripInternalFields(value as Record<string, unknown>);
      }
    } else {
      result[key] = value;
    }
  }
  return result as T;
}
```

Combine with field ordering for clean API output:

```typescript
function prepareResponse<T extends Record<string, unknown>>(obj: T): T {
  return stripInternalFields(orderFields(obj));
}
```

---

## External Vocabularies

When Schema.org lacks coverage for your domain, consider established external vocabularies before inventing your own:

| Domain | Vocabulary | URL |
|--------|-----------|-----|
| Supply chain / retail | GS1 Web Vocabulary | https://gs1.org/voc |
| Music ontology | Music Ontology | http://musicontology.com |
| Bibliographic | Dublin Core | https://dublincore.org |
| Scientific datasets | DCAT | https://www.w3.org/ns/dcat |
| Geospatial | GeoSPARQL | http://www.opengis.net/ont/geosparql |

External vocabularies can coexist with Schema.org in a JSON-LD context:

```json
{
  "@context": {
    "@vocab": "https://schema.org/",
    "gs1": "https://gs1.org/voc/"
  },
  "@type": "Product",
  "name": "Example Widget",
  "gs1:netWeight": { "@type": "QuantitativeValue", "value": 250, "unitCode": "GRM" }
}
```

---

## Pending Terms

Schema.org uses a "pending" label for experimental terms. These are real Schema.org terms but may be renamed, restructured, or dropped based on adoption.

### Safe Usage

- Acceptable for internal systems and APIs you control
- Acceptable for JSON-LD on pages you can update quickly
- Risky for third-party integrations or contractual API surfaces
- Pin to a specific Schema.org version in your `assets/VERSION` file if stability matters

### Checking Pending Status

In the types or properties CSV, the `isPartOf` column indicates whether a term is in `https://pending.schema.org` (pending) vs `https://schema.org` (core).
