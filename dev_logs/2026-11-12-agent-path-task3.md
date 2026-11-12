# 2026-11-12 — `gl_propose()`, `gl_tools()`, and the pilot made ready while the models were down

- **Related plan:** [plan/2026-11-12-agent-path.md](../plan/2026-11-12-agent-path.md) (active: Task 3 steps 1 to 3 done, step 4 waiting for the models; Task 4 steps 1 and 2 done; Task 5 has its material, questions, dry run and the arm without a model, and waits for the models; Task 5b added). [plan/2026-11-11-m1-roles-and-binding.md](../plan/2026-11-11-m1-roles-and-binding.md) (one scope change: the leaf verified on no result, fixed).
- **Related ADRs:** [ADR-0007](../dev_docs/decisions/0007-derived-tables-of-the-substrate.md) (the bindings in the figure, which `propose` now reads a leaf's layer from), [ADR-0009](../dev_docs/decisions/0009-package-behaviour-enters-as-a-checked-proposal.md) (what code says and what a proposal may say).
- **Worked on by:** Claude, after the owner's "支持，你的判断准确" on going on with the agent-path plan. Another session committed figures and dev logs on the same branch meanwhile (`1e22e10`, `18e9557`); no file of this log's work was touched by it.

Continues [the Task 2 log](2026-11-12-agent-path-task2.md), whose last section ended with "Task 3, step 2: `gl_propose()` with no model".

## What changed

| Commit | What |
|---|---|
| `79cfaa0` | `gl_propose()`: a pairing as data, checked from the figure alone; three outcomes (`R/propose.R`, 7 tests) |
| `d241114` | `gl_tools()`, `gl_tool_state()`: nine tools for aisdk, one of them `propose`; aisdk and R6 in `Suggests` (`R/agent-tools.R`, 6 tests) |
| `60c34ae`, `a2b1840` | Task 1's questions through `gl_tools()`: harness, predictions 120-123, and a launch that measured nothing |
| `a5de050` | Binder fix: a leaf passes only on a result for every element (2 tests first) |
| `d9dd27e`, `a90d661`, `11a2615` | Prediction 124, the two development bind reruns archived, then scored |
| `0def04f`, `641a942` | Condition A's sandbox, the material writer and its hook in the bench worker, the pilot's sample and harness |
| `c6db263`, `a3c352d`, `d7b2651`, `5ba7cca` | Predictions 125-128, the pilot's material and 30 questions, the arm without a model archived, then scored |
| `22ff88b`, `7edf4fc`, `e99f4b3` | Prediction 129; `gl_propose()` uses the layer the figure states for a leaf (3 tests first); the arm without a model run again and archived |

No change to capture. The binder changed in one place (the fix). `bench/R/runner.R` gained an optional hook that hands the figure to a writer; with no writer it does nothing.

## Measured

**Suite** (`NOT_CRAN=true Rscript -e "devtools::test()"`; container: `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R`):

| At | Host | Container |
|---|---|---|
| start (`79cfaa0`) | 12 files / 135 tests / 1233 expectations / 0 failed / 0 skipped | the same, 0 errors |
| `gl_tools()` (`d241114`) | 13 / 141 / 1278 / 0 / 0 | 13 / 141 / 1272 / 0 failed / 1 skipped |
| binder fix (`a5de050`) | 13 / 143 / 1296 / 0 / 0 | 13 / 143 / 1290 / 0 / 1 skipped |
| layer check (`7edf4fc`) | 13 / 146 / 1357 / 0 / 0 | 13 / 146 / 1351 / 0 / 1 skipped |

The container's one skip is the scripted-model test of `gl_tools()`: aisdk is not in the container's image. So the aisdk wrapper has run on the host only; `tool_specs()`, which does the reading, runs in both.

`R CMD build --no-build-vignettes .` and `R CMD check --no-manual` on the tarball (host, at `0def04f`): Status OK, no error, warning or note. It had not been run since Task 6a.

**`gl_propose()` and `gl_tools()`** (hand-built figures; mechanisms, not coverage): results are in the plan under Task 3, steps 2 and 3. `bench/agent/drive-gl-tools.R --dry`, no model: all five of Task 1's questions reach their checked row through `gl_tools()` in both variants, a wrong row rejected and the right one accepted.

**The run with models (step 4): not made.** The first launch ended its first request after 120.3 s with an error and no tool call. A one-word request with no tool got 502 from the gateway for all three models, about 38 s each, and again an hour later. The gateway and its model list answered; the models behind it did not. I stopped the script; no model output was seen and no archive was written. Predictions 120-123 stand unscored.

**The binder fix.** Two tests written first, both failing on the old code: a boxplot of one box with one outlier, whose outlier leaf came out `verified` with 0 verified elements and an element of status `NA`; and a comparison that returns nothing, or `NA`, for a scatter plot's 32 points (the `NA` case stopped the whole figure's bindings with an error). Reruns of the bind step on both development sets, prediction 124 first: `2026-11-12-1840-bind-dev` and `-1848-bind-dev-tree` against `-1116` and `-1107`: 7114 and 595 leaves, 0 changed. The held-out set was not rerun; the change is reported as made after looking at a held-out result.

**The sandbox** (`Rscript bench/agent/sandbox.R --dry`): 14 checks pass. No network; no key, token or proxy of the host; no repository; nothing writable outside `/work` and `/tmp`; time and memory limits, each told apart in what the code is handed back; a call with ggplot2 loaded takes about 1 s with the container's start. Every pilot figure's own code runs there: 0.7 to 55.2 s.

**The pilot's material and questions** (development figures; containers offline). Population: 29 of 66 ggplot and patchwork development figures have circles or rectangles bound one for one row and verified. Sample: 10 by stratum, seed 20261113. Material written for 9 of the 10; the tenth's bundle could not be written (below) and the next of its stratum stands in. Of 6493 such elements in the 10 figures, 0 are at another place in svglite's own page than in gloss's scene, and 3 are not alone at their place. 30 questions. Dry run, no model: for all 30 the answer is in arm A's material, arm B finds the element at its place with its binding hidden, and `propose` accepts the answer on the figure read back from a bundle written on Linux and read on macOS.

**The arm without a model** (`bench/agent/pilot.R enumerate`, every row of every built table proposed; predictions 125-128, 4 right with one point guess wrong):

| Run | `propose` | Answer accepted | Right (the answer and nothing else) | By figure, of 3 |
|---|---|---|---|---|
| `2026-11-12-1906-pilot-enumerate` | by place | 30 of 30 | 23 of 30 | 3, 3, 0, 3, 3, 3, 3, 2, 3, 0 |
| `2026-11-12-1913-pilot-enumerate` | place and the leaf's layer | 30 of 30 | 30 of 30 | 3 on each of the 10 |

26265 proposals took 34 s in the first run. The 10 other rows accepted there are all rows of another layer drawn at the same place, 5 of them as `verified`; none is in the answer's own table.

**Not run:** any model, in any arm; any held-out figure; aisdk 1.4.12, the version on CRAN (the host has 1.5.0); the bundle on development figures other than the pilot's ten.

## Surprises

- **The models behind the gateway went down between Task 1's run and this one.** The owner's free models are the only models this plan uses, and nothing here can restart them. → plan, Scope change of 2026-11-12: what needs no model was done first, and the pilot's harness appends run by run and resumes under its stamp, with one more attempt for a run that ended in a request error.
- **The bundle refused one of ten sampled figures, and no bench run had ever written a bundle.** `gl_write()` stops on exts-021: the plot's data is a fitted model and its raw table carries the model's `terms`, which the codec cannot store. The error names the type and not the table. Every earlier statement that a bundle is lossless rests on hand-built figures. → plan, Task 5b: the round trip measured on both development sets before anything else is built on bundles; a figure that cannot be written cannot be served to an agent on the host.
- **`propose` accepted rows of the wrong layer.** I wrote the check to ask one thing, whether the row lands where the element is. Two layers draw at one place more often than I guessed: a second layer over the same rectangles (exts-030, all 3 questions), a tree's branches ending at its points (tree-077 3 of 3, tree-062 1 of 3). 7 of 30 questions, 3 of 10 figures. An agent in arm B could have been told "accepted, verified" for a wrong table. → fixed test-first before any model is asked: the figure knows each leaf's layer from the plot's structure, and a row of another table is rejected with that reason; a figure without bindings is checked by place and says so. Plan, Scope change of 2026-11-12.
- **Code alone answers every pilot question once the layer is given.** That is assumption 5 of the plan coming true on this kind of question. → plan, Scope change (d); it decides what M5 asks, and goes into the closing notes.
- **My point guess for prediction 127 read the sample's table wrongly.** The table counts layers whose elements are bound one for one row; I took "1 table" to mean a figure with one layer. exts-030 has a second layer over the same rectangles. → nowhere in the code; `bench/predictions.md` says so.
- **The binder defect had a second half that no run had shown.** Writing the general test, a comparison that returns `NA` did not pass the leaf: it stopped the figure's whole binding with an error. And my first version of that test mocked a comparison the scatter plot does not use (its points state a shape, so they go through the symbols' comparison); the fix did not turn it green, which is how I saw it. → fixed before the commit; the test was then run against the unfixed binder to see it fail for its own reason.
- **The sandbox called a memory kill a timeout.** bioc-016's code, a 223-line vignette, was killed at 2 GB after 12 s and the sandbox reported "ran longer than 60 s". A model would have been told to wait longer. → `641a942`: 6 GB, two minutes a call, and the two endings told apart; a check for it in the self-check.
- **Another session committed during a bench run again** (`18e9557`, during the v0 rerun). Both reruns loaded one source snapshot, and the archive commit says what happened. → still with the owner: two sessions on one branch.

## What's next

- **When the models answer:** step 4's run (predictions 120-123 are committed), then the rehearsal of both arms on a hand-built figure, then predictions for arms A and B and the 540 runs of the pilot (30 questions, 3 models, 2 arms, 3 repeats).
- **Without models:** Task 5b, the bundle's round trip on both development sets, with a prediction first; then whatever it shows the codec must store or leave out with a reason.
- **For the closing notes of this plan:** on single pairings in panels with linear scales, code finds the answer by trying rows. M5's decisive comparison has to be asked where code cannot enumerate: a leaf the engine could not bind, a table that has to be found in the figure's code, or a claim about the figure.
- **Waiting on the owner:** pull request 1; reading ADR-0007; when to push `feat/agent-path`; how two sessions share the branch.

## Later the same session: the bundle on real figures, and the models back

Added after the log above was committed (`bb1ef3e`); nothing above is changed.

### What changed

| Commit | What |
|---|---|
| `a61221f`, `4688958`, `579f9cb`, `94aee29` | Predictions 130-133; `bench/R/bundle.R` and the worker's hook made general; the round trip on both development sets archived, then scored |
| `dde855f` | Predictions 134-139 for the pilot's arms with a model, written while the models were down; dated notes in the design doc for `gl_propose()` and `gl_tools()` |
| `dae3966`, `09a6586` | A note beside predictions 120-123 on what changed in the tools since; the step 4 harness waits for a model that is down and makes a run that ended in a request error once more |
| `3b387eb`, `0296183` | Predictions 140-141; three fixes, each with a test first: tables written without what the codec cannot store, a figure without tables read back identical, `propose` refusing another engine before it looks at the row |
| `b05db60`, `2f5d37f` | Task 1's questions through `gl_tools()` with the three models: archived, then scored; Task 3 done |
| `1dc039f`, `5ab9c4d`, `68a6fe9`, `fcbe9a7`, `cfbbdc7`, `9e29cfd` | The round trip rerun and scored; the `sf` fix with two tests first; prediction 142; the third run archived and scored; Task 5b done |
| `a821000`, `2f0a3a2`, `307762e` | The pilot's harness waits for a model that is down; then its own plain loop for both arms, after a rehearsal that aisdk's loop invalidated; a reproduction of what aisdk does to tool arguments |

### Measured

**Suite** after `0296183`: host 13 files / 148 tests / 1393 expectations / 0 failed / 0 skipped (was 13 / 146 / 1357); container 13 / 148 / 1387 / 0 failed / 0 errors / 1 skipped (aisdk). After `68a6fe9`, the last change under `R/` or `tests/` of the session: host 13 / 150 / 1422 / 0 failed / 0 skipped; container 13 / 150 / 1416 / 0 failed / 0 errors / 1 skipped.

**The bundle's round trip** (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bundle.R dev` and `dev tree`; runs `2026-11-12-1918-bundle-dev`, `-1926-bundle-dev-tree`; predictions 130-133: two right, one half right, one wrong). 83 of 84 development figures are captured. 5 cannot be written, all on v0, under either embedding; the 78 written are all read back; with everything embedded 73 are identical in every part and 5 differ in an empty list of tables; the tree stratum's 29 are identical. On the figures read back, `gl_propose()` accepts 222 of 250 sampled verified pairings on ggplot and patchwork figures, refuses 27 and rejects 1; on base and heatmap figures it refused 47 of 55 and rejected 8. The table by set and the reasons are in the plan under Task 5b.

**The round trip again, twice** (v0's development set; a prediction before each). Run `2026-11-12-1938-bundle-dev` after the three fixes (predictions 140-141: one wrong, one right): 52 of 54 written, not all; the 5 figures without tables identical; the 8 false rejections on heatmaps refusals; no other count moved on the figures written before. Run `2026-11-12-1957-bundle-dev` after the `sf` fix (prediction 142: right): 54 of 54 written under both embeddings; 49 identical with everything embedded, 5 differing in their partial tables and the status that lists them; 54 identical in substrate and derived tables under the default embedding. With the tree stratum: all 83 captured development figures are written and read back, 78 identical in every part.

**Task 1's questions through `gl_tools()`** (`Rscript bench/agent/drive-gl-tools.R`, host, run `2026-11-12-1927-drive-gl-tools`; predictions 120-123: four right, one of them for another reason than I gave). 60 of 60 runs right, 10 of 10 for each of the three models in each variant; 0 failed calls of 308; no proposal rejected or refused; median 5 calls, 8.7 s and 10104 tokens a run. One hand-built figure and five questions: the tools work in a model's hands. Through aisdk's own loop.

**The rehearsal of the pilot's two arms** (`Rscript bench/agent/pilot.R rehearse`, a hand-built two-panel scatter plot that is not in the pilot, two questions, one run each; not a pilot result).

| Archive | Loop | Arm A (material and sandbox) | Arm B (`gl_tools()`, bindings hidden) |
|---|---|---|---|
| `2026-11-12-1942-pilot-rehearsal` (2 models, stopped by me) | aisdk 1.5.0 `generate_text()` | 2 of 4 right; 28 failed calls of 83, 21 of them "undefined columns selected"; 2 runs ended "blocked"; 12 to 38 steps; up to 546191 tokens | 4 of 4 right; 5 or 6 calls |
| `2026-11-12-2008-pilot-rehearsal` (3 models) | the harness's `tool_loop()` | 6 of 6 right; 4 failed calls of 68, none of that kind; 7 to 15 calls; 19 to 147 s; 28603 to 102804 tokens | 6 of 6 right; 4 to 10 calls; 6 to 27 s; 8825 to 26041 tokens |

The first row is not a measurement of arm A (Surprises). `Rscript bench/agent/pilot.R dry`, no model: the loop hands a tool its arguments as written, sends answers and turns back unchanged, adds up usage and stops at 16 requests; all 30 questions pass as before. `Rscript dev_docs/research/aisdk-args/repro.R`: 3 of 7 valid arguments are changed by aisdk's parser before a tool would see them.

**The sandbox's memory.** The heaviest pilot figure's own code (bioc-016) peaks at 3.3 GB resident in the sandbox (one run); the Docker VM has 11.7 GB. So at most two models run the pilot at once.

**Not run:** the bundle reruns on the tree stratum (nothing that changed touches a figure that was written and has tables); aisdk 1.4.12; any held-out figure. The pilot's arms A and B: started at the end of this session (below); no result in this log.

### Surprises

- **5 of 83 figures could not be stored, and the codec's answer was to stop.** It named a type and not a table, and one column of geometries cost the whole figure. I had read "lossless" as a property the tests showed; they showed it on figures whose tables hold only what the codec stores. → `0296183`: left out, named, warned about; design §内嵌哪些数据 now says the bundle is lossless for what the codec stores. Not an ADR: nothing that was stored before is stored differently.
- **A figure with no tables was the one I had not thought of.** Five grid and base figures came back differing, and the difference was an empty list's empty names. No value lost, and a comparison by `identical()` is what found it. → fixed with a test; prediction 131 scored half right.
- **I predicted 95% acceptances and named, in the same sentence, the refusals that make 95% impossible.** Base and heatmap figures are refused whole by design. → `bench/predictions.md`; the number that means something is the one on ggplot and patchwork figures, 222 of 250.
- **`propose` rejected a heatmap's own binding as "outside the table".** The binding's row is a cell of the matrix; the range check ran before the engine's refusal. A rejection with a false reason again, the kind Task 2 found for flipped panels. → fixed with a test: the engine is refused first.
- **`[` does not always take a column out.** My first fix left a column out by name. On an `sf` table the geometry stays whatever columns are asked for, so two figures still could not be written, and my prediction that all would be was wrong. Two of my five predictions about the writer failed on what a base operation does to an object I had not pictured (an empty list, an `sf` frame). → `68a6fe9`, two tests first; such a table is stored as a plain data frame and says so. Had a figure still failed, the plan's branch was an ADR on what a table may hold; it did not come to that.
- **aisdk rewrote the R code a model sent to the sandbox.** In the rehearsal, `d[i, ]` arrived as `d[i]`: 21 of arm A's 28 failed calls. One model spent calls testing whether `[` had been redefined. aisdk 1.5.0 repairs a tool call's arguments with regular expressions before it tries to parse them as they are, and the expressions act inside strings. Arm B's arguments are numbers and names and were untouched, so the comparison would have been between a sandbox with a broken keyboard and tools without one. I found it by reading the transcripts before trusting the scores; the scores alone (A 2 of 4, B 4 of 4) looked like the result I had predicted. → plan, Scope change of 2026-11-12: the pilot's loop is the harness's own, checked without a model; `dev_docs/research/aisdk-args/repro.R` for the owner, whose lab maintains aisdk. Not worked around under `R/`: gloss owns no loop and has no tool that takes free text yet; design §风险 should carry it when such a tool is added.
- **aisdk's `max_steps` is not a limit.** It is a window; the runtime then asks the model whether to go on (up to 8 windows), asks again after a tool's error, and ends a run as "blocked" when a call repeats. Runs took 17, 20 and 38 steps under `max_steps = 16`, one used 546191 tokens, and one was ended with the right answer in its text and no submission. The budget I had written in the plan described a loop that did not exist. → the same Scope change: 16 requests a run is now what is enforced, for both arms.
- **A binding that is disclosed is not read.** In step 4, 28 of the 30 runs that could have asked for the element's binding worked the row out instead, and were right. The question's wording ("work out the row") may have invited it. → nowhere yet: the pilot hides bindings anyway; it matters for what a later stage is told to read first.
- **The models came back unevenly.** After about an hour of 502, two answered and the third answered 429 ("too many concurrent requests"). → `09a6586`: the harness asks a model for one word before its runs and waits; the pilot's harness already resumes.

### What's next

- **The pilot's 540 runs** (30 questions, 3 models, 2 arms, 3 repeats; predictions 134-139 committed; the harness resumes under its stamp): started after this log, two models at a time. Scored with `bench/agent/score-pilot.R` when the last run is in, per figure and per model before any pooled share; transcripts of arm A are read before the scores are believed.
- **Then Task 6:** the closing notes of the plan. What they already have to say: on single pairings in panels with linear scales, code finds the answer by trying rows once it knows the leaf's layer, so M5's decisive comparison has to be asked where code cannot enumerate (a leaf the engine could not bind, a table that has to be found in the figure's code, a claim about the figure); a figure's bundle now always exists but may lack what the codec cannot store; and the loop that runs an arm has to be shown not to touch what a model sends.
- **aisdk:** the reproduction is in `dev_docs/research/aisdk-args/`. Whether to report it upstream, and whether gloss should ask for a fixed version before its own tools take free text, is the owner's call.
- **Waiting on the owner:** pull request 1; reading ADR-0007; when to push `feat/agent-path` (not on the remote; 58 commits since `8835020`, four of them another session's: `34f13b0`, `d3ae23c`, `1e22e10`, `18e9557`); how two sessions share the branch.

## Later still: while the pilot's runs were being made

The pilot's 540 runs were started at 20:19 UTC from a clean tree at `83b398b`, two models at a time (stamp `2026-11-12-2019`). Nothing under `R/`, `tests/` or the pilot's harness was touched while they ran.

### What changed

- `c73e831`, `8527cd6`: two additions to `bench/agent/score-pilot.R` (65 lines), written before any run of the pilot was scored. The paired difference by figure (B's share right minus A's), its mean, sd and a 95% interval from drawing the figures again (10000 draws, seed 20261113), for all models and for each, with what a question cost in A over what it cost in B. And the tool calls that failed, by what the tool answered.
- `eed40df`: a dated note in design §评测设计: the loop both conditions share is a factor to control.

### Measured

- `R CMD build --no-build-vignettes .` and `R CMD check --no-manual` on the tarball (host; the package's files are those of `68a6fe9`, `git diff --stat 68a6fe9 HEAD -- R tests man inst DESCRIPTION NAMESPACE` is empty): Status OK, no error, warning or note.
- The scorer's additions, no model. On a synthetic archive of 3 figures, 2 models and known answers the printed differences (+0.00, +0.50, +0.75; mean +0.417, sd 0.382; by model +0.333 and +0.500) are the ones computed apart from the scorer. On the two rehearsal archives the failed calls come out as they were counted by hand: `-1942` (aisdk's loop) arm A 28 of 83, 21 of them "undefined columns selected"; `-2008` (the harness's loop) 4 of 68, four different messages; arm B none in either. No line of the saved score of `-2008` changes.
- **Not run:** the suite (nothing it tests changed); the scorer on the pilot's own archives, which are scored once, after they are complete and committed.

## The pilot's result, and the plan closed

The agent-path plan is closed and moved to [`plan/done/2026-11-12-agent-path.md`](../plan/done/2026-11-12-agent-path.md); this section is its closing log. The header of this file gives the plan's old path and state, as they were when the file was opened.

### What changed

| Commit | What |
|---|---|
| `fe14fb4`, `bd868f0` | the pilot's three archives, 180 runs each, committed unscored |
| `63d89bc` | `bench/agent/show-run.R` (60 lines): the transcript of archived runs, by model, arm, figure, question and outcome |
| `7827849` | `bench/runs/2026-11-12-2019-pilot-score.txt`; predictions 134-139 scored |
| this commit | the plan's result for Tasks 5 and 6, a scope change, closing notes, and the move to `plan/done/`; `plan/README.md`; the design doc; this section |

Design doc: a new subsection for the pilot (§评测设计, `#sec-pilot`) with its table and what it cannot show; a dated note under the research card; three bullets in the paragraph on models and budgets (the harness's own loop, reporting against the budget used, reading transcripts before believing a score); seven rows of the reviewer table rewritten and one added; two risk items; a dated note under the milestones; a change-list entry. The notes this plan had appended by date were folded into their sections as the current state: the status paragraph, the paragraph on proposals, the tools (with a table of the nine that exist) and the bundle's round trip. Nothing under `R/`, `tests/` or `man/` changed in this part of the session.

### Measured

**Suite** (`NOT_CRAN=true Rscript -e "devtools::test()"`, host): 13 files / 150 tests / 1422 expectations / 0 failed / 0 skipped at the end of the session, as at `68a6fe9`, the last change under `R/` or `tests/`. The container suite was last run at `68a6fe9` (13 / 150 / 1416 / 0 failed / 0 errors / 1 skipped), and nothing it loads has changed since. Session, start to end: 12 files / 135 tests / 1233 expectations to 13 / 150 / 1422.

**The pilot** (stamp `2026-11-12-2019`; 10 development figures, 30 questions, 3 models, 2 arms, 3 repeats; temperature 0; 16 requests a run; a pilot, not a reported number). Made 20:19 to 22:13 UTC, two models at a time; no request error, no run made twice. Scored once, after all three archives were committed: `Rscript bench/agent/score-pilot.R 2026-11-12-2019 bench/runs/2026-11-12-1913-pilot-enumerate.csv`.

| Arm | Runs | Right | Wrong | No answer | Median run |
|---|---|---|---|---|---|
| A: raw material and a sandbox | 270 | 246 (91.1%) | 6 | 18 | 9 calls, 28.0 s, 44094 tokens |
| B: `gl_tools()`, bindings hidden | 270 | 269 (99.6%) | 0 | 1 | 7 calls, 9.4 s, 14108 tokens |
| S: no model | 30 questions | 30 | 0 | 0 | 26265 rows tried, 29.7 s in all |

- By figure (right runs of 27, A then B): bioc-016 27, 27; exts-027 18, 27; exts-030 27, 27; gallery-002 26, 26; gallery-005 24, 27; gallery-029 21, 27; patchwork-006 26, 27; tree-062 23, 27; tree-068 27, 27; tree-077 27, 27. B above A on 5 figures, A above B on none. B minus A over figures: +0.085, sd 0.117, +0.022 to +0.159 when the figures are drawn again.
- By model (right of 90, A then B): Qwen3.8-27B 89, 90; deepseek-v4.1-flash 83, 90; glm-5.3-flash 74, 89. The difference over figures is +0.011, +0.078 and +0.167.
- By the tool call at which the answer was in (A, B, of 270): by the 8th 104, 236; the 10th 165, 267; the 16th 244, 269.
- Arm B's proposals: 275; 270 accepted, each the answer for the element asked about; 5 rejected; 0 refused; 0 wrong acceptances.
- Cost: 211 minutes of model time; 17.8 million tokens (A 13.7, B 4.1), 94% of them prompt tokens. A's median run is 3.0 times B's in seconds and 3.1 times in tokens.
- Predictions 134-139: 1 right, 2 half right, 3 wrong.

**Read before the shares were believed** (`show-run.R`, the scorer's list of failed calls, and scripts kept outside the repository). Arm A: 161 of 2701 calls failed, none a timeout or a kill (2361 sandbox calls, median 0.44 s, at most 2.05 s); 296 calls reached the sandbox with a comma before `]`, so the loop hands code over as written. Arm B: 3 failed calls of 1847; 168 runs asked for the binding and each was told it is hidden; no tool's answer held a binding. All 18 of A's runs without an answer ended at the 16th request with nothing submitted. Each of A's 6 wrong answers was one submission, in the answer's own table.

**The design doc.** `quarto render dev_docs/design.qmd --to html`: exit 0, no unresolved reference. `fact_diff.py` between the doc before and after: three facts had dropped out in the folding (the dates of the first probe runs, a token count, a run's name) and were put back; what is still missing is a pointer to predictions 140-141, one count that the text now gives as its complement, and the earlier of two runs with the tools, each replaced by the later state and all still in the plan. `tell_scan.py` on the added lines: no strong or medium candidate.

**Not run:** the container suite (see above); the two missing arms of the 2 by 2; arm A with a larger budget; any held-out figure; any model newer than the three free ones.

### Surprises

- **Condition A was far stronger than I predicted, three times.** I wrote 45%, then 60% after the first rehearsal; it is 91.1%, and 98.9% for one model. My picture of A came from a rehearsal that a faulty loop had spoiled and from doubting that these models could find one rectangle in a 1.9 MB SVG within 16 requests; they could, in 21 of 27 runs on that figure. Three of six predictions were wrong, all in this direction. → `bench/predictions.md`; the plan's scope change of 2026-11-12 (the pilot); design `#sec-pilot`, the note under the research card, a risk item.
- **The size of the gap is set by the budget and the model, not only by the condition.** By the 8th call A has 104 answers in and B 236; at the limit 244 and 269, and A is still rising. One model shows a difference of one run in 90. A single number at one limit would have been read as a property of the substrate. → design §评测设计 (report against the budget used); closing notes (A again at twice the requests).
- **What I predicted for B's bars happened and did not matter.** `find_rows` put the bar's row 7.26 pt from the place asked about; the models proposed the nearest row and it was accepted. → `bench/predictions.md`; nothing changes in the tools.
- **The only run of B that failed never looked the element up by its place.** It read elements one id at a time until its requests ran out, after one rejected proposal for the wrong element. → nowhere yet: one run in 270, and changing a tool's description after seeing which runs fail is tuning on the result.
- **A model gave a row's name for its number.** One figure's built tables keep row names that are not 1 to n; `tables.rds` has no `row` column while the CSV files do, as the prompt says. 16 failed calls asked for that column and 3 of A's 6 wrong answers are on that figure. An ambiguity of ours in the baseline's material. → closing notes (fixed before any reported run); design `#sec-pilot` under what the pilot cannot show.
- **One model kept opening a file the material does not hold.** The frozen code's header comment says "see meta.json"; 21 calls of one model tried to read it. A request lost in each of those runs. → closing notes, with the material's other fix: the header line is left out of condition A's copy of the code.
- **The third model's runs record another commit.** I committed the scorer and two documents while the first lane ran, and the second lane's next process read `HEAD` when it started. Nothing a run loads differs between the two commits (checked with `git diff --stat` on those paths), but the archive could not have shown that by itself. → what's next: the harness records a digest of the files it loads, as the bench's workers do since `57fc97b`, and nothing is committed while a run is being made.

### What's next

- **For the owner to decide:** the next plan toward the main claim. Recommended in the closing notes: the thinnest path for claims (a few check primitives, a `propose` for claims, a pilot with this harness), before M5 is sized; the alternative is the record core of M2. Whether the research card's main claim is reworded for bindings (a dated note is under it; the card's text is unchanged).
- **Before any reported run with models:** the two missing arms of the 2 by 2; the material for condition A says a row's number the same way in both kinds of file and drops the header line that names a file it does not hold; a population that includes pairings `propose` refuses; a digest of what the harness loads in each archive.
- **aisdk 1.5.0:** the reproduction is in `dev_docs/research/aisdk-args/`; reporting it upstream is the owner's call.
- **Still waiting on the owner:** pull request 1; reading ADR-0007; when to push `feat/agent-path` (not on the remote); how two sessions share the branch.
- **The M1 plan** is the one active plan: labels by annotator A, then Tasks 3, 4, 6b, 7 and 8.
