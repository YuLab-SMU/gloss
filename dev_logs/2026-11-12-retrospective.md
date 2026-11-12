# 2026-11-12 — The tree binding plan closed; a review of the plans and the documents

- **Related plan:** [plan/done/2026-11-11-tree-binding.md](../plan/done/2026-11-11-tree-binding.md) (closed here); [plan/2026-11-11-m1-roles-and-binding.md](../plan/2026-11-11-m1-roles-and-binding.md) (active; decisions 4 and 5 open).
- **Related ADRs:** [ADR-0009](../dev_docs/decisions/0009-package-behaviour-enters-as-a-checked-proposal.md).
- **Worked on by:** Claude (Fable 5.2), on the owner's word: "推送，关闭树图计划. 复盘一下开发计划、文档。review 和调整". Follows [the log of the held-out run](2026-11-12-tree-heldout.md).

Five plans are closed and one is active. Capture and binding are measured, capture on two held-out sets and binding on one. Everything the design gives the agent, and the comparison the paper rests on, has no data and no code. The review found why the work went where it did, corrected the documents that had fallen behind, and changed three rules of the workflow. No function of the package changed.

## What changed

| Commit | What |
|---|---|
| `d228d07` | M1 plan: current state from the latest runs; Task 5's status line; decisions 4 and 5, open; a Scope change |
| `73ab474` | `README.md`: status and evidence as measured |
| `291866e` | `AGENTS.md`: three workflow rules, the layout note; `plan/_template.md`; `dev_docs/README.md` |
| this commit | The tree binding plan closed and moved to `plan/done/`; `plan/README.md` (the plan listed as completed; two conventions); design: the binding section and the tree risk rewritten as the current state, three reviewer rows updated and two added, a note on the milestones, §与上一版的区别; `dev_docs/research/bind-dev/d4-geoms.R` and `.out`; links in two research notes; this log |

Pushed on the owner's word before the review: `bd388fb`. The four commits above are not pushed.

## Measured

- **Where the work went.** 174 commits on `feat/m0-substrate` to `bd388fb` (22, 28, 96 and 28 on 2026-11-09 to -12), all ahead of `main`, which last moved on 2026-11-08. No pull request has been opened (`gh pr list --state all`: none). Lines added since `main` (`git diff --shortstat origin/main..bd388fb`): 8408 under `R/` and `tests/`, 3679 under `bench/R`, 4498 in plans, logs, ADRs, ideas, predictions and NEWS.
- **What has data.** Of the nine clauses of the research card (design @tbl-claims), three: the M0 clauses on capture. The two that carry the main claim (the substrate against the same raw material; records that follow the figure) have none; classification rests on three hand-built figures; claim checking on one example.
- **The tree binding plan,** end against start: its closing notes. Predictions made under it: 34 right of 39.
- **Binding without a handler** (`Rscript dev_docs/research/bind-dev/d4-geoms.R`, on the leaf tables of runs `2026-11-12-1116`, `-1107`, `-1427`): 33 geom classes on the 92 figures with a layer leaf; 17 from extension packages, of which 8 are checked whole, 5 in part and 4 not at all; 2038 of their 6627 elements checked. No line of `R/` outside comments names a geom class other than `ggplot2::Geom` itself. Two of the eight pass in part through rules read from their packages (ADR-0009's frozen three).
- **The design document,** before and after this commit (a script over `dev_docs/design.qmd`): the word 补记 60 times → 54; text inside dated parenthesised notes 12% → 6%; longest paragraph 3878 characters → 1365. `fact_diff.py` between the two flagged 24 numbers as removed. Two were put back with a link it also flagged (the ambiguous count 15328, the heatmap's 250 cells, the link to the M1 plan); the rest are steps on the way (intermediate shares, run names, figure ids) and stay in the plan's closing notes, `bench/predictions.md` and the dev logs.
- `quarto render dev_docs/design.qmd --to html`: exit 0.
- Suite: not run again; nothing under `R/` or `tests/` changed. Host 9 files / 109 tests / 807 expectations / 0 failed / 0 skipped at `1f7aa1f`; the container the same at `40bbe77`.
- Not reviewed line by line: the design's appendices A to C, `dev_docs/research-report.qmd`, `bench/README.md`, the dev logs before 2026-11-11.

## Surprises

- **Riskiest first was applied inside each plan and never across them.** Each plan ordered its own tasks by risk. The choice of the next plan followed the milestone table and what the last run showed, and the table puts the decisive comparison last (M5). Five plans later the clauses with data are the three that were least in doubt. → `AGENTS.md` (a plan names the research-card clause it gives evidence for; a clause with no data outranks refining one that has some); `plan/README.md`; `plan/_template.md`; a dated note in design §实施计划.
- **The only number the loop had was the checked share on the development set,** so "measure, fix the largest class, measure again" could only produce more binding rules. It did, until Task 6 (374 lines for 28 elements), where the owner stopped it. → ADR-0009 (earlier today); `AGENTS.md` (record what a task cost; stop when a kind of task moves little for much).
- **The roles half of the M1 plan has not moved since it opened.** Its rules wait for the development labels, and those wait for lab members to label fifteen figures; none has. Work went to what was not waiting: binding, then the tree stratum. Nothing in the plan said so. → M1 plan, *Current state* and decision 4 (open).
- **Binding was never in M1 by the milestone table.** The table has it under M3; the M1 plan pulled it forward because a "data mark" role cannot be checked without it. The move was right and was recorded only in the plan's title. Bindings are still internal: the bench reads them, a user cannot. → design §实施计划 (note); M1 plan decision 5 (open).
- **The design had become a log.** `dev_docs/README.md` said it is rewritten as the system evolves; in practice each result was appended as a dated note, and the section on binding was one sentence of design followed by six notes. → the two worst paragraphs rewritten as the current state; `plan/README.md`: a plan's notes are folded into the text when it closes. The other dated notes are left (the word still occurs 54 times): their plans closed earlier, and each is short.
- **Nobody had counted the result the research card most needs from this layer.** The card holds one handler per geom against existing tools. That 17 extension geom classes were paired with no geom named in the code was sitting in three leaf tables. → design §绑定假设 and a new row in §审稿人预演; `README.md`. A candidate for the card's legacy list, which is the owner's to change.
- **An element-weighted share misled on every set.** v0's two largest figures hold 17883 of 24783 ggplot layer elements; the tree halves turned on one leaf and on two book figures. And "checked" joins verified with ambiguous: on v0's ggplot figures 36.6% and 61.8%. → `AGENTS.md` (*Done means measured*); design @tbl-bind-measured gives the columns apart.
- **`README.md` described the project as it was on 2026-11-09,** before the capture route changed and before any binding. → rewritten from the measurements.
- **What held up, and stays.** Predictions before runs: the wrong ones found a defect or a wrong belief each time (gallery-020's labels, the outline counts, tree-041's two classes). The held-out sets were each run once, with the binder or the route frozen. Every fix began with a test that failed. The container suite caught what the host could not. One slip of this session belongs here too: two counts in my first draft of the closing notes were wrong and were caught only by recomputing them (39 predictions, not 60; 34 right, not 32); a number in prose is recomputed by a command before it is committed.
- **One branch holds everything.** 174 commits, named for M0, no pull request, `main` five days behind. `AGENTS.md` asks for a PR that references the plan and its log. → nowhere yet: opening a pull request or merging is the owner's call.
- **Appendix C of the design lists `aisdk` under Imports;** `AGENTS.md` says the core works without it, and `DESCRIPTION` does not have it. → nowhere yet: it is settled when the first agent code lands (Suggests keeps the core independent).
- **A commit of mine carried a rename it did not name.** `git mv` stages the move at once, and the next `git add` of another file committed both. Caught before pushing; the three local commits were undone and made again. → nowhere else.

## What's next

Nothing is opened: the next plan is the owner's choice.

- **Recommended: the thinnest path to an agent,** before any layer is widened. In order: ADR-0007 with bindings stored in the figure and one exported query (M1 decision 5); read-only tools over the substrate and one `propose` entry that validates on submit, through aisdk; then a pilot of the decisive comparison on about ten development figures, the same model with the substrate's tools against the same model with the raw material and a sandbox, on questions whose truth exists today without labels (a layer's hidden bindings; injected true and false claims computed on the built data). Not a reported number: it says whether the main claim has any effect to measure, and what a run costs. The reason is the first surprise above: this is the clause with no data that the rest of the design depends on. It needs from the owner a model, a key and a cost cap.
- **In the background, waiting on people:** the lab's labels on fifteen figures; M1 decision 4 says whether the development labels wait for them.
- **Deferred, with their sizes:** code's own gaps inside ADR-0009's line (rectangles munched along a coord, 600 elements in 2 held-out figures; three smaller classes); the proposal experiment of the idea note (241 elements in 7 development figures without outlines); text drawn as outlines (4321 elements in 7 figures, no comparison exists).
- **The owner's, not started:** a pull request or merge to `main`; the four untracked directories; whether the research card gains "binding chosen by tag and counts, no handler per geom" as a clause or a legacy.
