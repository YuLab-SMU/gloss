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
- [ ] Write the v0/tree development material with public facts and an isolated
  oracle, content hashes and a run manifest.
- [ ] Add the four internal comparison arms and an archive writer. `legacy`
  must compare byte-for-byte with the frozen binding rows; `contract` uses the
  engine contract plus device geometry; `enumeration` and `agent` go through the
  same checker.
- [ ] Run the prototype on the complete development set, archive every outcome
  row, and record coverage, ambiguity, refusals, mutation outcomes and costs.
- [ ] Run host and pinned-container suites, update the design/NEWS only if
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

None yet. Evidence from the synthetic fixture and the first development run is
recorded here before later tasks are expanded.
