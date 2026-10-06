# Adopting the records in a repository

Adoption is one reviewable change. Do it on a branch, show the plan first, and land it as `chore(records): adopt project records` (or split the retroactive seed into its own `docs(records)` commit).

## 1. Survey

Read before writing. Report what exists:

- Existing `DEVLOG.md`, `CHANGELOG.md`, `docs/adr/`, `docs/decisions/`, a decision ledger, or `HISTORY.md`.
- The release model: semver tags, deploy tags, or none. `git tag --list --sort=-creatordate | Select-Object -First 20`.
- The hook manager: `.githooks/`, `.husky/`, `lefthook.yml`, or none. `git config core.hooksPath`.
- An existing commit-message validator (commitlint, a custom script, a step in the hook runner). It is retired in step 3.
- An existing changelog generator (git-cliff, semantic-release, release-please, changesets). If one owns the CHANGELOG, keep it and skip the renderer (see `changelog.md`, "Porting to existing tooling").
- The commit history's conformance: `git log --format=%s -200` and count subjects that already match `type(scope): subject`. This is a first look only; the records tool, configured with the adopted types, is the judge (step 4).
- What should never count as a release: `.gitattributes` `export-ignore` lines, if the project deploys with `git archive`.

## 2. Configure

Copy `assets/templates/records.config.json` to the repository root and decide each value:

| Key | Decide |
|-----|--------|
| `logPrefix` | `[ACRONYM][Records]` for the project |
| `paths.commitMsgHook` | The hook file. With an existing hook manager, that runner's file |
| `subject.passthroughPrefixes` | The subjects accepted unchecked. `[]` turns pass-through off, for a project whose old validator never accepted `fixup!`, `squash!`, `amend!`, or `Merge ` |
| `subject.enforceFrom` | Optional commit SHA that starts `check-range` in place of the hook's install commit. Set it when the hook file predates adoption (see step 3) |
| `commitTypes` | Add workspace types with `section: null`; keep the list short |
| `scopeSections` | `security`, plus `legal` if the project publishes legal pages |
| `changelog.sectionOrder` | Reader priority; add `Removed` only with a removal ledger |
| `changelog.releaseFilter` | `export-ignore` when deploys use `git archive` and `.gitattributes` excludes tooling; otherwise `none` |
| `changelog.tagPattern` / `tagGlob` | The release model (see `changelog.md`) |
| `changelog.compareTarget`, `previewFrom`, `previewTo` | The branch that holds unreleased work and the refs the release pull request compares |
| `archive` | `{ "root": "<archive dir>/", "fileSuffix": "<plan suffix>" }` when work units are archived under one root, as files or folders; a key is the first path segment under `root`. A folder archive reads `{ "root": "plans/archive/completed/", "fileSuffix": ".plan.md" }`. Otherwise `null` |

The tool refuses an incomplete or inconsistent config (a type mapped to a section that is not in `sectionOrder`, an invalid pattern, a malformed `enforceFrom`) and names the key.

## 3. Scaffold

```powershell
$skill = '<path to tl-project-records>'
New-Item -ItemType Directory -Force scripts, docs/adr | Out-Null
Copy-Item "$skill/scripts/project-records.ps1" scripts/
Copy-Item "$skill/assets/templates/DEVLOG.md" DEVLOG.md
Copy-Item "$skill/assets/templates/CHANGELOG.md" CHANGELOG.md
Copy-Item "$skill/assets/templates/adr-README.md" docs/adr/README.md
Copy-Item "$skill/assets/templates/adr-template.md" docs/adr/template.md
```

Then branch on the survey's hook manager.

**No hook manager:**

```powershell
New-Item -ItemType Directory -Force .githooks | Out-Null
Copy-Item "$skill/assets/templates/commit-msg" .githooks/
Copy-Item "$skill/assets/templates/pre-commit" .githooks/   # only when archive is configured
git add --chmod=+x -- .githooks/commit-msg .githooks/pre-commit
git config core.hooksPath .githooks
```

On Windows, `git commit -- <paths>` rebuilds the named paths from the working tree, where there is no executable bit, so it commits a new hook as `100644` even after `git add --chmod=+x`. Commit the hooks from the index instead (`git commit -F <file>` with no pathspec, after `git diff --cached --name-status` shows only your paths), then confirm with `git ls-tree HEAD .githooks/`.

**Husky or lefthook:** do not create `.githooks/` and do not touch `core.hooksPath`; two managers fight over that setting.

- Add `pwsh -NoProfile -File scripts/project-records.ps1 check-msg "$1"` to the runner's `commit-msg` (`.husky/commit-msg`; in `lefthook.yml`, a `commit-msg` job with `{1}` for the message file). Add `check-commit` to its `pre-commit` only when `archive` is configured.
- Set `paths.commitMsgHook` to the runner's file.
- `check-range` starts at the first commit of that file, which predates adoption, so it would check every older subject. Set `subject.enforceFrom` to the commit the rule binds from, inclusive: the root commit when history conforms (step 4), else the adoption commit, pinned in a follow-up `chore(records)` commit once it exists. A commit between them is valid when `check-range -Base <root commit> -Head HEAD` exits 0 over the committed adoption.
- A validator already in that runner follows "Retiring a superseded commit-message validator" below.

Never overwrite an existing record. Merge: keep existing entries, convert their headings to the entry shape, and add the conventions header. The merge may make structural edits and no substantive ones:

- Adding a missing required DEVLOG heading with the content `None recorded at the time.`, or reordering an entry's existing sections, is structural.
- Normalizing an existing ADR's status line to `Accepted (<its Date bullet>)` is structural.
- Changing any sentence is substantive, and is not part of adoption.

Existing decisions keep their location:

- **One file per decision** (`docs/decisions/`): set `paths.adrDirectory` to it.
- **A single-file ledger of rulings** (`D-nn` entries for product, content, or rules decisions): leave it in place, and write the split into `docs/adr/README.md`: ADRs hold structural decisions that meet the trigger rule; the ledger holds rulings; an ADR cites the rulings it implements by id and never restates them. A DEVLOG entry cites either by id.

Then edit:

- The DEVLOG and CHANGELOG titles, and the CHANGELOG foot link (`OWNER/REPOSITORY`).
- The ADR README's first paragraph and its trigger rule, if the project's reversal-cost examples differ.
- `.gitattributes`: add `.githooks/* text eol=lf` when using `.githooks/`; if `releaseFilter` is `export-ignore`, add `export-ignore` lines for `scripts/project-records.ps1`, `records.config.json`, `docs/adr/`, `DEVLOG.md`, and the hook directory so record and tooling commits do not render as releases.
- `AGENTS.md`: paste `assets/templates/agents-md-records.md`.
- CI: paste `assets/templates/ci-records-job.yml`.

## 4. Seed

- **ADRs:** backfill decisions in effect and evidenced, under the backfill rules in `adr.md`. Start with the few that agents most often get wrong; a dozen good ADRs beat fifty thin ones.
- **DEVLOG:** one bounded pre-history entry, then one entry per significant past event, each tagged `retroactive` and citing commits. Stop at adoption.
- **CHANGELOG:** do not backfill releases from before the subject rule; old subjects do not parse. The tool decides where the first stanza starts, not a `git log` count:
  - Run `changelog-preview -From <root commit>` with the adopted config and read the stderr count line. **Zero skipped** means every release-bound subject in that history parses, so the first cut may use `-From` the root commit.
  - **Any skipped:** the `WARN` lines name the commits. When all of them are older than some point and a preview `-From` that point reports zero skipped, the first cut may use `-From` that point. Otherwise cut the first stanza `-From` the adoption base.
  - A hand-written `[Unreleased]` section is superseded by the first cut, and leftover lines would land inside the new stanza. Move its content into commit bodies or a DEVLOG entry and empty the section first; never keep it hand-edited.

## 5. Verify

```powershell
pwsh -NoProfile -File scripts/project-records.ps1 self-test   # exit 0
pwsh -NoProfile -File scripts/project-records.ps1 check       # exit 0
pwsh -NoProfile -File scripts/project-records.ps1 changelog-preview -From <last release or adoption base>
```

Then prove the hooks in a throwaway clone of the adoption branch: `git commit --allow-empty -m "Update stuff"` must be rejected with the allowed types listed, and `git commit --allow-empty -m "chore: hook probe"` must pass. `self-test` already runs the same probes against fixture repositories.

## Retiring a superseded commit-message validator

A project that already validates subjects (commitlint, a custom script) has two validators with different rules after adoption: two competing paths for one rule. Retire the old one:

1. List every rule it enforces.
2. Map each to `check-msg` (shape, types, scope, length, encoding, BOM, pass-through), or mark it uncovered. A pass-through the old validator never allowed is covered by `passthroughPrefixes: []`.
3. If every rule is covered, remove the old validator, its tests, its config, and any dependency only it used.
4. If a rule is uncovered, add it to the records tool with a self-test case, or keep the old validator chained after `check-msg` until it is. Record the gap and its owner.

## Retiring a superseded devlog convention

When a project moves from an older devlog format, update every pointer in the same change: `AGENTS.md`, the DEVLOG conventions header, workspace rules, and any skill amendment that names the old format. Leave dated history (past DEVLOG entries, accepted ADRs, archived plans) as written; it was true when written. The only edits allowed to it are the structural ones in step 3.
