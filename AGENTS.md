# Repository Guidelines

`gloss` is an R package that builds a semantic substrate for an R figure that has already been drawn, and lets agents and people add layered, verifiable semantics to it. Agents run on [`aisdk`](https://github.com/YuLab-SMU/aisdk); gloss **does not own an agent loop**. The core and the semantic store work without aisdk.

The current design is [`dev_docs/design.qmd`](dev_docs/design.qmd). Read it before changing anything structural.

## Project Structure & Module Organization

- `R/` — Package source:
  - core (`core-*.R`): substrate, data and row keys, anchors, records, verification, bundle, plugin registry;
  - capability interfaces (`identify.R`, `classify.R`, `hierarchy.R`, `semantics.R`, `operate.R`, `update.R`);
  - built-in plugins (`engine-*.R`, `layer-*.R`, `check-*.R`, `op-*.R`, `project-*.R`, `context-*.R`, `stage-*.R`);
  - agent running (`agent-*.R`).
- `inst/` — JSON Schemas, the browser runtime (`js/gloss-core.js` plus `js/ops/`), versioned prompts, engine knowledge.
- `man/` — Generated documentation. Do not edit `.Rd` files.
- `tests/testthat/` — Unit and integration tests. Entrypoint `tests/testthat.R`.
- `bench/` — Benchmark figures with code, and evaluation scripts. **Not part of the build.**
- `vignettes/` — Long-form user documentation (Quarto).
- `dev_docs/` — Design, research archive, ADRs (`decisions/`). **Not part of the build.**
- `dev_logs/` — Time-stamped session logs, append-only. **Not part of the build.**
- `plan/` — Phase plans with task-by-task tracking. **Not part of the build.**
- `idea/` — Exploration not yet promoted to a plan. **Not part of the build.**

Directories that don't exist yet are created when first needed.

## Build, Test, Document

- `Rscript -e "devtools::document()"` — regenerate `NAMESPACE` and `man/*.Rd`.
- `Rscript -e "devtools::load_all()"` — load the package for development.
- `Rscript -e "testthat::test_dir('tests/testthat')"` — run the test suite.
- `Rscript -e "testthat::test_file('tests/testthat/test-<name>.R')"` — run one test file.
- `quarto render dev_docs/design.qmd --to html` — render the design doc (rendered output is gitignored).
- `R CMD build .` then `R CMD check --as-cran gloss_*.tar.gz` — CRAN-style check.

## Development Workflow

Every change either lands as part of an active plan or as a tracked patch with a dev log entry.

```
  idea/  ──promote──▶  plan/  ──execute──▶  code + tests
                         │                      │
                         ▼                      ▼
                   (close plan)            dev_logs/  ──▶  NEWS.md (if user-facing)
                                                │
                                                ▼
                                 dev_docs/decisions/ (if architectural)
```

**When you start work:** find the active plan in `plan/`. If none covers it, draft one from `plan/_template.md`. If you're only exploring, write in `idea/` first.

**When you finish a unit of work:**

1. Update the plan checklist immediately, with the verification command when marking `[x]`.
2. Write `dev_logs/<YYYY-MM-DD>-<slug>.md`: what changed, why, what's next. One per session is enough.
3. If user-facing behavior changed, add a line to `NEWS.md`.
4. If an architectural decision was made or settled, write a numbered ADR in `dev_docs/decisions/`.

**Plan status:** `[ ]` not started, `[~]` in progress, `[x]` done, `[!]` blocked, `[-]` cancelled. Update immediately. Never silently rewrite a `[x]` task; append a dated Scope Change note. Closed plans move to `plan/done/` with a closing dev log.

## Design Principles

From the design doc; these are the owner's standing preferences.

1. Geometry comes only from the original graphics device. Nothing redraws the figure, and agents never write SVG.
2. What code can determine is never left to a model. Model output must be checkable.
3. Semantics live apart from the figure, anchored to elements, append-only.
4. Verification is a standing constraint, re-run whenever the substrate changes, not a single gate at export.
5. People and agents use the same API. A human note is just another record.
6. Least disclosure and least privilege for agents: read-only tools plus one `propose` entry point that validates on submit.
7. Infer instead of asking the user. Anything inferred (row keys, context, enabled operations) can be changed later without losing work.
8. No hard-coded policies for situational questions such as conflict resolution or which operations to enable. Judge from context and record the judgment with its rationale. Failed checks are the only hard constraint.
9. Plugin-first. The core holds only the substrate, anchors, records, verification and the registry. Built-ins register through the same `gl_register()` as third-party plugins; no special paths.

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

- testthat edition 3; files named `test-<feature>.R`; helpers in `tests/testthat/helper-*.R`.
- No network calls or paid API keys by default. Agent loops are tested with a scripted `aisdk::LanguageModelV1` subclass; real-model tests are gated with `Sys.getenv()` and `skip_if_not()`.
- Every extension point has contract tests through `gl_test_plugin()`, and built-in plugins use them too.

## Commit & PR

- Short imperative subjects: `feat(core): add anchor resolution`, `fix(engine-ggplot): handle empty panels`, `docs(adr): accept ADR-0004 ...`.
- Reference the plan task and link the dev log in the PR body.
- Run `devtools::document()` and the affected tests before a PR.

## Safety and CRAN Hygiene

- Model output is schema-validated data only: no HTML, CSS, URLs or JS. The runtime writes text with `textContent`, never `innerHTML`.
- Code restored from a bundle is never executed without an explicit `trust = TRUE`.
- ASCII-safe Rd, `tempdir()` defaults, no `<<-`, no `.GlobalEnv` writes, no `Rplots*.pdf` in the tarball, and the dev directories stay in `.Rbuildignore`.
