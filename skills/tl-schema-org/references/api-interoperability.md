# Schema.org API Interoperability

Schema.org provides a shared vocabulary that makes APIs interoperable without requiring full JSON-LD compliance. The spectrum runs from "use Schema.org property names" to "serve full JSON-LD responses."

---

## OpenAPI Type Hierarchy

Mirror Schema.org's type hierarchy in OpenAPI using `allOf` for inheritance. This gives you type reuse, consistent naming, and a clear relationship between your API types and the universal vocabulary.

### Base Type: Thing

```yaml
components:
  schemas:
    Thing:
      type: object
      properties:
        name:
          type: string
        identifier:
          type: string
        url:
          type: string
          format: uri
        image:
          type: string
          format: uri
        description:
          type: string
        sameAs:
          type: array
          items:
            type: string
            format: uri
        datePublished:
          type: string
          format: date-time
        dateModified:
          type: string
          format: date-time
```

### Extending Thing

```yaml
    Event:
      allOf:
        - $ref: '#/components/schemas/Thing'
        - type: object
          properties:
            startDate:
              type: string
              format: date-time
            endDate:
              type: string
              format: date-time
            eventStatus:
              type: string
              enum:
                - https://schema.org/EventScheduled
                - https://schema.org/EventCancelled
                - https://schema.org/EventPostponed
                - https://schema.org/EventRescheduled
                - https://schema.org/EventMovedOnline
            eventAttendanceMode:
              type: string
              enum:
                - https://schema.org/OfflineEventAttendanceMode
                - https://schema.org/OnlineEventAttendanceMode
                - https://schema.org/MixedEventAttendanceMode
            location:
              $ref: '#/components/schemas/Place'
            performer:
              type: array
              items:
                $ref: '#/components/schemas/Person'
            offers:
              type: array
              items:
                $ref: '#/components/schemas/Offer'

    MusicEvent:
      allOf:
        - $ref: '#/components/schemas/Event'
        - type: object
          properties:
            x-headlinerInSupport:
              type: boolean
            x-promoImage:
              type: string
              format: uri
```

### Supporting Types

```yaml
    Place:
      allOf:
        - $ref: '#/components/schemas/Thing'
        - type: object
          properties:
            address:
              $ref: '#/components/schemas/PostalAddress'
            geo:
              $ref: '#/components/schemas/GeoCoordinates'
            maximumAttendeeCapacity:
              type: integer

    PostalAddress:
      type: object
      properties:
        streetAddress:
          type: string
        addressLocality:
          type: string
        addressRegion:
          type: string
        postalCode:
          type: string
        addressCountry:
          type: string

    GeoCoordinates:
      type: object
      properties:
        latitude:
          type: number
        longitude:
          type: number

    Offer:
      type: object
      properties:
        price:
          type: string
        priceCurrency:
          type: string
        availability:
          type: string
        itemCondition:
          type: string
        validFrom:
          type: string
          format: date-time
        url:
          type: string
          format: uri
        seller:
          $ref: '#/components/schemas/Organization'

    Organization:
      allOf:
        - $ref: '#/components/schemas/Thing'
        - type: object
          properties:
            logo:
              type: string
              format: uri

    Person:
      allOf:
        - $ref: '#/components/schemas/Thing'
        - type: object
          properties:
            sameAs:
              type: array
              items:
                type: string
                format: uri

    Product:
      allOf:
        - $ref: '#/components/schemas/Thing'
        - type: object
          properties:
            sku:
              type: string
            brand:
              $ref: '#/components/schemas/Brand'
            manufacturer:
              $ref: '#/components/schemas/Organization'
            material:
              type: string
            productionDate:
              type: string
            weight:
              $ref: '#/components/schemas/QuantitativeValue'
            offers:
              type: array
              items:
                $ref: '#/components/schemas/Offer'
            isVariantOf:
              $ref: '#/components/schemas/ProductModel'
            additionalProperty:
              type: array
              items:
                $ref: '#/components/schemas/PropertyValue'

    ProductModel:
      allOf:
        - $ref: '#/components/schemas/Product'

    Brand:
      type: object
      properties:
        name:
          type: string
        logo:
          type: string
          format: uri

    QuantitativeValue:
      type: object
      properties:
        value:
          type: number
        minValue:
          type: number
        maxValue:
          type: number
        unitCode:
          type: string
        unitText:
          type: string

    PropertyValue:
      type: object
      properties:
        name:
          type: string
        value:
          oneOf:
            - type: string
            - type: number
```

---

## Response Format Spectrum

### Full JSON-LD

Include `@context` and `@type`. Suitable for public APIs consumed by search engines, AI systems, or linked-data clients:

```json
{
  "@context": "https://schema.org",
  "@type": "Event",
  "name": "Summer Jazz Festival",
  "startDate": "2026-07-15T19:00:00-05:00",
  "location": {
    "@type": "MusicVenue",
    "name": "Riverside Amphitheater"
  }
}
```

### Schema.org-Inspired

Include `@type` but omit `@context`. Internal or partner APIs that benefit from shared vocabulary without RDF overhead:

```json
{
  "@type": "Event",
  "name": "Summer Jazz Festival",
  "startDate": "2026-07-15T19:00:00-05:00",
  "location": {
    "@type": "MusicVenue",
    "name": "Riverside Amphitheater"
  }
}
```

### Property Names Only

Use Schema.org naming conventions without any JSON-LD markers. Maximum compatibility with existing tooling:

```json
{
  "type": "event",
  "name": "Summer Jazz Festival",
  "startDate": "2026-07-15T19:00:00-05:00",
  "location": {
    "type": "venue",
    "name": "Riverside Amphitheater"
  }
}
```

---

## Cross-System Identifier Mapping

When entities exist across multiple systems, maintain a structured identifier registry:

### `sameAs` for Canonical URLs

```json
{
  "@type": "MusicGroup",
  "name": "LCD Soundsystem",
  "sameAs": [
    "https://musicbrainz.org/artist/f59c5520-5f46-4d2c-b2c4-822eabf53419",
    "https://open.spotify.com/artist/066X20Nz7iquqkkCW6Jxy6",
    "https://www.wikidata.org/wiki/Q843781"
  ]
}
```

### `x-externalIdentifiers` for System IDs

```json
{
  "@type": "MusicGroup",
  "name": "LCD Soundsystem",
  "x-externalIdentifiers": [
    { "source": "musicbrainz", "identifier": "f59c5520-5f46-4d2c-b2c4-822eabf53419" },
    { "source": "ticketmaster", "identifier": "K8vZ9175st0" },
    { "source": "spotify", "identifier": "066X20Nz7iquqkkCW6Jxy6" }
  ]
}
```

### Querying by External ID

Design APIs to accept external IDs with a source prefix:

```
GET /api/artists?id=musicbrainz:f59c5520-5f46-4d2c-b2c4-822eabf53419
GET /api/artists?id=ticketmaster:K8vZ9175st0
GET /api/artists?id=internal:228924
```

This allows consumers to query using whatever ID system they already have.

---

## Data Source Typing

When your API aggregates data from multiple sources, represent each source as a Schema.org Organization:

```json
{
  "dataSources": [
    {
      "@type": "Organization",
      "name": "Ticketmaster",
      "identifier": "ticketmaster",
      "disambiguatingDescription": "eventDataSource"
    },
    {
      "@type": "Organization",
      "name": "SeatGeek",
      "identifier": "seatgeek",
      "disambiguatingDescription": "venueDataSource"
    }
  ]
}
```

The `disambiguatingDescription` field clarifies what kind of data each source provides.

---

## Vocabulary Alignment Checklist

When designing a Schema.org-grounded API:

- [ ] All entity types map to Schema.org types (or documented extensions)
- [ ] Property names use Schema.org vocabulary where a match exists
- [ ] Enumeration values use full Schema.org URIs
- [ ] `allOf` used for type inheritance in OpenAPI schemas
- [ ] Extension fields use `x-` prefix
- [ ] Internal fields use `_x-` prefix and are stripped from public responses
- [ ] Identifier strategy supports internal IDs, slugs, and external system IDs
- [ ] `sameAs` used for canonical URLs of the same entity on other platforms
- [ ] Date/time values use ISO 8601 format
- [ ] Prices use numeric strings with separate `priceCurrency`
