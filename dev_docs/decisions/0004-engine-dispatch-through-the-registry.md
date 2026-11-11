# ADR-0004: `gloss()` dispatches to engine plugins through the registry

- **Status:** Accepted; engine contract amended by [ADR-0006](0006-capture-the-page-the-figure-draws.md) (`grob(state)` removed)
- **Date:** 2026-11-09
- **Deciders:** Yonghe Xia
- **Related:** [ADR-0003](0003-plugin-based-core.md), [plan/2026-11-09-m0-substrate.md](../../plan/2026-11-09-m0-substrate.md), [dev log](../../dev_logs/2026-11-09-m0-substrate.md)

## Context

ADR-0003 says an engine plugin provides "a capture method (an S3 method for `gloss()`)". Implementing M0 showed that this would make an engine two things: an S3 method on `gloss()` and a registry entry. A third-party package would then need both, and the registry could disagree with S3 dispatch about which engine handles a class.

## Decision

**`gloss()` stays an S3 generic, and `gloss.default()` chooses the engine from the registry by the classes each engine plugin declares.**

- An engine plugin declares `classes` and provides `prepare(x, width, height)` and `grob(state)`. It may also provide `tables(state)`, `panels(state, substrate)`, `describe(state)` and `example()`.
- `gloss.default()` walks `class(x)` in order and takes the first engine that declares that class; among engines declaring the same class, the one registered last wins. `gloss(x, engine = "name")` overrides the choice.
- The capture itself (`gl_capture()`) is core and the same for every engine: engines only turn their object into a grob and describe their tables and panels.
- A package may still define its own `gloss()` S3 method; nothing in gloss relies on it.

## Alternatives considered

- **An S3 method per engine, as ADR-0003 worded it.** Rejected: two registrations per engine, and the manifest would record a plugin that dispatch never consulted.
- **Engines decide with an `accepts(x)` predicate.** Rejected for now: order-dependent and harder to explain than class matching. It can be added as an optional field if a real engine needs it.

## Consequences

### Positive

- One registration per engine, for built-in and third-party engines alike; a test registers a toy engine and captures through `gloss()`.
- The engine recorded in the manifest is the one that captured the figure.

### Negative / accepted tradeoffs

- Two engines declaring the same class are resolved by registration order. The override argument is the escape hatch.

### Follow-ups

- ADR-0003's wording "an S3 method for `gloss()`" is superseded on this point only.
