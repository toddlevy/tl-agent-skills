# Schema.org Taxonomy Guide

## Type Hierarchy

Everything in Schema.org descends from `Thing`. The vocabulary contains 800+ types organized into major branches. Types can have multiple parent types (multiple inheritance), though the primary hierarchy is tree-shaped.

### Top-Level Branches

```
Thing
├── Action                    # User interactions and operations
├── BioChemEntity             # Life sciences (Gene, Protein)
├── CreativeWork              # Content, media, publications
├── Event                     # Happenings with dates and locations
├── Intangible                # Abstract concepts (Offer, Rating, StructuredValue)
├── MedicalEntity             # Health and medical content
├── Organization              # Entities with structure and identity
├── Person                    # People with roles and relationships
├── Place                     # Physical and administrative locations
├── Product                   # Tangible goods and variants
└── Taxon                     # Biological taxonomy
```

### Action (User Interactions)

```
Action
├── AchieveAction             # LoseAction, TieAction, WinAction
├── AssessAction              # ChooseAction, ReactAction (Like, Dislike, Endorse)
├── ConsumeAction             # EatAction, DrinkAction, ReadAction, WatchAction
├── ControlAction             # ActivateAction, DeactivateAction, LoginAction
├── CreateAction              # CookAction, DrawAction, WriteAction, PhotographAction
├── FindAction                # CheckAction, DiscoverAction, TrackAction
├── InteractAction            # CommunicateAction, FollowAction, JoinAction
├── MoveAction                # ArriveAction, DepartAction, TravelAction
├── OrganizeAction            # AllocateAction, BookmarkAction, PlanAction
├── PlayAction                # ExerciseAction, PerformAction
├── SearchAction              # Search boxes and deep linking
├── TradeAction               # BuyAction, SellAction, RentAction, OrderAction
├── TransferAction            # DownloadAction, SendAction, ReceiveAction
└── UpdateAction              # AddAction, DeleteAction, ReplaceAction
```

### CreativeWork (Content)

```
CreativeWork
├── Article                   # BlogPosting, NewsArticle, TechArticle, Report
├── Book                      # Audiobook
├── Course                    # Educational content
├── Dataset                   # Data collections
├── DigitalDocument           # NoteDigitalDocument, SpreadsheetDigitalDocument
├── HowTo                     # Recipe (subtype), HowToStep, HowToDirection
├── ImageObject               # Barcode, ImageObjectSnapshot
├── Map                       # Maps and cartographic content
├── MediaObject               # AudioObject, VideoObject, 3DModel
├── Menu                      # Restaurant menus
├── Movie                     # Films
├── MusicComposition          # Musical works
├── MusicPlaylist             # MusicAlbum, MusicRelease
├── MusicRecording            # Specific recordings
├── Painting                  # Visual art
├── Photograph                # Photos
├── Review                    # CriticReview, UserReview, EmployerReview
├── SoftwareApplication       # MobileApplication, WebApplication, VideoGame
├── TVSeries / TVSeason       # Television content
├── VisualArtwork             # Visual art pieces
├── WebPage                   # FAQPage, AboutPage, ContactPage, ItemPage, CollectionPage
├── WebPageElement            # SiteNavigationElement, WPHeader, WPFooter
└── WebSite                   # Entire websites
```

### Event

```
Event
├── BusinessEvent             # Trade shows, conferences
├── ComedyEvent               # Comedy performances
├── CourseInstance             # Specific offering of a Course
├── DanceEvent                # Dance performances
├── DeliveryEvent             # Package delivery events
├── EducationEvent            # Training, workshops
├── EventSeries               # Recurring event series
├── ExhibitionEvent           # Museum or gallery exhibitions
├── Festival                  # Multi-day festivals
├── FoodEvent                 # Food festivals, tastings
├── Hackathon                 # Coding events
├── LiteraryEvent             # Book readings, signings
├── MusicEvent                # Concerts, music performances
├── SaleEvent                 # Sales and promotions
├── ScreeningEvent            # Film screenings
├── SocialEvent               # Parties, gatherings
├── SportsEvent               # Games, matches, races
├── TheaterEvent              # Stage performances
└── VisualArtsEvent           # Art exhibitions
```

### Intangible (Abstract Concepts)

```
Intangible
├── Audience                  # BusinessAudience, Researcher, PeopleAudience
├── BedDetails                # Hotel bed configuration
├── Brand                     # Product brands
├── Class                     # Meta: Schema.org types themselves
├── ComputerLanguage          # Programming languages
├── DataFeedItem              # Feed items
├── Demand                    # Demand for products
├── DefinedTerm               # Categorization terms, glossary entries
├── DefinedTermSet            # Collections of DefinedTerms
├── Enumeration               # All Schema.org enumerations
├── GameServer                # Online game servers
├── Invoice                   # Billing documents
├── ItemList                  # Lists (BreadcrumbList, HowToSection, OfferCatalog)
├── ListItem                  # Items within an ItemList
├── MenuItem                  # Restaurant menu items
├── Observation               # Statistical observations
├── Occupation                # Job types
├── Offer                     # Pricing and availability for products/services
├── OfferCatalog              # Collections of offers
├── Order                     # Purchase orders
├── OrderItem                 # Items within an Order
├── ProgramMembership         # Memberships and subscriptions
├── Property                  # Meta: Schema.org properties themselves
├── Quantity                  # Distance, Duration, Energy, Mass
├── Rating                    # AggregateRating, EndorsementRating
├── Reservation               # FoodEstablishmentReservation, FlightReservation
├── Role                      # OrganizationRole, PerformanceRole
├── Schedule                  # Recurring time specifications
├── Service                   # FinancialProduct, GovernmentService, Taxi, BroadcastService
├── StructuredValue           # ContactPoint, GeoCoordinates, MonetaryAmount, PostalAddress
├── Trip                      # Flight, TrainTrip, BusTrip, BoatTrip
└── VirtualLocation           # Online event locations
```

### Organization

```
Organization
├── Airline                   # Airlines
├── Consortium                # Multi-org partnerships
├── Corporation               # Companies
├── EducationalOrganization   # CollegeOrUniversity, HighSchool, MiddleSchool
├── FundingScheme              # Grant programs
├── GovernmentOrganization    # Government bodies
├── LibrarySystem             # Library networks
├── LocalBusiness             # (see Place-related subtypes below)
├── MedicalOrganization       # Hospital, Pharmacy, Physician
├── NewsMediaOrganization     # News outlets
├── NGO                       # Non-profits
├── PerformingGroup           # MusicGroup, DanceGroup, TheaterGroup
├── Project                   # FundingAgency, ResearchProject
├── SportsOrganization        # SportsTeam
└── WorkersUnion              # Labor organizations
```

### Place

```
Place
├── Accommodation             # Apartment, House, Room, Suite, CampingPitch
├── AdministrativeArea        # City, State, Country, SchoolDistrict
├── CivicStructure            # Airport, BusStation, Museum, Park, Zoo, Stadium
├── LandmarksOrHistoricalBuildings
├── LocalBusiness             # (dual-inherits from Organization)
│   ├── AnimalShelter
│   ├── AutomotiveBusiness    # AutoRepair, GasStation
│   ├── EntertainmentBusiness # AmusementPark, Casino, NightClub
│   ├── FinancialService      # AccountingService, BankOrCreditUnion
│   ├── FoodEstablishment     # Restaurant, BarOrPub, Bakery, CafeOrCoffeeShop
│   ├── HealthAndBeautyBusiness
│   ├── LodgingBusiness       # Hotel, Motel, Hostel, Resort
│   ├── MusicVenue            # Concert halls, clubs
│   ├── ProfessionalService   # Attorney, Dentist, Notary
│   ├── Store                 # BookStore, ClothingStore, GroceryStore, JewelryStore
│   └── SportsActivityLocation # GolfCourse, SkiResort, TennisComplex
├── Residence                 # ApartmentComplex, GatedResidenceCommunity
└── TouristAttraction         # Points of interest
```

### Product

```
Product
├── IndividualProduct         # Unique, one-of-a-kind items
├── ProductCollection         # Groups of related products (series, lines)
├── ProductGroup              # Grouping of variants
├── ProductModel              # Canonical product definition (base product)
├── SomeProducts              # Subset of products
└── Vehicle                   # Car, Motorcycle, BusOrCoach, MotorizedBicycle
```

---

## Domain Clusters

Quick-reference for mapping business verticals to Schema.org type constellations.

| Vertical | Core Types | Supporting Types | Key Properties |
|----------|-----------|-----------------|----------------|
| **E-commerce** | Product, Offer | Brand, Organization, AggregateOffer, QuantitativeValue, SizeSpecification, ProductModel, ProductGroup | name, sku, offers, brand, weight, size, material, isVariantOf |
| **Events / Concerts** | Event, MusicEvent, Festival | Place, MusicVenue, PostalAddress, GeoCoordinates, Offer, Person, MusicGroup | startDate, endDate, location, performer, offers, eventStatus, eventAttendanceMode |
| **Publishing** | Article, BlogPosting, NewsArticle | Person, Organization, ImageObject, WebPage, WebSite, BreadcrumbList | headline, datePublished, author, publisher, image, mainEntityOfPage |
| **Jobs** | JobPosting | Organization, Place, MonetaryAmount, OccupationalExperienceRequirements | title, datePosted, hiringOrganization, jobLocation, baseSalary, employmentType |
| **Local Business** | LocalBusiness (subtypes) | PostalAddress, GeoCoordinates, OpeningHoursSpecification, AggregateRating | name, address, geo, openingHoursSpecification, telephone, priceRange |
| **Recipes / Food** | Recipe, HowToStep | NutritionInformation, ImageObject, Person, AggregateRating | cookTime, recipeIngredient, recipeInstructions, nutrition, author |
| **Education** | Course, LearningResource | Organization, Person, Offer, CourseInstance | provider, name, description, offers, hasCourseInstance |
| **Music** | MusicGroup, MusicEvent, MusicComposition | Person, MusicAlbum, MusicRecording, Place, Offer | member, genre, foundingLocation, performer, recordedAt |
| **Collectibles** | Product, ProductModel, ProductGroup | Offer, Brand, QuantitativeValue, PropertyValue, SizeSpecification | material, productionDate, brand, weight, additionalProperty, isVariantOf |
| **Real Estate** | Accommodation, Apartment, House | PostalAddress, GeoCoordinates, QuantitativeValue, Offer | numberOfRooms, floorSize, address, geo, offers |
| **Travel** | LodgingBusiness, TouristAttraction | Offer, PostalAddress, AggregateRating, Review | address, starRating, amenityFeature, checkinTime |
| **Software** | SoftwareApplication, WebApplication | Offer, Organization, AggregateRating, Review | applicationCategory, operatingSystem, offers, aggregateRating |
| **Healthcare** | MedicalCondition, Drug, Hospital | MedicalProcedure, Physician, MedicalSpecialty | name, associatedAnatomy, drug, possibleTreatment |
| **Glossary / Reference** | DefinedTerm, DefinedTermSet | -- | name, description, termCode, inDefinedTermSet |

---

## Decision Trees

### "Which type should I use for my page?"

```
Is this page about a specific thing you can describe?
├── Yes → What kind of thing?
│   ├── A physical product for sale → Product (with Offer)
│   ├── An event with a date → Event (or subtype: MusicEvent, SportsEvent, etc.)
│   ├── A person → Person
│   ├── A business or organization → Organization (or LocalBusiness subtype)
│   ├── A physical location → Place (or subtype: MusicVenue, Restaurant, etc.)
│   ├── An article or blog post → Article or BlogPosting
│   ├── A recipe → Recipe
│   ├── A job listing → JobPosting
│   ├── A course or class → Course
│   ├── A piece of software → SoftwareApplication
│   ├── A video → VideoObject
│   ├── A podcast → PodcastEpisode / PodcastSeries
│   └── A FAQ → FAQPage
├── No, it's a list of things → ItemList or CollectionPage
├── No, it's a search results page → SearchResultsPage
└── No, it's a general page → WebPage
```

### "Should I use a subtype or the parent type?"

```
Does a specific subtype exist for your entity?
├── Yes → Does it accurately describe the entity?
│   ├── Yes → Use the subtype (MusicEvent, not Event)
│   └── No → Use the parent type
└── No → Use the closest parent type
```

The principle: be as specific as Schema.org allows, but never force-fit a type.

### "My entity fits multiple types"

```
Does the entity genuinely belong to two types?
├── Yes → Use an array: "@type": ["Book", "Product"]
│   Only when both types independently describe the entity.
│   Common combos: Product + SomeCreativeWork, LocalBusiness + Place
└── No → Pick the primary type and use properties from the other
```

---

## Using the Data Files

The `data/` directory contains machine-readable Schema.org release files for runtime lookup.

### Types CSV (`schemaorg-current-https-types.csv`)

Columns: `id`, `label`, `comment`, `subTypeOf`, `enumerationtype`, `equivalentClass`, `properties`, `subTypes`, `supersedes`, `supersededBy`, `isPartOf`

Use this to:
- Look up any type by name
- Find its parent types (`subTypeOf`)
- List all properties valid for a type (`properties`)
- Discover subtypes (`subTypes`)

### Properties CSV (`schemaorg-current-https-properties.csv`)

Columns: `id`, `label`, `comment`, `subPropertyOf`, `equivalentProperty`, `subproperties`, `domainIncludes`, `rangeIncludes`, `inverseOf`, `supersedes`, `supersededBy`, `isPartOf`

Use this to:
- Look up any property by name
- Find which types it belongs to (`domainIncludes`)
- Find what types of values it accepts (`rangeIncludes`)
- Discover sub-properties (`subproperties`)

### Type Hierarchy (`tree.jsonld`)

A JSON-LD file representing the type hierarchy in D3-compatible format. Each node has `name` and `children`. Useful for traversal and visualization.

### JSON-LD Context (`jsonldcontext.json`)

The official context file mapping short property names to their full Schema.org URIs. Used by JSON-LD processors to expand compact representations.
