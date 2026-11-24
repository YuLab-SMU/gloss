---
name: gloss-audit
description: Reconcile manuscript text, figure captions, and quantitative claims against the exact raw/built tables, statistical column semantics, scale transformations, and omission logs inside a gloss Asset Bundle (.gloss/).
---

# `gloss-audit` — Manuscript & Figure Statistical Reconciliation Workflow

Use this skill when auditing whether quantitative claims in a paper, preprint, slide deck, or figure caption accurately match the underlying R figure captured in a `.gloss/` Asset Bundle.

## Core Principles

1. **Bundle Integrity, Omissions & Silent Drops First**: Always verify `manifest.json` digests, inspect `omitted.json`, and check `ir.layers[].row_accounting` (`n_raw`, `n_built`, `n_dropped_na`, `n_dropped_oob`, `dropped_raw_row_ids`) before evaluating sample sizes (`N`/`n`). Also read `ir.layers[].params` (`method`, `level`, `formula`, `fun.data`, `bins`) to verify whether error bars show SD, SE, or 95% CI, and check `scene/texts.json` (`< 10 KB`) to inspect all figure-rendered p-value annotations directly.
2. **Distinguish `raw` vs `built` Tables**:
   - `tables/raw.csv` (or `p<i>_raw.csv`, `matrix_<ht>.csv`, `anno_*`) holds pre-stat input observations. Use it for cohort sample sizes (`n`), subgroup counts, raw means/medians/IQRs, and exact subject/gene identifiers (`_row_id` or `key`).
   - `tables/built_layer*.csv` holds post-stat engine coordinates and computed summaries, plus `_raw_row_id` (1:1 row bridge) or `_group_key` + `tables/groups_*.json` (aggregated group-to-raw-rows bridge). Consult `tables/schema.json` (`stat_role`) and `asset-map.json -> ir.layers[].stat_columns` to audit plotted error bars, confidence ribbons, and boxplot hinges directly.
3. **Respect Coordinate & Scale Transformations**: Check `ir.panels[].x_trans` / `y_trans`, `domain_space`, `x_data_domain`/`y_data_domain`, and `ir.scales[].trans`. In `ggplot2`, built position columns (`x`, `y`, `ymin`, `ymax`, `middle`) are stored in **transformed scale units** when a scale transformation (e.g. `log-10`) is active!
4. **Emit Durable Threads for Human-Agent Handoff**: Pass `--emit-threads <figure>.gloss.work/threads.json` to `audit_bundle.py` so failed claims and silent row-drop warnings are persisted alongside the immutable `.gloss/` bundle for human review and decision tracking.

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
