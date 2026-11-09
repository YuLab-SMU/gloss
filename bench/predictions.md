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

### Scoring

To be filled in after Tasks 4 and 6, with the counts from `runs/attempts.csv` and the capture run file.
