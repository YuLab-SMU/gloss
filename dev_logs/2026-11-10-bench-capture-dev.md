# 2026-11-10 — Capture on the development set: 51 of 55, and captures that are another figure

- **Related plan:** [plan/2026-11-09-bench-v0.md](../plan/2026-11-09-bench-v0.md) (active; Tasks 1–6 done, Task 7 open; capture fidelity next)
- **Related ADRs:** none
- **Worked on by:** Yonghe Xia, Claude
- **Follows:** [2026-11-10-bench-freeze.md](2026-11-10-bench-freeze.md)

## What changed

| Commit | Files | Change |
|---|---|---|
| `257c17a` | `bench/R/runner.R`, `capture.R`, `check-runner.R` | before the run: the worker records which unowned elements are the device background; `capture.R` runs with no network, 900 s, its own classes for timeout and changed engine, the commit in the run's JSON; check Part 1e captures in `bioc` |
| `803437f` | `bench/predictions.md`, `bench/R/score-capture.R` | scoring rules for predictions 5–8 and the scorer, before the run |
| `0d3166a` | `bench/runs/2026-11-10-1131-capture-dev.*` | the scored run; `refusal()` returns NULL |
| `c237e0e` | `R/engine-ggplot.R`, `tests/testthat/test-capture.R` | a ggplot without layers is captured (built layers from the built plot) |
| `bc78662` | `R/engine-ggplot.R`, `R/engine-patchwork.R`, test, `NEWS.md` | a ggplot extension that does not build into a built ggplot is refused |
| `087476c` | `bench/R/runner.R`, `harvest.R`, `capture.R`, `check-runner.R` | capture runs draw on svglite; the scene is compared with the page the code drew |
| `e9b6670` | `bench/runs/2026-11-10-1159-capture-dev.*`, `score-capture.R` | the second run, after looking |

## Measured

- Suite: 7 files, 45 tests, 268 expectations → 7 files, 47 tests, 276 expectations; 0 failed, 0 skipped (`NOT_CRAN=true`, `devtools::test()`).
- Harness checks before the scored run: `check-runner.R` host and container OK; 8 of 8 synthetic figures captured with one unowned element, the background; capture in `bioc` (a visible `Heatmap`): 9 leaves. A mutation (viewBox not found) fails the check with "background test gave NA" on all 8. The first version crashed the worker on that path (`strsplit(character(0))[[1]]`), losing the capture record; the mutation found it, and so did a container check that read the mutated file while it was in place (run concurrently by mistake, then rerun).
- **Scored run** (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev`, `803437f`, clean tree; `bench/runs/2026-11-10-1131-capture-dev.*`): 55 figures, 51 captured, 4 errors, 0 refused, 0 timeouts, 0 rerun failures. Captured by engine: base 10/10, ggplot 31/32, grid 3/4, heatmap 3/3, patchwork 4/6. Predictions 5–8 right: 51/55 = 93%; grid 1/3 against objects 3/42; 35/51 = 69% with a count mismatch; 51/51 with only the background unowned (`bench/R/score-capture.R`; `bench/predictions.md`). Capture time per figure: median 0.26 s (base, ggplot) to 0.90 s (heatmap), maximum 9.83 s.
- Diagnosis of the 4 errors (call stacks in the container, `~/.cache/gloss-bench/work/diag-capture-errors.R`): patchwork-001 and -006 stopped in `ggplot_tables()` at `plot$layers[[i]]`: `ggplot_build()` adds a `geom_blank` layer to a ggplot without layers, and wrapped patchwork elements are such plots; reproduced on the host with `gloss(ggplot(mtcars))`. gallery-053 (a gganimate animation) stopped in `ggplot_gtable()`, `data@plot` on a `gganim_built`. gallery-056 (treemap) stopped drawing its grabbed scene.
- Fixes, each from a failing test: layerless ggplot, alone and as a wrapped patchwork element, drawn element for element as `print()` draws it (before: subscript out of bounds); a ggplot subclass whose `ggplot_build()` returns something else, alone and in `wrap_plots()` (before: the `@` error; after: refused, "not a built ggplot").
- **Grabbed scenes and devices** (`diag-grab.R`, `diag-grab-diff.R`): grabbed on `pdf(NULL)` and drawn on svglite, exts-007 (ggpattern, drawn by `plot()`) moved 711 of 713 primitives (title and axis text metrics of the pdf device) and gained 6 polygons; grabbed on svglite, 0 of 713 differ. gallery-056: 15 of 38 differ on pdf with `wrap.grobs = TRUE`, 1 of 38 on svglite; without `wrap.grobs` its grab cannot be drawn by grid at all ("no such index at level 1"). bioc-001 (a ComplexHeatmap drawn by a package function): 0 of 226 either way; with `wrap.grobs = TRUE` gloss fails (`Viewport 'main_heatmap_body_1_1' was not found`), so wrapping is not a general fix.
- Fidelity check in the self-check: ggplot, heatmap and grid synthetic figures equal what the code drew; base figures differ by one primitive, gridGraphics' `graphics-background` rect, which appears when the plot is recorded on svglite (on `pdf(NULL)`, 29 of 29 equal). A mutation (the open svglite page not repaired) fails the check.
- **Second run, after looking** (`087476c`; `bench/runs/2026-11-10-1159-capture-dev.*`): 53 captured, 1 refused (gallery-053), 1 error (gallery-056). Fidelity: heatmap 3/3, patchwork 6/6, ggplot 28/31, grid 2/3, base 1/10. Not faithful: exts-018 (ggbreak `ggcut`; 322 primitive differences), exts-022 (12,347 primitives drawn, 94 in the scene: a dense leaf rasterized), gallery-059 (gghighlight; 5), gallery-052 (ggExtra `ggExtraPlot`; 136), base: 1 primitive in 6 figures, 3 in gallery-013 and -038, 17 in gallery-008, 34 in bioc-004.
- Not run: the held-out set (as the rules say); a diagnosis of the base differences beyond the background, of gallery-052 and of gallery-059 (causes above marked "likely" are not verified); which leaves carry the count mismatches.

## Surprises

- **A capture can succeed and be another figure.** exts-018 is a ggbreak `ggcut`, whose print method draws a cut y axis; gloss dispatches it to the ggplot engine, builds it with `ggplot_build()` and captures an uncut plot, with no error and no warning. The invariant says gloss refuses what it cannot capture correctly; this is a silent degradation, and prediction 5 counts it as a success. The bench could not see it before `087476c`, which added the comparison with the drawn page. → plan scope change (capture fidelity is the next slice, before M1); design note in Task 7.
- **The recovery device matters.** A grob built while the code runs carries the text metrics of the device open at the time; the first run grabbed scenes on `pdf(NULL)` and gloss drew them on svglite. The eligibility checks never saw this because they compare engines, not drawings. → `087476c` (capture runs draw on svglite); recorded here.
- **gridGraphics adds a background leaf when the plot is recorded on svglite** (white background set), not on `pdf(NULL)`. One extra primitive per base figure, absent from the drawing the code made. → nowhere yet; part of the fidelity slice (it decides what "faithful" means for base figures).
- **A grabbed scene can be undrawable.** treemap's `grid.grab()` warns "viewport overwritten" and the result fails in grid itself. `wrap.grobs = TRUE` draws, nearly faithfully, but breaks heatmaps drawn by package functions. → nowhere yet; a recovery limit, counted as an error by the fixed rules.
- **`capture.R` labelled its errors NA.** `refusal()` returned `NA_character_` and `%||%` replaces only NULL. The raw run is kept; the scorer reads NA as error. → fixed in `0d3166a`.
- **Prediction 7 is right and uninformative.** 69% of captured figures have some leaf with a count mismatch, ggplot 81%; whether those are gridlines or data layers decides whether binding suffers, and the run does not record it. → fidelity slice (record which leaves mismatch).

## What's next

- Capture fidelity, on the development set (before M1): refuse, or follow, objects whose print or build method is not the ggplot path (ggbreak, ggExtra; gganimate is refused now); explain the base differences beyond the background; make the comparison aware of rasterized leaves; record which leaves mismatch; then rerun capture on the development set and report it as made after looking.
- Plan Task 7: design doc notes (frame used, environments, data out of git; capture fidelity in §风险与未决问题), M0 Task 9.
- Held-out set: only after the fidelity slice settles what is counted, with the rules and the scorer fixed first.
