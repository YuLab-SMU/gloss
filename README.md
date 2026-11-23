# gloss

**Source Map and Asset Preparation Core for R Figures**

`gloss` captures what happens inside an R plotting session before it evaporates into a flat image, turning R figures into open, cross-language assets for external AI skills, interactive frontends, and analysis scripts:

- **Device Capture & Instrumentation**: preserves both the untouched `original.svg` and an addressable `scene.svg` with deterministic `<g>` leaf groups and draw-time viewport coordinates.
- **Engine Intermediate Representation (IR)**: snapshots `raw` and `built` tables, scale & palette dictionaries (`domain <-> hex/shape/size`), layer specifications (`geom`, `stat`, `position`, `aes`), facet layouts, and draw-time permutations (such as `ComplexHeatmap` clustering orders).
- **Structural Lineage**: records correspondences (`element <-> leaf <-> viewport <-> panel <-> layer/table`) and cardinalities (`1:1`, `N:1`, `1:M`, `stat_aggregated`) as neutral facts.
- **Open Asset Packaging**: emits standard, zero-proprietary-codec outputs — a compact JSON **`Asset Map`** (`asset-map.json`) and a self-contained **`Asset Bundle`** (`.gloss/` directory or `.zip` with `SVG` + `CSV`/`Parquet` + `JSON`).

Task context planning, publication SVG refinement (`gloss-svg-refine`), semantic/statistical auditing (`gloss-audit`), live session bridging (`gloss-mcp`), and interactive browsing (`Workbench`) collaborate around `Asset Map` and `Asset Bundle` outside the R core.

## Architecture

See [`dev_docs/architecture.md`](dev_docs/architecture.md) for the complete design, asset schemas, public R API, surrounding ecosystem, and end-to-end workflows.

## License

MIT
