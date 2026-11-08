# ADR-0002: A long-lived semantic substrate with append-only, anchored records

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** Yonghe Xia
- **Related:** [design: 核心模型、存储](../design.qmd)

## Context

The first design was a converter: capture, annotate once with an agent, compile to a file. Two corrections from the owner showed it was the wrong shape:

- Semantics are not computed once. They are layered and staged, and keep being added and revised by several agents and by people.
- Figures change. Code and data get edited, and the work already done on a figure must follow it.

## Decision

**A figure is a long-lived object. Semantics are records in named layers, anchored to elements, and only ever appended.**

- **Substrate.** Produced by capture and read-only afterwards: a graphics interface (elements, leaves, panels, guides, geometry queries) and a data interface (tables with inferred, changeable row keys, and element ↔ row bindings with status).
- **Anchors.** Records point at targets through anchors, not element ids. An anchor carries several selectors, tried from most to least stable: data key, data predicate, structural path, role, data-space region, element id. Resolution is unique, ambiguous (with candidates) or missing.
- **Records and layers.** Every record has a layer, anchors, a body, provenance, status and dependencies. Four operations, all appends: add, revise (supersede), retract, verify. One JSONL log per layer. Layers form a dependency graph; custom layers carry their own schema.
- **Status propagation.** When the substrate changes, every anchor is re-resolved. Records that no longer resolve become invalid, and so does everything that depends on them. The invalid set is the repair task.
- **Conflicts.** Contradicting records coexist. They are resolved by a judgment made in context (checks, provenance, time, stated intent, scenario), written as a record with rationale. There is no fixed precedence. The only hard rule is that a claim whose check fails is never projected as fact.
- **Projections.** SVG, HTML, the accessibility tree and text descriptions are read-only outputs of substrate plus layers.
- **Bundle.** Two lossless forms: a directory (for version control) and a single SVG/HTML file that embeds the bundle and a sniffed context record (for distribution). `gl_read()` restores either.

## Alternatives considered

- **One-shot converter.** Rejected: work is lost on every change, and only one writer is possible.
- **Semantics stored as attributes inside the SVG.** Rejected: lost on re-capture, no history, no anchoring beyond element ids.
- **Mutable records.** Rejected: no history or undo, and concurrent writers silently overwrite each other.

## Consequences

### Positive

- History, diff, rollback and branching come from the logs. Many agents and sessions can keep writing.
- After an edit to the figure, only invalid records need repair.
- People, agents and other programs share one interface.

### Negative / accepted tradeoffs

- More machinery up front: anchor resolution, status propagation, a versioned bundle format.
- Conflict handling relies on recorded judgment rather than a rule, so the review stage and the status report have to make conflicts visible.

### Follow-ups

- M2: record schema, layer plugins, JSONL logs, anchor resolution, stable ids, status propagation, conflict records, `gl_rebase()`.
- M0: bundle read and write, including the single-file round trip.
