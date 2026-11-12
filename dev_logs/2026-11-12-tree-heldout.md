# 2026-11-12 — ADR-0009 accepted; the tree stratum's held-out half, one run

- **Related plan:** [plan/2026-11-11-tree-binding.md](../plan/2026-11-11-tree-binding.md) (Tasks 1-7 done; Task 8's closing notes open).
- **Related ADRs:** [ADR-0009](../dev_docs/decisions/0009-package-behaviour-enters-as-a-checked-proposal.md), accepted this session.
- **Worked on by:** Claude (Fable 5.2), on the owner's word: "接受 ADR，推送，然后按建议跑 Task 7". Follows [the log of the same day](2026-11-12-few-rules.md).

The frozen binder, run once on the 28 tree figures it had never seen, captures all of them and fails no element. On the 24 ggplot figures it checks 92.6% of the layer elements and every one of them in 18 figures. The four patchwork compositions pull the whole to 74.4%, through two book figures whose text is drawn as outlines. Nothing in gloss was changed.

## What changed

| Commit | What |
|---|---|
| `40bbe77` | ADR-0009 accepted: its status; principle 2 in `AGENTS.md`; dated notes in the design (the principle, binding hypotheses, classification, a new risk, the changes section, the status callout). Pushed |
| `ee75172` | Predictions 93-101 and how the runs are scored; `bench/R/score-residue.R`. Pushed before the runs |
| `41fc2b2` | Runs `2026-11-12-1422` (capture) and `-1427` (binding) on the held-out half, archived unscored |
| this commit | The three score files; predictions scored; plan Task 7; design notes (§评测设计, §风险与未决问题, §与上一版的区别); NEWS; this log |

No file under `R/` or `tests/` changed.

## Measured

- Suite, bench container, at `40bbe77` (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R`): 9 files / 109 tests / 807 expectations / 0 failed / 0 errors / 0 skipped / 0 warnings. The host suite gave 807 passed at `1f7aa1f` earlier the same day; `R/` and `tests/` are unchanged since `752bb73`.
- The binder frozen: `git diff --quiet 752bb73 HEAD -- R tests inst` at `ee75172` finds nothing; both runs' `gloss_source_digest` is `b5307a6245018bf13fa55f8860f3c767`, as in the development runs `1105` to `1116`; both ran at `ee75172` from start to end.
- Capture, held-out half of the stratum (`score-capture.R` on run `1422`): 28 of 28 captured, no refusal, no error; 27 `equal`, 1 `not_deterministic` (tree-035), 0 `different`; gloss's verdict identical to the bench's on 28; the only element without a leaf is the device background in 28; panels withheld in 1 (tree-020); longest capture 2.3 s.
- Binding (`score-bind.R` on run `1427`): 13923 layer elements; verified 7960, ambiguous 2398 (74.4%); failed 0; unbound 1022; count mismatch 2542. Longest capture with binding 3.7 s.
  - ggplot, 24 figures: 9847 elements, 92.6% checked (development half: 92.4% of 24911); every layer element checked in 18, at least 80% in 21, none at 0. By kind of PSU: topics 15 of 17, vignettes 3 of 7.
  - patchwork, 4 figures: 4076 elements, 30.5% checked. tree-002 and tree-039 (vignettes) 100%; tree-020 41.7% and tree-049 16.0% (book).
- Residue (`score-residue.R` on run `1427`, `--against` the leaf tables of `1107` and `1116`): 3564 elements in 86 leaves of 8 figures, 9 classes. Text drawn as outlines 2492 (2 figures); rectangles munched along a coord 600 (2); no panel with scales 341 (1); a `GeomText` count mismatch 50 (1); made when drawn 31 (1); a boxplot's pieces 30 in three classes (1); a caught transform error 10 (1).
  - Classes no development figure gave: 4, with 411 elements in 4 figures. Against the stratum's development half alone: 7, with 1041 elements.
- Predictions 93-101: 8 of 9 right (`bench/predictions.md`).
- `quarto render dev_docs/design.qmd --to html`: exit 0 at `40bbe77` and again after this commit's notes.
- Not run: v0's held-out set, on which binding has never run; the host suite again (nothing it tests changed).

## Surprises

- **No element fails on figures the binder never saw.** Prediction 99 said at least one would: a geom drawing its rows off their built place, paired rightly and failing. The half holds none that gloss does not already name. One reading is that the naming rules of Tasks 4 and 6 catch the cases that used to fail (tree-035's 31 repelled elements are unbound as made when drawn); another is that 28 figures are few. → `bench/predictions.md`; plan Task 7.
- **The new reasons are not about packages.** Four classes of residue appear that neither development set gave, as the owner expected of unseen figures. By their text they are a composition whose panels gloss withheld, a count, an error while placing rows under a polar coord, and a boxplot's rows: gaps in how gloss handles ggplot2 and patchwork themselves, or not read. The 600 elements of bars under `coord_polar()` are of the same kind. Under ADR-0009 these are code's own work; a proposal about a package reaches the outlines (no comparison exists) and 31 elements. → design §风险与未决问题; the idea note's sets K and P gain nothing from this half but tree-035.
- **The whole-set share is set by two figures.** 74.4% overall against 92.6% on the ggplot figures: tree-049 and tree-020 hold 2833 of the 3564 unchecked elements. The per-figure counts are the number to read; the scorer says so for ggplot figures and prints no per-figure share for patchwork. → plan Task 7 reports both; nowhere else yet.
- **A caught error is given as a reason.** Five leaves of tree-027 are unbound with "the coord's transform failed (CoordPolar): replacement has 0 rows, data has 2". gloss did not stop and did not bind wrongly, but the reason says that placing the rows broke, not what the leaves are. Not read further and not changed: the plan's Scope change forbids a change in answer to this run. → What's next.
- **I named the wrong figure in prediction 95.** I expected the jitter topic (tree-070) to differ between two drawings; it is `equal`. The one figure that differs is a vignette with repelled labels. The scored claim held. → `bench/predictions.md`.

## What's next

- Close the tree binding plan: its closing notes, then `plan/done/`. Left for the owner's word, since what the next plan starts with is theirs to choose.
- The candidates the measurements give, none started:
  - code's own work under ADR-0009, by figures affected: bars and rectangles munched along a coord (600 elements in 2 of 24 held-out ggplot figures; 25 on v0's development set), the transform error on tree-027, boxplot rows, panels withheld in a composition;
  - the experiment of `idea/2026-11-12-binding-proposals.md`, with its three decisions still the owner's;
  - the M1 plan's open tasks (labels, role rules, ADR-0007), read under ADR-0009.
- The stratum's held-out half is used for capture and binding. A later change to either, run on it again, is reported as made after this run.
