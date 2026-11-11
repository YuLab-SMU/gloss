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
- Suite: 7 files, 56 tests, 338 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-11, after Task 1).
- Key numbers: development set on the engine route 40 equal / 6 known exceptions / 5 different of 51 captured; grid pages captured by the page route in `R/` (Task 1), not yet run on the development set; six fixtures identical to the engine route.

**Overall progress**
- [x] Task 1: Grid pages in the core: draw, wrap in place, self-check
- [ ] Task 2: Engines on the page: tables and panels that describe what was drawn
- [ ] Task 3: Dense leaves, size and time
- [ ] Task 4: Bench on the page route; development run of the grid step
- [ ] Task 5: Base pages by display-list entry _(stub; written out after Task 4)_
- [ ] Task 6: Base on the development set; names and classification re-measured; gridGraphics out; `R CMD check` _(stub)_
- [ ] Task 7: Records: design §元素归属 rewritten, NEWS, dev logs _(stub)_
- [ ] Task 8: Held-out predictions and run _(stub; needs the owner's go-ahead)_

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

**Status:** `[ ]`

**Tests assumption:** 1.

**Files**
- Modify: `R/engine-ggplot.R`, `R/engine-patchwork.R`, `R/engine-heatmap.R`, `R/engine-grid.R`
- Test: `tests/testthat/test-capture.R`, `test-identify.R`, `test-data.R`

**Intent**
- Tables and panels are statements about the page. Show that they hold, or withhold them.

**Checklist**
- [ ] Measure first, before changing engines: a ggplot with `position_jitter()` and no seed; drawn point positions against the built table mapped through the panel scales. Record how many points agree when the engine builds separately, and when it builds from the random state `print()` started with
- [ ] Measure on the two development figures with their own print methods (exts-018 ggbreak, gallery-052 ggExtra) what the ggplot engine's `tables()` and `panels()` return against the page: leaves found, panels matched, counts
- [ ] From the two measurements choose the rule (rebuild from the saved random state; or the engine's own drawing step where the print method is ggplot2's) and write it as a scope change with the numbers
- [ ] Where the engine's panels or tables cannot be matched to the page, withhold them with a reason in the substrate's status; test with the synthetic subclass
- [ ] ComplexHeatmap: draw on the page directly, keep the drawn list for tables; no `grid.grabExpr()`

**Verification**
- Tests: jittered points agree with the table for every row (a tolerance of the SVG's printed precision, stated in the test); the subclass fixture has no tables and a reason; heatmap and patchwork tables equal today's on the fixtures.
- Would change the plan: no rule makes the jittered table agree. Then tables of a randomly built plot are withheld, and M1 binding on such figures is a recorded limit.

**Result** _(filled in when done)_

---

### Task 3: Dense leaves, size and time

**Status:** `[ ]`

**Tests assumption:** 2 (second half) and 3.

**Files**
- Modify: `R/core-substrate.R` (`rasterize_leaves()`, `keep_only_leaf()`)
- Test: `tests/testthat/test-capture.R` (dense), `test-bundle.R` (size)

**Checklist**
- [ ] Redraw one leaf alone from the display list on the PNG device; compare its raster with today's on `points_1e4` (pixel for pixel) and its index (same points)
- [ ] The 10^5-point slow test: bundle under 3 MB, as today
- [ ] Time at 10^3, 10^4, 10^5 points, capture and self-check apart, five runs each, median and range, against `aef42f2`
- [ ] If the check exceeds the limit of assumption 3, apply the scope change described there

**Verification**
- `NOT_CRAN=true Rscript -e "devtools::test()"` with the slow test; a timing script kept under `dev_docs/research/capture-fidelity/` with its output.
- Would change the plan: a raster that differs from today's; a bundle over 3 MB.

**Result** _(filled in when done)_

---

### Task 4: Bench on the page route; development run of the grid step

**Status:** `[ ]`

**Tests assumption:** 4.

**Files**
- Modify: `bench/R/runner.R` (recovery, comparison), `capture.R`, `score-capture.R`, `check-runner.R`

**Checklist**
- [ ] Comparison with clip regions; `check-runner.R` gains a case that loses a clip with every primitive unchanged and must be `different`
- [ ] A verdict `not_deterministic`, proved by the bench itself (two plain drawings of the figure differ), never assumed from the package
- [ ] Recovery: an object stays an object; a page the code drew is handed over as a recorded plot, not through `grid.grab()`. Check on fixtures that the replayed page captures like the page drawn in place
- [ ] The reference for an object is the page that object draws alone; the page the frozen code left is reported beside it (39 of 42 objects equal it in the spike)
- [ ] Record gloss's own verdict per figure and its agreement with the bench's
- [ ] `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev`, archived, labelled as made after looking

**Verification**
- `Rscript bench/R/check-runner.R`: OK, with the new cases failing before the change.
- Development run: the grid-step line of *Done when*. Would change the plan: any figure different without gloss's verdict saying so; a grid page that errors.

**Result** _(filled in when done)_

---

### Task 5: Base pages by display-list entry _(stub)_

Replay by entry in the core, reading only the new bytes of a file device (`s6-details.R`: 5008 entries in 0.32 s against 53 s); leaves, names from the entry's call, expected counts, leaf marks in the scene, panels and scales from `par()`; the base engine without gridGraphics; a recorded plot from another device captured with a recorded note. Written out after Task 4, from what Tasks 1 to 4 showed about the substrate's format.

### Task 6: Base on the development set _(stub)_

Development run of the base step against the last line of *Done when*; the base names in design §分类 measured again on the development base figures; gridGraphics removed from `Suggests` and the tests; `R CMD build` and `R CMD check --as-cran`; the recorded-plot structure tested on each R version available.

### Task 7: Records _(stub)_

Design doc: §元素归属 rewritten for the page route (not only dated notes), §风险与未决问题, §已定事项, §与上一版的区别; `NEWS.md`; a dev log per session; this plan closed to `plan/done/`.

### Task 8: Held-out predictions and run _(stub; owner's go-ahead)_

Predictions for the held-out capture run written into `bench/predictions.md` and committed before it. Both routes on the same 54 figures in the same container: the page route at the plan's final commit and the engine route at the tag `engine-route-final` (Task 1), so the comparison is matched. One run each, archived. Anything changed after reading the held-out results is reported as such.

---

## Scope changes

_(append-only; never edit completed tasks above)_

## Closing notes

Filled in when the plan moves to `done/`.
