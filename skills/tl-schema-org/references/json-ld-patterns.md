# JSON-LD Patterns

## 1. Single Entity (Minimal)

The simplest valid JSON-LD. One entity, no nesting:

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Riverside Concerts",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png"
}
```

## 2. Nested Entities

Entities within entities. The inner objects inherit the `@context` from the root:

```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "2024 Silver Eagle 1oz BU",
  "sku": "ase-2024-1oz-bu",
  "brand": {
    "@type": "Brand",
    "name": "US Mint"
  },
  "offers": {
    "@type": "Offer",
    "price": "32.50",
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock",
    "seller": {
      "@type": "Organization",
      "name": "Metro Coins",
      "url": "https://example.com"
    }
  }
}
```

## 3. `@graph` with Multiple Top-Level Entities

When a page describes several independent entities, use `@graph` to group them in a single `<script>` tag:

```json
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://example.com/#org",
      "name": "Riverside Concerts",
      "url": "https://example.com",
      "logo": "https://example.com/logo.png",
      "sameAs": [
        "https://twitter.com/riversideconcerts",
        "https://instagram.com/riversideconcerts"
      ]
    },
    {
      "@type": "WebSite",
      "@id": "https://example.com/#site",
      "name": "Riverside Concerts",
      "url": "https://example.com",
      "publisher": { "@id": "https://example.com/#org" }
    },
    {
      "@type": "BreadcrumbList",
      "itemListElement": [
        { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com" },
        { "@type": "ListItem", "position": 2, "name": "Events", "item": "https://example.com/events" }
      ]
    }
  ]
}
```

## 4. `@id` Cross-References

Define an entity once with `@id`, reference it elsewhere. This avoids duplication and creates a coherent graph:

```json
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "MusicVenue",
      "@id": "https://example.com/venues/riverside-amphitheater",
      "name": "Riverside Amphitheater",
      "maximumAttendeeCapacity": 5000,
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "100 River Road",
        "addressLocality": "Austin",
        "addressRegion": "TX",
        "postalCode": "78701",
        "addressCountry": "US"
      },
      "geo": {
        "@type": "GeoCoordinates",
        "latitude": 30.2672,
        "longitude": -97.7431
      }
    },
    {
      "@type": "MusicEvent",
      "name": "Summer Jazz Festival",
      "startDate": "2026-07-15T19:00:00-05:00",
      "endDate": "2026-07-15T23:00:00-05:00",
      "eventStatus": "https://schema.org/EventScheduled",
      "eventAttendanceMode": "https://schema.org/OfflineEventAttendanceMode",
      "location": { "@id": "https://example.com/venues/riverside-amphitheater" },
      "performer": [
        { "@type": "MusicGroup", "name": "The Silver Notes" },
        { "@type": "Person", "name": "Diana Monroe" }
      ],
      "offers": {
        "@type": "Offer",
        "price": "45.00",
        "priceCurrency": "USD",
        "availability": "https://schema.org/InStock",
        "validFrom": "2026-05-01T10:00:00-05:00",
        "url": "https://example.com/events/summer-jazz/tickets"
      }
    }
  ]
}
```

## 5. Multi-Type Entities

When something genuinely belongs to two types simultaneously:

```json
{
  "@context": "https://schema.org",
  "@type": ["Book", "Product"],
  "name": "The Complete Jazz Standards Fake Book",
  "isbn": "978-0-123456-78-9",
  "author": { "@type": "Person", "name": "Charles Mingus Jr." },
  "offers": {
    "@type": "Offer",
    "price": "29.95",
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock"
  }
}
```

Common multi-type combos: `["Book", "Product"]`, `["LocalBusiness", "Restaurant"]`, `["MusicEvent", "Festival"]`.

## 6. Enumeration Values as Full URIs

Always use the full Schema.org URI for enumeration members:

```json
{
  "@type": "Offer",
  "availability": "https://schema.org/InStock",
  "itemCondition": "https://schema.org/NewCondition"
}
```

```json
{
  "@type": "Event",
  "eventStatus": "https://schema.org/EventScheduled",
  "eventAttendanceMode": "https://schema.org/MixedEventAttendanceMode"
}
```

Never use bare strings like `"InStock"` or `"NewCondition"`.

## 7. Product with Variant Architecture

Base product (canonical definition) with sellable variants:

```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "2024 American Silver Eagle 1oz Proof",
  "sku": "ase-2024-1oz-proof",
  "isVariantOf": {
    "@type": "ProductModel",
    "@id": "https://example.com/base-products/american-silver-eagle",
    "name": "American Silver Eagle"
  },
  "material": "Silver",
  "productionDate": "2024",
  "brand": { "@type": "Brand", "name": "US Mint" },
  "weight": {
    "@type": "QuantitativeValue",
    "value": 1.0,
    "unitCode": "APZ",
    "unitText": "oz t"
  },
  "additionalProperty": [
    { "@type": "PropertyValue", "name": "Purity", "value": ".999" },
    { "@type": "PropertyValue", "name": "Finish", "value": "Proof" },
    { "@type": "PropertyValue", "name": "Face Value", "value": "USD 1.00" }
  ],
  "offers": [
    {
      "@type": "Offer",
      "price": "59.95",
      "priceCurrency": "USD",
      "availability": "https://schema.org/InStock",
      "itemCondition": "https://schema.org/NewCondition",
      "seller": { "@type": "Organization", "name": "Silver Direct" }
    }
  ]
}
```

## 8. SizeSpecification and QuantitativeValue

For products with physical dimensions, use `SizeSpecification` for the size system and `QuantitativeValue` for individual measurements:

```json
{
  "@type": "Product",
  "name": "2024 Gold Maple Leaf 1oz",
  "size": {
    "@type": "SizeSpecification",
    "sizeSystem": "https://schema.org/SizeSystemMetric",
    "hasMeasurement": [
      {
        "@type": "QuantitativeValue",
        "value": 1.0,
        "unitCode": "APZ",
        "unitText": "oz t"
      }
    ]
  },
  "weight": {
    "@type": "QuantitativeValue",
    "value": 31.1,
    "unitCode": "GRM",
    "unitText": "g"
  },
  "width": {
    "@type": "QuantitativeValue",
    "value": 30.0,
    "unitCode": "MMT",
    "unitText": "mm"
  },
  "depth": {
    "@type": "QuantitativeValue",
    "value": 2.87,
    "unitCode": "MMT",
    "unitText": "mm"
  }
}
```

## 9. FAQPage

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is the difference between proof and BU coins?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Proof coins are struck multiple times with polished dies, creating a mirror-like finish. Brilliant Uncirculated (BU) coins are standard production strikes with a satin luster."
      }
    },
    {
      "@type": "Question",
      "name": "How do I store silver coins?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Store in a cool, dry environment in acid-free holders or capsules. Avoid PVC-based flips which can damage the surface over time."
      }
    }
  ]
}
```

## 10. Article with Full Metadata

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Understanding the 2026 Concert Season",
  "image": "https://example.com/images/concert-season-2026.jpg",
  "datePublished": "2026-03-15T09:00:00-05:00",
  "dateModified": "2026-03-20T14:30:00-05:00",
  "author": {
    "@type": "Person",
    "name": "Jamie Rivera",
    "url": "https://example.com/authors/jamie-rivera"
  },
  "publisher": {
    "@type": "Organization",
    "@id": "https://example.com/#org",
    "name": "Music Daily",
    "logo": {
      "@type": "ImageObject",
      "url": "https://example.com/logo.png"
    }
  },
  "description": "A look at the biggest tours and festivals planned for 2026.",
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://example.com/articles/concert-season-2026"
  }
}
```

## 11. ItemList (Search Results, Catalog Pages)

```json
{
  "@context": "https://schema.org",
  "@type": "ItemList",
  "name": "Top Silver Coins for Investment",
  "numberOfItems": 3,
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "item": {
        "@type": "Product",
        "name": "American Silver Eagle",
        "url": "https://example.com/products/american-silver-eagle"
      }
    },
    {
      "@type": "ListItem",
      "position": 2,
      "item": {
        "@type": "Product",
        "name": "Canadian Silver Maple Leaf",
        "url": "https://example.com/products/canadian-silver-maple-leaf"
      }
    },
    {
      "@type": "ListItem",
      "position": 3,
      "item": {
        "@type": "Product",
        "name": "Austrian Silver Philharmonic",
        "url": "https://example.com/products/austrian-silver-philharmonic"
      }
    }
  ]
}
```

## 12. SearchAction (Sitelinks Search Box)

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Coin Catalog",
  "url": "https://example.com",
  "potentialAction": {
    "@type": "SearchAction",
    "target": {
      "@type": "EntryPoint",
      "urlTemplate": "https://example.com/search?q={search_term_string}"
    },
    "query-input": "required name=search_term_string"
  }
}
```

---

## Framework Rendering Patterns

### React / SSR Component

```tsx
interface JsonLdProps {
  data: Record<string, unknown> | Record<string, unknown>[];
}

function JsonLd({ data }: JsonLdProps) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}
```

### SSR HTML Template Injection

Build structured data in your route handler, then inject into the HTML shell:

```typescript
function renderHtmlTemplate(content: string, structuredData?: object): string {
  const schemaScript = structuredData
    ? `<script type="application/ld+json" id="structured-data">${JSON.stringify(structuredData)}</script>`
    : "";
  return `<!DOCTYPE html>
<html>
<head>${schemaScript}</head>
<body>${content}</body>
</html>`;
}
```

### SPA Dynamic Injection

For client-side rendering where structured data depends on fetched data:

```typescript
function injectStructuredData(data: object): void {
  const existing = document.getElementById("structured-data");
  if (existing) existing.remove();

  const script = document.createElement("script");
  script.type = "application/ld+json";
  script.id = "structured-data";
  script.textContent = JSON.stringify(data);
  document.head.appendChild(script);
}
```

---

## Common Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Bare enum values (`"InStock"`) | Validators warn; some consumers can't resolve | Use full URI: `"https://schema.org/InStock"` |
| Relative URLs in `image` or `url` | Search engines can't resolve | Use fully qualified `https://` URLs |
| Multiple `<script type="application/ld+json">` tags | Fragmented graph, harder to debug | Use single tag with `@graph` |
| Hardcoded dates that aren't updated | Content mismatch penalty | Generate from database values |
| Schema for content not on page | Violates Google guidelines | Only mark up visible content |
| Missing `@context` on nested objects | Valid, but confusing when reading | Put `@context` on root only |
| Using `@id` without pairing with `url` | Cross-page references won't resolve | Include both `@id` and `url` |
