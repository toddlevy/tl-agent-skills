# Schema.org Version Tracking

Schema.org publishes numbered releases periodically (roughly every few weeks). The vocabulary grows but rarely removes terms -- deprecated items move to an "attic" rather than being deleted. This makes it stable for production use but requires monitoring for new opportunities.

---

## Release Structure

Each release is identified by a version number (e.g., `30.0`) and a date. Releases are published at:

- **Release summary**: https://schema.org/version/latest
- **All releases**: https://schema.org/docs/releases.html
- **GitHub releases**: https://github.com/schemaorg/schemaorg/tree/main/data/releases

Each release includes:
- Types CSV: All types with their properties, parent types, and subtypes
- Properties CSV: All properties with their domains, ranges, and relationships
- JSON-LD, Turtle, N-Triples, N-Quads, and RDF/XML definitions
- A human-readable release summary listing what changed

---

## Updating Local Data Files

Run the update script to download the latest release files:

**Bash:**
```bash
./scripts/update-schema-data.sh
```

**PowerShell:**
```powershell
.\scripts\update-schema-data.ps1
```

This downloads:
- `schemaorg-current-https-types.csv`
- `schemaorg-current-https-properties.csv`
- `tree.jsonld`
- `jsonldcontext.json`

And writes a `data/VERSION` file with the version number, date, and download timestamp.

---

## Diffing Changes Between Versions

### Types

Compare `schemaorg-current-https-types.csv` between versions:

```bash
diff <(cut -d',' -f1,2 old-types.csv | sort) <(cut -d',' -f1,2 new-types.csv | sort)
```

Look for:
- **New rows**: New types added to the vocabulary
- **Changed `subTypeOf`**: Type moved in the hierarchy
- **Changed `properties`**: Type gained or lost properties
- **Changed `isPartOf`**: Term moved from `pending.schema.org` to `schema.org` (graduated) or to attic (deprecated)

### Properties

Compare `schemaorg-current-https-properties.csv`:

```bash
diff <(cut -d',' -f1,2 old-properties.csv | sort) <(cut -d',' -f1,2 new-properties.csv | sort)
```

Look for:
- **New rows**: New properties added
- **Changed `domainIncludes`**: Property now valid on additional types
- **Changed `rangeIncludes`**: Property now accepts additional value types
- **Changed `isPartOf`**: Graduation from pending or deprecation to attic

---

## Change Impact Assessment

| Change Type | Risk | Action Required |
|-------------|------|-----------------|
| New type added | None | Evaluate whether it's relevant to your domain |
| New property on existing type | Low | Consider adopting, especially if it replaces an `x-` extension |
| Existing property gains new domain | Low | May enable using it on types you couldn't before |
| Property range expanded | Low | May enable richer data modeling |
| New enumeration member | Low | Consider adding to your enum mapping tables |
| Term graduated from pending | None | Safe to rely on for production use |
| Term moved to attic | Medium | Plan migration if you use it; it still works but is deprecated |
| Property renamed or restructured | High | Rare, but requires coordinated update across your systems |
| Type hierarchy change | Medium | May affect your OpenAPI `allOf` chain |

---

## Migration: Extension Becomes Official

When Schema.org adds a property that matches one of your `x-` extensions:

### Phase 1: Dual Emit

Emit both the new standard property and your existing extension:

```json
{
  "@type": "MusicEvent",
  "performer": [
    {
      "@type": "MusicGroup",
      "name": "The Silver Notes",
      "performanceRank": 1,
      "x-performanceRank": 1
    }
  ]
}
```

### Phase 2: Consumer Migration

Give API consumers time to migrate to the standard property. Set a deprecation timeline.

### Phase 3: Drop Extension

Remove the `x-` field. Update your OpenAPI schema and documentation.

### Timeline

- **Phase 1**: Start immediately when the new property appears
- **Phase 2**: 1-2 release cycles (or your API versioning cadence)
- **Phase 3**: Next major version or after all known consumers have migrated

---

## Monitoring Automation

For production systems, consider automating version checks:

1. **Scheduled check**: Weekly or monthly, run the update script and compare `data/VERSION` to previous
2. **Diff report**: Generate a summary of new types and properties relevant to your domain clusters
3. **Alert on attic moves**: Flag any term you use that moves to the attic
4. **Alert on pending graduation**: Flag pending terms you use that graduate to core

---

## Schema.org GitHub Repository

The canonical source for Schema.org vocabulary development:

- **Repo**: https://github.com/schemaorg/schemaorg
- **Issues**: Feature requests, bug reports, new type proposals
- **Discussions**: W3C Schema.org Community Group

Editorial work uses Turtle format with an RDFS-based approach. Changes flow through GitHub issues and community discussion before appearing in releases.

---

## Version Pinning

If your system requires stability guarantees:

1. Record the Schema.org version in `data/VERSION`
2. Only update when you've assessed the diff
3. Pin your enum mapping tables to specific Schema.org enumeration members
4. Document which Schema.org version your API contract is based on
5. Test after each update to ensure no breaking changes in your serialization
