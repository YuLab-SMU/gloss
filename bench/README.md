# bench

The gloss benchmark: R figures with runnable code and data, sampled from published sources, split into a development set and a held-out set. Not part of the package build. The design is [design §评测设计](../dev_docs/design.qmd); the plan that builds v0 is [plan/done/2026-11-09-bench-v0.md](../plan/done/2026-11-09-bench-v0.md).

## Rules

- Rules, prompts and thresholds are tuned on the development set only.
- The held-out set only produces reported numbers. Every run on it is archived in `runs/`; any change made after looking at its results is reported as such.
- Predictions go into `predictions.md`, committed before the run they predict.
- Figures that fail are counted, never dropped: every sampled unit has an outcome row.

M5 semantic evaluation uses the registered task and condition files under
`agent/` and archives traces in `runs/`. The first closed slice used six
development materials and six held-out materials. Four held-out figures yielded
directional tasks under the M5 task rule. M6 adds a pinned image with
`svglite` 2.2.2 (`docker/image-manifest.json`) and writes its canonical material
under the `m6-container` cache namespace. The six M5 held-out host materials
were regenerated in that image: all six were written with zero prepared-view
answer leaks, and all six changed scene hash against the old host material
because the host used `ggplot2` 4.0.3.9000 while the pinned image uses 4.0.3.
The old M5 archives remain unchanged; M6 task files record the new container
scene hashes before any new held-out model run.

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
| `agent/m5-material.R`, `agent/m5-pilot.R`, `agent/score-m5.R` | M5 material writer, fixed-loop semantic runner and archive-only scorer |
| `semantic/m5_checks.R` | deterministic M5 claims, transformed data, masked binding, update and SVG preflight |
| `semantic/m6_env.R`, `semantic/m6_updates.R`, `semantic/m6_audit.R` | M6 container parity, selector ablation and audit-contract archives |
| `agent/m6-pilot.R` | M6 development sizing for raw, checked gloss, SVG-only and prepared-visual conditions |
| `baselines/m6_inventory.R` | M6 comparison-package availability and integration inventory |
| `agent/binding-dsl.R`, `agent/binding-checker.R` | Closed proposal DSL, replay checker and mutation tests for the agent-first binding prototype |
| `agent/material-v1.R`, `agent/binding-run.R` | Development-only public material/oracle writer and four-arm binding archive runner |
| `agent/binding-agent.R`, `agent/sandbox.R` | Fixed-model agent loop with a persistent read-only analysis sandbox and `run_analysis` result contract |
| `docker/` | the pinned container (`run.sh`, `image`) in which all third-party code runs |

## Agent-first binding prototype (2026-11-17)

The first binding prototype is bench-only. It freezes the current package
binding rows as the `legacy` arm and compares them with `contract`, finite
`enumeration` and fixed-model `agent` arms. All arms use the same 84 development
figures, public facts and independent checker. The held-out set is refused by
the material writer and runner.

Write the complete development material in the pinned container after the
predictions section has been committed:

```sh
GLOSS_BENCH_OFFLINE=true GLOSS_BINDING_NAMESPACE=binding-v1 \
  bench/docker/run.sh Rscript bench/agent/material-v1.R dev
```

Each material directory has `public/` and `oracle/` siblings. Public facts,
tables, SVG and grob tree can be mounted read-only in the sandbox. The oracle
holds the captured figure, legacy rows, device geometry and contract replay.
`binding-run.R --dry` exercises all four arms without a model gateway. A real
agent run records the fixed model id, proposal, analysis code hash, tool calls,
usage, elapsed time, sandbox resets and failure reason in
`bench/runs/binding-v1/`.

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

v0 is the five strata above, frozen at `e985d82`: 160 PSUs, 109 figures, 55 development and 54 held-out. Every number reported before 2026-11-11 is v0's and stays so. On 2026-11-11 the owner added a sixth stratum, figures drawn with the ggtree family ([plan](../plan/done/2026-11-11-bench-tree-stratum.md)). It is not part of the population v0 sampled by design: it was chosen because the owner's lab draws such figures, after v0's held-out capture run had been looked at. Its numbers are reported apart, as this stratum's, and are never folded into a number of v0.

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
