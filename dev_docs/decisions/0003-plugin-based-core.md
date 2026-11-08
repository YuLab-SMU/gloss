# ADR-0003: Plugin-based core

- **Status:** Accepted
- **Date:** 2026-11-08
- **Deciders:** Yonghe Xia
- **Related:** [design: 插件机制](../design.qmd), [ADR-0002](0002-semantic-substrate-with-append-only-records.md)

## Context

Almost everything in gloss varies along some axis: engine (ggplot, ComplexHeatmap, base, extension packages), output format, operation, scenario, agent task. The owner asked for the package to be built as plugins so it stays easy to maintain and extend, and for features to start simple and grow with real needs.

## Decision

**The core holds only the substrate, anchors, records, verification and a plugin registry. Everything else is a plugin, and built-in features register the same way as third-party ones.**

Eight extension points share one registration call, `gl_register(kind, name, version, schema, ...)`:

| Kind | A plugin provides |
|---|---|
| engine | capture method (an S3 method for `gloss()`), data tables, structure tree, bindings |
| classify rules | match conditions → role and kind |
| layer | layer name, body schema, dependencies, verification |
| check | argument schema, execution on data tables |
| operation | argument schema, R-side materialization, JS-side handler |
| projection / exporter | layers read, output format |
| context sniffer | sniffing and restoring one item of context |
| agent stage | layers read and written, prompt, tool subset |

- Each plugin declares its name, version, required core API version and schema; registration validates them.
- Other packages register in `.onLoad()`; gloss needs no knowledge of them.
- The bundle manifest records which plugins and versions were used. A missing plugin does not block restoring: the affected records are marked as missing a plugin and kept.
- Each extension point has shared contract tests, `gl_test_plugin()`, used for built-in plugins too.
- The browser runtime is a small kernel plus one file per operation; a projection bundles only the operations it uses.

## Alternatives considered

- **S3 generics only.** Rejected as the general mechanism: they fit engines, but not paired R + JS operations, layer schemas or versioned manifests. S3 dispatch is kept for `gloss()` itself, inside engine plugins.
- **Hard-coded built-ins with hooks for extras.** Rejected: two code paths, and the hooks never cover what the built-ins can do.

## Consequences

### Positive

- Each feature can be maintained and tested in isolation.
- Third-party packages (for example a survival-curve extension) can add an engine, rules and checks without changing gloss.
- Features can start small and be added when a real scenario needs them.

### Negative / accepted tradeoffs

- Registry and versioning overhead from day one.
- The plugin API has to be stabilized early, because external plugins will depend on it.

### Follow-ups

- M0: registry, plugin schema, `gl_register()`, `gl_test_plugin()`.
