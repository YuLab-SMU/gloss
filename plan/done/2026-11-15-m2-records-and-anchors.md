# M2 records and anchors

> Status: closed 2026-11-15/16. Owner: Codex.

**Goal:** Complete the record and anchor core described by ADR-0002: append-only layer logs, safe selector resolution, explicit invalidation, and rebasing after controlled figure edits.

**Why now:** The semantic pilot and prepared visual artifact established the proposal boundary but deliberately left persistence and update propagation out of scope. The owner routed the next slice to M2 with `/goal 完成M2`.

**Research-card clause:** The design claim that semantic work remains attached to the right element after a figure update. This slice measures the mechanism on a controlled fixture; benchmark coverage and the registered threshold remain for M5.

**Starting state:** The visual pilot ended with 17 test files, 1477 expectations, 0 failures and 0 skips. M0/M1 derived tables, the semantic `trend` check, and bundle format 0.2.0 were present; no figure carried records or layer logs.

**Architecture:** Derived roles and bindings remain read-only tables. Records are JSON-like values in named layer plugins. Every write appends an event (`add`, `revise`, `retract`, `verify`, `rebase` or `rewrite`) to `layers/<name>.jsonl`; materialised current state is rebuilt from the log. Anchors contain structured selectors and never evaluate R code. A more stable selector that disappears makes a weaker fallback `ambiguous`, so a record is never silently attached to a new target.

## Progress tracking

- [x] Task 1: Register the eight core layers and implement record schema, provenance, append-only events and queries.
- [x] Task 2: Implement data-key, predicate, structure, role, region and element-id selectors, stable structural ids and conservative fallback.
- [x] Task 3: Implement verification, rejected claims, revision/retraction, conflict listing/resolution and dependency invalidation.
- [x] Task 4: Integrate layer JSONL files into directory and single-file bundles; add `gl_rebase()`, `gl_status()`, `gl_diff()` and `gl_repair()`.
- [x] Task 5: Measure controlled updates, update design/docs, and run the host suite.

## Task 1: Record and layer core

**Status:** `[x]`

**Files:** `R/core-record.R`, `R/core-plugin.R`, `R/zzz.R`, `R/propose.R`, `R/classify.R`, `tests/testthat/test-records.R`.

**Result:** Eight built-in `layer` plugins register through `gl_register()`. `gl_record()` and the record form of `gl_propose()` validate bodies and anchors, preserve provenance, and materialise current records from an append-only event log. `gl_records()` exposes list columns and the original records attribute. Failed closed checks are retained as `rejected` and cannot become verified facts.

**Verification:** `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-records.R')"` passed 20 expectations before the conservative fallback assertion was added; the final full-suite count below includes it.

## Task 2: Anchors and stable targets

**Status:** `[x]`

**Files:** `R/core-anchor.R`, `R/core-substrate.R`, `R/core-bundle.R`.

**Result:** Selectors resolve to `unique`, `ambiguous` or `missing` with candidates and attempts. Stable ids depend on leaf identity, primitive tag and ordinal, so repeated captures with or without bindings agree. When bindings are present, the resolution also stores a data target; a row changing under an element id is invalidated during rebase. Data-key and predicate selectors use stored table values and never evaluate arbitrary expressions.

## Task 3: Status, history and conflicts

**Status:** `[x]`

**Files:** `R/core-record.R`, `R/core-update.R`, `R/classify.R`.

**Result:** `gl_verify()` appends verification events; `gl_revise()` supersedes without erasing; `gl_retract()` appends a retraction; `gl_conflicts()` reports different bodies at one anchor; `gl_resolve()` appends a rationale-bearing resolution record. `gl_rebase()` appends per-record rebase events, marks missing/ambiguous targets invalid and propagates invalidity through `depends_on`. `gl_repair()` returns only the invalid queue.

## Task 4: Bundle integration

**Status:** `[x]`

**Files:** `R/core-bundle.R`, `R/core-record.R`, `R/utils.R`.

**Result:** Bundle format is 0.3.0 (same major reader compatibility). Every layer has a JSONL file in directory bundles and is packed into single-file HTML/SVG bundles. Logs, plugin metadata, record status and check evidence survive round trips byte-for-byte at the materialised R level.

## Task 5: Controlled update measurement

**Status:** `[x]`

**Verification:** `Rscript bench/m2/rebase.R` on the fixed mtcars point fixture produced:

| edit | automatic hits | records | hit rate |
|---|---:|---:|---:|
| title | 3 | 4 | 75% |
| colour | 4 | 4 | 100% |
| data subset | 2 | 4 | 50% |
| add layer | 4 | 4 | 100% |
| delete layer | 4 | 4 | 100% |

The two data-subset misses and the title-region miss were explicit `invalid` records; no wrong target was accepted. The raw summary is archived at `bench/runs/2026-11-15-m2-rebase/`.

**Host suite:** `NOT_CRAN=true Rscript -e "devtools::test()"` → 18 files, 1506 expectations, 0 failures, 0 skips (final run after the docs and fallback test).

`R CMD build --no-build-vignettes --no-manual .` and `R CMD check --no-manual --no-vignettes gloss_0.0.0.9000.tar.gz` also completed with `Status: OK`.

## Scope changes

- 2026-11-15 — The prepared visual pilot was closed with its comparative model run deferred; the owner routed the next slice to M2 records and anchors. The prepared artifact remains available for a later agent evaluation.
- 2026-11-15 — M2's “four update cases” criterion is reported as a controlled mechanism fixture, including both add and delete layer edits. A benchmark-wide threshold was not invented; it remains an M5 evaluation question.

## Closing notes

M2 is complete as a package mechanism: records are persistent, append-only and queryable; anchors resolve safely; checks and conflicts remain visible; bundle round trips preserve history; and rebase marks lost or changed targets instead of silently moving them. The controlled fixture is evidence of the mechanism, not a coverage claim for the benchmark population.
