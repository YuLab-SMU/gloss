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

## What's next

- Run the frozen offline proposal fixture through the same check boundary and emit a targeted audit queue. The result must distinguish a code-verifiable claim, a model proposal that is rejected by evidence, and a meaning claim for which code has no authority.
