# Adopting the records in a repository

Adoption is one reviewable change. Do it on a branch, show the plan first, and land it as `chore(records): adopt project records` (or split the retroactive seed into its own `docs(records)` commit).

## 1. Survey

Read before writing. Report what exists:

- Existing `DEVLOG.md`, `CHANGELOG.md`, `docs/adr/`, `docs/decisions/`, or `HISTORY.md`.
- The release model: semver tags, deploy tags, or none. `git tag --list --sort=-creatordate | Select-Object -First 20`.
- The hook manager: `.githooks/`, `.husky/`, `lefthook.yml`, or none. `git config core.hooksPath`.
- An existing changelog generator (git-cliff, semantic-release, release-please, changesets). If one owns the CHANGELOG, keep it and skip the renderer (see `changelog.md`, "Porting to existing tooling").
- The commit history's conformance: `git log --format=%s -200` and count subjects that already match `type(scope): subject`.
- What should never count as a release: `.gitattributes` `export-ignore` lines, if the project deploys with `git archive`.

## 2. Configure

Copy `assets/templates/records.config.json` to the repository root and decide each value:

| Key | Decide |
|-----|--------|
| `logPrefix` | `[ACRONYM][Records]` for the project |
| `commitTypes` | Add workspace types with `section: null`; keep the list short |
| `scopeSections` | `security`, plus `legal` if the project publishes legal pages |
| `changelog.sectionOrder` | Reader priority; add `Removed` only with a removal ledger |
| `changelog.releaseFilter` | `export-ignore` when deploys use `git archive` and `.gitattributes` excludes tooling; otherwise `none` |
| `changelog.tagPattern` / `tagGlob` | The release model (see `changelog.md`) |
| `changelog.compareTarget`, `previewFrom`, `previewTo` | The branch that holds unreleased work and the refs the release pull request compares |
| `archive` | `{ "root": "<archive dir>/", "fileSuffix": "<plan suffix>" }` when work units are archived as files; otherwise `null` |

The tool refuses an incomplete or inconsistent config (a type mapped to a section that is not in `sectionOrder`, an invalid pattern) and names the key.

## 3. Scaffold

```powershell
$skill = '<path to tl-project-records>'
New-Item -ItemType Directory -Force scripts, .githooks, docs/adr | Out-Null
Copy-Item "$skill/scripts/project-records.ps1" scripts/
Copy-Item "$skill/assets/templates/DEVLOG.md" DEVLOG.md
Copy-Item "$skill/assets/templates/CHANGELOG.md" CHANGELOG.md
Copy-Item "$skill/assets/templates/adr-README.md" docs/adr/README.md
Copy-Item "$skill/assets/templates/adr-template.md" docs/adr/template.md
Copy-Item "$skill/assets/templates/commit-msg" .githooks/
Copy-Item "$skill/assets/templates/pre-commit" .githooks/   # only when archive is configured
git add --chmod=+x -- .githooks/commit-msg .githooks/pre-commit
git config core.hooksPath .githooks
```

On Windows, `git commit -- <paths>` rebuilds the named paths from the working tree, where there is no executable bit, so it commits a new hook as `100644` even after `git add --chmod=+x`. Commit the hooks from the index instead (`git commit -F <file>` with no pathspec, after `git diff --cached --name-status` shows only your paths), then confirm with `git ls-tree HEAD .githooks/`.

Never overwrite an existing record. Merge: keep existing entries, convert their headings to the entry shape, and add the conventions header. An existing `docs/decisions/` keeps its location; set `paths.adrDirectory`.

Then edit:

- The DEVLOG and CHANGELOG titles, and the CHANGELOG foot link (`OWNER/REPOSITORY`).
- The ADR README's first paragraph and its trigger rule, if the project's reversal-cost examples differ.
- `.gitattributes`: add `.githooks/* text eol=lf`; if `releaseFilter` is `export-ignore`, add `export-ignore` lines for `scripts/project-records.ps1`, `records.config.json`, `docs/adr/`, `DEVLOG.md`, and `.githooks/` so record and tooling commits do not render as releases.
- `AGENTS.md`: paste `assets/templates/agents-md-records.md`.
- CI: paste `assets/templates/ci-records-job.yml`.

## 4. Seed

- **ADRs:** backfill decisions in effect and evidenced, under the backfill rules in `adr.md`. Start with the few that agents most often get wrong; a dozen good ADRs beat fifty thin ones.
- **DEVLOG:** one bounded pre-history entry, then one entry per significant past event, each tagged `retroactive` and citing commits. Stop at adoption.
- **CHANGELOG:** do not backfill releases from before the subject rule; old subjects do not parse. The first stanza is the first release after adoption, cut with an explicit `-From`.

## 5. Verify

```powershell
pwsh -NoProfile -File scripts/project-records.ps1 self-test   # exit 0
pwsh -NoProfile -File scripts/project-records.ps1 check       # exit 0
pwsh -NoProfile -File scripts/project-records.ps1 changelog-preview -From <last release or adoption base>
```

Then prove the hooks in a throwaway clone of the adoption branch: `git commit --allow-empty -m "Update stuff"` must be rejected with the allowed types listed, and `git commit --allow-empty -m "chore: hook probe"` must pass. `self-test` already runs the same probes against fixture repositories.

## Retiring a superseded devlog convention

When a project moves from an older devlog format, update every pointer in the same change: `AGENTS.md`, the DEVLOG conventions header, workspace rules, and any skill amendment that names the old format. Leave dated history (past DEVLOG entries, accepted ADRs, archived plans) as written; it was true when written.
