# 2026-11-15 — M1 development role labels

## Scope

Task 1 of the active M1 plan: complete annotator A's role and kind labels for
the 54 captured development figures before any development-set rules run.

## Result

- `bench/labels/dev/` now contains one label file for each of the 54 captured
  figures and `time.csv` with guideline version 1.
- The labels cover 7108 leaves with drawn elements and 33243 leaf elements.
- Three base leaves are split by element range (`axis` and `title` cases); the
  role-split share is 3 / 7108 = 0.04%, below the plan's 5% threshold.
- The five-figure pilot remains the agreement check: role κ 0.822 on 121 leaf
  units, role-and-kind κ 0.664, and no split leaves for either annotator.

## Verification

`Rscript bench/R/score-labels.R check bench/labels/dev` passed: all 54 label
files resolve to the current sheets, every drawn leaf element is covered once,
and every role/kind is in the vocabulary.

The labels were made from the rendered page, leaf and element sheets, frozen
figure code and guideline v1. No gloss classification output or binding run
table was used before this label set was written.

## Next

Commit the labels as the Task 1 baseline. Before running any rules on the
development set, commit the Task 3 residue predictions; then register the
engine rules and measure coverage.
