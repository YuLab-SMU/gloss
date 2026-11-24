---
name: gloss-svg-refine
description: Derive publication-grade SVGs from a gloss Asset Bundle (.gloss/) via controlled typography, layout, label-avoidance, and palette refinement while preserving exact data geometry and recording cryptographic parent_manifest_sha256 lineage.
---

# `gloss-svg-refine` — Publication SVG Derivation Workflow

Use this skill when refining an R figure exported as a `.gloss/` Asset Bundle (font normalization, overlapping text avoidance, legend layout adjustment, journal colorblind-safe palette remapping, or callout annotations) without redrawing in R and without distorting underlying data geometry.

## Core Invariants

1. **Never Mutate the Source Bundle**: `assets/original.svg`, `scene/scene.svg`, `manifest.json`, and `tables/*` inside `<figure>.gloss/` are immutable compiler artifacts. Write all refined outputs into a separate `derived/` directory (e.g. `<figure>.gloss/../derived/` or `<out_dir>/`).
2. **Data Geometry Lock**: Every `<g data-gloss-leaf="L...">` linked in `asset-map.json -> lineage` (`layer_id != null`) whose `ir.layers` `geom` is a data mark (`GeomPoint`, `GeomLine`, `GeomPath`, `GeomBar`, `GeomCol`, `GeomRect`, `GeomTile`, `GeomBoxplot`, `GeomViolin`, `GeomRibbon`, `GeomSmooth`, `GeomErrorbar`, `GeomPolygon`, `GeomSf`, `HeatmapBody`, `HeatmapAnnotation`, `Base*`, etc.) has **locked coordinates and dimensions**. Never translate, scale, add, or delete primitives inside data mark leaves.
3. **Synchronized Scale Remapping**: When replacing colors or stroke widths, consult `asset-map.json -> ir.scales` and `scene/leaves.json` (`layout_slot` matching `guide-box*`) so every color change updates **both** data mark leaves and matching legend keys identically.
4. **Cryptographic Lineage (`parent_manifest_sha256`)**: Every derived SVG must be accompanied by a `derived-manifest.json` recording the SHA-256 digest of the source bundle's `manifest.json` and `scene/scene.svg`.

---

## Step-by-Step Procedure

### Step 1 — Inspect the Bundle Index & Scene Schema

Read these compact files first (do **not** load full `scene.svg` or multi-MB `elements.json` into context before checking the map):

1. `<bundle>/asset-map.json` — inspect `scene.coord`, `ir.panels`, `ir.layers`, `ir.scales` (discrete `map` & continuous `stops`), `ir.guides.entries` (item-level `swatch_elements`/`label_elements`), `scene.label_links`, and `lineage` (`semantic_role`, `edit_policy`, `lineage_tier`).
2. `<bundle>/scene/texts.json` (`< 10 KB`) — inspect all text strings, `bbox_pt`, `font_size`, `font_family`, `rotation`, `semantic_role`, and `edit_policy` to detect overlaps and type hierarchy issues directly.
3. `<bundle>/assets/preview.png` (optional visual glance) — evaluate overall layout balance and whitespace visually, while relying exclusively on JSON metadata for coordinates.

### Step 2 — Respect `semantic_role` & `edit_policy` Locks

Schema v1.1 bundles explicitly label every leaf in `lineage` and `scene/leaves.json`:

| `edit_policy` | Typical `semantic_role` | Allowed Edits | Forbidden Edits |
| :--- | :--- | :--- | :--- |
| **`geometry_locked`** | `data_mark`, `reference_mark`, `axis_tick` | `fill`, `stroke`, `stroke-width`, `opacity` (synced with `ir.scales` & `ir.guides`) | Moving coordinates/dimensions, adding/removing primitives, altering tick text |
| **`movable`** | `data_label`, `leader_line`, `annotation`, `plot_title`, `axis_title`, `guide_label`, `strip_label` | Translating overlapping labels (with automatic leader-line update via `label_links`), font styling, moving legend box | Altering text characters so labels contradict `tables/` or `ir.scales` |
| **`style_only`** | `panel_grid`, `panel_frame`, `axis_line`, `guide_key`, `guide_frame`, `background` | Stroke width, color, opacity, palette synchronization | Geometry distortion of panel frames |

### Step 3 — Emit a Declarative Visual Patch & Compile Deterministically

Prefer emitting a concise JSON **Visual Patch Spec** (`gloss-visual-patch`) and running the bundled deterministic applier instead of asking an LLM to rewrite raw SVG XML:

```json
{
  "format": "gloss-visual-patch",
  "schema_version": "1.1.0",
  "operations": [
    { "kind": "set_typography", "font_family": "Helvetica", "roles": ["plot_title", "axis_title", "axis_tick", "guide_label"] },
    { "kind": "remap_scale_palette", "aesthetic": "colour", "mapping": { "Cohort A": "#0072B2", "Cohort B": "#D55E00" } },
    { "kind": "translate_label", "element_id": "E0042", "dx": 8.0, "dy": -6.0 },
    { "kind": "add_callout", "panel_id": "P1", "raw_row_id": 12, "text": "Outlier S12", "offset_pt": [20, -18] }
  ]
}
```

```bash
python3 skills/gloss-svg-refine/scripts/apply_visual_patch.py \
  --bundle path/to/figure.gloss \
  --patch path/to/figure.gloss.work/patches/pub-v1.json \
  --out path/to/figure.gloss.work/derived/figure-pub.svg \
  --manifest path/to/figure.gloss.work/derived/derived-manifest.json
```

`apply_visual_patch.py` enforces `edit_policy` locks, checks `clip_bbox_pt` overflow, auto-drags paired `ggrepel` leader endpoints via `scene.label_links`, syncs item-level `ir.guides` swatches, writes `derived-manifest.json`, and invokes `verify_svg_fidelity.py` automatically. For custom script derivations, invoke `verify_svg_fidelity.py` directly:

```bash
python3 skills/gloss-svg-refine/scripts/verify_svg_fidelity.py \
  --bundle path/to/figure.gloss \
  --derived path/to/derived/figure-pub.svg \
  --write-manifest path/to/derived/derived-manifest.json \
  --operations '[{"kind":"typography","font_family":"Helvetica"},{"kind":"palette_remap"}]' \
  --tol-pt 0.05
```

If data text labels (`GeomText` / `GeomLabel` / `GeomTextRepel`) were intentionally nudged to resolve collisions, pass `--allow-label-move` (the verifier still enforces exact text content preservation and locked non-text data marks).

---

## Derived Manifest Schema (`gloss-derived-svg`)

```json
{
  "format": "gloss-derived-svg",
  "schema_version": "1.0.0",
  "capture_id": "sha256:...",
  "parent_manifest_sha256": "<64-hex sha256 of bundle/manifest.json>",
  "parent_scene_sha256": "<64-hex sha256 of bundle/scene/scene.svg>",
  "derived_svg": {
    "path": "figure-pub.svg",
    "bytes": 18420,
    "sha256": "<64-hex sha256 of figure-pub.svg>"
  },
  "operations": [
    { "kind": "typography", "font_family": "Helvetica" }
  ],
  "created_at": "2026-11-24T00:00:00Z"
}
```
