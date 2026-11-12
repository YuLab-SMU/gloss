# Second batch for the label workbench (M1 plan Task 1)

Ten development figures, two per engine, drawn by seed (`select.R` → `figures.csv`, seed 20261112) from the 49 captured development figures outside the pilot that have at most 80 leaves to label: bioc-017 and gallery-048 (ggplot), patchwork-012 and patchwork-008, heatmap-008 and heatmap-036, gallery-056 and exts-007 (grid), gallery-040 and bioc-009 (base); 255 leaves. The cap was fixed before the draw; five figures of 129 to 4011 leaves are left out and need a sample of leaves, which the workbench cannot show yet. Sheets are those of `bench/labels/sheets/` (not copied here).

Why: one annotator and the pilot's five figures do not place the agreement on one side of 0.8 (`bench/predictions.md`, predictions 28–31). Predictions 48–52 and the condition under which each annotator labels were committed before anyone labelled one of the ten (`7c27f26`).

- `claude/`: annotator A's labels (guideline version 1), made from the page, the sheet and the code in one sitting of 14 minutes wall-clock for the ten (model time, not comparable with a person; no `time.csv`), after seeing the owner's pilot labels and before any person labelled one of the ten. `Rscript bench/R/score-labels.R check bench/labels/batch2/claude bench/labels/sheets`: every label resolves; 10 figures, 255 leaves, 2077 elements, 1 leaf split between two roles (base `title()`).
- People label in the team workbench, where the ten are added to the pilot's five as one set (`--reveal set`): a lab member sees no one's labels before all fifteen are labelled. The owner, who froze the pilot's five before the batch existed, sees nothing of the ten before labelling them (`check.py`: "a set that grows").

To score, copy `team/` back from the server and run, per pair of annotators,

    Rscript bench/R/score-labels.R agree <dir A> <dir B> bench/labels/sheets

with `<dir A>` holding A's fifteen files (`../pilot/claude/` and `claude/`) for the fifteen-figure reading, or one batch's for that batch.

Where A was least sure (said in `note`, as `unsure:`): circle-packing circles and treemap rectangles as `data` / `area`; the box behind a treemap label (`data` / `other` by the order of the questions, against `decoration` / `background`); a treemap's default title; `anno_block` blocks and their text as a strip; curved and self-loop edges of a network as `segment`; the dashed line ComplexHeatmap draws between the slices' dendrograms and the dendrogram of slices.
