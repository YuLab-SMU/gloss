# ADR-0009: Code binds what the drawing system's contract gives; a package's own behaviour enters as a checked proposal

- **Status:** Accepted
- **Date:** 2026-11-12
- **Deciders:** Yonghe Xia. The owner agreed to the direction on 2026-11-12 ("同意，按你说的三件事做") and accepted this text, drafted by Claude, the same day ("接受 ADR").
- **Related:** plan/2026-11-11-tree-binding.md (Task 6, Scope change of 2026-11-12); plan/2026-11-11-m1-roles-and-binding.md (Scope change of 2026-11-12); idea/2026-11-12-binding-proposals.md; dev_logs/2026-11-12-tree-binding-remains.md; dev_logs/2026-11-12-few-rules.md; design §命名、与 ggai 的关系、设计原则 (principle 2), §绑定假设也要能检查, §分阶段的 agent.

## Context

Principle 2 reads "what code can determine is never left to a model", and `AGENTS.md` lists it among the invariants. The design also gives the agent a binding stage: for a layer nobody wrote a handler for, it proposes a binding hypothesis in a fixed format and code checks it by back-substitution (§绑定假设也要能检查; the founding idea drew data binding as "deterministic, or agent-proposed and verified"). The two were never reconciled, because the principle does not say where code stops.

The tree binding plan showed that it does not stop by itself. How ggimage justifies an image, where shadowtext draws its halo and what ggtree adds to `x` while drawing can each be determined by code, so each got a rule. After reading Task 6's result the owner stopped the work: the binder had become "program 式的绑定", far from the agentic design first intended, and "残留修复是没有止境的 ... 我们前期不能做太多规则的东西，不然整个系统的规则依赖会非常严重，导致通用、智能化降级". A decision is needed now because M1's open tasks (role rules, base legends) would follow the same principle to the same place.

## Evidence

All on development figures; nothing here was run on a held-out set.

- **Rules that state the drawing system's own behaviour carried the tree stratum.** Tasks 1-5 of the tree plan (text in its own frame as R's engine places it, rows through the coord's own transform, points by the parts R draws for each symbol, a page over the parser's limit, outlines named) took the checked share from 40.1% of 24915 layer elements to 92.2% of 25037: 9984 to 23091 elements, for 955 lines added to `R/` and `tests/` (`git diff --shortstat b02ea8c..d13ecfd -- R tests`; runs `2026-11-11-2118`, `2026-11-12-0927`).
- **Rules about one package's behaviour moved almost nothing.** Task 6's classes added 374 lines (`c8081de..752bb73`) for 28 more checked elements, 92.2% to 92.3% (run `2026-11-12-1107`). Of the 28, 5 follow ggplot2's own `handle_na()` and 11 pass the comparison of an image by its box; the other 12 pass only through rules written for two packages: 6 lines through the nudge read from ggtree's geom, 6 images through the justification measured on ggimage. "Failed 67 to 0" is 6 elements bound and 61 renamed as unbound with a reason.
- **Such a rule cannot be written from documentation.** The first image rule followed grid's meaning of `hjust`, passed its own fixture, and would have failed tree-041's six rightly paired images by about 31 pt, because ggimage moves an image by its own estimate of the width; 72 cases were measured in the container to find the rule that holds (`dev_docs/research/image-justification/`). Four defects in Task 6's rules were found before any run (dev log 2026-11-12, *Surprises*).
- **The residue does not shrink to nothing.** After those rules, 1918 layer elements of the tree development half and 3314 of v0's development set are unchecked, in 18 classes of reason (`Rscript dev_docs/research/bind-dev/d3-residue.R` on the leaf tables of runs `2026-11-12-1107` and `-1116`; its output is `d3-residue.out`, and the table is in the idea note).
- **Not measured:** whether anything other than a hand-written rule (an enumeration by code, a model, a person) can state these bindings so that the check passes. No proposal has ever been made or verified.

## Decision

gloss's own code determines what follows from the drawing system's contract and nothing beyond it; what a package does on top of that contract is not written into gloss as a rule but enters as a proposal, which counts only when code has checked it.

1. **The drawing system's contract** is what R's graphics engine and device draw for a primitive, grid (grobs, viewports, `makeContent()`, the display list), base graphics' display list and its calls' arguments, and the build protocol of each engine gloss supports (ggplot2's built data, `Geom$handle_na()`, `Coord$transform()` and gtable; patchwork's assembly; ComplexHeatmap's drawn object).
2. **The test for a rule.** A rule belongs in gloss when it can be written and tested from that contract alone. If getting it right needed reading or measuring a package that is not one of those engines, it is outside. A rule that only names what a leaf is (made when drawn, drawn as outlines) and binds nothing is inside.
3. **Code keeps** capture, every verification (all comparisons, counts and refusals), and the bindings and roles the contract gives.
4. **A proposal** says, in a closed vocabulary, how a leaf's elements come from rows where the engine's own pairing does not pass: which rows are drawn, in what order, how many elements each draws, where they are moved, which leaf they repeat. It is checked by the same back-substitution as an engine's pairing. A proposal that passes is a record with its author and its check, laid over the derived tables (ADR-0007, to come); one that does not pass is never a binding. Each kind of proposal is admitted only with a mutation test in which permuted rows fail.
5. **Who proposes is not decided here.** It may be an enumeration by code over the closed vocabulary, a model, or a person, through the same entry point (principle 5). The experiment in the idea note measures the first two.
6. **Residue is named, reported and left.** A class of unchecked elements gets its reason and its count. It does not get a rule unless the rule passes the test of point 2.
7. **Three rules in the code are outside the line.** They stay, frozen, until a proposer is shown to replace them, and no rule of their kind is added: the draw-time nudge and the justification taken from a `draw_panel()` parameter (`ggplot_rows_drawn()` in `R/engine-ggplot.R`), with the image check "inside its box along the justified axis" (`row_family()` in `R/core-bind.R`); and copies at one offset (`mark_copies()` in `R/core-bind.R`).

Not changed: the second sentence of principle 2 (model output must be checkable), principles 1 and 6, and the rule that gloss refuses and says why when it cannot attribute or bind correctly.

On acceptance, principle 2 in `AGENTS.md` becomes: "What follows from the drawing system's own contract is determined by code, never by a model. What a package does on top of that contract is not written into gloss as a rule: it enters as a proposal, from an agent, a person or a search, and counts only when code has checked it. Model output must be checkable."

## Alternatives considered

- **Keep the principle as written and add a rule for each class.** The evidence above: 12 elements for the rules about two packages, each needing the package read or measured, and 18 classes of reason still open.
- **Put a package's behaviour in a plugin for that package.** Principle 9 allows it, and the three frozen rules concern ggtree, ggimage and shadowtext, which the owner's lab maintains. Not taken now: it is the handler-per-geom route the research card holds against, and nothing measured says the lab's figures need it. It stays open, outside the core (see *Revisit when*).
- **Remove the three rules now.** They are part of the binder measured on the development half, and Task 7 runs that binder once on the held-out half; they are also the answer key for the experiment.
- **Let a model propose every binding.** The engines' own pairings check 98.4% of v0's ggplot layer elements with no model and give the same answer every time; capture and binding together take a median 0.37 s a figure on v0's development set (run `2026-11-12-1116`).

## Consequences

### Positive

- The core stops growing with the number of packages. A new extension package needs no change to gloss when what it does can be said in the proposal vocabulary.
- The reasons already written on unchecked leaves become the proposer's work list, by class.
- The principle and the design's binding stage say the same thing.

### Negative / accepted tradeoffs

- Figures that use extension packages keep a named residue until proposals exist. On the tree development half that is 1918 of 25037 layer elements, and 5 of 28 ggplot figures have a layer element unchecked.
- "A proposer can repair a binding" is now the riskiest assumption in the design and has no measurement.
- By elements, proposals may move little: 86% of today's residue sits in three classes (text drawn as outlines 1829, `sf` paths 1626, grid figures with no table 1056 of 5232) that lack a comparison, a count or a table, not a guess about a package.
- A proposal that passes a weak check can be wrong. Mutation tests and the `ambiguous` status are the guard, and every kind of proposal has to earn them.

### Follow-ups

- On acceptance: the wording of principle 2 in `AGENTS.md`; dated notes in design §设计原则, §绑定假设也要能检查, §分类 and §与上一版的区别; this file's status and the index.
- The experiment of `idea/2026-11-12-binding-proposals.md`, promoted to a plan if the owner agrees to it.
- ADR-0007 says where a verified proposal lives beside the derived tables.
- Tree plan Task 7 runs the frozen binder once on the held-out half; its predictions say how many elements are expected unchecked for a reason no development figure gave.

### Revisit when

- The experiment finds that neither an enumeration nor a model re-derives what the three frozen rules bind (12 elements on tree-041) and name (20 on tree-072): the line then costs coverage with nothing to recover it, and package plugins are reconsidered.
- A verified proposal is found to pair an element with the wrong row.
- One package's behaviour leaves most layer elements unchecked in more than a fifth of a stratum's figures: a plugin for that package, outside the core, is weighed against the residue.
