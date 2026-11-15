# 2026-11-15 — M1 role rules, checks and trees

## Scope

Tasks 3–7 of the active M1 plan: register deterministic role rules, measure
coverage and accuracy against the committed 54-figure labels, run consistency
checks and silent-error scoring, expose the derived roles and the structure/data
views, and measure base legend handling with and without source code.

## Final development run

The archived container run is `bench/runs/2026-11-15-2239-classify-dev.*`,
scored by `bench/R/score-classify.R` into
`bench/runs/2026-11-15-2239-classify-dev-score.txt`.

- The run visited 55 frozen entries: 54 captured figures and the known
  `gallery-053` capture error. The labels join 33243 drawn elements.
- 33231 elements were classified (99.96%); 12 were residue, all with the
  reason `no rule matched the leaf`. Residue was 11/2923 base elements,
  1/2289 patchwork element, and 0 for ggplot (26321), grid (1056) and
  heatmap (654). The 12 residue elements occur in six figures; the scorer
  prints their per-figure coverage.
- Every classified role matched the labels: 33231/33231 role-correct
  (100.0%). Kind accuracy was 32010/33231 (96.3%); kind-only differences do
  not count as role errors.
- Silent errors were 0. Flagged-but-correct was 0/33231 (0.0%). The three
  consistency checks passed 22708 data checks, 10522 non-data binding checks
  and 5106 text/label checks, with no failed checks.
- Coverage by engine was base 99.6%, ggplot 100.0%, grid 100.0%, heatmap
  100.0% and patchwork 99.96% (rounded to 100.0% by the scorer).

The first rules run exposed 2364 silent errors, mostly from extension output
being mistaken for reference or data marks. Four measured, committed rule
revisions narrowed these cues to drawing-system paths, state and frozen code;
the final rerun is the one above. The label-path check was then changed to
accept a label polygon/path when the engine rule identifies its text semantic,
which reduced flagged-but-correct from 6.1% to 0% without changing a role.

## Base legend evidence

The code-cue run classified all 10 labelled base legend elements (two of the
10 base figures) as guide keys/labels, never as data. A separate page-only
run, `bench/runs/2026-11-15-2253-classify-dev-ids.*`, ran the same ten base
figures with source context disabled: all 10 legend elements became explicit
residue, not data. This is the allowed fallback when the page alone cannot
separate a legend suffix from data marks.

## API and tree views

Roles are kept as the `roles` derived table and survive bundle round trips;
`gl_classify()`, `gl_role()`, `gl_unclassified()` and `gl_role_checks()` read
them. `gl_tree()` now exposes structure nodes (figure, panel, leaf, element)
and data nodes (table, series, row); `gl_map()` joins role nodes to checked
binding rows. `tests/testthat/test-hierarchy.R` covers both views and the
element mapping.

## Verification

- `NOT_CRAN=true Rscript -e "devtools::test()"` after the final code and tree
  changes: 14 test files, 1450 expectations, 0 failures, 0 skips.
- Targeted classification tests: 14 expectations, 0 failures.
- Targeted hierarchy tests: 9 expectations, 0 failures.

## Next

M1 closes with the derived role/binding tables and the residue list archived.
Held-out annotation and reporting remain for the next evaluation plan; no
held-out figure was used to tune these rules.
