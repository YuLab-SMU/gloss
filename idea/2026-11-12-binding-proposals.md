# Binding proposals: who repairs a binding the engine cannot state

> Status: idea, for the owner's decision. Not a plan, not an ADR. Nothing here has been run.
> Date: 2026-11-12. Follows [ADR-0009](../dev_docs/decisions/0009-package-behaviour-enters-as-a-checked-proposal.md) (accepted the same day, after this note was written). Evidence: [`dev_docs/research/bind-dev/d3-residue.R`](../dev_docs/research/bind-dev/d3-residue.R) and its `.out`; [dev log](../dev_logs/2026-11-12-few-rules.md).

## The question

ADR-0009 stops gloss from writing a rule for what one package does when it draws. Such a binding is to come from a proposal that code checks. Nobody has made one. Can a proposer state the bindings that hand-written rules state today, and bind any of what is left, without a wrong binding passing the check? And does the proposer need to be a model?

## Where it starts (measured)

After the binder of `752bb73`, 5232 layer elements in 32 of the 83 captured development figures are unchecked (runs `2026-11-12-1107` and `-1116`). Sorted by what each reason lacks, which is a reading of the reason's text and not a check made leaf by leaf:

| What is lacking | Elements | Figures | Largest classes |
|---|---|---|---|
| What a package does when it draws | 2070 | 11 | text drawn as outlines under showtext 1829; leaves made when the layer's grob is drawn (ggrepel, geomtextpath) 200; copies 20; three small ones 21 |
| A count or comparison the drawing system defines | 1898 | 16 | `sf` paths, several for a row 1626 (1606 in one map); heatmap tracks and dendrograms 156; a patchwork panel no plot owns 41; base types `'h'`, `'o'` 37 |
| A table to bind to | 1218 | 5 | four grid figures 1056; one figure with a print method of its own 162 |
| Not read | 46 | 2 | |

Three things follow.

- **A proposal about a package can reach at most 2070 of the 5232 elements, and 1829 of those are one class.** Text drawn as outlines has no comparison at all today; a proposal cannot pass a check that does not exist. Without that class, the package residue is 241 elements in 7 figures.
- **The second row is code's own work under ADR-0009,** to be taken or left by the figures it affects. It is not part of this idea.
- **The third row is where a table has to be found in the figure's code.** No closed vocabulary reaches it. It is the place a model is most likely to be needed, and it needs a sandbox; it is the next experiment, not this one.

So by elements the lever is small on these sets, and by figures it is 11 of 83. The experiment is worth making for what it decides (below), not for the share it could move.

## The idea

A proposal says how a leaf's elements come from the layer's rows, in a closed vocabulary. Code turns it into the rows' places on the device and checks it with the comparison the binder already has (`check_claim()`); an engine's own pairing is the proposal with nothing changed.

| Kind | Says | Checked by |
|---|---|---|
| `rows` | which built rows are drawn: all, or those where a named column is not missing or has a named value | counts, then back-substitution |
| `order` | the order they are drawn in: as built, by a named column, reversed | back-substitution; a wrong order fails |
| `per_row` | how many elements a row draws: a constant, or a named column's value or length | the counts add up; each element's box holds its row |
| `shift` | rows moved in data units by a named layer parameter, on x, on y, or on both ends | back-substitution at the moved place |
| `anchor` | which point of the element sits at the row: its centre, an edge by a named justification, its first or last vertex | the comparison families of `row_family()` |
| `match` | text elements paired with rows by a named column's string | each text equals one row's value; a tie is ambiguous |
| `copy_of` | the leaf repeats a named leaf at one offset | element for element equal but for one offset (the check `mark_copies()` makes) |
| `none` | the leaf is not drawn from the rows, with a reason from a closed list | not checked: it stays residue, with the proposer's reason |

Two rules keep a pass meaningful.

- **No free numbers.** Every quantity is a name code looks up: a column, a layer parameter, a leaf. An offset is measured, never proposed. A proposer cannot fit its way to a pass.
- **A kind is admitted with a mutation test:** permuted rows fail on every element they move, ties aside, as the engine pairings are tested today.

Because nothing is free, the proposals for a leaf are a finite list. Code can try them all. That is the rival below.

## Research card

1. **Bottleneck.** A tool that binds drawn elements to data by rules binds only what someone wrote a rule for; each package that draws in its own way needs the package read or measured (ggimage: 72 cases for one rule).
2. **Claim.** With a closed proposal vocabulary and the binder's check, the bindings of the three frozen package rules can be re-derived with no package-specific code, and no proposal that pairs an element with the wrong row passes.
3. **Strongest rival.** No model is needed for this: with no free numbers, an enumeration by code finds whatever a model would propose. A second rival: a pass is cheap, because trying many proposals on a leaf of two or three elements lets a wrong one through.
4. **Decisive comparison.** The same leaves, the same vocabulary and the same check, proposed by (S) an enumeration and (M) a model that sees the same facts. S as good as M means binding repair is a search, and the model's work in binding is the table row above. M better than S means the design's binding stage stands as written. For the second rival: every accepted proposal on leaves whose answer is known is compared with the answer, and an accepted proposal needs every passing proposal to give the same rows.
5. **Boundary and legacy.** If neither re-derives the frozen rules, ADR-0009's line costs coverage and package plugins are reconsidered. What would outlast gloss: a vocabulary of the ways a drawn layer departs from its built rows, with a check for each and how often each occurs on sampled figures.

## The thinnest experiment

- **Set K, answers known:** the binder with the three frozen rules switched off. 32 elements in two figures are expected to fall back to failed, as they were before the rules: tree-041's 6 dotted lines and 6 tip images, tree-072's 20 halo copies. The answer is what the rules give in run `1107`. Too few for a rate; enough to show the mechanism and to catch a wrong pass.
- **Set P, no answer:** the package residue without outlines and without K's copies, 221 elements in 6 figures. A pass here is read on the page by a person, every one of them.
- **Not yet:** outlines (1829 elements). They need a comparison for a run of outlines first, which is a second step only if K and P work.
- **Arms.** S: code lists every proposal the vocabulary allows for the leaf and checks each; it accepts when all that pass give the same rows. M: a model gets the leaf's facts (reason, tags, boxes and texts of its elements, the layer's geom class, its parameters' names and values, its built rows' columns with a few rows) and returns one proposal as schema-validated data; on a failed check it gets the error list and may revise twice. Five runs a leaf for M.
- **Reported, by leaf, element and figure:** proposed, valid, verified, ambiguous, none; on K, agreement with the answer and every wrong pass; for M, calls, tokens, seconds and the spread over runs.
- **Where it runs.** Third-party code runs only in the bench container with no network, and a model call needs the network. So: the container writes the leaves' facts; the host sends facts to the model and gets proposals; the container checks them. The model never sees more than the facts, and the host runs no figure code.
- **What it needs built:** an internal switch for the three rules; a function from a proposal to the rows' places on the device (the engine's `ggplot_rows_on_device()` after the proposal's changes); the `match` check; the enumeration; a script that calls a model through aisdk (1.5.0 is installed on the host), gated by an environment variable. All under `bench/` and internal functions; nothing exported.
- **Before any run:** predictions in `bench/predictions.md`. Mine today, to be committed then: S re-derives all three classes of K; M does no better than S on K or P; on P both bind the texts that are still text by `match` and leave boxes and connectors as `none`.

## What each result would change

| Result | Then |
|---|---|
| S re-derives K and matches M | binding repair is a search over the vocabulary, with no model; the three rules are removed in favour of it; ADR-0009's "who proposes" is answered for bindings; the agent's place in binding is finding tables |
| M beats S | the `propose` entry point for bindings is built early in the record core, and the binding stage of design §分阶段的 agent is kept as written |
| Neither re-derives K | ADR-0009 is revisited: a package's behaviour goes to a plugin for that package |
| A wrong proposal passes | that kind is tightened or dropped before anything else is built on it |

## What it does not test

- Roles, relations and claims, which are most of what the design gives the agent, and the comparison of the substrate against raw material (design §研究卡片). Those have no data either.
- Whether the vocabulary fits packages the development sets do not hold. It is written from their residue; the residue of a held-out run is the test, and that run is a reported one.
- The table row: a model reading the figure's code to find what a grid figure drew from.

## Decisions asked of the owner

1. Promote this to a plan now, or after tree plan Task 7. Recommended: after. Task 7 is one run away and will list the held-out half's residue by reason, which says whether K and P are the right sets.
2. The model or models for arm M, the key, and a cap on what the runs may cost.
3. Whether finding tables for the grid figures belongs to this experiment. Recommended: no; it needs a sandbox and its own card.
