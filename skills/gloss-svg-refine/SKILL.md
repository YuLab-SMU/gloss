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

Read these files first (do **not** load full `scene.svg` into context before checking the map):

1. `<bundle>/asset-map.json` — inspect `page` (`width_pt`, `height_pt`), `ir.panels` (`bbox_pt`, `x_domain`, `y_domain`), `ir.layers` (`geom`, `aes`), `ir.scales` (`map` domain-to-hex dictionary), `ir.guides` (unified legend `bbox_pt` & `leaf_ids`), and `lineage`.
2. `<bundle>/scene/leaves.json` — inspect each leaf's `layout_slot` (`panel`, `guide-box*`, `axis-b`, `axis-l`, `strip-t`, `title`, `subtitle`, `caption`) and active clip box (`clip_id`, `clip_x0..clip_y1`).
3. `<bundle>/scene/elements.json` — inspect text bounding boxes (`bbox_x0..bbox_y1`), `font_size`, `font_family`, `text_anchor`, `rotation`, `stroke_width`, and `opacity` to detect text collisions or inconsistent type hierarchy mathematically.

### Step 2 — Classify Leaves Before Editing

Partition `<g data-gloss-leaf="L...">` groups in `scene/scene.svg` into three buckets:

| Bucket | Identification Rule | Allowed Edits | Forbidden Edits |
| :--- | :--- | :--- | :--- |
| **Locked Data Marks** | `lineage.layer_id != null` and `geom` not in `GeomText*` / `GeomLabel*` | `fill`, `stroke`, `stroke-width`, `opacity` (synced with `ir.scales` & legend) | Moving `cx`/`cy`/`x`/`y`/`d`/`points`, `r`/`width`/`height`, group `transform`, or primitive count |
| **Data & Axis Text** | `geom` in `GeomText`, `GeomLabel`, `GeomTextRepel`, `GeomLabelRepel`, or `layout_slot` starting with `axis` | `font-family`, `font-size`, `fill`; nudging `x`/`y` of overlapping data labels (`--allow-label-move`) + updating leader lines | Changing or deleting text characters / numeric tick labels |
| **Layout Chrome & Guides** | `layout_slot` in `guide-box*`, `title`, `subtitle`, `caption`, `strip*`, `background` | Repositioning `guide-box*` group, restyling backgrounds/gridlines, normalizing title hierarchy | Altering legend category text so it contradicts `ir.scales` |

### Step 3 — Generate Derived SVG & Manifest

Write a reproducible Python/XSLT/DOM script starting from `<bundle>/scene/scene.svg`, save the refined SVG to `<out_dir>/<name>-pub.svg`, and emit `<out_dir>/derived-manifest.json` + run geometric verification via the bundled stdlib script:

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
