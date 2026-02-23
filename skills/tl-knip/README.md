# tl-knip

Find and remove unused files, dependencies, and exports in TypeScript/JavaScript projects using [Knip](https://knip.dev).

Part of [tl-agent-skills](https://github.com/toddlevy/tl-agent-skills).

## What This Skill Covers

- Configuration-first workflow for accurate dead code detection
- Barrel file and re-export handling (common false positive source)
- Plugin ecosystem: 80+ frameworks auto-detected
- Agent-specific guidance: auto-delete vs ask-first categorization
- CI integration with GitHub Actions examples
- Monorepo workspace configuration
- Systematic troubleshooting

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill: workflow, quick commands, agent guidance |
| `references/configuration.md` | Complete `knip.json` / `knip.ts` option reference |
| `references/plugins.md` | Full plugin ecosystem with all frameworks and tools |
| `references/barrel-files.md` | Barrel file and re-export false positive handling |
| `references/troubleshooting.md` | Systematic diagnosis for common issues |
| `scripts/knip-check.sh` | Tiered health check script (bash) |
| `scripts/knip-check.ps1` | Tiered health check script (PowerShell) |

## Knip License Notice

This skill documents [Knip](https://knip.dev), which is © webpro-nl and contributors, licensed under the [ISC License](https://github.com/webpro-nl/knip?tab=ISC-1-ov-file#readme).

This skill is independent documentation. It is not affiliated with or endorsed by the Knip project. The skill itself is MIT licensed.

## Quilted Source Skills

| Source | Weight |
|--------|--------|
| [brianlovin/claude-config](https://skills.sh/brianlovin/claude-config/knip) | 35% |
| [laurigates/claude-plugins](https://skills.sh/laurigates/claude-plugins/knip-dead-code-detection) | 30% |
| [artivilla/agents-config](https://skills.sh/artivilla/agents-config/knip) | 20% |
| [knoopx/pi](https://skills.sh/knoopx/pi/knip) | 10% |
| [pproenca/dot-skills](https://skills.sh/pproenca/dot-skills/knip-deadcode-best-practices) | 5% |

## Links

- [Knip — GitHub](https://github.com/webpro-nl/knip) (ISC License)
- [Knip docs](https://knip.dev)
- [Configuration reference](https://knip.dev/reference/configuration)
- [Plugin list](https://knip.dev/reference/plugins)
