# M3 semantic verification, operations and projections

> Status: active.
> Date opened: 2026-11-16. Owner: Codex.

**Goal:** Deliver the first model-free semantic product loop: a claim is accepted only after schema, anchor and deterministic check validation; approved operations can be materialised without changing the captured geometry; and the same bundle can be opened as an interactive HTML page or exported as accessible text and annotations.

**Why now:** M2 closed the append-only record, anchor and rebase mechanism, so there is now somewhere for verified semantic work to persist. The current package has one deterministic check (`trend`) and static HTML/SVG bundle projections, but no operation plugin, `gl_apply()`, browser runtime, overlay materialisation, ARIA/text projection or Web Annotation exporter. The M2 closing measurement is a controlled mechanism result (title 75%, colour 100%, data subset 50%, add/delete layer 100%), not a benchmark coverage claim. The semantic pilot is the narrowest next research path: five frozen proposals produced one verified, one failed, one partial, one refused and one uncheckable result, with three owner-audited cases. See [the M2 plan](done/2026-11-15-m2-records-and-anchors.md), [the M2 log](../dev_logs/2026-11-15-m2-records-and-anchors.md), [the semantic pilot log](../dev_logs/2026-11-15-semantic-pilot.md), and design §实施计划.

**Research-card clause:** Primary evidence for “声明核验拦下错误靠的是检查，不是少答” (design §研究卡片; currently one closed-check pilot, no benchmark-wide number). Secondary infrastructure for the interaction and projection parts of the same claim: the plan must show that an accepted semantic record can drive an operation and an accessible projection without redrawing the substrate. It does not claim model accuracy, human-label agreement or the final A/B comparison.

**Starting state (measured):**

- `NOT_CRAN=true Rscript -e "devtools::test()"` on 2026-11-16: 18 test files, 1506 passed, 0 failures, 0 skips (277.1 s).
- The semantic pilot's built mtcars claim has five of six runnable group trends negative and one automatic 4-cylinder group at slope `+3.067891`; the frozen offline proposals were `verified`, `failed`, `partial`, `refused` and `uncheckable` once each. No real-model or inter-rater number exists.
- M2's controlled `Rscript bench/m2/rebase.R` fixture: title 3/4, colour 4/4, data subset 2/4, add layer 4/4, delete layer 4/4 automatic anchor hits. Misses were explicit invalid records; no wrong target was accepted.
- `R/semantic-checks.R` contains `gl_check()` and the `trend` plugin. `R/project-html.R` and `R/project-svg.R` emit a scene plus embedded bundle, but there is no `inst/js/` runtime, no registered operation plugin and no `gl_apply()` implementation.

**Assumptions to test:**

1. The existing table-oriented check API can express the closed claim cases needed for v0 without allowing arbitrary R expressions. Task 1 tests this with injected true, false, mixed and unrunnable claims. If an `exists` check needs figure/anchor context rather than a table, split it into a figure-aware check contract and record the scope change before implementing it.
2. The M2 record status model is sufficient to keep `verified`, `partial`, `refused`, `rejected`, `speculative` and `invalid` meanings distinct in every projection. Task 2 tests that rejected and speculative records never appear as verified facts.
3. A JSON-like operation specification can be shared by R and JavaScript while preserving the original scene. Task 3 tests schema validation, anchor resolution, overlay geometry and scene hashes before adding a browser.
4. A small event-delegated browser kernel plus four operation plugins is enough for a usable v0 and can stay below 15 KB compressed. Task 4 tests the runtime in a real browser when available and falls back to syntax/static contract tests when it is not.
5. ARIA, text and Web Annotation projections can be derived from the same records without leaking free-form HTML, CSS or JavaScript. Task 5 tests output structure, provenance and omission/labeling of non-factual records.

**Architecture:** Keep the substrate, derived tables, anchors and append-only layer logs unchanged as the source of truth. Add closed check plugins and explicit record-body schemas in R; add an operation registry with a serializable operation spec, an R materializer that writes only a separate overlay group, and a browser kernel under `inst/js/` with one file per browser operation. Extend the projection registry so HTML embeds only the runtime and operation plugins it uses; keep the captured SVG scene byte-for-byte intact. Add exporter plugins for an ARIA tree, a text description and one-way W3C Web Annotation JSON. All model or human text remains data validated by schemas and is inserted with `textContent`; no evaluator or runtime executes it.

**Out of scope:**

- M4 agent loops, prompts, aisdk orchestration, caching or real-model runs.
- M5 held-out figures, sample-size decisions, A/B or 2×2 accuracy claims, and broad human annotation.
- New engine/binding rules, improvements to base/heatmap binding, or changing the M2 conservative rebase policy.
- SVG redrawing, arbitrary user JavaScript, WebMCP, operation editing in the browser, `focus`/`link`/`raise` as browser interactions before the v0 four are measured.
- Importing Web Annotation or treating speculative/open-world text as a verified fact.

**Tech stack:** R and testthat edition 3; existing `jsonlite`, `xml2`, `digest`, `cli`, `svglite` and `withr`; plain JavaScript with no runtime dependency; optional Chromium/Playwright or the existing browser automation only for the headless smoke test. No network calls or paid API keys.

**Done when:**

- The frozen semantic fixture injects true, false, mixed and unrunnable closed claims, and every false claim is rejected or remains non-factual; every true fixture claim is `verified`; evidence and reasons survive a bundle round trip. The result is archived under `bench/runs/2026-11-16-m3-*`.
- A registered operation spec rejects unknown verbs, invalid parameters, unresolved anchors and overlays without a verified basis. R materialisation leaves the original scene hash unchanged and places all generated geometry in one `gloss-overlay` group. The controlled fixture exercises every R-side v0 verb.
- An HTML projection opens without external assets, registers only the operations it uses, and passes a browser smoke test for `select`, `style`, `show`/`hide` and `tooltip`. Runtime syntax/static checks pass when a browser is unavailable, and the compressed kernel plus v0 operation files are under 15 KB.
- ARIA, text and Web Annotation exports have deterministic fixture snapshots, valid target/provenance mappings and no unescaped HTML/JS. Rejected claims are omitted from factual summaries; partial and speculative records are explicitly labeled.
- The host suite remains at 0 failures and 0 skips, with the final command and counts recorded in the closing log. No held-out result is used to tune a rule or threshold.

---

## Progress tracking

**Status legend**
- `[ ]` Not started
- `[~]` In progress
- `[x]` Completed
- `[!]` Blocked
- `[-]` Cancelled

**Plan maintenance rules**
- Update when a task lands, in the same commit as the code.
- When marking `[x]`, record the command and observed result (counts, numbers, fixture or figure set).
- If a result contradicts an assumption, append a dated Scope change and update only open tasks. Never edit a completed task silently.

**Current state** _(2026-11-16)_
- Suite: 18 files, 1506 passed, 0 failed, 0 skipped (`NOT_CRAN=true Rscript -e "devtools::test()"`).
- Key numbers: one `trend` check; semantic pilot statuses 1/1/1/1/1 across five frozen proposals; M2 controlled rebase hits 75%, 100%, 50%, 100%, 100% for title, colour, subset, add-layer and delete-layer edits.
- Package gap: no `inst/js/` runtime, operation registration, `gl_apply()` or package-level ARIA/text/Web Annotation exporter.

**Overall progress**
- [ ] Task 1: Close the deterministic check vocabulary and claim verification contract.
- [ ] Task 2: Make semantic layer schemas and projection eligibility explicit.
- [ ] Task 3: Implement R-side operations, context selection and overlay materialisation.
- [ ] Task 4: Implement the HTML browser kernel and the four v0 browser operations.
- [ ] Task 5: Add ARIA, text and Web Annotation exporters.
- [ ] Task 6: Run the integrated M3 fixture, archive measurements and close the plan. _(Stub; detail after Tasks 1–5.)_

### Task 1: Close the deterministic check vocabulary

**Status:** `[ ]`

**Tests assumption:** Assumption 1; the table-oriented check boundary is expressive enough and remains closed.

**Files**
- Create or modify: `R/semantic-checks.R`, check plugin files if the registry becomes clearer by one file per primitive.
- Test: `tests/testthat/test-semantic-checks.R`, a frozen fixture under `bench/semantic/` and its archived result under `bench/runs/`.

**Intent**
- Keep `trend` as the reference implementation and add the smallest closed v0 vocabulary: `count`, `value`, `compare` and `range`. Test `exists` only after deciding whether it needs table or figure context; do not smuggle anchor lookup into a table-only plugin.
- Normalize all check results to evidence-bearing `verified`, `failed`, `partial` or `refused`, with stable reasons and group/row evidence. No plugin evaluates an R expression supplied in a proposal.

**Checklist**
- [ ] Define schemas, missing-data behavior, tolerance rules and evidence columns for the four table-local primitives.
- [ ] Add contract tests for all-pass, all-fail, mixed, missing-column, empty and non-runnable cases, plus a shuffled-row negative control.
- [ ] Re-run the five frozen semantic pilot proposals through the expanded registry and archive CSV/JSON results without changing the old pilot files.
- [ ] Decide and record the `exists` boundary as a Scope change or an ADR if the evidence requires a new figure-aware check API.

**Verification**
- `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-semantic-checks.R')"`.
- `Rscript bench/semantic/m3_checks.R` (to be added): every injected false claim is `failed` or non-factual, every true fixture claim is `verified`, and no check runs arbitrary code.

**Result** _(filled in when done)_
- Command, result, lines added under `R/` and `tests/`, fixture runs and surprises.

### Task 2: Make semantic layer schemas and eligibility explicit

**Status:** `[ ]`

**Tests assumption:** Assumption 2; record statuses and provenance can support safe projections without changing M2 history.

**Files**
- Modify: `R/core-record.R`, `R/core-plugin.R` or a new semantic-layer plugin file, `R/semantic-checks.R` as needed.
- Test: `tests/testthat/test-records.R`, a new `tests/testthat/test-semantic-records.R`.

**Intent**
- Replace the eight built-in layer bodies' `any` schemas with minimal JSON-like v0 schemas for meaning, relation, claim, narrative, behavior and overlay; keep structure and binding compatible with the derived-table path. Encode provenance (`direct`, `derived`, `speculative`) and the rule that only checked direct/derived claims can be factual.
- Make `gl_verify()` re-run all attached checks after a substrate/table change and preserve the evidence-bearing status transition in the append-only log. A failed check remains `rejected`; a mixed or refused check cannot become `verified` by projection.

**Checklist**
- [ ] Define field vocabularies and size/character limits; reject unknown fields and unsupported HTML/JS-like payloads.
- [ ] Add record fixtures for verified, rejected, partial, refused, speculative and invalid states, including dependencies and rebase invalidation.
- [ ] Add an eligibility helper used by every exporter and operation validator; test that rejected claims are never factual and speculative claims stay labeled.
- [ ] Preserve byte/materialized equality through directory and single-file bundle round trips.

**Verification**
- Targeted semantic record tests pass with explicit status assertions and unchanged M2 tests.
- A round-trip fixture has identical `gl_records()`, check evidence and append-only logs before and after `gl_write()`/`gl_read()`.

**Result** _(filled in when done)_
- Command, result, lines added under `R/` and `tests/`, fixture runs and surprises.

### Task 3: Implement R-side operations and overlay materialisation

**Status:** `[ ]`

**Tests assumption:** Assumption 3; one serializable operation vocabulary works in R and preserves the substrate.

**Files**
- Create: operation plugin files under `R/` (for example `op-select.R`, `op-style.R`, `op-visibility.R`, `op-overlay.R`, `op-tooltip.R`) and the public `gl_apply()` implementation.
- Modify: `R/core-plugin.R`, `R/core-bundle.R`, projection files and `NAMESPACE`/generated documentation.
- Test: a new `tests/testthat/test-operations.R` and fixture helpers.

**Intent**
- Register the v0 operation vocabulary through `gl_register("operation", ...)`. Validate verbs, parameters, anchors, relation types and evidence references before materialisation. Keep operations as records or projection inputs; never mutate the captured substrate.
- Implement all R-side v0 verbs (`select`, `style`, `show`, `hide`, `raise`, `lower`, `focus`, `link`, `unlink`, `overlay`, `tooltip`) as pure materialization steps. Generated annotation geometry is derived from element boxes/panels and lives in a separate `<g class="gloss-overlay">` group.
- Choose enabled operations from context and existing layers with deterministic defaults, while allowing an explicit caller override to be recorded.

**Checklist**
- [ ] Define the shared operation JSON schema and plugin contract tests.
- [ ] Implement class/attribute-based style and visibility changes, preserving scene geometry and using `textContent` for labels.
- [ ] Implement overlay box/leader/bracket/region geometry from anchors; require a verified claim for factual overlays and label partial/speculative evidence.
- [ ] Add scene-hash, invalid-anchor, invalid-verb and operation round-trip tests.

**Verification**
- `gl_test_plugin("operation", ...)` passes for every built-in operation.
- On the controlled mtcars fixture, every R-side v0 verb either materialises or refuses with a reason; the original scene hash is unchanged and only the overlay group is new.

**Result** _(filled in when done)_
- Command, result, lines added under `R/` and `tests/`, fixture runs and surprises.

### Task 4: Implement the HTML browser kernel and four v0 operations

**Status:** `[ ]`

**Tests assumption:** Assumption 4; a small dependency-free runtime is sufficient for the first interaction path.

**Files**
- Create: `inst/js/gloss-core.js`, `inst/js/ops/select.js`, `inst/js/ops/style.js`, `inst/js/ops/visibility.js`, `inst/js/ops/tooltip.js`.
- Modify: `R/project-html.R`, operation/projection registry code and HTML projection tests.
- Test: `tests/testthat/test-runtime.R`, Node syntax checks and an optional headless browser smoke script.

**Intent**
- Add one event-delegated kernel that reads serialized operation metadata, resolves `data-gloss-*` targets, registers only bundled plugins and toggles classes/attributes. Decorative overlays use `pointer-events: none`; no runtime redraws geometry or executes model text.
- Ship only `select`, `style` (highlight/fade), `show`/`hide` and `tooltip` in the browser v0, plus keyboard focus/navigation and default legend filtering where the substrate exposes the target.

**Checklist**
- [ ] Embed runtime and operation manifest in HTML without external network dependencies; keep plain SVG readable without executing JavaScript.
- [ ] Add deterministic DOM fixtures for click/hover/keyboard behavior and target-missing behavior.
- [ ] Run `node --check` on each script and a browser smoke test when Chromium is available; otherwise record the environment skip and keep static contracts mandatory.
- [ ] Measure compressed runtime size and enforce the 15 KB design ceiling.

**Verification**
- HTML fixture opens, all four operations change only classes/visibility/tooltip text, and an unresolved target produces a visible no-op/error state rather than a guessed target.
- Runtime files pass syntax checks; compressed kernel plus plugins are `< 15 KB`.

**Result** _(filled in when done)_
- Command, result, byte size, browser availability and surprises.

### Task 5: Add ARIA, text and Web Annotation exporters

**Status:** `[ ]`

**Tests assumption:** Assumption 5; projections can share one eligibility and provenance mapping.

**Files**
- Create: projection/exporter plugin files under `R/` and deterministic templates under `inst/` if needed.
- Modify: projection registry, `R/core-bundle.R`, `NAMESPACE`/generated documentation.
- Test: `tests/testthat/test-projections.R` with snapshot fixtures for ARIA, text and Web Annotation JSON.

**Intent**
- Produce a WAI-ARIA graphics tree with stable ids, descriptions and keyboard order; a plain-text reading of verified claims, exceptions and speculative notes; and a one-way W3C Web Annotation JSON mapping record → Annotation, anchor → Target/Selector, provenance → creator/generator/created.
- Keep exporter output deterministic and explicitly mark partial, speculative, rejected and invalid records. Do not import annotations or force the internal record schema to mirror the external model.

**Checklist**
- [ ] Decide and document the exporter call shape (`gl_export()` or projection formats) before implementing files; add a registry contract rather than hard-coded format branches.
- [ ] Generate stable ARIA relationships and text descriptions with no duplicate ids or factual rendering of rejected claims.
- [ ] Generate Web Annotation JSON with selectors and provenance, validate required fields, and test missing-plugin/missing-data cases.
- [ ] Add output snapshots and a safety test that rejects HTML/JS payloads and uses text insertion only.

**Verification**
- All three fixture outputs are byte-deterministic across two runs, parse successfully, and preserve anchors/provenance; the safety test finds no executable markup.

**Result** _(filled in when done)_
- Command, result, snapshots and surprises.

### Task 6: Integrated M3 fixture and closure

**Status:** `[ ]`

**Tests assumption:** None; this task records the measured end state after Tasks 1–5.

**Files**
- Create: `bench/m3/` scripts and `bench/runs/2026-11-16-m3-*` archives; closing `dev_logs/` entry.
- Modify: this plan, `plan/README.md`, `dev_docs/design.qmd` or an ADR only when evidence requires it, and `NEWS.md` for user-visible package behavior.

**Intent**
- Exercise the whole path on a frozen mtcars figure: append claims and annotations, rebase after controlled edits, regenerate projections, open the HTML interaction and compare all export states. Report mechanism numbers separately from any future benchmark coverage.

**Verification**
- Run the full host suite with `NOT_CRAN=true`, record files/pass/fail/skip counts, run `R CMD build`/`R CMD check`, and archive all M3 fixture outputs. Do not run or tune against the held-out set.

**Result** _(filled in when done)_
- Final counts, measurements, scope changes and the next slice.

## Scope changes

_(Append dated changes here; never edit completed tasks silently.)_

## Closing notes

Filled in when the plan moves to `done/`: compare the final suite and key measurements with the starting state, state which assumptions held, link the closing dev log and NEWS entry, and derive the next plan from the evidence.
