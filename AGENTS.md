# Repository Guidelines (gloss v2)

`gloss` is the **Source Map and Asset Preparation Core for R Figures**. Its canonical design is [`dev_docs/architecture-v2.md`](dev_docs/architecture-v2.md). The v1 prototype is archived on branch `v1-archive`.

## Core Principles

1. **Compiler Source Map, Not Gatekeeper**: R plots are deterministic programmatic artifacts (`code + data -> engine IR -> device SVG`). Core code faithfully observes and records device groups, viewports, engine intermediate representations (`raw`/`built` tables, `scales`, `layers`, `panels`, draw-time orders), and structural lineage. Do not build pixel back-substitution courts, double-redraw gates, or `withheld` data blocks into the core. Verification belongs to upper-layer semantic skills and audit tools.
2. **Strict In-Core Boundary**: The R package handles only what requires a live R session and graphics device: capture instrumentation, engine IR extraction, runtime source inventory, and open-format packaging (`Asset Map` and `Asset Bundle`). Task intent planning, agent loops, MCP servers, interactive frontends (Workbench), and SVG derivation live outside the core package.
3. **Single Capture, Layered Payload**: `Asset Map` and `Asset Bundle` derive from the same capture state so plots are never redrawn to package assets. They differ only in serialized payload size (metadata/IR summary vs. full tables and source files).
4. **Zero Proprietary Codecs (File-First)**: Never invent custom binary encodings or non-standard JSON dialects. Output standard UTF-8 SVG, JSON, and CSV (or Parquet for large tables) readable out of the box by Python, JS, DuckDB, R, and external coding agents.
5. **Minimal Surface**: Keep exports tight (`gloss()`, `gl_asset_map()`, `gl_asset_bundle()`, `gl_scene()`, `gl_tables()`, `gl_sources()`, `gl_query()`, `gl_register_engine()`). Keep built-in engines (`ggplot`, `patchwork`, `heatmap`, `base`, `grid`) in-repo with package dependencies in `Suggests`.

## Build, Test, Check

- `Rscript -e "devtools::document()"` — regenerate `NAMESPACE` and `man/*.Rd`.
- `NOT_CRAN=true Rscript -e "devtools::test()"` — run the test suite.
- `R CMD build --no-build-vignettes .` then `R CMD check --no-manual gloss_*.tar.gz` — verify CRAN hygiene (`tempdir()` defaults, no `<<-`, no `.GlobalEnv` writes, no `Rplots*.pdf`).
