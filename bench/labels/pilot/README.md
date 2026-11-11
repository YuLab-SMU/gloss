# Labelling pilot (M1 plan Task 1)

Five development figures, one per engine, drawn by seed (`select.R` → `figures.csv`): gallery-070 (ggplot), patchwork-006, heatmap-026, gallery-052 (grid), gallery-021 (base). Two annotators label them independently with guideline version 1 (`../guideline.md`); agreement is computed by

    Rscript bench/R/score-labels.R agree bench/labels/pilot/claude bench/labels/pilot/owner

and predictions 28–31 in `bench/predictions.md` were committed before either annotator started.

**The quick way: the label workbench.**

    python3 bench/labels/workbench/serve.py

opens http://127.0.0.1:8765/ with the five figures, smallest first. One leaf at a time is outlined on the page; answer with the number keys (role, then kind), `Space` repeats the last label, `S` labels a leaf's elements one by one, `U` marks a label unsure, `←` goes back. Each finished figure is written to `owner/<id>.csv`, the active time to `owner/time.csv`; closing the page loses nothing. For another annotator: `--out bench/labels/pilot/<annotator>`. The workbench reads the sheets, the code and the vocabulary only, never another annotator's labels.

**By hand**, for each figure:

1. Look at `sheets/<id>-page.png` (the page), `sheets/<id>.png` or `sheets/<id>.svg` (each leaf boxed and numbered by `k`) and the code, `bench/figures/<id>/code.R`.
2. Copy `sheets/<id>.csv` to `<annotator>/<id>.csv` and fill `role`, `kind` and, where needed, `note` for every row with `n_elements` above 0. Leave the other columns as they are.
3. A leaf whose elements need different labels: copy its row, one copy per group of elements, and set `elements` on each (`1`, `2-5`), with indices from `sheets/<id>-elements.csv`.
4. Add a row to `<annotator>/time.csv` (`figure,minutes,guideline,note`).

Then `Rscript bench/R/score-labels.R check bench/labels/pilot/<annotator> bench/labels/pilot/sheets` checks that every label resolves and every leaf is covered.

Do not open the other annotator's directory before both have committed their labels.

**How the two annotators worked** (recorded because it can bear on the agreement): annotator A (Claude) labelled from the sheets and the English guideline, whole figures at a time. Annotator B (the owner) uses the workbench: one leaf at a time, the other leaves dimmed, the guideline's questions and the kinds' definitions shown in Chinese.
