# Records tool contract

`scripts/project-records.ps1` is one PowerShell script that owns every records check and the changelog renderer. It runs on Windows PowerShell 5.1 and PowerShell 7 on any platform, needs only `git`, and is copied into the adopting repository as `scripts/project-records.ps1`.

## Invocation

```powershell
pwsh -NoProfile -File scripts/project-records.ps1 <command> [arguments] [-Config <path>]
```

- Run from anywhere inside the work tree; the repository root is found with `git rev-parse --show-toplevel`.
- The config is `records.config.json` at the repository root unless `-Config` names another file. Every command except `self-test` requires a valid config.
- An unknown command, a flag the command does not take, a missing required value, or an invalid config exits 1 with a message naming the problem.

## Commands

| Command | Arguments | Reads | Writes | Exit 0 | Exit 1 |
|---------|-----------|-------|--------|--------|--------|
| `check-msg` | `<message file>` | The file, as bytes | Nothing | Subject accepted or pass-through | BOM, no subject, wrong shape, or too long |
| `check-commit` | none | The index | Nothing | Archive rule passes, nothing archived, or archive not configured | An archived key is not named in the staged DEVLOG |
| `check-range` | `-Base <rev> -Head <rev>` | Commit messages | Nothing | Every checked subject passes, or Head has no install commit (`0 checked`) | Shallow clone, unresolvable revision, a failing subject, or the hook file removed after its install commit |
| `check` | none | The work tree | Nothing | ADR, DEVLOG, and CHANGELOG checks all pass | Any problem; every problem is listed |
| `changelog-preview` | `[-From <rev>] [-To <rev>] [-OutFile <path>]` | Commits, `.gitattributes`, ledger | `-OutFile` only | Rendered | Unresolvable revision, or `@latest-tag` with no matching tag |
| `changelog-cut` | `-Tag <tag> [-From <rev>]` | Commits, tags, CHANGELOG.md | CHANGELOG.md | Stanza written | Tag outside the pattern or missing, stanza exists, empty range, no earlier tag and no `-From`, no `[Unreleased]` heading or foot link, no `origin` remote |
| `self-test` | none | Nothing in the repository | Temp directories only | Every fixture passes | Any fixture fails |

`check-range` checks non-merge commits in `Base..Head` that descend from the commit that first added `paths.commitMsgHook`.

`changelog-preview` defaults `-From` and `-To` to `changelog.previewFrom` and `changelog.previewTo`. The token `@latest-tag` resolves to the nearest tag matching `tagGlob` in the ancestry of `HEAD`.

`changelog-cut` takes the range start from the nearest earlier matching tag in the tag's ancestry, or from `-From`. A `-From` that is not a tag is pinned to its eight-character SHA in the compare link.

## What `check` enforces

**ADRs** (`paths.adrDirectory`): file names `NNNN-kebab-title.md`; numbers unique, starting at `0001`, with no gaps; every `adr.headerLabels` bullet present before the first `##` heading; `Status` is `Proposed`, `Accepted (YYYY-MM-DD)`, `Superseded by NNNN`, or `Deprecated`; `README.md` exists and its `## Index` table has exactly one row per file, linking that file, with a status equal to the file's (the acceptance date may be omitted in the row).

**DEVLOG** (`paths.devlog`): entry headings `## [YYYY-MM-DD] Title` with a real calendar date, newest first; after the first entry, no other `##` heading; in each entry, `**Category:**`, `**Tags:**`, `### Summary`, `### Detail`, `### Related` in order; the category is one of `devlog.categories`; tags are not empty; every `ADR-NNNN` mentioned has a file; with `archive` configured, every archived key is named somewhere in the DEVLOG.

**CHANGELOG** (`paths.changelog`): exactly one `## [Unreleased]`, as the first `##` heading; every other `##` heading is `## [<tag>] - YYYY-MM-DD` with a tag matching `tagPattern` that exists locally and whose date equals the heading date; stanzas newest first (date, then the `number` group); `###` sections only from `sectionOrder`, in order, not repeated.

## Output

- Every diagnostic line starts with `logPrefix` and one space. `OK` lines go to stdout, `FAIL` lines and their indented detail to stderr.
- `changelog-preview` without `-OutFile` writes the raw markdown to stdout with no prefix, so it can be piped or captured. Its warnings (skipped unparseable subjects) go through `Write-Warning`, which a redirect or capture does not carry.
- Files are written as UTF-8 without a BOM. `changelog-cut` keeps the CHANGELOG's existing line endings.

## Configuration schema

| Key | Type | Meaning |
|-----|------|---------|
| `logPrefix` | string | Prefix for every diagnostic line |
| `paths.devlog`, `paths.changelog` | string | Repository-relative record files |
| `paths.adrDirectory` | string | ADR directory, holding `README.md` and `template.md` |
| `paths.commitMsgHook` | string | The hook file whose first commit starts `check-range` |
| `subject.maxLength` | integer, at least 20 | Subject length limit |
| `subject.passthroughPrefixes` | string array | Subjects accepted unchecked |
| `commitTypes[]` | `{ type, section }` | Allowed types, in the order the hook lists them; `section: null` means never rendered |
| `scopeSections` | object | Scope to section overrides |
| `devlog.categories` | string array | Allowed entry categories |
| `adr.headerLabels` | string array, must include `Status` | Required ADR header bullets |
| `changelog.sectionOrder` | string array | Section names and their order |
| `changelog.releaseFilter` | `export-ignore` or `none` | Path filter for rendered commits |
| `changelog.tagPattern` | .NET regex | Release tags; optional named groups `date` and `number` |
| `changelog.tagGlob` | git glob | The same tags, for `git describe --match` |
| `changelog.compareTarget` | string | The ref the `[Unreleased]` foot link compares against |
| `changelog.previewFrom`, `previewTo` | string | Default preview range; `previewFrom` may be `@latest-tag` |
| `changelog.removalLedger` | object or `null` | Optional ledger rendering (see `changelog.md`) |
| `archive` | `{ root, fileSuffix }` or `null` | Optional archive rule; a key is the first path segment under `root` of a file ending in `fileSuffix` |

The config is the single home for this vocabulary; the script carries no defaults for these keys. Fixed by the tool, not configurable: the ADR file-name and status grammar, the DEVLOG entry labels, the CHANGELOG heading grammar, and the bullet format.

## Self-test coverage

`self-test` builds temp directories and temp git repositories only, with an isolated git identity and hooks path, and removes them afterward. Groups: config validation; subject rule (shapes, BOM, pass-through, length); archive rule; whole-tree check (ADR, DEVLOG, CHANGELOG failure cases); range check (install commit, shallow clone, removed hook); render (every type and scope, file and directory release-filter patterns, `releaseFilter: none`, ledger rows, raw preview output); cut (refusals, CRLF preservation, deploy-dated and semver models, first release); end-to-end (real `git commit` through the real hook shims).
