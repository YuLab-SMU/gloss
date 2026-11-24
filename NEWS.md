# gloss 0.1.0

Initial core release of **gloss** — the Source Map and Asset Preparation Core for R Figures.

## Public API Surface (8 Exports)

- `gloss()`: single-draw capture on `svglite` preserving untouched `original.svg`, instrumented addressable `scene.svg` (`<g id="L...">`), draw-time viewport probes, Engine IR, neutral structural lineage, and runtime source context.
- `gl_asset_map()`: serializes a compact `asset-map.json` global catalog (Engine IR, table column summaries, lineage, source pointers) directly from an in-memory `gloss_capture` without redrawing.
- `gl_asset_bundle()`: packages portable open-format `.gloss/` directories or `.zip` archives (`manifest.json` with SHA-256 digests, `asset-map.json`, `omitted.json`, dual SVG, `leaves.json`/`elements.json`, dense PNG rasters, UTF-8 CSV or Apache Parquet (`table_format = c("csv", "parquet")`) tables with 1-based `_row_id` + `tables/schema.json`, and `sources/`). Supports `select` table/column/source/elements filtering and `rows` slicing while preserving original `_row_id` values.
- `gl_scene()`, `gl_tables()`, `gl_sources()`: read-only in-memory inspection helpers.
- `gl_query()`: composable structural (`panel`, `leaf`), spatial (`box = c(x0, y0, x1, y1)`), and tabular (`table`, `rows`) slicing with panel-aware `PANEL` row filtering.
- `gl_register_engine()`: extensible S3/S4 class and `page_kind` registry for third-party plotting engines.

## Schema v1.0 & Built-in Plotting Engines

- **Schema v1.0 Scene & Stat Semantics**: `elements.json` records typography & style (`font_size`, `font_family`, `text_anchor`, `rotation`, `stroke_width`, `opacity`), both `elements.json` and `leaves.json` record active `<clipPath>` bounding boxes (`clip_id`, `clip_x0..clip_y1`), `guide-box*` legend containers preserve outer layout slot identity, and `ir$layers` / `tables/schema.json` annotate statistical column roles (`median`, `quartile_low`, `quartile_high`, `interval_low`, `interval_high`, `std_error`, `count`, `density`).
- **`grid`**: grobs, `gList`, `gTree`, `gtable`, grid functions, and `recordedplot` objects, including nested `groupGrob` alignment and command-aware SVG `<path>` bounding boxes.
- **`ggplot2`** (`Suggests`): single-build `ggplot_build()` -> `ggplot_gtable()` -> `grid.draw()` extraction of `raw`/`built_layer*` tables, discrete & continuous `scales` dictionaries (including multi-panel `scales = "free"` facets), `layers` recipes, `panels` domains, neutral cardinalities (`1:1`, `N:1`, `1:M`, `stat_aggregated`), custom `print.*` fallback, and compatibility across `ggrepel`, `sf` (`geometry_wkt`), `ggtree`, and `ggbreak`.
- **`patchwork`** (`Suggests`): composite multi-subplot extraction via public `patchworkGrob()` API with non-mutating stochastic `geom_jitter` seed pinning, `guides = "collect"` unified legend coordinates (`ir$guides`), subplot-namespaced panels/tables, and clean handling of `plot_spacer()` / `wrap_elements()`.
- **`ComplexHeatmap`** (`Suggests`): single `draw()` capture recording draw-time clustering permutations (`row_order` / `column_order`) in `ir$orders`, matrix & annotation tables (`anno_*`), `ColorMapping` scale dictionaries, slice panels, annotation slice lineage, and rasterized (`use_raster = TRUE`) bodies.
- **`base`**: step-by-step display-list replay on `svglite` supporting single and multi-panel (`par(mfrow)`, `layout()`, `par(new = TRUE)`) figures, log-transformed axes, dense rasterization, and extracted plotting tables.
