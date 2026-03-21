# Rich Results and SEO

Structured data enables rich results in search engines -- enhanced listings with FAQ dropdowns, star ratings, product cards, event details, recipe cards, and more. This is the most visible consumer of Schema.org markup.

---

## Required and Recommended Properties

Missing a required property suppresses the entire rich result. Recommended properties improve quality and eligibility.

### Product

| Property | Status | Notes |
|----------|--------|-------|
| `name` | Required | Product name |
| `image` | Required | At least one image URL |
| `offers` | Required | Must include `price` + `priceCurrency` + `availability` |
| `offers.price` | Required | Numeric string (no currency symbol) |
| `offers.priceCurrency` | Required | ISO 4217 code (USD, EUR, GBP) |
| `offers.availability` | Required | Full URI: `https://schema.org/InStock` |
| `brand` | Recommended | Brand name or Brand object |
| `sku` | Recommended | Stock keeping unit |
| `aggregateRating` | Recommended | Rating with `ratingValue` and `reviewCount` |
| `review` | Recommended | At least one Review object |
| `description` | Recommended | Product description |
| `offers.itemCondition` | Recommended | Full URI: `https://schema.org/NewCondition` |
| `offers.seller` | Recommended | Organization object |
| `offers.url` | Recommended | Link to purchase page |
| `offers.priceValidUntil` | Recommended | ISO 8601 date |

### Article / BlogPosting / NewsArticle

| Property | Status | Notes |
|----------|--------|-------|
| `headline` | Required | Article title |
| `image` | Required | Representative image |
| `datePublished` | Required | ISO 8601 date-time |
| `author` | Required | Person or Organization |
| `author.name` | Required | Author's name |
| `dateModified` | Recommended | Last modification date |
| `publisher` | Recommended | Organization with `name` and `logo` |
| `description` | Recommended | Article summary |
| `mainEntityOfPage` | Recommended | WebPage with `@id` |

### Event

| Property | Status | Notes |
|----------|--------|-------|
| `name` | Required | Event name |
| `startDate` | Required | ISO 8601 date-time with timezone |
| `location` | Required | Place with `name` and `address` |
| `location.address` | Required | PostalAddress |
| `endDate` | Recommended | ISO 8601 date-time |
| `offers` | Recommended | Ticket offers with price |
| `performer` | Recommended | Person or MusicGroup |
| `image` | Recommended | Event image |
| `description` | Recommended | Event description |
| `eventStatus` | Recommended | Full URI: `https://schema.org/EventScheduled` |
| `eventAttendanceMode` | Recommended | Full URI |
| `organizer` | Recommended | Organization |
| `previousStartDate` | Recommended | For rescheduled events |

### FAQPage

| Property | Status | Notes |
|----------|--------|-------|
| `mainEntity` | Required | Array of Question objects |
| `mainEntity[].@type` | Required | Must be `"Question"` |
| `mainEntity[].name` | Required | The question text |
| `mainEntity[].acceptedAnswer` | Required | Answer object |
| `mainEntity[].acceptedAnswer.text` | Required | The answer text |

### LocalBusiness

| Property | Status | Notes |
|----------|--------|-------|
| `name` | Required | Business name |
| `address` | Required | PostalAddress |
| `@type` | Required | Specific subtype (Restaurant, Store, etc.) |
| `geo` | Recommended | GeoCoordinates with latitude/longitude |
| `openingHoursSpecification` | Recommended | Business hours |
| `telephone` | Recommended | Phone number |
| `url` | Recommended | Website URL |
| `image` | Recommended | Business photo |
| `aggregateRating` | Recommended | Rating with ratingValue |
| `priceRange` | Recommended | e.g., "$$$" |

### Recipe

| Property | Status | Notes |
|----------|--------|-------|
| `name` | Required | Recipe name |
| `image` | Required | Finished dish photo |
| `author` | Recommended | Person |
| `datePublished` | Recommended | Publication date |
| `description` | Recommended | Recipe summary |
| `prepTime` | Recommended | ISO 8601 duration (PT30M) |
| `cookTime` | Recommended | ISO 8601 duration |
| `totalTime` | Recommended | ISO 8601 duration |
| `recipeIngredient` | Recommended | Array of ingredient strings |
| `recipeInstructions` | Recommended | Array of HowToStep objects |
| `nutrition` | Recommended | NutritionInformation |
| `recipeYield` | Recommended | Serving size |
| `recipeCategory` | Recommended | Meal type |
| `recipeCuisine` | Recommended | Cuisine type |
| `aggregateRating` | Recommended | Rating |

### BreadcrumbList

| Property | Status | Notes |
|----------|--------|-------|
| `itemListElement` | Required | Array of ListItem objects |
| `itemListElement[].position` | Required | Integer position (1-based) |
| `itemListElement[].name` | Required | Breadcrumb label |
| `itemListElement[].item` | Required | URL for that breadcrumb level |

### HowTo

| Property | Status | Notes |
|----------|--------|-------|
| `name` | Required | Title of the how-to |
| `step` | Required | Array of HowToStep objects |
| `step[].name` | Recommended | Step title |
| `step[].text` | Required | Step instructions |
| `step[].image` | Recommended | Step image |
| `totalTime` | Recommended | ISO 8601 duration |
| `estimatedCost` | Recommended | MonetaryAmount |
| `supply` | Recommended | HowToSupply objects |
| `tool` | Recommended | HowToTool objects |

---

## Validation Workflow

### 1. Build

Generate JSON-LD from your data model. Ensure all values come from live data, not hardcoded strings.

### 2. Validate Syntax

Confirm valid JSON: no trailing commas, proper quoting, no comments. Use any JSON linter.

### 3. Validate Schema.org Compliance

**Tool**: https://validator.schema.org/

Paste your JSON-LD or provide a URL. This checks:
- Valid `@type` values
- Properties match their declared domain types
- Range types are appropriate

### 4. Validate Rich Results Eligibility

**Tool**: https://search.google.com/test/rich-results

This checks Google-specific requirements:
- All required properties present
- Property values in correct format
- Content matches visible page

### 5. Monitor in Production

**Tool**: Google Search Console > Enhancements

Watch for:
- New errors after deployments
- Declining valid page counts
- Rich result eligibility warnings

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Missing required field | Required property omitted | Add the property; check per-type table above |
| Invalid URL | Relative URL or malformed | Use fully qualified `https://` URLs |
| Invalid date format | Not ISO 8601 | Use `YYYY-MM-DDTHH:MM:SS+00:00` |
| Invalid enum value | Bare string instead of URI | Use `https://schema.org/InStock`, not `InStock` |
| Content mismatch | Schema doesn't match visible content | Ensure schema reflects what users see |
| Invalid price | Currency symbol or commas in value | Use numeric string only: `"149.99"` |
| Missing `@context` | JSON-LD processor can't resolve types | Add `"@context": "https://schema.org"` |
| Wrong `@type` casing | `"product"` instead of `"Product"` | Use exact Schema.org type name (PascalCase) |
| Array where object expected | `"offers": [...]` when single offer | Both work; prefer object for single, array for multiple |
| Duplicate properties | Same property twice in one object | Keep only one; merge values if needed |

---

## Quality Rules

1. **Accuracy**: Schema must accurately represent visible page content
2. **Completeness**: Include all required properties and as many recommended as possible
3. **Currency**: Dynamic values (prices, availability, ratings) must reflect current data
4. **Consistency**: Same entity should have consistent markup across pages
5. **Relevance**: Only mark up content appropriate for the page type
6. **Truthfulness**: Never use structured data to deceive or mislead

### Things That Will Get Rich Results Suppressed

- Marking up content that isn't visible on the page
- Fake reviews or manipulated ratings
- Misleading prices or availability
- Cloaking (showing different content to Googlebot)
- Marking every page with the same generic schema

---

## Implementation Checklist

- [ ] JSON-LD syntax is valid (no trailing commas, proper quotes)
- [ ] `@context` is `"https://schema.org"`
- [ ] `@type` uses exact Schema.org type name
- [ ] All required properties for target rich result are present
- [ ] Enumeration values use full URIs (`https://schema.org/InStock`)
- [ ] Dates use ISO 8601 format with timezone
- [ ] URLs are fully qualified (`https://...`)
- [ ] Prices are numeric strings without currency symbols
- [ ] Content matches visible page content
- [ ] Schema validates at https://validator.schema.org/
- [ ] Rich results test passes at https://search.google.com/test/rich-results
- [ ] Search Console Enhancement reports show no errors
