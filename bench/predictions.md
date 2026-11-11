# Predictions

Written before the run they predict, committed with a date, scored afterwards. A wrong prediction is reported, not edited. Format per item: the prediction, the reasoning, then (after the run) the observed value and a verdict.

## Bench v0 harvest and capture (2026-11-09)

Written by Claude on 2026-11-09, before any sampled figure was run (only the runner self-check on scripts written for it had run). Owner may add predictions before the run; added ones carry their own date.

### Harvest and eligibility (plan Task 4, all 160 PSUs)

1. **About 60% of attempts are retained (90–100 of 160).** Reasoning: Gallery posts carry widgets, tables and 3-D scenes that are outside the population, plus URL and file dependencies; Bioconductor vignettes need heavy installs and often remote data. Package examples run under CRAN and Bioconductor checks, so they should mostly work.
2. **By stratum:** gallery about 65%, exts about 70%, bioc about 40%, patchwork about 85%, heatmap about 85%.
3. **The largest failure class in the gallery stratum is "outside population"** (htmlwidgets, tables, rgl); in the bioc stratum it is "needs network" or "timeout".
4. **Fewer than 100 retained** would trigger the plan's second sampling round; predicted not to be needed, with low confidence.

### Capture on the development set (plan Task 6)

5. **At least 90% of development figures capture without error.** Reasoning: capture wraps leaves of whatever grob tree the engine produces and has handled every input class tried so far; the likely failures are exotic base plots through gridGraphics (`persp`, `filled.contour`, `image` with rasters) and masks, which capture refuses.
6. **Figures recovered as grid scenes through `grid.grab()` fail capture more often than returned objects.** Reasoning: a grabbed scene rebuilds grobs from the display list and can lose viewport structure.
7. **At least 30% of captured figures have one or more leaves with a count mismatch.** Reasoning: the M0 faceted plot had 6 of 62 leaves mismatched (gridlines with NA breaks, NaN ribbons), and such gridlines appear in most ggplot themes.
8. **In at least 95% of captured figures, the only element without a leaf is the device background.**

### Changes made after these predictions, before any sampled figure ran (2026-11-09)

The predictions above are unchanged. Two things they were written against changed afterwards; both are scored with the change reported next to them.

- **Heatmap sample.** 10 of the 15 heatmap draws were ComplexHeatmap help topics whose examples are only `# There is no example` and `NULL`. They are now out of scope and replaced by the next 10 in-scope rows of the same permutation (plan Scope changes). On the original sample those 10 would have been "no code" by construction, so prediction 2's heatmap rate could not have exceeded 5/15 there.
- **Software environment.** Figure code runs in the pinned Bioconductor 3.21 container, with CRAN pinned to 2026-10-22 (the Gallery commit's date). With that snapshot, 9 of the 77 sampled Gallery posts and 4 of the 30 exts packages need a package absent from CRAN and Bioconductor 3.21 (static count, `bench/R/snapshot-coverage.R`). This was measured after prediction 1 was written.

### Changes made after looking at the first full harvest (2026-11-09)

The predictions above are unchanged. The first full harvest (harness at `4fde108`) exposed harness defects, fixed after its outcomes had been read; the harvest is then rerun from scratch with the fixed harness. Predictions 1–4 are scored on both runs: the first run is archived in `runs/` and was not chosen or tuned to match them, and the rerun is labelled as made after looking. The fixes (plan Scope changes, dev log 2026-11-09-bench-harvest): visible values are printed as knitr prints them (lattice and other print-drawn figures were invisible, and a ggplot failing only at print counted as a figure); the Gallery's closing `includeHTML()` chunk is dropped; no-break spaces become spaces; failed package downloads are retried and a package named by an error is installed and the script rerun; a URL inside `download.file()` stays a `file://` URL; shapefiles are vendored with their sidecars; output outside the population followed by an error counts as outside the population.

### Scoring

#### Predictions 1–4 on the first full harvest (scored 2026-11-09)

Run: `runs/2026-11-09-harvest-1-attempts.csv` (harness at `4fde108`, all 160 sampled PSUs; 155 in the full run, 5 from the pilot, 4 of them on the harness before `cd36aca`, whose only change is on a path they did not reach). "Retained" here means passing the harvest's own eligibility rerun with the dead proxy; the no-network pass (`offline-check.R`) was not run on this run's figures. The harness defects listed above affected these counts in both directions (print-drawn figures missed; a ggplot failing at print could count as retained).

| Stratum | Attempted | Retained | Predicted rate | Observed rate |
|---|---|---|---|---|
| gallery | 70 | 50 | ~65% | 71% |
| exts | 30 | 23 | ~70% | 77% |
| bioc | 30 | 9 | ~40% | 30% |
| patchwork | 15 | 11 | ~85% | 73% |
| heatmap | 15 | 4 | ~85% | 27% |
| all | 160 | 97 | ~60% (90–100) | 61% |

1. **Right.** 97 of 160 (61%).
2. **Partly right.** gallery and exts within about 7 points, above the prediction; bioc and patchwork 10–12 points below; heatmap wrong by 58 points: 8 of 15 were "no figure" (ComplexHeatmap help topics for utilities such as `c.ColorMapping` or `is_abs_unit`, which draw nothing; and annotation topics such as `anno_barplot` and `bar3D`, which draw grid scenes, not a Heatmap object).
3. **Wrong in both strata.** Gallery: no PSU was "outside population"; the largest classes were "missing package" (6) and "missing data" (5), and at least three of the "missing data" were widget or table posts misclassified by the harness (`includeHTML()` defect). Bioconductor: "no figure" (7) and "code error" (7), not network or timeout (3 and 0).
4. **Wrong.** 97 retained, under the 100 that triggers the plan's second sampling round. Whether the round is needed is decided on the rerun's numbers after the no-network pass.

#### Predictions 1–4 on the second full harvest (scored 2026-11-10; made after looking)

Run: `runs/attempts.csv` (harness `923713e`, written after run 1's outcomes had been read; heatmap-016 and -021 rerun on `a09d0ff`, which changed only how outcomes are labelled). Eligible = retained by the harvest and rerun in a container with no network (`runs/offline-check.csv`, 103 of 106). This is the set the split will use.

| Stratum | Attempted | Eligible | Predicted rate | Observed rate |
|---|---|---|---|---|
| gallery | 70 | 54 | ~65% | 77% |
| exts | 30 | 26 | ~70% | 87% |
| bioc | 30 | 8 | ~40% | 27% |
| patchwork | 15 | 11 | ~85% | 73% |
| heatmap | 15 | 4 | ~85% | 27% |
| all | 160 | 103 | ~60% (90–100) | 64% |

1. **Wrong by its stated range:** 103 of 160 (64%), above 90–100; the rate is close to the predicted 60%.
2. **Partly right.** gallery and exts 12–17 points above the prediction, bioc and patchwork 12–13 below, heatmap 58 below (7 of its 15 PSUs are help topics that never draw a heatmap).
3. **Wrong in both strata.** Gallery: "missing package" 6, "outside population" 3. Bioconductor: "no figure" 8; network 6 (3 found only with no network), timeout 0.
4. **Right on this run** (103 ≥ 100, no second round), wrong on run 1 (97). The difference is the harness fixes, made after looking.

#### Heatmap frame narrowed after scoring (2026-11-10)

After predictions 1–4 were scored on runs 1 and 2, the owner narrowed the heatmap frame: ComplexHeatmap help topics whose examples call no function returning a Heatmap are out of scope, and 7 drawn topics were replaced (plan Scope changes). The scores above stand. The final eligible counts, on the narrowed frame, are reported in the plan and the dev log as made after looking; they are not a test of prediction 2.

#### Era-matched Bioconductor environment and freeze (2026-11-10; made after looking)

After predictions 1–4 were scored, the owner also moved the bioc and heatmap strata to an era-matched environment (Bioconductor 3.21 with CRAN 2025-10-29; plan Scope changes), and the 45 PSUs of those strata were rerun. The frozen counts are **109 of 160 eligible** (gallery 54, exts 26, bioc 12, patchwork 11, heatmap 6), against 103 on run 2 above. They come after both changes, both made after looking, and are not a test of predictions 1–4; the scores above stand. Predictions 5–8 are untouched: no capture has run.

### How predictions 5–8 are scored (fixed 2026-11-10, before any capture run)

Written after the freeze (`e985d82`) and before `bench/R/capture.R` has run on any benchmark figure. The predictions themselves are unchanged; this fixes how their words are counted.

- **Run.** The development set, 55 figures (`split.csv`), once: `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev`, at a clean commit recorded in the run's JSON. The first complete run is the one scored. Any rerun after a fix to gloss or the harness is reported beside it as made after looking, and never replaces it.
- **Outcome of a figure.** *captured*; *refused* (mask, no engine, device without groups, integrity check: gloss stops and says why); *error* (anything else `gloss()` raises); *timeout* (900 s; every figure reran within 300 s without capture); *rerun failure* (the frozen figure no longer reruns or recovers its recorded engine: a harness or environment outcome, not capture's).
- **Prediction 5** (at least 90% capture without error): captured ÷ figures that rerun and recover their engine. Refusals count against it, as the prediction's own reasoning lists masks among the failures; timeouts count against it. Captured ÷ 55 is reported too.
- **Prediction 6** (grid scenes fail more often than returned objects): among figures that rerun, the share not captured, for figures recovered by `grid.grab()` (`recovered = grid`) against figures recovered as returned objects (`recovered = object`). Right if the first share is larger. The development set has 4 grid figures, so the verdict is reported with its counts.
- **Prediction 7** (at least 30% of captured figures have a leaf with a count mismatch): among captured figures, the share with `leaves_mismatch ≥ 1`.
- **Prediction 8** (in at least 95% of captured figures, the only element without a leaf is the device background): among captured figures, the share where every unowned element is the device background (`unowned == unowned_bg`), counting figures with no unowned element as meeting it. The device background is the first element when it is a rect covering the SVG's viewBox (`runner.R`).
- Everything is also reported per engine, from `split.csv`.

#### Predictions 5–8 on the development set (scored 2026-11-10)

Run: `runs/2026-11-10-1131-capture-dev.csv` (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev` at `803437f`, clean tree), scored by `bench/R/score-capture.R` with the rules above (`runs/2026-11-10-1131-capture-dev-score.txt`). 55 figures: 51 captured, 4 errors, 0 refused, 0 timeouts, 0 rerun failures. The run wrote the 4 errors' status as NA (a labelling bug in `capture.R`: `refusal()` returned `NA_character_`, which `%||%` does not replace); the scorer reads NA as error and says so.

| Prediction | Observed | Verdict |
|---|---|---|
| 5. ≥ 90% capture without error | 51/55 = 93% | right |
| 6. grid scenes fail more often than returned objects | 1/3 = 33% against 3/42 = 7% | right, on 3 grid figures |
| 7. ≥ 30% of captured figures have a count mismatch | 35/51 = 69% (ggplot 25/31, patchwork 4/4, base 5/10, grid 1/3, heatmap 0/3) | right |
| 8. ≥ 95%: the only unowned element is the background | 51/51 = 100% | right |

- The 4 errors: two layerless ggplots inside patchwork (`wrap_elements()`, `wrap_ggplot_grob()`), a gloss bug; a gganimate animation, which gloss went on to draw instead of refusing; a treemap whose `grid.grab()` scene grid itself cannot draw. None was a refusal, so the plan's rule applies: M1 waits for capture fixes.
- Prediction 6 is right for the reason it gave: the one grid failure is a grabbed scene that lost its viewport structure (`grid.grab()` warns "viewport overwritten").
- Prediction 7 is right by a wide margin and says little: 69% of figures have a count mismatch somewhere. What it costs depends on which leaves mismatch (data layers or gridlines), which the run does not record.

**Second run, made after looking** (`runs/2026-11-10-1159-capture-dev.csv`, at `087476c`, after the fixes `c237e0e`, `bc78662`, `087476c`): 53 captured, 1 refused (the gganimate animation, now with its reason), 1 error (the treemap). On it, predictions 5–8 would read 53/55, 1/3 against 1/42, 36/53, 53/53. It does not replace the scored run.

**Not predicted, measured on the second run: a captured figure is not always the figure the code drew.** The scene equals what the code drew on svglite for heatmap 3/3, patchwork 6/6, ggplot 28/31, grid 2/3, base 1/10. Most base differences are one primitive, the background rect gridGraphics adds. exts-018, a ggbreak `ggcut` drawn by its own print method, was captured as a plain ggplot: another figure, with no error. Prediction 5 counts it as a success.


## Held-out capture run, both routes (page-capture plan Task 8; 2026-11-11)

Written by Claude on 2026-11-11, before any capture has run on a held-out figure, with the owner's go-ahead of the same day. What is known about the held-out set when this is written: its 54 ids, strata and engines (`split.csv`: 29 ggplot, 9 base, 8 patchwork, 5 grid, 3 heatmap), and that every figure reran with no network when the benchmark was frozen. The held-out figures' code has not been read for these predictions, and neither route has captured any of them.

What the predictions rest on: the 55 development figures, on which the page route was built and tuned (runs `2026-11-11-0627`, `-0705`), and the hand-built fixtures. The development set is a random half of the same frozen sample, so the rates should carry over; but 55 figures say little about a failure class that occurs in fewer than about 1 figure in 20 (with 0 of 55 seen, the 95% upper bound on a rate is about 5%, that is up to 3 of 54 held-out figures), and the page route has only ever met the base functions, print methods and page layouts of those 55.

### How the run is made and scored (fixed before the run)

- **Runs.** Each route once: `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R heldout`, in the pinned container with no network.
  - *Page route:* this repository at the commit that holds these predictions, clean tree (the commit is recorded in the run's JSON). `R/` is as in the development run `2026-11-11-0705` except for comments and roxygen text.
  - *Engine route:* a clean clone at the tag `engine-route-final` (`f48c124`), with the tag's own package, harness and `run.sh` (same image digest, same package libraries in the cache). The seven vendored `data/` directories, which are not in git, are copied in; every file under `bench/figures/` in the clone has the checksum of this repository's copy. Its files are archived here as `<stamp>-capture-heldout-engine-route.*`.
  - The first complete run of each route is the one reported. A run that stops before its last figure for a reason outside gloss and the harness (the container, the disk) is archived as it is and started again unchanged. Any change to gloss or to the harness after a held-out result has been read is reported as made after looking, and a rerun never replaces the first run.
- **Outcome of a figure:** as written by `capture.R` at the run's commit. For the page route, a stop is a refusal only if `capture.R` labels it one (mask, no engine, device without groups, integrity check, not a static ggplot, empty page, mixed page, base page on another engine). Three stops gloss explains have no label and therefore count as **errors**: "the input closed gloss's device while drawing", "replaying the base page started a new page", "replaying display-list entry k failed". They stay errors in the score; relabelling them now, the day of the run, would be tuning the count.
- **Verdicts** come from each route's own harness, and this is where the two runs are *not* matched:

  | | Page route (this commit) | Engine route (tag) |
  |---|---|---|
  | Comparator | the bench's own; primitives and the clip regions in force for each | gloss's `scene_signatures()` at the tag; primitives only, blind to a lost clip |
  | Reference for a returned object | the page the object draws alone | the page the code left (can hold more than the object) |
  | A drawn page is handed to gloss as | `recordPlot()` | `recordPlot()` (base), `grid.grab()` (grid) |
  | Verdicts | `equal`, `not_deterministic` (two plain drawings differ), `different` | `equal`, `known_exception` (one extra background rect; a dense leaf), `different` |

  The same figures, container, package libraries and seeds; not the same judge. The engine route's judge is the more lenient on clips and has exceptions, and the stricter on a random figure and on an object that shares its page. So the comparison reported is: outcomes per route, `equal` per route under its own judge, and the figure-by-figure table of both verdicts. No difference in `equal` counts smaller than the figures affected by the judge (listed with the result) is read as a difference between routes.
- **Scorer:** `bench/R/score-capture.R` at this commit, which now accepts a held-out file. On the development runs it prints what it printed before (`2026-11-11-0705`: byte-identical to the archived score). Predictions 5–8 above were made for the development set; the scorer prints their numbers for the held-out runs, and they are not tests of 5–8.
- **Engine-route procedure, tried on the development set first** (made after looking, development only, not a reported number): the clone ran the development set in the container (`runs/2026-11-11-0832-capture-dev-engine-route.*`, commit `f48c124` in its JSON) and gave 51 captured, 3 refused, 1 error; 40 `equal`, 6 `known_exception`, 5 `different`; base 1 of 10 `equal`, 5 of 10 with a count mismatch. These are the counts of the engine-route run `2026-11-10-1424` (`1b22fe1`), so the clone, the copied data and the tag's harness work as the repository did.

### Predictions: page route, 54 held-out figures

9. **At least 50 of 54 are captured; at most 1 error; 0 timeouts.** Point guess: 52 captured, 2 refused, 0 errors. Reasoning: 54 of 55 on the development set, the one refusal an animation. The held-out set may hold what the development set did not: a mask, a page mixing base and grid, a figure that closes or switches devices, a base figure that starts a second page while replaying. Each of those is a refusal or an error by design, not a wrong capture.
10. **No figure the bench finds `different` while gloss says `equal`** (the invariant), **and no captured figure with the bench's verdict `different` at all.** Reasoning: on a grid page gloss's self-check and the bench compare the same two things; 0 of 54 on the development set. Least sure for returned objects whose page depends on what is already on the device, and for recorded pages replayed on a device other than the one that recorded them. Confidence about 85%. *A single such figure is a failed invariant: it blocks M1 and reopens the plan.*
11. **`equal` for at least 47 figures; `not_deterministic` for 0 to 4** (point guess 2). Reasoning: 52 and 2 of 55; random label placement and clustering inside the drawing step are the known sources.
12. **All 9 base figures are captured and `equal`.** Reasoning: 10 of 10 on the development set, 26 of 26 fixtures. Lower confidence than 10: nine figures can call base functions the development figures did not (the development figures drew through `plotXY`, `path`, `axis`, `text`, `segments`, `box`, `polygon`, `symbols`, `rect`, `title`, `mtext`), and one that fails to replay by entry is an error under the rule above.
13. **At most 1 of the 9 base figures has a leaf with a count mismatch.** Low confidence. Reasoning: 0 of 1469 counted leaves on the development set, but the expected counts assume one element per point, string, rect and segment; a point symbol drawn as several primitives (`pch` 3, 4, 8), an empty string, or a rect with neither border nor fill would break that. A mismatch is a leaf gloss declines to bind, not a wrong capture.
14. **gloss's verdict agrees with the bench's on every captured figure** (plan Task 4 reading), **and is identical on all but at most 2.**
15. **In every captured figure the only element without a leaf is the device background** (54 of 54 on the development set).
16. **Tables or panels are withheld in at most 3 captured figures** (1 of 54 on the development set: ggbreak).

### Predictions: engine route at the tag, and the two routes together

17. **The engine route captures fewer figures than the page route or the same number, and at least 2 of the 54 are refused or end in an error** (development: 3 refused for a print method of their own, 1 error on a grabbed grid scene).
18. **Under its own, more lenient judge the engine route has at least 6 fewer `equal` figures than the page route.** Reasoning: 40 against 52 on the development set; base figures alone should account for most of it.
19. **At most 2 of the 9 base figures are `equal` on the engine route** (1 of 10 on the development set; the rest one extra background rect, or different), **and at least 3 of the 9 have a leaf with a count mismatch** (5 of 10).
20. **No figure is `equal` on the engine route and refused, in error or `different` on the page route.** A figure `equal` on the engine route and `not_deterministic` on the page route can occur (heatmap-008 on the development set: the page route's bench draws the figure twice) and is not counted against this.

**What would change the plan:** a failed invariant (10); a base figure the bench finds different (12); a figure the engine route gets right and the page route loses (20). Anything else wrong is reported as wrong and goes to the dev log.
