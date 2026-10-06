# CHANGELOG.md

The CHANGELOG answers "what did each release change?" for a reader of releases: an operator, a consumer of the package, or an auditor. It is rendered from commit subjects, never hand-curated, so it cannot drift from the commit log.

## Format

[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), with these project rules:

- `## [Unreleased]` is the first second-level heading and stays **empty** permanently.
- Each release is `## [<tag>] - YYYY-MM-DD`, newest first, where `<tag>` matches `changelog.tagPattern` and exists in the repository.
- Sections are `### <name>` in the configured `changelog.sectionOrder`; an empty section is omitted. A release with nothing release-bound renders "No release-bound changes."
- Each bullet is `- **scope** subject (sha8)`, or `- subject (sha8)` with no scope.
- Foot links: `[Unreleased]: <repo>/compare/<latest-tag>...<compareTarget>` and one `[<tag>]: <repo>/compare/<previous>...<tag>` per release.

## Why `[Unreleased]` stays empty

A hand-fed `[Unreleased]` section is a second copy of the commit log. It drifts, it conflicts every time two branches touch it, and nobody can tell whether it is complete. Instead:

- `changelog-preview` renders what the next release carries, to stdout or `-OutFile`. Use it as the release pull request body.
- `changelog-cut -Tag <tag>` writes the stanza under `[Unreleased]` once the release tag exists, and rewrites the foot links.

## What renders

A commit renders when all of these hold:

1. It is not a merge commit.
2. Its subject parses as `type(scope): subject` and its type maps to a section (`commitTypes[].section` is not null). Types mapped to `null` (docs, chore, ci, test, style, build in the template) never render.
3. With `releaseFilter: "export-ignore"`, it changes at least one path **outside** the `.gitattributes` `export-ignore` set. Tooling-only and docs-only commits drop out even when typed `feat` or `fix`. With `releaseFilter: "none"`, every included commit renders.

A scope listed in `scopeSections` reroutes the commit: with `"security": "Security"`, `fix(security): ...` renders under Security instead of Fixed. Use this for sections a release reader must not miss (Security, and Legal where the project publishes legal pages).

A commit whose subject does not parse is skipped with a warning naming its SHA. Subjects from before the commit-msg hook was installed are the usual source; history is not rewritten.

## Release models

| Model | Tag | Date | Config |
|-------|-----|------|--------|
| Semver package | `v1.4.0` | The tag's creation date | `tagPattern: "\\Av\\d+\\.\\d+\\.\\d+\\z"`, `tagGlob: "v*"`, `previewFrom: "@latest-tag"` |
| Deploy-dated site | `deploy/2026-10-05`, `deploy/2026-10-05-2` | The date in the tag | `tagPattern` with named groups `date` and optional `number`; `tagGlob: "deploy/*"` |

For a deploy-dated model, the pattern is:

```json
"tagPattern": "\\Adeploy/(?<date>\\d{4}-\\d{2}-\\d{2})(?:-(?<number>\\d+))?\\z",
"tagGlob": "deploy/*",
"compareTarget": "staging",
"previewFrom": "origin/main",
"previewTo": "origin/staging"
```

`check` verifies that each heading's date equals the tag's date (from the `date` group, or the tag's creation date when the pattern has none), that the tag exists, and that stanzas run newest first, using `number` to order same-day releases.

## Release procedure

1. Push, so the remote refs the preview reads are current.
2. `./scripts/project-records.ps1 changelog-preview -OutFile <temp file>` and use it as the release pull request body. Read it: a missing change usually means a mistyped subject; a surprising one usually means a path that should be `export-ignore`.
3. Merge and create the release tag on the released commit. Push the tag.
4. `./scripts/project-records.ps1 changelog-cut -Tag <tag>`. The range starts at the nearest earlier matching tag in the tag's ancestry.
5. Write the release DEVLOG entry if the workspace logs releases.
6. Commit `CHANGELOG.md` (and `DEVLOG.md`) as `docs(records): cut <tag>`.

**First release:** there is no earlier tag, so `changelog-cut` refuses and asks for `-From`. Pass the last commit the first release does not include. A relative or branch revision is pinned to its commit SHA in the compare link.

## Removal ledger (optional)

A project that removes deployed artifacts by decision (plugins, endpoints, services) and tracks them in a markdown table can render those removals into the stanza. Configure `changelog.removalLedger`:

```json
"removalLedger": {
  "path": "docs/removal-ledger.md",
  "header": ["Item", "Environment", "Decision", "Status", "Notes"],
  "itemColumn": "Item",
  "environmentColumn": "Environment",
  "statusColumn": "Status",
  "environmentMatch": "production",
  "statusPrefix": "Removed",
  "section": "Removed",
  "lineTemplate": "- {item} from production (see [removal ledger]({path}))"
}
```

A row renders when its environment cell contains `environmentMatch` (case-insensitive), its status cell starts with `statusPrefix`, and it was not already in that state at the range start. The table header must match `header` exactly; any other shape stops the render rather than guessing. Add the `section` to `sectionOrder`.

## Porting to existing tooling

The renderer is deliberately small. A project already on another tool can keep the same rules:

- **git-cliff**: `--tag-pattern` for the release model, `--include-path`/`--exclude-path` for the release filter, `-u` for the preview, `-p CHANGELOG.md -t <tag>` for the cut. Prove with a fixture that its path filter means "renders when at least one changed path is outside the excluded set" before relying on it.
- **semantic-release, release-please, changesets**: these own versioning and publishing. Keep their changelog output and adopt only the commit-subject rule and the ADR and DEVLOG records from this skill; do not run two renderers.

## Format examples

```markdown
## [Unreleased]

## [v1.4.0] - 2026-04-02

### Security

- **security** reject unsigned webhook payloads (5d20fd92)

### Added

- **import** chunked CSV import with progress reporting (cbe417db)

### Fixed

- **auth** keep the session when the refresh token rotates (91aa02c3)

[Unreleased]: https://github.com/OWNER/REPOSITORY/compare/v1.4.0...main
[v1.4.0]: https://github.com/OWNER/REPOSITORY/compare/v1.3.2...v1.4.0
```
