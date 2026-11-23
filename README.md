# gloss

**Source Map and Asset Preparation Core for R Figures**

`gloss` (v2) is a lightweight R kernel that captures what happens inside an R plotting session before it evaporates into a flat image:

- **Device Capture & Instrumentation**: preserves both the untouched `original.svg` and an addressable `scene.svg` with deterministic `<g>` leaf groups and draw-time viewport coordinates.
- **Engine Intermediate Representation (IR)**: snapshots `raw` and `built` tables, scale & palette dictionaries (`domain <-> hex/shape/size`), layer specifications (`geom`, `stat`, `position`, `aes`), facet layouts, and draw-time permutations (e.g., `ComplexHeatmap` clustering orders).
- **Structural Lineage**: records neutral correspondences (`element <-> leaf <-> viewport <-> panel <-> layer/table`) and cardinalities (`1:1`, `N:1`, `1:M`) without rigid pixel-verification gates or table withholding.
- **Open Asset Packaging**: emits standard, zero-proprietary-codec outputs — a compact JSON **`Asset Map`** (`asset-map.json`) and a self-contained **`Asset Bundle`** (`SVG` + `CSV`/`Parquet` + `JSON`).

Task planning, SVG layout refinement, interactive browsing (Workbench), and higher-level semantic or statistical verification live outside the R core as consumers of `Asset Map` and `Asset Bundle`.

## Architecture

See [`dev_docs/architecture-v2.md`](dev_docs/architecture-v2.md) for the complete v2 design, data formats, public R API, File-First / live-MCP boundary, and roadmap.

> The v1 full-stack prototype (monolithic `gloss_figure`, append-only records, embedded Workbench, and pixel back-substitution binder) is archived on the [`v1-archive`](https://github.com/YuLab-SMU/gloss/tree/v1-archive) branch.

## License

MIT
