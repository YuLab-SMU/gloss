# gloss on the tree stratum: every page captured, what ggtree users add bound

> Status: active (opened 2026-11-11 on the owner's word, "按你的建议开树图计划", after the tree stratum's first runs).
> Date opened: 2026-11-11. Owner: Yonghe Xia.

**Goal:** On the 29 development figures of the tree stratum, gloss captures every page or refuses it with a reason, and the layer elements it does not check today because a comparison does not fit what was drawn (labels moved off their node by justification or rotation, circular and fan layouts, text drawn as glyph outlines) are either checked against their rows or left unchecked with a reason that names what they are.

**Why now:** The tree plan's first runs ([closing notes](done/2026-11-11-bench-tree-stratum.md#closing-notes), [dev log](../dev_logs/2026-11-11-m1-plan.md), last two sections) found gloss captures tree figures as well as v0's but binds 40.1% of their layer elements against 98.4% on v0's ggplot figures, and stops with an internal error on one page, against the invariant. Branches bind (5216 of 5216); what fails is what ggtree users add around the tree. These are the figures the owner's lab draws. The dev log's *What's next* proposed this plan, ordered by the figures each class affects; the owner accepted it on 2026-11-11.

**Starting state (measured):**

- Suite at `b02ea8c`: 9 files, 88 tests, 544 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-11, host).
- Stratum, development half (29 figures), container with no network:
  - capture run `2026-11-11-2110` at `a578985`: 28 captured, 27 `equal`, 1 `not_deterministic` (tree-054), tree-041 stops with `internal error: Huge input lookup [1]`;
  - binding run `2026-11-11-2118` at `0cc6e72` (`Rscript bench/R/score-bind.R bench/runs/2026-11-11-2118-bind-dev-tree.csv`): 24915 layer elements, verified 9662, ambiguous 322 (40.1%), failed 212, unbound 308, count mismatch 14411; 83.3% without tree-014's leaf of 12690 points; per figure, of 27 ggplot figures, every layer element checked in 15, at least 80% in 18, none in 3.
- Every element not checked in run `2118`, by class (from the run's leaves and predictions 58-62's scoring):

  | Class | Figures | Elements | Today |
  |---|---|---|---|
  | A page the parser refuses (embedded images) | tree-041 | the whole figure | internal error |
  | Labels justified outside 0..1 | tree-011, -060, -083 | 128 | failed (rightly paired) |
  | Polar coordinates (circular, fan, inward layouts) | tree-025, -038, -057 | 241 | unbound, `CoordPolar` |
  | Text drawn as glyph outlines (`emojifont` turns `showtext` on) | book figures: tree-014, -046, -054, -062 | 1721 + 37 | count mismatch; failed |
  | Points in several shapes in one leaf | tree-014 | 12690 | count mismatch |
  | Rotated labels | tree-072 | 34 | unbound, "rotated text?" |
  | Repelled label boxes and their connectors | tree-054 | 41 + 28 | failed; unbound |
  | A text leaf with 5 elements for 11 rows | tree-003 | 5 | unbound |
  | Not explained | tree-045 | 6 | failed |

  The classes add up to the run's totals: failed 128 + 37 + 41 + 6 = 212; unbound 241 + 34 + 28 + 5 = 308; count mismatch 1721 + 12690 = 14411.
- v0, development set: binding run `2026-11-11-1353` is the reference every binder change is compared with (ggplot layer elements 98.4% checked, failed 8, unbound 370; heatmap 250 of 250; base 98.6%; patchwork 104 checked of 1783).

**Assumptions to test** (riskiest first):

1. *The offset of a justified or rotated label from its row is a share of the label's own measured size, so it can be checked as tightly as an unjustified one.* Evidence, one hand drawing (svglite 2.2.2, host, 2026-11-11): the anchors of `hjust = -0.1` labels sit at x + 0.1 × `textLength` within 0.38 pt; the baseline under `vjust = -0.5` sits 0.75 pt from where the string height of "M" puts it. Tested in Task 2. The along-baseline check keeps its tolerance (0.5 pt); the across-baseline check may be no looser than today's box (one font size). If that cannot hold, justified labels are unbound with the reason "justified outside 0..1", never verified by a looser rule.
2. *The coord's own transform puts built rows where a non-Cartesian panel draws them,* and a segment under polar coordinates is a munched path whose ends are its row's transformed ends. Tested in Task 3, on a fixture and on tree-025, -038, -057. If ggtree's geoms draw circular layouts other than the coord says, binding them needs per-geom code, which design §绑定假设 holds against; those leaves stay unbound with the reason, and the claim is narrowed in the design doc.
3. *Mapping Cartesian panels through the coord's transform changes nothing on v0.* Tested in Task 3 by v0's development binding run against run `1353`. Any element that moves is explained before the task is done.
4. *A text leaf drawn as outlines can be told from the page alone* (a text grob whose elements are all `<path>`), without asking whether `showtext` is on. Tested in Task 4 on a fixture under `showtext` and on the four book figures.
5. *tree-041 is one parser limit, not a class of pages:* libxml2 refuses a node over 10^7 bytes unless `HUGE` is set; with it, tree-041 is captured and nothing else on the page changes. Tested in Task 1. If tree-041 then fails elsewhere (memory, time), it is refused with that reason.

**Architecture:** Changes stay in capture and binding. `R/core-substrate.R` and `R/core-bind.R` parse gloss's own pages without the parser's size limit (Task 1). The text comparison in `R/core-bind.R` works in the label's own frame (along and across its baseline), from row columns the engine states when it has them (`hjust`, `vjust`, `angle`), so the comparison is still chosen by tag and counts, never by geom names (Task 2). `R/engine-ggplot.R` puts rows on the device through `Coord$transform()` with the panel's params instead of its own linear map, and `R/core-bind.R` gains a comparison for a path paired one per row whose row has ends: its first and last vertices at the row's ends (Task 3). Capture says when a text leaf was drawn as outlines, and the binder gives that as the reason (Task 4). `bench/R/runner.R`'s comparator gets the same parser option as gloss (a bench change, Task 1). Not touched: roles, labels and the workbench; the bundle format; exported functions; the M1 plan's tasks.

**Out of scope:**

- The stratum's held-out half, until Task 7 under decision 1.
- `aplot` compositions: the stratum's figure test leaves them out (three PSUs), so no retained figure measures an engine for them; a later round if the owner widens the test.
- Repelled labels (tree-054): ggrepel places them at draw time, not at their rows; stub Task 6.
- Rules, roles and anything measured on v0's held-out set.

**Tech stack:** R 4.5.2; ggplot2 (`Coord$transform()`, `coord_munch()`), grid, svglite >= 2.2, xml2; showtext for one fixture (Suggests); the bench container (Bioconductor 3.21, ggtree 3.16.3, ggplot2 4.0.0).

**Done when** (the stratum's 29 development figures in the container with no network, unless said):

- tree-041 is captured or refused with a reason, and no figure of the 29 ends in an error that is not a refusal. A test with a page over the parser's limit fails before the fix.
- Labels justified outside 0..1 or rotated: the elements of tree-011, -060, -083 and -072 counted above are verified or ambiguous, with the along-baseline tolerance at 0.5 pt. A fixture test fails before the change; a mutation that permutes the labels of a leaf fails on every label it moves, ties aside.
- Polar coordinates: no layer leaf of tree-025, -038 or -057 is unbound for "the panel's scales cannot be mapped"; each is checked or unbound for another stated reason. A fixture under `coord_polar()` fails before the change; the same mutation fails.
- Glyph outlines: every text leaf of the 29 figures drawn as outlines says so in its reason, and none of its elements is `failed`.
- v0: after each binder change, v0's development binding run moves no element from verified or ambiguous to failed, unbound or count mismatch against run `1353`; any other move is listed with its cause.
- The stratum's shares (per figure first, then per element with and without tree-014's leaf) reported against run `2118`; predictions committed before each run; every run archived in `bench/runs/`.
- The suite passes with its counts at every commit that touches `R/` or `tests/`; the container suite also passes for Tasks 1 and 4 (code that reads what the device wrote).

**Decisions (the owner's; the recommendation is Claude's):**

1. *When the stratum's held-out half is run.* (a) Once, at the end of this plan, with the binder frozen at a commit and predictions committed before: a reported number for tree figures now. A later change to the binder (M1 Tasks 3-6) would mean a second run, archived and reported as made after the first. (b) After M1 closes, together with v0's held-out binding run: one run for both, and no reported number on tree figures until then. **Recommended: (a).** The lab cares about tree figures now, and nothing in the M1 tasks left open is planned to change how ggplot layers bind. Needed only by Task 7.

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
- Suite: 9 files, 96 tests, 620 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-11, `73b317d`; the container the same); was 88 / 544 at `b02ea8c`.
- Key numbers: stratum development half, 29 of 29 captured (run `2221`); 41.5% of 25037 layer elements checked, failed 67, unbound 87, every text leaf drawn as outlines named; every layer element checked in 22 of 28 ggplot figures, none at 0 (run `2344`). Was 28 captured, 40.1% of 24915, failed 212, unbound 308, 15 of 27 (runs `2110`, `2118`). v0 development binding: 0 regressions against run `1353`; gallery-020's 5 labels gained (run `2315`).

**Overall progress**
- [x] Task 1: A page over the parser's limit (tree-041)
- [x] Task 2: Labels in their own frame: justification and rotation (tree-011, -060, -083, -072; tree-045)
- [x] Task 3: Polar coordinates through the coord's transform (tree-025, -038, -057)
- [x] Task 4: Text drawn as glyph outlines (the book figures)
- [ ] Task 5: Points in several shapes (tree-014) _(stub)_
- [ ] Task 6: What remains: repelled labels (tree-054), tree-003's text leaf _(stub)_
- [ ] Task 7: The stratum's held-out half, one run _(stub; decision 1)_
- [ ] Task 8: Records: design notes, NEWS, dev log, closing notes

Each of Tasks 1-4 ends with a run on the stratum's development half, predictions committed before it. Tasks 2-4 change the binder, so each also reruns v0's development binding and compares it with run `1353`.

---

### Task 1: A page over the parser's limit (tree-041)

**Status:** `[x]` (2026-11-11)

**Tests assumption:** 5.

**Files**
- Modify: `R/core-substrate.R`, `R/core-bind.R` (every parse of a page gloss drew); `bench/R/runner.R` (the comparator).
- Test: `tests/testthat/test-capture.R` (a page with an embedded raster over 10^7 bytes of base64).

**Intent**
- The invariant: when gloss cannot capture a page it refuses and says why. tree-041 gets neither; an error of the XML parser escapes. Its page embeds images whose base64 exceeds libxml2's limit for one node.
- Pages gloss drew itself are trusted input; the limit guards against hostile documents, which gloss does not parse on this path. A plain SVG handed to gloss from outside (`figure_from_plain_svg()`) keeps the limit, and a document over it is refused with the reason.

**Checklist**
- [x] A test that fails first: a ggplot or grid page with a raster large enough that its base64 exceeds 10^7 bytes is captured, its elements counted, and its binding step runs. — `test-capture.R`, a grid page and a base page with a 1900 × 1900 raster (16.6 MB of SVG) and two points, each through `bind_capture()`. Before the fix, on the host: `AttValue length too long [40]` from `inline_groups()` (libxml2 words the same limit differently from the container's `Huge input lookup`). After: 11 expectations pass in 8.5 s: verdict `equal`, the image and both points owned by leaves, every leaf bound, base's two points verified. `skip_on_cran()` (slow).
- [x] Parse gloss's own pages with `HUGE`; the bench's comparator too (a bench change, recorded as such). — `read_page()` in `R/core-substrate.R`, used at every parse of a page gloss drew (capture's three pages, the base scene, the scene's geometry for binding, the regression signature, the engine contract's page check); the base route's "not well-formed" refusal now carries the parser's message. `compare_pages()` in `bench/R/runner.R` reads with `HUGE`; `check-runner.R` gains a page with the same raster: the comparator before the change gives no verdict (`AttValue length too long`), after it `faithful TRUE`.
- [x] A plain SVG over the limit from outside: refused with a reason naming the limit (a test). — `read_outside_svg()` in `R/core-bundle.R`; `test-bundle.R`: an 11 MB attribute, `gl_read()` refuses with "the XML parser refused it" and says such a node is read only from pages gloss drew (2 expectations).
- [x] Suite on the host; container suite (code that reads what the device wrote). — Host: 9 files / 90 tests / 557 expectations / 0 failed / 0 skipped (was 88 / 544). Container (`bench/R/suite.R`): 9 / 90 / 557 / 0 failed / 0 errors / 0 skipped / 0 warnings. `Rscript bench/R/check-runner.R` on the host: OK, exit 0.
- [x] Predictions (63-), then `capture.R dev tree` and `bind.R dev tree` in the container; scored. — Predictions 63-66 at `4391fdb`; runs `2221` (capture) and `2224` (binding) at that commit: 3 right, 1 wrong (`bench/predictions.md`).

**Verification**
- `NOT_CRAN=true Rscript -e "devtools::test()"` on the host and `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R`.
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev tree`: tree-041 captured or refused with a reason; the other 28 as in run `2110`.

**Result** (2026-11-11; the stratum's 29 development figures, container, no network)
- Capture, `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R dev tree` at `4391fdb` (run `2026-11-11-2221`): 29 of 29 captured; tree-041 `equal` by the bench and by gloss (125 primitives each side), 6.6 s, background the only unowned element. The other 28: no cell differs from run `2110` in 37 columns besides the seconds (the 38th, `message`, is empty in both).
- Binding, `... bench/R/bind.R dev tree` at `4391fdb` (run `2026-11-11-2224`): no bind error. `Rscript bench/R/compare-bind.R bench/runs/2026-11-11-2118-bind-dev-tree.csv bench/runs/2026-11-11-2224-bind-dev-tree.csv`: 561 of 561 leaves of the 28 figures unchanged, 0 regressions. tree-041's 122 layer elements: verified 24 (its 22 branches among them), failed 10, unbound 17 (images: no comparison for `<image>`), count mismatch 71 (the labels' glyph outlines).
- Stratum totals: 25037 layer elements, 40.0% checked, failed 222, unbound 325, count mismatch 14482; per figure, of 28 ggplot figures, all checked in 15, at least 80% in 18, none in 3.
- `Rscript bench/R/check-runner.R`: OK on the host (exit 0); in the container OK with 1 skipped (install check, no network), exit 0.
- Predictions 63-65 right; 66 wrong: tree-041's 10 failed elements are two classes this plan did not list (Scope change below).

---

### Task 2: Labels in their own frame: justification and rotation

**Status:** `[x]` (2026-11-11)

**Tests assumption:** 1.

**Files**
- Modify: `R/core-bind.R` (the text comparison), `R/engine-ggplot.R` (state `hjust`, `vjust`, `angle` with the rows when the built data has them).
- Test: `tests/testthat/test-bind.R`.

**Intent**
- The text rule puts the anchor's x at the row's x and the row's y inside the text's box. A label written with `hjust = -.1` is drawn a tenth of its own width away from its row and fails, rightly paired (128 elements in three figures). A rotated label is not compared at all (34 elements in tree-072), and polar layouts rotate their tip labels (Task 3 needs this).
- In the label's own frame the offset from the row is known: along the baseline, (hjust − the anchor svglite wrote) × `textLength`, which svglite writes from the same measure R used to place it; across the baseline, a share of the text's height. The check reads the angle from the element's transform and the justification from the row, so it applies to any engine whose rows state them.
- tree-045's 6 failed elements (3 label boxes, 3 tip labels, `plot_tree(orient = "v")` of cardelino) are read before the rule changes: if they are another class, they get their own line here or in Task 6.

**Checklist**
- [x] Read tree-045's failed elements and say what they are. — 3 label boxes of `geom_label()` (0.66 pt off: the box class of tree-041, Scope change of Task 1) and 3 tip labels of `plot_tree(orient = "v")`, which cardelino draws with `geom_tiplab(hjust = 0.39, vjust = 1)` under `coord_flip()`: svglite anchors them at the middle, so the old rule was off by 0.11 of each label's width (4.66 pt at most).
- [x] Tests that fail first: `geom_text()` with `hjust = -0.1, vjust = -0.5`; with `angle = 30` and `hjust = 0.3`; a label leaf with its labels permuted fails on every moved label. — `test-bind.R`: six cases (hjust or vjust outside 0..1, both, inside but not 0/0.5/1, rotated 30°, rotated -90° and outside), each verified with max deviation under 0.05 pt and failing on all five labels when permuted; label boxes of plain `geom_label()` for hjust 0.5, 0 and 1. Before the change 14 of 24 and 3 of 6 expectations failed: justified labels `failed`, rotated ones `unbound`, 3 of 6 boxes per case `failed`.
- [x] The comparison in the label's frame; along the baseline at 0.5 pt; across it no looser than today's box. — `R/core-bind.R`: along the baseline, row = anchor + (hjust − the anchor svglite wrote) × `textLength`, at 0.5 pt; across it, the row inside the text's box as before (−0.2 to 0.8 of the font size), moved by the part of vjust outside 0..1 times the ascent of "M", measured with `strheight()` on svglite once per font and size. On a hand drawing the model is exact to 0.005 pt over 120 cases (6 hjust × 5 vjust × 4 angles). A row with no justification is taken as justified where svglite anchored it (the old rule; base text). A polygon whose rows state hjust and vjust (a label's box) is compared by its box centre, moved by (0.5 − hjust) and (0.5 − vjust) of its size in the row's angle; other polygons keep the vertex mean. `R/engine-ggplot.R` states `hjust`, `vjust` (names read as numbers; `inward`/`outward` as NA) and `angle` with the rows.
- [x] Suite on the host. — 9 files / 92 tests / 587 expectations / 0 failed / 0 skipped; the container the same (the rule reads svglite's output and measures fonts on the device, and Linux has other fonts).
- [x] Predictions, then `bind.R dev tree` and `bind.R dev` (v0) in the container; v0 compared with run `1353` leaf by leaf. — Predictions 67-72 at `6d11c86`; runs `2241` and `2244`: 6 of 6 right.

**Verification**
- The elements of tree-011, -060, -083 and -072 counted in the starting state: verified or ambiguous. v0: no element moves to failed or unbound.

**Result** (2026-11-11, container, no network)
- Stratum, `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/bind.R dev tree` at `6d11c86` (run `2026-11-11-2241`): 25037 layer elements, verified 9784, ambiguous 376 (40.6%), failed 104, unbound 291, count mismatch 14482 (was 40.0%, 222, 325, 14482 in run `2224`). `compare-bind.R` against `2224`: 566 of 595 leaves unchanged, 29 changed, all in tree-011, -041, -045, -060, -072 and -083; 0 regressions. tree-011, -045, -060, -083: every layer element checked (453, 22, 87, 76). tree-041: its 4 boxes verified. tree-072: 14 of 34 verified, 20 failed (halo copies, 0.57-0.81 pt; Scope change). Per figure, of 28 ggplot figures: all checked in 19 (was 15), at least 80% in 21 (was 18), none in 3.
- v0, `... bench/R/bind.R dev` at `6d11c86` (run `2026-11-11-2244`): `compare-bind.R` against `1353`: 7114 of 7114 leaves with status, counts and reason unchanged; 0 regressions.
- Suite: host 9 files / 92 tests / 587 expectations / 0 failed / 0 skipped; container the same.

---

### Task 3: Polar coordinates through the coord's transform

**Status:** `[x]` (2026-11-11)

**Tests assumption:** 2 and 3.

**Files**
- Modify: `R/engine-ggplot.R` (`ggplot_rows_on_device()` through `Coord$transform()` and the panel's params; panels of a non-Cartesian coord are mappable), `R/core-bind.R` (a path paired one per row whose row has ends).
- Test: `tests/testthat/test-bind.R`.

**Intent**
- Circular and fan layouts are common in tree figures, and three of 28 bind nothing. The engine maps rows through continuous or discrete scales only; the coord's own transform is what ggplot2 uses to draw, under any coord.
- Under a non-linear coord, `GeomSegment` draws each segment as a path munched along the coord: one path per row, its ends at the row's transformed ends.

**Checklist**
- [x] Tests that fail first: `coord_polar()` with points, segments and text (rotated by `angle`); permuted rows fail. — `test-bind.R`: points, segments, text rotated by `angle` with `hjust = -0.1`, and points under `theta = "y", start = 1, direction = -1`: each leaf's 5 elements verified or ambiguous, and all 5 fail when the rows are permuted. Before the change no leaf was claimed (the engine stopped at the panel's scales).
- [x] Rows through `Coord$transform()`; a coord whose transform fails leaves its leaves unbound with the coord's name and the error. — `ggplot_rows_on_device()` maps every coord through its own transform and the panel's params, then the panel's box; a linear coord transforms all position aesthetics at once (`coord_flip()` swaps them, so the engine no longer swaps names itself); one that is not linear transforms (x, y) and (xend, yend) as points. Under a coord that is not linear, rows that are rectangles are claimed with the reason that they are drawn as polygons munched along the coord, and a path one per group is unbound with the reason that it is munched (a test: `geom_line()` and a pie under `coord_polar()`, unbound, 0 failed).
- [x] Path one per row with ends: first and last vertices at the row's ends. — `R/core-bind.R`, for `polyline` and `path` elements whose rows have `xend` and `yend`; a test with `geom_curve()` on Cartesian axes (3 verified; before, failed on the vertex mean).
- [x] Suite on the host. — 9 files / 95 tests / 610 expectations / 0 failed / 0 skipped; container the same.
- [x] Predictions, then `bind.R dev tree` and `bind.R dev` (v0); v0 compared with run `1353`. — Predictions 73-75 at `c19c6f5` (runs `2300`, `2303`): 2 of 3 right; 75 wrong, which found a defect (Scope change). The fix at `84b60fb`; predictions 76-77 at `9f448a1` (runs `2315`, `2327`, made after looking): 2 of 2.

**Verification**
- No leaf of tree-025, -038, -057 unbound for "the panel's scales cannot be mapped". v0 unchanged, or every move explained.

**Result** (2026-11-11, container, no network)
- Stratum, `bind.R dev tree` at `9f448a1` (run `2026-11-11-2327`; the same as run `2300` at `c19c6f5` on all 595 leaves): tree-025, -038, -057: 241 of 241 layer elements checked (192 branch polylines by their ends, 134 verified and 58 ambiguous; 49 rotated tip labels verified), 0 failed, 0 unbound. Stratum: 41.5% of 25037 layer elements checked, failed 104, unbound 50, count mismatch 14482; per figure, every layer element checked in 22 of 28 ggplot figures, at least 80% in 24, none at 0 (was 19, 21, 3 in run `2241`). `compare-bind.R` against `2241`: 10 leaves changed, all in the three figures; 0 regressions.
- v0, `bind.R dev` at `9f448a1` (run `2026-11-11-2315`) against `2244`: 8 of 7114 leaves changed, 0 regressions, failed 8 as before. gallery-020: 5 labels verified, 5 slices unbound (rectangles munched along `CoordPolar`); exts-024: 20 bars unbound for the same reason (`CoordCombMatrix`); exts-017: its raster unbound (no comparison for `<image>`); patchwork-010 and -011: three `geom_sf()` leaves (1626 elements) from unbound to count mismatch, the counts capture always reported. Cartesian panels, now mapped by the coord's transform, give the same statuses and counts on every other leaf.
- Suite: host 9 files / 95 tests / 613 expectations / 0 failed / 0 skipped; container the same.

---

### Task 4: Text drawn as glyph outlines

**Status:** `[x]` (2026-11-11)

**Tests assumption:** 4.

**Files**
- Modify: `R/core-substrate.R` (a text leaf whose elements are all paths is marked as outlines), `R/core-bind.R` (the reason).
- Test: `tests/testthat/test-capture.R`, `tests/testthat/test-bind.R` (under `showtext`, skipped when it is not installed).

**Intent**
- The ggtree book's setup attaches `emojifont`, which turns `showtext` on; every glyph is then a path. A text leaf draws one element per glyph and is a count mismatch, or, when every label is one glyph, passes the count and fails on position (37 elements). Neither says what happened.
- First say it. Binding the outlines (a label's glyphs together, against the label's box) is a later step, decided from how many leaves of the four figures it would reach.

**Checklist**
- [x] Tests that fail first: under `showtext`, a text leaf's reason names glyph outlines; a one-glyph-per-label leaf's elements are not `failed`. — `test-bind.R` (`showtext` added to Suggests): labels "A", "B", "C" were `partly_failed` (2 failed), labels "Alpha", "Be ta", "C" a count mismatch saying only "drew 10 elements, its grob 3"; 6 of 7 expectations failed. After: unbound and count mismatch, each with a reason that names glyph outlines and counts paths, labels and characters.
- [x] The mark in capture; the reason in the binder. — Changed from the plan: no mark in capture. The binder tells outlines from the leaf's class (`text`) and its elements' tags (all `path`), which capture already records, so the substrate and the bundle format do not move. `R/engine-ggplot.R` states each row's label, so the reason can count characters.
- [x] Suite on the host; container suite. — Host 9 files / 96 tests / 620 expectations / 0 failed / 0 skipped; container the same (showtext installed there, so not skipped).
- [x] Count, on the four book figures, the text leaves whose glyph paths would group into labels by count (non-space characters per label): the number for deciding the later step. — From the reasons of run `2344`: in 23 of the 67 leaves (five book figures: tree-041 also draws outlines) the paths equal the labels' characters other than spaces; those leaves hold 291 of the 1829 elements drawn as outlines (16%). tree-054's 41 repelled labels are paired with all 126 rows of their group, so their labels cannot be counted against a leaf. Decision: binding outlines label by label is not taken up in this plan.
- [x] Predictions, then `capture.R dev tree` and `bind.R dev tree`. — Changed from the plan: no capture run, since capture did not change. Predictions 78-80 at `57fc97b`; runs `2344` (stratum) and `2347` (v0): 2 of 3 right, 80 wrong.

**Verification**
- Every text leaf drawn as outlines in the 29 figures has the reason; no element of one is `failed`.

**Result** (2026-11-11, container, no network)
- Stratum, `bind.R dev tree` at `57fc97b` (run `2026-11-11-2344`): the 67 layer text leaves drawn as outlines (tree-014, -041, -046, -054, -062) all name glyph outlines, with the counts of paths, labels and characters; 11 unbound, 56 count mismatch, 0 failed. Stratum: failed 67, unbound 87, count mismatch 14482, 41.5% checked; `compare-bind.R` against `2327`: only these 67 leaves changed, 0 regressions.
- v0, `bind.R dev` at `57fc97b` (run `2026-11-11-2347`): 7114 of 7114 leaves unchanged against `2315`.
- Suite: host 9 files / 96 tests / 620 expectations / 0 failed / 0 skipped; container the same.

---

### Task 5: Points in several shapes (tree-014)

**Status:** `[~]` _(written out 2026-11-11, after Tasks 1-4; started 2026-11-12)_

**Tests assumption:** a new one, written here before any of it is measured: *every primitive svglite draws for a point symbol (pch 0-25) is centred on the point*, so a row drawn as k elements can be checked element by element against one centre. A symbol whose primitives are not centred (a triangle drawn with its box off the point, as the vertex-mean rule already knows) gets the centre its own family uses; a symbol that cannot be checked this way is listed with its reason, never passed.

**Files**
- Modify: `R/core-substrate.R` (`expected_count()` for a points grob: the primitives each `pch` draws), `R/core-bind.R` (one row drawn as several elements, in drawing order), `R/engine-ggplot.R` (state `shape` with the rows if the count needs it).
- Test: `tests/testthat/test-capture.R` (a points grob with every shape 0-25: expected count equal to what svglite draws), `tests/testthat/test-bind.R` (mixed shapes bind; permuted rows fail).

**Intent**
- tree-014's leaf of 8100 points in eight shapes draws 12690 elements and is a count mismatch: half the stratum's layer elements, and why its element-weighted share sits at 41.5% while the median figure is checked whole. v0 has the same class (design §风险与未决问题: shapes drawn with more than one primitive).

**Checklist**
- [x] Measure on svglite, host and container, what each `pch` 0-25 draws (tags and count) and where each primitive's centre lies; written to `dev_docs/research/` and read before the rule. — `dev_docs/research/point-symbols/` (`785c807`): host and the container's `bioc` library identical but for the ggplot2 version. Every part is centred across; down its box, every part at 1/2 except the triangles (2, 17, 24 at 2/3; 6, 25 at 1/3; pch 11's two at 3/7 and 4/7), within 0.0075 pt over sizes 3-96 pt. The assumption holds as written for all parts but the triangles, whose share is the symbol's own, as the assumption allowed. What removes parts was measured too: non-finite x, y or size (the point), blank lines (the `<line>` parts), zero size (the circles), with `lty`, `lwd`, `fontsize` inherited and `lex`, `cex` multiplied from parents.
- [x] Test that fails first: a points grob with every shape has an expected count equal to what svglite draws, and binds. — `test-capture.R`: 45 grobs (pch 0-25, characters, codes that draw nothing, blank lines, zero sizes, non-finite positions) counted against svglite; 7 cases of settings inherited from a parent gTree or viewport; ggplot2 shapes 0-25 and a shape by name. `test-bind.R`: shapes 1-8 (75 parts for 40 rows), vector and dense; rows rotated within a shape fail all 75 parts; rows shifted fail every part paired with another row than its own; shapes 0-25 (43 parts); a stated shape with other parts, other tags or another share fails or is unbound with the reason. Before the change: 34 + 14 expectations failed (one per point, count mismatch, no mode).
- [x] Expected count per shape in capture; the comparison for one row as k elements. — `R/core-substrate.R`: `symbol_parts`, `symbol_fy`, `symbol_kind()` (what `GEstring_to_pch()` and `GESymbol()` do with a pch), `points_expected()`. Changed from the plan: a points leaf is counted again where its probe is drawn, with the settings it inherits there (`point_context()`), since a parent's `lty` is not on the leaf. `R/core-bind.R`: mode `symbol` for a points leaf whose rows state `shape`, single-part symbols included; parts by their boxes (circles by the centre the scene writes), so a dense leaf binds. `R/engine-ggplot.R` states `shape`, translated as `GeomPoint` does. An expectation of `test-capture.R` was wrong: a point at `x = NA` was expected to count; R's engine does not draw it (the base route never counted it), so the test's mismatch is now its text leaf only.
- [x] Suite on the host; container suite (capture reads what the device wrote). — Host 9 files / 101 tests / 717 expectations / 0 failed / 0 skipped (was 96 / 620); container (`bench/R/suite.R`) the same, 0 errors, 0 warnings.
- [x] Before the predictions, a class found by reading run `2344`'s leaves: tree-061's `geom_point(shape = '|')` under `emojifont` draws each symbol as a glyph outline (3785 paths), which the vertex-mean rule passed with max deviation 0.49 pt against 0.5. The symbol rule would fail them on their tag. A character symbol drawn as paths is now named as glyph outlines and not compared, as text is since Task 4 (a test that failed first, `test-bind.R`). Suite: host 9 / 102 / 721 / 0 failed / 0 skipped; container the same.
- [ ] Predictions, then `capture.R dev tree`, `bind.R dev tree`, `capture.R dev` and `bind.R dev`; compared with the runs before.

### Task 6: What remains (tree-054's repelled labels, tree-003's text leaf)

**Status:** `[ ]` _(stub)_

Also, from Task 1: ggtree's segments moved by their draw-time `nudge_x` (tree-041, 6); `<image>` elements with no comparison (tree-041, 17). From Task 2: shadowtext's halo copies, drawn at a fixed offset from their row (tree-072, 20 failed by 0.57-0.81 pt).

### Task 7: The stratum's held-out half, one run

**Status:** `[ ]` _(stub; decision 1)_

### Task 8: Records

**Status:** `[ ]`

- Design §绑定假设 and §风险与未决问题 (the tree item, class by class), §与上一版的区别; NEWS for user-facing changes (pages over the parser's limit; justified, rotated and polar labels bound); dev log; closing notes.

---

## Scope changes

_(append-only; never edit completed tasks above)_

- 2026-11-11 — **Two classes found on tree-041 once it was captured; tree-045 explained in part.** **Evidence:** run `2224` and prediction 66 (`bench/predictions.md`). (1) Six dotted lines of `geom_tiplab(align = 2, offset = 2)` fail by up to 128 pt: `GeomSegmentGGtree$draw_panel()` adds its geom parameter `nudge_x` to x while drawing, and the built rows do not hold it. (2) Four of six label boxes fail by 0.67-0.74 pt; plain `geom_label(hjust = .5)` on the host, without `showtext`, gives the same deviations for the same strings, so the binder's comparison (a polygon's vertex mean at the row) does not fit a label's box. tree-045's 3 failed label boxes are this class. **Effect:** Task 2 also covers label boxes (they are placed from their text, so the same frame applies), with a fixture of plain `geom_label()`; its verification adds tree-041's 4 and tree-045's 3 boxes. Task 6 gains the draw-time `nudge_x` of ggtree's segments (6 elements) and `<image>` elements, which have no comparison (17 in tree-041). The starting table's classes stand; tree-041 adds 122 layer elements to the stratum's totals.
- 2026-11-11 — **tree-072's criterion is restated: the label verified, its halo copies checked or failed by no more than the halo's offset.** **Evidence:** shadowtext 0.1.6's `shadowtextGrob()` (read in the container before the run): each label is drawn 17 times, 16 copies moved by 0.1 × the string height of "X" in 16 directions of the device, then the label. Prediction 70, committed before run `2241`, said 10 of the 16 copies would fail; they did, by 0.57-0.81 pt, the label itself verified. The copies are drawn away from their row on purpose and are rightly paired; the exact along-baseline check fails them, as it should, and widening it to pass them would make every label's check weaker. **Effect:** the *Done when* line on rotated labels holds for tree-072's label leaf, and its 20 halo elements are a class for Task 6 (copies of a layer's leaf drawn at a fixed offset), with the offset reported. Nothing else in the criteria changes.
- 2026-11-11 — **Rectangles under a coord that is not linear are told by what is drawn, not by the rows' columns.** **Evidence:** run `2303`, prediction 75: gallery-020's 5 labels, stacked on a pie's slices with `position_stack()`, keep the stack's `xmin`..`ymax` and were given the rectangles' reason. **Effect:** fixed in `84b60fb` with a test that failed first; runs `2315` and `2327` made after looking (predictions 76-77). No task or criterion changes.
- 2026-11-11 — **A bench run loads gloss from the working tree, figure by figure.** **Evidence:** a stratum run at `9f448a1` (`2323`) was going while R/ was edited for Task 4; `run_worker()` calls `pkgload::load_all()` on the repository when each figure starts. The run was discarded unscored and made again on a clean tree (`2327`). **Effect:** before Task 4's runs, the bench copies gloss's source once when a run starts and every worker loads the copy; the copy's digest goes into the run's record.

## Closing notes

_(filled in when the plan moves to `done/`)_
