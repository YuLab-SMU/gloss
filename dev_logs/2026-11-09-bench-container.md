# 2026-11-09 — Bench v0 in a pinned container: environment, scope rule, offline pass

- **Related plan:** [plan/2026-11-09-bench-v0.md](../plan/2026-11-09-bench-v0.md) (active; Tasks 1–3 done, Task 4 in progress, Tasks 5–7 open)
- **Related ADRs:** none
- **Worked on by:** Yonghe Xia, Claude
- **Follows:** [2026-11-09-bench-v0-start.md](2026-11-09-bench-v0-start.md)

## What changed

The owner decided that third-party figure code runs in a container (plan Scope changes). This session built that environment, ran the runner self-check in it, and fixed what the check exposed before any sampled figure ran.

| File | What it does |
|---|---|
| `bench/docker/image` | `bioconductor/bioconductor_docker@sha256:359702d4…` (RELEASE_3_21; linux/arm64; R 4.5.2) |
| `bench/docker/run.sh` | repo read-only except `bench/figures`, `bench/runs`; cache volume; CRAN pinned to the 2026-10-22 snapshot; forwards the host proxy; `GLOSS_BENCH_OFFLINE=true` runs with `--network none` |
| `bench/R/setup-container.R` | installs the harness and gloss's dependencies into the container's library |
| `bench/R/common.R` | one package library per platform and R version; `rd_example_code()`, `has_example_code()` |
| `bench/R/frame.R`, `bench/frame/` | topics without example code kept but marked `in_scope = FALSE` |
| `bench/R/sample.R`, `bench/sample.csv` | out-of-scope rows skipped; weights by in-scope frame size |
| `bench/R/runner.R` | installs always use the pinned CRAN; install errors logged; `package_topics()` drops topics without example code |
| `bench/R/check-runner.R` | third-party part asserts exact engines counted from the sources |
| `bench/R/snapshot-coverage.R` | static count of units needing a package absent from a CRAN snapshot |
| `bench/R/offline-check.R`, `bench/R/split.R` | no-network rerun of every retained figure; the split uses only figures that pass it |

## Measured

- Suite at the start of the session: 7 files, 45 tests, 268 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`). No package code changed.
- Container smoke test: `/gloss/R` not writable, `bench/runs` writable; R 4.5.2, Bioconductor 3.21, 12 cores.
- Container network, direct route (OrbStack): 2 of 5 HTTPS requests failed (one hung over 2 minutes, one timed out at 30 s). Through the host proxy at `host.docker.internal`: 12 of 12 succeeded, 1.4–5.6 s each.
- Heatmap frame: 153 of the 253 ComplexHeatmap topics have examples that are only `# There is no example` and `NULL`. Same count in 2.24.1 (container) and 2.26.0 (host). patchwork: 0. Of the 15 sampled heatmap PSUs, 10 were such topics.
- Re-run of `Rscript bench/R/frame.R` and `Rscript bench/R/sample.R` with the scope rule: gallery, exts and bioc frames byte-identical; 150 of 160 draws unchanged (id, rank, PSU); the 10 placeholder draws replaced by heatmap ranks 16–34 (6 topics, 4 vignettes); heatmap in-scope N = 194, weight 12.93.
- `Rscript bench/R/snapshot-coverage.R 2025-12-09 2026-10-22 2026-11-09`, units needing a package absent from CRAN + Bioconductor 3.21 + base:

  | CRAN snapshot | Gallery frame | Gallery posts in sample | exts frame | exts sample |
  |---|---|---|---|---|
  | 2025-12-09 (image build day) | 86/344 | 23/77 | 25/145 | 5/30 |
  | 2026-10-22 (Gallery commit day) | 35/344 | 9/77 | 15/145 | 4/30 |
  | 2026-11-09 | 35/344 | 9/77 | 15/145 | 4/30 |

- `bench/docker/run.sh Rscript bench/R/setup-container.R` (CRAN 2026-10-22): 6 installed, 14 present, 0 failed; ggplot2 4.0.3, ComplexHeatmap 2.24.1, patchwork 1.3.2, svglite 2.2.2, gridGraphics 0.5.1.
- `GLOSS_BENCH_THIRD_PARTY=true bench/docker/run.sh Rscript bench/R/check-runner.R` → `runner check: OK`: synthetic 7/7 found, recovered, captured, eligible; `13-scatter-plot.Rmd` 4 base, `164-area-chart-ggplot2.Rmd` 2 ggplot, `ComplexHeatmap::densityHeatmap` 4 heatmap, each equal to the count read from the source. Host synthetic part: 7/7, OK.
- Offline blocking, in the container: the dead proxy used by harvest's eligibility check blocks `url()` and `download.file()` but not a raw `socketConnection()`. With `GLOSS_BENCH_OFFLINE=true` (`--network none`) the raw socket is blocked too.

- Not run: any sampled PSU. The harvest pilot (`bench/docker/run.sh Rscript bench/R/harvest.R gallery-001 exts-001 bioc-001 patchwork-001 heatmap-005`) was refused by the session's auto-mode permission check. A first attempt passed the ids as one zsh word and matched nothing, so it ran nothing. `offline-check.R` and the `split.R` change have not run (no retained figures yet); only the `--network none` mode of `run.sh` was tested.
- Suite at the end: unchanged, 7 files, 45 tests, 268 expectations, 0 failed, 0 skipped (no package code changed this session).

## Surprises

- **60% of ComplexHeatmap's help topics have no example code**, and 10 of 15 heatmap draws were among them. Found only because the self-check's heatmap topic, `ComplexHeatmap::Heatmap`, is one of them and returned 0 figures; the check printed that but did not fail, because its third-party part had no expectations. → plan scope change (topics without example code out of scope, 10 draws replaced); predictions.md dated note; check-runner now asserts exact counts.
- **The image's build date was the wrong CRAN date.** hrbrthemes (52 Gallery posts) was archived from about mid-2025 to early 2026; the 2025-12-09 snapshot left 86 of 344 Gallery posts needing an absent package, the Gallery commit's date (2026-10-22) leaves 35. → plan scope change; `run.sh` pins 2026-10-22.
- **Most plotting packages were not in the image.** ggplot2, ComplexHeatmap, patchwork and svglite all came from the bench library, so changing the CRAN date changed ggplot2 (4.0.1 → 4.0.3). → nowhere yet; recorded here and in plan Current state.
- **The dead proxy is not offline.** A raw socket reaches the network through it. → `offline-check.R` reruns each retained figure with no network interface; `split.R` refuses to split without it. Plan Task 4 result (when it lands).
- **The container's direct network route is flaky** (2 of 5 requests failed). → `run.sh` forwards the host proxy.
- **`install.packages()` errors were not in the install log** (they are messages; only output was sunk). The hrbrthemes failure showed a header line and nothing else. → fixed in `runner.R`.
- **My first expected count for the scatter post was wrong** (3, from a source read truncated at 60 lines; the post has 4 `plot()` calls). The exact check caught it. → corrected in `check-runner.R`, noted in plan Task 3.

- **The permission check let the self-check's third-party code run in the container but refused the harvest pilot.** → plan Task 4 status `[!]`; the owner runs the harvest or allows it.

## What's next

- The owner runs the harvest, or allows it: pilot first (`bench/docker/run.sh Rscript bench/R/harvest.R gallery-001 exts-001 bioc-001 patchwork-001 heatmap-005`), then all PSUs (`bench/docker/run.sh Rscript bench/R/harvest.R`, resumable), then `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/offline-check.R`; then score predictions 1–4.
- Then the split and freeze (Task 5), capture on the development set (Task 6).
