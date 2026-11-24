---
name: gloss-report
description: Synthesize traceable, multi-panel or project-wide analytical reports from one or more gloss Asset Bundles (.gloss/) with mandatory row-level, panel-level, leaf-level, and source-code citations.
---

# `gloss-report` — Traceable Figure Synthesis & Reporting Workflow

Use this skill when generating structured scientific or engineering reports interpreting complex multi-panel compositions (`patchwork`, faceted `ggplot2`, `ComplexHeatmap` clustered slices) or a suite of `.gloss/` figure bundles across a study.

## Mandatory Citation Contract

Every quantitative or structural statement in a `gloss-report` document **must** carry an inline provenance anchor back to the bundle's open files:

- **Observation / Outlier Anchor**: `[<bundle>/tables/<table_id>#_row_id=<ids>, panel=<panel_id>, leaf=<leaf_id>]`
- **Statistical Layer Summary Anchor**: `[<bundle>/tables/<built_table>#stat_role=<role>, layer=<layer_id>, panel=<panel_id>]`
- **Heatmap Cluster / Annotation Anchor**: `[<bundle>/asset-map.json#ir.orders.<heatmap>.<row|column>_order[slice=<s>], anno=<anno_table>]`
- **Method / Code Provenance Anchor**: `[<bundle>/sources/<code_or_doc_path>, sha256=<prefix8>]`

Never invent numbers from visual estimation when `tables/` is included; if a table or subset was excluded during packaging, explicitly disclose the exclusion from `<bundle>/omitted.json`.

---

## Workflow

1. **Index Sweep (`asset-map.json` + `omitted.json`)**:
   - Inventory all bundles, engines (`ggplot`, `patchwork`, `heatmap`, `base`, `grid`), subplot/facet `panels`, `scales` dictionaries (so color/shape descriptions match exact domain labels), and `omitted.json` disclosures.
2. **Deterministic Statistical Extraction**:
   - Run `python3 skills/gloss-audit/scripts/audit_bundle.py --bundle <bundle>` on each `.gloss/` directory to gather exact sample sizes, subgroup distributions, medians/IQRs, confidence bounds, and manifest integrity checks.
3. **Targeted Row & Source Drill-Down**:
   - Query extreme `_row_id`s, cluster slice orderings (`ir.orders`), and `sources/code/*` or `sources/docs/*` to explain *how* statistical transformations, normalizations, or cutoffs were computed.
4. **Structured Report Assembly**:

```markdown
# Figure Analysis Report: <Title>

## 1. Executive Summary
- High-level takeaways with exact sample sizes and effect magnitudes.

## 2. Panel-by-Panel Evidence Breakdown
### Panel `<panel_id>` (`<subplot / facet / slice context>`)
- **Encoding & Scales**: Mapped fields, transformations (`log-10`, `CoordSf`, etc.), and palette dictionary.
- **Quantitative Findings**: Group summaries, confidence intervals, and extreme observations with `[tables/...#_row_id=..., leaf=...]` anchors.

## 3. Cross-Panel Synthesis & Anomalies
- Concordance across subplots (`patchwork`), heatmap slices (`ir.orders`), and annotations (`anno_*`).
- Outliers, boundary clipping (`clip_x0..y1`), or missing-value (`n_na`) disclosures.

## 4. Provenance & Reproducibility Appendix
- `capture_id`, `manifest.json` integrity status, R version & package versions (`sources/session.json`), Git commit/dirty status, and `omitted.json` summary.
```
