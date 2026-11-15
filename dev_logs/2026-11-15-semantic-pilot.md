# 2026-11-15 — semantic pilot starts with a closed claim check

- **Related plan:** [plan/2026-11-15-semantic-pilot.md](../plan/2026-11-15-semantic-pilot.md)
- **Related ADR:** [ADR-0010](../dev_docs/decisions/0010-targeted-human-audits-and-evidence-bearing-correspondence.md)
- **Worked on by:** Codex.

## What changed

- Added the exported `gl_check()` runner for registered semantic check plugins.
- Added the built-in `trend` check. It works on one built data frame, keeps one row of evidence per group, and returns `verified`, `failed`, `partial` or `refused`.
- Added tests for schema errors, missing columns, all-pass, mixed, all-fail and unrunnable groups.
- Opened the semantic pilot plan. The proposal fixture and offline comparison are the next task; records, anchors and rebase remain out of scope.

## Measured

- Starting suite: 17 files, 1450 expectations, 0 failures, 0 skips.
- After Task 1: `NOT_CRAN=true Rscript -e "devtools::test()"` → 17 files, 1477 expectations, 0 failures, 0 skips.
- Targeted semantic tests: 26 expectations, 0 failures, 0 skips.
- On the built mtcars point layer, the negative trend claim is `partial`: five of six facet × cylinder groups pass and the automatic 4-cylinder group has slope `+3.067891`. The 8-cylinder subset is `verified`.

## Surprise

- The built `geom_smooth()` table contains prediction rows rather than the source observations. The pilot therefore checks the point layer's built data for the claim, while the smoother remains the visible representation. This keeps the check on the data the figure actually draws and preserves the group-level exception.

## Pilot result

- The offline fixture has 5 proposals: 1 code and 4 model-shaped. The code proposal is `verified`; the model-shaped proposals are 1 `failed`, 1 `partial`, 1 `refused` and 1 `uncheckable`.
- The false trend proposal is rejected by the check (`failed`); the universal trend proposal remains `partial` because the automatic 4-cylinder group has slope `+3.067891`. Neither is upgraded to a verified fact.
- Three cases enter the targeted audit queue: the mixed trend wording, an open-world meaning claim with no closed check, and a predictor column that is absent from the built table. The audit CSV carries the question and group evidence where code has it. The run is archived at `bench/runs/2026-11-15-semantic-pilot.{csv,json}` and `-audit.csv`.
- Final host suite after the documentation sync: `NOT_CRAN=true Rscript -e "devtools::test()"` → 17 files, 1477 expectations, 0 failures, 0 skips.

## Surprise

- A check can reject a false declaration without deciding the author's intended wording. The mixed trend is therefore an audit candidate even though the data already expose the exception; the open-world meaning claim is a different kind of gap because code has no truth procedure for it.

## What's next

- Get a small independent audit on the three queued cases. Use it only to decide whether the check vocabulary or route changes; do not turn this fixture into a model-accuracy or broad human-label result. If the audit does not change the route, start the next plan from M2 records and anchors.
