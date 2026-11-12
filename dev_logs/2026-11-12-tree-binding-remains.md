# 2026-11-12 — What remained on the tree stratum: base points, rows as drawn, images, leaves made when drawn, copies

- **Related plan:** [plan/2026-11-11-tree-binding.md](../plan/2026-11-11-tree-binding.md) (Tasks 1-6 done; 7-8 open).
- **Related ADRs:** none new.
- **Worked on by:** Claude (Opus 5.5), on the owner's word: "好的，把还没做的两项做完" (finish the two items left: base points by symbol, and Task 6's classes).

Two things were left after Task 5: the base route still counted one element per point, and Task 6's classes on the stratum. Those classes were tree-003's text leaf, tree-041's nudged dotted lines and images, tree-054's repelled labels, and tree-072's halo copies. Both are done. Reading the baselines and the geoms' code before writing predictions found four defects in what I had committed. All four were fixed with tests before any run: one rule was overturned by a measurement, one would have stopped figures with a list aesthetic, one would have relabelled count mismatches, and one rule was replaced.

## What changed

| Commit | What |
|---|---|
| `e9d254d` | Plan Task 6 written out: a class table, files, checklist; base points as a Scope change |
| `c8081de` | Base points counted and paired symbol by symbol (`base_point_parts()`; the base engine states `shape`); `research/point-symbols/base.R` |
| `2325e3f` | The ggplot engine's rows as the geom draws them (`ggplot_rows_drawn()`): rows dropped as `Geom$handle_na()` drops them; a `draw_panel()` that takes `nudge_x`, `nudge_y` has the layer's value added |
| `62f9536` | Images compared by their box: one per row as a rect is, one raster per group by its cells' bounds (`check_image_groups()`) |
| `6d66aca` | Leaves made when the layer's grob is drawn (not among its children in the built gtable) are unbound with that reason when the layer's rows do not pass; a failed leaf that is a passing sibling moved by one offset is unbound as a copy (`mark_copies()`) |
| `ec8856d` | A count mismatch made when drawn keeps its own reason |
| `c0c097d` | Rows missing a list aesthetic dropped as `remove_missing()` drops them |
| `897bedc` | An image justified by its layer's `hjust` placed by it (grid's meaning; overturned by the next) |
| `752bb73` | ...checked inside its box along the justified axis instead, after measuring ggimage (`research/image-justification`) |
| `dda5bf7`, `fd0401b` | Predictions 87-92, and one exception added to 92 before the runs; `bench/R/compare-capture.R` |
| this commit | Predictions scored; plan Task 6; design notes; NEWS; run logs and scores; this log |

## Measured

All bench runs in the container with no network, at `fd0401b` from start to end (the predictions commit), no tracked file modified, one copy of gloss's source for the four runs (digest `b5307a62`).

- Suite, host, `NOT_CRAN=true Rscript -e "devtools::test()"`: 9 files / 102 tests / 733 expectations / 0 failed / 0 skipped at the start (`d13ecfd`) → 9 / 104 / 743 at `c8081de` → 9 / 106 / 748 at `2325e3f` → 9 / 107 / 756 at `62f9536` → 9 / 109 / 774 at `6d66aca` → 785 at `ec8856d` → 787 at `c0c097d` → 797 at `897bedc` → 9 / 109 / 807 / 0 / 0 at `752bb73`. Container (`bench/R/suite.R`) at each: the same counts, 0 errors, 0 warnings. No `R/` or test change after `752bb73`.
- Every new test failed first; the numbers are in the plan's Task 6 checklist.
- Base points (`research/point-symbols/base.R`, host): the same parts as grid. A symbol's lines are drawn whatever `lty` or `lwd` says, and a point whose `cex` is not positive draws nothing. Six base pages were counted as drawn: 43, 11, 8, 4, 3 and 11 elements. The old count expected 26, 6, 4, 5, 1 and 7.
- ggimage's justification (`research/image-justification`, container, 72 cases): above, under Surprises.
- Capture, stratum (`1105`) against `0924`, and v0 (`1110`) against `0930` (`compare-capture.R`, 38 columns): 0 cells differ on either.
- Binding, stratum (`1107`) against `0927`:
  - 139 of 595 leaves changed, 0 regressions;
  - verified 14195 → 14212, ambiguous 8896 → 8907 (checked 92.3% of 25037), failed 67 → 0, unbound 87 → 126, count mismatch 1792;
  - per figure, of 28 ggplot figures: all checked 23 (was 22), at least 80% 25, none 0.
  - By class: the plan's Task 6 Result.
- Binding, v0 (`1116`) against `0936`:
  - 23 of 7114 leaves changed, 0 regressions;
  - verified 11959 → 11961, failed 8 → 6, unbound 1667;
  - the 27 base points leaves are in mode `symbol` with their counts unchanged.
- Predictions 87-92: 5 of 6 (91 wrong in one number, an arithmetic slip; 89's and 91's totals were quoted by leaf status, which the runs gave exactly).
- `quarto render dev_docs/design.qmd --to html`: exit 0.
- Not run: the stratum's held-out half (Task 7); v0's held-out set.

## Surprises

- **ggimage does not justify an image the way grid does.** `geom_tiplab(geom = "image")` passes `hjust = 0`, and `imageGrob()` moves the image right by its own estimate of half its width. That estimate is `size * adj`, with `adj = size / diff(x.range)`, so the move is 0.07-2.76 pt for images 16-83 pt wide, not the 8-42 pt grid's `hjust` would mean. My first rule (`897bedc`) placed the box by grid's meaning. It passed its own test, a geom drawing `rasterGrob(hjust = )`, and would have failed tree-041's six rightly paired tip images by about 31 pt. I found it by reading `imageGrob()` while writing the predictions, and measured it before any run (72 cases). The row is inside the box along x and at its centre across (0.01 pt) in every case; that is the rule now (`752bb73`). The lesson for fixtures: a fixture built from grid's documented behaviour shows the mechanism, not what a package does with the same parameter. → `research/image-justification`; design §绑定假设; plan Task 6 `<image>` item.
- **The made-when-drawn rule would have relabelled count mismatches.** As first committed, it replaced every leaf that did not pass, and tree-054's 41 texts are count mismatches (drawn as glyph outlines): they would have become unbound with "the layer's rows do not pass", though they were never paired, and lost the outline reason. Found reading run `0927`'s leaves for the predictions (`ec8856d`). → plan Task 6.
- **`complete.cases()` stops on a list column; `remove_missing()` does not.** Dropping NA rows with `complete.cases()` would have turned any figure with a list aesthetic among a geom's required or non-missing aesthetics into a bind error. Found reading `ggplot2:::detect_missing()` for the predictions (`c0c097d`). → plan Task 6.
- **Unbinding every leaf made when drawn loses `geom_curve()`.** `curveGrob()` also makes its paths when drawn, in row order, and they pass. The rule now unbinds such a leaf only when pairing it with the layer's rows does not pass. Caught by the suite before committing. → plan Task 6, "Changed from the plan".
- **ggrepel's `draw_panel()` takes `nudge_x`, `nudge_y` too,** so the draw-time nudge rule adds them to a repel layer's rows. Its leaves are made when drawn and unbound either way, so nothing measured depends on it. → nowhere else.
- **A copy's reason can name another copy.** shadowtext draws 16 copies on a circle around each label; the nearest passing sibling of a failed copy can be a neighbouring copy (one moved only along the baseline passes the text rule). The reason is still true, since that leaf is the sibling moved by that offset, but it does not say which leaf is the label. Not changed: nothing on the page tells the label from a copy moved along its baseline. → design §绑定假设.
- **I wrote two predictions' totals in the wrong unit.** I summed elements by their leaf's status, while the scorers count by element, so a verified leaf's ambiguous elements count as ambiguous. The runs matched the sums I wrote, and the checked total is the same either way. The slip in 91 (unbound "1665" for −2 + 2) was arithmetic. → `bench/predictions.md`: later predictions quote element counts.
- **exts-014's two `geom_rocci()` label leaves still fail by 4.07 pt,** rightly paired or not. Why was not read (plotROC may place a cutoff's label off its point by an offset of its own; not checked). They are v0's only failed elements. → What's next.

## What's next

- Task 8 (records) is mostly written by this session; what is left are the plan's closing notes.
- Task 7, decision (a): freeze the binder at a commit, commit predictions for the stratum's held-out half (28 figures), run it once. Its classes may include ones the development half does not have; the predictions should say how many elements are expected unchecked, and why.
- Not in this plan: exts-014's `geom_rocci()` labels (6 elements failed, 4.07 pt); the text drawn as glyph outlines (1792 elements, count mismatches, left as Task 4 decided); aplot compositions, which have no engine.
