# 2026-11-09 — Development rules follow the evidence

- **Related plan:** [plan/2026-11-09-m0-substrate.md](../plan/2026-11-09-m0-substrate.md) (active; Task 9 open). No plan task: a process change, logged as a tracked patch.
- **Related ADRs:** none. The ADR template gains `Evidence` and `Revisit when`; no decision changed.
- **Worked on by:** Yonghe Xia, Claude

## What changed

With M0 in code, the owner asked for the repository's rules to stop treating the design doc and the milestone table as fixed, and to adjust from development progress, results and tests instead.

| File | Change |
|---|---|
| `AGENTS.md` | Ground truth is code, tests and measurements; the design doc is the current best explanation. The workflow is a loop (measure → slice → build and test → measure → record surprises → adjust). "Done" needs a command and an observed result. Surprises are routed to a plan scope change, a design note, an ADR or a risk. Milestones are a map. The nine principles are split into invariants (1, 2, 6, failed checks, refuse rather than degrade silently) and defaults (3, 4, 5, 7, 9, rest of 8) that evidence can override through the dev log and an ADR. Test rules: full suite at start and end of a session, no loosening to get green, fixtures are not coverage. The test command now matches what was actually run (`NOT_CRAN=true Rscript -e "devtools::test()"`); the old `testthat::test_dir()` line skipped the slow tests. |
| `plan/README.md` | A plan covers the next measurable slice, not a whole milestone; starts from a measured state; riskiest assumption first; four re-plan triggers. Active plans list fixed (it still said "none yet" while M0 was active). |
| `plan/_template.md` | New header fields: starting state (measured), assumptions to test, done when. Each task gets `Tests assumption` and `Result`; scope changes carry `Evidence` and `Effect`; closing notes compare end and starting state. |
| `dev_logs/README.md` | New. Format: what changed, measured, surprises (each routed), what's next. The M0 log is the worked example. |
| `dev_docs/decisions/README.md`, `_template.md` | ADRs rest on evidence and name an observable `Revisit when` condition; a decision without a measurement stays `Proposed`. |
| `dev_docs/design.qmd` | Status callout: the doc is not a spec, measurements win. Principles: invariants and defaults. Research card: revisable with dated evidence until predictions are committed for M5. Evaluation: the development set doubles as development feedback, re-measured at the end of each plan; held-out runs are archived and later changes reported. Plan: milestones are a map, with the two classes of rule that don't move. §已定事项 changes must cite their evidence. §与上一版的区别: dated entry. |

Afterwards the owner asked for commits as each unit lands rather than in large batches; `AGENTS.md` (*Commit & PR*, *End of a session*) now says so. The M0 work, uncommitted until then, went in as two commits on branch `feat/m0-substrate` (code and tests; records), and this change as a third.

Left unchanged on purpose: the evaluation integrity rules (development/held-out split, predictions before runs, two-rater labelling), the safety and CRAN rules, the append-only conventions for dev logs and completed plan tasks, ADR immutability.

## Measured

- Suite, before the change: `NOT_CRAN=true Rscript -e "devtools::test(reporter = 'summary')"`: 7 files, 268 expectations, 0 failed, 0 skipped (bundle 51, capture 67, codec 11, context 30, data 30, identify 37, plugin 42). Matches the M0 record. No R code changed, so the suite was not re-run after.
- `quarto render dev_docs/design.qmd --to html`: renders with no warnings; no unresolved cross-references (`?@sec-` does not occur in the output).
- Not run: `R CMD check` (no package files changed).

## Surprises

- `AGENTS.md` gave `Rscript -e "testthat::test_dir('tests/testthat')"` as the suite command, but every recorded run used `NOT_CRAN=true ... devtools::test()`; the first skips `skip_on_cran()` tests, so its counts would not match the plan. → fixed in `AGENTS.md`.
- `plan/README.md` listed no active plan although M0 has been active since this morning. → fixed.
- The first draft of the integrity rule said "the held-out set stays sealed until M5". The claims table in design §研究卡片 already assigns held-out measurements to M0 and M1 (capture coverage, rule-only classification), so the draft contradicted it. The rule is now "the held-out set only produces reported numbers; runs are archived; later changes are reported". → `AGENTS.md`, design §评测设计 and §实施计划.

## What's next

- Task 9 of the M0 plan is now also the first source of objective feedback: the capture has only met six hand-picked inputs. Sample the benchmark, split it, then run capture over the development set and report attempted, captured and refused counts with failure classes. Plan M1 from those numbers rather than from the milestone table.
- Re-read ADR-0001 to ADR-0005 when they are next touched and add `Evidence` and `Revisit when` where the evidence exists (ADR-0005 has the 2.65 MiB measurement; ADR-0002 has no anchor measurement yet and would name the M2 hit rate).
