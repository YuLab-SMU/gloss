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
| `R/frame-tree.R`, `R/check-tree.R`, `R/split-tree.R`, `runs/tree-candidates.csv` | the stratum added in v1 (below): its frame, the check of its figure test, its split, every figure its PSUs drew |
| `R/check-scope.R` | which figures a run covers: v0's strata together, an added stratum on its own (below) |
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

## A stratum added after v0: tree figures (v1, 2026-11-11)

v0 is the five strata above, frozen at `e985d82`: 160 PSUs, 109 figures, 55 development and 54 held-out. Every number reported before 2026-11-11 is v0's and stays so. On 2026-11-11 the owner added a sixth stratum, figures drawn with the ggtree family ([plan](../plan/2026-11-11-bench-tree-stratum.md)). It is not part of the population v0 sampled by design: it was chosen because the owner's lab draws such figures, after v0's held-out capture run had been looked at. Its numbers are reported apart, as this stratum's, and are never folded into a number of v0.

| Stratum | Frame | Pinned at |
|---|---|---|
| tree | Help topics with examples of ggtree and ggtreeExtra; Bioconductor packages with vignettes that depend on or import either; the chapters the ggtree book builds (`R/frame-tree.R`, `frame/tree.csv`, `frame/sources-tree.json`) | ggtree 3.16.3, ggtreeExtra 1.18.1; Bioconductor 3.21; treedata-book `1af8f25` |

The frame was fixed, with the owner, before anything of it was drawn or run: 85 PSUs, 84 in scope. Every PSU in scope and not drawn by an earlier stratum is taken (83; seed `20261109 + 6` orders them and names them `tree-<rank>`). The 160 rows of v0 in `sample.csv` are byte-identical before and after. All of it runs in the `bioc` environment.

A figure counts for this stratum when the object its expression returns is a `ggtree` plot or a patchwork that holds one (the runner's `tree`; `R/check-tree.R`); the frozen figure must come back so with the network blocked. Every figure a PSU of the stratum drew, counted or not, is in `runs/tree-candidates.csv`. A book chapter is run alone, after the book's shared setup (`p_load(x)` read as `require(x)`, the files it sources inlined), one figure per chapter by seed like any PSU; its frozen code is redistributed under the license of the book's online version, CC BY-NC-SA 4.0 (`figures/SOURCES.md`).

The stratum is split by `R/split-tree.R` (seed `20261109 + 100 + 6`) before any capture run on one of its figures; `split.csv` gains rows and loses none.

A run names a set, and a set is v0's: `capture.R dev` and `bind.R heldout` cover the 55 and 54 figures they covered before, and every archived run of v0 scores as it did. The stratum is run on its own, by its name after the set (`capture.R dev tree`), its files carry the name (`<stamp>-capture-dev-tree.csv`), and `score-capture.R` checks such a run against the stratum's figures only (`set_figures()` in `R/common.R`; `Rscript bench/R/check-scope.R`). Until 2026-11-11 the scripts took every row of `split.csv` with the set asked for; once the stratum's rows were added, a `dev` run would have covered 84 figures and the archived runs could not be scored again ("55 of 84 figures"). Nothing was run in that state.

Harvested and split on 2026-11-11: of the 83 PSUs, 57 give a frozen tree figure (34 of 41 help topics, 15 of 26 vignettes, 8 of 16 book chapters), 13 draw no figure of the stratum, 7 stop on a code error, 3 need the network when rerun, 3 are outside the population; all 57 rerun with no network. 29 are development, 28 held-out. The test loses at least one tree figure (`ggplot(tree) + geom_tree()`, a plain ggplot) and cannot see into `aplot` compositions (three PSUs drew nothing else). With this stratum the bench holds 166 figures: v0's 109 and these 57.

Sampling seed: `20261109`; stratum *h* (in the order gallery, exts, bioc, patchwork, heatmap) uses `20261109 + h` with `RNGkind("Mersenne-Twister", "Inversion", "Rejection")`. Allocation: 70, 30, 30, 15, 15.

## Rebuilding

Run from the repository root. Sources and downloads go to `~/.cache/gloss-bench/` (override with `GLOSS_BENCH_CACHE`), never into the repository.

```sh
Rscript bench/R/frame.R
Rscript bench/R/sample.R
```
