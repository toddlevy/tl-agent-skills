## Project records

Three records, each answering one question. Keep each fact in one home.

| Record | Question it answers | Written when |
|--------|---------------------|--------------|
| `docs/adr/` | Why is the project shaped this way? | A change meets the trigger rule in `docs/adr/README.md` |
| `DEVLOG.md` | What happened, when, and why? | Close-out, release, incident, or an ADR-producing decision |
| `CHANGELOG.md` | What did each release change? | Rendered at release by `changelog-cut`; never hand-edited |

- Commit subjects are Conventional (`type(scope): subject`); `.githooks/commit-msg` rejects any other shape and names the allowed types. The changelog is rendered from these subjects, so a subject is written for a release reader.
- The ADR trigger rule has one home, `docs/adr/README.md`. Link it; do not restate it.
- Run `git config core.hooksPath .githooks` once per clone.
- Write commit messages to a file without a byte order mark and commit with `git commit -F <file>`.

| Gate | Surface |
|------|---------|
| `./scripts/project-records.ps1 check` | ADR numbering, headers, and index; DEVLOG structure; CHANGELOG stanzas and tags |
| `./scripts/project-records.ps1 self-test` | The records tool itself, against temp-repo fixtures |
| `./scripts/project-records.ps1 changelog-preview` | What the next release carries; read-only |
