# 2026-11-18 — agent-first binding prototype complete

- **Related plan:** [plan/done/2026-11-17-agent-first-binding.md](../plan/done/2026-11-17-agent-first-binding.md) (closed; live model route deferred)
- **Related ADRs:** none
- **Worked on by:** Codex

## What changed

- Added the bench-only closed proposal DSL, strict schema checks, finite
  enumeration, mutation tests and independent replay checker.
- Added a persistent read-only analysis sandbox with the standardised
  `run_analysis` result, separate stdout/stderr, exit status, timeout and
  scratch hashes.
- Added the complete development material writer. The public directory holds
  code, data, facts, tables, SVG and grob tree. The hidden oracle holds the
  captured figure, legacy rows and device geometry.
- Added internal `binding_mode` dispatch in the existing binder without adding
  a public argument or a package-specific rule.
- Added `legacy`, `contract`, `enumeration` and `agent` archive arms. The live
  agent gateway was not called because no token was present, so the agent
  archive uses the deterministic dry sandbox driver.

## Measured

- `Rscript bench/agent/prototype-check.R` → synthetic public/oracle isolation,
  schema rejection, mutation rejection and sandbox hash checks passed.
- Pinned material run `bench/runs/2026-11-18-041130-binding-material-dev.csv`
  → 84 development ids, 83 `written`, one explicit `replay_not_captured`
  (`gallery-053`, gganim build refusal). Total material writer time was 701.0
  seconds.
- Legacy/enumeration archive `bench/runs/binding-v1/2026-11-18-050943-summary.csv`
  → 168 arm rows. Legacy was measured for 83 figures and had one material
  failure. Enumeration produced 4 accepted figure-level results, 1 ambiguous,
  72 `none`, 6 refused and one material failure. The trace records 135
  accepted candidates, all with `mutation.status = passed`.
- Contract archive `bench/runs/binding-v1/2026-11-18-045836-summary.csv`
  → 71 measured, 12 refused and one material failure. Total replay time was
  278.7 seconds. The slowest figure was `gallery-029` at 192.4 seconds.
- Agent dry archive `bench/runs/binding-v1/2026-11-18-051450-summary.csv`
  → 84 rows, one accepted proposal, 82 `none` and one material failure. The
  accepted proposal's mutation test passed. The dry agent made 84 sandbox
  sessions and no model requests.
- Host suite `NOT_CRAN=true Rscript -e "devtools::test()"` → 23 files, 1648
  expectations, 0 failures and 0 skips.
- Pinned-container suite
  `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R` → 23
  files, 187 tests, 1633 expectations, 0 failures, 0 errors, 5 explicit
  aisdk-dependent skips and 0 warnings.
- `R CMD build --no-build-vignettes .` followed by `R CMD check --no-manual`
  → `Status: OK`.
- No held-out material, label or model score was read.

## Surprises

- `gallery-053` remains non-material because the captured object is `gganim`
  and its build is intentionally refused. This is an explicit outcome row,
  not a silently dropped figure. → plan closing note and material run archive.
- Large `sf` tables retain geometry columns through the `sf` subsetting method
  unless coerced to a plain data frame. Geometry columns are now excluded from
  public CSV facts. → `binding-material.R` and regenerated patchwork materials.
- The first uncached checker replay repeatedly parsed large tables and made one
  56k-row figure take minutes. Shared checker placement caches reduced the
  full enumeration archive to 118.6 seconds. → `binding-checker.R` and plan
  closing note.
- No fixed model gateway token was available. The agent route is therefore
  operationally exercised in dry mode, while live model coverage and route
  selection remain open. → plan scope change.

## What's next

Provide a fixed model gateway, register its prediction budget before use, and
rerun only the agent arm on the same development material. Use the resulting
accepted/ambiguous/refused and cost rows to decide whether the checker should
be promoted to the next internal stage. Keep the held-out set closed until
that decision is recorded.
