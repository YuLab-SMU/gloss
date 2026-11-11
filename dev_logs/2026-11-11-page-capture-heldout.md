# 2026-11-11 — Page capture on the held-out set; the plan closes

- **Related plan:** [plan/done/2026-11-11-page-capture.md](../plan/done/2026-11-11-page-capture.md) (closed this session; Task 8 done). The two earlier logs of this plan link to its old place, `plan/2026-11-11-page-capture.md`.
- **Related ADRs:** [ADR-0006](../dev_docs/decisions/0006-capture-the-page-the-figure-draws.md) (accepted; unchanged).
- **Worked on by:** Yonghe Xia, Claude
- **Follows:** [2026-11-11-page-capture-execution.md](2026-11-11-page-capture-execution.md)

The owner answered the four open questions of the last log: run the held-out set now; other R versions stay a risk until a release; the container suite becomes a rule for code that reads device output; the M0 `<<-` are removed now.

## What changed

| Commit | Change |
|---|---|
| `5458cad` | AGENTS.md: code that reads what a graphics device wrote is done only when the suite has also passed in the bench container. `bench/R/suite.R` runs it there and prints the counts. |
| `0df5774` | Design §风险与未决问题: R versions other than 4.5.2 are tested before a release, not now. |
| `529426c` | Predictions 9–20 and the scoring rules for the held-out run, committed before it. `score-capture.R` accepts a held-out file. The engine-route procedure tried on the development set first (run `0832`). |
| `f0413eb` | Both held-out runs, archived as run, before any change. |
| `a061a26` | Predictions scored; plan Task 8 result and a scope change. |
| `02f9599` | `scan_code_for_data()`, `decode_dense_index()` and `element_boxes()` without `<<-`; `test-hygiene.R` forbids it in every function of the package. |
| `21988ee` | Fix: the kind of page is read from the device's display list. Made after looking at the held-out run. |
| `31c3b06` | Design doc: held-out numbers, the defect, dated notes; development rerun `0858` archived. |
| _this commit_ | Plan closed and moved to `plan/done/`; this log. |

## Measured

- Suite at the start: 7 files / 65 tests / 420 expectations / 0 failed / 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, `e883b20`). At the end: 8 files / 67 tests / 438 expectations / 0 failed / 0 skipped on the host, and the same counts with 0 errors in the bench container (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R`, R 4.5.2, aarch64-unknown-linux-gnu). In between: 66 / 421 after the `<<-` test.
- Engine-route procedure, development set (made after looking, not a reported number): a clean clone at `engine-route-final` with the seven vendored `data/` directories copied in; every file under `bench/figures/` has this repository's checksum. Run `2026-11-11-0832-capture-dev-engine-route`: 51 captured, 3 refused, 1 error; 40 equal, 6 known exceptions, 5 different. These are the counts of run `2026-11-10-1424`.
- **Held-out set, 54 figures, one run per route** (`GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/capture.R heldout`; predictions in `529426c`):
  - Page route, `2026-11-11-0837` at `529426c`, clean tree: 52 captured, 2 refused ("the page mixes base graphics and grid": bioc-019, bioc-023), 0 errors, 0 timeouts. 50 equal, 2 not deterministic (exts-002: two drawings differ in 1399 primitives; patchwork-013: 742), 0 different. gloss's verdict agrees with the bench's on 52 of 52, identical on 50; 0 failed invariants. Base: 7 of 9 equal, 2 refused; 110 leaves with an expected count, all `ok`; 137 without one. Withheld tables or panels: 3 figures. Only the device background unowned: 52 of 52. Median time by engine 0.11 to 0.62 s, maximum 5.3 s.
  - Engine route, `2026-11-11-0843` at `f48c124`, its own harness and judge (no clip regions, two kinds of known exception, no `not_deterministic`): 53 captured, 1 refused (exts-015, ggsurvfit's print method), 0 errors. 40 equal, 5 known exceptions, 8 different. Base: 0 of 9 equal; 7 of 9 with a count mismatch.
  - Figure by figure: the 40 figures equal on the engine route are equal on the page route. Ten more are equal on the page route only: seven base figures, exts-015, and two dense figures (the last two by the judge: a rasterized leaf is a known exception there, a vector recapture here).
- Predictions 9–20: 10 right, 2 wrong (12 and 17). Two of the ten were right at their limit (14: identical verdicts on all but 2; 16: 3 figures with something withheld).
- `<<-` refactor: outputs of the three functions identical before and after on a code scan, four captures (ggplot, base, grid, a 12,000-point dense leaf) and their bundle round trips, 12 of 12 items. `test-hygiene.R` on the old code: 1 failed of 1, naming the three functions.
- Mixed-page defect, hand-built page (a grid page, then a base page, drawn by a function and as a recorded plot): before the fix refused with "7 base operations, 2 grid grobs"; the device's display list for the page holds 7 base operations and 0 grid operations. After: captured as a base page, `equal`, the same primitives and clip regions as the base plot drawn alone. A page that mixes the two (1 grid operation on the device's list) is refused before and after, also as a recorded plot. `Rscript bench/R/check-runner.R`: OK.
- Development set after the fix, run `2026-11-11-0858` at `21988ee`: every column of every row equals run `0705` except the seconds; 52 equal, 2 not deterministic, 1 refused.
- `quarto render dev_docs/design.qmd --to html`: exit 0, no warnings.
- Not run: the held-out set after the fix; whether bioc-023's refusal has the same cause as bioc-019's; `R CMD check` after this session's changes (last run at `84abf35`, 2 NOTEs); anything on R versions other than 4.5.2.

## Surprises

- **Two held-out base figures were refused as mixed pages, and neither is known to be one.** The development set has no such figure (0 of 55). Both are the last figure of a Bioconductor vignette that drew grid figures before, on the same device. `page_kind()` counted the grobs on grid's own display list, which a new base page does not clear. Evidence for bioc-019 without rerunning it: the engine route's capture is the code's page plus one background rect, nothing missing, and gridGraphics redraws base operations only. → plan scope change (Task 8); fixed in `21988ee` with a hand-built failing test, reported as made after looking in `bench/predictions.md`, NEWS and design §元素归属; the held-out set was not run again.
- **"0 of 55 mixed pages" had measured the test, not the pages.** The plan's *Out of scope* and the design both quoted it as a frequency. → design doc (§元素归属, dated note on the sentence; §风险与未决问题, new item: 55 figures do not show a failure class rarer than a few percent).
- **The engine route captured more held-out figures than the page route** (53 against 52); prediction 17 expected the opposite from the development set, where the engine route lost four. Its two extra captures are the two refused figures, and neither is the code's page by its own judge. → `bench/predictions.md` (17 wrong); nowhere else: the count of captures is not the measure the plan is held to.
- **One figure is a known exception on the engine route and refused on the page route** (bioc-019). Prediction 20 holds by its wording ("equal on the engine route") and fails in spirit for this figure. → `bench/predictions.md`, plan Task 8 result; the cause is the defect above.
- **gloss saw neither of the two random held-out figures.** Both are `equal` for gloss and `not_deterministic` for the bench (development: one of two). This is the reading the design already gives `equal`, now 3 of 4 cases. → design §元素归属 (held-out paragraph). Nowhere else yet: making gloss draw twice was weighed and declined in §风险与未决问题; three cases of four do not change that argument, they make the printed wording of `equal` matter more.
- **More than half of the base leaves on the held-out figures have no expected count** (137 of 247; development 574 of 2043). "No count mismatch" covers the rest only. → plan closing notes (what the next plan starts with); it is an M1 question, since a leaf without a count can still be captured and classified.
- **The command for the container suite was not written down anywhere**, although the last log quoted its counts. → `bench/R/suite.R` and AGENTS.md.

## What's next

- **For the owner:** whether to run the held-out set once more on the fixed code. It would show what the fix does on bioc-019 and bioc-023, and it would be a second look: reported beside the first run as made after looking, never in its place. Not running it keeps the first run the only one, with the two figures' state unknown.
- **M1 can start** from the closed plan's numbers; the next plan is drafted from `plan/_template.md`. Its first questions for base figures: binding through the call's arguments and `usr`, and what to do with leaves that have no expected count.
- **Before a release:** the suite and the base replay on R-oldrel and R-devel; `R CMD check --as-cran` on Linux and Windows, and again on macOS after this session's changes.
- `bench/R/runner.R` still uses `<<-` in two places. It is not package code and no rule covers it; left as it is.
