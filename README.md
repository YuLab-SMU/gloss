# gloss

<!-- badges: start -->
[![R-CMD-check](https://github.com/YuLab-SMU/gloss/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/YuLab-SMU/gloss/actions/workflows/R-CMD-check.yml)
[![Project Map](https://github.com/YuLab-SMU/gloss/actions/workflows/project-map.yml/badge.svg)](https://yulab-smu.github.io/gloss/)
<!-- badges: end -->

**Source Map and Asset Preparation Core for R Figures**

`gloss` captures what happens inside an R plotting session before it evaporates into a flat image, turning R figures into open, cross-language assets for external AI skills, interactive frontends, and analysis scripts:

- **Single-Draw Dual SVG Capture**: preserves both the untouched `assets/original.svg` and an addressable `scene/scene.svg` with deterministic `<g id="L...">` leaf groups, draw-time viewport coordinates, and optional PNG raster slices for dense layers (`dense = 10000`).
- **Engine Intermediate Representation (IR)**: snapshots `raw` and `built` tables, scale & palette dictionaries (`domain <-> hex/shape/size`), layer recipes (`geom`, `stat`, `position`, `aes`), facet panels & coordinate domains, and draw-time permutations (`ComplexHeatmap` clustering orders).
- **Neutral Structural Lineage**: records factual correspondences (`element <-> leaf <-> viewport <-> panel <-> layer/table`) and cardinalities (`1:1`, `N:1`, `1:M`, `stat_aggregated`) without blocking capture or withholding data.
- **File-First Open Packaging**: emits standard UTF-8 SVG, JSON, and CSV (`_row_id` + `tables/schema.json`) with zero proprietary binary codecs — readable out of the box by Python, JS, DuckDB, R, and coding agents.

## Installation

```r
# Install the development version from GitHub
remotes::install_github("YuLab-SMU/gloss")
```

## Quickstart

```r
library(gloss)
library(ggplot2)

p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point(size = 2.5) +
  facet_wrap(~ am) +
  scale_colour_manual(
    values = c("4" = "#0072B2", "6" = "#E69F00", "8" = "#D55E00"),
    labels = c("4 cyl", "6 cyl", "8 cyl")
  ) +
  labs(title = "Fuel Economy by Transmission")

# 1. Capture once (no redraw during subsequent map/bundle exports)
cap <- gloss(p, sources = list(code = "plot_mpg.R"))
cap

# 2. Emit compact Asset Map (asset-map.json)
map <- gl_asset_map(cap)
map$ir$scales

# 3. Query in memory by panel, leaf, spatial SVG box, or table rows
slice <- gl_query(cap, panel = "P2", rows = function(df) df$y > 25)
slice$tables$built_layer1

# 4. Export a portable open-format Asset Bundle (.gloss/ directory or .zip)
bundle_dir <- gl_asset_bundle(cap, path = file.path(tempdir(), "mpg.gloss"))
list.files(bundle_dir, recursive = TRUE)
```

## Public API Surface (8 Functions)

| Function | Role |
| :--- | :--- |
| `gloss(x, sources, width, height, dense, engine, preview, preview_dpi, page, parent, entities, upstream)` | Single-draw capture into an in-memory `gloss_capture` object (with optional preview PNG, parent recompute chain, cross-figure entity bindings, and pre-plot upstream funnel) |
| `gl_asset_map(cap, path)` | Build or write compact `asset-map.json` index (with `package_version`, `schema_version`, `entities`, `scene.role_contracts`, `scene.layout_tracks`, and Engine IR) |
| `gl_asset_bundle(cap, path, select, rows, format, table_format, overwrite)` | Package portable `.gloss/` directory or `.zip` bundle (`csv` or `parquet` tables) |
| `gl_scene(cap)` | Inspect dual SVGs, preview PNG, leaves, elements, label links, rasters, and panels |
| `gl_tables(cap, name)` | Access captured `raw`, `annotation`, and engine-`built` data frames |
| `gl_sources(cap)` | Inspect `explicit`, `runtime_observed`, and `sniffed_hint` provenance |
| `gl_query(cap, panel, leaf, box, table, rows)` | Composable structural, spatial, and tabular slicing with row convergence, entity hits, and in-group `context_summary` |
| `gl_register_engine(name, classes, capture_fn, ...)` | Register third-party plotting engines |

## Built-in Plotting Engines

| Engine | Classes Handled | Package Dependency | Extracted Highlights |
| :--- | :--- | :--- | :--- |
| `ggplot` | `ggplot`, `ggplot2::ggplot` | `Suggests: ggplot2` | Single-build `raw`/`built_layer*` tables, row bridges, `scale_id` & style tokens, item-level guides, panel `aspect_lock` & `attached_to` topology, `row_accounting` |
| `patchwork` | `patchwork` | `Suggests: patchwork`, `ggplot2` | Multi-subplot namespaced panels/tables/scales, subplot-attributed peripheral axes/strips/titles, unified collected guides, cross-subplot merged entities |
| `heatmap` | `Heatmap`, `HeatmapList` | `Suggests: ComplexHeatmap` | Draw-time `row_order`/`column_order`, matrix & annotation tables, bidirectional row/column entities, structured `ir.guides`, slice panels & `attached_to` |
| `base` | `function`, `recordedplot` | `Imports: grDevices, graphics` | Step-by-step display-list replay, unified transformed/data domains, multi-panel layouts, extended primitive tables, label anchors |
| `grid` | `grob`, `gList`, `gTree`, `gtable`, `function`, `recordedplot` | `Imports: grid` | Exact leaf wrapping, draw-time viewport probes, nested `groupGrob` support |

## Asset Bundle Layout (Immutable `.gloss/` Core & Orthogonal Ecosystem)

`gloss` keeps the compiled figure fact core strictly read-only in `<fig>.gloss/`. Downstream presentation views (`<fig>.gloss.view/`) and multi-turn human-agent work state (`<fig>.gloss.work/`) live cleanly alongside it outside the R kernel:

```text
figure.gloss/
├── manifest.json            # Package & schema version, capture_id, parent links, SHA-256 digests
├── asset-map.json           # Compact Asset Map index, entities, role_contracts, Engine IR & lineage
├── omitted.json             # Excluded tables/columns/rows/sources/pages with neutral reasons
├── assets/
│   ├── original.svg         # Untouched device output (immutable reference)
│   └── preview.png          # Pixel-aligned overview PNG rendered from frozen display list
├── scene/
│   ├── scene.svg            # Addressable SVG with stable <g id="L..."> leaf groups
│   ├── leaves.json          # Leaf grob paths, slots, z_index, clip boxes, subplot & attached_to
│   ├── texts.json           # Compact text index with text_block_id, measured_width_pt & anchors
│   ├── elements.json        # Element bboxes, style tokens, built_row_id/group_id & part_role
│   └── rasters/*.png        # Optional PNG slices for dense non-text leaves
├── tables/
│   ├── schema.json          # Column types, entity_role, stat_role, factor levels & timezones
│   ├── groups_*.json        # Group-key -> raw _row_id lookup maps for aggregated/N:1 layers
│   └── *.csv                # UTF-8 CSV (or Parquet) tables with explicit 1-based _row_id
└── sources/                 # Snapshotted code/docs/data files & session.json
```

## Architecture, Skills & Live Project Map

- Full design specifications:
  - [`dev_docs/architecture.md`](dev_docs/architecture.md) — Core R package architecture
  - [`dev_docs/kernel-upgrade-plan.md`](dev_docs/kernel-upgrade-plan.md) — Schema v1.2 kernel specification
  - [`dev_docs/ecosystem-vision-and-contracts.md`](dev_docs/ecosystem-vision-and-contracts.md) — Orthogonal `.gloss` / `.gloss.view` / `.gloss.work` ecosystem contracts
- Out-of-core downstream skills & stdlib Python verifiers (`skills/`):
  - [`skills/gloss/`](skills/gloss/SKILL.md) + `scripts/focus_bridge.py`, `scripts/workspace_state.py` — base protocol, bidirectional focus/overlay grounding & `.gloss.work/` state
  - [`skills/gloss-svg-refine/`](skills/gloss-svg-refine/SKILL.md) + `scripts/apply_visual_patch.py`, `scripts/verify_svg_fidelity.py` — declarative publication SVG refinement & contract-driven fidelity verifier
  - [`skills/gloss-audit/`](skills/gloss-audit/SKILL.md) + `scripts/audit_bundle.py` — manuscript caption & statistical claim reconciler
  - [`skills/gloss-report/`](skills/gloss-report/SKILL.md) — traceable multi-panel & study-level report synthesis
- Interactive architecture & code-alignment map (auto-updated on every commit to `main`): **[gloss Project Map (LikeC4)](https://yulab-smu.github.io/gloss/)**

## License

MIT
