# Project Name - Development Log

A living record of decisions, milestones, incidents, and lessons: what happened, when, and why. Entries run newest first.

## Conventions

- **Entry format:** `## [YYYY-MM-DD] Title`, then `**Category:**`, `**Tags:**`, `### Summary`, `### Detail`, and `### Related`, in that order.
- **Categories:** exactly one of `architecture`, `milestone`, `incident`, `bug`, `ops`, `design`, `strategy`, `takeaway`.
- **Triggers:** a work-unit close-out, a production release, a live incident, and any decision that produces an ADR. In-flight work is not logged.
- **Decisions:** the reasons for a decision live in its ADR; the entry links it as `ADR-NNNN` under Related and does not restate it.
- **Seeded entries:** an entry written after the fact carries the tag `retroactive`.
- **Commits:** a standalone entry is committed as `docs(records): <title>`.
- **Enforcement:** `./scripts/project-records.ps1 check` validates every entry.

---
