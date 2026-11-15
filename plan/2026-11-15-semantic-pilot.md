# Semantic pilot: checked claims before records

> Status: active
> Date opened: 2026-11-15. Owner: Codex.

**Goal:** Measure, on a controlled claim fixture, which parts of a semantic declaration are decided by code, which survive as checked model proposals, and which need a targeted human audit.

**Why now:** M1 closed the role and binding questions narrowly. [ADR-0010](../dev_docs/decisions/0010-targeted-human-audits-and-evidence-bearing-correspondence.md) says the next evaluation should start with a semantic pilot rather than broad role annotation. The latest reflection records that no semantic pilot has yet been run ([dev log](../dev_logs/2026-11-15-m1-reflection.md)).

**Research-card clause:** The claim that declaration verification catches false statements rather than merely reducing coverage (design §研究卡片, `声明核验拦下错误靠的是检查，不是少答`). This clause currently has one worked example but no package-level check path, proposal comparison, or audit yield measurement.

**Starting state (measured):** `NOT_CRAN=true Rscript -e "devtools::test()"` on 2026-11-15: 17 test files, 1450 expectations, 0 failures, 0 skips. The package has `gl_propose()` for checked binding proposals, but no public semantic-check runner and no claim proposal/audit experiment.

**Assumptions to test:**

1. A closed check can distinguish a verified claim, a false claim, a partially true claim and a claim it cannot run, while preserving group-level evidence. Task 1 tests this; a failure changes the check vocabulary before any model run.
2. Model proposals can be evaluated by the same schema and check result as code-generated proposals, without treating a plausible sentence as verified. Task 2 tests this; if the proposal boundary needs record or anchor state, the plan stops before M2 and records the missing contract.
3. Targeted audits are more useful when sampled from unresolved or decision-changing cases than when applied broadly. Task 3 measures the audit queue and its potential rule/route changes; it does not claim human agreement until an independent audit is completed.

**Architecture:** Add a small, plugin-backed semantic check runner for built-data claims, starting with the existing `trend` example. Keep it separate from append-only records and anchors. Add a bench pilot that runs deterministic checks, validates a fixed proposal fixture through the same boundary, and emits an evidence-bearing audit queue. The pilot is development evidence only; no held-out figures or production record schema are changed.

**Out of scope:** M2 record storage, anchor rebasing, update propagation, relation persistence, real-model gateway runs, broad human labelling, and new extension-package-specific binding rules.

**Tech stack:** R >= 4.2, existing plugin registry and schema language, testthat 3, base `stats`, and the frozen `mtcars` claim fixture. Optional model/audit inputs remain file-based and offline by default.

**Done when:**

- the `trend` check has contract tests for verified, failed, partial and refused groups;
- a deterministic pilot reports the four evidence outcomes and emits a queue containing only cases that code cannot settle or that could change the route;
- proposal validation uses the same check result and never upgrades a failed/partial/refused claim to verified;
- the plan and dev log record counts, cases, and the cost in `R/`, `tests/`, and bench runs.

---

## Progress tracking

**Status legend**
- `[ ]` Not started
- `[~]` In progress
- `[x]` Completed
- `[!]` Blocked
- `[-]` Cancelled

**Current state** _(update as results come in)_
- Suite: 17 files, 1477 expectations, 0 failures, 0 skips (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-15).
- Key numbers: the first `trend` check on the full mtcars point layer returns 5/6 negative slopes and one positive slope (`partial`); the 8-cylinder subset returns `verified`.

**Overall progress**
- [x] Task 1: Add and test the closed `trend` semantic check.
- [ ] Task 2: Run the offline proposal comparison through the same check boundary.
- [ ] Task 3: Produce the targeted audit queue, update design/logs, and decide whether a larger pilot or M2 should follow.

---

### Task 1: Closed trend check with group evidence

**Status:** `[x]`

**Tests assumption:** Assumption 1.

**Files**
- Create: `R/semantic-checks.R`, `tests/testthat/test-semantic-checks.R`.
- Modify: `R/zzz.R`, `NAMESPACE` via `devtools::document()` if the runner is exported.

**Intent**
- Turn the existing `heavier = thirstier` worked example into a reusable deterministic check over built data. Keep the per-group slope, sample size, pass/fail and refusal reason so a partial result is evidence rather than a boolean.

**Checklist**
- [x] Register the built-in check through `gl_register("check", ...)`.
- [x] Return `verified`, `failed`, `partial` or `refused` with group-level evidence.
- [x] Test malformed schemas, missing columns, all-pass, mixed, all-fail and no-runnable-group inputs.

**Verification**
- `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-semantic-checks.R')"`.
- `NOT_CRAN=true Rscript -e "devtools::test()"` after the task.

**Result** _(filled in when done)_
- `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-semantic-checks.R')"` → 26 expectations, 0 failures, 0 skips.
- `NOT_CRAN=true Rscript -e "devtools::test()"` → 17 files, 1477 expectations, 0 failures, 0 skips.
- `Rscript` over the built mtcars point layer → `partial`, 5/6 groups passed, one slope `+3.067891`; the filtered 8-cylinder table → `verified`. Cost: 1 new `R/` file (194 lines), 1 test file (72 lines), documentation/NAMESPACE regeneration; no benchmark run yet.

---

### Task 2: Offline proposal comparison

**Status:** `[ ]`

**Tests assumption:** Assumption 2.

**Files**
- Create: `bench/semantic/pilot.R`, `bench/semantic/proposals.csv` (or an equivalent frozen input and output archive).
- Modify: this plan and the dev log with the measured run.

**Intent**
- Give code-generated and proposal-generated claims the same closed check. The fixture must include a true claim, a false claim, a partial claim and an unsupported/open-world claim, so a proposal cannot gain credit by abstaining.

**Checklist**
- [ ] Freeze the proposal cases before running the scorer.
- [ ] Report coverage, verified/partial/failed/refused counts, and false-claim rejection separately.
- [ ] Keep the model arm explicitly offline unless a later run supplies an archived model trace.

**Verification**
- `Rscript bench/semantic/pilot.R --dry`.
- The output names every case, its proposal source, check status and whether it can enter the audit queue.

**Result** _(filled in when done)_
- Pending.

---

### Task 3: Targeted audit queue and route decision

**Status:** `[ ]`

**Tests assumption:** Assumption 3.

**Files**
- Modify: `bench/semantic/pilot.R`, `dev_docs/design.qmd`, `plan/README.md`, and a dated `dev_logs/` entry.

**Intent**
- Sample only cases where the check refuses, returns partial evidence, or a proposal introduces an open-world relation/meaning that code cannot decide. Record the question and available evidence so an independent audit can change a rule, score or route.

**Checklist**
- [ ] Emit a compact audit sheet with an explicit decision question and evidence payload.
- [ ] Run or queue a small independent audit; report agreement and any rule/route change separately from code outcomes.
- [ ] Close the plan only if the evidence says a larger semantic pilot is warranted, or record why M2 should start instead.

**Verification**
- `Rscript bench/semantic/pilot.R --dry` and review the audit queue.
- Full suite and, if any code reads device output, the required bench-container suite.

**Result** _(filled in when done)_
- Pending.

---

## Scope changes

_(append-only; none yet.)_

## Closing notes

Filled in when the plan moves to `done/`.
