# README Root Template

Template for the root `docs/README.md` index file.

---

## Template

```markdown
# Documentation

> **Last Updated:** {{DATE}}

Quick links to {{PROJECT_NAME}} documentation.

## Getting Started

- [Quick Start](./getting-started.md) — Get up and running in 5 minutes
- [Installation](./installation.md) — Detailed setup instructions

## Developer Guide

- [Architecture](./developer/architecture.md) — System design overview
- [Local Development](./developer/setup.md) — Dev environment setup
- [Testing](./developer/testing.md) — Test guidelines
- [Scripts](./developer/scripts/README.md) — CLI scripts reference

## Reference

- [API Reference](./reference/api/README.md) — REST endpoints
- [Configuration](./reference/config.md) — All configuration options
- [Environment Variables](./reference/env-vars.md) — Required and optional env vars

## Operations

- [Deployment](./operations/deployment.md) — Deploy to production
- [Monitoring](./operations/monitoring.md) — Observability setup
- [Troubleshooting](./operations/troubleshooting.md) — Common issues

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.
```

---

## Usage Notes

- Replace `{{DATE}}` with current date (YYYY-MM-DD)
- Replace `{{PROJECT_NAME}}` with actual project name
- Remove sections that don't apply
- Add sections as needed for project scope
- Keep links relative for portability

---

## Source Attribution

Based on JamBase `data.jambase.com/docs/README.md` hierarchical pattern.
