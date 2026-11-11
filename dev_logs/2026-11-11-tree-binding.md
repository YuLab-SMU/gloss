# 2026-11-11 — The tree binding plan: every page captured, labels in their frame, polar trees, glyph outlines

- **Related plan:** [plan/2026-11-11-tree-binding.md](../plan/2026-11-11-tree-binding.md) (opened this session; Tasks 1-4 done, 5-8 open). [plan/2026-11-11-m1-roles-and-binding.md](../plan/2026-11-11-m1-roles-and-binding.md) (a Scope change: the owner confirms the criterion's reading).
- **Related ADRs:** none new.
- **Worked on by:** Claude (Opus 5.5), on the owner's word: "按你的建议开树图计划，标准认可".

The owner accepted the plan the last session proposed for gloss on the tree stratum's development half, ordered by the figures each class of shortfall affects, and confirmed that the label criterion is read on the median of A's pairwise κ (the question left open in the three sessions before). Four tasks were done here, each with a test that failed first, predictions committed before each run, and v0's development binding compared leaf by leaf after every binder change.

## What changed

| Commit | What |
|---|---|
| `0e89a23` | The plan opened; the owner's confirmation in the M1 plan and `bench/predictions.md` |
| `c8a6e85` | Task 1: `read_page()` parses pages gloss drew with libxml2's `HUGE`; an SVG from outside keeps the limit and is refused with the parser's reason; the bench's comparator gets the option; `bench/R/compare-bind.R` |
| `934af71` | Task 2: text compared in its own frame (justification, rotation); label boxes by their box centre; the ggplot engine states `hjust`, `vjust`, `angle` |
| `e96d5f5`, `84b60fb` | Task 3: rows through the coord's own transform; a path one per row with ends bound by its ends; rectangles and per-group paths munched along a non-linear coord unbound with that reason, decided by what is drawn |
| `7589e0f` | Bench: a run's workers load a copy of gloss's source taken when the run starts; the commit at start and end and the copy's digest in the run's record |
| `73b317d` | Task 4: text drawn as glyph outlines named, never compared as shapes; `showtext` in Suggests |
| predictions | 63-66, 67-72, 73-75, 76-77, 78-80, each committed before its runs and scored after |
| this commit | Design notes (§绑定假设, §风险与未决问题, §与上一版的区别), NEWS, Task 5 written out, this log |

## Measured

All bench runs in the container with no network, at the commit holding their predictions, clean tree.

- Suite, host, `NOT_CRAN=true Rscript -e "devtools::test()"`: 9 files / 88 tests / 544 expectations / 0 failed / 0 skipped at `b02ea8c` → 9 / 96 / 620 / 0 / 0 at `73b317d`. At the end, at `399b799`: 9 / 96 / 620 / 0 / 0 (no `R/` change after `73b317d`). Container (`bench/R/suite.R`) at every commit touching `R/`: the same counts as the host, 0 errors, 0 skipped.
- Stratum, development half (29 figures):
  - capture: 28 → 29 captured (tree-041 `equal`, 6.6 s); the other 28 unchanged in 37 columns (runs `2110` → `2221`);
  - binding, layer elements checked (verified or ambiguous): 40.1% of 24915 (run `2118`) → 40.0% of 25037 with tree-041 (`2224`) → 40.6% (`2241`, Task 2) → 41.5% (`2300`/`2327`, Task 3) → 41.5% (`2344`, Task 4); failed 212 → 222 → 104 → 104 → 67; unbound 308 → 325 → 291 → 50 → 87;
  - per figure, of the ggplot figures, every layer element checked: 15 of 27 → 15 of 28 → 19 → 22; none checked: 3 → 3 → 3 → 0.
  - The element-weighted share stays near 40% because one leaf of tree-014 (12690 points in eight shapes, a count mismatch, Task 5) holds half the elements.
- v0, development binding, `compare-bind.R` against the run before: Task 2 (`2244`): 7114 of 7114 leaves unchanged. Task 3 (`2303`, then `2315` after a fix): 8 leaves changed in five named figures, 0 regressions, failed 8 as before.
- Predictions: 63-66, 3 of 4 (66 wrong); 67-72, 6 of 6; 73-75, 2 of 3 (75 wrong, found a defect); 76-77, 2 of 2 (after looking); 78-80, 2 of 3 (80 wrong). 15 of 18 in all.
- Task 4 (`2344`, `2347`): the 67 layer text leaves drawn as outlines name it, 0 failed among them; stratum failed 104 → 67, unbound 50 → 87; v0 unchanged. Grouping glyph paths into labels by count would reach 23 of the 67 leaves, 291 of their 1829 elements (16%).
- `bench/R/check-runner.R`: OK on the host; in the container OK with 1 skipped (the install check needs the network), after each change to `runner.R`.
- `quarto render dev_docs/design.qmd --to html`: exit 0.
- Not run: the stratum's held-out half (decision 1 of the plan, open); v0's held-out set.

## Surprises

- **tree-041's 10 failed elements were two classes the plan did not list.** ggtree's aligned dotted lines are moved at draw time by a geom parameter (`nudge_x = offset`) the built rows do not hold (6 elements, up to 128 pt); label boxes are not centred on their row to 0.5 pt when measured by the vertex mean of a rounded rectangle (4), and plain `geom_label()` does the same without `showtext`. tree-045's "unexplained" failures were the box class and `hjust = 0.39` labels. → plan Scope change; the boxes went into Task 2, the nudge into Task 6.
- **R's placement of text is exactly predictable from what svglite writes.** Along the baseline by (hjust − text-anchor) × `textLength`, across it by vjust × the ascent of "M" on the device: 120 hand-drawn cases within 0.005 pt. My first probe was off by 0.37 pt because I placed the text in grid's `pt` (1/72.27 in), not `bigpts`. The across-baseline rule was kept as wide as before, because a label's text inside its box sits by margins and descent. → `R/core-bind.R`; design §绑定假设 (below).
- **shadowtext's halo copies fail the exact rule, as they should.** Each label is drawn 17 times, 16 copies moved 0.8 pt in 16 directions; the prediction (10 of 16 copies fail) was written from the package's code before the run and held. → plan Scope change restating tree-072's criterion; Task 6.
- **My rectangle rule under polar read columns, not drawings.** Labels stacked on a pie keep `xmin`..`ymax`; prediction 75 caught it on gallery-020. → fixed with a test that failed first (`84b60fb`), runs made again after looking.
- **A bench run loads gloss from the working tree for each figure.** I edited `R/` while a stratum run was going; the run was discarded unscored and made again on a clean tree. Compared afterwards it was identical, which does not make it clean. → `7589e0f`: the workers load a copy taken at the start; plan Scope change.
- **Most text drawn as outlines cannot be put back into labels by counting glyphs.** I predicted 80% of the leaves would match; 23 of 67 did. tree-054's repelled labels are each one label in a leaf the binder pairs with all 126 rows of its group, and tree-014's largest tip-label leaf draws 1444 paths for 2344 characters. → predictions.md; the plan's Task 4 decision (not taken up); design §风险与未决问题.
- **Moving the binder past the coord exposed counts capture had reported all along:** three `geom_sf()` leaves of patchwork-010 and -011 (1626 elements) go from "the panel's scales cannot be mapped (CoordSf)" to count mismatch. Neither is checked. → predictions.md; nowhere else yet (sf geometries are out of this plan).

## What's next

- Task 5 (written out in the plan): tree-014's leaf of points in eight shapes (12690 elements, half the stratum's layer elements). First measure what each `pch` draws on svglite, then capture's expected count per shape and a comparison for one row drawn as several elements. This is what moves the element-weighted share, and v0 has the same class.
- Task 6: what is left after Tasks 1-4, all small: repelled labels (tree-054, 41 + 28), ggtree's draw-time `nudge_x` (6), halo copies (20), `<image>` elements (17), tree-003's text leaf with 5 elements for 11 rows (5).
- Decision 1 (the owner's): run the stratum's held-out half once at the end of this plan (recommended), or after M1.
- Still open for the owner from before: widen the stratum's figure test in a later round; a batch of tree figures for the lab. The lab's labels on the fifteen figures, when they come: `score-labels.R agree`, predictions 43-52.
