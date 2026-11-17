# M6 evaluation closure and measurement validation

> Status: completed.
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

- Suite: 22 files, 1644 passed, 0 failures and 0 skips (`NOT_CRAN=true Rscript -e "devtools::test()"`; opening 296.7 seconds, closing 285.7 seconds).
- M6 evidence: the new image writes 6/6 development and 6/6 held-out materials with zero prepared-view leaks; development source scenes match 6/6 M5 hashes, while the six old held-out host hashes are replaced by container-canonical hashes because the host used `ggplot2` 4.0.3.9000 and the image uses 4.0.3. Deterministic checks on the container materials are 4/4 claims, 20/20 masked bindings in each direction, 5/5 updates, 16/16 SVGs parsed and 0 leaks.
- M6 model sizing: two models, four conditions and five tasks each (40 runs, one repeat). Every run had a response and no request error. GLM: A 5/5, B+check 4/5, D 3/5, visual 4/5; DeepSeek: A 5/5, B+check 5/5, D 2/5, visual 3/5.

**Overall progress**

- [x] Task 1: Repair the pinned bench environment and establish container-canonical material parity.
- [x] Task 2: Validate the archive contract and extend the update/anchor ablation; the human open-world queue remains explicitly unlabelled.
- [x] Task 3: Run the SVG-only/prepared-visual development sizing and complete the two-model cost gate.
- [x] Task 4: Measure the thin engineering-baseline inventory on the frozen figures.
- [x] Task 5: Close the expanded held-out comparison by scope change; retain it as the next slice after the human audit and repeat budget are available.

---

### Task 1: Pinned environment and material parity

**Status:** `[x]`

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

**Result**

- Added `bench/docker/Dockerfile`, rebuilt the pinned base as image `sha256:ab2a2e6f27e84cd1cb113fc84aa3dccbf9c0047bdbaabe633dcc7edd07f015c5`, and installed `svglite` 2.2.2. `bench/docker/image-manifest.json` records the base digest, R 4.5.2, Bioconductor 3.21 and CRAN snapshot.
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/semantic/m6_env.R dev` wrote 6/6 materials and matched the M5 source scene hash on 6/6, with 0 prepared-view leaks. The held-out command wrote 6/6 with 0 leaks; all six are `source_changed_from_m5`, caused by the host/container `ggplot2` version difference. M6 task files use the container hashes and the old M5 archives remain unchanged.
- `GLOSS_BENCH_OFFLINE=true GLOSS_MATERIAL_NAMESPACE=m6-container bench/docker/run.sh Rscript bench/semantic/m5_checks.R` reproduced 4/4 claim statuses, 20/20 masked bindings in each direction, 5/5 updates, 16/16 parsed prepared SVGs and 0 leaks.
- Cost: one image build, two six-figure container material runs and the namespace/preflight changes; the result moved the semantic materials from host-only to a pinned container reference.

---

### Task 2: Audit validity and anchor robustness

**Status:** `[x]`

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

**Result**

- `GLOSS_MATERIAL_NAMESPACE=m6-container Rscript bench/semantic/m6_audit.R` archived 20 deterministic proxy items with 20/20 agreement between the closed check/binding path and an independent recomputation. It also archived the three existing open-world audit candidates with two blank human-rater columns; no two-person human labels were available in this session, so no masked-versus-human ordering claim is made.
- `Rscript bench/semantic/m6_updates.R` ran 25 updates × 3 selectors = 75 attempts. The multi-selector path had 25/25 unique resolutions and 0 silent misattachments; element-id also had 0 silent misattachments; data-key-only had 7 silent misattachments and 3 missing targets. There were 0 rebase errors.
- Cost: 20 proxy audit items, 3 queued human items and 75 selector/update attempts. The human audit remains an explicit open-world measurement gap.

---

### Task 3: SVG-only, prepared-visual and cost gate

**Status:** `[x]`

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

**Result**

- `GLOSS_MATERIAL_NAMESPACE=m6-container Rscript bench/agent/m6-pilot.R materials` generated five prepared PNGs with the registered zero-answer metadata. Two development runs of `Rscript bench/agent/m6-pilot.R run` completed 40 runs: GLM and DeepSeek, four conditions (`A_raw`, `B_check`, `D_svg`, `V_prepared`), five tasks and one repeat per model.
- Every run had full coverage and 0 request errors. GLM medians were 18.67/14.56/16.65/14.21 seconds and 4282/1201/15748/3044 tokens for A/B/D/visual. DeepSeek medians were 6.95/10.51/6.09/4.53 seconds and 4650/2570/16914/2349 tokens. No prepared visual row reported a binding-answer leak.
- The cost gate supports the two-model one-repeat development extension. Five-repeat precision and the expanded held-out run remain outside this slice because the human audit is unlabelled and the task material migrated to a new pinned-container hash set.

---

### Task 4: Engineering baselines

**Status:** `[x]`

**Result**

- `Rscript bench/baselines/m6_inventory.R` archived 48 rows over 12 figures and four comparison packages. `ggiraph` and `plotly` were installed but had no baseline-specific calls in the frozen code (12 `not_applicable` rows each); `gridSVG` and `maidr` were unavailable (12 rows each). No comparison package entered `DESCRIPTION`, and no adapter was inferred from an unavailable or non-integrated package.

---

### Task 5: Conditional expanded held-out comparison

**Status:** `[x]`

**Result**

- The held-out semantic model extension was deferred after the environment migration and the missing two-rater open-world labels. The new container materials and `m6-tasks-heldout.csv` are archived, but no held-out model call was made and no prediction was tuned on the old host hashes.

---

## Scope changes

- 2026-11-17 — The pinned image now contains `svglite` 2.2.2. The six development materials matched the old host source scenes, while all six selected held-out host scenes changed under the pinned `ggplot2` 4.0.3 versus host 4.0.3.9000. **Evidence:** `bench/runs/m6-environment/2026-11-17-1603-dev-summary.json` and `2026-11-17-1606-heldout-summary.json`; held-out scene diffs show changed panel margins/clipping geometry. **Effect:** M6 uses the six container-generated held-out materials and their new source hashes as the canonical future task set; the old M5 host material and score remain historical and unchanged.
- 2026-11-17 — The planned two-rater open-world audit could not be completed in this session. The deterministic proxy has 20/20 agreement, and the three open-world candidates have no human labels. **Evidence:** `bench/runs/m6-audit/2026-11-17-1615-items-summary.json`. **Effect:** the masked metric is not promoted to a primary open-world metric; the human audit is the first task of the next slice.
- 2026-11-17 — The update matrix found 7/25 silent misattachments for data-key-only anchors, 0/25 for multi-selector anchors and 0/25 for element-id anchors; 3 data-key resolutions were missing. **Evidence:** `bench/runs/m6-updates/2026-11-17-1613-selector-ablation-summary.json`. **Effect:** the multi-selector result is retained as the safe path, while data-key-only remains an auxiliary ablation and does not meet the 1% research-card criterion.
- 2026-11-17 — Two models completed one development repeat over four conditions with full coverage and no request errors, but no five-repeat precision estimate or held-out semantic run was made. **Evidence:** `bench/runs/m6-model/2026-11-17-1618-dev-summary.csv` and `2026-11-17-1624-dev-summary.csv`. **Effect:** the cost gate is closed for a two-model one-repeat feasibility extension; the repeated precision and main A/B confidence-interval clauses remain open.
- 2026-11-17 — The engineering baseline inventory found no runnable baseline-specific integration in the 12 frozen figures; ggiraph/plotly were installed but not applicable, and gridSVG/maidr were unavailable. **Evidence:** `bench/runs/m6-baselines/2026-11-17-1630-inventory.csv`. **Effect:** M6 records package availability and integration reasons; actual adapter coverage remains open without changing package dependencies.

## Closing notes

- End state against the opening state: the host suite remains green at 22 files, 1644 passed, 0 failures and 0 skips. The pinned image now has `svglite` 2.2.2; 12 container materials were written with zero prepared-view leaks; the held-out six use container-canonical scene hashes.
- Confirmed: container material writing, deterministic semantic checks, the prepared-view contract, multi-selector safety on 25 controlled updates and a two-model one-repeat development sizing path. Refuted or left open: host/container scene identity for the old held-out materials, human masked-versus-audit agreement, data-key-only safety, five-repeat precision, held-out semantic extension and runnable engineering baselines.
- Design consequence: M6 closes as a measured feasibility and reproducibility slice. It does not establish the main A-versus-B claim, a confidence interval, an open-world audit ordering or the 1% anchor criterion.
- Related log: `dev_logs/2026-11-17-m6-complete.md`. No `NEWS.md` entry is needed because this slice adds bench evaluation artifacts and changes no package-facing behavior.
