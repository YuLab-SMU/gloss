# Labelling pilot (M1 plan Task 1)

Five development figures, one per engine, drawn by seed (`select.R` → `figures.csv`): gallery-070 (ggplot), patchwork-006, heatmap-026, gallery-052 (grid), gallery-021 (base). Two annotators label them independently with guideline version 1 (`../guideline.md`); agreement is computed by

    Rscript bench/R/score-labels.R agree bench/labels/pilot/claude bench/labels/pilot/owner

and predictions 28–31 in `bench/predictions.md` were committed before either annotator started.

**The quick way: the label workbench.**

    python3 bench/labels/workbench/serve.py

opens http://127.0.0.1:8765/ with the five figures, smallest first. One leaf at a time is outlined on the page; answer with the number keys (role, then kind), `Space` repeats the last label, `S` labels a leaf's elements one by one, `U` marks a label unsure, `←` goes back. Each finished figure is written to `owner/<id>.csv`, the active time to `owner/time.csv`; closing the page loses nothing. For another annotator: `--out bench/labels/pilot/<annotator>`. The workbench reads the sheets, the code and the vocabulary only, never another annotator's labels.

**Several annotators: the team workbench** (2026-11-11, plan Scope changes). The same five figures, labelled by the owner and invited lab members on the lab's server:

    python3 bench/labels/workbench/serve.py --team bench/labels/pilot/team --reveal set --host 0.0.0.0 --invite <code>

Each annotator joins with the invite code and a nickname no one has, and labels into `team/<nickname>/` (the same files as above). No one sees another's labels before their own five figures are labelled and they open the others': that freezes their labels (`<id>.csv` from then on), and what they change afterwards goes to `team/<nickname>/revised/`. Who has labelled how much is visible at any time. Annotator A's labels sit in the team as the read-only annotator `claude`. The deployment (`~/projects/gloss-labels` on the lab's head node, `run.sh` to start and stop, port 8765) holds the workbench, the five sheets and their code, the guideline's examples and the vocabulary: no held-out figure, no rule output. To score, copy `team/` back and run `score-labels.R agree` on two directories at a time; the page's statistics use the same formula (checked in `workbench/check.py`) and are not the score.

The workbench shows more than the sheets (version 3): the leaf's fill and stroke, the leaf painted, alone on a checkerboard, hidden, dragged aside, its place in the drawing order, and the guideline's worked examples beside each role and kind. Each figure's state records the version it was labelled with.

**By hand**, for each figure:

1. Look at `sheets/<id>-page.png` (the page), `sheets/<id>.png` or `sheets/<id>.svg` (each leaf boxed and numbered by `k`) and the code, `bench/figures/<id>/code.R`.
2. Copy `sheets/<id>.csv` to `<annotator>/<id>.csv` and fill `role`, `kind` and, where needed, `note` for every row with `n_elements` above 0. Leave the other columns as they are.
3. A leaf whose elements need different labels: copy its row, one copy per group of elements, and set `elements` on each (`1`, `2-5`), with indices from `sheets/<id>-elements.csv`.
4. Add a row to `<annotator>/time.csv` (`figure,minutes,guideline,note`).

Then `Rscript bench/R/score-labels.R check bench/labels/pilot/<annotator> bench/labels/pilot/sheets` checks that every label resolves and every leaf is covered.

Do not open the other annotator's directory before both have committed their labels.

**How the two annotators worked** (recorded because it can bear on the agreement): annotator A (Claude) labelled from the sheets and the English guideline, whole figures at a time. Annotator B (the owner) uses the workbench: one leaf at a time, the other leaves dimmed, the guideline's questions and the kinds' definitions shown in Chinese. The owner labelled gallery-070 and heatmap-026 (and one leaf of patchwork-006) with workbench version 1, on 2026-11-11 before 09:57; everything after that, by the owner or a lab member, is made with version 3, whose examples were labelled by annotator A.

**The owner's labels** (2026-11-11): all five figures, frozen in the team workbench and copied to `team/yonghe/` (`<id>.csv` the independent labels, `revised/` the two figures changed after seeing the others', `time.csv`; the server's own state files and accounts are not copied). `time.csv` names workbench 4 for every figure because the two version-1 figures were moved in under it; gallery-070 and heatmap-026 are byte-identical to the files made locally with version 1. Scored against annotator A in `bench/predictions.md` (predictions 28–31). `owner/` on the owner's machine holds the two local originals and is not tracked.

**From workbench version 5** (2026-11-11, after the owner's labels were scored) the examples include `ex-box`, a boxplot over a typed band: lab members label with it, the owner did not. A save names the revision of the labels the page holds; a page that was open while another saved is refused and loads the newer labels, so two tabs cannot overwrite each other.

**A second batch** (2026-11-11): ten more development figures are in the same team set (`../batch2/`), so the set is fifteen figures and a lab member labels all of them before anyone's labels open. On the server their sheets, code and annotator A's labels sit beside the pilot's (`pilot/sheets/`, `team/claude/`); in the repository A's labels of the ten are in `../batch2/claude/` and the sheets in `../sheets/`. Copy to the server with `scp` or with `COPYFILE_DISABLE=1 tar`: a tar made on macOS without it leaves `._*` files beside each sheet (the workbench now skips hidden files; before `37f0728` it did not start).
