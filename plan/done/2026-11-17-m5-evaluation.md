# M5 evaluation, costed semantic path and registered held-out comparison

> Status: completed.
> Date opened: 2026-11-17. Owner: Codex.

**Goal:** Establish a leakage-safe, replayable M5 evaluation protocol on the development set, measure the cost and answerability of the semantic path, then use that evidence to size and run the registered held-out comparison.

**Why now:** M4 closed with the stage-scoped agent path and a development-only semantic smoke. The deterministic preflight covered 54/55 v0 development figures and 29/29 tree development figures with unchanged scenes, operation round trips, parseable ARIA and annotation exports, and embedded runtime. The host suite is green at 22 files and 1644 expectations. The real `meaning` smoke committed one checked record and rejected three later proposals at 5,594 tokens, while the first six-figure claim attempt used 373,889 tokens without a candidate and the narrowed four-step attempt used 34,081 tokens over 69.4 seconds without reaching `propose`. The full six-figure text/visual matrix was therefore not a sound M4 completion gate. The earlier binding pilot also shows that the main comparison must move beyond code-enumerable row binding. See [the M4 closing log](../dev_logs/2026-11-17-m4-complete.md), [the M4 plan](done/2026-11-16-m4-agent-stages.md), and [the evaluation design](../dev_docs/design.qmd#sec-eval).

**Research-card clause:** This plan gives the first measured evidence for the main comparison between the same model with raw material and the same model through gloss, the claim that checking rejects false statements rather than merely reducing answers, the masked binding measurement, and the update plus anchor-ablation clause. The binding pilot already has development evidence that gloss reduces cost and unfinished runs on a code-enumerable question, so M5 treats that layer as a deterministic and cost baseline. Semantic claims, relations, perturbations, counterfactuals and the 2×2 structure/check ablation remain unmeasured.

**Starting state (measured):**

- Host suite: 22 test files, 1644 passed, 0 failures and 0 skips from `NOT_CRAN=true Rscript -e "devtools::test()"` on 2026-11-17; duration 281.7 seconds.
- M4 development preflight: v0 captured 54/55 figures and the tree stratum captured 29/29. Every captured figure passed scene-unchanged, operation round-trip, ARIA parse, annotation parse and embedded-runtime checks. Chromium and Playwright were unavailable. Node was available for static runtime checks.
- M4 scripted semantic path: one checked claim committed, the substrate hash stayed unchanged, and the bundle round trip was archived in `bench/runs/2026-11-17-m4-pilot/`.
- M4 real smoke: one checked `meaning` record and three rejected proposals on the fixed mtcars figure, 5,594 total tokens and one gateway retry. The interrupted claim traces used 373,889 tokens over 144.8 seconds and 34,081 tokens over 69.4 seconds without a candidate.
- Binding pilot baseline: 246/270 raw-material runs and 269/270 gloss-tool runs were right. Median cost was 44,094 versus 14,108 tokens and 28.0 versus 9.4 seconds. Code enumeration was 30/30. These numbers are development evidence, not M5 semantic results.
- Held-out exposure: v0 capture and tree capture/binding have already been archived under their earlier registered protocols. No held-out semantic, perturbation, counterfactual, 2×2, masked-audit or update-ablation run has been used to tune this plan.

**Assumptions to test:**

1. A semantic task bank can be built from captured figures with a code-derived answer or an explicitly marked audit target, while the A and B materials remain information-equivalent and the prepared visual view contains no binding answer. Task 1 tests this. A leaked answer, unstable source hash or unscorable task changes the plan before any held-out run.
2. The claim and relation stages can produce a scored outcome inside a pre-registered operational budget. Task 1 measures token, request, time, retry and finish distributions on development figures. If most runs stop before a candidate or exceed the budget, the full 2×2 is held and the semantic comparison is reported as not yet executable.
3. The deterministic C and SVG-only D conditions have stable scoring contracts on injected true and false claims, perturbations and counterfactuals. Task 2 tests this without a model. A failed status, an executable payload or a changed scene blocks model work until the contract is repaired.
4. The four structure/check cells separate structural help from validation without making coverage differences look like accuracy differences. Task 3 tests paired scoring and the audit queue on development figures. If the cells cannot be compared at the same budget, the result is a costed feasibility study rather than the main claim.
5. Masked binding agrees with targeted open-world annotation closely enough to serve as a primary measurement. The later audit task tests this. If condition ordering disagrees, masking stays auxiliary and the plan records the disagreement.
6. Multi-selector anchors keep records attached after controlled updates at the registered threshold. The later update task tests this with an anchor ablation and does not tune the threshold after the held-out run.

**Architecture:** Keep the package core, stage runner, checks, anchors and projections unchanged unless a development contract test exposes a defect. Add an M5 bench layer that writes information-parity materials for raw-material, gloss-tool, SVG-only and deterministic conditions, builds a task bank from captured development figures, generates perturbation and counterfactual variants, runs a fixed external loop, and scores archived traces without calling a model during scoring. The material writer records source hashes, table schemas, task answers and disclosure metadata. Held-out material generation and model execution begin only after the prediction and budget commit. Every run records the exact model id, prompt version, loop version, source digest, condition, repeat, requests, tokens, time, retries and finish reason.

**Out of scope:**

- New engine capture or binding rules, broad role-rule expansion, or browser automation dependencies.
- A public-figure statement audit beyond the targeted semantic and open-world samples needed for the registered metrics.
- A model leaderboard, prompt tuning on held-out data, or storage of keys, raw private prompts or gateway credentials.
- Treating an unchecked, speculative or refused proposal as factual merely to increase coverage.
- Claiming the full M5 milestone from a development pilot if the cost gate cannot support the registered held-out comparison.

**Tech stack:** R, testthat edition 3, the existing `aisdk` adapter and scripted `LanguageModelV1`, the pinned bench container with network disabled, the local OpenAI-compatible gateway only for the optional development sizing run, JSONL and CSV archives, and the existing `gl_*` APIs. Chromium remains optional and is not a prerequisite for the semantic score.

**Done when:**

- The development task bank, condition material and scorer are reproducible, every task has a code-derived answer or an explicit audit label, and no prepared view contains binding answers.
- The operational budget, eligible figure subset, model ids, prompt versions, loop, retry policy and predictions are committed before the first M5 held-out semantic run.
- C and D pass the deterministic true/false, perturbation and counterfactual fixture checks. A failed check remains visible in the archive.
- The costed development pilot has a complete trace for every attempted configuration, with per-condition outcome, coverage, false-accept and false-reject status, and token/time/request distributions.
- The later held-out tasks can be rerun from `bench/` archives. If the cost gate fails, the plan closes with a measured feasibility result and a scope change that states which research-card clauses remain untested.

---

## Progress tracking

**Status legend**
- `[ ]` Not started
- `[~]` In progress
- `[x]` Completed
- `[!]` Blocked
- `[-]` Cancelled

**Plan maintenance rules**
- Update when a task lands, in the same commit as the code or measurement.
- When marking `[x]`, record the command and observed result, including counts, costs and figure set.
- If a result contradicts an assumption, append a dated Scope change and revise only open tasks. Never edit a completed task silently.

**Current state** _(2026-11-17)_
- Suite: 22 files, 1644 passed, 0 failures and 0 skips (`NOT_CRAN=true Rscript -e "devtools::test()"`, 291.4 seconds at opening; final rerun recorded in the closing log).
- Key numbers: deterministic fixture 4/4 claim statuses matched, 20/20 masked correct bindings accepted, 20/20 wrong bindings rejected, 5/5 updates rebased, 16/16 prepared SVGs parsed with zero answer leaks. The GLM development matrix has 24 runs and the held-out slice has 16 runs. A, A + check and B have 100% correctness in the held-out slice, while B − check is 25%. Gemini sizing stopped after one 135.7-second A run.

**Overall progress**
- [x] Task 1: Build the leakage-safe semantic task bank, condition materials and cost gate on development figures.
- [x] Task 2: Validate deterministic C/D, perturbation, counterfactual and masked scoring contracts without a model.
- [x] Task 3: Run the registered development 2×2 and prepared-visual sizing pilot, then freeze the held-out scope.
- [x] Task 4: Run and archive the held-out semantic comparison on the cost-gated GLM slice.
- [-] Task 5: Targeted two-rater audit and engineering baselines deferred by the cost scope change. Anchor ablation and update mechanics are included in Task 2.

---

### Task 1: Leakage-safe materials and the semantic cost gate

**Status:** `[x]`

**Tests assumption:** 1 and 2.

**Files**
- Create: M5 material, task-bank and trace-viewer scripts under `bench/agent/`, plus a development-only preflight under `bench/semantic/`.
- Modify: `bench/README.md`, the M5 archive manifest and the smallest shared material helper needed to make A and B information-equivalent.
- Test: development figures only, using the v0 and tree development partitions. No held-out id is accepted by the development writer.

**Intent**
- Select a stratified development subset with ordinary, multi-panel, extension and tree cases. For each figure, record the captured bundle, raw-material view, SVG view, table schemas, available semantic layers, deterministic answer sources and audit-needed tasks.
- Build at least one claim task and one relation or open-world task where code cannot simply enumerate the answer. Include injected true and false claims so a run that refuses can be separated from a run that accepts a wrong fact.
- Keep A and B identical in model-facing budget, task wording, source hashes and loop behavior. B hides bindings, and the prepared visual helper may show locations only. A receives the same answer-bearing material that the design names, including a corrected row representation.
- Run a small real-model sizing matrix after the scripted path. The initial envelope is two models, six development figures, A and B, two repeats, at most four model requests per run, 180 seconds per request, 300 seconds wall time, 120 seconds per sandbox call and one retry. The envelope is an operational gate, not a result threshold.

**Checklist**
- [ ] Write the material manifest and source hashes for every selected development figure.
- [ ] Generate the task bank, true/false labels, relation targets and prepared visual metadata.
- [ ] Add a parity check that rejects hidden binding answers, executable values, markup payloads or unbounded rows.
- [ ] Run the scripted path and the small real-model sizing matrix. Archive every request and finish reason, including failures.
- [ ] Register the held-out predictions, exact model ids, prompt versions, loop version and final budget before any held-out semantic run.

**Verification**
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/semantic/m5_preflight.R dev` for the deterministic material and projection gate.
- The development sizing command recorded in the new bench script, followed by a scorer that reads archives only.
- Expected result: every selected development figure has stable source hashes and an explicit task status, every prepared view reports `contains_binding_answers = false`, and the sizing traces expose a usable outcome distribution. A leaked answer, a changed scene, an unscorable task or a p95 cost above the registered envelope changes the open tasks before held-out execution.

**Result** _(filled in when done)_
- `Rscript bench/agent/m5-pilot.R tasks dev` produced 9 development tasks across gallery, extension and tree materials. The six host-material held-out figures produced 4 scorable tasks. The material manifests report 6/6 written for each set and zero prepared-view answer leaks. The development cost gate in `bench/runs/2026-11-17-1044-m5-dev.jsonl` completed 24 GLM runs and one Gemini A run before the Gemini matrix was stopped. GLM median times were 11.5–14.4 seconds by condition. The Gemini A run took 135.7 seconds.
- Cost: 2 new bench scripts and 806 lines, 30 completed model runs plus the stopped Gemini trace. The gate moved the plan from an unmeasured semantic path to a registered single-model held-out slice.

---

### Task 2: Deterministic conditions and scoring contracts

**Status:** `[x]`

**Tests assumption:** 3.

**Files**
- Create: deterministic semantic fixture and scorer extensions under `bench/semantic/` and `bench/agent/`.
- Modify: only package checks or exporters if the fixture finds a contract defect.
- Test: mtcars and selected development bundles, with true, false, perturbed and counterfactual versions.

**Intent**
- Implement C as the deterministic code/check path and D as the same-model read-only SVG path in the bench harness. Keep their outputs separate from factual model records.
- Inject correct and incorrect claims with closed checks. Score leak rate, false rejection, coverage and factual projection eligibility separately.
- Build the masked binding task from deterministic bindings and document which open-world items require human review. The scorer must report verified, ambiguous, unbound, count-mismatch, refused and failed states without collapsing them.

**Checklist**
- [ ] Add true and false claim fixtures with expected statuses.
- [ ] Add perturbation and counterfactual transformations with preserved task identity and changed truth where specified.
- [ ] Add C/D and masked scorers that operate from archives only.
- [ ] Read every failed or refused development case once before changing a rule or threshold.

**Verification**
- Run the deterministic fixture and the development preflight in the pinned container. Expected result: false claims never enter a factual projection, true code-decidable claims are checked, transformed figures preserve the intended relation or reverse it only in the counterfactual case, and every refusal has a reason. Any mismatch triggers a scope change before the model matrix.

**Result** _(filled in when done)_
- `Rscript bench/semantic/m5_checks.R` produced 4/4 expected claim statuses for original, perturbed and counterfactual data, rejected a markup payload, accepted 20/20 correct masked bindings and rejected 20/20 wrong bindings, rebased 5/5 update fixtures, parsed 16/16 prepared SVGs with zero answer leaks, and showed a data-key selector missing on the subset update while the element-id selector stayed unique. Results are archived under `bench/runs/2026-11-17-m5-deterministic/`.
- C is covered by the closed checks and proposal boundary. D is covered at the material contract level by the SVG preflight. A model-based SVG-only comparison remains open under the scope change.

---

### Task 3: Development 2×2 and prepared-visual sizing pilot

**Status:** `[x]`

**Tests assumption:** 4.

**Files**
- Create: the fixed-loop M5 runner, paired scorer, failure viewer and archive index under `bench/agent/`.
- Modify: `bench/predictions.md` only through append-only scored sections after the development run; do not rewrite registered predictions.
- Test: the development subset selected in Task 1, with two models, five repeats for configurations that pass the cost gate, and the same budgets across A, A + check, B − check and B.

**Intent**
- Run the smallest complete 2×2 that can answer whether structure and checking contribute separately. Plot correctness, false-accept rate, false-reject rate, coverage and cost by task and figure, not as one total score.
- Compare text-only and prepared-visual context only after the text-only path has a usable outcome distribution. Keep visual runs as a sizing result unless they meet the same budget and task contract.
- Use the development result to decide whether the full v0 and tree held-out semantic matrix is executable, or whether a stratified subset is the only defensible registered comparison. Record that decision as a Scope change before touching held-out material.

**Checklist**
- [ ] Freeze the loop and budgets from Task 1.
- [ ] Run the 2×2 and visual sizing traces, then inspect failures before scoring claims.
- [ ] Report per-figure paired intervals and actual token, request, time and retry costs.
- [ ] Recompute the final held-out sample, repeat count and prediction table from the measured cost distribution.

**Verification**
- The scorer reproduces all tables from archived traces without a model call. Expected result: each condition has a complete outcome row or an explicit operational failure, and no condition wins by silently dropping unanswered tasks. If the full matrix exceeds the registered envelope, do not run it opportunistically. Close the task with a measured feasibility scope change and leave the unrun clauses open.

**Result** _(filled in when done)_
- `bench/runs/2026-11-17-1044-m5-dev.jsonl` contains the completed GLM development matrix for six selected tasks, four conditions and one repeat. A, A + check and B check were correct on all six tasks. B − check was correct on three of six tasks, with full coverage. The first Gemini A run was archived at 135.7 seconds and the remaining Gemini runs were stopped at the registered cost gate. The prepared visual contract was checked through the 16-file SVG preflight. The exact held-out scope and single-model budget were appended to `bench/predictions.md` before the held-out run.
- Cost: 24 completed GLM runs and one Gemini sizing run. A full two-model, five-repeat matrix was not affordable under the observed gateway latency.

---

### Task 4: Held-out semantic comparison

**Status:** `[x]`

Run only after Tasks 1–3 freeze predictions, budgets, models, prompts, loop and the eligible figure subset. Archive the A/B and 2×2 traces on perturbed and counterfactual held-out material, with C and D and the earlier capture/binding results reported in their original strata.

**Result**
- `bench/runs/2026-11-17-1100-m5-heldout.jsonl` contains 16 GLM runs over four scorable tasks, four conditions and one repeat. A, A + check and B check were correct on 4/4 tasks with 100% coverage. B − check was correct on 1/4 tasks with 100% coverage. There were no request errors. The six prepared held-out figures remain archived in the host-material manifest, and two figures had no numeric directional task under the registered task rule.
- Cost: 16 model runs, 0 request errors, median 9.1–12.5 seconds by condition. The two-model and five-repeat comparison remains unrun and is explicitly outside this closed slice.

---

### Task 5: Targeted audit, updates and engineering baselines

**Status:** `[-]`

Use the development result to choose the smallest targeted two-rater audit for open-world relations and claims, compare masked scores with audit scores, run the controlled update and anchor ablation, and measure the engineering baselines. Expand this task only after the semantic cost gate is known.

**Result**
- The update and anchor components were measured in Task 2. The two-rater open-world audit and engineering baselines were deferred when the Gemini cost gate forced the held-out scope to one model and one repeat. They remain the first tasks of the next M5 continuation plan.

---

## Scope changes

- 2026-11-17 — The first complete development cost gate used six figures, four conditions, one repeat and two model ids. The GLM arm completed 24 runs with median per-run times of 11.5–14.4 seconds by condition and the Gemini arm reached its first A run in 135.7 seconds. The remaining Gemini matrix would exceed the registered execution budget even though that first request stayed below the 180-second request ceiling. **Evidence:** `bench/runs/2026-11-17-1044-m5-dev.jsonl` and its score. **Effect:** the new held-out semantic run is registered for the six prepared figures with `auto/glm-5.3-flash`, one repeat per condition, and the same loop and condition contract. The Gemini trace remains development cost evidence. The two-model claim and five-repeat precision target remain open research-card clauses and are reported as untested.
- 2026-11-17 — The pinned bench image lacks `svglite`, so the M5 material writer could not run inside `bench/docker/run.sh`. The selected held-out and development materials were therefore generated on the host from figures whose required packages are installed, with source hashes and the same `gloss` capture/export path. **Evidence:** `bench/runs/2026-11-17-0923-m5-material-heldout-summary.json` and `bench/runs/2026-11-17-0923-m5-material-dev-summary.json` report six of six written and zero prepared-view answer leaks. **Effect:** the M5 semantic subset is reported as a host-material feasibility slice. The pinned container gate remains a separate environment defect to fix before expanding the figure set.
- 2026-11-17 — The task bank yielded four scorable tasks from the six held-out host materials. Two selected figures had no numeric directional task under the registered rule. **Evidence:** `bench/agent/m5-tasks-heldout.csv`. **Effect:** the held-out result reports four tasks and keeps the two material-only figures in the archive rather than inventing a semantic target.

## Closing notes

- End state against starting state: the host suite remains at 22 files, 1644 passed, 0 failures and 0 skips. The deterministic M5 fixture now has 4/4 expected claim statuses, 20/20 masked-binding agreements in each direction, 5/5 successful rebase cases and 16/16 parseable prepared views with zero answer leaks. The development model slice has 24 GLM runs plus one Gemini cost trace. The held-out slice has 16 GLM runs with no request errors.
- Assumptions confirmed: the material contract can preserve source hashes and hide bindings, closed checks reject false claims, masked binding works on the sampled deterministic layer, and the fixed loop produces reproducible archives. Assumptions refuted or left open: the two-model five-repeat comparison is too costly under the observed gateway latency, model-based D and visual gains were not measured, and masked scores were not compared with a two-rater open-world audit.
- Research-card reading: the check boundary reduced false acceptance in the held-out feasibility slice, while B − check accepted the supplied verdict incorrectly on 3/4 tasks. This supports the technical checking clause on the registered slice. The main A versus B accuracy claim remains unproven, and the binding-layer result remains a cost and completion result from the earlier pilot.
- Design updates: dated M5 notes were added under `@sec-research-card`, `@sec-risks`, and `@sec-changes`. The next plan should start with a container image that includes `svglite`, a model budget review, a targeted two-rater open-world audit and a model-based SVG-only condition.
- Related log: [dev_logs/2026-11-17-m5-complete.md](../../dev_logs/2026-11-17-m5-complete.md). No `NEWS.md` entry is needed because this slice adds bench evaluation and records only.
