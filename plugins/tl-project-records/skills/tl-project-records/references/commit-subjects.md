# Commit subjects

The changelog is rendered from commit subjects, so a subject is a release note written at commit time. The commit-msg hook rejects any subject the renderer cannot read.

## Shape

```
type(scope): subject
type: subject
type(scope)!: subject
```

- `type` is one of `commitTypes[].type` in `records.config.json`. The hook names the allowed list when it rejects.
- `scope` is optional, one word of lowercase letters, digits, and hyphens. One scope only: `feat(api, ui): ...` is rejected. Split the commit instead.
- `!` before the colon marks a breaking change. It is accepted; describe the break in the body.
- One space after the colon, then a non-blank subject.
- The subject line is at most `subject.maxLength` characters (100 in the template).
- The first non-blank line that does not start with `#` is the subject.

## Types and where they render

The template vocabulary:

| Type | Renders under | Use for |
|------|---------------|---------|
| `feat` | Added | A new capability a release reader would notice |
| `fix` | Fixed | A defect correction |
| `perf` | Changed | A performance change with no behavior change |
| `refactor` | Changed | Restructuring with no behavior change |
| `revert` | Changed | Reverting an earlier change (git's own `Revert "..."` also passes) |
| `docs` | not rendered | Documentation, including record updates: `docs(records): ...` |
| `build` | not rendered | Build system and dependencies |
| `chore` | not rendered | Maintenance with no product effect |
| `ci` | not rendered | CI configuration |
| `test` | not rendered | Tests only |
| `style` | not rendered | Formatting only |

A workspace adds types (for example `plan`, `notes`, `research`) by adding entries with `section: null`. Keep the list short: every type is a choice an author must make correctly.

## Reserved scopes

A scope in `scopeSections` moves the bullet to a named section regardless of type. The template reserves `security`: a `feat`, `fix`, `perf`, `refactor`, or `revert` that changes a security or privacy boundary uses `(security)` so the release reader sees it under Security. A project with published legal pages typically adds `"legal": "Legal"`. The reservation only works if authors use it; say so in `AGENTS.md`, and check the history (`git log --format=%s | Select-String '\((security|legal)\)'`) before claiming the section is populated.

## Pass-through subjects

Subjects starting with a `subject.passthroughPrefixes` entry are accepted unchecked: `Merge `, `Revert "`, `fixup! `, `squash! `, `amend! `. These are written by git itself. Merge commits never render; fixup and squash commits should be gone by merge time.

## Writing the subject

- Write for the release reader: what changed for them, in the imperative or a short noun phrase. `fix(auth): keep the session when the refresh token rotates`, not `fix: bug`.
- Lowercase after the colon unless a proper noun starts it. No trailing period.
- The body explains why, and names `ADR-NNNN`, issues, and follow-ups.
- One logical change per commit. If the subject needs "and", it is probably two commits.

## Message files on Windows

Commit messages with more than one line go through a file. Two defects are common on Windows PowerShell:

- **Byte order mark.** `Set-Content -Encoding utf8` on Windows PowerShell 5.1 prepends `EF BB BF`, and git folds it into the subject as an invisible `U+FEFF`. The hook reads the message as bytes and rejects a BOM. Write with `[System.IO.File]::WriteAllText($path, $message, (New-Object System.Text.UTF8Encoding $false))`, which writes no BOM on 5.1 and 7.
- **Shared temp file names.** A fixed name such as `COMMIT_MSG.txt` collides when two sessions commit at once. Use a unique name.

```powershell
$message = @'
feat(import): chunked CSV import with progress reporting

The synchronous importer timed out behind the load balancer. See ADR-0009.
'@
$messagePath = Join-Path $env:TEMP ("commit-msg-" + [guid]::NewGuid().ToString('N') + ".txt")
[System.IO.File]::WriteAllText($messagePath, $message, (New-Object System.Text.UTF8Encoding $false))
git commit -F $messagePath -- src/import
Remove-Item -LiteralPath $messagePath
```

Never use a bash heredoc in PowerShell. In bash, `git commit -F - <<'EOF'` is fine.

## History before the hook

Adopting the rule on a project with history leaves non-conforming subjects behind. Do not rewrite or allowlist them. `check-range` checks only commits that descend from the commit that first added the hook file, so CI starts enforcing at adoption, and the renderer warns on and skips the old ones.
