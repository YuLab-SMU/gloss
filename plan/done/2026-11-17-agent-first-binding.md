# 2026-11-17 — agent-first binding prototype

- **Research card clause:** the substrate with a verifiable proposal path, with
  package-specific binding rules frozen as a legacy comparison arm.
- **Starting suite:** `NOT_CRAN=true Rscript -e "devtools::test()"` → 22 files,
  1644 expectations, 0 failures and 0 skips (the M6 closing run on
  2026-11-17).
- **Scope:** bench-only prototype on the 84 development figures (55 v0 and 29
  tree). The held-out set and the public package API remain unchanged.
- **Riskiest assumption:** the closed proposal vocabulary can express a
  candidate while the independent device checker rejects row-order, target and
  ownership mutations. The first implementation slice tests this on a synthetic
  figure before material generation.

## Tasks

- [x] Add a versioned proposal DSL, strict schema validation, finite enumeration,
  replay and mutation checks in `bench/agent/`. `Rscript
  bench/agent/prototype-check.R` accepted a synthetic binding, rejected schema
  and target/order/filter mutations, and recorded a passing mutation test.
- [x] Add a persistent read-only material sandbox and the standardised
  `run_analysis` result contract. The smoke check returned separate stdout and
  stderr, exit status 1 for an R error and status 124 plus `sandbox_reset` for
  a timeout; the public hash stayed unchanged.
- [x] Write the v0/tree development material with public facts and an isolated
  oracle, content hashes and a run manifest. The pinned-container run covered
  all 84 development ids, wrote 83 materials and kept one explicit
  `replay_not_captured` row for `gallery-053`.
- [x] Add the four internal comparison arms and an archive writer. `legacy`
  must compare byte-for-byte with the frozen binding rows; `contract` uses the
  engine contract plus device geometry; `enumeration` and `agent` go through the
  same checker. The prototype archives are under `bench/runs/binding-v1/`.
- [x] Run the prototype on the complete development set, archive every outcome
  row, and record coverage, ambiguity, refusals, mutation outcomes and costs.
  The full development enumeration used a 500-candidate cap per figure; the
  agent arm used the dry sandbox driver because no model gateway token was
  available in this session.
- [x] Run host and pinned-container suites, update the design/NEWS only if
  user-facing behaviour changes, and close this plan with measured counts.

## Acceptance criteria

- No new package-specific rule enters `R/`.
- Every proposal outcome is one of `accepted`, `rejected`, `ambiguous`,
  `refused`, `none` or `operational_failure`, with category-level reasons.
- An accepted proposal has a unique checker result and a passing mutation test.
- Public material cannot read the hidden legacy binding, geometry oracle or
  answer files. The sandbox cannot modify public material or access the repo,
  host environment, network or secrets.
- No held-out material, label or model score is read by the prototype.

## Scope changes

The live model comparison and route decision are deferred until a fixed model
gateway is available. The held-out set remains untouched.

## Closing notes — 2026-11-18

- Host suite after the internal binding-mode test: 23 files, 1648 expectations,
  0 failures and 0 skips. The pinned-container suite: 23 files, 187 tests,
  1633 expectations, 0 failures, 0 errors, 5 aisdk-dependent skips and 0
  warnings.
- Material archive `2026-11-18-041130-binding-material-dev.csv` has 84 outcome
  rows, 83 `written` and one `replay_not_captured` for the known `gganim`
  build refusal.
- Legacy archive `2026-11-18-050943-summary.csv` has 83 measured legacy rows
  and one explicit material failure. Enumeration has 4 accepted figure-level
  results, 1 ambiguous result, 72 `none`, 6 refused and one material failure.
  Its proposal trace has 135 accepted candidate traces and every one has
  `mutation.status = passed`.
- Contract archive `2026-11-18-045836-summary.csv` measured 71 figures, refused
  12 and retained one material failure. The slowest contract replay was the
  192.4-second `gallery-029` run.
- Agent dry archive `2026-11-18-051450-summary.csv` covers all 84 figure rows.
  It has one accepted proposal with a passing mutation test, 82 `none` rows
  and one material failure. No live model call was made because the gateway
  token was absent. A real fixed-model run remains the next measurement.
