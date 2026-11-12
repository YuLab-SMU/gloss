# The thinnest agent path, and a pilot of the decisive comparison

> Status: active.
> Date opened: 2026-11-12. Owner: Yonghe Xia. Opened by Claude on the owner's word of 2026-11-12 ("我们使用自己部署的模型，magpie 中的westlakeHPC 模型都是免费的。其他你来决定就行"), as recommended in [the retrospective](../dev_logs/2026-11-12-retrospective.md).

**Goal:** A model that works only through read-only tools over a gloss figure and one `propose` that validates on submit answers binding questions on development figures, and a pilot compares it with the same model given the raw material and a read-only R sandbox, so that we know whether the main claim has an effect to measure and what a run costs.

**Why now:** [The retrospective](../dev_logs/2026-11-12-retrospective.md), first surprise: five plans ordered their own tasks by risk and none tested the clause the paper rests on. Of the nine clauses of the research card three have data, all on capture. `gl_bindings()` exists since [Task 6a of the M1 plan](2026-11-11-m1-roles-and-binding.md), so an agent has something exported to read.

**Research-card clause:** "底座加同一模型，比同样原始材料加同一模型更准，覆盖率不降" (design @tbl-claims, the concept claim; the main claim of design §研究卡片, point 2). It has no data and no code today. This plan gives it a pilot on development figures, on the binding layer only. A pilot is not a reported number: it runs on the development set, with free models that are not the latest, and it exists to size the experiment of M5 and to find out early if there is nothing to measure.

**Starting state (measured):**
- Suite: 10 files, 119 tests, 885 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-12, `f078dd9`); the bench container the same.
- Agent code under `R/`: none (`ls R/agent-*.R`: no such file). Tools over the substrate: none. `propose`: none. Records: none.
- Model access (checked 2026-11-12): the owner's magpie gateway at `http://127.0.0.1:3425/v1`, OpenAI-compatible; `westlakehpc/glm-5.3-flash`, `westlakehpc/deepseek-v4.1-flash`, `westlakehpc/Qwen3.8-27B`. One call with one tool through aisdk 1.5.0 (`create_openai(base_url = )`, `generate_text(tools = , max_steps = )`) ran the tool once and answered in 2.9 s. aisdk is installed on the host and is not in `DESCRIPTION`.
- Model-driven runs so far: 0. Numbers on conditions A or B: none.

**Assumptions to test (riskiest first):**
1. *The owner's free models drive a tool loop to a validated submission, through aisdk and the gateway, often enough to run an experiment.* Evidence: one call with one tool. Tested in Task 1 on a hand-built figure. If fewer than two of the three models finish the lookup variant correctly in 8 of 10 runs, the plan stops before any tool is built into the package and the owner is asked for other models.
2. *A pairing proposed after capture can be checked from the figure alone:* the element's geometry, the table's row and the panel's scales, with no engine state. `propose` must validate on a figure read from a bundle, because model calls are made on the host and third-party figure code runs only in the container. Evidence: none; today's check takes device positions from the engine while its state is at hand. Tested in Task 2 without a model, on the development sets: the share of verified elements whose own row passes the figure-alone check and whose permuted row fails. If it is under 80% of the verified elements of ggplot figures, the placements of rows on the device become a derived table made at capture (ADR-0007) before `propose` is built on them.
3. *The question has room between the two conditions.* Design §评测设计 expects the gap to be small on plain scatter plots, since condition A can compute the answer in its sandbox. If A is right on 95% or more of the pilot's questions, the pilot says so and the figures or the layer asked about change before M5 is sized.
4. *Condition A can be given a sandbox that is read-only, offline and held to the same budget.* The bench container runs with no network; a tool call from the host would start R in it. Tested in Task 4. If a call costs more than about 10 s of start-up, the budget in calls is not comparable and the sandbox needs a session that stays up.
5. *Code alone does not already answer the pilot's questions.* The rival of [the idea note on proposals](../idea/2026-11-12-binding-proposals.md): an enumeration over tables and rows, checked by the same validation, needs no model. The pilot reports it as its own arm. If it answers everything, the binding layer is the wrong place to look for the model's contribution and the pilot moves to a layer code cannot enumerate.

**Architecture:** Agent code is new files `R/agent-*.R` and depends on aisdk through `Suggests`; the core and the store keep working without it. Tools are closures over one figure, made by a factory, all read-only except `propose`. `propose` takes schema-validated data only, checks it with code and returns either an accepted proposal or the list of what failed; an accepted proposal is the first record laid over a derived table (ADR-0007, point 1). gloss owns no agent loop: the loop is aisdk's. Harness code for the pilot (question sampling, the two conditions, scoring, archives) lives under `bench/`, not in the package. Nothing in capture or in the binder changes.

**Out of scope:**
- Roles, relations, claims: no rules, no check primitives and no labels to score them against yet.
- The held-out sets. Every run here is on hand-built figures or the development sets.
- Reported numbers, the latest closed model, five repeats per configuration with intervals over figures: that is M5, sized from this pilot.
- The record core of M2 (anchors with several selectors, layers, rebase). The pilot needs one kind of record, kept in memory for the run.
- Staged agents, `gl_annotate()`, caching, disclosure levels other than the one the pilot uses.
- Speeding up the bind step (ADR-0007, follow-up).

**Tech stack:** R 4.5.2; aisdk 1.5.0 (Suggests, when agent code lands under `R/`); the magpie gateway and the westlakeHPC models, called from the host; the bench container for anything that runs figure code; jsonlite. The gateway's key is read from the environment and is never printed, logged or archived.

**Done when:**
- Task 1's numbers are recorded for the three models, with the predictions committed before the runs.
- The figure-alone check is measured on both development sets against the capture-time bindings (Task 2), and `propose` rests on whichever of the two the measurement supports.
- `gl_tools()` passes contract tests with a scripted model (no network), and a test shows that `propose` rejects a wrong pairing with a reason and accepts the right one.
- The pilot has run on about ten development figures in conditions A and B and the enumeration arm, each run archived under `bench/runs/` with its inputs, tool calls, outputs and model id, with predictions committed first; accuracy, coverage, calls and time are reported per figure and per condition, and the report says plainly that it is a pilot.
- The closing notes say what M5 should be, given the pilot: which layer, how many figures and repeats, which models, and the cost of one run.

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
- Suite: 13 files, 146 tests, 1357 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-12, `7edf4fc`); the bench container 13 / 146 / 1351, 0 failed, 0 errors, 1 skipped (the scripted-model test: aisdk is not in the container's image).
- Key numbers: the figure alone against the engine's positions, runs `2026-11-12-1737-alone-dev` and `-1748-alone-dev-tree` (development sets, container, after the flipped-panel change): of the elements the engine's positions verify, the figure alone verifies 99.9% on v0's ggplot figures (9063 of 9069; 24 of 26 figures agree) and 98.2% on the tree set's (13865 of 14112; 24 of 28); base 83.8% (4 of 9 figures); heatmap 0 of 250 cells; no leaf passes more from the figure alone. Before the change (Task 2's runs): 99.8% and 98.1%, 23 of 26 and 23 of 28.
- Task 1, run `2026-11-12-1627-drive-tools` (hand-built figure, host): 60 of 60 runs correct, 10 of 10 for each of three models in each variant; 0 failed calls of 313; 0 rejected submissions; median 7.5 s and 8380 tokens a run. Conditions A and B: no number yet; the models stopped answering on 2026-11-12 before any run of them.
- The pilot's arm without a model (30 questions on 10 development figures, every row of every built table proposed): with `propose` checking place only, the answer accepted on 30 and the arm right on 23 (run `2026-11-12-1906-pilot-enumerate`); with the leaf's layer checked as well, right on 30 of 30 (run `-1913`).

**Overall progress**
- [x] Task 1: Do the free models drive tools to a validated submission?
- [x] Task 2: A pairing checked from the figure alone, measured against the capture-time bindings
- [~] Task 3: `gl_tools()` and a validating `propose`; the first record _(steps 1 to 3 done 2026-11-12: the flipped panel, `gl_propose()`, `gl_tools()`; the run with models open)_
- [x] Task 4: Condition A: the raw material and a read-only, offline R sandbox _(done 2026-11-12; no model has used it yet)_
- [~] Task 5: The pilot: conditions A and B and the enumeration arm on development figures _(material, 30 questions, the dry run and the arm without a model done 2026-11-12; the arms with models wait for the models)_
- [~] Task 5b: The bundle's round trip on the development sets _(measured and three defects closed 2026-11-12; the rerun on v0 is going)_
- [ ] Task 6: Records: design notes, NEWS, dev log, closing notes

---

### Task 1: Do the free models drive tools to a validated submission?

**Status:** `[x]` (2026-11-12)

**Tests assumption:** 1.

**Files**
- Create: `bench/agent/drive-tools.R` (the harness: figure, tools, questions, runs, scoring), `bench/runs/<stamp>-drive-tools.*` (archive).
- Modify: `bench/predictions.md` (predictions 102 onward, committed before the first run).
- Test: none under `tests/`; nothing under `R/` changes.

**Intent**
- Everything after this task assumes a model that calls tools in a loop and ends by submitting. If the free models cannot, tools built into the package would be tested by nothing. The task is a harness outside the package so that no API is fixed before it is known to be usable.

**Checklist**
- [ ] One hand-built figure on the host: `mtcars`, weight against mpg, coloured by cylinders, facetted by transmission (32 points in 2 panels, every binding verified). Five questions, the elements drawn with a fixed seed: "the circle centred at (cx, cy) pt: which row of `built_layer1` does it draw?"
- [ ] Variant L (lookup): tools `overview`, `find_elements` (by device point), `get_binding` (the element's row, from `gl_bindings()`), `get_rows`, `submit`. The answer is two calls away; this measures the loop.
- [ ] Variant M (masked): no `get_binding`. Tools `overview`, `find_elements`, `to_data` (device point to data values in a panel), `find_rows` (rows of a table near given values), `get_rows`, `submit`. The model has to work the pairing out.
- [ ] `submit(element, table, row)` validates on submit: the element and the row exist, and the pairing is the checked one. A rejection returns the reason and the run goes on. A run is correct when it ends with an accepted submission for the element asked about; the harness asserts that no accepted submission is wrong.
- [ ] Three models, two variants, five questions, two runs each: 60 runs, `temperature = 0`, at most 12 steps. Per run: finished, correct, tool calls, calls aisdk reports as failed, rejected submissions, seconds, tokens when the gateway gives them.
- [ ] Predictions committed, then the runs, archived before scoring.

**Verification**
- `Rscript bench/agent/drive-tools.R` on the host, with the gateway up.
- Expected: at least two models correct in 8 of 10 runs of variant L. The result that would change the plan: fewer than two (stop, ask the owner for models); variant M under 5 of 10 for every model (the tools of Task 3 are redesigned before the pilot, starting from what the transcripts show).

**Result** (2026-11-12; [dev log](../dev_logs/2026-11-12-agent-path-task1.md))

- *Order kept:* predictions 102-107 and the harness committed in `cce1bab`; `Rscript bench/agent/drive-tools.R --dry` (no model) reached the checked row for all five questions in both variants and had a wrong row rejected each time; then `Rscript bench/agent/drive-tools.R` once, 60 runs, archived unscored in `dca7905` (`bench/runs/2026-11-12-1627-drive-tools.json`, `.csv`); then `Rscript bench/agent/score-drive-tools.R bench/runs/2026-11-12-1627-drive-tools.json` (`-score.txt`).
- *Observed:* correct runs of 10, variant L then M: glm-5.3-flash 10 and 10, deepseek-v4.1-flash 10 and 10, Qwen3.8-27B 10 and 10. No run raised an error; all ended with `stop`. Failed calls 0 of 313. Rejected submissions 0. Median tool calls 4.5 in L (3 to 8) and 6 in M (5 to 6). Seconds a run: median 7.5, 90th percentile 16.3, longest 28.5; by model, medians 4.7 to 5.1 (deepseek), 6.7 to 8.2 (Qwen), 9.7 to 16.0 (glm). Tokens a run: median 8380, most 14035; 504923 in all, 9.2 minutes.
- *Assumption 1 holds on this task:* all three models drive the loop to an accepted submission every time. The result that would have stopped the plan did not occur.
- *Predictions:* 4 right of 6 (`bench/predictions.md`). Wrong: the models make more calls than the answer needs (`overview` in 57 of 60 runs; `get_rows` after `get_binding` in 13 of 30), and no submission was ever rejected.
- *Cost:* 362 lines under `bench/agent/` (harness 270, scorer 92), none under `R/` or `tests/`; one run with models. *Moved:* model-driven runs from 0 to 60; the plan's first assumption from one call to a measured rate.
- *Its limits:* one figure, `mtcars`, five questions. It measures the loop.

---

### Task 2: A pairing checked from the figure alone

**Status:** `[x]` (2026-11-12)

**Tests assumption:** 2.

**Files**
- Create: `R/core-alone.R` (`place_rows()`: a table's rows put on the page through a panel's scales, from the figure and nothing else; `recheck_alone()`: the engine's own claims checked a second time with their rows placed that way; `alone_capture()` for the bench), `tests/testthat/test-alone.R`, `bench/R/alone.R`, `bench/R/score-alone.R`.
- Modify: `bench/R/runner.R` and `bench/R/harvest.R` (an `alone` option beside `bind`), `bench/predictions.md`.

**Intent**
- `propose` has to validate on a figure read from a bundle, where the engine's state is gone. Today the device position of a row comes from the engine at capture (the coord's own transform, the base entry's `usr`, a heatmap's cell order). The cheapest replacement is what the figure already holds: the table's position columns and the panel's scale ranges. This task measures how far that goes before anything is built on it. It uses no model.
- The comparison is made claim by claim at capture, where both are available: the same rows, the same comparison by tag, the positions once from the engine and once from the figure alone.

**Checklist**
- [ ] Tests first (`test-alone.R`), on hand-built figures: placements equal the engine's on a cartesian scatter and a facetted figure; a panel whose scales are not ranges on the page (polar) gives a reason, not a position; a flipped coord is never verified by mistake.
- [ ] `place_rows()`, `recheck_alone()`, `alone_capture()`; host suite and container suite.
- [ ] Per claimed leaf: the status under the engine's positions and under the figure's own; the largest gap between the two placements in pt; the reason when the figure alone cannot place the rows; and a mutation (positions shifted by one row within the leaf) counted under both, as the number of elements whose place moves by more than the tolerance and that still pass.
- [ ] Predictions committed; then `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/alone.R dev` and `... dev tree`, archived before scoring.
- [ ] Report by engine, verified apart from ambiguous, with per-figure counts; the reasons, by class.

**Verification**
- The two runs above and `Rscript bench/R/score-alone.R <run>-leaves.csv`.
- Expected: on ggplot figures with a cartesian coord the two agree. The result that would change the plan: under 80% of the elements the engine's positions verify on ggplot figures are verified from the figure alone (then row placements become a derived table made at capture, ADR-0007, before `propose` is built); any element verified from the figure alone that the engine's positions fail (a defect in one of the two, examined before anything else).

**Result** (2026-11-12; [dev log](../dev_logs/2026-11-12-agent-path-task2.md))

- *Order kept:* tests first (`test-alone.R`, failing: the functions did not exist), then the code; predictions 108-116 and the scoring rules in `29d92e4` with the code; runs archived unscored in `3dd0f57`; scored with `Rscript bench/R/score-alone.R` (`bench/runs/2026-11-12-1711-alone-dev-score.txt`, `-1722-alone-dev-tree-score.txt`). Two earlier runs measured nothing (a shadowed option; `0c0217d`) and are not kept.
- *Suite,* `NOT_CRAN=true Rscript -e "devtools::test()"`: host 11 files / 125 tests / 917 expectations / 0 failed / 0 skipped at `29d92e4` (was 10 / 119 / 885), container the same with 0 errors; host 11 / 126 / 922 at `d23876d`.
- *Observed,* elements the engine's positions verify that the figure alone verifies, and figures in which every checked leaf has the same counts:

  | set, engine | verified | ambiguous | figures that agree |
  |---|---|---|---|
  | v0, ggplot | 9053 of 9069 (99.8%) | 15328 of 15328 | 23 of 26 |
  | tree, ggplot | 13843 of 14112 (98.1%) | 8901 of 8907 | 23 of 28 |
  | v0, patchwork | 98 of 98 | 6 of 6 | 3 of 3 |
  | tree, patchwork | 100 of 100 | 0 of 0 | 1 of 1 |
  | v0, base | 2131 of 2544 (83.8%) | 93 of 93 | 4 of 9 |
  | v0, heatmap | 0 of 250 | 0 of 0 | 0 of 3 |

  Where the two agree the placements are the same to 0.0000 pt, apart from 101 base path leaves that agree by coincidence (gaps up to 0.49 pt). No leaf passes more elements from the figure alone than with the engine's positions.
- *Assumption 2 holds where the panel's scales are linear ranges on the page, and only there.* Both sets clear the plan's 80% on ggplot figures. By figure, 3 of 26 and 5 of 28 have a leaf the figure alone does not check, and three circular trees have none it can. What it lacks, by kind, is in `bench/predictions.md` under predictions 108-116: polar and `sf` panels (not placed, with the reason), `coord_flip()` (placed elsewhere: a right pairing would be rejected), the binder's two draw-time rules, base polygons and paths (the engine pairs an element with the mean of its vertices), heatmap cells (the binding's row is a cell).
- *Predictions:* 8 right of 9. Wrong: the tree set's share (98.1%, predicted 50% to 90%).
- *Cost:* 284 lines under `R/` and `tests/` (`R/core-alone.R` 176, its tests 84, the heatmap test and its note in the documentation 24), 201 net under `bench/R`; two host suite runs, one container suite run, four bench runs of which two measured nothing. *Moved:* the plan's second assumption from no evidence to a number on 84 development figures; nothing a user can call.
- *Found on the way and fixed:* `gl_bindings()` said its rows are rows of the table; for a heatmap they are cells of the matrix (`d23876d`, documentation and a test).
- *Its limits:* the claims are the binder's own, so this measures whether a check after capture reproduces the check at capture, not whether a proposal from elsewhere is right. The recheck is slow on many leaves (222.7 s on gallery-029's 4002).


---

### Task 3: `gl_tools()` and a validating `propose`

**Status:** `[~]` (written out 2026-11-12, after Task 2; step 1 done)

**Tests assumption:** 2, on single pairings; and that what Task 1's models used is enough to answer with.

**Files**
- Step 1 (done): `R/engine-ggplot.R`, `R/engine-heatmap.R`, `R/core-substrate.R`, `R/identify.R` (panels say whether they are flipped), `R/core-alone.R`, `tests/testthat/test-alone.R`, `bench/R/compare-alone.R`.
- Create: `R/propose.R` (`gl_propose()`), `tests/testthat/test-propose.R`; then `R/agent-tools.R` (`gl_tools()`), `tests/testthat/test-agent-tools.R`.
- Modify: `DESCRIPTION` (aisdk in `Suggests`), `NEWS.md`.

**Intent**
- One entry point that takes a pairing as data and answers from the figure alone, also on a figure read back from a bundle: accepted, rejected with the reason, or refused because this figure does not let it be checked. People call it as agents do (principle 5). The tools are thin closures over one figure; the loop is aisdk's.

**Checklist**
- [x] Step 1: a flipped panel says so and is placed through; measured again on both development sets (Result below).
- [x] Step 2, no model: `gl_propose(fig, proposal)` for `list(kind = "binding", element, table, row)`. Schema first (fields, types, no extras), then existence (element, table, row), then the check: the row placed by `place_rows()`, the element compared by the binder's comparison for its tag, and the other rows of the table in that panel counted as the binder counts ties. Three outcomes, never a fourth: `accepted` (with the status `verified` or `ambiguous` and the deviation), `rejected` (the check ran and failed; the reason carries the distance), `refused` (the check cannot run here; the reason says why: a panel whose scales are not ranges, a table without positions, an element that draws a group). Tests first, among them: every verified element of a facetted figure is accepted with its own row and rejected with another's; the same on the figure read back from an HTML bundle; a polar figure is refused, not rejected; an extra field or a URL in a field is a schema error.
- [x] Step 3: `gl_tools(fig)`: `overview` (panels with their scales, tables with their columns), elements by place, rows by number and by value, `propose`; a state that keeps what was accepted, rejected and refused in the run. aisdk in `Suggests`; its internet probe switched off for the run (`options(aisdk.skip_internet_check = TRUE)`: it only asks `curl::has_internet()`, which looks up two public DNS names and, behind a proxy, fetches a captive-portal page; it sends nothing of ours). Contract tests with a scripted `aisdk::LanguageModelV1` subclass, no network.
- [ ] Step 4: Task 1's harness run again through `gl_tools()` on its figure, as a check that the package's tools do what the harness's did (predictions first).

**Verification**
- Host and container suites with counts; the tests named above.
- The result that would change the plan: an element the binder verifies whose own row `gl_propose()` rejects on a figure where Task 2 found agreement (the single-pairing check differs from the leaf's check, and the difference is found before any model sees it).

**Result, step 1** (2026-11-12; `b48c373`)

- Tests first: a flipped scatter and flipped bars with labels (failing: placed elsewhere), panels of ggplot, patchwork and base saying whether they are flipped, a panel that does not say refused. One defect of mine on the way: swapping x and y in column names with `chartr()` turned `xmax` into `ymay`; the bars' test caught it.
- Suite, `NOT_CRAN=true Rscript -e "devtools::test()"`: host 11 files / 128 tests / 933 expectations / 0 failed / 0 skipped (was 11 / 126 / 922); container the same, 0 errors.
- Measured again, predictions 117-119 first (3 right of 3): runs `2026-11-12-1737-alone-dev` and `-1748-alone-dev-tree`. Exactly two figures change, bioc-016 (10 bars) and tree-045 (22 elements), from failed to verified; nothing under the engine's positions changes. v0 ggplot 9063 of 9069 verified from the figure alone, 24 of 26 figures agree; tree ggplot 13865 of 14112, 24 of 28.
- Cost: 51 net lines under `R/` and `tests/` (68 added, 17 removed), 36 under `bench/R`; one host and one container suite run, two bench runs. Moved: 32 elements in 2 figures, and a false rejection that `propose` would have given.

---

**Result, step 2** (2026-11-12)

- *What landed:* `gl_propose(fig, proposal)`, exported, with `print()`; internal `propose_context()` (the scene parsed once) and `check_proposal()`. Three outcomes with a `stage` (`schema`, `exists`, `check`); an accepted proposal carries its record (element, leaf, table, row, status, deviation, tolerance, `basis = "figure"`). The record is returned, not stored: where records live is the tools' state for a run (step 3) and M2's record core after that.
- *Tests first* (`tests/testthat/test-propose.R`, 7 tests, 300 expectations, failing before the code): every element of a facetted figure that the binder verified or left ambiguous with one row is accepted with its own row and the binder's status, and rejected with another's; the same answers on the figure read back from an HTML bundle and on one captured with `bind = FALSE`; seven malformed proposals and four that name what is not there are rejected before any check; a row of another panel with the same values is rejected; legend keys are rejected; a polar panel, an element that draws a group and a base figure are refused; a flipped panel and a dense leaf of 12000 points are checked.
- *Narrower than the plan's step said, on purpose:* ggplot and patchwork figures only. Task 2 measured two ways a right pairing would be rejected on base figures (a log axis, which the panel does not state; a polygon paired with the mean of its vertices) and none of a heatmap's cells can be placed, so both are refused with that reason instead of checked wrongly. Only built tables are placed: a raw table's columns named `x` and `y` are not positions by any contract.
- *Suite,* `NOT_CRAN=true Rscript -e "devtools::test()"`: host 12 files / 135 tests / 1233 expectations / 0 failed / 0 skipped (was 11 / 128 / 933); the bench container the same, 0 errors.
- *Speed:* on a 32-point figure the context takes 0.002 s and 32 checks 0.029 s (host, one run).
- *Cost:* 363 lines added under `R/` and `tests/` (`R/propose.R` 194, its tests 155, 14 in a helper shared with `core-alone.R`); one host suite run, one container run. *Moved:* the validating entry point from design to an exported function tested on a bundle-restored figure; no bench number.
- *Not done:* a model has not called it; no proposal for a group of rows; no record is stored anywhere.

---

**Result, step 3** (2026-11-12)

- *What landed:* `gl_tools(fig, hide = NULL)` and `gl_tool_state(tools)`, exported; the tools' work is plain R in `tool_specs()`, which needs no aisdk. Nine tools: `overview` (page, panels with their scales and whether they are flipped, tables with their columns), `find_elements` (by place), `get_element`, `get_binding` (what capture bound; `hidden` for the leaves named in `hide`), `describe_table`, `get_rows` (by number, 20 at most), `find_rows` (nearest rows by value in a panel), `to_data`, and `propose`, which is `gl_propose()`. Arguments are checked against each tool's schema before the tool runs; a call that cannot be served answers `{"error": ...}` and is counted as failed; every call is kept in the run's state, and only `propose` adds to its proposals. No tool writes the figure, runs code or reaches outside.
- *Tests first* (`tests/testthat/test-agent-tools.R`, 6 tests, 45 expectations on the host): the eight read-only tools answer what the R API answers; eight read-only calls leave no proposal, a wrong row is rejected with the distance and the right one accepted; eight calls no tool can serve (a wrong type, a missing argument, an element, table or panel that is not there, too many rows, a table without positions, a tool that does not exist) come back as data; hidden bindings stay hidden and `propose` still checks; the same on a figure read back from an HTML bundle; a scripted `aisdk::LanguageModelV1` subclass drives `gl_tools()` through aisdk's loop to a rejected and then an accepted proposal, and what it is handed back after the rejection is the reason as JSON.
- *Suite,* `NOT_CRAN=true Rscript -e "devtools::test()"`: host 13 files / 141 tests / 1278 expectations / 0 failed / 0 skipped (was 12 / 135 / 1233). Bench container (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R`): 13 / 141 / 1272 / 0 failed / 0 errors / 1 skipped. The skip is the scripted-model test: aisdk is not in the container's image, so the wrapper `gl_tools()` has run on the host only; `tool_specs()`, which does all the reading, ran in both.
- *aisdk:* in `Suggests`, with R6 for the test's scripted model. CRAN has aisdk 1.4.12 (index read 2026-11-12); the host has 1.5.0, and nothing was run against 1.4.12.
- *Cost:* 451 lines added under `R/` and `tests/` (`R/agent-tools.R` 271, its tests 180); the host suite and the container suite once each on the final code. *Moved:* the tools from the bench harness into the package, under contract tests; no bench number.
- *Not done:* no real model has called these tools yet (step 4); the state lives for one run and is not written into the figure (records are M2's); nothing limits how many calls a run makes, that is the loop's `max_steps`.

---

### Task 4: Condition A

**Status:** `[x]` (written out 2026-11-12, after Task 3 step 3; done the same day)

**Tests assumption:** 4 (a sandbox that is read-only, offline and held to the same budget), before any model is asked.

**Files**
- Create: `bench/agent/sandbox.R` (R code run in the bench container), `bench/agent/material.R` (the material of chosen development figures, made in the container).
- Modify: `bench/R/runner.R`, `bench/R/harvest.R` (the worker writes a figure's material when asked).

**Intent**
- Condition A as design §研究卡片 has it: the model gets the figure's code, its raw data, the built data, the grob tree as text and the SVG svglite wrote, and can run R on them. Nothing of gloss is in its hands. The tables are the ones gloss holds, written out, so both conditions name rows the same way; the SVG is the figure drawn alone on svglite, not gloss's scene.
- The sandbox is the bench container: no network, a read-only root, the figure's package library read-only, none of the host's environment, not the repository; limits on time, memory and processes. Each run works on a fresh copy of the material, which is thrown away. Third-party figure code and code a model wrote run nowhere else.

**Checklist**
- [x] Step 1: `bench/agent/sandbox.R` with a self-check (`--dry`) of what it can and cannot do.
- [x] Step 2: `bench/agent/material.R`, development figures only: per figure, the bundle gloss writes (for condition B and the enumeration, read on the host with `gl_read()`), the bindings made at capture (the answers, kept apart), and condition A's directory: `code.R` and its `data/`, `tables/<name>.csv` and `tables.rds`, `grob_tree.txt`, `figure.svg`. A check that every element a question can ask about has the same place in `figure.svg` as in gloss's scene.
- [x] Step 3: the harness's two tool sets: A has `run_r(code)` and `submit(table, row)`, which records and says nothing more; B has `gl_tools()` with every binding hidden. One budget for both: the same limit on steps and on time, the same cap on what a tool hands back. A no-model check drives both to a right answer on one figure.

**Verification**
- The self-check's output; the material's counts per figure; the no-model check.
- The result that would change the plan: an element whose place in svglite's own page differs from gloss's scene by more than 0.01 pt (the two conditions would be asked about different things, and the question has to name the element another way).

**Result, step 1** (2026-11-12)

- `Rscript bench/agent/sandbox.R --dry`: 13 checks, all pass. The sandbox reads its material, loads the bench's packages and builds a plot (0.9 s for that call, container start included); has no network; sees no key, token or proxy of the host, no repository and no sources; cannot write outside `/work` and `/tmp`; keeps its own files from one call to the next and leaves the material unchanged; stops code after its time limit and says so; clips a long output to head and tail; an error or a call for too much memory ends that call only; a new sandbox starts from the material; closing removes it.
- *Assumption 4's threshold:* a call costs about 1 s with the container's start, far under the 10 s that would have asked for a session that stays up. One container a call is kept.
- Cost: 136 lines under `bench/agent/`, none under `R/` or `tests/`.

**Result, steps 2 and 3** (2026-11-12; `0def04f`, `a3c352d`, `641a942`)

- *Material* (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/agent/material.R pilot`, runs `2026-11-12-1853-material-pilot` and `-1900`): written for 9 of the 10 sampled figures, 41 KB to 5130 KB a figure. Not for exts-021: `gl_write()` stops on its raw table (Scope changes). exts-030 stands in.
- *The same element in both arms:* of the 6493 circles and rectangles bound one for one row in the 10 figures, 0 are at another place in svglite's own page than in gloss's scene (0.01 pt); the result that would have changed the plan did not occur.
- *The tool sets* (`Rscript bench/agent/pilot.R dry`, no model, all 30 questions): the answer's row is in arm A's material and a submission of it scores right; arm B finds the element at its place, its binding is hidden, and `propose` accepts the answer on the figure read back from the bundle. Every figure's own code runs in the sandbox, 0.7 to 55.2 s.
- *One budget:* 16 model turns, 180 s a model request, 120 s a sandbox call, 4000 characters a tool hands back. The time of a whole run is recorded, not capped.
- *What the first dry run showed:* bioc-016's code was killed at the sandbox's 2 GB and the sandbox called it a timeout. Now 6 GB, and a memory kill is told apart from a timeout (14 checks in the self-check).
- *Assumption 4 holds:* the sandbox is read-only outside its own copy, offline, and its calls cost about 1 s.
- Cost: 942 lines under `bench/agent/` (sandbox 144, material 86, writer 39, harness 470, sample 47, scorer 156) and 20 added in the bench worker and its caller; none under `R/` or `tests/`. Not done: no model has called `run_r` or `submit`; the rehearsal on a hand-built figure waits for the models.

---

### Task 5: The pilot

**Status:** `[ ]` (written out 2026-11-12; the rule below is fixed before any model run)

**Tests assumption:** 3 and 5: with the same model, material and budget, are answers through the substrate's tools and a validating `propose` right more often than answers worked out in a sandbox? And is a model needed at all where code can try every row?

**Which figures, which questions** (fixed here, before any run; seed 20261113)
- *Population:* the development figures of both sets whose engine is ggplot or patchwork and which have, in the bindings made at capture, circles or rectangles verified one for one row. In the archived development runs (`2026-11-12-1116-bind-dev`, `-1107-bind-dev-tree`) that is 29 of 66 such figures: bioc 2, exts 6, gallery 8, patchwork 3, tree 10. Circles and rectangles only, because both conditions read their place the same way (the centre of the box); text, lines and polygons wait. Elements code left unbound have no answer to score against and are not asked about here.
- *Sample:* 10 figures, by stratum in proportion (bioc 1, exts 2, gallery 3, patchwork 1, tree 3), drawn with the seed from the population in the order of their ids. Not chosen by what they hold. The scope change after Task 1 asked for figures where a first answer can be wrong; the archives show that 24 of the 29 have such elements in one layer only, so a rule that kept only figures with several such layers would leave five. The pilot therefore samples the population as it is and reports, per figure, what it holds (layers, panels, rows that tie).
- *Questions:* up to 3 elements a figure, drawn with the seed: first one element from each of up to 3 leaves, then further elements if the figure has fewer than 3 such leaves. The question gives the element's tag and the centre of its box in pt and asks for the table and the row. The answer is the binding made at capture (`verified`), which neither condition is shown.
- *Arms:* A (Task 4), B (`gl_tools()` with bindings hidden), and S, no model: every row of every built table tried through `gl_propose()` for the element.
- *Runs:* the three westlakeHPC models, each arm with a model 3 times a question, temperature 0; the same limit on steps and time. Predictions committed first; every run archived before it is scored.

**Scored** (per figure, then over figures; never one pooled share alone)
- A: the last submission names the answer's table and row. B: `propose` accepted the answer's table and row for the element. An accepted proposal that is not the answer is counted as a wrong acceptance, never as right. S: the answer is accepted and nothing else is; more than one accepted is reported as such.
- Beside each: runs with no answer, proposals refused (against B's coverage), first submissions rejected and what followed, calls, tokens and seconds used.

**Verification**
- The archive and its score; predictions scored.
- The results that would change the plan, each way: A as right as B (the tools are a convenience for this question, and M5's decisive comparison has to be asked on claims or on repair, not on single pairings); S as right as B (binding one element is a search, and the model's work lies elsewhere); a wrong acceptance (the check alone does not carry a proposal, and `propose` needs more than a place).

**Result so far** (2026-11-12; no model yet)

- *Sample and questions:* 10 figures by the rule (`bench/agent/pilot-figures.csv`; exts-030 in place of exts-021), 30 questions (`bench/agent/pilot-questions.csv`): bars, tiles and points, 21 on the seven figures that are not trees and 9 on the three that are.
- *Arm S,* predictions first (125-128: 4 right, one point guess wrong; 129: right):

  | Run | `propose` checks | Answer accepted | Right | Questions with another row accepted |
  |---|---|---|---|---|
  | `2026-11-12-1906-pilot-enumerate` | place | 30 of 30 | 23 of 30 (by figure 3, 3, 0, 3, 3, 3, 3, 2, 3, 0) | 7 (10 rows, all of another layer) |
  | `2026-11-12-1913-pilot-enumerate` | place and the leaf's layer (`7edf4fc`) | 30 of 30 | 30 of 30 | 0 |

- *Assumption 5 does not hold on this question:* with the layer given by code, trying rows finds every answer. Arm A against arm B is still to be measured; what a model adds here is nothing.
- Cost of the layer check: 108 lines added under `R/` and `tests/` (`R/propose.R` 32, `R/agent-tools.R` 3, tests 73), one host and one container suite run, two runs of the arm (about half a minute each). Moved: 7 of 30 questions from a wrong acceptance possible to none.

---

### Task 5b: The bundle's round trip on the development sets

**Status:** `[~]` (added 2026-11-12)

For every captured development figure, in the container: write the bundle, read it back, compare elements, tables and bindings with the figure written, and have one verified binding checked by `gl_propose()` on the figure read back. Reported per figure with the reason for each one that does not come back whole. Prediction first. What it decides: whether arm B can be served on every figure the bench captures, and what the codec must store, or leave out with a reason, before M5.

**Result** (2026-11-12; `bench/R/bundle.R`, `bench/R/score-bundle.R`; predictions 130-133 first: two right, one half right, one wrong)

- *Runs* `2026-11-12-1918-bundle-dev` (55 figures, 54 captured) and `-1926-bundle-dev-tree` (29, all captured), offline container, each figure written with everything embedded and with the default embedding, read back and compared.

  | | v0 development, 54 | tree development, 29 |
  |---|---|---|
  | cannot be written (either embedding) | 5: exts-021, gallery-048, exts-017, patchwork-010, patchwork-011 | 0 |
  | written and read back | 49 | 29 |
  | identical in every part, everything embedded | 44 | 29 |
  | differ | 5, in an empty list of tables only: gallery-052, gallery-056, exts-007, bioc-001, bioc-009 | 0 |
  | identical in substrate and derived tables, default embedding | 49 | 29 |

  By engine, written of captured: ggplot 56 of 59, patchwork 5 of 7, base 10 of 10, grid 4 of 4, heatmap 3 of 3.
- *Why 5 are not written:* a table holds something the codec has no case for: a `terms` attribute of type language, a list column of lists, a column of `SpatRaster`, `sf` geometries (two figures). The codec said which type and stopped the whole figure.
- *`gl_propose()` on the figure read back* (default embedding; up to 5 pairings a figure, verified at capture, one element for one row): ggplot and patchwork, 50 figures, 250 pairings: 222 accepted, 27 refused, 1 rejected; 44 figures with all accepted. Refused: four figures with polar or `sf` panels (20) and segments paired one per row (7). Rejected: one row on tree-014 that its geom moves while drawing, the gap Task 2 counted. Base and heatmap, 11 figures, 55 pairings: 47 refused and 8 rejected, the 8 being a heatmap's cell number answered as "outside the table" before the engine was refused.
- *Closed, each with a test that failed first* (`0296183`): a table is written without what the codec cannot store, with a warning that names each column or attribute, and comes back `partial_data` with `not_stored`; a figure without tables reads back identical; `propose` refuses another engine's figure before it looks at the row. Suite after: host 13 files / 148 tests / 1393 expectations / 0 failed / 0 skipped; container 13 / 148 / 1387 / 0 failed / 1 skipped.
- *What it decides:* arm B can be served every figure the bench captures once the rerun below confirms it; its coverage on ggplot and patchwork figures is what `propose` can check there, 222 of 250 sampled pairings, and the rest is refused with a reason. The bundle is lossless for what the codec stores and says what it left out.
- Cost: 140 lines added and 9 removed under `R/`, `tests/` and `man/` for the three fixes (`R/core-bundle.R` 57, `R/propose.R` 14 moved, tests 69, documentation 9), 177 under `bench/R/` (`bundle.R` 135, `score-bundle.R` 42); one host and one container suite run, two bench runs and a rerun.

---

### Task 6: Records

**Status:** `[ ]`

Design notes (§研究卡片, §评测设计, §审稿人预演, §实施计划), `NEWS.md` if anything exported changes, the dev log, closing notes with what M5 should be.

---

## Scope changes

_(append-only; never edit completed tasks above)_

- 2026-11-12 — **Task 1 is at ceiling, and the validation never fired.** **Evidence:** run `2026-11-12-1627-drive-tools`: 60 of 60 correct, in the masked variant too; 0 rejected submissions in 60 runs; three masked runs skipped `to_data` and worked the data values out from the scales themselves, and two lookup runs skipped the binding tool. **Effect:** (a) Assumption 3 is sharper than written: on a plain scatter plot with one layer the masked question does not separate anything, so condition A can be expected at ceiling there as well. Task 5's questions are drawn from figures where a first answer can be wrong: several layers on one panel, rows that tie in position, facets with free scales, a stat layer whose rows are not the data's, coords that are not linear, and elements code leaves unbound. The rule for choosing them is fixed before any run. (b) Task 5 reports, per condition, how many first submissions were rejected. If none is, the arms with and without validation cannot differ and the pilot says so instead of reporting a null. (c) Task 3's tools start from what the models did here: an `overview` that carries the scales (57 of 60 runs called it, 50 as their first call), element lookup by place, rows by number and by value. `to_data` and `get_binding` were skipped by models that could do without them. (d) A repeat is not a copy at temperature 0 (the same tool path in 16 of 30 pairs), so repeats per configuration are needed for the pilot's spread, as design §评测设计 has it. (e) All three models stay in; none is dropped on this evidence.

- 2026-11-12 — **Task 2: `propose` rests on the figure alone where the panel says how; elsewhere it refuses, and one case has to be closed first.** **Evidence:** runs `2026-11-12-1711-alone-dev` and `-1722-alone-dev-tree`; the Result of Task 2. **Effect:** (a) Task 3's `propose` validates a pairing with `place_rows()` and the binder's comparisons. No table of placements is stored at capture now: the threshold that would have asked for one was not met on either set, and it would cost bundle size on every figure (ADR-0007's evidence on size). (b) Before `propose` is built, a flipped panel must not be placed as if it were not: under `coord_flip()` the figure alone puts rows thousands of pt away and would reject a right pairing with that distance as its reason (32 elements in 2 figures). Task 3 starts with a test that fails for this; either the panel table says which of the plot's scales is horizontal, which is ggplot2's own contract (ADR-0009), or `place_rows()` refuses such a panel with the reason. (c) Where the figure alone cannot place rows (polar and `sf` panels, 247 elements in 5 figures; base polygons and paths; heatmap cells; the two draw-time rules), `propose` refuses and says why. It never accepts unchecked. Such a refusal is not a wrong answer and not a right one: Task 5 counts it against condition B's coverage and reports it by kind. (d) Storing placements for those panels only (the plan's "second form") stays open and is decided by what the pilot shows it would buy; the three circular trees of the tree set are the case to watch, since circular trees are what the owner's lab draws. (e) The mutation used here leaves a claim unchanged for an element that draws a whole group; Task 3's test of `propose` permutes pairings between elements, not rows within one.
- 2026-11-12 — **The models stopped answering, and the bundle refused one figure of ten.** **Evidence:** (1) the first launch of step 4's run ended its first request after 120.3 s with an error; a one-word request without tools got 502 from the gateway for all three models (the models' upstream closed the connection), and still did an hour later. No model output was seen; predictions 120-123 stand. (2) `bench/runs/2026-11-12-1853-material-pilot.csv`: `gl_write()` stops on exts-021 ("Cannot store a vector of type \"language\""): the plot's data is a fitted model, and its raw table carries the model's `terms` as an attribute. No bench run had ever written a bundle; the bundle's round trip is tested on hand-built figures only. **Effect:** (a) step 4 and the model arms of Task 5 wait for the models; everything that needs none is done first, and the pilot's harness appends each run to its archive and takes up where it stopped, since an outage in the middle would otherwise cost hours. (b) exts-030 stands in for exts-021 by Task 5's rule. (c) A figure whose bundle cannot be written cannot be served to an agent on the host at all, so the bundle's coverage on the development sets is a number arm B rests on and nobody has: it is measured (write, read back, compare, check one binding) before M5 is sized. Tracked here as Task 5b.

- 2026-11-12 — **Place alone does not carry a proposal: the arm without a model shows `propose` accepting a row of another layer.** **Evidence:** run `2026-11-12-1906-pilot-enumerate`, predictions 125-128 (4 right, one point guess wrong): the answer is accepted on 30 of 30 questions and no other row of its own table is; on 7 questions (3 of 10 figures: exts-030, tree-062, tree-077) a row of another layer is accepted too, 10 rows in all, 5 of them as `verified`. Two layers draw at one place: a second layer over the same rectangles, a tree's branches ending at the nodes its points sit on. **Effect:** (a) Before any model is asked, `gl_propose()` rejects a row of another table than the one the element's leaf was drawn from, where the figure says which that is. It does: the engine reads each leaf's layer from the plot's own structure at capture (ggplot2's contract, ADR-0009) and the bindings in the figure keep it, also for leaves it could not bind. Where the figure holds no bindings the check rests on place alone, and an acceptance says so. Tests first. (b) This is the rule of design principle 2 applied to the check itself: which layer drew an element follows from the drawing system's contract, so code says it and no model is asked to guess it. (c) The arm without a model is run again after the change, with a prediction first. (d) Assumption 5 gets sharper: with the layer given by code, trying every row finds the one answer on these questions, so on single pairings in panels with linear scales a model has nothing to add to code. The pilot still measures arm A against arm B, because that comparison is about what the substrate saves a model, not about whether a model is needed.

## Closing notes

Filled in when the plan moves to `done/`.
