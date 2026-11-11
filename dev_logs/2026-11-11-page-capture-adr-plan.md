# 2026-11-11 — Page capture decided: ADR-0006 and its plan

- **Related plan:** [plan/2026-11-11-page-capture.md](../plan/2026-11-11-page-capture.md) (opened today; all tasks open). [plan/2026-11-09-bench-v0.md](../plan/2026-11-09-bench-v0.md) (active; Task 7 open).
- **Related ADRs:** [ADR-0006](../dev_docs/decisions/0006-capture-the-page-the-figure-draws.md) (new, accepted); status lines of ADR-0001 and ADR-0004.
- **Worked on by:** Yonghe Xia, Claude
- **Follows:** [2026-11-10-page-capture-spike.md](2026-11-10-page-capture-spike.md)

## What changed

The owner chose option 3 of the idea note (page capture, grid pages first, base pages second) and asked for the ADR and the plan before any code. Documents only; nothing in `R/`, `tests/` or `bench/`.

| Commit | Files | Change |
|---|---|---|
| `01cf687` | `dev_docs/decisions/0006-*.md`, status lines of `0001` and `0004`, index | ADR-0006 accepted. |
| `a36e851` | `plan/2026-11-11-page-capture.md`, `plan/README.md`, idea note and index, bench v0 plan (scope change) | Plan opened; idea marked promoted. |
| records commit | `dev_docs/design.qmd` (four dated notes), this log | Decision routed into the design doc. |

## Measured

- Suite at the start (`aef42f2`) and at the end: 7 files, 49 tests, 298 expectations, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`, counted from the result's data frame). Unchanged, as expected: no code changed.
- `quarto render dev_docs/design.qmd --to html`: renders.
- Not run: the bench, in the container or otherwise; the held-out set; any of the spike scripts. Every number in the ADR and in the plan's starting state is quoted from the runs of 2026-11-10.

## Surprises

Found while reading the code against the spike to write the plan; none is measured yet.

- **The spike's 54 of 55 is not `gloss(object)`.** `s3-dev-set.R` wraps the page the frozen code left on its own device. The package has no entry for that today: `gloss()` takes an object, a function or a recorded plot. For the 42 figures recovered as objects, the object printed alone equals that page in 39. → plan: the reference for an object is the page that object draws; the bench hands a drawn page over as a recorded plot (assumption 4, Task 4).
- **With `print(x)` drawing, tables and page come from two builds.** Today the ggplot engine draws from the build it reads tables from. A build that uses random numbers (jitter without a seed) would give tables that are not the drawn points, and for a print method that draws something else (ggbreak) the built tables describe a plot that is not on the page. The spike compared tables only on deterministic inputs. → plan assumption 1, ordered first (Task 2); ADR-0006 point 4 (withhold with a reason).
- **Rasterising a dense leaf redraws one leaf from the wrapped tree,** which the in-place route does not have as one object. → plan assumption 2, Task 3.
- **The base route reads a recorded plot's internal structure,** which R documents as subject to change, and calls its entries; ADR-0001 had only public grid API. → ADR-0006, accepted tradeoffs and *Revisit when*; plan assumption 6 (`R CMD check --as-cran`).
- **Dispatch by class does not fix the page kind for a function or a recorded plot:** the base engine declares both classes today, and a function that draws with grid ends in an unexplained error. → ADR-0006 point 4, last item; the form is left to Task 1's contract tests.

## What's next

- Owner's review of ADR-0006 points 3 and 4, which go beyond "option 3" as stated in the idea note: a figure that is not deterministic is captured and reported instead of refused; an engine may keep a drawing step of its own under a contract test; tables are withheld where they cannot be shown to describe the page.
- Then Task 1 of the page-capture plan, starting with the tag `engine-route-final` and the failing tests.
- Gaps against the evaluation standard, flagged and not acted on: the development numbers were all made after looking, so the only reportable capture number will be the held-out run of Task 8, with both routes on the same figures and predictions committed first; the fidelity verdict has a single comparator written by the same hands as the capture, so Task 4 keeps the bench's proof of each verdict independent of the package's self-check.
- Bench v0 Task 7 (records) is still open.
