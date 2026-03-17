# CHANGELOG Template

Keep a Changelog 1.1.0 format for version history.

---

## Template

```markdown
# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- {{NEW_FEATURE_DESCRIPTION}}

### Changed

- {{CHANGED_BEHAVIOR_DESCRIPTION}}

### Fixed

- {{BUG_FIX_DESCRIPTION}}

## [{{VERSION}}] - {{DATE}}

### Added

- Initial release with {{CORE_FEATURES}}

[Unreleased]: https://github.com/{{OWNER}}/{{REPO}}/compare/v{{VERSION}}...HEAD
[{{VERSION}}]: https://github.com/{{OWNER}}/{{REPO}}/releases/tag/v{{VERSION}}
```

---

## Section Types

| Section | Use For |
|---------|---------|
| **Added** | New features for the user |
| **Changed** | Changes in existing functionality |
| **Deprecated** | Features to be removed in future |
| **Removed** | Removed features |
| **Fixed** | Bug fixes |
| **Security** | Vulnerability fixes |

---

## Rules

### Formatting

- Most recent version first
- ISO 8601 dates (YYYY-MM-DD)
- Each version links to git comparison
- Human-readable descriptions (not commit messages)

### What to Include

| Include | Example |
|---------|---------|
| User-facing features | "Added dark mode toggle" |
| Breaking changes | "Changed API response format" |
| Security fixes | "Fixed XSS vulnerability in comments" |
| Deprecations | "Deprecated legacy authentication endpoint" |

### What to Exclude

| Exclude | Why |
|---------|-----|
| Internal refactoring | Not user-visible |
| Dependency updates (minor) | Noise unless breaking |
| Build config changes | Not user-relevant |

---

## Yanked Releases

For pulled releases, add `[YANKED]`:

```markdown
## [1.2.1] - 2026-03-18 [YANKED]

Yanked due to critical bug in authentication.
```

---

## Commit-to-Changelog Mapping

| Commit Type | Changelog Section |
|-------------|-------------------|
| `feat:` | Added |
| `fix:` | Fixed |
| `perf:` | Changed |
| `BREAKING CHANGE:` | Changed (with note) |
| `security:` | Security |
| `deprecate:` | Deprecated |

---

## Example

```markdown
# Changelog

## [Unreleased]

### Added

- Magic link authentication for passwordless login
- Admin dashboard with analytics

## [1.2.0] - 2026-03-17

### Added

- User profile page with avatar upload
- Email notification preferences

### Changed

- Updated to React 19
- Improved form validation messages

### Fixed

- Memory leak in WebSocket connection handler
- Timezone display in event dates

### Security

- Fixed CSRF vulnerability in form submissions

## [1.1.0] - 2026-02-15

### Added

- Initial public release
- Core authentication flow
- Basic API endpoints

[Unreleased]: https://github.com/example/project/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/example/project/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/example/project/releases/tag/v1.1.0
```

---

## Source Attribution

Based on itechmeat changelog skill following Keep a Changelog 1.1.0 standard.
