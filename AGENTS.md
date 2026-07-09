# AGENTS.md — tl-agent-skills

## Canonical source location

The canonical source for all skills in this repo is:

```
D:\Documents\Projects\TL Agent Skills\tl-agent-skills\
```

**Never edit the installed copy at `C:\Users\Todd\.agents\skills\`.** That directory is a mirror — skills are installed there by the Windsurf/Cascade skill loader from the canonical source. Edits to the installed copy are silently overwritten on the next sync and are invisible to git. Any change to a skill must be made in this repo, then the installed copy will reflect it after the next sync.

## Repository layout

```text
skills/
  tl-agent-plan-create/   Plan authoring skill (SKILL.md + references/ + templates/)
  tl-agent-plan-audit/    Plan audit skill (SKILL.md + references/)
  tl-agent-plan-execute/  Plan execution skill (SKILL.md + references/)
rules/                    Companion Cursor rules (if any)
plugins/                  Plugin manifests (if any)
scripts/                  Maintenance scripts
DEVLOG.md                 Development log
```

## Editing discipline

- Edit `skills/<name>/SKILL.md` and its `references/` files for skill content changes.
- All three skills version together; update the `metadata.version` field in the edited skill's frontmatter on every meaningful change.
- Do not add per-skill `version` fields outside the frontmatter `metadata:` block.
- After editing, the installed copy at `C:\Users\Todd\.agents\skills\<name>\` must be refreshed manually (copy or sync) before the change is visible to the agent skill loader.
