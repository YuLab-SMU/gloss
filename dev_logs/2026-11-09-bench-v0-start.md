# 2026-11-09 — Bench v0: frames, sample and runner; harvest blocked on permission

- **Related plan:** [plan/2026-11-09-bench-v0.md](../plan/2026-11-09-bench-v0.md) (active; Tasks 1–2 done, Task 3 part 1 done, Tasks 4–6 blocked)
- **Related ADRs:** none
- **Worked on by:** Yonghe Xia, Claude

## What changed

The M0 work, until now uncommitted, went into branch `feat/m0-substrate` as separate commits (code and tests; records; process rules). Then M0 Task 9, the benchmark, started as its own plan.

| File | What it does |
|---|---|
| `bench/R/common.R` | pinned sources (Gallery `8be6801`, ggplot2-exts `10a7d40`, Bioconductor 3.21), seed, Rmd chunk parser, static engine guess |
| `bench/R/frame.R`, `bench/frame/` | one frame per stratum plus `sources.json` |
| `bench/R/sample.R`, `bench/sample.csv` | 160 PSUs, a seed per stratum, full permutations so a second round continues without changing earlier draws |
| `bench/R/runner.R` | runs a PSU expression by expression in a `callr` subprocess; finds figures (returned object, base display list, grid scene); reruns truncated code offline and recovers the figure; optional `gloss()` capture |
| `bench/R/harvest.R` | installs into a separate library, vendors URL data, picks a figure seeded by the id, freezes `bench/figures/<id>/`, checks offline eligibility, writes `runs/attempts.csv` |
| `bench/R/check-runner.R` | self-check on scripts written for it; a third-party part behind `GLOSS_BENCH_THIRD_PARTY=true` |
| `bench/predictions.md` | eight predictions for harvest and capture, committed before any sampled figure ran |

## Measured

- Suite at the start and the end of the session: 7 files, 268 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`). No package code changed.
- Frames (`Rscript bench/R/frame.R`, byte-identical on rerun): gallery 344 posts (2417 R chunks), exts 145, bioc 419 (Bioconductor 3.21; the current release has 459), patchwork 30, heatmap 347.
- Sample (`Rscript bench/R/sample.R`, byte-identical on rerun): gallery 70, exts 30, bioc 30, patchwork 15, heatmap 15.
- Runner self-check (`Rscript bench/R/check-runner.R`): 7 of 7 expected figures found in 8 synthetic chunks; each recovered from truncated code with the network blocked and captured by `gloss()`; 7 of 7 frozen copies eligible offline.
- Not run: any sampled PSU; the third-party part of the self-check; package installs.

## Surprises

- **TidyTuesday has no figure code.** The official repository's weekly directories hold data, `meta.yaml`, a readme and images. → plan scope change (owner review); design note waits for Task 7.
- **A quarter of Gallery posts show their figure code in `eval = FALSE` chunks** and display a pre-rendered image; counting only evaluated chunks, 84 of 344 posts had no plotting code. The frame and runner use all R chunks. → plan Task 1 result.
- **85 of the 154 packages Gallery posts load are not installed here** (hrbrthemes alone in 52 posts). Retention depends on installing them, so harvest installs into `~/.cache/gloss-bench/lib`. → plan sampling design.
- **The runner's first new-page test was wrong twice:** by display-list length it missed `hist()` followed by `barplot()`; by prefix it compared a list with a pairlist and saw a new page everywhere. The synthetic check caught both before any real run. → fixed in `runner.R`.
- **Running the sampled figures was refused by the session's auto-mode permission check** (code from a downloaded repository). → plan scope change; Tasks 3 (part 2) to 6 blocked until the owner decides.

## What's next

- The owner decides how third-party figure code may run: on this machine (subprocesses, temp directories, separate library, as built), inside a container (Docker/OrbStack 29.8.2 is running here; a Bioconductor 3.21 image would match the frame), or not at all, which restricts v0 to already-installed packages and makes the frame a convenience sample.
- Then: `GLOSS_BENCH_THIRD_PARTY=true Rscript bench/R/check-runner.R`, `Rscript bench/R/harvest.R`, split and freeze (Task 5), capture on the development set (Task 6), score the predictions.
