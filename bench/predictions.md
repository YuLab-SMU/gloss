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
