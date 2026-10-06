# Wiring

Records stay current when writing them is a side effect of ceremonies the project already runs, and when the mechanical rules fail closed. Each rail below has a backstop, because each local rail can be bypassed.

| Rail | Enforces | Runs | Bypass | Backstop |
|------|----------|------|--------|----------|
| `.githooks/commit-msg` | Subject shape | Every local commit | `--no-verify`, or hooks not installed | `check-range` in CI |
| `.githooks/pre-commit` | Archive rule: an archived work unit is named in the staged DEVLOG | Every local commit | Same | `check` (archived key coverage) |
| `check` | ADR, DEVLOG, CHANGELOG structure across the tree | Locally, in CI, at close-out | Not running it | CI `records` job |
| `check-range` | Subjects in a pull request | CI | None once the job is required | Branch protection |
| `changelog-cut` | The stanza is rendered, not typed | Release step | Hand-editing CHANGELOG.md | `check` on headings and tags |
| `AGENTS.md` section | Agents know the rules | Every agent session | An agent that does not read it | The hooks |

## Hooks

Hooks live in `.githooks/` (tracked) and are activated per clone:

```powershell
git config core.hooksPath .githooks
```

- Commit them with LF line endings and the executable bit: `git add --chmod=+x -- .githooks/commit-msg .githooks/pre-commit`, committed from the index rather than with a pathspec (see `adoption.md`), and checked with `git ls-tree HEAD .githooks/`. Add `.githooks/* text eol=lf` to `.gitattributes`. A CRLF shebang fails on Linux and macOS with a confusing "not found".
- Both shims call `pwsh`. PowerShell 7 must be on `PATH` for every committer, including CI runners (GitHub's hosted runners have it).
- Git runs hooks from the repository root, so the shims use the repository-relative path `scripts/project-records.ps1`.
- The pre-commit shim's `exec` must be the last line. Chain any other pre-commit check above it with `|| exit 1`, so a failure stops the commit before the records check replaces the shell.
- Install `pre-commit` only when `archive` is configured. With no archive rule it only prints "not configured" on every commit.
- A repository that already uses Husky or lefthook adds the two commands to that runner instead of switching `core.hooksPath`; two hook managers fight over the same setting.

## CI job

Paste `assets/templates/ci-records-job.yml` under `jobs:` in the pull-request workflow.

- `fetch-depth: 0` is required. In a shallow clone `check-range` cannot find the hook's install commit and exits 1 by design.
- Start the job non-required. Promote it to a required check once `check` has passed on the default branch for a few pull requests.
- `self-test` in CI catches a records-tool edit that broke a rule.

## Close-out ceremony

When a work unit (plan, epic, cycle, milestone) closes:

1. Write the ADR for every decision in the work unit that meets the trigger rule in `docs/adr/README.md`, and add its index row.
2. Write the DEVLOG close-out entry (category `milestone`). Name the work unit's key exactly as it will appear under the archive root. List the ADRs under Related.
3. Move the work unit to the archive root and stage the DEVLOG in the same commit. The pre-commit rail refuses the archive otherwise.
4. Run `check` and report its exit code.
5. Commit by pathspec: `git commit -F <message file> -- DEVLOG.md docs/adr <archived paths>`, subject `docs(records): close <key>`.

## Release step

See the release procedure in `changelog.md`. The release pull request body is the `changelog-preview` output; the stanza is written by `changelog-cut` after the tag exists.

## AGENTS.md

Paste `assets/templates/agents-md-records.md` into `AGENTS.md`. Keep it short and pointing outward: the trigger rule lives in `docs/adr/README.md`, the DEVLOG conventions in the DEVLOG header, and the commit vocabulary in `records.config.json`. `AGENTS.md` names where each rule lives; it does not hold a second copy.

## Shared working trees

When more than one agent session shares a working tree and index:

- Commit by pathspec only (`git commit -F <file> -- <paths>`), after `git diff --cached --name-status` shows only your paths. A bare `git commit` sweeps another session's staged work into yours.
- Never `reset`, `checkout`, `restore`, `stash`, or `clean` a shared tree to get your commit through.
- Record files are append-mostly, so concurrent sessions conflict on them. Write the entry last, right before the commit.
