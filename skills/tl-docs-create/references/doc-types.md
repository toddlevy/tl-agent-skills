# Documentation Types

Patterns and guidelines for each documentation artifact type. Synthesized from shpigford (README), getsentry (AGENTS.md), itechmeat (CHANGELOG), patricio0312rev (API docs), and jezweb (lifecycle).

---

## README.md

The project entry point. Serves three purposes: Deploy, Understand, Develop.

### Core Principles (from shpigford)

1. **Exploration first** — Understand the codebase deeply before writing
2. **Three purposes** — Every README should let someone deploy, understand, and develop
3. **Absurd thoroughness** — When in doubt, include it

### Section Structure

| Section | Purpose | Required |
|---------|---------|----------|
| Title + Description | What is this, one sentence | Yes |
| Quick Start | Fastest path to running | Yes |
| Installation | Complete setup steps | Yes |
| Usage | How to use the thing | Yes |
| Configuration | All options explained | If applicable |
| Architecture | How it works | For complex projects |
| Development | How to contribute | For OSS/team projects |
| Deployment | How to ship to production | Yes |
| Troubleshooting | Common issues and fixes | Recommended |

### Project Type Variations (from softaworks)

| Type | Focus | Minimal Sections |
|------|-------|------------------|
| **OSS Library** | Usage, API, examples | Title, Install, Usage, API, Contributing |
| **Internal Tool** | Setup, workflow | Title, Quick Start, Configuration |
| **Personal Project** | Future self | Title, What, Why, How to Run |
| **Config Repo** | What each file does | Title, Structure, Files Explained |

### Audience Considerations

| Audience | Emphasize | De-emphasize |
|----------|-----------|--------------|
| Contributors | Dev setup, architecture, testing | Deployment |
| Users | Quick start, usage, examples | Internal architecture |
| Operators | Deployment, monitoring, config | Code architecture |

---

## AGENTS.md

Minimal context file for AI assistants. From getsentry skill.

### Core Principles

1. **Under 60 lines** — Instruction quality degrades with length
2. **File-scoped commands** — Per-file test/lint/typecheck over project-wide
3. **No filler** — No intros, conclusions, pleasantries
4. **Reference, don't embed** — Point to existing docs

### Required Sections

```markdown
# AGENTS.md

## Commands

Test: `pnpm test`
Lint: `pnpm lint`
Type check: `pnpm typecheck`
Build: `pnpm build`

## File-Scoped Commands

Test single file: `pnpm test path/to/file.test.ts`
Lint single file: `pnpm lint path/to/file.ts`

## Conventions

- Use TypeScript strict mode
- Prefer named exports
- Co-locate tests with source

## Do NOT

- Modify package.json without discussion
- Add dependencies without checking existing ones
- Skip type definitions
```

### Anti-Patterns

| Avoid | Why |
|-------|-----|
| Duplicating linter rules | Style lives in config files |
| Long explanations | Brevity is critical |
| Generic advice | Be project-specific |
| Restating READMEs | Link instead |

### Commit Attribution

AI-generated commits MUST include:

```
Co-Authored-By: assistant-name <assistant@example.com>
```

---

## CHANGELOG.md

Version history in Keep a Changelog 1.1.0 format. From itechmeat skill.

### Format

```markdown
# Changelog

All notable changes to this project are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- New feature description

## [1.2.0] - 2026-03-17

### Added
- User authentication with magic links
- Admin dashboard

### Changed
- Updated to React 19

### Fixed
- Memory leak in WebSocket handler

## [1.1.0] - 2026-02-15

### Added
- Initial API endpoints

[Unreleased]: https://github.com/user/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/user/repo/releases/tag/v1.1.0
```

### Section Types

| Section | Use For |
|---------|---------|
| **Added** | New features |
| **Changed** | Changes in existing functionality |
| **Deprecated** | Soon-to-be removed features |
| **Removed** | Removed features |
| **Fixed** | Bug fixes |
| **Security** | Vulnerability patches |

### Rules

- ISO 8601 dates (YYYY-MM-DD)
- Most recent version first
- Each version links to git comparison
- Human-readable, not git log dumps
- Update README if changelog documents feature changes

### Yanked Releases

For pulled releases:

```markdown
## [1.2.1] - 2026-03-18 [YANKED]

Yanked due to critical bug in authentication.
```

---

## API Reference

Documentation for REST/GraphQL endpoints or library functions. From patricio0312rev skill.

### REST Endpoint Format

```markdown
# Create User

Creates a new user account.

## Request

`POST /api/users`

### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | Bearer token |
| `Content-Type` | Yes | `application/json` |

### Body

```json
{
  "email": "user@example.com",
  "name": "Jane Doe"
}
```

### Body Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | Yes | Valid email address |
| `name` | string | Yes | Display name (2-100 chars) |

## Response

### Success (201 Created)

```json
{
  "id": "usr_abc123",
  "email": "user@example.com",
  "name": "Jane Doe",
  "createdAt": "2026-03-17T10:00:00Z"
}
```

### Errors

| Status | Code | Description |
|--------|------|-------------|
| 400 | `VALIDATION_ERROR` | Invalid input |
| 409 | `EMAIL_EXISTS` | Email already registered |
| 401 | `UNAUTHORIZED` | Invalid or missing token |
```

### One API Per Page Rule (from remotion)

Each endpoint or function gets its own page. Don't combine multiple endpoints.

### OpenAPI Integration

For complex APIs, generate from OpenAPI spec:

```yaml
openapi: 3.1.0
info:
  title: My API
  version: 1.0.0
paths:
  /api/users:
    post:
      summary: Create user
      # ... full spec
```

---

## docs/ Folder Structure

For comprehensive documentation scope.

### Recommended Structure

```
docs/
├── README.md              # Index with quick links
├── getting-started.md     # Quick start guide
├── architecture.md        # System overview
├── developer/
│   ├── README.md          # Developer section index
│   ├── setup.md           # Local dev setup
│   ├── testing.md         # Test guidelines
│   └── scripts/
│       └── README.md      # Scripts index
├── reference/
│   ├── README.md          # Reference section index
│   ├── api/
│   │   └── README.md      # API index
│   ├── config.md          # Configuration reference
│   └── env-vars.md        # Environment variables
└── operations/
    ├── README.md          # Operations index
    ├── deployment.md      # Deploy guide
    └── monitoring.md      # Observability
```

### Hierarchical READMEs

Each directory has a README that:
- Introduces the section
- Links to all pages in the section
- Notes what audience this serves

---

## Lifecycle Management (from jezweb)

Commands for documentation maintenance.

### `/docs-init`

Initialize documentation structure:
1. Create AGENTS.md if missing
2. Create README.md if missing
3. Create docs/ skeleton if comprehensive scope

### `/docs-update`

Audit and update existing docs:
1. Check for staleness (no updates in 30+ days)
2. Verify links aren't broken
3. Compare versions against package.json
4. Flag outdated references

### Staleness Indicators

| Age | Action |
|-----|--------|
| 30+ days | Review for accuracy |
| 90+ days | Likely needs updates |
| 180+ days | Verify still relevant |

### Version Drift Detection

Compare doc mentions against actual:
- Dependency versions
- Node.js version
- API versions
- Feature flags
