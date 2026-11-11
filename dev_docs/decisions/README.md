# Architecture Decision Records (ADRs)

ADRs record choices that would be expensive to reverse. Format follows Michael Nygard's lightweight template.

## Conventions

- **One file per decision.** Filename: `NNNN-short-slug.md`, zero-padded sequence number.
- **Immutable once accepted.** If a decision is overturned, write a new ADR that supersedes it and edit only the `Status` line of the old one.
- **Status values:** `Proposed`, `Accepted`, `Superseded by ADR-NNNN`, `Deprecated`.
- **Keep it short.** Context, evidence, decision, consequences. Discussion goes in `dev_logs/`.
- **Rest on evidence.** Link the measurement, test or dev log that forced or supports the decision. A decision taken before any measurement says so, and stays `Proposed` while the measurement that would settle it is still to come (for example, the anchor hit rate that M2 measures).
- **Name what would reopen it.** `Revisit when` gives an observable condition (a number crossing a threshold, a class of figures that fails); when it occurs, write the superseding ADR or record why the decision still stands.

The decision to build gloss as a standalone package is recorded in ggai: [ggai ADR-0004](https://github.com/YuLab-SMU/ggai/blob/main/dev_docs/decisions/0004-semantic-figure-substrate-as-standalone-package.md).

## Template

See [`_template.md`](_template.md).

## Index

| # | Title | Status | Date |
|---|-------|--------|------|
| [0001](0001-capture-by-group-delimiting-and-probes.md) | Capture elements by graphics-group delimiting plus probes | Accepted | 2026-11-08 |
| [0002](0002-semantic-substrate-with-append-only-records.md) | A long-lived semantic substrate with append-only, anchored records | Accepted | 2026-11-08 |
| [0003](0003-plugin-based-core.md) | Plugin-based core | Accepted | 2026-11-08 |
| [0004](0004-engine-dispatch-through-the-registry.md) | `gloss()` dispatches to engine plugins through the registry | Accepted | 2026-11-09 |
| [0005](0005-bundle-format-v0.md) | Bundle format v0 | Accepted | 2026-11-09 |
| [0006](0006-capture-the-page-the-figure-draws.md) | Capture the page the figure draws, not a grob built from the object | Accepted | 2026-11-11 |
| [0008](0008-held-out-role-labels-by-one-labeller-and-an-independent-sample.md) | Held-out role labels: annotator A labels every figure, people label a seeded sample independently (0007 is kept for the M1 plan's Task 6) | Accepted | 2026-11-11 |
