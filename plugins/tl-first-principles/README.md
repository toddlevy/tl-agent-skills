# tl-first-principles Plugin

Cursor plugin bundling the First Principles rule and skill.

## Structure

This plugin uses symlinks to reference the canonical sources:

```
tl-first-principles/
├── .cursor-plugin/
│   └── plugin.json
├── rules/              → symlink to ../../rules/
│   └── first-principles.mdc
├── skills/             → symlink to ../../skills/tl-first-principles/
│   └── tl-first-principles/
│       ├── SKILL.md
│       ├── principles/
│       ├── founders/
│       └── sources/
└── README.md
```

## Setup (Windows Admin PowerShell)

Run these commands to create the symlinks:

```powershell
# Navigate to plugin directory
cd "D:\Documents\Projects\toddlevy\TL Agent Skills\tl-agent-skills\plugins\tl-first-principles"

# Create symlink for rules directory
New-Item -ItemType SymbolicLink -Path "rules" -Target "..\..\rules"

# Create symlink for skills directory  
New-Item -ItemType SymbolicLink -Path "skills" -Target "..\..\skills\tl-first-principles"
```

## What's Included

### Rule: first-principles.mdc
Always-apply rule that enforces adherence to foundational software design principles.

### Skill: tl-first-principles
Complete reference for 8 core principles with:
- Historical lineage (who, when, what work)
- Modern manifestations
- Anti-patterns
- Connections between principles
- Primary source bibliography with PDF links

## Principles Covered

| Principle | Founder | Year |
|-----------|---------|------|
| Information Hiding | Parnas | 1972 |
| Separation of Concerns | Dijkstra | 1974 |
| Abstraction & Contracts | Liskov, Hoare | 1974, 1969 |
| Single Source of Truth | Hunt & Thomas | 1999 |
| Conceptual Integrity | Brooks | 1975 |
| Fail Fast | Hamilton | 1960s |
| Composition Over Inheritance | GoF | 1994 |
| Explicit Over Implicit | Peters | 1999 |
