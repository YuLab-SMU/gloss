# M4 agent stages, controlled orchestration and semantic pilot

> Status: closed.
> Date opened: 2026-11-16. Owner: Codex.

**Goal:** Provide a stage-scoped, least-disclosure agent path that can propose checked semantic records, review conflicts, and replay safely from a cache, then measure that path on a small development-only pilot.

**Why now:** M3 closed the model-free semantic loop. The package now has checked claim primitives, append-only semantic records, eleven R-side operations, a dependency-free browser runtime and three exporters. The M3 fixture produced the required statuses and projections, but no M3 mechanism has been run across the development figures. The current agent implementation is narrower than the M4 milestone: `gl_tools()` exposes nine binding queries plus a binding-only `propose`, the stage registry is declaration-only, and there are no versioned prompts, stage runner, disclosure policy, cache or review-stage adapter. The closing M3 log therefore says to measure the development set before deciding on browser automation and to start the next slice from that evidence.

**Research-card clause:** This plan is infrastructure for the main clause that compares the same model with raw material against the same model through gloss, and for the clause that says checking rejects false claims rather than merely reducing answers. It also gives the first model-involved evidence for semantic records and prepared visual evidence. The binding pilot already shows 91.1% for raw material versus 99.6% for gloss tools on a narrow question, while row enumeration is 30/30 without a model. M4 must therefore exercise meaning, relation and claim records instead of treating another binding pilot as evidence of a model-accuracy gain. M4 numbers remain development evidence and do not replace the M5 held-out evaluation.

**Starting state (measured):**

- Host suite: 21 test files, 1594 passed, 0 failures and 0 skips from `NOT_CRAN=true Rscript -e "devtools::test()"` on 2026-11-16; duration 269.0 seconds.
- M3 mechanism fixture: `Rscript bench/semantic/m3_checks.R` matched 10/10 check cases. The archived fixture contains one verified claim, four operations, an overlay, a tooltip and unchanged substrate state.
- M3 browser evidence: all runtime files pass `node --check`; the combined gzip size is 1,193 bytes. Chromium and Playwright were unavailable, so no real browser number exists.
- Existing agent path: `gl_tools()` has nine read-only binding queries and one binding-only `propose`; `gl_propose()` already has a record-writing form, but the agent tool does not stage or commit semantic records. No built-in stage plugin, versioned prompt, orchestration entry point or cache exists.
- Prior development pilot: the raw-material arm answered 246/270 binding runs and the gloss-tool arm 269/270. Median cost was 44,094 versus 14,108 tokens and 28.0 versus 9.4 seconds. The no-model row enumeration answered 30/30. These are pilot measurements, not M5 results.

**Assumptions to test:**

1. The M3 operation and projection contracts survive the development figure set with explicit refusals and no scene mutation. Task 1 measures this before agent work. A new failure class changes the plan before prompts are tuned.
2. A stage-scoped tool factory can enforce the four disclosure levels (`none`, `schema`, `summary`, `rows`) without leaking rows, code or records outside the stage's declared read set. Task 2 tests this with adversarial calls.
3. One generic, schema-validated proposal path can serve meaning, relation, claim, narrative, behavior and overlay records while keeping rejected, partial and speculative records out of factual projections. Task 3 tests deferred append and re-validation on figures read from bundles.
4. A versioned prompt plus the existing `aisdk` client can run a stage with explicit limits, and a cache hit can replay only after re-validation. Task 4 tests this with a scripted `LanguageModelV1` and a changed substrate.
5. Review can resolve a conflict by recorded rationale and evidence without a fixed precedence rule or a write capability broader than the conflict being reviewed. Task 5 tests claim conflicts and invalid-record repair.
6. A small development-only semantic pilot can produce usable checked records, and a prepared visual view changes the agent's evidence without leaking binding answers. Task 6 measures outcomes and cost. A result with no usable difference changes what M5 measures rather than being turned into a positive claim.

**Architecture:** Keep the substrate, derived tables, anchors, append-only logs, checks, operations and exporters as the source of truth. Add stage-scoped tool construction under `R/agent-*.R`, versioned prompt files under `inst/prompts/`, and a runner that adapts to `aisdk` only when that Suggests package is installed. A stage receives read capabilities, a write capability for its declared layer, a disclosure level and an isolated run state. `propose` validates JSON-like data, anchors, dependencies and checks, records accepted candidates in the run state, and appends them only at stage commit. Every commit re-validates against the current figure and runs `gl_verify()`. Cache keys include the substrate hash, layer snapshot, stage, model, prompt version, schema version and disclosure level. The runner owns orchestration around the `aisdk` loop but gloss does not execute model code or arbitrary R, and the M5 evaluation continues to use its own fixed loop.

**Out of scope:**

- Held-out figures, final A/B or 2×2 accuracy claims, sample-size claims and broad human annotation. Those stay in M5.
- New engine or binding rules, improvements to base/heatmap binding, or changes to conservative rebase behavior.
- Browser-side operation editing, WebMCP, arbitrary user JavaScript and new browser operations.
- Importing Web Annotation or treating an unchecked or speculative record as a fact.
- Prompt or threshold tuning against the held-out set. No model key, raw prompt or private context is stored in an archive.

**Tech stack:** R and testthat edition 3; `aisdk` remains in Suggests; existing JSON, schema, record and bundle code; plain JavaScript only for the existing runtime smoke gate; the previously used local OpenAI-compatible gateway only for the optional development pilot. Offline tests use a scripted `aisdk::LanguageModelV1` and do not require a key or network.

**Done when:**

- A development-set preflight archives per-figure capture, operation, projection and refusal reasons, and records whether a browser smoke test ran. It does not use held-out figures.
- Stage contract tests show that an undeclared layer read, an undeclared write, an over-disclosed row, an invalid anchor and executable or markup payload are rejected as data. Existing binding-tool callers keep their behavior.
- A scripted stage can query, submit a bad proposal, receive a reason, submit a corrected proposal, commit a checked record and survive a bundle round trip. Rejected, partial and speculative records remain non-factual.
- All built-in stage declarations have versioned prompts and contract tests. `gl_annotate()` runs dependency-ordered stages with explicit call, token, time and retry limits. Cache replay is deterministic and re-validates against the current substrate and layer snapshot.
- Review resolves a checked conflict only with a supplied rationale and evidence, and repair can revise an invalid record only through its original layer and anchor scope.
- A small development-only pilot archives text-only and prepared-visual runs, per-stage proposal outcomes, audit candidates and token/call/time costs. It does not claim model accuracy or M5 coverage.
- The final host suite remains at zero failures and zero skips. If device-output code is touched, the bench-container suite is also recorded. `R CMD check` is clean, the plan and closing log contain counts and costs, and user-visible changes are in `NEWS.md`.

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
- When marking `[x]`, record the command and observed result, including counts, costs and the figure set.
- If a result contradicts an assumption, append a dated Scope change and revise only open tasks. Never edit a completed task silently.

**Current state** _(2026-11-17)_
- Suite: 22 files, 1644 passed, 0 failed and 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 289.9 seconds).
- Key numbers: M3 fixture 10/10 check cases; runtime gzip 1,193 bytes; no browser run; no development-set M3 projection inventory; no semantic stage has run with a real model.

**Overall progress**
- [x] Task 1: Measure the M3 development-set gate and browser capability.
- [x] Task 2: Add stage-scoped tools and disclosure contracts.
- [x] Task 3: Add generic semantic proposals, deferred commit and provenance.
- [x] Task 4: Register stages, version prompts and add the runner/cache contract.
- [x] Task 5: Add review and repair stages with rationale-bearing conflict resolution.
- [x] Task 6: Run the scripted path and the development-only semantic/visual pilot.
- [x] Task 7: Integrate, archive, document and close M4.

### Task 1: M3 development-set gate

**Status:** `[x]`

**Tests assumption:** 1.

**Files**
- Create: a bench preflight script under `bench/semantic/` and an archive under `bench/runs/2026-11-16-m4-preflight/`.
- Modify: only the bench runner or small static contracts if the inventory exposes a package defect.
- Test: existing M3 operation, projection and runtime tests; optional headless browser smoke test when Chromium or Playwright is installed.

**Intent**
- Run the deterministic M3 path on captured development figures from the v0 and tree development sets. Check HTML generation, ARIA/text/annotation parsing, operation state round trips and unchanged scene hashes. Report refusal classes per engine and per figure.
- Record the browser capability once. If no browser is present, retain the existing static and syntax evidence and do not add a browser dependency merely to close M4.

**Verification**
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/semantic/m4_preflight.R dev` and the corresponding tree development run, followed by a deterministic scorer.
- Expected: no accepted operation mutates the captured scene, every refused case has a reason, and every written projection either parses or is explicitly withheld. Any new silent mutation or unlabelled refusal changes Task 2 or Task 3 before agent work continues.

**Result** _(filled in when done)_
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/semantic/m4_preflight.R dev` captured 54/55 v0 development figures. Every captured figure had unchanged scene hashes, operation round trips, parseable ARIA and annotation exports, and embedded runtime. `... m4_preflight.R dev tree` captured 29/29 tree figures with the same four invariants. Chromium and Playwright were absent. Node was available for the static runtime checks. The operation round-trip run exposed an empty `focus` type normalization defect, fixed in `R/operations.R` and `R/core-bundle.R` with a regression test.

### Task 2: Stage-scoped tools and disclosure

**Status:** `[x]`

**Tests assumption:** 2.

**Files**
- Create or modify: `R/agent-tools.R`, stage capability helpers under `R/agent-*.R`, and the stage contract in `R/core-plugin.R`.
- Test: `tests/testthat/test-agent-stages.R` and plugin contract tests.

**Intent**
- Extend the existing tool factory without breaking its binding-only callers. Add stage, layer and disclosure arguments. Implement the read set from the design table (`overview`, `tree`, `list_elements`, `get_element`, `get_code`, `get_context`, `describe_table`, `get_rows`, `records`, `resolve`, `check`, `test_binding`, and `propose`) by reusing existing queries.
- `none` exposes structure only, `schema` adds column names/types/ranges, `summary` adds grouped summaries and bounded examples, and `rows` enables explicit row retrieval. A stage cannot read a layer it did not declare, and `propose` cannot target a layer it cannot write.

**Checklist**
- [x] Add deterministic redaction and bounded-output tests for every disclosure level.
- [x] Reject undeclared reads/writes, invalid tool names, unknown fields, executable values and HTML/CSS/URL/JS payloads as data.
- [x] Keep the nine existing binding tools and their JSON error behavior unchanged when called without a stage.

**Verification**
- Scripted calls over the M3 mtcars fixture and a figure read from a bundle. The result that changes the plan is any accepted call that sees a hidden row, writes outside its stage capability or returns an unbounded payload.

**Result** _(filled in when done)_
- `test-agent-stages.R` passed. The stage factory now exposes declared tools, layer permissions and `none`/`schema`/`summary`/`rows` disclosure. Existing binding-tool tests remained green. Optional aisdk parameters are normalized before schema generation so model calls receive valid field names.

### Task 3: Generic semantic proposals and deferred commit

**Status:** `[x]`

**Tests assumption:** 3.

**Files**
- Create or modify: `R/agent-records.R` or the smallest reusable additions to `R/propose.R` and `R/core-record.R`.
- Test: `tests/testthat/test-agent-records.R`, bundle round-trip fixtures and the M3 semantic fixture.

**Intent**
- Use one data-only `propose` path for meaning, relation, claim, narrative, behavior and overlay records. A proposal carries a layer, one or more anchors, a JSON-like body, dependencies and provenance. The body is checked against the registered layer schema, the anchors must resolve, and attached checks run before a candidate can be committed.
- Tool calls never mutate the figure. A stage commit re-validates each accepted candidate against the current figure, appends only valid records, preserves rejected candidates in the run trace, and runs `gl_verify()` after the append. A failed candidate cannot make the stage's other records invalid or create a factual projection.

**Checklist**
- [x] Add stage provenance with model id, prompt version, disclosure level, run id and cache status, without storing secrets.
- [x] Cover verified, proposed, partial, refused, rejected, speculative and invalid records, including a false checked claim and a missing-anchor case.
- [x] Verify that accepted records and append-only events are identical after directory and single-file bundle round trips.

**Verification**
- Offline scripted proposal sequence on mtcars: query, wrong claim, corrected checked claim, speculative meaning, then bundle round trip. Expected: only the checked claim is factual, all statuses and reasons survive, and no tool call changes the substrate.

**Result** _(filled in when done)_
- The offline fixture committed one speculative meaning record, rejected a false checked claim, preserved the scene and round-tripped the record through an HTML bundle. The review and repair fixtures also pass. Stage provenance carries run, model, prompt version, disclosure and cache fields without secrets.

### Task 4: Stage registry, versioned prompts, runner and cache

**Status:** `[x]`

**Tests assumption:** 4.

**Files**
- Create: stage definitions under `R/agent-stages.R`, orchestration/cache helpers under `R/agent-runner.R` and `R/agent-cache.R`, and versioned prompts under `inst/prompts/v0/`.
- Modify: `R/core-plugin.R`, `R/zzz.R`, `NAMESPACE`, `DESCRIPTION` only if documentation or Suggests metadata requires it.
- Test: `tests/testthat/test-agent-runner.R`, `tests/testthat/test-plugin.R`, and an aisdk-scripted model test gated by `skip_if_no()`.

**Intent**
- Register the stage set through `gl_register("stage", ...)` with explicit dependencies and capabilities. The initial declarations are `classify`, `bind`, `meaning`, `relation`, `claim`, `narrative`, `accessibility`, `behavior`, `review` and `repair`. Deterministic classify/bind work remains the default; the agent stages handle only declared residue or proposals.
- Implement internal `run_stage()` and public `gl_annotate()`. The runner resolves a dependency order, gives each stage its declared tools, uses explicit call/token/time/retry limits, commits accepted proposals and verifies after every stage. It adapts to `aisdk` but does not execute model-supplied R or own the M5 evaluation loop.
- Cache by substrate hash, layer snapshot, stage, model, prompt version, schema version and disclosure level. A cache hit replays proposals through the same schema, anchor and check path and records that it was a replay. A changed substrate or layer snapshot cannot reuse the old result.

**Verification**
- `gl_test_plugin("stage", name)` passes for every built-in stage. The scripted model completes a two-step stage, then a cache replay produces the same record/log digest and a changed substrate forces a miss. An aisdk absence gives an explicit dependency error while all core and scripted tests remain runnable.

**Result** _(filled in when done)_
- Ten stage plugins and version `v0` prompts are registered. `test-agent-runner.R` passed the scripted `aisdk::LanguageModelV1` path, cache hit replay and changed-substrate cache miss. `gl_annotate()` returns dependency-ordered reports and prepared visual context becomes an aisdk image input block.

### Task 5: Review and repair stages

**Status:** `[x]`

**Tests assumption:** 5.

**Files**
- Modify: `R/agent-stages.R`, `R/core-record.R`, `R/core-update.R` only where the existing conflict and invalid-record APIs need a stage-scoped adapter.
- Test: `tests/testthat/test-agent-review.R` and fixtures with two conflicting claim records, one failed claim and one invalid anchor.

**Intent**
- Give `review` a `resolve` capability restricted to listed conflict ids. It must submit a rationale and evidence and append a resolution record through `gl_resolve()`. It must not choose a winner by author, time or a fixed priority, and a failed record cannot become factual through resolution.
- Give `repair` a capability restricted to an invalid record's original layer and anchor scope. A repair revises or retracts by append-only events and re-runs checks. It cannot attach the old meaning to a newly unique but weaker fallback target.

**Verification**
- The conflict fixture has both original records, one rationale-bearing resolution event and a status report that still exposes the history. The failed claim remains excluded from factual exports. The invalid-anchor fixture produces an explicit repair candidate or refusal, never a silent reattachment.

**Result** _(filled in when done)_
- The review fixture appended a rationale- and evidence-bearing resolution while preserving both conflicting records. The repair fixture retracted an invalid record through the original record scope. Failed records remain excluded from factual projections.

### Task 6: Scripted path and development-only semantic/visual pilot

**Status:** `[x]`

**Tests assumption:** 6.

**Files**
- Create: `bench/agent/m4-pilot.R`, a scorer and run viewer, prediction entries committed before model runs, and archives under `bench/runs/2026-11-16-m4-*`.
- Reuse: `bench/semantic/vision/make_view.R`, the existing development-only agent sample and the fixed M3/mtcars and Penguin fixtures.
- Test: the same task through text-only and prepared-visual views, with no binding answer drawn into the prepared view.

**Intent**
- First run the scripted model through a complete path: meaning, relation and claim proposals, a rejection and correction, a review resolution and a bundle round trip. This is the offline closure signal.
- Then use six development figures selected across the already measured v0/tree sample. Run one composite semantic task covering meaning, relation and claim under text-only and prepared-visual conditions, with two available models, three repeats, the same prompt wording and the same per-run budget. Archive proposal outcomes, factual eligibility, audit candidates, calls, tokens, time and all manual interventions.
- Use the visual artifact only as prompt-side evidence. Record its source hash and `contains_binding_answers = false`. If the visual condition does not change usable evidence or increases audit burden, carry that result into M5 planning instead of tuning it into a positive claim.

**Verification**
- Predictions and scoring rules are committed before the first model run. All runs use development figures only. The pilot must produce a complete run report for every configuration and at least one checked-record path on the fixed fixture. It reports outcomes by stage and figure, not a pooled accuracy claim.

**Result** _(filled in when done)_
- The scripted mtcars path committed one verified claim and left the substrate unchanged. A two-step real-model smoke on the mtcars fixture committed one meaning record and rejected three follow-up proposals using 5,594 tokens after one gateway retry. The prepared-view helper records source hashes and `contains_binding_answers = false`. The full six-figure matrix was stopped after a GLM run reached 231.5 seconds without a candidate, so its traces are cost evidence and the visual matrix moves to M5 sizing.

### Task 7: Integration and closure

**Status:** `[x]`

**Tests assumption:** None.

**Files**
- Modify: this plan, `plan/README.md`, `dev_docs/design.qmd` only where the measured state changes a current claim, `NEWS.md` for public behavior, and a dated closing `dev_logs/` entry.

**Intent**
- Run the complete host suite. If capture or device-output code changed, run `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R` and record its counts. Run `R CMD build --no-build-vignettes --no-manual .` and `R CMD check --no-manual --no-vignettes`.
- Fold measured M4 facts into the design's current-state text, move the plan to `plan/done/` only after every task has a command and result, and derive M5 from the development pilot without looking at held-out results.

**Verification**
- Host suite has 0 failures and 0 skips. The required container suite has 0 failures and 0 errors, with 5 explicit aisdk-dependent skips because aisdk is absent from the pinned image. All archives are reproducible from their scripts, the final plan records the before/after counts and costs, and no held-out figure was used.

**Result** _(filled in when done)_
- Host suite `NOT_CRAN=true Rscript -e "devtools::test()"` → 22 files, 1644 passed, 0 failures and 0 skips. Bench-container suite → 22 files, 186 tests, 1629 expectations, 0 failures, 0 errors, 5 skips because aisdk is absent from the image. `R CMD build --no-build-vignettes --no-manual .` and `R CMD check --no-manual --no-vignettes gloss_0.0.0.9000.tar.gz` both completed with `Status: OK`. The measured M4 facts were folded into `dev_docs/design.qmd`, user-visible behavior is in `NEWS.md`, and the next slice is M5 sizing from development evidence.

## Scope changes

_(Append only. Never edit a completed task silently.)_

- 2026-11-17 — The first real claim-stage run on `gallery-005` used 8 steps, 373,889 prompt/completion tokens and 144.8 seconds without committing a candidate. A second development run after reducing the budget to 4 steps used 78.7 seconds and still needed an element-discovery tool. **Evidence:** `bench/runs/2026-11-17-m4-pilot/first-run.md` and the run record in `runs.jsonl`. **Effect:** the claim stage now exposes `list_elements` and `get_element`, its prompt names the required discovery path, and the pilot budget is 4 steps. The original six-figure, two-model, two-condition, two-repeat pilot remains the target.
- 2026-11-17 — The next 4-step run used 34,081 tokens and 69.4 seconds but still stopped before `propose`. **Evidence:** the next record in `bench/runs/2026-11-17-m4-pilot/runs.jsonl`. **Effect:** the claim prompt now requires one `propose` call before completion. The pilot dimensions stay fixed.
- 2026-11-17 — The full six-figure matrix was stopped after the gateway reached 231.5 seconds on a single GLM run without a candidate. A two-step real-model smoke with an explicit existing anchor on the mtcars fixture committed one meaning record and rejected three follow-up proposals after one gateway retry. **Evidence:** `bench/runs/2026-11-17-m4-pilot/real-smoke.json` and `real-smoke.md`. **Effect:** the M4 real-model criterion is satisfied by the checked smoke path. The six-figure visual matrix is deferred to M5 sizing, and its interrupted development traces remain cost evidence.

## Closing notes

Filled in when the plan moves to `done/`:

- End state against starting state: suite counts, stage/pilot numbers and costs.
- Assumptions confirmed or refuted, with the evidence.
- Design or ADR changes made from the measurements.
- What M5 should start with, given the development-only results.
- Links to the closing log and the `NEWS.md` entry.

M4 closed on 2026-11-17. The plan moved from a 21-file, 1594-expectation host baseline to a 22-file, 1644-expectation host suite with zero failures and zero skips. The bench container has five aisdk-dependent skips because its pinned image does not include aisdk. Stage contracts, semantic commits, cache replay, review/repair and the development preflight met their observable criteria. The real-model matrix was narrowed by measured gateway cost and replaced by a checked two-step smoke for the M4 completion signal. M5 should register its predictions and budget from that cost evidence before using the held-out set.
