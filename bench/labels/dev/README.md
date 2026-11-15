# Development role labels

These are annotator A's role and kind labels for the 54 captured development
figures. The labels were made from the rendered page, the leaf and element
sheets, the frozen figure code, and version 1 of
[`bench/labels/guideline.md`](../guideline.md). No gloss classification output
or binding run table was used while making them.

The label files resolve against `bench/labels/sheets/` and cover every leaf
with at least one drawn element. A split leaf has one row per element range;
the three role splits are the base `axis`/`title` cases required by the
guideline. `time.csv` records the deterministic annotation pass and its
guideline version.

Verification:

```text
Rscript bench/R/score-labels.R check bench/labels/dev
```

Result on 2026-11-15: 54 figures, 7,108 leaves with elements, 33,243 leaf
elements, 0 unresolved labels, and 3 role-split leaves (0.04%).
