# 2026-11-12 — A pairing checked from the figure alone (agent-path Task 2)

- **Related plan:** [plan/2026-11-12-agent-path.md](../plan/2026-11-12-agent-path.md) (active; Tasks 1 and 2 done; Tasks 3 to 6 open).
- **Related ADRs:** [ADR-0007](../dev_docs/decisions/0007-derived-tables-of-the-substrate.md), [ADR-0009](../dev_docs/decisions/0009-package-behaviour-enters-as-a-checked-proposal.md).
- **Worked on by:** Claude (Fable 5.2). The owner, after [the log of Task 1](2026-11-12-agent-path-task1.md) and its report: "支持，你的判断准确".

`propose` has to validate on a figure read from a bundle, where the engine's state is gone. This session measured, with no model, how far the figure's own tables and panel scales go in reproducing the check made at capture. On ggplot figures with linear panels they reproduce it exactly; under a polar, map or flipped coord, on base polygons and on heatmaps they do not.

## What changed

| Commit | What |
|---|---|
| `29d92e4` | `R/core-alone.R` (`place_rows()`, `recheck_alone()`, `alone_capture()`; internal); `tests/testthat/test-alone.R`; `bench/R/alone.R`, `score-alone.R`, an option in the runner; predictions 108-116; Task 2 written out |
| `d23876d` | `gl_bindings()`: what `row` is for a heatmap, with a test |
| `0c0217d` | the runner's option renamed (it was shadowed and never ran) |
| `3dd0f57` | the two runs, archived unscored |
| this commit | the score files; predictions 108-116 scored; Task 2's result and a Scope change; this log |

## Measured

- **Suite,** `NOT_CRAN=true Rscript -e "devtools::test()"`: host 10 files / 119 tests / 885 expectations / 0 failed / 0 skipped before; 11 / 125 / 917 at `29d92e4`, and the bench container the same with 0 errors and 0 warnings; host 11 / 126 / 922 at `d23876d` (one more test; under `R/` only a roxygen comment changed, so the container was not run again).
- **The runs** (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/alone.R dev` and `... dev tree`, at `0c0217d`; 54 of 55 and 29 of 29 figures rechecked). Of the elements the engine's positions verify, verified from the figure alone, with the figures in which every checked leaf has the same counts:
  - v0, ggplot: 9053 of 9069 (99.8%); 23 of 26 figures. Ambiguous 15328 of 15328.
  - tree, ggplot: 13843 of 14112 (98.1%); 23 of 28 figures. Ambiguous 8901 of 8907.
  - patchwork: 98 of 98 and 100 of 100; 3 of 3 and 1 of 1 figures.
  - v0, base: 2131 of 2544 (83.8%); 4 of 9 figures.
  - v0, heatmap: 0 of 250 cells; 0 of 3 figures.
- **No leaf passes more elements from the figure alone** than with the engine's positions, on either set.
- **Gap between the two placements** where they agree: 0.0000 pt, except 101 base path leaves (up to 0.49 pt).
- **Rows shifted by one,** where one element draws one row: 1 of about 21700 moved elements still passes on v0, 13 of about 22500 on the tree set, the same from the figure alone as with the engine's positions.
- **Time of the recheck,** its own capture included: median 0.44 s on v0, 0.48 s on the tree set; 222.7 s on gallery-029.
- **Predictions 108-116:** 8 right of 9 (`bench/predictions.md`).
- **Not run:** any held-out figure; a model; `place_rows()` on a figure read back from a bundle. By its code it reads only the tables and the panels, which the suite shows a bundle restores identically; the recheck itself needs the engine's claims and so runs at capture.

## Surprises

- **Two runs measured nothing and said "rechecked".** The worker already had a local `alone`; my new argument of the same name was overwritten, the block was skipped, and every figure came back with NA counts under a status that read as success. I noticed because no leaf table had been written. → `0c0217d`: the option renamed, and the script now reports "recheck did not run" for a captured figure without a leaf table. The empty archives are not kept; predictions untouched.
- **`gl_bindings()`'s documentation was wrong for heatmaps,** and I had written it hours earlier. The binding's row is a cell of the matrix counted column by column; the table has one row per matrix row. Found because the figure alone answered "the rows are not all in the table". → `d23876d` (documentation and a test). A binding that names the row and the column apart → M1 plan Task 7, where the data tree is.
- **The tree set did not fall where I expected.** I predicted 50% to 90%; it is 98.1%. Three polar figures and one flipped hold 263 of 23019 checked elements. An element share again says what three large figures do. → reported by figure beside it; plan, Scope change (d): the circular trees are the case to watch.
- **Under `coord_flip()` the figure alone is not silent: it is wrong on the safe side.** The panel's horizontal range is the plot's y, and nothing in the figure says so, so rows land thousands of pt off and a right pairing fails. Nothing wrong is accepted, but a rejection with a false reason is what `propose` would hand a model. → plan, Scope change (b): closed test-first before `propose` exists.
- **Base polygons and paths are paired with a number the table does not hold.** The engine pairs one element with the mean of its vertices; the rows are the vertices. All 504 such leaves on v0 are affected: 403 differ, and 101 agree only because the first vertex is within 0.5 pt of the mean. Stated as one element per group of vertices, the core's own comparison for a group would read the rows directly. → nowhere yet: a change to the base engine's claims, outside this plan; noted for the M1 plan's Task 5.
- **My mutation was the same claim for an element that draws a group.** Giving every row the next row's place does not change the set of points of an area's polygon. 19 leaves "still passed" and showed nothing. → plan, Scope change (e); `bench/predictions.md` says so beside prediction 115.
- **The recheck took 222.7 s on one figure.** The per-leaf cost of the bind step (ADR-0007, follow-up) four times over. → nowhere new; it is the same defect.

## What's next

- **Task 3,** from the Scope change: first the flipped panel, test-first; then `gl_tools()` and `propose` on `place_rows()` and the binder's comparisons, with aisdk in `Suggests` and contract tests on a scripted model. What aisdk requests when it "tests for internet connectivity" is read before it enters `DESCRIPTION`.
- **Then** Task 4 (condition A's sandbox) and Task 5 (the pilot, on figures where a first answer can be wrong; refusals of `propose` counted against coverage).
- **Waiting on the owner:** pull request 1; the branch `feat/agent-path` is not pushed (10 commits).

## Later the same session: the flipped panel (Task 3, step 1)

Added after the log above was committed; nothing above is changed.

- **What changed:** `b48c373` (panels say whether they are flipped; `place_rows()` goes through a flipped panel and refuses one that does not say; `bench/R/compare-alone.R`; predictions 117-119), `3a6dad0` (the reruns, archived unscored), and this commit (their scores, the predictions scored, Task 3 written out with step 1's result, a note in the M1 plan).
- **Measured:** suite, host 11 files / 126 tests / 922 expectations before, 11 / 128 / 933 / 0 failed / 0 skipped after; the bench container 11 / 128 / 933 / 0 failed / 0 errors. Reruns `2026-11-12-1737-alone-dev` and `-1748-alone-dev-tree` against `-1711` and `-1722` (`Rscript bench/R/compare-alone.R`): exactly two figures change, bioc-016 (10 bars) and tree-045 (22 elements), from failed to verified from the figure alone; no count under the engine's positions changes. v0 ggplot 9063 of 9069 (24 of 26 figures agree), tree ggplot 13865 of 14112 (24 of 28). Predictions 117-119: 3 right of 3. Not run: `R CMD check`.
- **What aisdk's internet probe does** (read from its code and curl's, not run under a monitor): before a streamed request it calls `curl::has_internet()`, which looks up `dns.google.com` and `time.cloudflare.com` and, when a proxy variable is set, fetches `http://captive.apple.com/hotspot-detect.html` through it. It sends nothing of ours, goes on when the probe fails (its default mode warns), and is switched off by `options(aisdk.skip_internet_check = TRUE)`. → plan, Task 3 step 3: off for runs against the local gateway.

### Surprises

- **Another session committed on this branch during a run.** While the tree rerun was going, `34f13b0` appeared: a status audit by another agent, at the owner's request, one new dev log and no code. The run recorded a different commit at its end than at its start. The source digest both reruns loaded is the same, so the run stands, and the archive's commit says what happened. → nowhere in the code; raised with the owner, since two sessions committing to one branch can also collide on files.
- **The audit found a leaf that is "verified" with no verified element,** on a held-out figure (tree-070, L022). I confirmed it from the archive: the only such leaf in three bind runs. A check that returns no result per element passes, because `all()` of nothing is true. I wrote that check. → M1 plan, Scope change of 2026-11-12: a defect, to be fixed test-first on a hand-built figure and reported as made after looking at the held-out run.
- **`chartr()` on a column name.** Swapping x and y that way turned `xmax` into `ymay`; the flipped scatter passed and the flipped bars did not. The bars were in the test because the bench figure that failed was a bar chart. → fixed before the commit; nowhere else.

### What's next

Task 3, step 2: `gl_propose()` with no model, tests first, including a figure read back from a bundle. Then the tools, then Task 1's harness through them.
