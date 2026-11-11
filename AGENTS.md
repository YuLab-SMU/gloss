# Repository Guidelines

`gloss` is an R package that builds a semantic substrate for an R figure that has already been drawn, and lets agents and people add layered, verifiable semantics to it. Agents run on [`aisdk`](https://github.com/YuLab-SMU/aisdk); gloss **does not own an agent loop**. The core and the semantic store work without aisdk.

**Where the truth is.** The code, the tests and measurements on real figures say what gloss does. [`dev_docs/design.qmd`](dev_docs/design.qmd) is the current best explanation and the map of what comes next; it can lag behind the code or be wrong. Before a structural change, read the design section it touches, the active plan in `plan/` and the latest dev log in `dev_logs/`. When they disagree with what you measure, the measurement wins: correct the doc or the plan with a dated note. Never bend a test or a number to match the doc.

## Project Structure & Module Organization

- `R/` — Package source:
  - core (`core-*.R`): substrate, data and row keys, anchors, records, verification, bundle, plugin registry;
  - capability interfaces (`identify.R`, `classify.R`, `hierarchy.R`, `semantics.R`, `operate.R`, `update.R`);
  - built-in plugins (`engine-*.R`, `layer-*.R`, `check-*.R`, `op-*.R`, `project-*.R`, `context-*.R`, `stage-*.R`);
  - agent running (`agent-*.R`).
- `inst/` — JSON Schemas, the browser runtime (`js/gloss-core.js` plus `js/ops/`), versioned prompts, engine knowledge.
- `man/` — Generated documentation. Do not edit `.Rd` files.
- `tests/testthat/` — Unit and integration tests. Entrypoint `tests/testthat.R`.
- `bench/` — Benchmark figures with code (development and held-out sets), evaluation scripts and run archives. **Not part of the build.**
- `vignettes/` — Long-form user documentation (Quarto).
- `dev_docs/` — Design, research archive, ADRs (`decisions/`). **Not part of the build.**
- `dev_logs/` — Time-stamped session logs, append-only: what was measured, what surprised us, where each surprise went. **Not part of the build.**
- `plan/` — Plans for the next slice of work that can be finished and measured, with task-by-task tracking. **Not part of the build.**
- `idea/` — Exploration not yet promoted to a plan. **Not part of the build.**

Directories that don't exist yet are created when first needed.

## Build, Test, Document

- `Rscript -e "devtools::document()"` — regenerate `NAMESPACE` and `man/*.Rd`.
- `Rscript -e "devtools::load_all()"` — load the package for development.
- `NOT_CRAN=true Rscript -e "devtools::test()"` — run the full suite. Without `NOT_CRAN` the slow tests (for example the 10^5-point size check) are skipped, so always set it when you record counts.
- `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-<name>.R')"` — run one test file.
- `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R` — run the full suite in the bench container (Linux, slow tests on). Required for code that reads device output; see *Tests*.
- `quarto render dev_docs/design.qmd --to html` — render the design doc (rendered output is gitignored).
- `R CMD build --no-build-vignettes .` then `R CMD check --no-manual gloss_*.tar.gz` — routine check; use `--as-cran` before a release.

## Development Workflow

Development runs on feedback. Plans and the design doc say what we expect; tests and measurements say what happened, and the next step comes from the second.

```
  measure ──▶ pick the next slice ──▶ build + test ──▶ measure again
     ▲         (riskiest assumption      (a test or a        │
     │          first)                    number that         │
     │                                    could fail)         ▼
     └── adjust plan / design / ADR ◀── record what surprised us (dev log)
```

**Start of a session.** Run the full suite and note the counts (files, tests, expectations, failures, skips). Read the open tasks of the active plan and the *Surprises* and *What's next* of the latest dev log. If the latest evidence contradicts the plan, revise the plan before writing code.

**Work in slices that end in something observable:** a test that could have failed, or a number measured on figures that were not picked to pass (the bench development set, once it exists). Do first the slice whose result could change the most of the plan.

**Done means measured.** Mark `[x]` only with the command and what it showed: counts, numbers, and the figure set it ran on. "Tests pass" without numbers is not a result. A result on hand-built fixtures is reported as such; it shows a mechanism works, not how much it covers.

**When the evidence disagrees with the plan or the design,** write it under *Surprises* in the dev log the same session, then route it:

- it changes what the remaining tasks should be → a `Scope change` in the plan, with the evidence;
- it changes a design claim, a number or a milestone → a dated note in the design doc, in that section and in §与上一版的区别;
- it settles or overturns something expensive to reverse → an ADR (a new one supersedes; the old one changes only its status line);
- it is not understood yet → §风险与未决问题 in the design doc, or a note in `idea/`.

Don't weaken a test, widen a tolerance, or drop a figure from a set to make a result match the plan. If an expectation was wrong, say why in the dev log, with the evidence, and then change it.

**Milestones are a map, not a contract.** M0–M5 and their completion criteria in design §实施计划 are the current best guess. When a plan closes, plan the next slice from what was measured: milestones may be split, merged or reordered, and criteria rewritten, with the evidence recorded. Two things do not move with progress:

- the invariants under *Design Principles* and the rules under *Safety and CRAN Hygiene*;
- evaluation integrity: rules, prompts and thresholds are tuned only on the development set; the held-out set only produces reported numbers, every run on it is archived in `bench/`, and any change made after looking at its results is reported as such; predictions are committed before the runs they predict (design §评测设计). These are what make the measurements worth trusting.

**Small changes** (a bug fix, a refactor that keeps behavior, a doc fix) need no plan. A bug fix starts with a test that fails before the fix. Note it in the session's dev log.

**Larger changes** belong to the active plan or a new one drafted from `plan/_template.md`. A plan covers the next slice that can be finished and measured, not a whole milestone in detail. If you are only exploring, write in `idea/`.

**End of a session.**

1. Run the full suite again and record the counts before → after.
2. Update the plan: status, verification command and observed result for each finished task; scope changes with their evidence.
3. Write or extend `dev_logs/<YYYY-MM-DD>-<slug>.md` in the format of [`dev_logs/README.md`](dev_logs/README.md). One per session is enough.
4. User-facing behavior changed → a line in `NEWS.md`. An architectural decision made or settled → an ADR in `dev_docs/decisions/`.
5. Nothing is left uncommitted; work committed during the session as each unit landed (see *Commit & PR*).

**Plan status:** `[ ]` not started, `[~]` in progress, `[x]` done, `[!]` blocked, `[-]` cancelled. Update when a task lands. Never silently rewrite a `[x]` task; append a dated Scope change. Closed plans move to `plan/done/` with a closing dev log.

## Design Principles

From the design doc; these are the owner's standing preferences. They are the starting position, not a substitute for evidence.

1. Geometry comes only from the original graphics device. Nothing redraws the figure, and agents never write SVG.
2. What code can determine is never left to a model. Model output must be checkable.
3. Semantics live apart from the figure, anchored to elements, append-only.
4. Verification is a standing constraint, re-run whenever the substrate changes, not a single gate at export.
5. People and agents use the same API. A human note is just another record.
6. Least disclosure and least privilege for agents: read-only tools plus one `propose` entry point that validates on submit.
7. Infer instead of asking the user. Anything inferred (row keys, context, enabled operations) can be changed later without losing work.
8. No hard-coded policies for situational questions such as conflict resolution or which operations to enable. Judge from context and record the judgment with its rationale. Failed checks are the only hard constraint.
9. Plugin-first. The core holds only the substrate, anchors, records, verification and the registry. Built-ins register through the same `gl_register()` as third-party plugins; no special paths.

**Invariants.** Principles 1, 2 and 6, and the last sentence of 8 (failed checks are hard constraints), hold whatever the progress. So does one rule from design §元素归属由图形设备给出: when gloss cannot attribute or bind something correctly it refuses and says why (a leaf whose counts don't match is not bindable; a masked figure aborts); it never degrades silently. Changing an invariant takes an ADR with evidence and the owner's agreement.

**Defaults.** Principles 3, 4, 5, 7, 9 and the rest of 8 are how we work unless the evidence says otherwise. When a measurement shows one costs more than it gives in a concrete case (speed, a class of figures it cannot handle, an API the tests show is awkward), record the evidence in the dev log and raise it; a lasting exception needs an ADR. Don't quietly work around a principle, and don't keep following one against the evidence without saying so.

## Prior Art

ggiraph, gridSVG, maidr, plotly, canvasXpress and the other surveyed tools are methodological reference only: no dependency, and no copied code. They may appear as comparison baselines under `bench/` or `dev_docs/`, never in `DESCRIPTION`.

## Coding Style

- Standard R style, 2-space indentation, `snake_case`; `CamelCase` only for R6 classes.
- Public API: `gloss()` builds a figure; every other exported function is `gl_*`. Internal helpers carry no prefix.
- Document exported functions with roxygen2.
- Returns over side effects: primitives return structured objects, never `print()` or `plot()`.
- Anything that varies by engine, format, operation or scenario is a plugin. Don't add special cases to the core.
- Prefer pure functions; use R6 only where identity or lifecycle is genuinely needed.

## Tests

Tests are the main feedback signal; measurements on the bench development set are the second.

- Run the full suite (with `NOT_CRAN=true`) at the start and end of a session and record the counts in the dev log.
- Don't delete, skip or loosen a test to get a green run. A skip for a known defect carries a reason and points to the plan task or risk that tracks it. Environment skips (`skip_if_no()` for a Suggests package, `skip_on_cran()`) are fine, but a run with skips is recorded with its skip count, not as a clean run.
- Code that reads what a graphics device wrote (the SVG svglite writes to a file or a string, a recorded plot, the display list) is done only when the full suite has also passed in the bench container: `GLOSS_BENCH_OFFLINE=true bench/docker/run.sh Rscript bench/R/suite.R`. Record the container's counts beside the host's. The host is macOS and cannot stand in for Linux here: on 2026-11-11 a file connection kept open returned stale bytes on Linux only, and every base capture was refused there while the host suite passed (`254bd73`). Other changes need the host suite only.
- A fixture test shows that a mechanism works on that fixture. Claims about coverage come from the bench development set; reported numbers come from the held-out set (design §评测设计).
- testthat edition 3; files named `test-<feature>.R`; helpers in `tests/testthat/helper-*.R`.
- No network calls or paid API keys by default. Agent loops are tested with a scripted `aisdk::LanguageModelV1` subclass; real-model tests are gated with `Sys.getenv()` and `skip_if_not()`.
- Every extension point has contract tests through `gl_test_plugin()`, and built-in plugins use them too.

## Commit & PR

- Commit each unit of work as soon as it is verified: a plan task or sub-step, a fix with its test, a doc change. Don't let changes pile up in the working tree. One purpose per commit, and the suite passes at every commit that touches `R/` or `tests/`; the commit message carries the counts or numbers that verified it.
- Short imperative subjects: `feat(core): add anchor resolution`, `fix(engine-ggplot): handle empty panels`, `docs(adr): accept ADR-0004 ...`.
- Reference the plan task and link the dev log in the PR body, with the suite counts and any bench numbers that changed.
- Run `devtools::document()` and the full suite before a PR.

## Safety and CRAN Hygiene

- Model output is schema-validated data only: no HTML, CSS, URLs or JS. The runtime writes text with `textContent`, never `innerHTML`.
- Code restored from a bundle is never executed without an explicit `trust = TRUE`.
- ASCII-safe Rd, `tempdir()` defaults, no `<<-`, no `.GlobalEnv` writes, no `Rplots*.pdf` in the tarball, and the dev directories stay in `.Rbuildignore`.
