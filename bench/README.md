# bench

The gloss benchmark: R figures with runnable code and data, sampled from published sources, split into a development set and a held-out set. Not part of the package build. The design is [design §评测设计](../dev_docs/design.qmd); the plan that builds v0 is [plan/done/2026-11-09-bench-v0.md](../plan/done/2026-11-09-bench-v0.md).

## Rules

- Rules, prompts and thresholds are tuned on the development set only.
- The held-out set only produces reported numbers. Every run on it is archived in `runs/`; any change made after looking at its results is reported as such.
- Predictions go into `predictions.md`, committed before the run they predict.
- Figures that fail are counted, never dropped: every sampled unit has an outcome row.

## Layout

| Path | What it holds |
|---|---|
| `R/common.R` | paths, pinned sources, seed, helpers |
| `R/frame.R` | builds the sampling frames |
| `frame/*.csv`, `frame/sources.json` | one frame per stratum, and the source versions they came from |
| `R/sample.R`, `sample.csv` | the PSU sample: stratum, rank in the stratum's permutation, weight |
| `R/runner.R`, `R/harvest.R` | run a PSU in a subprocess, find its figures, install packages, vendor URL data, freeze one figure |
| `R/offline-check.R`, `R/spot-check.R` | rerun frozen figures with no network (all of them; 10 of them 3 times) |
| `R/attribution.R`, `figures/SOURCES.md` | source, version and license of each frozen figure |
| `R/split.R`, `split.csv`, `MANIFEST.md5` | the seeded development / held-out split and the checksums of the freeze |
| `figures/<id>/` | one frozen figure: `code.R`, `meta.json` (in git), `data/` (not in git) |
| `runs/` | outcome rows of every attempt (`attempts.csv`), check results, logs, archived earlier runs |
| `predictions.md` | predictions, committed before the runs they predict, and their scores |
| `docker/` | the pinned container (`run.sh`, `image`) in which all third-party code runs |

Data vendored from URLs (`figures/<id>/data/`, 7 figures) is not in git: several sources state no license (owner's decision, 2026-11-10). Its checksums are in `MANIFEST.md5` and its URLs in `meta.json`.

Two package environments, each with its own library: `cran` (CRAN snapshot 2026-10-22) for the gallery, exts and patchwork strata; `bioc` (Bioconductor 3.21 with CRAN 2025-10-29, the last day 3.21 was the release) for bioc and heatmap. Each figure's `meta.json` records its environment, and reruns use it.

## Sources (v0)

| Stratum | Frame | Pinned at |
|---|---|---|
| gallery | R Graph Gallery posts (`*.Rmd`, `package/*.Rmd`) | commit `8be6801` |
| exts | ggplot2 extensions gallery entries marked as on CRAN | commit `10a7d40` of `ggplot2-exts/gallery` |
| bioc | Bioconductor software packages in the Visualization view with vignettes | Bioconductor 3.21 VIEWS |
| patchwork | Gallery posts loading patchwork, and patchwork help topics with examples | as above; patchwork 1.3.2 |
| heatmap | ComplexHeatmap help topics with examples, and Bioconductor packages with vignettes importing ComplexHeatmap | ComplexHeatmap 2.26.0; Bioconductor 3.21 |

TidyTuesday, listed in the design, is not in v0: its official repository has data but no figure code (see the plan's scope changes).

Sampling seed: `20261109`; stratum *h* (in the order gallery, exts, bioc, patchwork, heatmap) uses `20261109 + h` with `RNGkind("Mersenne-Twister", "Inversion", "Rejection")`. Allocation: 70, 30, 30, 15, 15.

## Rebuilding

Run from the repository root. Sources and downloads go to `~/.cache/gloss-bench/` (override with `GLOSS_BENCH_CACHE`), never into the repository.

```sh
Rscript bench/R/frame.R
Rscript bench/R/sample.R
```
