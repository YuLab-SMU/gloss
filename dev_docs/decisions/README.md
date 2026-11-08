# Architecture Decision Records (ADRs)

ADRs record choices that would be expensive to reverse. Format follows Michael Nygard's lightweight template.

## Conventions

- **One file per decision.** Filename: `NNNN-short-slug.md`, zero-padded sequence number.
- **Immutable once accepted.** If a decision is overturned, write a new ADR that supersedes it and edit only the `Status` line of the old one.
- **Status values:** `Proposed`, `Accepted`, `Superseded by ADR-NNNN`, `Deprecated`.
- **Keep it short.** Context, decision, consequences. Discussion goes in `dev_logs/`.

The decision to build gloss as a standalone package is recorded in ggai: [ggai ADR-0004](https://github.com/YuLab-SMU/ggai/blob/main/dev_docs/decisions/0004-semantic-figure-substrate-as-standalone-package.md).

## Template

See [`_template.md`](_template.md).

## Index

| # | Title | Status | Date |
|---|-------|--------|------|
| [0001](0001-capture-by-group-delimiting-and-probes.md) | Capture elements by graphics-group delimiting plus probes | Accepted | 2026-11-08 |
| [0002](0002-semantic-substrate-with-append-only-records.md) | A long-lived semantic substrate with append-only, anchored records | Accepted | 2026-11-08 |
| [0003](0003-plugin-based-core.md) | Plugin-based core | Accepted | 2026-11-08 |
