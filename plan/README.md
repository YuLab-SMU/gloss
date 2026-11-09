# plan

Plans for the next slice of work, with task-by-task tracking. A plan is the current hypothesis about what to do next; tests and measurements decide whether it holds. Files here are **committed work**, unlike `idea/` (exploration).

## Conventions

- **Filename:** `YYYY-MM-DD-<slug>.md`, dated when the plan opens.
- **Scope: the next slice that can be finished and measured.** The milestones M0–M5 in [design §实施计划](../dev_docs/design.qmd#sec-plan) are a provisional map. A plan may cover part of a milestone, or cut across two, when the evidence says so. Write out in detail only the tasks you can see clearly; leave later ones as one-line stubs and fill them in once the earlier results are in.
- **Start from a measured state.** The header records the suite counts and the numbers the plan means to move, on the day it opens, with the commands that produced them.
- **Riskiest assumption first.** List what the plan assumes that could turn out wrong, and order the tasks so the first ones test it.
- **Status discipline:** `[ ]` not started, `[~]` in progress, `[x]` done (record the command and the observed result: counts, numbers, figure set), `[!]` blocked (note the blocker), `[-]` cancelled (note the reason).
- **Update when a task lands,** in the same commit as the code.
- **Re-plan when the evidence says so.** Stop and revise the open tasks when:
  - a test or measurement contradicts an assumption of the plan or of the design;
  - a completion criterion turns out to be unmeasurable, or to measure the wrong thing;
  - real figures show a failure class the plan did not foresee;
  - a task stays blocked.

  Append a `Scope change` that names the evidence (command, number, figure) and says which open tasks or criteria changed. Completion criteria can be revised this way too; the evaluation integrity rules in [`AGENTS.md`](../AGENTS.md) cannot.
- **Never silently rewrite a `[x]` task.** Append a dated `Scope change` instead.
- **When a plan closes:** fill in the closing notes (end state against starting state, assumptions confirmed or refuted, what moved in the design), move the file to `plan/done/`, write a closing `dev_logs/` entry, and plan the next slice from what was measured.

## Template

See [`_template.md`](_template.md).

## Active plans

- [2026-11-09-m0-substrate.md](2026-11-09-m0-substrate.md): M0, the substrate. Tasks 1–8 and 10 done; Task 9 (benchmark sampling, split and freeze) open.

## Completed plans

_(none yet)_
