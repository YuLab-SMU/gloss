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

### Predictions 9–20 on the held-out set (scored 2026-11-11)

Runs, one per route, the first and only ones: page route `runs/2026-11-11-0837-capture-heldout.*` (commit `529426c`, which holds the predictions; clean tree while it ran); engine route `runs/2026-11-11-0843-capture-heldout-engine-route.*` (clone at `f48c124`). Both archived in `f0413eb` before anything else was changed. Scores by `bench/R/score-capture.R` (`*-score.txt`).

| | Page route | Engine route (its own judge) |
|---|---|---|
| Captured | 52 | 53 |
| Refused | 2 (mixed page: bioc-019, bioc-023) | 1 (print method of its own: exts-015, ggsurvfit) |
| Errors, timeouts | 0, 0 | 0, 0 |
| `equal` | 50 | 40 |
| `not_deterministic` | 2 (exts-002, patchwork-013) | no such verdict |
| `known_exception` | no such verdict | 5 (3 one background rect, 2 dense leaf) |
| `different` | 0 | 8 (6 base; exts-002 and patchwork-013, the two random figures) |
| Base figures, 9 | 7 `equal`, 2 refused | 0 `equal`, 3 known exceptions, 6 different |
| Base figures with a count mismatch | 0 of 7 captured | 7 of 9 |

| Prediction | Observed | Verdict |
|---|---|---|
| 9. ≥ 50 captured, ≤ 1 error, 0 timeouts (guess 52 / 2 refused / 0) | 52 captured, 2 refused, 0 errors, 0 timeouts | right |
| 10. No failed invariant; no captured figure `different` | 0 and 0 of 52 | right |
| 11. `equal` ≥ 47; `not_deterministic` 0–4 (guess 2) | 50 and 2 | right |
| 12. All 9 base figures captured and `equal` | 7 of 9; 2 refused as mixed pages | **wrong** |
| 13. ≤ 1 of the base figures with a count mismatch | 0 of 7 captured | right; see the limit below |
| 14. gloss agrees with the bench on every captured figure; identical on all but ≤ 2 | 52 of 52; identical on 50 | right, at the limit |
| 15. Only the device background is unowned, in every captured figure | 52 of 52 | right |
| 16. Tables or panels withheld in ≤ 3 figures | 3 (exts-015, bioc-012, patchwork-013) | right, at the limit |
| 17. Engine route captures no more than the page route; ≥ 2 of 54 refused or in error | 53 against 52; 1 refused | **wrong**, both halves |
| 18. Engine route has ≥ 6 fewer `equal` | 10 fewer (40 against 50) | right |
| 19. ≤ 2 of 9 base figures `equal` on the engine route; ≥ 3 with a count mismatch | 0 of 9; 7 of 9 | right |
| 20. No figure `equal` on the engine route and refused, in error or `different` on the page route | 0 (the 40 are `equal` on both) | right as worded; see below |

- **12 is wrong, and the reason is a defect in gloss, found by this run.** Both refusals say "the page mixes base graphics and grid". For bioc-019 the engine route's own capture shows the page is base only: its scene is the code's page plus one background rect, nothing missing, and gridGraphics redraws base operations only. The figure is the last of a vignette that drew a grid figure on an earlier page. Reproduced afterwards on a hand-built page, not on the held-out figures: a function that draws a grid page and then a base page is refused as mixed, with 0 grid operations on the device's display list for the page and 2 grobs left on grid's own display list from the page before; a page that really mixes the two has a grid operation on the device's display list. gloss counts grid's list, which a new base page does not clear. For bioc-023 (1 grid grob, 64 base operations; its code loads ggplot2 and motifStack) the same cause is likely and **not verified**. The refusal is the safe direction, no wrong capture; it costs figures. Nothing was changed before the runs were archived; the fix and its test are made after looking and are reported in the dev log. Neither held-out run is repeated.
- **17 is wrong.** The engine route captured one figure more than the page route. It did so by capturing the two pages the page route refuses, and neither capture is the code's page under the engine route's own judge (bioc-019: one extra rect, a known exception; bioc-023: 72 primitives differ). The development set had three print-method refusals and one error on the engine route; the held-out set has one refusal and no error.
- **20 holds as worded and comes close to failing in substance.** bioc-019 is a `known_exception` on the engine route, every primitive of the code's page present, and refused on the page route. That is one figure the engine route captured within its stated exception and the page route lost, for the defect above.
- **13 is right and says less than on the development set.** The seven captured base figures have 110 leaves with an expected count, all `ok`, and 137 leaves with none (development: 1469 and 574). A leaf without an expected count cannot mismatch.
- **18, by cause.** The ten figures `equal` on the page route and not on the engine route: seven base figures (five `different`, two with the extra background rect), one refused for its print method (exts-015), two dense figures. Only the two dense ones are the judge's doing: the engine route's judge calls a rasterized leaf a known exception, the page route's compares a vector recapture. Eight of the ten are differences between routes; the clip-blind comparator of the engine route can only have helped it.
- **Not predicted.** Both `not_deterministic` figures are `equal` for gloss (development: one of two): the ggplot engine draws its kept build and patchwork-013's built tables are withheld, so gloss's two drawings are the same page. gloss's self-check did not see either figure's randomness; the bench's two plain drawings did (1399 and 742 primitives). Objects drawn alone equal the page the code left in 36 of 40 (development: 39 of 41). Time per captured figure: median 0.11 to 0.62 s by engine, maximum 5.3 s.

#### Changes made after looking at the held-out run (2026-11-11)

- `21988ee`: gloss reads the kind of page from the device's display list (base operations and grid's drawing operations), not from the grobs on grid's own display list. The test is a hand-built page (a grid page, then a base page), which failed before with "7 base operations, 2 grid grobs". This is the refusal of bioc-019 and probably of bioc-023 (prediction 12).
- Development set after the fix, run `runs/2026-11-11-0858-capture-dev.*` (`21988ee`): every column of every row equals run `2026-11-11-0705` except the seconds; 52 equal, 2 not deterministic, 1 refused.
- The held-out set has not been run again. What the fix does on bioc-019 and bioc-023 is not measured. A later held-out capture run would be reported as made after looking, beside the run scored above, never in its place.

## Binding on the development set (M1 plan 2026-11-11-m1-roles-and-binding, Task 2; 2026-11-11)

Written by Claude on 2026-11-11, before binding has run on any benchmark figure. What is known when this is written: the development capture runs (`2026-11-11-0858`: 54 captured; elements by engine ggplot 26352, patchwork 2295, heatmap 657, grid 1060, base 2933), the leaf names they list (`bench/R/leaf-names.R`: the largest ggplot name stems by elements are `geom_point.points` 13648, `geom_rect.rect` 6174, `box` 2000, `GRID.text` 616, `geom_hex.polygon` 551), and binding on hand-built figures only (`tests/testthat/test-bind.R`: points, regression lines and ribbons, bars under `coord_flip()`, a line on a log scale, `annotate()` text, heatmap cells by place and colour). No development figure's code was read for this.

What is bound, by construction and not predicted: ggplot leaves under a layer and heatmap body cells. Patchwork, grid and base engines state no bindings, so all their leaves are unbound with that reason; ggplot figures drawn by a print method of their own have their tables withheld and are unbound with that reason.

### How the run is made and scored (fixed before the run)

- **Run.** `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bind.R dev`, in the pinned container with no network, at the commit that holds these predictions, clean tree. The first complete run is scored; the development set is for tuning, so later runs after changes are allowed and are labelled as made after looking.
- **Scorer.** `Rscript bench/R/score-bind.R bench/runs/<stamp>-bind-dev.csv`, at the same commit. *Layer elements* are the elements of every leaf except `outside` (axes, legends, strips, titles, panel backgrounds, grid lines) and except leaves of engines that state no bindings; *checked* is verified plus ambiguous over layer elements.
- Tolerance 0.5 pt (design §绑定假设), not changed after the run.

### Predictions

21. **ggplot: at least 80% of layer elements are checked** (verified or ambiguous); point guess 90%. Reasoning: point and rect leaves carry most ggplot elements and verified on every fixture; the rest go unbound (boxplot parts, ribbon outlines, error bars, rotated text, extension grobs), which lowers the share without failing anything.
22. **ggplot: at most 1% of layer elements fail, and no element of a point layer (`GeomPoint`, circles) fails.** A failure means the order of the built rows, or the panel's scales, is not what was drawn; point layers are where that assumption is simplest.
23. **The exts stratum is checked at least 10 points less than the gallery stratum** (share of checked layer elements in ggplot figures). Reasoning: extension geoms draw their own grobs, often several per row or with their own viewports.
24. **The largest unbound class among ggplot layer leaves is "neither one per row nor one per group"** (by leaves).
25. **Heatmap: no body cell fails, and at least 90% of the elements of body leaves are verified** (colour included).
26. **Fewer than 5% of the checked ggplot elements outside dense leaves are ambiguous.**
27. **No captured figure ends in a bind error** (the engine's bind step and the core's checks never stop with an error).

**What would change the plan:** 22 wrong for point layers (assumption 1 of the plan: order binding); 21 far below 80% with the unbound share spread over many classes (the geometry families are too few). Anything else wrong is reported as wrong and goes to the dev log.

### Predictions 21–27 on the development set (scored 2026-11-11)

Run `runs/2026-11-11-1205-bind-dev.*` at `77c21ff` (the commit holding the predictions; clean tree), the first and only complete run before any change; scored by `bench/R/score-bind.R` at that commit. The score file was regenerated afterwards with the scorer's failure listing grouped and a per-figure table added (see the scorer's header); no number below changed. 54 figures captured, 1 not (gallery-053, the animation, as in every capture run).

| Prediction | Observed | Verdict |
|---|---|---|
| 21. ggplot: ≥ 80% of layer elements checked (point guess 90%) | 8094 of 24800 = 32.6%. Per figure: median 99.6%, 17 of 31 figures ≥ 80%, 9 at 0% | **wrong** |
| 22. ggplot: ≤ 1% of layer elements fail; no element of a point layer fails | 2038 failed (8.2%); 0 failed in point layers (`GeomPoint`: 1132 verified, 122 ambiguous, over circles, polygons and rects) | **wrong** in its first half, right in its second |
| 23. exts checked ≥ 10 points below gallery | exts 32.0%, gallery 34.2% | **wrong** |
| 24. Largest unbound class among ggplot layer leaves, by leaves: "neither one per row nor one per group" | "no comparison for `<text>` elements paired one per group", 2000 leaves, one figure (gallery-029); then ggbreak's print method, 29; then "neither one per row nor one per group", 22 | **wrong** |
| 25. Heatmap: no body cell fails; ≥ 90% of body-leaf elements verified | 250 of 250 body cells verified, colour included; annotations and dendrograms (156 elements) unbound by design | right |
| 26. < 5% of checked ggplot elements outside dense leaves ambiguous | 126 of 8094 (1.6%); none in dense leaves | right |
| 27. No captured figure ends in a bind error | 3 (gallery-056, exts-007, bioc-001, all grid pages handed over as recorded plots) | **wrong** |

- **21 and 23 are wrong because two figures hold most of the elements, and both are binder defects, not failures of the order assumption.** exts-022 (12275 elements, half of all ggplot layer elements) is unbound: its panels hold more children than background, 5 layers and foreground, which the binder requires before it pairs anything. gallery-029 (4060) draws `geom_label()`, whose own `draw_panel` makes one child per row; the binder assumed one per group, paired each label with the whole group, and the check failed all 2000 label boxes. The checks did what they are for: a wrong pairing came out `failed`, not `verified`.
- **22's first half is wrong for the same reason and three smaller ones.** Of 2038 failed elements, 2000 are gallery-029's labels; 30 are `geom_area()` outlines, drawn through `ymax` and compared with `y` (gallery-024); 8 are labels that are drawn away from their rows by design (ggrepel, gallery-059; plotROC's offset labels, exts-014). Its second half, the one the plan would change on, holds: no element of a point layer failed.
- **27 is wrong because of a defect in capture, not in binding.** The runner captures each figure twice in one process (once for the capture record, once inside `bind_capture()`). The first capture of a recorded grid page wrapped the leaves of grid's display list in place, and that list is the one inside the caller's recording, so the second capture failed its integrity check ("0 probes drew"). Fixed in `98ad505` with a test that fails before; a gloss user capturing the same recording twice would have hit it too.
- **The plan's trigger is not met.** Assumption 1 would change the plan if point layers failed (none did) or if the unbound share were spread over many classes; it is concentrated in two figures and two causes, both in the binder.

#### Changes made after looking at run 2026-11-11-1205

- `98ad505`: recorded plots are replayed from a deep copy (above).

## Role labels: the pilot (M1 plan Task 1)

Written 2026-11-11, before either annotator labelled a pilot figure, with guideline version 1 (`bench/labels/guideline.md`) and the pilot's five figures drawn by seed (`bench/labels/pilot/select.R`: gallery-070 ggplot, patchwork-006, heatmap-026, gallery-052 grid, gallery-021 base). Annotator A is Claude, B the owner; each labels independently from the sheets. Scored by `Rscript bench/R/score-labels.R agree bench/labels/pilot/claude bench/labels/pilot/owner`.

28. **Roles agree with leaf-weighted Cohen's κ of at least 0.8** (point guess 0.85). Reasoning: most leaves are axes, legends, grid lines and marks, which the guideline names; the guideline's cases were written for the rest.
29. **At least half of the disagreement (leaf-weighted) involves `decoration` or `annotation`** on one side, not `data` against `guide`. Reasoning: backgrounds, borders and typed text are where "carries no information" and "typed by the author" take judgement.
30. **Each annotator splits at most 5% of the pilot's leaves** (more than one role in a leaf; assumption 3 of the plan). Reasoning: the only split the guideline foresees is base `title()` drawing a main title and axis titles; the base figure has one or two such leaves of 36.
31. **Annotator A needs at most 15 minutes for each pilot figure.** Reasoning: the pilot figures hold 13 to 38 leaves.

**What would change the plan:** 28 wrong (κ below 0.8): the guideline is revised and the pilot repeated before the full labels count (assumption 4). 30 wrong: roles are stored per element and rules return element masks (assumption 3). 31 wrong: label a seeded sample of leaves instead of all (Task 1's verification).

**Changed after these predictions were written, before any scoring (2026-11-11).** Annotator B's tool changed twice, both at the owner's request: first a label workbench instead of CSV sheets (`bfd5aa2`), then, after the owner had labelled gallery-070 and heatmap-026 with it, workbench version 2 (`dfec1f9`), which adds aids to see a leaf (fill and stroke, painting, isolating, hiding, moving, drawing order) and shows the guideline's worked examples of leaves of the same class; version 3, the same day and before B labelled further, shows each role and kind in those examples beside its option. Those examples were labelled by annotator A, so versions 2 and 3 can raise B's agreement with A. Prediction 28 will be reported for the five figures as written, and apart for the figures B labelled with version 1 and with the later versions (each figure's state records the version, and each label whether the examples were open). Nothing of B's labels had been read when this was written: only the counts of leaves labelled and the timer (13 and 15 leaves, 317 s and 289 s).

### Predictions 28–31, A against the owner (scored 2026-11-11)

`Rscript bench/R/score-labels.R agree bench/labels/pilot/claude bench/labels/pilot/team/yonghe bench/labels/pilot/sheets`, on the owner's five label files as frozen in the team workbench (2026-11-12 00:14 on the server's clock, 2026-11-11 for the owner), copied to `bench/labels/pilot/team/yonghe/`. 121 leaves with elements; no leaf holds two roles for either annotator. The owner labelled gallery-070 and heatmap-026 with workbench version 1 (no examples shown) and gallery-052, gallery-021 and patchwork-006 with version 4 (examples labelled by A beside each option); the note above asked for the two groups apart.

| Prediction | Observed | Verdict |
|---|---|---|
| 28. κ on roles, leaf-weighted, at least 0.8 (0.85) | **0.822**, agreement 0.876 (15 of 121 leaves differ). Apart: 0.651 on the two figures labelled before the examples were shown (28 leaves), 0.856 on the three after (93). Per figure: gallery-070 0.567, heatmap-026 0.737, gallery-052 0.723, patchwork-006 0.859, gallery-021 0.903; three of five below 0.8 | **right**, by 0.022, and not on the figures labelled without A's examples |
| 29. At least half of the disagreement involves `decoration` or `annotation` | 12 of the 15 leaves; `data` against `guide` 2 | **right** |
| 30. Each annotator splits at most 5% of the leaves | 0 of 121 for both (A gives the two base `axis` leaves three kinds by element, one role) | **right** |
| 31. A needs at most 15 minutes a figure | 10 to 29 s (model time). The owner: 3.0 to 15.3 active minutes, median 5.3 | **right**; says nothing about a person |

- **How firm 0.822 is.** Resampling the 121 leaves with replacement (10000 draws, seed 20261111): 95% of the κ values between 0.737 and 0.901, 29% below 0.8. Resampling the five figures (all 3125 resamples): 0.681 to 0.886, 38% below 0.8. Computed once in a Python session from the two directories, not by a script in the repository. One human annotator and five figures do not place κ on one side of 0.8.
- **The 15 leaves, read against the guideline** (by A, who wrote it; the owner looked at A's labels after freezing and judged them the more correct ones, in the owner's words "你标注的都比我标注的正确"). In 14 the guideline's text decides, and for A's label: four panel grid lines given `decoration` / `background` (gallery-070, version 1); four invisible parts of `ggMarginal` densities given `reference` or `decoration` (gallery-052; the case *Invisible elements*); two heatmap body leaves given `guide` / `colour bar` (heatmap-026, version 1); two panel backgrounds and a base `box()` given `reference` / `reference area`, a kind without an example then; a plot title given `guide` / `other` with the note "像是整个图的title". One the text does not decide: the stamp `textGrob('TOP SECRET')` over patchwork-006, `annotation` / `text` for A (typed content and position, question 4), `decoration` / `other` for the owner (the case for logos); the owner kept it after seeing A's.
- **After freezing** the owner changed 4 leaves (heatmap-026 2 and 3, patchwork-006 4 and 16), each to A's label (`team/yonghe/revised/`). These are made with A's labels in view and are not agreement.
- **Kinds agree less: κ on role and kind 0.664** (agreement 0.702). 22 leaves have the same role and another kind; 15 of them are a boxplot's whiskers, `segment` for A (the kind's definition names whiskers) and `box` for the owner, in both boxplot figures. Two are base `axis` leaves the owner gave one kind; three are heatmap-026's slice titles and column name given `legend title`; two are a figure's background given `border`.
- **What the verdicts do not carry:** A wrote the guideline, the examples and these predictions, so "right by the guideline" is A agreeing with A's own text. What is measured is whether a second person, reading the page's questions, gives the same role: on 106 of 121 leaves.

#### Changes made after looking at these labels (2026-11-11)

- `76e8efc`: a fourth worked example (`ex-box`), which the dev log named as the next step before the owner had finished labelling: `data` / `box` and `reference` / `reference area` get a standard example, labelled by A; workbench version 5. It was built after the role disagreements above were listed and before the kind disagreements were. Its whiskers are `segment`, as the kind's definition says, which is the leaf on which the owner most often chose another kind: annotators from version 5 on are shown A's choice there. Lab members' agreement with A on boxplot leaves (39 of the pilot's 121) and on `reference area` is reported with this said.
- No role, kind, case, question or unit of agreement was changed. The watermark and the whisker are open (guideline cases to decide with the annotators' labels in hand, not before).

### The pilot with several annotators (written 2026-11-11, before any lab member joined)

The owner decided to invite lab members to label the same five figures (plan, Scope changes): one person's labels need not be valid. They label in the team workbench (`serve.py --team`, `--reveal set`): no one sees another's labels before their own five figures are labelled and frozen; `<id>.csv` holds the frozen labels. Annotator A's committed labels are in the team as a read-only annotator. Predictions 28–31 stay as written (A against the owner). "Human annotators" below are the owner and every lab member who finishes all five figures; a pair's κ is on roles, leaf-weighted, over the five figures, by `bench/R/score-labels.R agree` on the two directories. The page's own statistics are a convenience, not the score. If fewer than three human annotators finish, 43–46 are not scorable and are reported so.

43. **The median κ over pairs of human annotators is at least 0.70** (point guess 0.78), **and below the κ of A against the owner.** Reasoning: lab members read the questions and hints on the page, not the guideline; A wrote the examples the page shows.
44. **A's median κ against the human annotators is within 0.10 of the median over human pairs.** Reasoning: if the guideline is what carries the agreement, a model that follows it is one annotator among others; much higher would mean the humans disagree with each other more than with the guideline's author, much lower that A reads the figures differently from people.
45. **Of the leaves on which the human annotators do not all give the same role, at least 80% still have one role given by more than half of them.** Reasoning: disagreement by a lone dissenter is more likely than an even split, if the roles are well defined.
46. **The pair of roles most often confused among human annotators (leaf-weighted) includes `decoration`.** Reasoning: as for prediction 29; grid lines, backgrounds and borders are where "carries no information" takes judgement.
47. **The median active time per figure over human annotators is at most 6 minutes.** Reasoning, and what was seen: the owner's first two figures took 5.3 and 4.8 minutes with version 1; the larger figures hold 36 and 38 leaves.

**What would change the plan:** 43 wrong on the low side (median human κ below 0.70): the roles are not yet something people agree on from the page's questions; the guideline's questions are revised and the pilot repeated with new figures, before the full labels. 44 wrong on the low side: A's labels of the remaining 49 development figures cannot stand in for a person's; the owner decides between a second annotator for all of them and a revised guideline. 45 wrong: the disputed leaves are listed by class, and the guideline gets a case for each class that splits evenly. Not predicted, and not measurable here (no annotator works without them): what the aids and the examples do to agreement.

**Fixed 2026-11-11, before any lab member joined: what the decision rests on.** The owner settled the open question of the plan's Scope change: A is compared with the several annotators, and what most of them give is not taken as correct ("标准可以按你对多人了，但是多人不一定是多数人对"). So: A's κ is computed against each human annotator who finishes the five figures, pair by pair; the criterion of 0.8 is read on the median of those κ values (A's reading of the owner's sentence, written here before the labels exist; the minimum and each pair are reported beside it). The majority label is reported as what most gave (prediction 45) and A is not scored against it. Each leaf on which A differs from most annotators is listed and read against the guideline's text, with the reason, whichever way it falls; a leaf the text does not decide becomes a case in the guideline, and that is a change made after looking.

**Confirmed by the owner, 2026-11-11, before any lab member had labelled:** the median reading above is the owner's ("标准认可"), no longer only A's reading of the owner's sentence. Nothing in the criterion or in predictions 43-52 changes.

### A second batch of ten figures (written 2026-11-11, before annotator A or anyone else labelled one of them)

The owner decided to open a second batch (plan, Scope changes): one annotator and five figures do not place κ on one side of 0.8 (above: 0.737 to 0.901). `bench/labels/batch2/select.R` (seed 20261112) draws two development figures per engine from the 49 captured figures not in the pilot, among those with at most 80 leaves to label (the cap fixed before the draw; five figures of 129 to 4011 leaves are left out and wait for a sample of leaves): bioc-017 and gallery-048 (ggplot), patchwork-012 and patchwork-008, heatmap-008 and heatmap-036, gallery-056 and exts-007 (grid), gallery-040 and bioc-009 (base); 255 leaves, against the pilot's 121. They are added to the team workbench's set (guideline version 1, workbench version 5, `--reveal set`), after annotator A's labels of them are committed.

Who labels under which condition, fixed here: **lab members** who join from now on label all fifteen figures before any label of anyone else opens to them. **The owner** froze the pilot's five and looked at A's labels of them before the second batch existed, so the owner's ten are labelled knowing how A labels; they are reported apart and never pooled with the owner's pilot. **A** labels the ten from the page, the sheet and the code before any person does, having seen the owner's pilot labels and nothing of the ten. An annotator counts for a set of figures when they finished all of it.

**What the decision on the full development labels rests on, restated before any lab member joined.** The criterion fixed above (κ on roles at least 0.8, read on the median of A's pairwise κ against the human annotators) is read twice: on the pilot's five figures, over the owner and the lab members, as fixed; and on all fifteen, over the lab members only (blind on all of them). The labels count if both are at least 0.8. If the two fall on different sides, the fifteen-figure reading decides, having three times the figures, and that is said with the result. With fewer than two lab members finishing the fifteen, only the pilot's reading exists and the second batch is reported as what it is.

48. **A against the owner on the ten: κ on roles, leaf-weighted, at least 0.85** (point guess 0.88), above the pilot's 0.822. Reasoning: the owner has seen A's labels of the pilot and judged them the more correct; what separated them most (grid lines, invisible leaves, a kind without an example) is now known to the owner or shown. Against it: two heatmaps and a 73-leaf patchwork, where the pilot's figures of those engines gave 0.737 and 0.859.
49. **Lab members blind on all fifteen: the median of A's pairwise κ against them, over the fifteen, is at least 0.75** (point guess 0.80), **and on the ten it is below A against the owner.** Reasoning: they have A's examples but not A's labels; the owner's blind figures with the examples shown gave 0.856, without them 0.651.
50. **The two figures of the ten with the lowest agreement with A (mean over the human annotators of the share of leaves given A's role) are among the four heatmap and grid figures.** Reasoning: in the pilot the heatmap and the grid figure were below the patchwork and the base figure (0.737 and 0.723 against 0.859 and 0.903); slice titles, annotation tracks and grobs without names take the code to read. The pilot's ggplot figure was lowest (0.567) for grid lines read as background, which the owner now knows and the lab members have an example of.
51. **The owner labels the ten at no more than the pilot's 17.3 s a leaf of active time** (2092 s for 121 leaves; point guess 12 s, 51 minutes for 255 leaves). Reasoning: practice, and fewer invisible leaves to puzzle over than gallery-052's.
52. **A splits no leaf of the ten between two roles, or at most 5% of them** (13 of 255). Reasoning: none of 121 in the pilot; the split the guideline foresees is base `title()`.

**What would change the plan:** 48 wrong (below 0.85) with the owner knowing A's labels: the page's questions do not carry the guideline even to a calibrated reader; the disagreeing leaves are read class by class and the guideline revised before the full development labels. 49 wrong on the low side (below 0.75): A's labels cannot stand for a person's on the development set, and the held-out protocol of ADR-0008 (A labels all, people a sample) starts from a worse prior; its fallback (two people label everything) is the more likely outcome. 50 wrong: the weak point is not the engines thought hardest; the per-engine examples are revisited. Not measurable here: what the owner's view of A's pilot labels did to the owner's ten, since no owner labelled them without it.

## Binding patchwork compositions on the development set (M1 plan Task 2b)

Written 2026-11-11 at `8f99857`, before any binding run with the patchwork engine's bind step, after reading the six figures' code (not their capture or binding output). Run: `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bind.R dev`, scored by `bench/R/score-bind.R`. The other engines' numbers are expected to equal run `1231`'s.

32. **No patchwork figure ends in a bind error, and no element of a point or bar layer fails** (a plot paired with another plot's build would fail them).
33. **The plots `inset_element()` adds (patchwork-008's `p2`, patchwork-010's `pcol`) are not found:** their layer leaves are unbound with "belongs to no plot", not paired. Reasoning: insets are drawn in cells the engine's walk does not look for.
34. **Every `geom_sf()` layer (patchwork-010's map, both plots of patchwork-011) is unbound:** its panel's scales cannot be mapped (`CoordSf`).
35. **The scatter `p1` binds in full in patchwork-006, -008 and -012:** 32 of 32 points verified or ambiguous in each; the `gtable` patchwork-006 adds (`p2_table`) is unbound with "belongs to no plot".
36. **The boxplot of patchwork-012 is not verified:** its whiskers (two segments per box) are unbound and its boxes unbound or failed. Reasoning: the binder knows no boxplot geometry; this is a gap in ggplot binding that patchwork only shows.

**What would change the plan:** 32 wrong (a failed point or bar element): the plot mapping is wrong somewhere, and Task 2b is not done. 33 wrong because insets are paired and verify: good news, the walk covers them. 33 wrong because insets are paired and fail: as 32.

### Predictions 32–36 on the development set (scored 2026-11-11)

Run `runs/2026-11-11-1319-bind-dev.*`, started at `b2d971b` (the commit holding the predictions). The working tree did not stay clean: while the run was going, `base_expected()` in `R/core-substrate.R` was edited (expected counts for more base calls, M1 Task 5), and the container reads the live tree, so figures captured after the edit used it. Binding does not read base expected counts (base leaves are all unbound, "states no bindings", before any count is consulted), and ggplot and heatmap numbers equal run `1231`'s in every column, so no number below depends on the edit. Scored by `bench/R/score-bind.R` at `b2d971b`.

| Prediction | Observed | Verdict |
|---|---|---|
| 32. No patchwork bind error; no point or bar element fails | patchwork-012 ends in a bind error ("arguments imply differing number of rows: 1, 0"); 0 failed elements in the other five | **wrong** |
| 33. Inset plots not found; their layer leaves unbound, "belongs to no plot" | patchwork-008's `p2` and patchwork-010's `pcol`: unbound with that reason | right |
| 34. Every `geom_sf()` layer unbound, `CoordSf` | patchwork-010's map (1606 elements) and patchwork-011's two plots (20) | right |
| 35. `p1` binds in full in patchwork-006, -008, -012; `p2_table` unbound | 006 and 008: 30 verified, 2 ambiguous (Mazda RX4 and RX4 Wag share mpg and disp); 012: bind error; `p2_table` unbound with "belongs to no plot" | **wrong** (012) |
| 36. patchwork-012's boxplot not verified | not scorable: the figure's binding stopped with the error | — |

- **32 and 35 are wrong for one defect in the core's comparisons, not in patchwork.** A boxplot's built rows carry no `y`; comparing its box polygons by vertex mean built a table from `y` and stopped. Any ggplot boxplot would have hit it; the 31 ggplot development figures draw none. The plot mapping itself held: no element failed.
- **Not foreseen:** a panel no plot owns had its background and grid lines counted with its layer leaves as unbound (patchwork-006 and -008: 14 leaves, 34 elements each, of which 9 leaves are layers).
- Patchwork layer elements in this run: 1775; verified 60, ambiguous 4, failed 0, unbound 1711 (sf 1626, panels no plot owns 85).

#### Changes made after looking at run 2026-11-11-1319

- Each comparison declares the row columns it reads; a layer missing one is unbound with the reason ("the rows paired with <polygon> elements have no y").
- A panel no plot owns: only the leaves in its layer slots are unbound; its background, grid and foreground are outside.

## Base expected counts and capture after Task 2b (M1 plan Task 5, first part)

Written 2026-11-11, before any capture run with the new expected counts (`base_expected()` for `polygon`, `path`, `symbols`, `arrows`, `abline` and `plotXY` types other than `p` and `l`) or with the patchwork engine's own drawing step (`8f99857`). Run: `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev`, compared with run `2026-11-11-1220` and its scorer.

37. **The base leaves of the development set left without an expected count are the guide calls only:** `axis` 19, `box` 29, `title` 7 and `mtext` 2, 57 leaves (574 before); no data-mark call is left without one.
38. **None of the newly counted base leaves is `count_mismatch`.**
39. **Every other column of the capture run equals run `1220`, figure by figure, apart from the seconds**, patchwork figures included: the patchwork engine's drawing step prints the composition as before, so its pages are the same.

### Predictions 37–39 on the development set (scored 2026-11-11)

Run `runs/2026-11-11-1339-capture-dev.*` at `c9f10b4` (clean tree; predictions committed in it), compared with run `2026-11-11-1220` column by column (38 columns besides the seconds, 55 rows).

| Prediction | Observed | Verdict |
|---|---|---|
| 37. Base leaves without an expected count: the guide calls only, 57 (574 before) | 57 (574 before); 57 is `axis` 19 + `box` 29 + `title` 7 + `mtext` 2, which have no rule, so no data-mark leaf is left without a count | right |
| 38. No newly counted base leaf is `count_mismatch` | 0 of 2043 base leaves `count_mismatch`; `ok` 1469 → 1986 | right |
| 39. Every other column equals run `1220`, apart from the seconds | the columns that describe the page (verdicts, primitives, clip regions, faithful, deterministic, every count of leaves and elements) are equal on all 55 figures; three patchwork columns changed: `panels` (0 → 1, 1, 1, 2, 5 on five figures), `drawn_by` (`print()` → `the engine`, six figures) and `withheld` (`panels` on patchwork-008 and -010, the insets) | **wrong** as written: these columns record what `8f99857` set out to change, and the prediction did not except them; what it was for, that the pages stay the same, holds |

## Base binding on the development set (M1 plan Task 5, second part)

Written 2026-11-11, before any binding run with the base engine's bind step (each data-mark entry's elements paired with its call's arguments, through the entry's `usr` and log axes), after reading the 10 base figures' code and the leaf classes of capture run `1339` (not any binding output for base). Run: `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bind.R dev`, scored by `bench/R/score-bind.R` (base leaves of data-mark calls: `plotXY`, `segments`, `arrows`, `rect`, `polygon`, `path`, `text`, `symbols`). The same run is Task 2b's rerun after looking at run `1319`; its patchwork numbers are reported, not predicted.

40. **No base figure ends in a bind error.**
41. **At least 80% of the elements of base data-mark leaves are verified or ambiguous** (point guess 90%); every unbound one has a reason naming its call's type, `pos`, plotmath, heads or symbol kind.
42. **No base element fails.** The arguments are what the entry drew; a failure would mean a wrong `usr`, log axis or plot region, not a wrong pairing.

### Predictions 40–42 on the development set (scored 2026-11-11)

Run `runs/2026-11-11-1353-bind-dev.*` at `6af0ad5` (clean tree; no file was edited during the run), scored by `bench/R/score-bind.R`.

| Prediction | Observed | Verdict |
|---|---|---|
| 40. No base figure ends in a bind error | 0 bind errors on all 54 captured figures | right |
| 41. ≥ 80% of the elements of base data-mark leaves verified or ambiguous (point guess 90%); each unbound one with a reason naming its type, `pos`, plotmath, heads or symbol kind | 2637 of 2674 = 98.6% (verified 2544, ambiguous 93); unbound 37, all `plotXY` of type `h` (19, bioc-004 and bioc-009) or `o` (18, bioc-004), with that reason | right |
| 42. No base element fails | 0 | right |

- By call: `path` 483 of 483 verified (the sf maps of gallery-013 and gallery-038), `plotXY` 1981 (1888 verified, 93 ambiguous: overplotted points in gallery-008's scatterplot matrix), `polygon` 21, `rect` 14, `segments` 57, `symbols` 17, `text` 64, all verified. 57 guide leaves (`axis`, `box`, `title`, `mtext`) are outside.
- These bindings are to the calls' arguments, not to a data frame: the arguments are vectors the call received.

**Patchwork, rerun after looking at run `1319`** (same run, not predicted): no bind error; 1783 layer elements, verified 98, ambiguous 6, failed 0, unbound 1679: `CoordSf` 1626, layers of panels no plot owns 41 (patchwork-006's gtable, the insets of -008 and -010), patchwork-012's boxplot 12 (whiskers: two segments per box; medians: no comparison for one line per row; boxes: rows without `y`). Every point and bar of the composed ggplots is verified or ambiguous.

## The tree stratum: capture on its development figures (tree plan Task 5)

Written 2026-11-11, before gloss has captured any figure of the stratum. What was known when they were written: the code of the 29 development figures (28 `ggtree` objects, 1 patchwork), that all 29 rerun with no network, and v0's development run `2026-11-11-1339`. Nothing of the stratum's 28 held-out figures was read beyond what the harvest table holds.

### How the run is made and scored (fixed before the run)

- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev tree`, at the commit that holds these predictions, with a clean tree. It writes `runs/<stamp>-capture-dev-tree.*`; the 29 figures are those of `set_figures(split, "dev", "tree")`.
- `Rscript bench/R/score-capture.R` on that file prints the numbers. Its lines "Prediction 5" to "Prediction 8" were made for v0 and are numbers here. Predictions 53-57 are read from its tables by the rules below.
- The numbers are the stratum's. They are not added to a number of v0.

### Predictions

53. **At least 27 of the 29 figures are captured, and none is refused for lack of an engine.** Each is a ggplot or a patchwork, which gloss captures from the page; v0: 37 of 38 ggplot and patchwork development figures. Read from "Outcomes by engine". If one fails I expect it to be tree-041, whose tips are images drawn by ggimage.
54. **At most 9 of the captured figures have a leaf with a count mismatch, and at most 3 have one in a panel grid line.** v0: 30 of 37 ggplot and patchwork figures have a mismatch leaf; in 19 every such leaf is a panel grid line, and 11 (30%) have one elsewhere (text, points of several shapes, paths). `theme_tree()` draws no grid, so the stratum should sit near the 30%, not the 81%. Read from the run's `leaves_mismatch` and `mismatch_leaves` columns (a leaf named `panel.grid.*`).
55. **Every captured figure's verdict is `equal`, except tree-054, which is `not_deterministic`; no figure is `different`, and gloss's own verdict is the same on every figure.** tree-054 places labels with `geom_label_repel()` and no seed, as v0's one `not_deterministic` ggplot (gallery-059) does. Read from "Fidelity verdicts" and "The bench's verdict against gloss's own".
56. **In every captured figure the only unowned element is the device background.** v0: 54 of 54. Read from the line "Prediction 8".
57. **No figure times out; the median capture takes under 1 second and the slowest under 60.** v0's ggplot and patchwork figures: median 0.36 s, maximum 27 s on 12347 elements. Read from the `seconds` column and the status table.

### Predictions 53-57 on the stratum's development figures (scored 2026-11-11)

Two runs. `runs/2026-11-11-2052-capture-dev-tree.*` at `d73bde9` (clean tree; the predictions committed in it) is the run the predictions were made for. In it the bench's own comparator gave no verdict on five captured figures, all from book chapters: the book's setup loads `conflicted`, and the comparator's bare `setdiff()` stopped inside the worker ("found in 3 packages"). That is a defect of the bench, not of gloss, whose own verdicts were recorded for all 28. It was fixed in `a578985` (the worker's code is closed over base; a check that fails without the fix), and `runs/2026-11-11-2110-capture-dev-tree.*` at `a578985` is the same run again. **The second run was made after looking at the first.** Nothing in gloss changed between them, and on the 23 figures that had a verdict every column of the two runs is equal apart from the seconds. The same fix left v0 where it was: `runs/2026-11-11-2104-capture-dev.*` equals run `1339` in all 38 columns besides the seconds, on all 55 figures.

| Prediction | Observed | Verdict |
|---|---|---|
| 53. At least 27 of 29 captured; none refused for lack of an engine; if one fails, tree-041 | 28 of 29 in both runs, no refusal. tree-041 is an error, not a refusal: `internal error: Huge input lookup`, the XML parser's limit on a text node, met by the page's embedded images | right |
| 54. At most 9 captured figures with a count-mismatch leaf; at most 3 with one in a panel grid line | 6 of 28 (21%; v0's ggplot and patchwork figures 30 of 37, 81%), none in a panel grid line: text leaves in all six (tree-014, -045, -061, -062, -077, and the 43 repelled labels of tree-054) and one leaf of points in tree-014 | right |
| 55. Every verdict `equal` except tree-054 `not_deterministic`; none `different`; gloss's own verdict the same on every figure | first run: 23 `equal`, 5 with no verdict of the bench (the defect above), so not scorable as written; second run: 27 `equal`, tree-054 `not_deterministic` (two plain drawings differ in 309 primitives), none `different`, gloss's verdict identical on all 28. gloss's own verdicts were these in the first run already | right on the second run; **not scorable on the run it was made for** |
| 56. The only unowned element is the device background, every captured figure | 28 of 28 | right |
| 57. No timeout; median under 1 s, slowest under 60 s | no timeout; median 0.34 s and slowest 4.8 s (tree-014, 14830 elements) in the first run, 0.30 s and 3.8 s in the second | right |

- 4 right of 5 on the first run with one not scorable, 5 of 5 on the second. I named tree-041 as the likely failure and tree-054 as the one that is not deterministic; both for the reason given.
- **tree-041 is a defect of gloss, and of the bench's comparator in the same way.** gloss stops with an internal error where it should either read the page or refuse and say why. Not changed here: it goes to the plan that tunes gloss on this stratum, with a test that fails first.
- The mismatch leaves are text, not grid lines, which `theme_tree()` does not draw. Why a text leaf of a tree draws a different number of elements than its grob holds is not known from this run; the binding run names the counts.
- One figure's page differs from the object drawn alone (tree-066: 335 primitives; the code left more on the page than the object), with the verdict `equal` on the object's own page, as the scorer reports for v0.
- Not predicted, and seen only because this run was looked at: **the bench trusted the search path the figure's code builds.** v0 has no figure that loads `conflicted`; a package that masks a base function with a different one would have changed the bench's own arithmetic without an error.


## The tree stratum: binding on its development figures (tree plan Task 5)

Written 2026-11-11, after the stratum's capture runs and before gloss's bind step has run on any figure of the stratum. What was known: the capture runs' tables (which show leaves and counts, no binding), the code of the 29 development figures, the binder's rules as written in `R/core-bind.R` and `R/engine-ggplot.R`, and v0's binding run `2026-11-11-1353`.

### How the run is made and scored (fixed before the run)

- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bind.R dev tree`, at the commit that holds these predictions, with a clean tree; scored by `Rscript bench/R/score-bind.R` on its file. Layer elements, verified, ambiguous, failed, unbound and count_mismatch as that script defines them.
- "Cartesian figures" are the captured figures other than tree-025, tree-038 and tree-057, whose trees are drawn on polar coordinates (`open_tree()`, `layout_inward_circular()`).
- The numbers are the stratum's. They are not added to a number of v0.

### Predictions

58. **No captured figure ends in a bind error.** v0: 0 of 54.
59. **The three figures on polar coordinates bind nothing:** every layer leaf of tree-025, tree-038 and tree-057 is unbound, with the reason that the panel's scales cannot be mapped (`CoordPolar`), and none of their elements is verified, ambiguous or failed. The ggplot engine maps rows to the device through continuous or discrete panel scales only.
60. **Branches bind on Cartesian figures:** of the `line` elements in leaves paired with a segment geom (ggtree's own or ggplot2's `GeomSegment`), at least 95% are verified or ambiguous and none fails. A branch is a segment whose two ends are in the layer's built rows.
61. **Labels set off from their node by justification fail the binder's text rule, though the pairing is right.** The rule is "the anchor's x at the row's x, the row's y inside the text's box"; a label with `hjust` or `vjust` outside 0..1 is drawn away from its row's position by a share of its own size. The text leaves written so in tree-011 (`geom_tiplab(hjust = -.1)`), tree-060 (`geom_nodelab(hjust = -.1)`), tree-062 (`vjust = -.5`) and tree-083 (`hjust = -0.5`, `vjust = -0.7`) have failed elements, and so have the repelled labels of tree-054 that are not count mismatches (v0's one `GeomLabelRepel` figure: text and box failed). **At least 90% of the run's failed elements are in these five figures.**
62. **The plain trees bind whole.** Of tree-008, -010, -012, -017, -021, -032, -046, -050, -068, -069 and -074 (a tree, with tip labels justified inside 0..1, tip or root points, a root edge, strips or one facet panel of points), at least 9 of the 11 have every layer element verified or ambiguous: none failed, unbound or in a count-mismatch leaf.

A point guess that is not scored, because three figures hold most of the elements (tree-014 14830, tree-061 5281, tree-079 2185) and I cannot tell how their layers bind: verified or ambiguous on about 80% of the layer elements of the Cartesian figures.

### Predictions 58-62 on the stratum's development figures (scored 2026-11-11)

Run `runs/2026-11-11-2118-bind-dev-tree.*` at `0cc6e72` (clean tree; the predictions committed in it; no file edited during the run), scored by `bench/R/score-bind.R`. 28 figures bound, tree-041 not captured as before.

| Prediction | Observed | Verdict |
|---|---|---|
| 58. No bind error | 0 on 28 captured figures | right |
| 59. The three polar figures bind nothing, with the reason naming `CoordPolar` | 10 layer leaves, 241 elements, all unbound with "the panel's scales cannot be mapped (CoordPolar)"; none verified, ambiguous or failed | right |
| 60. Branches on Cartesian figures: at least 95% of `line` elements of segment geoms verified or ambiguous, none failed | 5216 of 5216 (verified 5196, ambiguous 20), failed 0, in 69 leaves of 25 figures | right |
| 61. At least 90% of the failed elements are in tree-011, -060, -062, -083 and -054 | 169 of 212 (80%). tree-011 76, tree-060 14 and tree-083 38, all in the text leaves named; tree-054 41, its label boxes; tree-062 none. Outside the five: tree-046 26, tree-014 11, tree-045 6 | **wrong** |
| 62. At least 9 of the 11 plain trees bind whole | 10 of 11: every layer element verified or ambiguous in all but tree-046 | right |

- 4 right of 5. The point guess that was not scored, 80% of the Cartesian figures' layer elements verified or ambiguous, was far off: 9984 of 24674, 40.5%. One leaf holds half of them: tree-014's 12690 points in eight shapes, a count mismatch (the leaf drew 12690 elements, its grob holds 8100; shapes drawn with more than one primitive are a known limit). Without that leaf it is 83.3%.
- **What I did not know when I wrote 61 and 62: in every figure from a book chapter the text is not text.** The book's setup attaches `emojifont`, which turns `showtext` on, and `showtext` draws each glyph as a path. Checked in the container after the run: two labels of five letters come out as 2 `<text>` before `library(emojifont)` and as 5 `<path>` after. A text leaf then draws one element per glyph, so it is a count mismatch (1721 elements in 49 leaves of tree-014, -054 and -062), except where every label is one glyph: tree-046's tip labels A to M and 11 labels of tree-014 pass the count and fail on position, which is the 37 failed elements I did not predict there. tree-062's labels, which I expected to fail, were never compared for the same reason.
- tree-045's 6 failed elements (3 label boxes, 3 tip labels; `plot_tree(orient = "v")` of cardelino) are not explained yet.
- The text rule fails rightly paired labels, as predicted, in three figures: 128 elements. I predicted the outcome from the rule; that justification is the cause is the reading that predicted it, not something a test has shown.
- Per figure, of the 27 ggplot figures: every layer element checked in 15, at least 80% in 18, none in 3 (the polar ones). v0's ggplot figures: 98.4% of elements checked. Other unbound elements: 34 of rotated clade labels (tree-072), 28 connector lines of repelled labels (tree-054), 5 of a text leaf with 5 elements for 11 rows (tree-003).
- Binding adds little time: median 0.40 s for capture and bind, 4.7 s at most.


## The tree stratum after the parser's limit is lifted (tree binding plan Task 1)

Written 2026-11-11, after gloss and the bench's comparator were changed to parse their own pages with libxml2's `HUGE` option and before either has run on any figure of the stratum since. What was known: runs `2110` (capture) and `2118` (binding) on the stratum's development figures, tree-041's code (a 6-tip tree; tip images through `geom_tiplab(geom = "image")`, `align = 2`; tip labels through `geom_tiplab(geom = "label", hjust = .5)`; one more image through `geom_image()`; the book's setup, so `emojifont` and `showtext`), and the fixture test in `test-capture.R`. Nothing of the stratum's held-out figures.

### How the runs are made and scored (fixed before the runs)

- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev tree`, then `... bench/R/bind.R dev tree`, at the commit that holds these predictions, with a clean tree. Scored with `score-capture.R` and `score-bind.R` on their files, and the binding run against run `2118` with `Rscript bench/R/compare-bind.R bench/runs/2026-11-11-2118-bind-dev-tree.csv <new run>`.
- The capture run is compared with run `2110` column by column, as the tree plan compared runs `2052` and `2110`.

### Predictions

63. **29 of 29 figures are captured, and tree-041's verdict is `equal` by the bench and by gloss.** On the other 28, every column of the run equals run `2110` apart from the seconds. The change lifts a size limit of the parser and nothing else.
64. **tree-041's capture takes under 60 s, and its only unowned element is the device background.** Its page is the largest of the stratum by bytes, not by elements.
65. **No bind error, and the 28 figures bound in run `2118` bind exactly as there:** `compare-bind.R` reports all 561 of their leaves with status, counts and reason unchanged.
66. **tree-041 has no failed element:** its branch segments (and the dotted lines `align` draws) are all verified or ambiguous; its image leaves are unbound with the reason that no comparison exists for `<image>` elements; its tip labels' text is in count-mismatch leaves (glyph outlines, as in every book figure). So under 80% of its layer elements are checked.

Not scored: the label boxes of tree-041 are verified or ambiguous (`hjust = .5`, so a box is centred on its row).

### Predictions 63-66 on the stratum's development figures (scored 2026-11-11)

Runs `runs/2026-11-11-2221-capture-dev-tree.*` and `runs/2026-11-11-2224-bind-dev-tree.*`, both at `4391fdb` (clean tree; the predictions committed in it), in the container with no network.

| Prediction | Observed | Verdict |
|---|---|---|
| 63. 29 of 29 captured; tree-041 `equal` by the bench and by gloss; the other 28 equal to run `2110` in every column but the seconds | 29 of 29; tree-041 `equal` by both (125 primitives on each side). On the other 28, 0 cells differ in 37 columns; the 38th, `message`, is empty for every figure in both runs (with no figure in error the column is all empty, and `read.csv` reads it as NA) | right |
| 64. tree-041 under 60 s; its only unowned element the background | 6.6 s (the slowest of the run; median 0.32 s); 1 unowned element, the background | right |
| 65. No bind error; the 28 figures of run `2118` bind exactly as there | 29 bound, no error. `compare-bind.R` against `2118`: 561 of 561 leaves with status, counts and reason unchanged; 0 regressions | right |
| 66. tree-041: no failed element; branches and `align`'s dotted lines checked; images unbound for no `<image>` comparison; label text in count-mismatch leaves | 122 layer elements: 24 verified, 10 **failed**, 17 unbound (images, the reason as predicted), 71 in count-mismatch leaves (the six labels' glyph outlines, as predicted). Branches: 22 of 22 verified. The failed: the 6 dotted lines of `align` (up to 128 pt off) and 4 of the 6 label boxes (0.67 to 0.74 pt off) | **wrong** |

- 3 right of 4. Not scored and wrong as well: 2 of tree-041's 6 label boxes are verified, not all.
- **Why the dotted lines fail:** ggtree draws them with `GeomSegmentGGtree`, whose `draw_panel()` adds a geom parameter, `nudge_x`, to x at draw time; `geom_tiplab()` passes its `offset` there (2 here, about 128 pt). The built rows do not carry it. A geom that moves its rows while drawing is what design §绑定假设 calls a per-geom adapter; nothing in the binder knows it. The pairing is right; the check rightly fails.
- **Why the label boxes fail is not the book's fonts:** the same six labels drawn with plain `geom_label(hjust = .5)` on the host, without `showtext`, give the same deviations (0.72, 0.74, 0.67, 0.74; 0.50 and 0.37 pass). The binder compares a polygon's vertex mean with the row; a label's box is not centred on its row to 0.5 pt. tree-045's 3 failed label boxes, "not explained" in run `2118`, are the same class. v0's 2000 label boxes (gallery-029) passed as ambiguous.
- The 11 copies of the frog image are `geom_image(x = .8, y = 5.5)` with x and y set as parameters: one image per row of the tree's 11 nodes, all at one place.
- Stratum, after Task 1 (ggplot figures, 28): every layer element checked in 15, at least 80% in 18, none in 3; 25037 layer elements, 40.0% checked, failed 222, unbound 325, count mismatch 14482.
