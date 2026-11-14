# plan

Plans for the next slice of work, with task-by-task tracking. A plan is the current hypothesis about what to do next; tests and measurements decide whether it holds. Files here are **committed work**, unlike `idea/` (exploration).

## Conventions

- **Filename:** `YYYY-MM-DD-<slug>.md`, dated when the plan opens.
- **Scope: the next slice that can be finished and measured.** The milestones M0–M5 in [design §实施计划](../dev_docs/design.qmd#sec-plan) are a provisional map. A plan may cover part of a milestone, or cut across two, when the evidence says so. Write out in detail only the tasks you can see clearly; leave later ones as one-line stubs and fill them in once the earlier results are in.
- **Start from a measured state.** The header records the suite counts and the numbers the plan means to move, on the day it opens, with the commands that produced them.
- **Riskiest assumption first.** List what the plan assumes that could turn out wrong, and order the tasks so the first ones test it. The same holds across plans: the header names the clause of the research card ([design §研究卡片](../dev_docs/design.qmd#sec-research-card)) the plan gives evidence for, or says that it is infrastructure and why that comes first.
- **Status discipline:** `[ ]` not started, `[~]` in progress, `[x]` done (record the command and the observed result: counts, numbers, figure set), `[!]` blocked (note the blocker), `[-]` cancelled (note the reason).
- **Update when a task lands,** in the same commit as the code.
- **Re-plan when the evidence says so.** Stop and revise the open tasks when:
  - a test or measurement contradicts an assumption of the plan or of the design;
  - a completion criterion turns out to be unmeasurable, or to measure the wrong thing;
  - real figures show a failure class the plan did not foresee;
  - a task stays blocked.

  Append a `Scope change` that names the evidence (command, number, figure) and says which open tasks or criteria changed. Completion criteria can be revised this way too; the evaluation integrity rules in [`AGENTS.md`](../AGENTS.md) cannot.
- **Never silently rewrite a `[x]` task.** Append a dated `Scope change` instead.
- **When a plan closes:** fill in the closing notes (end state against starting state, assumptions confirmed or refuted, what moved in the design), fold the dated notes the plan added to the design into the text of their sections (the history stays in the design's §与上一版的区别 and in the closing notes), move the file to `plan/done/`, write a closing `dev_logs/` entry, and plan the next slice from what was measured. Links to the plan in files that are not append-only are repointed; old dev logs keep the path they were written with.

## Template

See [`_template.md`](_template.md).

## Active plans

- [2026-11-11-m1-roles-and-binding.md](2026-11-11-m1-roles-and-binding.md): M1, first slice: roles and bindings on the development set. Opened 2026-11-11; the owner's three decisions settled. Scope change of 2026-11-12: few rules, with the open tasks read under ADR-0009 (accepted 2026-11-12).

## Completed plans

- [2026-11-14-semantic-storyboard.md](done/2026-11-14-semantic-storyboard.md): the guided six-layer Penguin storyboard. Closed 2026-11-14. The primary path now uses one shared add/advance action and makes each semantic layer visibly change the same figure; duplicate Overview proposal controls are removed from the main experience. The full package suite remains clean (1422 passed, 0 failed, 0 skipped).

- [2026-11-09-m0-substrate.md](done/2026-11-09-m0-substrate.md): M0, the substrate. Closed 2026-11-11; code landed 2026-11-09, Task 9 (benchmark) carried out under bench v0. Six input classes identical to plain svglite; lossless round trip; 10^5 points in 2.65 MiB.
- [2026-11-09-bench-v0.md](done/2026-11-09-bench-v0.md): sample and freeze the benchmark; first capture feedback. Closed 2026-11-11. 109 of 160 eligible, 55 development / 54 held-out, frozen in `e985d82`; the fidelity gap it found led to ADR-0006.
- [2026-11-11-page-capture.md](done/2026-11-11-page-capture.md): capture the page the input draws ([ADR-0006](../dev_docs/decisions/0006-capture-the-page-the-figure-draws.md)). Closed 2026-11-11. Development set: 52 equal, 2 not deterministic, 1 refused of 55. Held-out set, one run: 50 equal, 2 not deterministic, 2 refused of 54; no figure captured as another one.
- [2026-11-11-bench-tree-stratum.md](done/2026-11-11-bench-tree-stratum.md): bench v1, a stratum of tree figures (the ggtree family), reported apart from v0. Closed 2026-11-11. 57 of 83 PSUs give a figure, 29 development / 28 held-out. First runs on the development half: 28 of 29 captured (27 `equal`); 40.1% of layer elements checked by binding, every element in 15 of 27 ggplot figures. gloss unchanged; six classes of shortfall listed for the next plan.
- [2026-11-11-tree-binding.md](done/2026-11-11-tree-binding.md): gloss on the tree stratum. Closed 2026-11-12. Development half: 29 of 29 captured; layer elements checked from 40.1% to 92.3%, failed from 212 to 0; every layer element checked in 23 of 28 ggplot figures (was 15 of 27). Held-out half, one run with the binder frozen and predictions first: 28 of 28 captured; 74.4% checked, none failed; 92.6% on its 24 ggplot figures, 18 of them whole. The owner stopped rule-writing for the residue after Task 6 ([ADR-0009](../dev_docs/decisions/0009-package-behaviour-enters-as-a-checked-proposal.md)).
- [2026-11-12-agent-path.md](done/2026-11-12-agent-path.md): the thinnest agent path and a pilot of the decisive comparison (research-card clause: the substrate with a model against the same model with the raw material). Closed 2026-11-12. `gl_propose()` and `gl_tools()`; every captured development figure written to a bundle and read back. Pilot on 10 development figures, 30 binding questions, 3 free models, 540 runs: raw material and a sandbox right in 91.1% of runs, the substrate's tools in 99.6%, code alone without a model in 30 of 30; the tools' runs take a third of the tokens and time. On single pairings the main claim has little room; the closing notes say where M5 should ask it.
- [2026-11-13-semantic-effects.md](done/2026-11-13-semantic-effects.md): the raw-versus-gloss semantic effects board. Closed 2026-11-13. The Overview now shows the same twelve penguin marks before and after semantic projection; Meaning and Relation submissions visibly change the overlay, relation line, effect state, and record history in one screen. The site checks and the full package suite remain clean (`1422` passed, `0` failed, `0` skipped).
