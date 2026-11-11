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
