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

- [2026-11-11-m1-roles-and-binding.md](2026-11-11-m1-roles-and-binding.md): M1, first slice: roles and bindings on the development set. Opened 2026-11-11; the owner's three decisions settled. Scope change of 2026-11-12: few rules, with the open tasks read under ADR-0009 (accepted 2026-11-12).
- [2026-11-11-tree-binding.md](2026-11-11-tree-binding.md): gloss on the tree stratum's development half: every page captured or refused with a reason; justified, rotated and polar labels and glyph outlines checked or named. Opened 2026-11-11 on the owner's word. Tasks 1-6 done: 92.3% of layer elements checked on the development half, none failed. The owner stopped rule-writing on 2026-11-12 (Scope changes; ADR-0009, accepted the same day). Open: Task 7, the held-out half once with the binder frozen (decision 1 (a)), and the closing notes.

## Completed plans

- [2026-11-09-m0-substrate.md](done/2026-11-09-m0-substrate.md): M0, the substrate. Closed 2026-11-11; code landed 2026-11-09, Task 9 (benchmark) carried out under bench v0. Six input classes identical to plain svglite; lossless round trip; 10^5 points in 2.65 MiB.
- [2026-11-09-bench-v0.md](done/2026-11-09-bench-v0.md): sample and freeze the benchmark; first capture feedback. Closed 2026-11-11. 109 of 160 eligible, 55 development / 54 held-out, frozen in `e985d82`; the fidelity gap it found led to ADR-0006.
- [2026-11-11-page-capture.md](done/2026-11-11-page-capture.md): capture the page the input draws ([ADR-0006](../dev_docs/decisions/0006-capture-the-page-the-figure-draws.md)). Closed 2026-11-11. Development set: 52 equal, 2 not deterministic, 1 refused of 55. Held-out set, one run: 50 equal, 2 not deterministic, 2 refused of 54; no figure captured as another one.
- [2026-11-11-bench-tree-stratum.md](done/2026-11-11-bench-tree-stratum.md): bench v1, a stratum of tree figures (the ggtree family), reported apart from v0. Closed 2026-11-11. 57 of 83 PSUs give a figure, 29 development / 28 held-out. First runs on the development half: 28 of 29 captured (27 `equal`); 40.1% of layer elements checked by binding, every element in 15 of 27 ggplot figures. gloss unchanged; six classes of shortfall listed for the next plan.
