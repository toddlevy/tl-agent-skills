# AGENTS.md -- tl-agent-skills

## Canonical source location

The canonical source for every **published** skill in this repo is:

```
D:\Documents\Projects\TL Agent Skills\tl-agent-skills\
```

**Never edit the installed copy at `C:\Users\Todd\.agents\skills\` for skills that ship from this repo.** That directory is a mirror -- canonical skills are installed there via `npx skills add toddlevy/tl-agent-skills -g -y --agent universal`. Edits on the mirror are silently overwritten on the next sync and are invisible to git. Author changes in this repo, then refresh the mirror with the install command above.

### Mirror-only exceptions (not in this repo)

Two `tl-*` skills are **explicit exceptions**: they are **not** canonical on D:, **not** under `skills/` here, and **not** updated by editing this repo.

| Skill | Policy |
| --- | --- |
| `tl-agent-skills-quilt` | Frozen installer-owned import in `C:\Users\Todd\.agents\skills\`. Read-only on C:. Update only by reinstalling from upstream (skills installer / skills.sh). Promote to D: only by an explicit future operator decision. |
| `tl-dev-startup-orchestration` | Same as above. |

Do not hand-edit their `SKILL.md` on C:. Do not add folders for them under this repo unless promoting them into the published roster.

## Repository layout

```text
skills/                   Published tl-* skills (see README.md roster)
rules/                    Companion Cursor rules (tl-*.mdc)
plugins/                  Plugin manifests (if any)
scripts/                  Maintenance scripts (e.g. sync-global-rules.ps1)
DEVLOG.md                 Development log
```

The skill roster and install/sync commands are documented in [README.md](README.md).

## Editing discipline

- Edit `skills/<name>/SKILL.md` and its `references/`, `scripts/`, and `assets/` for skill content changes.
- The **plan suite** (`tl-agent-plan-create`, `tl-agent-plan-audit`, `tl-agent-plan-execute`) share release discipline: bump `metadata.version` in the edited plan skill's frontmatter on every meaningful plan-suite change (keep the three versions aligned when a change spans the suite).
- Other skills maintain their own `metadata.version` (or documented version field) per skill; do not add stray `version:` keys outside frontmatter conventions.
- After editing on D:, refresh the global mirror: `npx skills add toddlevy/tl-agent-skills -g -y --agent universal`. That command updates only skills from `toddlevy/tl-agent-skills` and leaves the two mirror-only exception directories untouched.
- After editing `rules/`, run `.\scripts\sync-global-rules.ps1` to mirror into `~/.cursor/rules/tl-agent-rules/`.
