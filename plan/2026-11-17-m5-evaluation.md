# M5 evaluation, costed semantic path and registered held-out comparison

> Status: active.
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
- Suite: 22 files, 1644 passed, 0 failures and 0 skips (`NOT_CRAN=true Rscript -e "devtools::test()"`, 281.7 seconds).
- Key numbers: M4 v0 preflight 54/55, tree preflight 29/29, real smoke 5,594 tokens for one checked record and three rejections, interrupted claim traces 373,889 and 34,081 tokens without a candidate, and no M5 semantic run on held-out figures.

**Overall progress**
- [ ] Task 1: Build the leakage-safe semantic task bank, condition materials and cost gate on development figures.
- [ ] Task 2: Validate deterministic C/D, perturbation, counterfactual and masked scoring contracts without a model.
- [ ] Task 3: Run the registered development 2×2 and prepared-visual sizing pilot, then freeze the held-out scope.
- [ ] Task 4: Run and archive the held-out semantic comparison. _(Stub; write out after Tasks 1–3.)_
- [ ] Task 5: Run targeted human audit, update and anchor ablation, and engineering baselines. _(Stub; write out after Tasks 1–3.)_

---

### Task 1: Leakage-safe materials and the semantic cost gate

**Status:** `[ ]`

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
-

---

### Task 2: Deterministic conditions and scoring contracts

**Status:** `[ ]`

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
-

---

### Task 3: Development 2×2 and prepared-visual sizing pilot

**Status:** `[ ]`

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
-

---

### Task 4: Held-out semantic comparison

**Status:** `[ ]` _(stub)_

Run only after Tasks 1–3 freeze predictions, budgets, models, prompts, loop and the eligible figure subset. Archive the A/B and 2×2 traces on perturbed and counterfactual held-out material, with C and D and the earlier capture/binding results reported in their original strata.

---

### Task 5: Targeted audit, updates and engineering baselines

**Status:** `[ ]` _(stub)_

Use the development result to choose the smallest targeted two-rater audit for open-world relations and claims, compare masked scores with audit scores, run the controlled update and anchor ablation, and measure the engineering baselines. Expand this task only after the semantic cost gate is known.

---

## Scope changes

_(append-only; none at plan opening)_

## Closing notes

Filled in when the plan moves to `done/`.
