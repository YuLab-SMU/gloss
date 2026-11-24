---
name: gloss-audit
description: Reconcile manuscript text, figure captions, and quantitative claims against the exact raw/built tables, statistical column semantics, scale transformations, and omission logs inside a gloss Asset Bundle (.gloss/).
---

# `gloss-audit` — Manuscript & Figure Statistical Reconciliation Workflow

Use this skill when auditing whether quantitative claims in a paper, preprint, slide deck, or figure caption accurately match the underlying R figure captured in a `.gloss/` Asset Bundle.

## Core Principles

1. **Bundle Integrity & Omission First**: Always verify `manifest.json` digests and inspect `omitted.json` before evaluating sample sizes (`N`/`n`). If rows were filtered during `gl_asset_bundle(..., rows = ...)`, `omitted.json` records `original_nrow` vs `included_nrow` so sliced bundles are never mistaken for full cohorts.
2. **Distinguish `raw` vs `built` Tables**:
   - `tables/raw.csv` (or `p<i>_raw.csv`, `matrix_<ht>.csv`, `anno_*`) holds pre-stat input observations. Use it for cohort sample sizes (`n`), subgroup counts, raw means/medians/IQRs, and exact subject/gene identifiers (`_row_id` or `key`).
   - `tables/built_layer*.csv` holds post-stat engine coordinates and computed summaries. Consult `tables/schema.json` (`stat_role`) and `asset-map.json -> ir.layers[].stat_columns` (`median`, `quartile_low`, `quartile_high`, `interval_low`, `interval_high`, `std_error`, `count`, `density`) to audit plotted error bars, confidence ribbons, and boxplot hinges directly.
3. **Respect Coordinate & Scale Transformations**: Check `ir.panels[].x_trans` / `y_trans` and `ir.scales[].trans`. In `ggplot2`, built position columns (`x`, `y`, `ymin`, `ymax`, `middle`) are stored in **transformed scale units** when a scale transformation (e.g. `log-10`) is active! Always note scale transformations explicitly before comparing built coordinates to raw units.

---

## Step-by-Step Audit Procedure

### Step 1 — Run Deterministic Bundle Profiling

Run the zero-dependency audit script to validate bundle SHA-256 integrity, inspect omissions, and compute exact per-table / per-group summary statistics:

```bash
python3 skills/gloss-audit/scripts/audit_bundle.py --bundle path/to/figure.gloss
```

### Step 2 — Decompose Prose into Atomic Claims & Verify Programmatically

Break every quantitative sentence in the manuscript/caption into atomic claims and pass them to `--claims` (or verify with a reproducible Python/R/DuckDB script):

```json
[
  {
    "id": "C1",
    "statement": "Total cohort size n = 32 cars",
    "table": "raw",
    "op": "nrow",
    "expected": 32,
    "tol": 0
  },
  {
    "id": "C2",
    "statement": "4-cylinder group mean fuel economy is 26.7 mpg",
    "table": "raw",
    "column": "mpg",
    "where": { "cyl": "4" },
    "op": "mean",
    "expected": 26.7,
    "tol": 0.05
  }
]
```

```bash
python3 skills/gloss-audit/scripts/audit_bundle.py \
  --bundle path/to/figure.gloss \
  --claims claims.json
```

### Step 3 — Emit the Structured Audit Ledger

Classify every claim into one of four neutral verdicts with exact evidence links:

- **`VERIFIED`** — Observed value matches within stated rounding precision (`|obs - exp| <= tol`).
- **`ROUNDING_DRIFT`** — Directionally consistent, minor rounding discrepancy (`tol < |obs - exp| <= 2 * tol`).
- **`MISMATCH`** — Contradicts table values, subgroup bounds, or scale mapping (cite `table_id`, `_row_id`s, observed vs claimed value).
- **`UNVERIFIABLE_FROM_BUNDLE`** — Requires external statistical test inputs or omitted columns not present in `tables/` or `sources/` (cite `omitted.json` if applicable).
