# 2026-11-12 — Points in several shapes: counted and checked symbol by symbol

- **Related plan:** [plan/2026-11-11-tree-binding.md](../plan/2026-11-11-tree-binding.md) (Tasks 1-5 done; 6-8 open; decision 1 settled: (a)).
- **Related ADRs:** none new.
- **Worked on by:** Claude (Opus 5.5), on the owner's word: "按你的建议选 (a)，继续做 Task 5".

The owner chose (a) for the plan's decision 1: the tree stratum's held-out half is run once, at the end of this plan, with the binder frozen and predictions committed before. Task 5 was done this session: tree-014's leaf of 8100 points in eight shapes, half the stratum's layer elements, was a count mismatch because capture expected one element per point. What each symbol draws was measured first, then counted in capture and checked part by part in the binder. Reading the last run's leaves before writing predictions found a second leaf the new rule would have misjudged (tree-061), which was measured and given its own rule before any run.

## What changed

| Commit | What |
|---|---|
| `785c807` | `dev_docs/research/point-symbols/`: what svglite draws for each `pch`, where each part's box holds its point, what removes parts; host and container |
| `457a386` | Capture counts a points grob symbol by symbol, recounted where its probe is drawn with the settings it inherits (`symbol_parts`, `symbol_fy`, `symbol_kind()`, `points_expected()`, `point_context()`); the binder's mode `symbol`, by boxes, dense leaves included; the ggplot engine states `shape`. A wrong expectation in `test-capture.R` corrected (below) |
| `0dda3d3` | Character symbols drawn as glyph outlines named and not compared (replaced by the next) |
| `5c0a3cd` | ...checked by the outline's box instead, after measuring where outlines sit (`research/point-symbols/glyph.R`) |
| `117665c` | Predictions 81-86 |
| this commit | Predictions scored; plan Task 5 and decision 1; design notes (§选择：让图自己画出一页 on counts, §绑定假设, §风险与未决问题 tree item ④, §与上一版的区别); NEWS; run logs and scores; this log |

## Measured

All bench runs in the container with no network, at `117665c` from start to end, no tracked file modified, one copy of gloss's source for the four runs (digest `2657d803`).

- Suite, host, `NOT_CRAN=true Rscript -e "devtools::test()"`: 9 files / 96 tests / 620 expectations / 0 failed / 0 skipped at `857b6a9` → 9 / 101 / 717 / 0 / 0 at `457a386` → 9 / 102 / 721 at `0dda3d3` → 9 / 102 / 733 / 0 / 0 at `5c0a3cd`. Container (`bench/R/suite.R`) at each of the three: the same counts, 0 errors, 0 warnings. No `R/` change after `5c0a3cd`.
- The tests that failed first: 34 expectations of the new capture tests (one per point, every multi-part symbol), 14 of the bind tests (count mismatch, no mode); the outline test failed at `0dda3d3` and, at `size = 10`, fails the vertex-mean rule by 2.75 pt.
- Point symbols, svglite 2.2.2 (`research/point-symbols/pch.R`), host and the container's `bioc` library identical but for the ggplot2 version: parts per pch 0-25 in drawing order; every part centred across, and down its box except the triangles (2/3, 1/3; pch 11 3/7 and 4/7), within 0.0075 pt over sizes 3-96 pt.
- Glyph outlines under `showtext` (`glyph.R`, six glyphs, three sizes, host and container identical): vertex mean off by 0.02-10.73 pt; box centre across within 0.01 pt; along, within 0.01 pt for symmetric glyphs, 0.24-1.36 pt for `j`; the point inside the box in all 108 cases.
- Capture, stratum (run `0924`) against `2221`, 38 columns: only tree-014's L030 changes, `ok` at 12690 = 12690; mismatch leaves 84 → 83. v0 (`0930`) against `2104`: only exts-014's two `geom_rocci()` leaves (6 = 6); 59 → 57. Run `2104` predates Task 1, so Task 1 left v0's captures alone too.
- Binding, stratum (`0927`): checked 41.5% → 92.2% of 25037 layer elements (verified 14195, ambiguous 8896); failed 67, unbound 87 unchanged; count mismatch 14482 → 1792. tree-014's L030: 4323 verified, 8367 ambiguous, 0 failed, max 0.008 pt. tree-061's L007: 3344 + 441, 0 failed, max 0.49 → 0.007 pt. `compare-bind.R` against `2344`: 593 of 595 leaves unchanged, 0 regressions. Per figure, of 28 ggplot figures: all checked 22, at least 80% 25 (was 24), none 0.
- Binding, v0 (`0936`) against `2347`: 7110 of 7114 leaves unchanged, 0 regressions, failed 8; exts-014's L013 and L016 count mismatch → verified (12); its L007 and L010 stay unbound, with "the rows' shapes draw 1001 parts, the leaf drew 10 elements"; ggplot count mismatch 27 → 15, checked 98.4% (unchanged at one decimal).
- Predictions 81-86: 6 of 6.
- `quarto render dev_docs/design.qmd --to html`: exit 0.
- Not run: the stratum's held-out half (Task 7, decision (a): at the end of this plan); v0's held-out set. The base route was not changed (below).

## Surprises

- **tree-061's tick marks were verified by luck.** Its `geom_point(shape = '|')` under `emojifont` draws each symbol as a glyph outline; the polygon rule compared the outline's vertex mean and passed at 0.49 pt of a 0.5 pt tolerance. Measured afterwards: the vertex mean is 1.15 pt off at a larger size, 10.7 pt for a `j`. Found by reading run `2344`'s leaves before writing predictions, because the symbol rule would have failed these on their tag. I first left them unchecked, as Task 4 does text drawn as outlines (`0dda3d3`); measuring showed the outline's box is exact across the baseline (R's engine centres a symbol's character by its glyph's box, and `showtext` takes the box from the outline), so they are checked as text is (`5c0a3cd`). → `research/point-symbols/glyph.R`; design §绑定假设; plan Task 5 checklist.
- **An expectation in `test-capture.R` was wrong.** "A count mismatch is reported" used a points grob with a point at `x = NA` as its mismatch, expecting 3 elements; R's engine draws 2, and the base route never counted such points. The expectation was changed with a comment; the test's mismatch is its two-line text leaf, which is still a mismatch. → the test; plan Task 5 checklist.
- **Two of my own test expectations were wrong before they were committed.** A plus stated as a cross passes, since both are two lines centred on the point: the rule checks where parts are, not what they look like. And rows shifted by one fail every part paired with another row, but a part the shift pairs with its own row again (the next part of the same symbol) passes when its tag matches. → the tests say both; nowhere else, since they describe what the rule claims, which the design note states.
- **What a points leaf draws depends on settings the leaf does not hold.** A parent gTree's or viewport's `lty = 0` removes a symbol's lines; `lex` and `cex` multiply down the tree. Counting from the leaf grob alone would be wrong for hand-built grid pages (never for ggplot, which puts every setting on the leaf). → the probe recounts points leaves where they are drawn; plan Task 5 "Changed from the plan".
- **Two-thirds of tree-014's points are ambiguous** (8367 of 12690 within 0.5 pt of another row's point). Not read further. → `bench/predictions.md`; nowhere else yet: it is the overlap class the design already reports separately.
- **The base route still expects one element per point for `plot()` and `points()`**, whatever their `pch` (`base_expected()`); a base page with `pch = 3` is a count mismatch, a refusal. No development figure has one, so nothing measured it. → What's next.

## What's next

- Task 6: what is left on the stratum is small: failed 67 (tree-054's repelled labels 41, tree-072's halo copies 20, tree-041's nudged dotted lines 6), unbound 87 (repelled connectors 28, tree-041's images 17, tree-003's text leaf 5, and the 37 single-glyph labels drawn as outlines). Count mismatch 1792 is text drawn as outlines, left as Task 4 decided.
- The base route's points could use the same symbol table (`base_expected()` for `C_plotXY` type `"p"`, and the base engine stating `pch`); a fixture first, since no development figure would measure it.
- Task 7, decision (a): when Tasks 6 and 8 are done, freeze the binder at a commit, commit predictions, run the stratum's held-out half once.
