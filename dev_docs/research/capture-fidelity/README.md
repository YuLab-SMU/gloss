# Capture fidelity spike (2026-11-10)

Evidence behind [`idea/2026-11-10-page-capture.md`](../../../idea/2026-11-10-page-capture.md) and [`dev_logs/2026-11-10-page-capture-spike.md`](../../../dev_logs/2026-11-10-page-capture-spike.md). Scripts are kept as run, each with its output (`.out`). Nothing here is package code, and nothing in `R/` uses it.

**Question.** The development set showed captures that are another figure, refusals by class, and base figures that differ from what the code draws (bench run `2026-11-10-1424`: 51 captured, 3 refused, 1 error; 40 equal, 6 known exceptions, 5 different). Each difference comes from capturing a grob that something other than the figure's own code built: `ggplot_gtable(ggplot_build(x))`, `gridGraphics::echoGrob()`, `grid.grab()`. Can gloss capture the *page* the code draws instead?

**Two routes, by what is on the device's display list** (`page-capture.R`):

- *grid page*: `grid.force()`, wrap every leaf of the display list in place with `grid.DLapply()` (probe + group, as ADR-0001), redraw with `grid.refresh()`. No engine-built grob, no `grid.grab()`.
- *base page*: replay the recorded display list one entry at a time on svglite, as `replayPlot()` does, and read the device after each entry. No gridGraphics.

Everything ran on the development set or on code written for the check. **The held-out set was not read or run.** The runs are made after looking at the development results and score no prediction.

## Scripts and what they showed

Host scripts run from the repository root with `Rscript <path>`; container scripts with `bench/docker/run.sh Rscript <path>` (`GLOSS_BENCH_OFFLINE=true` for `s3`).

| Script | Where | What it showed |
|---|---|---|
| `s0-root-causes.R` | host | ggExtra: the captured object equals its own `print()`, 83 = 83 primitives; the bench's reference page held two figures, 219. gridGraphics resolves colour 0 against its own shadow device (`par("bg")` is `transparent` on `pdf(NULL)`, `white` on svglite): `rect(border = 0)` differs in 2 of 2 primitives. `pairs()`: 16 primitives differ (which axis labels are drawn, and where). `gloss()` on a function that draws with grid stops with "EXPR must be a length 1 vector"; on a function that draws 4 base pages it keeps the last page with a warning. |
| `s1-page-grid.R` | host | In-place capture of 16 grid pages: 15 identical to the page the code drew (ggplot, patchwork, ComplexHeatmap, lattice, pheatmap, ggExtra, aplot, gridExtra, cowplot, raw grid calls with a repeated viewport name, 10^4 points). The 16th, ggrepel without a seed and with the random state not pinned, differs in 77 primitives; with the state pinned, 0. |
| `s2-page-base.R` | host | 26 base figures (scatter, `mfrow`, `layout`, `pairs`, `image`, `persp`, plotmath, log axes, `heatmap`, `coplot`, `filled.contour`, ...): entry-by-entry replay identical to the code's drawing in 26; `replayPlot()` identical in 26. gridGraphics on the same recorded plots: identical in 0 (16 differ by exactly one primitive, the background rect; 9 by 3 to 531; plotmath is an error). |
| `s3-dev-set.R` | container | The 55 development figures (runs below). |
| `s4-unknowns.R` | host | Random numbers: restoring the state from before `print()`, or from the start of the page, does not reproduce the page when the build also draws random numbers (56 primitives differ); saving it between build and draw does (0, and equal to `print()` from the same seed). The self-check, wrapped redraw against plain redraw from one saved state, holds (0), and plain redraw against the first drawing shows the figure is not deterministic (56). A page recorded on `pdf(NULL)` and replayed on svglite is self-consistent but differs from drawing on svglite (242 primitives). Masks and leaves with their own group are refused, as today. Mixed pages (base and grid on one page) are detected. Time: page capture 0.10 / 0.44 / 3.5 s at 10^3 / 10^4 / 10^5 points against 0.11 / 0.40 / 4.1 s for `gloss()` today; the comparison adds 0.02 / 0.28 / 2.5 s. |
| `s5-drop-in.R` | host | Five grid test inputs: the element tables are identical to today's (134, 186, 293, 115, 10040 rows), the leaf tables have the same rows and differ only in `name` and `vp`, and the engines' own `panels()` give identical panels from page-route leaves. Base: panel box and scales from `par("fig", "plt", "usr")` place the data within 0.005 pt of the drawn circles (4 layouts, including log axes, `mfrow`, `layout` with margins); the `C_plotXY` entry drew as many circles as rows. |
| `s6-details.R` | host | Reading the device after each entry: parsing the whole page each time is quadratic (5008 entries: 53 s); a file device kept valid while written (`always_valid = TRUE`), reading only the new bytes: 0.32 s, same counts per entry, same page. A base plot recorded on `pdf(NULL)` and replayed on svglite differs from the code on svglite in 2 of 3 cases (6 of 60 and 2 of 2 primitives). The leaf `name` and `vp` differences of `s5` are grid's automatic numbering only (equal after replacing digits, 5 of 5). |
| `s7-clip-blind-spot.R` | host | `scene_signatures()` cannot see clipping: the clip region is an attribute of an ancestor group. A `clipGrob` leaf lost its clip in both routes with every primitive unchanged (before `4f8abe4`: 1 of 2 primitives with another clip region; after: 0). The six test inputs keep their clip regions. |
| `p1-fixtures-vs-engine-route.R` | host | Package code, page-capture plan Task 1 (2026-11-11): the six capture inputs on the page route against the tag `engine-route-final`. Element tables, panels, tables and clip regions identical; leaf `name` and `path` differ in grid's automatic numbering, and the heatmap's `path` loses the root `grid.grabExpr()` added. |
| `p2-jitter-tables.R` | host | Package at `19f39d7`, Task 2: `position_jitter()` without a seed, 32 rows, 5 runs. Tables from a separate build: 0 of 32 rows on their point; from the random state `print()` starts with, or from the build the engine draws: 32 of 32. The engine's page equals `print()`'s from the same seed. |
| `p2-own-print.R` | container | Task 2: exts-018 (ggbreak) and gallery-052 (ggExtra). Before the table rule (`p2-own-print.out`): exts-018 offers `built_layer1` (20 rows, uncut scale) against 3 sub-panels of 20 bars, all counts `ok`; no panels, no reason. After (`p2-own-print-t2.out`): `raw` kept, `built_layer1` and `panels` withheld with the reason. gallery-052: grid engine, no tables. |
| `p3-time.R` | host | Task 3: points_1e4's dense leaf redrawn from the display list, raster identical to the engine route's byte for byte; 10^5-point bundle 2.65 MB on both routes; `gloss()` 1.52x, 1.62x, 1.31x the engine route's median time at 10^3, 10^4, 10^5 points, self-check 0.01, 0.05, 0.55 s. |
| `p5-base-fixtures.R` | host | Task 5: the 26 base pages of `s2`, package against the tag `engine-route-final`, each in its own process. Equal to the code's own page on svglite (with clip regions): page route 26 of 26, all with the verdict `equal`, 0 count mismatches; engine route (gridGraphics on the function) 14 of 26 (`pairs` 16 primitives, `image_contour` 530, `dendrogram` 78, `persp` 30, `rect(border = 0)` and `border = FALSE` 2, `bg_colour` 3, `smooth_scatter` clip regions only, plotmath an error). Leaf names over the 26 pages: `segments` 91, `axis` 58, `polygon` 52, `plotXY` 48, `box` 47, `text` 24, `title` 18. Data through each panel's `usr` scales onto the drawn circles: within 0.007 pt (scatter, log axes, `pairs` figure 2, `layout`). Time per page 0.00 to 0.54 s (`smoothScatter`, 16,441 elements). Two earlier runs were wrong and are not kept: sourcing `s2` ran its `load_all(".")` over the tag, so both columns measured the page route; and the `pairs` check mapped disp on mpg (`pairs()` fills by column), a 1383.889 pt gap. |
| `p6-base-classify.R` | host | Task 6: the base figure of design §分类 (`plot()`, `abline()`, `legend()`) on the page route: 9 leaves (gridGraphics: 15), 60 elements, verdict `equal`. `classify.R`'s base rules matched on call names (`plotXY` for points and lines): 57 elements right, 2 wrong (`legend()`'s `rect` and `segments` as data marks), 1 unclassified (its `text`), the same as through gridGraphics. The display list holds the graphics calls `legend()` makes, not `legend()` itself, as gridGraphics' names did. |
| `d1-treemap-names.R` | container | gallery-056: treemap draws `grid.rect(name = <one name per rectangle>)`, a grob whose name is a vector (2 of 14 display-list elements). grid draws it; `grid.grab()` returns a tree it cannot index ("no such index at level 1"). |
| `d2-gghighlight-rng.R` | container | gallery-059: its label layer is `GeomLabelRepel` with `seed = NA`. Two plain `print()` calls differ in 5 primitives; with the same seed before each, 0. |

## Development-set runs (`bench/runs/*-page-capture-spike-dev.csv`)

`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript dev_docs/research/capture-fidelity/s3-dev-set.R`, 55 development figures, about 3 minutes each run. Per figure: `A0` the page the code left on svglite, `A1` (grid pages) the same display list redrawn untouched, `B` the captured page.

| Run | Change | Result |
|---|---|---|
| `2026-11-10-1653` | first full run | 54 of 55 captured, 0 errors. `B = A0` in 53. gallery-059: `A1 != A0` (5 primitives) and `B != A1`. gallery-053: empty page. |
| `2026-11-10-1722` | `A1` and `B` start from the same random state | grid pages: `B = A1` 44 of 44; `A1 = A0` 43 of 44. |
| `2026-11-10-1731` | comparison also on clip regions | grid: `B = A1` 44 of 44 with clip regions; base: `B = A0` 10 of 10 with clip regions. No development figure has a `clipGrob` leaf. Output in `s3-dev-set.out`. |

Final run, by page kind: 44 grid pages, 10 base pages, 1 empty (gallery-053, an animation: nothing on the device), 0 mixed. Of the 42 figures the bench recovers as an object, the object printed alone on a fresh page equals the page the code left in 39; it differs for gallery-052 (the page holds two figures) and gallery-059 (random), and gallery-053 cannot be drawn. The code of 23 of the 55 figures drew more than one page; the last is kept, as in the bench. 31 of the 44 grid pages have a leaf with a count mismatch, as before. Time per figure: median 0.09 s, maximum 37.9 s (gallery-023, 1301 entries, with the quadratic reader of `page-capture.R`).

Two pilot outputs (5 and 3 development figures, `2026-11-10-1652` and the first `-1653` pilot file) were deleted before the full runs; the full runs contain those figures.

## Not tested

- Nothing is implemented in `R/`. The spike calls gloss internals (`wrap_leaves()`, `build_substrate()`).
- Dense leaves as rasters on the page route (only a forced display list redrawn on a second svglite device: identical).
- Tables on the page route end to end; the engines' `tables()` do not depend on the drawing and were not rerun.
- Base figures: leaves, expected counts and classification by display-list entry. Only the page, the per-entry attribution and the panel coordinates were checked.
- Pages that mix base and grid (0 of 55 development figures).
- The held-out set.
