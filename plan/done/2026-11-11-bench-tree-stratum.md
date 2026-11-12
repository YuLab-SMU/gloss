# Bench v1: a stratum of tree figures (the ggtree family)

> Status: closed 2026-11-11 (opened the same day on the owner's decision to add figures of the ggtree kind; the owner settled decisions 1 and 2 that day, see Scope changes).
> Date opened: 2026-11-11. Owner: Yonghe Xia.

**Goal:** The bench holds a stratum of tree figures drawn with the ggtree family, sampled by seed from a frame fixed before the draw and split into development and held-out halves before any gloss code runs on them, so that capture, roles and bindings can be reported for this family apart from the 109 figures of v0.

**Why now:** The bench holds one figure of the family, and it is held-out (bioc-021, a MicrobiotaProcess vignette), so nothing measured so far says anything about tree figures ([dev log 2026-11-11](../../dev_logs/2026-11-11-m1-plan.md), *Surprises* of the team workbench session). They are the figures the owner's lab draws. The owner decided on 2026-11-11 to add them.

**Starting state (measured):**

- Suite: 9 files, 88 tests, 544 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-11, host, at `25d6751`). Nothing under `R/` or `tests/` is touched by this plan.
- Bench v0, frozen at `e985d82`: 160 PSUs sampled, 109 figures retained, 55 development and 54 held-out (`bench/split.csv`). Tree figures: 1 (searching the figures' code for the packages' names).
- The frame of the new stratum (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/frame-tree.R`, 2026-11-11): 69 PSUs. 42 help topics with examples of ggtree 3.16.3 and ggtreeExtra 1.18.1 as installed in the bench's `bioc` environment (41 in scope; `ggtree::zoomClade` has no executable example line), and the 27 Bioconductor 3.21 software packages with vignettes that depend on or import ggtree or ggtreeExtra. One of the 27, MicrobiotaProcess, was drawn in the `bioc` stratum of v0 and is skipped by `sample.R`'s rule, which leaves 67.

**Assumptions to test** (riskiest first):

1. *Enough of the frame gives a tree figure.* A vignette of a package that imports ggtree may draw no tree in the vignette the seed picks (enrichplot draws mostly dot plots). Tested in Task 3. Fewer than 16 retained figures (8 and 8) from the allocation chosen: the next round continues down the same permutation, or the frame is widened by a new decision of the owner's, made before looking at any figure of the round.
2. *"A tree figure" can be told by code:* the object the figure's expression returns has class `ggtree` first. A tree drawn by a package's own function that returns a patchwork or an `aplot` composition is not counted. Tested in Task 3 by listing, for every PSU that ran, the classes of all the figures it drew; the count of compositions that hold a tree is reported, and a different test is a Scope change made before the split.
3. *The v0 harvester runs these PSUs without change* beyond the stratum's class test (topics and vignettes are kinds it knows; the `bioc` environment holds ggtree). Tested in Task 3's first run.
4. *The existing five strata's draws do not move* when `sample.R` gains a sixth. Tested in Task 2: `git diff` of `bench/sample.csv` shows added rows only.

**Architecture:** One more stratum through the v0 pipeline, nothing new in kind: `frame-tree.R` → `frame/tree.csv`; `sample.R` with a sixth stratum (seed `20261109 + 6`); `harvest.R` with a class test for the stratum; the offline check; a split of the stratum alone (seed `20261109 + 100 + 6`), appended to `split.csv`; attribution and manifest appended. The 109 figures, their split, their runs and every number reported on them are not touched. Not touched either: `R/`, `tests/`, the label workbench.

**Out of scope:** Tuning anything in gloss for tree figures (a later plan, on the stratum's development half only). The ggtree book and CRAN packages that import ggtree as sources (decision 1). Labels of the new figures (a third batch for the lab, if the owner wants one, after the split). Pooling the stratum into v0's numbers.

**Tech stack:** R, the bench's pinned container and its `bioc` environment (Bioconductor 3.21, CRAN snapshot 2025-10-29).

**Done when:**

- Every sampled PSU of the stratum has an outcome row in `bench/runs/attempts.csv`; none is dropped.
- Every retained figure reran in the container with no network and gave a figure whose class is `ggtree`.
- The stratum is split by seed before any capture run on one of its figures; `bench/split.csv` and `bench/MANIFEST.md5` differ from v0's by added rows only.
- `bench/README.md` states v1: the stratum, its frame, seed and allocation, that it was added after the held-out capture run of v0 had been looked at, and that its numbers are reported apart.
- Predictions for the first capture run on the stratum's development half are committed before that run.

**Decisions (the owner's; recommendations are Claude's):**

1. *The frame.* (a) As built: help topics of ggtree and ggtreeExtra, and the 27 Bioconductor packages that depend on or import them, one seeded vignette each: 67 PSUs available. Everything is pinned by v0 already (Bioconductor 3.21 `VIEWS`, the `bioc` environment). (b) (a) plus the chapters of the ggtree book (treedata-book) as a third kind, pinned at a commit: the richest source of the family's figures, and a new kind of source to pin, fetch and run (its data, its packages). (c) Help topics only: 41 PSUs, cheap to run, and only the package authors' own minimal examples. **Recommended: (a)**, with (b) as a later round if (a) gives too few figures or too plain ones. The frame cannot be changed after the first figure of the stratum is seen without the change being reported as made after looking, which is why it is asked before the draw.
2. *The allocation.* (a) All 67 available PSUs: no sampling error within the frame, some 26 package installs in the container (hours, in the background), several of which will end as "missing package" outcomes. (b) 40 by seed, a later round continuing down the permutation if needed. **Recommended: (a)**: the frame is small, and the heatmap stratum's 3 + 3 figures show what a small allocation leaves.
3. *How it is reported* (not asked; as the bench's rules require): apart from v0's 109 figures, as a stratum added after the fact and chosen because the lab draws such figures, with its own weights; never inside a number already reported.

---

## Progress tracking

**Status legend**
- `[ ]` Not started
- `[~]` In progress
- `[x]` Completed
- `[!]` Blocked
- `[-]` Cancelled

**Plan maintenance rules**
- Update when a task lands, in the same commit as the code.
- When marking `[x]`, record the command and the observed result (counts, numbers, figure set).
- When a result contradicts an assumption of this plan or of the design, append a `Scope change` with the evidence and revise the open tasks. Never edit completed ones.

**Current state** _(update as results come in)_
- Suite: 9 files, 88 tests, 544 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-11).
- Key numbers: frame 85 PSUs (84 in scope, 83 available: 41 help topics, 26 vignettes, 16 book chapters); sampled 83; retained 57; all 57 rerun with no network; split 29 development, 28 held-out. No capture run on any of them yet.

**Overall progress**
- [x] Task 1: The frame
- [x] Task 2: The draw
- [x] Task 3: Harvest with the stratum's class test; outcomes
- [x] Task 4: Offline check, split of the stratum, attribution, manifest
- [x] Task 5: Predictions, then the first capture run and the first binding run on the stratum's development half
- [x] Task 6: Records: bench README (v1), design notes, dev log, closing notes

---

### Task 1: The frame

**Status:** `[x]` (2026-11-11)

**Tests assumption:** none.

**Files**
- Create: `bench/R/frame-tree.R`, `bench/frame/tree.csv`, `bench/frame/sources-tree.json`.

**Intent**
- Fix what the stratum is drawn from before anything of it is run or seen, from sources v0 already pins.

**Checklist**
- [x] Help topics with examples of ggtree and ggtreeExtra, read from the `bioc` environment's library in the container (the host has ggtree 4.0.1, the environment 3.16.3).
- [x] Bioconductor 3.21 software packages with vignettes that depend on or import either, from the cached `VIEWS-3.21` (md5 `c31abce8…`, the one v0's frame records).
- [x] Out-of-scope rule as in v0: a topic whose examples have no executable line stays in the frame and is skipped by the draw.

**Result**
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/frame-tree.R`: 69 rows, 68 in scope (topics 41 of 42, vignettes 27 of 27). The script writes to `bench/runs/frame-tree/` (the container mounts `bench/frame` read-only); the two files were copied to `bench/frame/`. The five v0 frames are not read or written (`git status`: two new files).

---

### Task 2: The draw

**Status:** `[x]` (2026-11-11)

**Tests assumption:** 4.

**Files**
- Modify: `bench/R/sample.R` (a sixth stratum, `tree`), `bench/sample.csv` (rows added), `bench/R/common.R` (`env_for_stratum("tree")` is `bioc`).

**Checklist**
- [x] `sample.R` with `tree` last in the order, seed `20261109 + 6`, the allocation of decision 2.
- [x] `git diff bench/sample.csv`: added rows only; the 160 rows of v0 byte-identical.

**Verification**
- `Rscript bench/R/sample.R`; `git diff --stat bench/sample.csv`; a removed or changed line is a defect of the change, not a result.

**Result**
- `Rscript bench/R/sample.R`: 243 PSUs, 83 of them `tree-001` to `tree-084` by rank (41 topics, 26 vignettes, 16 book chapters; MicrobiotaProcess, drawn as bioc-021 in v0, skipped; `ggtree::zoomClade` out of scope). The first 161 lines of `bench/sample.csv` are byte-identical to v0's file (`cmp`); `git diff --numstat`: 83 added, 0 removed. Assumption 4 holds. Committed before any PSU of the stratum was run.

---

### Task 3: Harvest with the stratum's class test; outcomes

**Status:** `[x]` (2026-11-11)

**Tests assumptions:** 1, 2, 3.

**Files**
- Modify: `bench/R/harvest.R` (a figure counts for the stratum when its class is `ggtree`; the frozen figure's rerun must give that class again), `bench/R/check-runner.R` (a check of the class test).
- Create: `bench/figures/tree-*/`, rows in `bench/runs/attempts.csv`.

**Checklist**
- [x] The class test, with a check that fails first.
- [x] Harvest in the container, online for installs, every PSU of the stratum; one outcome row each.
- [x] For every PSU that ran: the classes of all figures it drew (assumption 2), compositions holding a tree counted.

**Verification**
- `bench/docker/run.sh Rscript bench/R/harvest.R <tree ids>`; outcome table by kind. Fewer than 16 retained: assumption 1's branch.

**Result**
- The test and the book kind (`271d7a7`): `Rscript bench/R/check-tree.R`, failing first (no `tree` column, no `book_script`), then 10 of 10 OK on the host (ggtree 4.0.1) and offline in the container (ggtree 3.16.3, ggplot2 4.0.0). `Rscript bench/R/check-runner.R` on the host: runner check OK, so the five strata of v0 run as before.
- Harvest at `1f09e30`, in the container: `tree-001` and `tree-005` first, then the other 81 (45 minutes wall-clock, 47 minutes of PSU time, the longest PSU 277 s; the `bioc` library already held most packages). 83 outcome rows, none missing; the 160 rows of v0 in `attempts.csv` byte-identical (`cmp`).

  | Kind | PSUs | retained | no figure | code error | needs network | outside population |
  |---|---|---|---|---|---|---|
  | help topic | 41 | 34 | 7 | 0 | 0 | 0 |
  | vignette | 26 | 15 | 6 | 3 | 0 | 2 |
  | book chapter | 16 | 8 | 0 | 4 | 3 | 1 |
  | all | 83 | **57** | 13 | 7 | 3 | 3 |

  Assumption 1 holds (57, against a floor of 16). Assumption 3 holds: no harness error, no missing-package outcome.
- What every PSU drew (`bench/runs/tree-candidates.csv`): 69 of the 83 drew at least one figure, 255 in all; 159 hold a tree by the test (119 `ggtree`, 2 `ggtreeSpace`, 38 patchwork holding one). Not counted: 56 plain ggplot, 13 grid, 10 `aplot`, 6 patchwork without a tree, 6 `ggsc`, 3 base, 2 `ggraph`. The retained figures: 52 `ggtree` plots and 5 patchwork compositions.
- **Assumption 2 holds with a known loss.** One PSU drew a tree the test does not see: `ggtree::geom_tree`, whose example is `ggplot(tree) + geom_tree()`, a plain ggplot. Three more ended as "no figure" having drawn only `aplot` compositions, which may hold a tree and cannot be told so by class (ggmsa 1, scDotPlot 4, SVP 3). The test was fixed before the run and is not changed (Scope changes).
- Code errors, read from the outcome rows: two are ggtree 3.16.3 objects that ggplot2 4.0.0 refuses (`@mapping must be <ggplot2::mapping>`; chapter 9 and mitology), a mismatch inside the pinned `bioc` environment (Bioconductor 3.21 with CRAN of its last day); one is the book's `conflicted` setting stopping `as.factor` (chapter 12); one chapter needs an object of an earlier chapter (chapter 3, `nhx`). Three chapters need the network when rerun (`BiocManager::repositories()`, a download inside a geom, the Open Tree of Life API).

---

### Task 4: Offline check, split of the stratum, attribution, manifest

**Status:** `[x]` (2026-11-11)

**Files**
- Modify: `bench/R/split.R` or a sibling that splits one added stratum without touching existing rows; `bench/split.csv`, `bench/MANIFEST.md5`, `bench/figures/SOURCES.md` (rows added).

**Checklist**
- [x] `offline-check.R` on the stratum's retained figures (no network).
- [x] Split by seed `20261109 + 100 + 6`, before any capture run on a figure of the stratum; the odd figure to development, as in v0.
- [x] `git diff` of `split.csv` and `MANIFEST.md5`: added rows only.

**Result**
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/offline-check.R tree`: 57 of 57 rerun with no network interface and come back holding their tree; the rows of v0 in `offline-check.csv` unchanged.
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/attribution.R`: `figures/SOURCES.md` gains 59 lines and loses none (57 figures, the book's license sentence); every figure has a license (8 chapters under CC BY-NC-SA 4.0).
- `Rscript bench/R/split-tree.R`: 29 development (28 ggplot, 1 patchwork), 28 held-out (24 ggplot, 4 patchwork). It checks that no figure of the stratum is in a capture run's table. `split.csv`: 57 lines added, 0 removed, the first 110 lines byte-identical to v0's. `MANIFEST.md5`: 121 lines added and 5 replaced, the five being files that grew by rows (`sample.csv`, `split.csv`, `runs/attempts.csv`, `runs/offline-check.csv`, `figures/SOURCES.md`); no checksum of a v0 figure or frame changed.
- The bench after this: 166 figures (109 + 57), 84 development (55 + 29), 82 held-out (54 + 28), the two parts reported apart.

---

### Task 5: Predictions, then the first capture run on the stratum's development half

**Status:** `[x]` (2026-11-11)

_Written out on 2026-11-11, after Task 4 and the Scope change on run scope. Until then a stub._

**Tests assumptions:** none of the plan's; it is the first measurement of gloss on the stratum, and decides what the next plan on it should be about.

**Files**
- Modify: `bench/predictions.md` (predictions 53-57, then their scores; predictions for the binding run, then their scores).
- Create: `bench/runs/<stamp>-capture-dev-tree.*`, `bench/runs/<stamp>-bind-dev-tree.*`.

**Checklist**
- [x] Predictions for the capture run, committed before it (53-57).
- [x] `capture.R dev tree` in the container with no network, at the commit of the predictions, clean tree; scored.
- [x] Predictions for the binding run, written after the capture run and committed before the binding run. The capture run does not show bindings.
- [x] `bind.R dev tree`; scored with `score-bind.R`.
- [x] Nothing in gloss is changed between the two runs. What the runs show goes to the next plan, not into this one.

**Verification:** the two runs' files in `bench/runs/`, each with its score file; `Rscript bench/R/check-scope.R` still 11 of 11; the held-out half of the stratum not run.

**Result** (2026-11-11; all on the stratum's 29 development figures, in the container with no network)
- Capture, `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev tree` at `d73bde9` (run `2026-11-11-2052`): 28 of 29 captured; tree-041 stops with `internal error: Huge input lookup` (embedded images). Count-mismatch leaves in 6 of 28 figures, none a panel grid line. Unowned: the background only, 28 of 28. Median 0.34 s, slowest 4.8 s. The bench's comparator gave no verdict on five figures, all from book chapters.
- That was a defect of the bench (Scope change below), fixed in `a578985`. The same command at `a578985` (run `2026-11-11-2110`, made after looking at the first): 27 `equal`, tree-054 `not_deterministic`, gloss's own verdict identical on all 28; the 23 figures with a verdict in both runs equal in every column but the seconds. v0's development run again at `a578985` (run `2026-11-11-2104`): all 38 columns besides the seconds equal run `1339` on all 55 figures.
- Predictions 53-57: 53, 54, 56, 57 right; 55 not scorable on the first run, right on the second.
- Binding, `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bind.R dev tree` at `0cc6e72` (run `2026-11-11-2118`): 28 bound, no bind error. Of 24915 layer elements: verified 9662, ambiguous 322 (40.1%), failed 212, unbound 308, in count-mismatch leaves 14411. Per figure (27 ggplot): all checked in 15, at least 80% in 18, none in 3. Branches: 5216 of 5216 `line` elements of segment geoms verified or ambiguous.
- Predictions 58-62: 58, 59, 60, 62 right; 61 wrong (169 of 212 failed elements in the five figures named, 80% against 90%).
- What holds binding back, by figures of the 28: text drawn as glyph paths in the 5 book figures (`emojifont` turns `showtext` on; 1721 elements in count-mismatch leaves, 37 failed); labels justified outside 0..1 in 3 (128 failed, rightly paired); polar coordinates in 3 (241 unbound); one leaf of points in eight shapes (12690 elements, count mismatch); rotated labels in 1 (34 unbound). tree-045's 6 failed elements are not explained.
- `Rscript bench/R/check-scope.R`: 11 of 11. `Rscript bench/R/check-runner.R`: OK on the host; OK in the container with 1 skipped (the install check needs the network). The 28 held-out figures of the stratum: not run.
- gloss unchanged: no file under `R/` or `tests/` differs from the session's start.

---

### Task 6: Records

**Status:** `[x]` (2026-11-11: README, design notes (§评测设计, §风险与未决问题, §与上一版的区别), dev log and closing notes; `quarto render dev_docs/design.qmd --to html` exit 0)

- `bench/README.md`: v1, the stratum's row in *Sources*, seed and allocation, how it is reported.
- Design §评测设计: a dated note under the paragraph on the population (the stratum, added after looking at v0's held-out capture run; reported apart).
- Dev log; closing notes.

---

## Scope changes

_(append-only; never edit completed tasks above)_

- 2026-11-11 — **The figure test is kept as fixed, with what it loses said.** **Evidence:** Task 3's table: one help topic draws its tree through `ggplot()` and three vignettes draw only `aplot` compositions; all four are "no figure" outcomes. **Effect:** none on the split, which is made on the 57 figures the test fixed before the run retained. Widening the test now (a ggplot whose data is a tree; an `aplot` whose plots hold a `ggtree`) would be a change made after looking at outcomes; it is the owner's to decide, as a later round over the same 83 PSUs, reported as such. aplot is also a kind of object gloss has no engine for yet, which is its own finding.
- 2026-11-11 — **The owner settles decisions 1 and 2: the frame is (b), help topics, the 27 packages and the chapters of the ggtree book; every available PSU is taken.** **Evidence:** the owner's answers, asked before anything was drawn; the book's source at `1af8f25` (2022-07-13): `_bookdown.yml` builds 19 files, 16 of them chapters with evaluated R code; its online version is CC BY-NC-SA 4.0 (`index.Rmd`). **Effect:** the frame is 85 PSUs, 84 in scope, 83 available (Task 1's result above is the frame before the book: 69). A chapter is one PSU, so the book gives at most 16 figures, one per chapter by seed, as every PSU does. Task 3 gains a new kind of source: a chapter's chunks that knitr evaluates, run alone after the book's shared setup (`setup.R` with `p_load(x)` read as `require(x)`, since the harness installs; `conflicted.R` and `software-link.R` inlined), in the `bioc` environment, with files the chapter reads from the repository vendored like URL data. A chapter that needs an earlier chapter's objects ends as a code error and is counted. Assumption 2 is restated for the book, whose figures are often several trees side by side: a figure counts when its object is a `ggtree` or a patchwork that holds one; cowplot and aplot compositions cannot be told by class and are counted in Task 3's table of what every PSU drew. The frozen code of a chapter is redistributed under the book's license, named in `bench/figures/SOURCES.md`; the allocation of "all 67" is read as all of the widened frame (Claude's reading of the two answers together).
- 2026-11-11 — **A run names its stratum; the scripts selected by set alone.** **Evidence:** after the split, `Rscript bench/R/score-capture.R bench/runs/2026-11-11-0858-capture-dev.csv` stopped with "the run does not cover the development set: 55 of 84 figures" (and "54 of 82" for the held-out run): `capture.R`, `bind.R`, `score-capture.R` and `label-sheet.R` took every row of `split.csv` with the set asked for, so the next `dev` run would have pooled 29 tree figures into v0's 55, against the rule this plan and the README state. Nothing was run in that state. **Effect:** `set_figures()`, `run_scope()` and `file_scope()` in `bench/R/common.R`; a set is v0's, the stratum is run by its name after the set (`capture.R dev tree`, `<stamp>-capture-dev-tree.csv`). `Rscript bench/R/check-scope.R`, written first: failed on its first check, then 11 of 11 OK. Three archived runs of v0 (`0858-capture-dev`, `0837-capture-heldout`, `0843-capture-heldout-engine-route`) scored again: 0 lines differ from their archived score files. Task 5 runs `capture.R dev tree`.
- 2026-11-11 — **The bench's worker looked its names up on the search path the figure's code builds.** **Evidence:** run `2026-11-11-2052`: no verdict of the bench on tree-014, -046, -054, -061 and -062, all from book chapters, while gloss's own verdict was recorded for each. In the container, tree-062's frozen code followed by the bench's `compare_pages()` on two plain drawings: `[conflicted] setdiff found in 3 packages` (dplyr, Biostrings, base). callr gives a shipped function the global environment, and the book's setup attaches `conflicted`. **Effect:** `launch_worker()` in `bench/R/runner.R` closes the worker and the functions shipped with it over base; `check-runner.R` gains a figure whose code attaches functions that stop in front of eight base names (no verdict before the fix, `equal` after) and a check that every bare name of the worker is base's. The capture run was made again (`2110`) and is reported as made after looking; v0's development run again (`2104`) equals run `1339` in every column but the seconds. `check-runner.R` ended with status 0 when it failed; it now ends with 1, which showed that its install check cannot run with no network: reported as skipped there, with the reason (`04ff4f7`).

## Closing notes

Closed 2026-11-11. Closing dev log: [2026-11-11-m1-plan.md](../../dev_logs/2026-11-11-m1-plan.md), the sections on the tree stratum.

**End state against starting state**

| | Start (2026-11-11) | End |
|---|---|---|
| Suite | 9 files / 88 tests / 544 expectations / 0 failed / 0 skipped | 9 files / 88 tests / 544 expectations / 0 failed / 0 skipped (nothing under `R/` or `tests/` touched) |
| Bench | v0: 160 PSUs, 109 figures, 55 development / 54 held-out; 1 tree figure, held-out | v1: v0 unchanged, and a tree stratum of 83 PSUs, 57 figures, 29 development / 28 held-out, reported apart |
| gloss on tree figures | never measured | development half: 28 of 29 captured, 27 `equal` and 1 `not_deterministic`; 40.1% of layer elements checked, every layer element in 15 of 27 ggplot figures. Held-out half not run |

**Done when**, line by line: an outcome row for each of the 83 PSUs (met); every retained figure reran with no network and came back holding its tree, 57 of 57 (met; the test is "a `ggtree` or a patchwork holding one", widened from the header's "class `ggtree`" before the harvest, Task 3); split by seed before any capture run, `split.csv` and `MANIFEST.md5` with added rows only (met; five manifest lines replaced, the files that grew); the README states v1 (met); predictions committed before the first capture run (met, `d73bde9`, and before the binding run, `0cc6e72`).

**Assumptions**

1. *Enough of the frame gives a tree figure:* confirmed. 57 of 83, against a floor of 16.
2. *A tree figure can be told by code:* partly. The test misses a tree drawn through `ggplot()` (1 PSU) and `aplot` compositions (3 PSUs); kept as fixed, with the loss stated.
3. *The harvester runs these PSUs without change:* refuted in two ways. A book chapter needed a script reader of its own (known when the owner chose the frame). And the bench's worker was not isolated from the code it runs: the book's `conflicted` stopped the bench's comparator, found only at the first capture run.
4. *v0's draws do not move:* confirmed for `sample.csv` (160 rows byte-identical), `split.csv` (v0's rows unchanged) and v0's development capture run (equal to run `1339` after the worker fix).

**What moved in the design:** §评测设计 (the stratum and how it is reported), §风险与未决问题 (a new item: where binding falls short on tree figures, six classes), §与上一版的区别 (two entries). No ADR: nothing expensive to reverse was decided here.

**For the next plan on the stratum** (on its development half only; each a gloss change, none made here):

- tree-041: gloss stops with an internal error where it must capture or refuse with a reason. A test that fails first (a page with a large embedded image).
- The text rule and justification outside 0..1: 128 rightly paired labels failed in 3 figures.
- Polar coordinates: 3 of 28 figures bind nothing. Circular and fan layouts are common in tree figures.
- Text drawn as glyph paths under `showtext`: gloss should at least say that a text leaf holds outlines, not text.
- Points in several shapes, rotated labels, `aplot` compositions: known limits that this stratum meets more often than v0.
- Not for gloss but for the bench: the comparator, like gloss, cannot read tree-041's page (`xml2::read_xml()` without the `HUGE` option).
- The owner's: whether the figure test is widened in a later round; whether the lab labels a batch of tree figures.
