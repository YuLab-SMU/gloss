# M6 evaluation closure and measurement validation

> Status: active.  
> Date opened: 2026-11-17. Owner: Codex.

**Goal:** Close the M5 measurement gaps that can change the design decision: make semantic materials reproducible in the pinned container, validate the masked metric against a blinded open-world audit, measure the SVG-only and prepared-visual conditions, and run a repeated or two-model extension only if its cost is demonstrably sustainable.

**Why now:** M5 closed as a cost-gated feasibility slice rather than the registered main comparison. The host suite is green, deterministic claim checking and update mechanics have fixtures, and the one-model held-out slice shows the check-enabled cells correct on 4/4 tasks while the no-check substrate cell is correct on 1/4. The evidence does not yet establish the A-versus-B claim, the masked metric, the visual condition, the SVG-only condition or the two-model/repeated result. The pinned bench image also lacks `svglite`, so the M5 semantic materials were generated on the host. The closing M5 log says to start with the image, a sustainable model budget, a targeted two-rater audit and a model-based SVG-only condition.

**Research-card clauses:** This plan is a continuation of the main comparison, the checking-versus-answerability clause, the masked-evaluation clause, the multi-selector anchor clause and the engineering-baseline clause. It is also infrastructure for the visual and SVG-only controls. The public-figure statement-prevalence line remains out of scope until these measurement clauses are settled.

**Starting state (measured 2026-11-17):**

- Host suite: 22 test files, 1644 passed, 0 failures and 0 skips from `NOT_CRAN=true Rscript -e "devtools::test()"`; the opening run for this plan took 296.7 seconds.
- Bench-container baseline: 22 files, 186 tests, 1629 expectations, 0 failures, 0 errors and 5 explicit aisdk-dependent skips. The M5 material writer cannot run there because the pinned image has no `svglite`.
- Frozen benchmark: v0 has 55 development and 54 held-out figures; the separate tree stratum has 29 development and 28 held-out figures. M5 used six host-material figures in each set; four held-out figures yielded directional tasks and two remained material-only.
- Deterministic M5 fixture: 4/4 claim statuses matched, 20/20 correct masked bindings accepted, 20/20 wrong masked bindings rejected, 5/5 controlled updates rebased and 16/16 prepared SVGs parsed with zero binding-answer leaks.
- M5 model slice: 24 GLM development runs and 16 GLM held-out runs, one repeat, four cells (A, A + check, B - check and B). On held-out tasks, A, A + check and B were 4/4 correct with full coverage; B - check was 1/4. The first Gemini A run took 135.7 seconds, so the remaining two-model matrix was stopped.
- No M6 audit labels, container-parity run, model-based D run, prepared-visual comparison, engineering baseline or repeated/two-model extension has run.

**Assumptions to test, riskiest first:**

1. The pinned container can reproduce the selected materials once `svglite` is available, without changing source hashes or leaking binding answers into prepared views. Task 1 tests this. A platform-dependent difference is recorded and bounded; a changed source or scene stops model work.
2. A small blinded two-rater audit can label the open-world claims and relations in a way that gives the same condition ordering as masked scoring. Task 2 tests this. If ordering disagrees, masking remains an auxiliary metric and the plan records the disagreement.
3. The four update classes expose the same conservative anchor behavior beyond the five hand-built fixtures. Task 2 tests selector ablations on a registered development matrix. A silent misattachment is a hard failure; missing or ambiguous targets remain visible outcomes.
4. SVG-only and prepared-visual materials are answerable under the fixed loop and contain no hidden binding or executable payload. Task 3 tests this on development materials before any held-out run.
5. A second model and repeated runs fit a pre-registered operational budget. Task 3 measures the distribution first. If the gate fails, Task 5 closes as a measured feasibility result and leaves the unrun precision and cross-model clauses explicitly open.
6. Existing tools can supply a fair identification/binding engineering baseline on the frozen figures without becoming package dependencies. Task 4 tests this. Unavailable or incompatible tools are counted with reasons rather than silently omitted.

**Architecture:** Keep the package substrate, checks, anchors, stages and exporters unchanged unless a contract test exposes a defect. Work primarily under `bench/docker/`, `bench/semantic/`, `bench/agent/` and `bench/baselines/`. The container manifest records the image digest and installed `svglite` version; material manifests retain source hashes and disclosure metadata. Audit labels are stored separately from model traces and are blinded to condition until adjudication. The fixed evaluation loop, prompt versions, model ids, budgets and scoring rules are frozen before held-out material or model execution. All traces, refusals, audit decisions and operational failures are archived so every table can be regenerated without a model call.

**Out of scope:**

- New engine capture, role or binding rules; broad support for base/heatmap residue; or a change to conservative rebase semantics.
- A public-figure statement-prevalence audit, which is a later research-card candidate.
- Browser automation, a new product UI, arbitrary R/JavaScript execution, or adding comparison tools to `DESCRIPTION`.
- Prompt, threshold or task-rule tuning on the held-out set; a model leaderboard; or storage of keys, private prompts or gateway credentials.
- Expanding the benchmark strata before the environment and metric gates pass.

**Tech stack:** R, testthat edition 3, the pinned Bioconductor container with `svglite`, the existing `aisdk` adapter and scripted `LanguageModelV1`, the local OpenAI-compatible gateway for optional model runs, JSONL/CSV archives and the existing `gl_*` APIs. The bench remains network-free for figure execution; no package dependency is added for comparison baselines.

**Done when:**

- The pinned container runs the selected development and held-out material writers and deterministic preflight. Source digests match the host manifests, every prepared view reports `contains_binding_answers = false`, and any remaining environment difference has a named archive row.
- Every selected audit item has two independent labels, an adjudicated label, a reason code and a recorded audit burden. The report gives agreement and per-class results and states whether masked and audit condition ordering agree; disagreement makes masked scoring auxiliary.
- The update matrix reports automatic hits, ambiguous/missing targets, repair outcomes and silent misattachments separately for title, colour, data-subset and add/delete-layer changes. No silent misattachment is accepted as a pass.
- SVG-only and prepared-visual development runs have parseable materials, fixed budgets, complete outcome rows or explicit operational failures, and zero answer leaks. Their held-out use begins only after predictions are committed.
- A cost-gated extension either completes the registered repeated/two-model or held-out comparison with per-task paired intervals and token/request/time distributions, or closes with an archived infeasibility result and the exact clauses that remain untested.
- Each engineering baseline has a coverage/failure row on the frozen figure set, including unavailable-tool reasons; no baseline code enters the package dependency graph.
- The host suite remains at zero failures and zero skips. If device-output code or the image is changed, the bench-container suite and `R CMD check` are recorded as well.

---

## Progress tracking

**Status legend**
- `[ ]` Not started
- `[~]` In progress
- `[x]` Completed
- `[!]` Blocked
- `[-]` Cancelled

**Plan maintenance rules**

- Update a task in the same commit as its code or measurement.
- Mark `[x]` only with the command, figure set and observed counts/costs.
- If a result contradicts an assumption or completion criterion, append a dated Scope change and revise only open tasks. Never rewrite a completed task silently.

**Current state** _(2026-11-17)_

- Suite: 22 files, 1644 passed, 0 failures and 0 skips (`NOT_CRAN=true Rscript -e "devtools::test()"`, 296.7 seconds).
- Key numbers: deterministic M5 fixture 4/4 claims, 20/20 masked bindings in each direction, 5/5 updates, 16/16 prepared SVGs with zero leaks; M5 held-out GLM slice 16 runs, A/A + check/B 4/4 correct, B - check 1/4; Gemini sizing stopped after one 135.7-second run.

**Overall progress**

- [ ] Task 1: Repair the pinned bench environment and prove host/container material parity.
- [ ] Task 2: Validate masked scoring with a blinded audit and extend the update/anchor ablation.
- [ ] Task 3: Run the SVG-only/prepared-visual development sizing and make the repeated/two-model cost decision.
- [ ] Task 4: Measure thin engineering baselines on the frozen figures.
- [ ] Task 5: Conditionally run and archive the expanded held-out comparison, or close with a measured feasibility scope change.

---

### Task 1: Pinned environment and material parity

**Status:** `[ ]`

**Tests assumption:** 1.

**Files**

- Modify: `bench/docker/image` and the image-build or environment manifest used to produce the pinned digest; `bench/README.md` if the reproducibility contract changes.
- Create: a small M6 environment/preflight script under `bench/semantic/` and parity summaries under `bench/runs/`.
- Test: the six development and six held-out host-material selections used by M5, followed by the deterministic material and prepared-view checks.

**Intent**

- Make `svglite` available in the pinned image without changing the frozen benchmark split or the package dependency graph.
- Regenerate the selected materials in the container, compare source and scene digests with the host manifests, and report any legitimate platform difference separately from a material failure.
- Run the deterministic checks before any model request. A changed scene, missing source hash, leaked binding answer or unlabelled refusal stops the plan at this gate.

**Verification**

- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/semantic/m6_env.R dev` and the corresponding held-out material preflight.
- Expected: all selected materials are written, source hashes match, prepared views contain no binding answers, and the deterministic M5 checks reproduce their archived statuses. The result that changes the plan is a container-only mismatch that cannot be explained by the recorded runtime or a missing package.

**Result** _(to be filled when done)_

- Command, counts, image digest and parity result.
- Cost: files changed, container builds/runs and what coverage or reproducibility number moved.

---

### Task 2: Audit validity and anchor robustness

**Status:** `[ ]`

**Tests assumptions:** 2 and 3.

**Files**

- Create: `bench/semantic/m6-audit.R`, its blinded rubric and archive-only scorer; update fixtures under `bench/semantic/`.
- Modify: only the smallest scorer or proposal contract if a test exposes a defect.
- Test: a stratified development sample of open-world claims/relations and the registered title, colour, data-subset and add/delete-layer updates. The sample and labels are frozen before any condition comparison.

**Intent**

- Select at least 20 auditable items when the development pool permits (balanced across claim/relation and true/false or supported/unsupported cases). Two raters label independently from the figure and code-derived evidence, without seeing model condition or masked answer; adjudication records evidence and rationale.
- Freeze an archive join that can compare masked and audit scores by item and condition, including verified, ambiguous, unbound, count-mismatch, refused and failed outcomes. Task 3 supplies the model-condition rows; do not collapse refusals into correctness.
- Repeat the update matrix with multi-selector, element-only and data-key-only anchors. Count silent misattachment separately from explicit missing/ambiguous outcomes; use the existing conservative fallback unchanged.

**Verification**

- Archive the item manifest, rater labels, adjudications, agreement statistics and the archive-only join contract for the later condition comparison. Every item has two labels or an explicit unavailable reason.
- Run the update scorer from archives only. Expected: no silent misattachment and a complete audit join ready for Task 3. The masked-versus-audit primary/auxiliary decision is made after the model-condition rows are scored; any disagreement changes Task 5's metric and predictions before held-out execution.

**Result** _(to be filled when done)_

- Command, item counts, agreement, ordering comparison, update counts and cost.

---

### Task 3: SVG-only, prepared-visual and cost gate

**Status:** `[ ]`

**Tests assumptions:** 4 and 5.

**Files**

- Create or modify: an M6 fixed-loop runner/scorer under `bench/agent/`, prepared-visual and SVG-only material manifests, and append-only prediction entries in `bench/predictions.md` before model execution.
- Test: the M5 development materials plus the audited task subset; held-out materials remain untouched until the gate is recorded.

**Intent**

- Run the same task wording, source digests, disclosure contract and per-run limits for A, B, D (SVG-only) and the prepared-visual arm. Report correctness, false accept, false reject, coverage and operational failure separately.
- Measure model cost first on a small development sizing matrix. Use the existing GLM configuration for continuity and a second model only if its first sizing run fits the registered request and wall-time envelope. Do not infer a model comparison from one stopped trace.
- Decide, before held-out execution, whether the observed distribution supports the two-model and repeated comparison or only a single-model feasibility report. The decision is a scope change, not a silent reduction of the target.

**Verification**

- Archive every request, tool call, finish reason, token count, retry, time and prepared-view leak check. The scorer makes no model calls.
- Expected: D and visual conditions have complete or explicitly failed rows, no answer leaks, and a registered cost decision. If the cost gate fails, Task 5 is marked deferred with the measured p95/total budget and the untested clauses.

**Result** _(to be filled when done)_

- Command, per-condition outcomes and cost distributions; prediction verdicts and scope change.

---

### Task 4: Engineering baselines

**Status:** `[ ]`

Measure identification and binding coverage for the frozen figures with the selected ggiraph, gridSVG, maidr and plotly baselines, or record an explicit unavailable/incompatible result for each. Keep all adapters under `bench/baselines/`; do not add dependencies to `DESCRIPTION`. Run first on development figures and freeze the runner before any held-out baseline report.

---

### Task 5: Conditional expanded held-out comparison

**Status:** `[ ]`

After Tasks 1–3 freeze the metric, eligible task set, model ids, prompt/loop versions, repeats and predictions, run the expanded held-out comparison and archive the paired scorer output. If the cost gate or audit validity fails, close this task with a dated Scope change that states the exact untested research-card clauses and does not claim M5's main comparison.

---

## Scope changes

_(append-only; none at plan opening)_

## Closing notes

To be filled when the plan closes: end state against the starting suite and key numbers, assumptions confirmed or refuted, the audit/masked decision, the cost-gate branch, design or ADR updates, the closing dev log and any NEWS entry.
