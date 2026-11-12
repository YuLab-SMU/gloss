# <Plan title>

> Status: active | completed | abandoned.
> Date opened: YYYY-MM-DD. Owner: <name>.

**Goal:** One sentence stating the outcome, phrased so that a test or a measurement can show it.

**Why now:** The evidence that set this scope: a dev log's surprises or next steps, a failing test, a measurement, an ADR follow-up. Link it.

**Research-card clause:** Which clause of design §研究卡片 this plan gives evidence for, and whether that clause has any data today. If the plan is infrastructure for a later clause, say which and why it cannot be thinner.

**Starting state (measured):** Suite counts on the opening date (files, tests, expectations, failures, skips) and any number this plan means to move, each with the command that produced it.

**Assumptions to test:** What this plan believes that could turn out wrong, riskiest first. For each: the task that tests it, and the result that would change the plan.

**Architecture:** One paragraph on the shape of the change. What is being touched, what is intentionally not being touched.

**Out of scope:** A short list. Pre-empt scope creep.

**Tech stack:** R, packages, external services.

**Done when:** Observable checks with thresholds, and the figure set each runs on (fixtures, bench development set). A criterion can be revised by a `Scope change` that names its evidence.

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
- Suite: N files, N tests, N expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, YYYY-MM-DD).
- Key numbers: ...

**Overall progress**
- [ ] Task 1: ...
- [ ] Task 2: ...
- [ ] Task 3: ... _(stub; written out after the results of Tasks 1–2)_

---

### Task 1: <name>

**Status:** `[ ]`

**Tests assumption:** which one from the header, or none.

**Files**
- Create: ...
- Modify: ...
- Test: ...

**Intent**
- Why this task exists; what failure mode it closes.

**Checklist**
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

**Verification**
- Command(s) to run.
- Expected result, and the result that would change the plan.

**Result** _(filled in when done)_
- Command and observed output. What it cost beside what it moved (lines added under `R/` and `tests/`, runs made). Anything surprising also goes to the dev log, and to `Scope changes` if it changes the plan.

---

### Task 2: <name>

...

---

## Scope changes

_(append-only; never edit completed tasks above)_

- YYYY-MM-DD — what changed. **Evidence:** command, number or figure. **Effect:** which open tasks or criteria changed.

## Closing notes

Filled in when the plan moves to `done/`:

- End state against starting state: suite counts and key numbers.
- Assumptions confirmed or refuted, with the evidence.
- What moved in the design doc or the ADRs.
- What the next plan should start with, given these results.
- Links to the closing dev log and the NEWS.md entry.
