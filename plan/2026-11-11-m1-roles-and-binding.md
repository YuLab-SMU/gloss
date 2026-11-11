# M1, first slice: roles and bindings on the development set

> Status: active (opened as a draft; the owner settled its three open decisions on 2026-11-11, see Scope changes).
> Date opened: 2026-11-11. Owner: Yonghe Xia.

**Goal:** On the 54 captured development figures, every drawn element has a role given by a rule or is listed as residue with a reason; every element of a data-mark leaf is bound to rows with a verified status or listed unbound with a reason; and against labels written to a fixed guideline, no rule error goes without a flag.

**Why now:** The page-capture plan closed with the capture M1 binds to: 50 of 54 held-out figures equal to the page drawn, none captured as another figure ([closing notes](done/2026-11-11-page-capture.md#closing-notes), [dev log](../dev_logs/2026-11-11-page-capture-heldout.md)). The owner decided on 2026-11-11 not to run the held-out set again and to start M1 from these numbers. The closing log named the first M1 questions: binding through the call's arguments and `usr` for base figures, and what to do with leaves that have no expected count. Two of the milestone's claims have little or no evidence yet: classification rests on three hand-built figures (481 of 486 elements, design §分类), and binding on none (design §风险与未决问题, "base 图的数据绑定还没有验证"; §审稿人预演, "base 图能绑定数据吗？未决").

**Starting state (measured, 2026-11-11):**
- Suite at `6041c60`: 8 files, 67 tests, 438 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`).
- Development set, run `2026-11-11-0858` at `21988ee` (`bench/runs/2026-11-11-0858-capture-dev.csv`; sums of its columns over captured rows): 54 of 55 captured, 7113 leaves, 33297 elements. By engine (figures / leaves / elements): ggplot 31 / 4579 / 26352; patchwork 6 / 202 / 2295; heatmap 3 / 55 / 657; grid 4 / 234 / 1060; base 10 / 2043 / 2933.
- Expected counts on the same run: 6480 leaves `ok`, 59 `count_mismatch` (ggplot 41, patchwork 17, grid 1), 574 with no expected count, all of them base leaves (574 of 2043).
- All 10 base development figures reach gloss as recorded plots (`recovered = base`; `bench/R/runner.R` calls `recordPlot()`), so no `legend()` call is visible to gloss on the bench, only the `rect`, `segments`, `text` and `points` entries it draws.
- Leaf names (`Rscript bench/R/leaf-names.R bench/runs/2026-11-11-0858-capture-dev.csv`; the run lists names cut at 600 characters, so leaf shares are taken on the 41 figures listed in full): a generic own name `GRID.<class>.<n>` for 196 of 342 leaves on 24 ggplot figures and 55 of 55 on the 3 heatmap figures; base leaves are named by their call (0 of 2043). By element, over every listed leaf, generic names cover 1280 of 24266 ggplot elements (the large geom leaves are named), 1912 of 2162 patchwork elements and 654 of 654 heatmap elements. The cues the design names (`geom_point`, `axis-l`, `strip-t`, `z_heatmap_body_1_1`) sit in the leaf's path and viewport, not in its name. On a hand-built facetted ggplot, an `annotate()` text is `layout/panel-1-1…/panel-1.gTree.22/GRID.text.6`: only its position among the panel's children says which layer drew it.
- Roles in the package: none. Research rules (naming only, outside `R/`): 481 of 486 elements on three hand-built figures; on the page route the base figure gives the same 57 of 60, with the legend's `rect` and `segments` classified as data marks (`dev_docs/research/capture-fidelity/p6-base-classify.out`). Development set: never measured.
- Bindings in the package: none. Base fixtures: a call's x and y through `usr` land within 0.007 pt of the drawn points (`p5-base-fixtures.out`). ggplot, patchwork, heatmap: never measured.
- Labels: no role or binding labels exist for any bench figure.

**Assumptions to test (riskiest first):**
1. *Within a leaf, data-mark elements follow the order of their built rows, so an order binding can be checked by putting the rows back through the panel's scales.* No evidence: M0 had no binding. Tested in Task 2. The check knows a few geometry families (points, rects, segments, paths, polygons, text), not geoms. If families do not verify most data-mark elements, binding needs per-geom adapters, which is what the research card holds against maidr's 40 handlers; the claim that gloss binds layers nobody wrote a handler for narrows, and the plan is redrawn around the geoms that fail. Elements whose rows tie in position verify against more than one row and are reported as ambiguous, not as verified.
2. *Rules on the three cues classify most elements of unpicked figures, and what they leave falls into a few named classes* (annotation text, base legends, extension grobs). Evidence: three hand-built figures. Tested in Task 3 (coverage, no labels needed) and Task 4 (accuracy). If the residue is more than 10% of the elements of ggplot figures, or no handful of classes covers most of it, the residue is the agent's main work rather than a remainder; design §分类's headline and the first prediction of §评测设计 (condition C classifies almost all roles on ggplot figures) are rewritten from the number.
3. *A role belongs to a leaf;* kinds may differ inside it (a base `axis` entry draws a line, ticks and labels). Labels, rules and checks are keyed by leaf, with element exceptions allowed. Tested in Task 1: annotators may split a leaf. If more than 5% of leaves need a split, roles are stored per element and rules return element masks (Task 3 changes before it starts).
4. *Labels written to a guideline are reproducible.* Tested in Task 1's pilot: two annotators label the same 5 figures independently. If Cohen's κ on roles is below 0.8, the guideline is revised and the pilot repeated before the full labels count.
5. *Consistency checks turn rule errors into flags without flagging most of what is right* (a legend key matches a series' style; axis ticks are collinear; a data-mark leaf binds or is declared dataless). No evidence. Tested in Task 4. A rule error with no check that catches it gets a rule or a check (the development set is for tuning), or the criterion is restated with the evidence. If the checks flag more than 5% of correctly classified elements, a flag carries little information and the checks are redesigned: flagging everything would satisfy "no silent error" and mean nothing.
6. *Base data marks bind through their calls' arguments and `usr`, and the entries `legend()` draws can be told apart from data marks* on a recorded plot. Tested in Task 5. Two deterministic cues are available: the code, matched by order of calls (the same order alignment design §元素归属 rejects for capture, so it has to be checked, not trusted), and the page (a `rect` that encloses `text` and key marks). If neither separates the legend entries of the 10 development figures without error, base legends go to the residue with a reason, which the milestone allows, and are never bound as data. A `gloss(function)` input could trace `legend()` instead; the bench does not hand gloss functions.

**Architecture:** Rules become `rules` plugins, one per engine, registered in `.onLoad()` (the kind exists in `core-plugin.R` with `engine` and `rules`; its contract is a declaration check today and gets a contract that runs the rules on the engine's example). A rule reads the leaf table (path, viewport, class, panel), the engine's state (ggplot layers with geom, stat and `annotate()` origin; guides through `get_guide_data()`; the drawn `HeatmapList`) and the code context, and returns a role, a kind, the cue it used and the rule's id. Binding is an optional engine field (`bind`) that pairs data-mark leaves with rows of the engine's tables; verification by back-substitution lives in the core, so every engine's bindings are checked by the same code. During Tasks 2–5 both run as internal functions on a captured figure and the bench calls them: the figure object, the bundle format and the exported functions do not change until Task 6 settles where roles and bindings live. Not touched: capture, except `base_expected()` for data-mark calls in Task 5 (code that reads device output: the container suite applies); records, anchors and layers (M2); the held-out set.

**Out of scope:**
- Corrections as records (`gl_reclassify()`): they need the record core of M2, or a minimal one pulled forward (open decision 3).
- Any classification or binding run on the held-out set. Its two-person annotation protocol and predictions open the next plan.
- Semantic groups, relations other than legend key ↔ series and strip ↔ panel, the agent's residue stage (M4).
- General grid figures beyond what viewport and grob names give (4 development figures; their residue is reported, not worked on).
- Linking base arguments to the rows of the user's data frame: measured in Task 5 (how often the code names the columns), not built.
- Masks and mixed pages: refused as today.

**Tech stack:** R 4.5.2; ggplot2 (`ggplot_build()`, `get_guide_data()`), patchwork, ComplexHeatmap, grid, grDevices; svglite >= 2.2, xml2; the bench container of bench v0. Labels are CSV under `bench/labels/`.

**Done when** (all on the 54 captured development figures, package code, in the container):
- Labels: every captured figure labelled to the guideline; pilot κ on roles at least 0.8 (or a revised guideline and a repeated pilot); every label resolves to a leaf of the current capture, and a label that no longer resolves fails the run instead of being skipped.
- Roles: every element has a rule role or is residue with a reason. Against the labels: 0 rule errors without a flag; correct roles that are flagged at most 5% of correctly classified elements (provisional, revised by a scope change with its evidence); residue and accuracy reported by engine and role.
- Bindings, ggplot, patchwork, heatmap: every element of a labelled data-mark leaf is verified, ambiguous (ties), unbound with a reason, or in a count-mismatch leaf. A mutation that permutes rows within a leaf fails verification on every leaf it changes, apart from tied elements.
- Base: data-mark entries bound to their arguments and verified through `usr`; no entry labelled legend is classified as data without a flag (the milestone's base-legend criterion).
- Time for classification and binding reported at 10^3, 10^4 and 10^5 points; Task 6 decides from it whether they run at capture or on demand.
- Each number from a run archived in `bench/runs/`; predictions committed before the first run of each task; the suite passes with its counts at every commit that touches `R/` or `tests/`.

**Decisions (the owner's; all three settled 2026-11-11 as recommended, see Scope changes):**
1. *Who labels the development set.* (a) Claude labels all 54 figures from the rendered page and the leaf sheet, committed before any rule runs on the development set; the owner labels the 5 pilot figures independently for κ. (b) The owner labels all 54. (c) The owner and a second person label all 54, which is the protocol the held-out set needs anyway. Recommended: (a). The development set is for tuning; the held-out labels, which give the reported numbers, need two people whatever is chosen here. The cost of (a): the labeller also writes the rules, so a cue that misleads both (a base legend's `rect` read as data) can agree with itself. The pilot and the blind order (labels before rules) are the guard.
2. *Where rule roles and engine bindings live.* Appendix A has `gl_classify()` write into the `structure` layer and tbl-layers lists rules as a source of `structure` records, which needs M2's record core. Alternative: roles and bindings are derived tables of the substrate, recomputed whenever it is rebuilt and versioned by the plugin that made them, like leaves and panels; only what code cannot derive (corrections, agent fills, human notes) is a record, and queries lay records over the derived tables. Recommended: the second (principle 2: what code determines is recomputed, not stored as a claim; principle 4: a rebuilt substrate needs no rebase for its own derived facts). Settled by ADR-0007 in Task 6; until then nothing is exported.
3. *Corrections in M1 or M2.* The milestone puts the correction interface in M1. Recommended: move `gl_reclassify()` to the plan that builds the record core, and say so in design §实施计划 with a dated note; this slice gives the residue list and the flags it will correct.

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
- Suite: 8 files, 67 tests, 438 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-11, `6041c60`).
- Key numbers: none yet; see the starting state.

**Overall progress**
- [ ] Task 1: Role vocabulary, labelling guideline, pilot agreement, development labels _(decision 1(a): Claude labels, the owner labels the pilot)_
- [ ] Task 2: Order binding for grid-page engines, verified by back-substitution
- [ ] Task 3: Rules as plugins; coverage on the development set
- [ ] Task 4: Accuracy against the labels; consistency checks; silent errors
- [ ] Task 5: Base figures: bindings through arguments and `usr`; legend entries
- [ ] Task 6: Where roles and bindings live (ADR-0007); public API _(stub; written out after Tasks 2–5)_
- [ ] Task 7: Structure tree, data tree and their mapping _(stub)_
- [ ] Task 8: Records: design notes, NEWS, dev log, closing notes

Tasks 1 and 2 can run side by side: Task 1 is labelling time, Task 2 needs no labels. Under decision 1(a), Task 3's rules do not run on the development set before the labels are committed (labels before rules).

---

### Task 1: Role vocabulary, labelling guideline, pilot agreement, development labels

**Status:** `[ ]`

**Tests assumption:** 3 and 4.

**Files**
- Create: `bench/labels/guideline.md`; `bench/R/label-sheet.R` (one sheet per figure); `bench/labels/dev/<id>.csv`; `bench/labels/pilot/<annotator>/<id>.csv`; `bench/R/score-labels.R` (agreement).

**Intent**
- Accuracy and "no silent error" need a truth that the rules did not write. Design §评测设计 asks for a guideline fixed before labelling; this task writes it on the development set, where it may still change.
- The guideline decides the cases the rules will meet: is `geom_hline(yintercept = 0)` data or reference; an `annotate("rect")`; a ggrepel label and its segment; a plot title; a colour bar; a heatmap's dendrogram and annotation tracks; a base `axis` entry.

**Checklist**
- [ ] Role vocabulary: `data`, `guide`, `reference`, `decoration`, `annotation`, each with kinds (for example `guide`: axis line, tick, tick label, axis title, legend key, legend label, legend title, colour bar, strip). One page, with one worked example per kind from the hand-built figures, not the bench.
- [ ] Label sheet per figure: the rendered page with every leaf outlined and numbered, and a CSV with one row per leaf (figure, leaf path, element index range, class, viewport, box, first text) and empty `role`, `kind`, `split` columns. The sheet shows no rule output.
- [ ] Labels keyed by leaf path and element index, not by `L001`-style ids, so they survive renumbering; `score-labels.R` fails when a label does not resolve on the current capture.
- [ ] Pilot: 5 development figures chosen by seed across engines, labelled independently by two annotators; κ on roles and on kinds, share of leaves split, minutes per figure.
- [ ] Full development labels (54 figures) committed before any rule runs on the development set.

**Verification**
- `Rscript bench/R/score-labels.R bench/labels/pilot`: κ, splits, time. Then the same check that every development label resolves on run `0858`'s capture.
- κ on roles below 0.8, or more than 5% of leaves split, is a scope change before the full labels (assumptions 4 and 3). Labelling time above about 15 minutes per figure is a scope change too: label a seeded sample of leaves instead, with its sampling error reported.

**Result** _(filled in when done)_

---

### Task 2: Order binding for grid-page engines, verified by back-substitution

**Status:** `[ ]`

**Tests assumption:** 1.

**Files**
- Create: `R/core-bind.R` (back-substitution by geometry family; statuses); `tests/testthat/test-bind.R`; `bench/R/bind.R`, `bench/R/score-bind.R`.
- Modify: `R/engine-ggplot.R`, `R/engine-patchwork.R` (panels of each composed plot, needed for their scales), `R/engine-heatmap.R` (field `bind`); `R/core-plugin.R` (optional engine field `bind`); `bench/predictions.md`.

**Intent**
- Binding is the claim with no evidence. If order plus back-substitution holds on unpicked figures, binding does not need a handler per geom; if it fails, the plan and the research card's claim 1 change, so this runs first.
- Data-mark leaves are selected here by the layer that drew them (ggplot: position among the panel's children; heatmap: body and annotation viewports), not by the rules of Task 3, so this task does not wait for them.

**Checklist**
- [ ] Predictions 21 onward in `bench/predictions.md`, committed before the first development run: share of ggplot data-mark elements verified; which geometry families fail; patchwork and heatmap.
- [ ] Leaf ↔ (layer, panel) for ggplot and patchwork from the panel gTree's children and `ggplot_build()`'s layers, including `annotate()` layers; test on a hand-built figure with two layers per panel and an annotation.
- [ ] Families: points (circle centre), rects (corners), segments (ends), paths (vertices per group), polygons (vertices per group), text (anchor, with justification). Tolerance 0.5 px (design §绑定假设). Statuses: `verified`, `ambiguous` (more than one row within tolerance), `failed` (the element is not where its row puts it), `unbound` (reason: no family, no scale, withheld table), `count_mismatch` (from the leaf).
- [ ] Mutation tests: permuting rows inside a leaf fails every changed leaf except tied elements; moving one element by 1 px fails it.
- [ ] Heatmap: body cells ↔ matrix cells through row and column orders and the body viewport's native scale.
- [ ] Development run in the container, archived; scored by engine, family and geom.

**Verification**
- `NOT_CRAN=true Rscript -e "devtools::test()"` with the new tests; `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bind.R dev`; `Rscript bench/R/score-bind.R bench/runs/<run>.csv`.
- Expected: most point, rect and text leaves verified; paths and polygons by group. A family that fails on more than a few figures, or `failed` elements in a family that verifies elsewhere, is a scope change under assumption 1.

**Result** _(filled in when done)_

---

### Task 3: Rules as plugins; coverage on the development set

**Status:** `[ ]`

**Tests assumption:** 2 (coverage half).

**Files**
- Create: `R/classify.R` (internal: run the rules plugins of the figure's engine, collect role, kind, cue, rule id, residue reason); `R/rules-ggplot.R`, `R/rules-heatmap.R`, `R/rules-base.R`, `R/rules-grid.R` (patchwork reuses ggplot's per composed plot); `tests/testthat/test-classify.R`; `bench/R/classify.R`, `bench/R/score-classify.R`.
- Modify: `R/core-plugin.R` (a `rules` contract that runs the rules on the engine's example and checks the output's shape); `R/zzz.R`; `bench/predictions.md`.

**Intent**
- Coverage needs no labels and says early whether the residue is a remainder or the main work.
- Rules read paths and viewports, and the object for what names cannot say (an `annotate()` layer; a guide's keys and their series from `get_guide_data()`).

**Checklist**
- [ ] Predictions committed before the first development run: residue share by engine; the classes it falls in.
- [ ] Rules ported from `dev_docs/research/capture-groups/classify.R`, matching on path and viewport segments; object cues for layers and guides; base rules by call name (the order of the 2026-11-11 note in design §分类: `plotXY`, `path`, `axis`, `text`, `segments`, `box`, `polygon`, `symbols`, `rect`, `title`, `mtext`).
- [ ] Residue carries a reason (no rule matched; two rules disagree; generic grob outside any known subtree).
- [ ] Contract tests through `gl_test_plugin()` for each rules plugin, and a third-party rules plugin registered in a test.
- [ ] Development run in the container, archived; residue by engine, by class, by figure.

**Verification**
- Suite; `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/classify.R dev`; `Rscript bench/R/score-classify.R`.
- Residue above 10% of ggplot elements, or spread so that no five classes cover most of it, is a scope change under assumption 2.

**Result** _(filled in when done)_

---

### Task 4: Accuracy against the labels; consistency checks; silent errors

**Status:** `[ ]`

**Tests assumption:** 2 (accuracy half) and 5.

**Files**
- Create: `R/classify-checks.R` (consistency checks as functions of the figure, the roles and the bindings); tests in `tests/testthat/test-classify.R`.
- Modify: `bench/R/score-classify.R` (confusion by engine and role; flagged and silent errors; flagged-but-correct).

**Checklist**
- [ ] Checks: legend key style matches a series (ggplot from `get_guide_data()`); axis ticks collinear and labels aligned with them; a `data` leaf is bound (Task 2) or declared dataless with a reason; a `reference` or `decoration` leaf does not bind to a layer's rows; text roles hold text elements.
- [ ] A role that fails a check is `flagged`, with the check and its evidence; `flagged` is reported with the residue.
- [ ] Score: accuracy by engine and role, residue, silent errors (wrong and not flagged), flagged-but-correct; every silent error listed with figure, leaf and the rule that made it.
- [ ] Each silent error gets a rule, a check or a stated reason it cannot be caught (the development set is for tuning; each change and the rerun archived and labelled as made after looking).

**Verification**
- `Rscript bench/R/score-classify.R` on the archived run, against `bench/labels/dev/`.
- Done when the criteria of the header hold: 0 silent errors; flagged-but-correct at most 5% of correct elements.

**Result** _(filled in when done)_

---

### Task 5: Base figures: bindings through arguments and `usr`; legend entries

**Status:** `[ ]`

**Tests assumption:** 6.

**Files**
- Modify: `R/core-substrate.R` (`base_expected()` for data-mark calls: `polygon`, `path`, `symbols`, `arrows`, `abline`; the 574 leaves without a count); `R/engine-base.R` (a table of each data-mark entry's arguments; field `bind`); `R/rules-base.R` (legend entries); tests in `tests/testthat/test-capture.R` and `test-bind.R`.

**Intent**
- On a recorded plot `legend()` leaves only primitive entries. The milestone allows base legends in the residue; it does not allow them bound as data.
- Expected counts matter where binding happens. A guide entry (`axis`, `box`, `title`, `mtext`) needs no count; a data-mark entry without one cannot be bound.

**Checklist**
- [ ] Predictions committed before the development run: legend entries found; base data-mark elements verified; leaves still without a count.
- [ ] Expected counts for `polygon`, `path`, `symbols`, `arrows`, `abline`, each with a hand-built test that fails before the change. Device-reading code: the container suite too.
- [ ] Arguments table per data-mark entry (x, y and what the call gives per element), bound by order and verified through the panel's `usr`.
- [ ] Legend entries from the code (calls matched by order, then checked against the page: the entries' boxes must sit inside the legend's `rect`) and from the page alone; both measured against the labels of the 10 figures. An entry neither cue settles is residue.
- [ ] Measure, do not build: in how many base figures the code names the data frame columns passed to the plotting calls.

**Verification**
- Suite on the host and `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R`; development runs of `bind.R` and `classify.R` for base, archived.
- A legend entry classified as data without a flag fails the milestone criterion and is a scope change.

**Result** _(filled in when done)_

---

### Task 6: Where roles and bindings live (ADR-0007); public API

**Status:** `[ ]` _(stub)_

ADR-0007 from open decision 2, with the numbers of Tasks 2–5 (time, size in the bundle); then `gl_classify()`, `gl_role()`, `gl_unclassified()` and a binding query, written out after those results. Bundle round trip and the 3 MB size check stay green.

---

### Task 7: Structure tree, data tree and their mapping

**Status:** `[ ]` _(stub)_

`gl_tree(view = c("structure", "data"))` and `gl_map()` from roles, bindings and the engines' layouts (design §分层), with the regression-band case of design §分层 (240 built rows, 3 fewer elements in panel 2) as a test.

---

### Task 8: Records

**Status:** `[ ]`

**Checklist**
- [ ] Dev log with measured counts and surprises
- [ ] Design doc: dated notes in §分类 (dev-set numbers beside 481 of 486; the name-versus-path finding), §分层, §风险与未决问题 (base binding), §审稿人预演, §实施计划 if decision 3 moves corrections, §与上一版的区别
- [ ] NEWS for user-visible changes (Task 6 onward)
- [ ] Closing notes; what the next plan starts with (held-out annotation protocol and predictions)

---

## Scope changes

_(append-only; never edit completed tasks above)_

- 2026-11-11 — **Owner's decisions: all three as recommended.** (1) Claude labels the 54 development figures from the rendered page and the leaf sheet, committed before any rule runs on the development set; the owner labels the 5 pilot figures independently. (2) Rule roles and engine bindings are derived tables of the substrate, recomputed when it is rebuilt and versioned by the plugin that made them; corrections, agent fills and human notes are records laid over them. ADR-0007 records this in Task 6 with the numbers of Tasks 2–5; nothing is exported before it. (3) `gl_reclassify()` moves to the plan that builds the record core. **Evidence:** the plan's header (who writes rules and labels; Appendix A's `structure` layer needs M2's record core). **Effect:** the plan is active; Task 1 has its annotators; design §实施计划 gets a dated note for (2) and (3). The owner also asked to close the M0 and bench v0 plans first and then start Task 2.

## Closing notes

Filled in when the plan moves to `done/`.
