# 2026-11-09 — Bench v0 harvest: harness defects found by the first full run

- **Related plan:** [plan/2026-11-09-bench-v0.md](../plan/2026-11-09-bench-v0.md) (active; Tasks 1–3 done, Task 4 in progress, Tasks 5–7 open)
- **Related ADRs:** none
- **Worked on by:** Yonghe Xia, Claude
- **Follows:** [2026-11-09-bench-container.md](2026-11-09-bench-container.md)

## What changed

The first full harvest (`bench/docker/run.sh Rscript bench/R/harvest.R`, harness at `4fde108`) was read while it ran. Its outcomes showed harness defects, not properties of the figures. They were fixed with checks, while the run finished on the old harness; the harvest is then rerun from scratch.

| File | Change |
|---|---|
| `bench/R/runner.R` | the worker prints visible values as knitr does (S4 via `show()`), except widgets, tables and apps (`outside_classes`); a print error stops the run (stage `print`); visible values are recorded with all their classes |
| `bench/R/runner.R` | `clean_code()`: no-break spaces (U+00A0) become spaces, install calls commented out as before; the count goes to `meta.json` and the `code.R` header |
| `bench/R/runner.R` | `gallery_script()` drops the Gallery's closing `includeHTML()` chunk |
| `bench/R/runner.R` | `ensure_packages()` keeps install warnings (and logs them), retries failed downloads twice, gives a reason per failed package |
| `bench/R/runner.R` | `rewrite_literal()`: a vendored URL inside `download.file()` becomes `file://data/<file>`; shapefiles are vendored with `.shx`, `.dbf`, `.prj`, `.cpg` |
| `bench/R/harvest.R` | `run_installing()`: a package named by an error (base R, caret, rlang wording) is installed and the script rerun (up to 3 rounds); `psu_outcome()` (pure) decides the outcome of a PSU without a figure; classifier: caret/rlang missing packages, relative-path `cannot open URL`, GDAL `Cannot open "…"` |
| `bench/R/check-runner.R` | lattice chunk; a ggplot failing at print; a Gallery-style post with U+00A0 and `includeHTML()`; Part 1c on the first run's recorded messages |

## Measured

- Suite: 7 files, 45 tests, 268 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`). No package code changed.
- First full harvest, first 115 of 155 outcomes (in progress): the misclassified or harness-caused outcomes are listed under Surprises. Final counts of this run are added below when it ends.
- `Rscript bench/R/check-runner.R` (host, synthetic) on `4fde108` with the new checks: synthetic 7 of 8 figures (the lattice plot missed); the broken ggplot counted as 2 figures, no error; the Gallery-style post and Part 1c failed (functions absent). After the fixes: 8 of 8 found, recovered, captured (the lattice figure: grid, 48 elements, 11 leaves), eligible offline; broken ggplot: 0 figures, stopped at print in chunk 2; Gallery-style post: 1 base figure, clean run; Part 1c OK. `runner check: OK`.
- `GLOSS_BENCH_THIRD_PARTY=true bench/docker/run.sh Rscript bench/R/check-runner.R` (container): same synthetic result; third-party part 4 base, 2 ggplot, 4 heatmap as expected, and both Gallery posts now run without stopping (before: both stopped at `includeHTML()`). `runner check: OK`.
- Scans of the Gallery checkout (344 posts): 275 end with an `includeHTML()`-only chunk; 10 contain U+00A0.
- `parse(text = "x <- 1 ")` fails with "unexpected input" on the host (macOS, R 4.5.2, en_US.UTF-8) as in the container (Linux, R 4.5.2, en_US.UTF-8).
- Not run: the shapefile sidecars and the `download.file()` rewrite on real data (only the rewrite is unit-checked); they are exercised by gallery-013 and bioc-005 in the rerun.

## Surprises

- **The runner never printed visible values.** `withVisible(eval(...))` does not print; only figure classes were recognised as objects. Figures drawn by a print method (lattice, GGally's `ggmatrix`, ggalign, UpSetR and others) were invisible, and a ggplot erroring only at print counted as a figure (and would be "retained" without ever being drawn). gallery-067, a lattice-only post, was recorded as "missing data". The self-check had no figure of this kind. → fixed in `runner.R`; check-runner chunk 8 and Part 1a; plan scope change (rerun).
- **Every Gallery post ends on an error.** 275 of 344 close with `htmltools::includeHTML()` of a file that lives on the website, not in the repository. Where a figure came first it did no harm; otherwise the error replaced the true outcome (widget and table posts gallery-026, -034, -039 recorded as "missing data"). The self-check had noted this stop on both of its posts without seeing it as a problem. → chunk dropped in `gallery_script()`; plan scope change.
- **No-break spaces break 4 of 69 sampled Gallery posts**, in chunks knitr evaluates (`echo=FALSE`). Current R rejects U+00A0 outside strings on both platforms, so the posts as published no longer knit. Replacing them is a mechanical edit like commenting out install calls; inside a string it changes a no-break space into a space. → `clean_code()`, recorded per figure; plan scope change.
- **Package downloads through the proxy fail now and then** (`SSL connect error` from `rspm-sync.rstudio.com`): ggsurvfit and ggerror, both in the 2026-10-22 snapshot, were recorded as "missing package", and gallery-057 (showtext) as "needs network" after a font download timed out. The proxied route had 0 of 12 failures in the earlier probe. → retries in `ensure_packages()`; gallery-057 is retried by the rerun; nowhere else yet.
- **"Not available" never reached the install log**: install.packages() reports it as a warning, and the sink only caught output and messages. ggTimeSeries, ggseas, ggpol and ggheatmap failed with an empty log section and an empty detail. → warnings logged and kept as the reason.
- **Vendoring broke two data paths**: a URL inside `download.file()` rewritten to a bare path (bioc-005 Voyager: `cannot open URL 'data/tissue_lowres_5a.jpeg'`, classed "needs network"), and a shapefile fetched without its sidecars (gallery-013: GDAL `Cannot open`, classed "code error"). → `rewrite_literal()`, sidecars; classifier reads both as "missing data" if they recur.
- **Packages reached through another package's Suggests were never installed.** bioc-015 condiments stopped on caret's "Required packages are missing: randomForest". The static scan cannot see these. → `run_installing()`.
- **gallery-049 is recorded as "missing package" (rgeos, archived) with a parse error as detail**: a failed install takes precedence over the run's error. Kept; the detail now names both. → nowhere else.

## What's next

- When the first run ends: record its counts here, archive `bench/runs/attempts.csv` as `bench/runs/2026-11-09-harvest-1.csv`, move its frozen figures out of `bench/figures/`, rerun the harvest with the fixed harness, compare per PSU.
- Then the offline check (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/offline-check.R`), predictions 1–4 scored on both runs, the open questions from the container log (vignettes drawing only into files; purled vignettes losing `eval = FALSE` chunks).
