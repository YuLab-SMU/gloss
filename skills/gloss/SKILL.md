---
name: gloss
description: Entry-point protocol for reading, querying, auditing, refining, and collaborating around gloss R figure Asset Bundles (.gloss/) in Human-Chart-Agent workflows using progressive perception (asset-map.json + texts.json + preview.png), bidirectional focus/overlay grounding, dual-track edits (Visual Patch vs R recomputation), and read-only source + external .gloss.work/ shared state.
---

# `gloss` — Base Figure Asset & Human-Agent Collaboration Protocol

Use this base skill whenever working with a captured R figure (`.gloss/` Asset Bundle, `asset-map.json`, or live R `gloss()` capture). It defines the **progressive reading order**, **bidirectional grounding contract**, and **edit-track routing** shared by `gloss-svg-refine`, `gloss-audit`, `gloss-report`, and interactive workbenches.

---

## 1. Progressive Perception Order (Token-Efficient Dual Channel)

Never dump multi-megabyte `scene/elements.json`, raw `scene/scene.svg`, or full CSV tables into context upfront. Always read in this order:

1. **`asset-map.json`** (tens of KB): Inspect `page`, `scene.coord` (`origin: "top-left"`, `y_direction: "down"`, `viewBox`), `ir.panels` (`bbox_pt`, `x_domain`, `y_domain`, `x_data_domain`, `y_data_domain`, `x_trans`, `y_trans`, `x_axis_group`/`row_axis_group`), `ir.layers` (`geom`, `stat`, `params`, `row_accounting`), `ir.scales` (discrete `map` & continuous `stops`), `ir.guides.entries` (item-level legend `swatch_elements`/`label_elements`), `lineage` (`semantic_role`, `edit_policy`, `lineage_tier`, `degradation_reason`), and `sources`.
2. **`scene/texts.json`** (`< 10 KB`): Read all figure text anchors (titles, axis labels, facet strips, legend labels, p-value annotations, gene labels) with exact `bbox_pt`, `semantic_role`, and `edit_policy` — without touching `scene/elements.json`.
3. **`assets/preview.png`** (optional VLM glance): Use vision strictly for holistic layout balance, whitespace, and visual crowding aesthetics; always use `asset-map.json`, `texts.json`, and `tables/*.csv` for exact numbers, coordinates, and statistical claims (zero VLM numeric hallucination).
4. **Targeted Deep Reads**: Slice only needed rows/columns from `tables/*.csv` (or `.parquet`), `tables/groups_*.json`, or `scene/elements.json` via scripts.

---

## 2. Bidirectional Grounding (`focus.json` & `overlay.json`)

Humans and agents share the same symbolic addressing primitives (`panel_id`, `leaf_id`, `element_ids`, `table_id`, `row_ids`, `bbox_pt`):

- **Human -> Agent (`box-to-rows`)**: Convert a user's pixel brush/selection `bbox_pt` into exact `built` and `raw` `_row_id`s (works for both vector marks via `built_row_id` and `>10^4` rasterized dense layers via inverse panel coordinate projection):
  ```bash
  python3 skills/gloss/scripts/focus_bridge.py box-to-rows \
    --bundle path/to/figure.gloss \
    --box 180,40,260,110 \
    --out path/to/figure.gloss.work/focus.json
  ```
- **Agent -> Human (`rows-to-overlay`)**: Project data-table findings (`raw` or `built` `_row_id`s) back onto the figure as a `gloss-focus` record and a visual highlight `overlay.svg` (dimming non-target marks, ringing target points, and attaching an attribution note):
  ```bash
  python3 skills/gloss/scripts/focus_bridge.py rows-to-overlay \
    --bundle path/to/figure.gloss \
    --table raw \
    --rows 12,45,78 \
    --note "Batch B low-depth samples" \
    --focus-out path/to/figure.gloss.work/focus.json \
    --svg-out path/to/figure.gloss.work/derived/highlight-overlay.svg
  ```

---

## 3. Dual-Track Edit Routing

Always classify every requested change into one of two tracks before acting:

| Track | When to Use | Action |
| :--- | :--- | :--- |
| **Track A — Presentation Patch** | Overlapping label avoidance, typography/font hierarchy, palette remapping, legend placement, highlight callouts | Use `gloss-svg-refine` with declarative JSON patches (`skills/gloss-svg-refine/scripts/apply_visual_patch.py`), never hand-edit raw XML. Output goes to `derived/` with `parent_manifest_sha256` + fidelity verification. |
| **Track B — Data / Model Recomputation** | Dropping outlier subjects, changing axis scale (`log10`), changing regression/error-bar statistic, reclustering heatmaps | Inspect `sources/code/` and `sources/session.json` (`call_expr`), update the R script, and re-run `gloss(p, parent = old_bundle_dir)` so the new `.gloss/` bundle chains `parent_capture_id` cleanly. |

---

## 4. Read-Only Source Bundle + Companion `.gloss.work/` State

Never modify files inside `<figure>.gloss/`. Persist multi-turn human-agent collaboration state in the sibling `<figure>.gloss.work/` directory using `skills/gloss/scripts/workspace_state.py`:

```text
figure.gloss/                 # Immutable compiler snapshot (verified by manifest.json)
figure.gloss.work/            # Mutable human-agent collaboration companion
├── workspace.json            # Links source_capture_id & source_manifest_sha256
├── focus.json                # Current shared selection / highlight focus
├── threads.json              # Audit findings, human questions, accept/dismiss/recompute decisions
├── patches/                  # Declarative gloss-visual-patch JSON specs
└── derived/                  # Refined SVGs, overlays, and derived-manifest.json receipts
```
