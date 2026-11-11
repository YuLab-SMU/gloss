# Page capture: grid pages, then base pages

> Status: active.
> Date opened: 2026-11-11. Owner: Yonghe Xia.

**Goal:** `gloss()` captures the page its input draws ([ADR-0006](../dev_docs/decisions/0006-capture-the-page-the-figure-draws.md)), and on the 55 development figures the package, not the spike, gives 53 equal to the page drawn, 1 reported as not deterministic, 1 refused with a reason, and no figure that differs without gloss saying so.

**Why now:** The development set showed that every capture difference has one cause: gloss draws a grob the figure's code did not build ([dev log 2026-11-10](../dev_logs/2026-11-10-page-capture-spike.md), [idea note](../idea/2026-11-10-page-capture.md)). The owner chose page capture on 2026-11-11. M1 binds elements to data and must not start on captures that can be another figure.

**Starting state (measured):**
- Suite at `aef42f2`, 2026-11-11: 7 files, 49 tests, 298 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`).
- Engine route on the development set (`1b22fe1`, run `2026-11-10-1424`, `bench/R/capture.R dev` in the container): 51 captured, 3 refused, 1 error; 40 equal, 6 known exceptions, 5 different; base figures equal 1 of 10.
- Spike of the page route on the same figures (run `2026-11-10-1731`, spike code outside `R/`, made after looking): 54 captured, 53 equal, 1 different (gallery-059, not deterministic), 1 empty page (gallery-053); 44 grid pages, 10 base, 0 mixed.
- Time today: 0.11 / 0.40 / 4.1 s at 10^3 / 10^4 / 10^5 points; spike 0.10 / 0.44 / 3.5 s, and the comparison adds 0.02 / 0.28 / 2.5 s (`s4-unknowns.R`, host).
- Nothing of the page route is in `R/`.

**Assumptions to test (riskiest first):**
1. *The engines' tables and panels still describe the page when `print(x)` draws it.* Today the engine draws from its own build, so tables and page share one build. With `print(x)` they are two builds: they differ when the build draws random numbers (jitter), and for a print method that draws something else (ggbreak). Tested in Task 2. If a second build cannot be shown to equal the drawn one, the ggplot engine keeps its own drawing step where the print method is ggplot2's and withholds tables elsewhere; ADR-0006 point 4 allows both.
2. *Wrapping in place gives the package what the engine-built tree gave it.* The spike showed identical element tables on five inputs. Dense leaves were not tested: rasterising needs to redraw one leaf alone, and today that uses the wrapped tree, which no longer exists as one object. Tested in Tasks 1 and 3. If one leaf cannot be redrawn alone from the display list, dense leaves need another mechanism and Task 3 is replanned.
3. *The self-check is cheap enough to run on every capture.* Tested in Task 3. If capture with the check takes more than twice today's time at 10^4 or 10^5 points, the check runs only when the cheap comparison (captured page against first drawing) fails, or becomes an option; a scope change records the number.
4. *A recorded page replayed on gloss's device captures like the page drawn there.* The bench recovers figures the code draws without returning an object as a recorded plot. Tested in Task 4. If replay differs, the bench runs the frozen code inside `gloss(function)` instead.
5. *A display-list entry is a usable leaf for base figures.* Names, expected counts, panels from `par()`, and the scene's leaf marks when one entry's primitives span several clip groups. Tested in Task 5. If entries are too coarse (one `plot()` call drawing points, axes and box in one entry), the split inside an entry needs its own rule, and the design's base classification is rewritten from the measurement.
6. *The base route passes `R CMD check --as-cran`* although it reads a recorded plot's structure and calls its entries. Tested in Task 6. If it does not, the base route moves behind a documented boundary or stays out of the CRAN build; the owner decides.

**Architecture:** The core (`R/core-substrate.R`) gains the page: open svglite, let the input draw, read the display list's kind, capture by the grid route or the base route, compare with the page drawn. `capture_scene()` and the engines' `grob()` go; `wrap_leaves()`, the probe and `build_substrate()` stay. Engines keep `prepare`, `tables`, `panels`, `describe`, `example`, with an optional drawing step. The bench's runner hands gloss the object or the recorded page and compares with clip regions. Not touched: the substrate's format as read by `identify.R`, the bundle and the projections (if Task 5 shows base leaves need a change there, it is a scope change); the data and context modules; the held-out set.

**Out of scope:** masks and leaves with their own group (refused as today); pages mixing base and grid (refused; 0 of 55); making a random figure reproducible; base data binding from the plot call's arguments (M1 or later, noted in Task 5 if seen); classification rules beyond re-measuring the base names; any run on the held-out set before Task 8.

**Tech stack:** R 4.5.2, grid (`grid.force()`, `grid.DLapply()`, `grid.refresh()`), grDevices (`recordPlot()`, `replayPlot()`), svglite >= 2.2, xml2; the bench container of bench v0.

**Done when:**
- Fixtures: the six capture inputs keep their element tables (rows, tags, boxes, leaf membership; leaf names may differ only in grid's automatic numbering) and their clip regions; the 10^5-point bundle stays under 3 MB.
- Development set, package code, container, after Task 4 (grid step): the 44 grid pages are 43 equal and 1 not deterministic, 0 errors; gallery-053 is refused with a reason; base figures unchanged from the starting state.
- Development set after Task 6 (base step): 53 equal, 1 not deterministic, 1 refused, 0 errors, 0 different.
- On every development figure, gloss's own verdict agrees with the bench's comparison (55 of 55). A figure the bench finds different and gloss calls equal is a failed invariant and blocks the plan.
- Time with the self-check on: at most twice today's at 10^4 and 10^5 points, or the scope change of assumption 3.
- Each number is from a run archived in `bench/runs/` and labelled as made after looking.

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
- Suite: 7 files, 65 tests, 420 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-11, after Task 5).
- Key numbers: development run `2026-11-11-0627` (page route for grid pages, base still through gridGraphics): 54 captured, 1 refused; grid pages 42 equal, 2 not deterministic, 0 different; base 1 equal, 5 known exceptions, 4 different; gloss's verdict and the bench's agree on 44 of 44 grid pages under the Task 4 reading.
- Development run `2026-11-11-0705` (page route, base by entry): 52 equal, 2 not deterministic, 1 refused, 0 different, 0 errors; base 10 of 10 equal; gloss and the bench agree on 54 of 54 captured figures (Task 4 reading). `R CMD check --as-cran`: 2 NOTEs, both from the setting.

**Overall progress**
- [x] Task 1: Grid pages in the core: draw, wrap in place, self-check
- [x] Task 2: Engines on the page: tables and panels that describe what was drawn
- [x] Task 3: Dense leaves, size and time
- [x] Task 4: Bench on the page route; development run of the grid step
- [x] Task 5: Base pages by display-list entry
- [x] Task 6: Base on the development set; names and classification re-measured; gridGraphics out; `R CMD check`
- [x] Task 7: Records: design §元素归属 rewritten, NEWS, dev logs
- [x] Task 8: Held-out predictions and run (owner's go-ahead 2026-11-11)

---

### Task 1: Grid pages in the core

**Status:** `[x]`

**Tests assumption:** 2 (wrapping in place), first half.

**Files**
- Modify: `R/core-substrate.R` (`gl_capture()`, `capture_scene()` replaced, `check_print_dispatch()` removed), `R/core-plugin.R` (engine contract), `R/engine-*.R` (drop `grob`)
- Test: `tests/testthat/test-capture.R`, `test-plugin.R`, `helper-figures.R`

**Intent**
- Put the spike's grid route (`dev_docs/research/capture-fidelity/page-capture.R`: `page_kind()`, `capture_grid_page()`, `scalar_names()`, `clip_signatures()`) into the core, with the self-check and the refusals of ADR-0006. Closes the silent wrong figure (ggbreak) and the over-refusal (ggExtra).

**Checklist**
- [x] Failing tests first: an object whose print method draws something other than its built grob is captured as what print draws (a synthetic ggplot subclass, and `ggExtra::ggMarginal()`); a grob with a vector name is captured; a function that draws with grid is captured; a function that draws nothing is refused with a reason
- [x] Draw by `print()`/`show()`, a call, or `replayPlot()` on gloss's svglite; read the page kind; mixed and empty pages abort with the reason
- [x] Wrap the display list in place and redraw; keep the first drawing as the reference
- [x] Self-check with primitives and clip regions; three verdicts (equal, not deterministic, capture changed the figure: abort); the verdict stored in the figure's meta and shown by `print()`
- [x] Several pages: the last is captured, the count is stored and warned
- [x] Engine contract: `grob` not required; optional drawing step; contract test that an engine's page equals `print(x)` on its example
- [x] Before the first change in `R/`: tag the last commit of the engine route (`engine-route-final`), the baseline of Task 8
- [x] The test "a figure that prints through its own method is refused" (two expectations of the error "custom print method") is replaced by the capture tests above. This is a change of intended behaviour by ADR-0006 point 5, recorded here, not a loosened test
- [x] Base figures stay on gridGraphics in this task, through the engine's own drawing step

**Verification**
- `NOT_CRAN=true Rscript -e "devtools::test()"`: the new tests fail before and pass after; the six inputs' regression (identical to plain svglite, clip regions) passes unchanged; element counts 134, 186, 293, 115, 10040 on the five grid inputs as in `s5-drop-in.out`.
- Would change the plan: an input whose element table changes beyond leaf names; a self-check that fails on a deterministic fixture.

**Result** (2026-11-11)
- Tag `engine-route-final` on `f48c124`.
- Tests first: 7 new or replaced tests in `test-capture.R`, 2 in `test-plugin.R`. Before the change: 56 tests, 304 expectations, 10 tests failing (7 failed expectations, 9 errors). After: `NOT_CRAN=true Rscript -e "devtools::test()"` 7 files, 56 tests, 338 expectations, 0 failed, 0 skipped.
- Fixtures (`dev_docs/research/capture-fidelity/p1-fixtures-vs-engine-route.R`, host, the tag in a worktree): the six inputs' element tables are identical to the engine route's (134, 186, 60, 293, 115, 10040 rows), panels, tables and clip regions identical, verdict `equal` on all six. Leaf tables: same rows; `name` and `path` differ only in grid's automatic numbering, except the heatmap's `path`, which lost the `GRID.gTree.N/` root that `grid.grabExpr()` added (16 of 16 leaves). Nothing in `R/` reads `path`; the tests match it with `grepl()`.
- Decisions settled here (ADR-0006 left them to the plan): the engine fields are `page` (`"grid"`, default, or `"base"`) and `draw(state)`, which returns the state; the verdict is `meta$page$verdict` (`equal`, `not_deterministic`), with `kind`, `drawn_by`, `pages`, `differ`, `primitives`, `renamed`. A grob is drawn with `grid.draw()`, because `print()` of a grob prints its description. The plain redraw of the self-check draws the forced display list that was wrapped, so the first comparison needs no restored random state and gloss writes no `.Random.seed`; it runs only when the captured page differs from the page drawn. A second plain redraw tells a figure random at draw time from a capture that changed it.
- Dense leaves are rasterised from the wrapped display list (needed here for the existing dense tests to pass); Task 3 still compares the rasters with today's.
- Not as expected: the base engine's drawing step (gridGraphics) passes the new contract check on its `example()`. gridGraphics draws a function on its own device, where the background is transparent; the same plot recorded on svglite differs by 1 primitive (the background rect), and `rect(border = 0)` by 2. A contract check on one example cannot see gridGraphics' differences; Task 5 removes them.
- Time, not yet against the limit: `points_1e4` 0.29 s on the engine route, 0.96 s here; the two signature passes of the self-check take 0.40 s of it. Assumption 3 is tested in Task 3.

---

### Task 2: Engines on the page

**Status:** `[x]`

**Tests assumption:** 1.

**Files**
- Modify: `R/engine-ggplot.R`, `R/engine-patchwork.R`, `R/engine-heatmap.R`, `R/engine-grid.R`
- Test: `tests/testthat/test-capture.R`, `test-identify.R`, `test-data.R`

**Intent**
- Tables and panels are statements about the page. Show that they hold, or withhold them.

**Checklist**
- [x] Measure first, before changing engines: a ggplot with `position_jitter()` and no seed; drawn point positions against the built table mapped through the panel scales. Record how many points agree when the engine builds separately, and when it builds from the random state `print()` started with
- [x] Measure on the two development figures with their own print methods (exts-018 ggbreak, gallery-052 ggExtra) what the ggplot engine's `tables()` and `panels()` return against the page: leaves found, panels matched, counts
- [x] From the two measurements choose the rule (rebuild from the saved random state; or the engine's own drawing step where the print method is ggplot2's) and write it as a scope change with the numbers
- [x] Where the engine's panels or tables cannot be matched to the page, withhold them with a reason in the substrate's status; test with the synthetic subclass
- [x] ComplexHeatmap: draw on the page directly, keep the drawn list for tables; no `grid.grabExpr()`

**Verification**
- Tests: jittered points agree with the table for every row (a tolerance of the SVG's printed precision, stated in the test); the subclass fixture has no tables and a reason; heatmap and patchwork tables equal today's on the fixtures.
- Would change the plan: no rule makes the jittered table agree. Then tables of a randomly built plot are withheld, and M1 binding on such figures is a recorded limit.

**Result** (2026-11-11)
- Measured before changing engines (package at `19f39d7`): jitter without a seed, 32 rows, 5 runs: separate build 0, 0, 0, 0, 0 of 32 rows on their point; build from the random state `print()` starts with 32 of 32 in 5 of 5; the engine drawing its own build 32 of 32 in 5 of 5, and its page identical to `print()`'s from the same seed (0 primitives differ) (`p2-jitter-tables.R`, host).
- exts-018 (ggbreak, container, `p2-own-print.out`): `print.ggcut` draws 3 sub-panels of 20 bars each, every leaf `ok` (20 = 20), against a build with 1 panel and 20 rows; `panels()` returned nothing without a reason (4 panel viewports, 1 layout row), and `built_layer1` was offered with 20 rows on the uncut scale, which M1 would have bound by count. gallery-052 (ggExtra) is a gtable: grid engine, no tables or panels, verdict `equal`.
- Rule: see the scope change below. After it, exts-018 keeps `raw` (20 rows) and lists `built_layer1` and `panels` as withheld with the reason (`p2-own-print-t2.out`).
- Tests first: 4 new tests (jitter rows in `test-identify.R`, withheld for the subclass in `test-capture.R`, a random patchwork plot in `test-data.R`, withheld reasons through a bundle in `test-bundle.R`); before the change 59 tests, 354 expectations, 4 tests failing (the jitter test: 0 of 32 rows in each of 3 runs). After: `NOT_CRAN=true Rscript -e "devtools::test()"` 7 files, 59 tests, 363 expectations, 0 failed, 0 skipped.
- Fixtures after the rule (`p1-fixtures-vs-engine-route.R`): heatmap and patchwork tables identical to the engine route's, as are the other four inputs' tables; verdict `equal` on all six.
- ComplexHeatmap draws on the page and keeps the drawn list (done in Task 1; no `grid.grabExpr()`).
- `ggplot_panels()` now withholds with a reason when the page's panel viewports and the built layout disagree in number (it returned `NULL` silently).

---

### Task 3: Dense leaves, size and time

**Status:** `[x]`

**Tests assumption:** 2 (second half) and 3.

**Files**
- Modify: `R/core-substrate.R` (`rasterize_leaves()`, `keep_only_leaf()`)
- Test: `tests/testthat/test-capture.R` (dense), `test-bundle.R` (size)

**Checklist**
- [x] Redraw one leaf alone from the display list on the PNG device; compare its raster with today's on `points_1e4` (pixel for pixel) and its index (same points)
- [x] The 10^5-point slow test: bundle under 3 MB, as today
- [x] Time at 10^3, 10^4, 10^5 points, capture and self-check apart, five runs each, median and range, against `aef42f2`
- [x] If the check exceeds the limit of assumption 3, apply the scope change described there

**Verification**
- `NOT_CRAN=true Rscript -e "devtools::test()"` with the slow test; a timing script kept under `dev_docs/research/capture-fidelity/` with its output.
- Would change the plan: a raster that differs from today's; a bundle over 3 MB.

**Result** (2026-11-11)
- `Rscript dev_docs/research/capture-fidelity/p3-time.R /tmp/gloss-engine-route` (host; the tag `engine-route-final` in a worktree, each route in its own R process), output in `p3-time.out`:
  - points_1e4, default `dense`: the dense leaf redrawn alone from the wrapped display list gives a raster identical to the engine route's, byte for byte and pixel for pixel (1008 x 720 px, 0 pixels differ); its index, 10000 elements, identical apart from the leaf id.
  - 10^5 points, HTML bundle: 2.65 MB on both routes (limit 3 MB). The slow test passes in the full suite with `NOT_CRAN=true`.
  - Time of `gloss()`, five runs, median [min, max]: 10^3 points 0.08 [0.08, 0.09] s against 0.12 [0.11, 0.14] s (1.52x); 10^4 0.29 [0.28, 0.53] against 0.47 [0.46, 0.62] (1.62x); 10^5 3.11 [3.05, 3.32] against 4.08 [4.05, 4.50] (1.31x). Self-check alone: 0.01, 0.05, 0.55 s. Within the limit of assumption 3 (2x at 10^4 and 10^5); the check runs on every capture, no scope change.
- To get there, `page_signature()` reads each top-level child of svglite's page once and its primitives with one regular expression; children with a nested clip group, defs, a pattern or a mask are read node by node through XPath, as before. Per-node reading cost 2.5 s per page at 10^5 points (0.40 s of the 0.96 s at 10^4 after Task 1). A test checks that both reads agree on six kinds of page (clip window, clipping path, pattern fill, escaped text, faceted ggplot) and that a lost clip changes the signature; on the six fixtures both reads agree on the page drawn and the page captured.
- Suite: 7 files, 60 tests, 374 expectations, 0 failed, 0 skipped.

---

### Task 4: Bench on the page route; development run of the grid step

**Status:** `[x]`

**Tests assumption:** 4.

**Files**
- Modify: `bench/R/runner.R` (recovery, comparison), `capture.R`, `score-capture.R`, `check-runner.R`

**Checklist**
- [x] Comparison with clip regions; `check-runner.R` gains a case that loses a clip with every primitive unchanged and must be `different`
- [x] A verdict `not_deterministic`, proved by the bench itself (two plain drawings of the figure differ), never assumed from the package
- [x] Recovery: an object stays an object; a page the code drew is handed over as a recorded plot, not through `grid.grab()`. Check on fixtures that the replayed page captures like the page drawn in place
- [x] The reference for an object is the page that object draws alone; the page the frozen code left is reported beside it (39 of 42 objects equal it in the spike)
- [x] Record gloss's own verdict per figure and its agreement with the bench's
- [x] `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev`, archived, labelled as made after looking

**Verification**
- `Rscript bench/R/check-runner.R`: OK, with the new cases failing before the change.
- Development run: the grid-step line of *Done when*. Would change the plan: any figure different without gloss's verdict saying so; a grid page that errors.

**Result** (2026-11-11)
- Harness (`ebd7e2a`): a drawn page, base or grid, is handed over as `recordPlot()`; an object's reference is the page it draws alone, and the page the code left is compared beside it; the bench's own comparator (primitives and clip regions, no gloss code) decides; `not_deterministic` only when the bench's two plain drawings differ; gloss's verdict, page kind, drawer, page count and withheld items recorded per figure; dense figures judged on a vector recapture (`dense = Inf`) instead of being a known exception.
- `Rscript bench/R/check-runner.R`: FAILED before the change (two drawn grid pages recovered as `gTree`; the random figure `different`; the object sharing a page `different`; dense a known exception; gloss's verdict not recorded; the lost clip not judged), OK after, on the host and in the container. Assumption 4 on fixtures: the two drawn grid pages of the synthetic script (raw grid calls, lattice) replayed by gloss are equal to the page the code drew.
- Development run `2026-11-11-0627` (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev`, commit `ebd7e2a`, made after looking; archived with its log and score in `bench/runs/`): 54 captured, 1 refused, 0 errors.
  - Grid pages, 44: 42 equal, 2 not deterministic (gallery-059: two drawings differ in 5 primitives; heatmap-008: in 236), 0 different, 0 errors.
  - gallery-053 refused: "<gganim> builds into <gganim_built>, not a built ggplot" (the ggplot engine checks the build before an own print method runs; the spike saw an empty page).
  - Base pages, 10, still through gridGraphics: 1 equal, 5 known exceptions (one background rect), 4 different (gallery-008, -013, -038, bioc-004), as in the starting state.
  - Against the engine route (`2026-11-10-1424`): exts-018 (ggbreak) and gallery-056 (treemap) now equal; exts-022 (dense) equal on the vector page instead of a known exception.
  - gloss's verdict against the bench's, grid pages: 43 of 44 agree; 0 figures the bench finds different while gloss says equal. The one disagreement is heatmap-008 (bench `not_deterministic`, gloss `equal`, see the scope change below). Base pages: gloss says equal on 10 (it compares with gridGraphics' page), the bench on 1.
  - Objects: drawn alone, 39 of 41 equal the page the code left (gallery-052 holds two figures, 136 primitives; gallery-059 is random), as in the spike.
  - Withheld: 1 of 54 captured figures (exts-018: `panels`, `built_layer1`).
  - Time per captured figure, median by engine 0.21 to 0.49 s; maximum 25.5 s (ggplot).

---

### Task 5: Base pages by display-list entry

**Status:** `[x]`

**Tests assumption:** 5 (a display-list entry is a usable leaf).

**Files**
- Modify: `R/core-substrate.R` (base route: replay by entry, leaf groups, self-check, dense leaves), `R/engine-base.R` (no gridGraphics; panels from the replay)
- Test: `tests/testthat/test-capture.R`, `test-identify.R`, `helper-figures.R`

**Intent**
- A base page is captured as the base graphics engine draws it, not as gridGraphics redraws it. The leaf is a display-list entry; its elements are the primitives the device wrote during that entry.

**Checklist**
- [x] Failing tests first: the six inputs' base input equals the code's own page on svglite (today it equals gridGraphics' page); `rect(border = 0)` and a plot recorded on svglite are captured equal to their own page (gridGraphics: 2 and 1 primitives differ); a 5000-entry page captures in linear time (s6: 0.31 s)
- [x] Replay in the core, entry by entry, on a file svglite device kept valid (`always_valid = TRUE`), reading the bytes each entry adds; restore the recorded graphics state first by replaying the plot with an empty display list
- [x] Leaf groups: each run of an entry's primitives between two clip changes is wrapped in `<g data-gloss-leaf>`; the parsed scene must hold, per leaf, the count read during the replay (integrity check, abort otherwise)
- [x] Leaves: name from the entry's call (`plotXY`, `text`, `axis`, ...), path `base/<entry>/<name>`, vp `figure-<n>` (n counts `plot.new()`), box and scales from `par("fig", "plt", "usr")` after the entry; expected counts for `plotXY` (type `p` and `l`), `text`, `rect`, `segments`, unknown elsewhere
- [x] Panels from the replay: one per figure, box from `fig` and `plt`, scales from `usr`; a leaf belongs to a panel when its primitives are clipped to that figure's plot region
- [x] Self-check as for grid pages; the plain redraw is `replayPlot()` of the recorded page
- [x] Dense leaves: the entry redrawn alone on the PNG device, the other entries that drew anything skipped
- [x] Base engine: no drawing step, no gridGraphics; a recorded plot carries a note that it is replayed with svglite's text metrics
- [x] Measure on the fixtures, against the engine route: element counts, leaves, panel boxes and scales (s5: within 0.005 pt of the drawn points)

**Verification**
- `NOT_CRAN=true Rscript -e "devtools::test()"`: the new tests fail before and pass after; the base panel test of `test-identify.R` passes from the replay's panels (built data mapped through `usr` lands on the drawn circles within 0.011 pt).
- Would change the plan: an entry whose primitives cannot be told apart from another's on the device (the counts read during the replay disagree with the parsed scene); a fixture whose page differs from the code's.

**Result** (2026-11-11)

- Suite: before Task 5, 7 files / 60 tests / 374 expectations / 0 failed / 0 skipped (a81cbbc). With the new tests and the old code: 64 tests, 403 expectations, 6 tests failing (15 failed expectations, 2 errors). After: 7 files / 65 tests / 420 expectations / 0 failed / 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`). The 65th test came from p5 (below).
- Fixtures (hand-built, so this shows the mechanism, not coverage): `Rscript dev_docs/research/capture-fidelity/p5-base-fixtures.R /tmp/gloss-engine-route` -> `p5-base-fixtures.out`. On the 26 base pages of s2, equal to the code's own page on svglite with clip regions: page route 26 of 26, all with the verdict `equal`; engine route (gridGraphics, tag `engine-route-final`) 14 of 26. Counted leaves 169 of 169 `ok`, 0 `count_mismatch`. Data through each panel's `usr` scales onto the drawn circles: largest gap 0.005 to 0.007 pt (scatter, log axes, `pairs` figure 2, `layout`), under the 0.011 pt of the verification. Time per page 0.00 to 0.54 s.
- Linear reading: 5000 `segments()` calls, `gloss()` 0.79 to 0.98 s (3 runs), 5000 leaves, verdict `equal`.
- Leaf names over the 26 pages: `segments` 91, `axis` 58, `polygon` 52, `plotXY` 48, `box` 47, `text` 24, `title` 18, `rect` 9, `abline` 5, `mtext` 5, others 1 to 3. Task 6 re-measures them on the development set for design §分类.
- Found while measuring (dev log 2026-11-11): text written by plotmath stopped `base_expected()` (an expression is not atomic), and behind it the page was cut at byte offsets with `substr()`, which counts characters, so any multibyte character (plotmath writes alpha as U+03B1; any non-ASCII label) left the split page not well-formed and the capture aborted on the integrity check. Fixed (byte slices; an expression has no expected count); test "base text drawn as plotmath or with multibyte characters is split by entry". The integrity check caught it as designed: no page was captured wrong.
- Two runs of p5 were wrong and are not kept: sourcing s2 ran its `load_all(".")` over the tag, so the engine-route column measured the page route (26 of 26 on both sides, which did not match s0's `rect(border = 0)` result and gave it away); the `pairs` check put disp on the mpg scale (`pairs()` fills by column), a 1383.889 pt gap.
- Would change the plan: neither condition occurred. No entry's primitives were confused with another's (the integrity check held on 26 pages and 5000 entries); no fixture differed from the code's page.

### Task 6: Base on the development set

**Status:** `[x]`

**Tests:** the last two lines of *Done when* (as read after the scope change of 2026-11-11, Task 6, below).

**Files**
- Modify: `bench/R/runner.R` (no known exception; leaf names per figure), `bench/R/capture.R`, `bench/R/score-capture.R`, `bench/R/check-runner.R`; `DESCRIPTION`, `.Rbuildignore`; comments in `R/` and `tests/` that still name gridGraphics.
- Records: `bench/runs/`, `dev_docs/research/capture-fidelity/README.md`.

**Intent**
- Base pages of the development set captured as their code draws them, judged by the bench with no exception; gridGraphics out of the package; the package checked as CRAN would.

**Checklist**
- [x] Bench judges base pages like grid pages: the gridGraphics background-rect exception removed from `fidelity_verdict()`; `check-runner.R` asserts base fidelity (it reported it) and that leaf names are recorded; the score judges agreement on every captured page under the Task 4 reading and tallies base leaf names
- [x] Linux: the bench container is the first Linux run of the base route (see Result)
- [x] Predictions below committed before the run
- [x] Development run (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev`), archived with its log and score
- [x] Base leaf names on the development base figures, from the run; the base figure of design §分类 classified again with rules for call names (the design text is Task 7)
- [x] gridGraphics out of `DESCRIPTION` and the tests; the bench container keeps it (Task 8 runs the tag's engine route there)
- [x] `R CMD build --no-build-vignettes .` and `R CMD check --as-cran`; known hygiene items to look at: `Rplots.pdf` not in `.Rbuildignore`, non-ASCII comments in 4 files of `R/`, `<<-` in M0 code (closures writing their own function's locals)
- [-] Recorded-plot structure: R 4.5.2 is the only version on the host and in the bench image; other versions are not run (installing them is the owner's call)

**Predictions for the development run** (written 2026-11-11 after looking at run `2026-11-11-0627` and the fixtures of Task 5, so they are not blind; development set only)
- 55 figures: 54 captured, 1 refused (gallery-053, "not a static ggplot"), 0 errors, 0 timeouts.
- Grid pages, 44: unchanged from `0627`, 42 equal, 2 not deterministic (gallery-059, heatmap-008).
- Base pages, 10: 10 equal (in `0627`, through gridGraphics: 1 equal, 5 one background rect, 4 different: gallery-008, -013, -038, bioc-004). gloss's own verdict `equal` on all 10.
- Agreement, Task 4 reading: 54 of 54 captured figures; identical verdicts 53 of 54 (heatmap-008); 0 failed invariants.
- Base leaves with a count mismatch: 0 (fixtures: 0 of 169 counted leaves); lower confidence than the lines above, since development figures may draw text or points the expected counts do not foresee.
- Would change the plan: a base page the bench finds different (the replay by entry does not reproduce the code's page); any figure the bench finds different while gloss says equal (failed invariant, blocks the plan).

**Result** (2026-11-11)
- Bench harness: `Rscript bench/R/check-runner.R` FAILED before the change (the one-rect case still `known_exception`; leaf names not recorded) and OK after, on the host and, with the read fix below, in the container. On the old run, the new score prints the Task 4 numbers again (`2026-11-11-0627`: agreement 44 of 44 grid pages, identical verdicts 43 of 44).
- Linux (`254bd73`): the first container check stopped every base capture on the integrity check ("the base page split by entry is not well-formed SVG"). A file connection kept open and seeked again returned bytes from before svglite rewrote its closing tags (2 of 8 entries of `plot(1:10, (1:10)^2)`; 0 on macOS); each read now opens its own connection. Container suite before: `test-capture.R` 5 errors (4 base pages, 1 `Rplots.pdf` in the read-only repository, fixed in `03abb95`); after: 7 files / 65 tests / 420 expectations / 0 failed / 0 errors / 0 skipped, as on the host.
- Development run `2026-11-11-0705` (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev`, commit `9984549`, which holds the predictions; while it ran the working tree differed only in comments, roxygen text and the `DESCRIPTION` Suggests line; archived with log and score in `bench/runs/`, `692c6cc`). Every prediction held:
  - 55 figures: 52 equal, 2 not deterministic (gallery-059: 5 primitives; heatmap-008: 236), 1 refused (gallery-053, "not a static ggplot"), 0 different, 0 errors, 0 timeouts.
  - Base pages 10 of 10 equal, gloss's verdict `equal` on all 10 (`0627`, through gridGraphics: 1 equal, 5 one background rect, 4 different). Count mismatches on base pages: 0 of 10 figures; 1469 leaves with an expected count, all `ok` (`0627`: 85 mismatched leaves on 5 figures). Median time 0.15 s per base figure (`0627`: 0.36 s); gallery-023, 1297 elements, 0.90 s (4.92 s).
  - gloss's verdict and the bench's agree on 54 of 54 captured figures under the Task 4 reading; identical on 53 of 54 (heatmap-008: bench `not_deterministic`, gloss `equal`); 0 failed invariants. The refused figure carries its reason.
  - Unchanged from `0627`: objects drawn alone equal the page the code left in 39 of 41; withheld 1 (exts-018); 54 of 54 with only the device background unowned.
- Base leaf names on the 10 development base figures (from the run's `leaf_names`; name: figures, leaves, elements): `plotXY` 7, 1362, 2018; `path` 2, 483, 483; `axis` 5, 19, 204; `text` 6, 61, 64; `segments` 3, 37, 57; `box` 5, 29, 29; `polygon` 3, 21, 21; `symbols` 2, 8, 17; `rect` 4, 14, 14; `title` 5, 7, 14; `mtext` 1, 2, 2. The base figure of design §分类 (`p6-base-classify.out`): `classify.R`'s rules on call names give 57 of 60 elements right, 2 wrong, 1 unclassified, as through gridGraphics, in 9 leaves instead of 15; `legend()` is not on the display list, only the calls it makes.
- gridGraphics: out of `DESCRIPTION` and the `gloss()` documentation (`c20e98b`); no test or code path used it after Task 5 (only comments named it). The bench container keeps it for Task 8.
- `R CMD build --no-build-vignettes` and `R CMD check --as-cran --no-manual` on a clean export of the commit (R 4.5.2, macOS; `_R_CHECK_CRAN_INCOMING_REMOTE_=false`, because CRAN did not answer from here within 60 s): first 1 WARNING (ggExtra used by the tests, not declared), 2 NOTEs; after declaring ggExtra (`84abf35`) 2 NOTEs, both from the setting (development version number; "unable to verify current time"). "R code for possible problems", non-ASCII, left-over files: OK. Assumption 6 holds on this platform: reading the recorded plot and calling its entries draws no check finding. Not run: the check on Linux (the container suite passes, 65 / 420 / 0), Windows, R-devel.
- Recorded-plot structure on other R versions: not run (`[-]`). R 4.5.2 is the only version on the host and in the bench image, and installing others is the owner's call. What a changed structure would do: an entry that is not a function and its arguments stops with "Replaying display-list entry k ... failed", and a page replayed differently fails the self-check; neither degrades silently. `replayPlot()` itself warns on a plot recorded by another R version.

### Task 7: Records

**Status:** `[x]`

**Files:** `dev_docs/design.qmd`, `dev_docs/figures/design/src/fig-capture.svg` and its PNG, `NEWS.md`, `dev_logs/2026-11-11-page-capture-execution.md`, `dev_docs/research/capture-fidelity/` (p7).

**Checklist**
- [x] Design §元素归属 rewritten for the page route (not only dated notes): input draws its own page; grid pages wrapped in place; base pages by display-list entry; self-check and what `equal` certifies; withheld tables and panels; @tbl-capture measured again on the test inputs (p7); development-set result
- [x] Dated notes: §分类 (base call names), §评测设计 (verdicts and the 52 / 2 reading), §风险与未决问题 (two items resolved; a new one on reading device files and recorded-plot formats), §已定事项, §与上一版的区别; abstract, overview and premortem lines
- [x] `fig-capture`: the line "vp lifted, or gridGraphics cannot find the viewport" replaced; PNG re-rendered with the command of `src/README.md`
- [x] NEWS: `equal` and what it certifies; gridGraphics gone; the development-set numbers
- [x] Dev log of the session
- [-] Plan to `plan/done/`: not yet. Task 8 belongs to this plan and waits for the owner's go-ahead; the plan closes when Task 8 runs or the owner cancels it.

**Result** (2026-11-11)
- `quarto render dev_docs/design.qmd --to html`: exit 0, 0 warnings; every cross-reference resolves (`aaec8e4`).
- One correction found while rewriting: the design said a device without graphics groups falls back to colour picking. The code refuses (since M0); colour picking was never implemented. Corrected in §元素归属 and §已定事项, with a dated note.
- The old @tbl-capture's numbers came from the research scripts' own figures, not the test fixtures, so the new table (p7) is not a row-by-row comparison with it; the matched comparison is p1 (element tables identical to the engine route on the six test inputs).

### Task 8: Held-out predictions and run

**Status:** `[x]` (owner's go-ahead: 2026-11-11)

**Files**
- Modify: `bench/predictions.md`, `bench/R/score-capture.R` (accepts a held-out file).
- Records: `bench/runs/`, `dev_docs/design.qmd` (§评测设计), `NEWS.md`, a dev log of its own.

**Intent**
- Predictions for the held-out capture run written into `bench/predictions.md` and committed before it. Both routes on the same 54 figures in the same container: the page route at the commit that holds the predictions and the engine route at the tag `engine-route-final` (Task 1). One run each, archived. Anything changed after reading the held-out results is reported as such.

**Checklist**
- [x] Scorer accepts a held-out run; on the development runs it prints what it printed (`2026-11-11-0705`: byte-identical to the archived score)
- [x] Engine-route procedure tried on the development set first: a clean clone at the tag with the seven vendored `data/` directories copied in (every file under `bench/figures/` has the repository's checksum). Run `2026-11-11-0832-capture-dev-engine-route`: 51 captured, 3 refused, 1 error; 40 equal, 6 known exceptions, 5 different, the counts of `2026-11-10-1424`
- [x] Predictions 9–20 and the scoring rules in `bench/predictions.md`, committed before either held-out run; they state where the two routes' judges differ
- [x] Page route on the held-out set, archived with log and score
- [x] Engine route on the held-out set, archived with log and score
- [x] Predictions scored; design §评测设计, NEWS, dev log; plan closed

**Result** (2026-11-11)
- Predictions 9–20 and the scoring rules committed in `529426c` before either run; both runs archived in `f0413eb` before any change to gloss or the harness. Commands: `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R heldout`, once in the repository at `529426c` (clean tree), once in the clone at `f48c124`.
- Page route, run `2026-11-11-0837`, 54 held-out figures: 52 captured, 2 refused ("the page mixes base graphics and grid": bioc-019, bioc-023), 0 errors, 0 timeouts; 50 equal, 2 not deterministic (exts-002, patchwork-013), 0 different. gloss's verdict agrees with the bench's on 52 of 52 (Task 4 reading), identical on 50; 0 failed invariants. Base: 7 of 9 equal, 2 refused; 0 count mismatches on 110 counted leaves (137 leaves have no expected count). Withheld tables or panels: 3 figures. Only the device background unowned: 52 of 52.
- Engine route, run `2026-11-11-0843`, same figures, its own harness and judge: 53 captured, 1 refused (ggsurvfit's print method), 0 errors; 40 equal, 5 known exceptions, 8 different. Base: 0 of 9 equal; 7 of 9 with a count mismatch.
- Predictions: 10 of 12 right; 12 and 17 wrong (`bench/predictions.md`). The lines that would change the plan: no failed invariant; no base figure the bench finds different; no figure `equal` on the engine route lost by the page route. One figure comes close to the third: bioc-019 is a known exception on the engine route (one extra rect, nothing missing) and refused on the page route.
- The two refusals are a defect, not mixed pages (scope change below).

---

## Scope changes

_(append-only; never edit completed tasks above)_

**2026-11-11, Task 2: the rule for tables (assumption 1).** A second build is not the drawn one when the build draws random numbers: with `position_jitter()` and no seed, 0 of 32 rows were on their point in 5 of 5 runs (`p2-jitter-tables.out`). Both candidate rules gave 32 of 32 in 5 of 5. Chosen: the engine's own drawing step where the print method is ggplot2's. It draws ggplot2's print steps (`grid.newpage()`, `ggplot_build()`, `ggplot_gtable()`, `grid.draw()`) and keeps the build; its page is `print()`'s (0 primitives differ from the same seed; contract check on `example()`). Not chosen: restoring the random state before `print()`. It writes `.Random.seed` into the global environment, and it is right only if the print method draws its random numbers in the same order as gloss's build, which gloss cannot check. Elsewhere tables are withheld with the reason (ADR-0006 point 4): a ggplot whose class has its own print method keeps its raw tables, and its built tables and panels are withheld (exts-018). patchwork has no public way to draw a kept build, so a plot whose two builds differ has its built tables withheld. Effect on the open tasks: Task 4 counts the development figures with withheld tables or panels; nothing else changes. This is the case the ADR names ("something the drawing returns"), so the ADR is not changed.

**2026-11-11, Task 4: what "gloss's verdict agrees with the bench's" means.** heatmap-008 is `Heatmap(..., km = 2)`: k-means runs inside `draw()`, so two drawings of the object differ (the bench's proof: 236 primitives). gloss says `equal`, and it is right about what it claims: its capture equals the page it drew (0 primitives differ), because the random numbers are drawn before grid's display list holds fixed grobs, and the engine's tables come from that same drawn list. gloss's self-check sees randomness only between its drawing and its capture (gallery-059: ggrepel places labels inside `makeContent()`); it does not certify that a figure draws the same page twice, and the jittered ggplot of Task 2 is another such case. The spike's "43 equal, 1 not deterministic" came from the page the code left, which it never drew a second time. Agreement in *Done when* is therefore read as: the bench's `equal` implies gloss's `equal`; the bench's `not_deterministic` allows gloss's `equal` or `not_deterministic`; the bench's `different` with gloss's `equal` is the failed invariant, unchanged. With this reading the grid pages agree 44 of 44. The design doc gets a dated note on what `equal` certifies.

**2026-11-11, Task 6: the counts the development run is held to.** *Done when* says "53 equal, 1 not deterministic, 1 refused" after the base step. Those counts came from the spike, which judged the page the code left and never drew a figure twice. Run `2026-11-11-0627` drew each figure twice and found two that are not deterministic: gallery-059 (5 primitives) and heatmap-008 (`Heatmap(km = 2)`, 236 primitives; Task 4 scope change). The line is therefore read as: 52 equal, 2 not deterministic, 1 refused, 0 errors, 0 different. "gloss's own verdict agrees with the bench's (55 of 55)" is read under the Task 4 reading over the 54 captured figures; the refused figure has no verdict on either side and counts as agreeing when its refusal carries a reason. Nothing else in *Done when* changes.

**2026-11-11, Task 8: "mixed page" is decided from the wrong display list (found on the held-out set; everything below is made after looking).** *Out of scope* says pages mixing base and grid are refused, "0 of 55". The held-out run refused 2 of 54 as mixed, both base figures at the end of a Bioconductor vignette. For bioc-019 the engine route's capture of the same figure shows a base-only page (the code's page plus one background rect). Reproduced on a hand-built page, not on the held-out figures: a function drawing a grid page and then a base page is refused with "7 base operations, 2 grid grobs", while the device's display list for the page holds 0 grid operations; `page_kind()` counts the grobs on grid's own display list, which a new base page does not clear. So the count "0 of 55 mixed" was a count of this test, not of mixed pages, and prediction 12 was wrong for it. The held-out numbers above stand as run. The fix (decide from the device's display list) is a bug fix with its own failing test, made after looking, verified on fixtures and the development set only, and recorded in the dev log; no held-out run is repeated without the owner's word. Whether bioc-023 has the same cause is not verified.

## Closing notes

Filled in when the plan moves to `done/`.
