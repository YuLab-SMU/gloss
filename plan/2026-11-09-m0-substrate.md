# M0: the substrate

> Status: active.
> Date opened: 2026-11-09. Owner: Yonghe Xia.

**Goal:** `gloss(x)` captures any ggplot, patchwork, ComplexHeatmap, base or grid figure into a read-only substrate (elements, leaves, panels, tables with inferred row keys, context), which can be queried and written to a directory or a single HTML/SVG file and read back without loss.

**Why now:** M0 is the first milestone in [design §实施计划](../dev_docs/design.qmd#sec-plan); every later capability reads the substrate. ADR-0001 and ADR-0003 both list M0 follow-ups (capture in `core-substrate.R`; registry, `gl_register()`, `gl_test_plugin()`).

**Architecture:** Core files `core-plugin.R` (registry, plugin schema, contract tests), `core-substrate.R` (group + probe capture, `<use>` inlining, element table, per-leaf counts, dense rasters), `core-data.R` (tables, row-key inference, `gl_key()`), `core-codec.R` (lossless JSON for tables and metadata), `core-bundle.R` (directory and single file, restore). `identify.R` holds the public geometry queries. Engines (`engine-*.R`), context sniffers (`context-*.R`) and the single-file projections (`project-*.R`) are plugins registered in `.onLoad()` through `gl_register()`, like a third-party plugin would be. Not touched: classification, structure and data trees (M1), records, anchors and layers (M2), checks, operations, ARIA (M3), agents (M4).

**Out of scope:** classification rules and the structure tree (M1); element ↔ data-row binding (M1, needs the data tree); record schema, layers and the JSONL log (M2), so `gl_key()` cannot yet rewrite data-key selectors; colour-pick fallback for devices without groups (svglite is the only capture device and supports groups; anything else aborts with a clear message); patchwork and heatmap scales for `gl_to_pixel()`.

**Tech stack:** R >= 4.2, svglite >= 2.2, xml2, jsonlite, digest, cli, rlang. Suggests: ggplot2, patchwork, ComplexHeatmap, gridGraphics, ggrepel, ragg, knitr, testthat, withr.

**Verification:** the three completion criteria from the design, as tests:
1. the six input classes of the capture table are captured with a drawn-primitive sequence identical to plain svglite and only the device background unowned;
2. directory → single file → directory is byte-identical, and `gl_read(gl_write(fig))` equals `fig`;
3. a 10^5-point scatter written as a single file is smaller than 3 MB.

---

## Progress tracking

**Status legend**
- `[ ]` Not started
- `[~]` In progress
- `[x]` Completed
- `[!]` Blocked
- `[-]` Cancelled

**Plan maintenance rules**
- Update immediately after landing a task or sub-step.
- Record the verification command / observed behavior when marking `[x]`.
- If scope shifts, append a `Scope Change` note rather than silently changing completed work.

**Overall progress**
- [x] Task 1: Package skeleton
- [x] Task 2: Plugin registry and contract tests
- [x] Task 3: Capture and the element graph
- [x] Task 4: Panels, scales and geometry queries
- [x] Task 5: Tables, row-key inference and `gl_key()`
- [x] Task 6: Dense leaves: raster plus binary index
- [x] Task 7: Context sniffing
- [x] Task 8: Bundle: directory, single file, restore
- [ ] Task 9: Benchmark sampling frame, split and freeze
- [x] Task 10: Records: ADRs, NEWS, dev log, design status

Full suite on 2026-11-09: `NOT_CRAN=true Rscript -e "devtools::test()"`: 7 files, 45 tests, 268 expectations, 0 failed, 0 skipped. `R CMD check --no-manual` (built with `--no-build-vignettes`): 0 errors, 0 warnings, 0 notes.

---

### Task 1: Package skeleton

**Status:** `[x]`

**Files**
- Modify: `DESCRIPTION`, `.Rbuildignore`
- Create: `R/gloss-package.R`, `R/zzz.R`, `R/utils.R`, `tests/testthat.R`

**Checklist**
- [x] Imports and Suggests in `DESCRIPTION`
- [x] roxygen package doc; `devtools::document()` generates `NAMESPACE`
- [x] testthat edition 3 entrypoint

**Verification**
- `Rscript -e "devtools::document()"` and `Rscript -e "devtools::load_all()"` run clean. Done 2026-11-09.

---

### Task 2: Plugin registry and contract tests

**Status:** `[x]`

**Files**
- Create: `R/core-plugin.R`, `R/core-schema.R`, `tests/testthat/test-plugin.R`

**Intent**
- ADR-0003: one `gl_register()` for eight kinds, validated at registration; built-ins use the same path; `gl_test_plugin()` runs the shared contract for a kind.

**Checklist**
- [x] Eight kinds with required fields; name, version, required core API version, schema validated on register
- [x] Small schema language (string, number, integer, boolean, enum, object, array) with a validator
- [x] `gl_register()`, `gl_unregister()`, `gl_plugins()`, `gl_plugin()`
- [x] `gl_test_plugin()` with per-kind contracts; a third-party plugin registered in a test and run through `gloss()`

**Verification**
- `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-plugin.R')"`: 42 expectations pass. Every built-in plugin (5 engines, 6 context sniffers, 2 projections) passes `gl_test_plugin()`; a toy third-party engine is dispatched by class and passes its contract.

---

### Task 3: Capture and the element graph

**Status:** `[x]`

**Files**
- Create: `R/core-substrate.R`, `R/engine-ggplot.R`, `R/engine-patchwork.R`, `R/engine-heatmap.R`, `R/engine-base.R`, `R/engine-grid.R`, `tests/testthat/test-capture.R`, `tests/testthat/helper-figures.R`

**Intent**
- ADR-0001 in package form: one render, attribution from the device, viewport paths and boxes from probes, refuse on count mismatch.

**Checklist**
- [x] Wrap every leaf of the forced scene as probe + `groupGrob()`, hoisting `vp`
- [x] Map groups to leaves through the probe draw order; abort when the group and probe counts disagree
- [x] Inline `<use>` into `<g data-gloss-leaf>`; parse elements (tag, box, style, text) and leaves (path, class, vp, box, expected and drawn counts, status)
- [x] `gloss()` S3 generic dispatching to engine plugins by declared class (ADR-0004)
- [x] Regression on the six input classes: identical to plain svglite, only the background unowned
- [x] Injected count mismatch is reported and the leaf is marked not bindable

**Verification**
- `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-capture.R')"`: 67 expectations pass. The six inputs (ggplot facets + smooth, patchwork, base via gridGraphics, ComplexHeatmap, ggrepel, 10^4 points) draw the same primitive sequence as plain svglite, with only the device background unowned. The faceted plot reproduces the spike: 134 elements, 62 leaves, 6 count mismatches.

---

### Task 4: Panels, scales and geometry queries

**Status:** `[x]`

**Files**
- Create: `R/identify.R`, `tests/testthat/test-identify.R`

**Checklist**
- [x] Panels with facet key, device box and x/y scale from the ggplot engine; native-scale panels from gridGraphics windows and heatmap bodies
- [x] `gl_elements()`, `gl_leaf()`, `gl_panels()`, `gl_hit()`, `gl_near()`, `gl_overlap()`, `gl_to_pixel()`, `gl_to_data()`
- [x] Scale check: built data mapped through `gl_to_pixel()` lands on the drawn circles

**Verification**
- `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-identify.R')"`: 37 expectations pass. Built data mapped through each panel lands within 0.011 pt of the drawn circle centres for `facet_wrap`, `facet_grid(scales = "free")` and a base scatter.

---

### Task 5: Tables, row-key inference and `gl_key()`

**Status:** `[x]`

**Files**
- Create: `R/core-data.R`, `tests/testthat/test-data.R`

**Checklist**
- [x] Raw, built and engine tables from the engine plugin
- [x] Five inference rules in order, with rule and basis recorded; rule 5 flagged fragile
- [x] `gl_key()` validates uniqueness and missingness and keeps a key history (selector rewriting waits for M2 records)

**Verification**
- `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-data.R')"`: 30 expectations pass, one case per rule plus a skipped non-unique hint.

---

### Task 6: Dense leaves: raster plus binary index

**Status:** `[x]`

**Checklist**
- [x] Leaves with at least `dense` non-text elements are drawn to a transparent PNG on their own and replaced by `<image>` in the scene
- [x] Their element geometry goes to a binary index; queries are unchanged

**Verification**
- `test-capture.R` "dense leaves become a raster plus index": the element table is identical with and without rasterising. `test-bundle.R` "dense leaves round-trip": the substrate is identical after an HTML round trip.

---

### Task 7: Context sniffing

**Status:** `[x]`

**Files**
- Create: `R/context-code.R`, `R/context-data.R`, `R/context-engine.R`, `R/context-env.R`, `R/context-doc.R`, `R/context-git.R`, `tests/testthat/test-context.R`

**Checklist**
- [x] One sniffer plugin per row of the context table; not found means empty plus a reason
- [x] Code: call, srcref, knitr chunk, script file; data: object names, source files with hashes, column summaries, row keys; engine: class and loaded extensions; env: versions, device, fonts, platform; doc: knitr/Quarto chunk, caption, output format, Shiny; git: commit and dirty state

**Verification**
- `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-context.R')"`: 30 expectations pass. Tested at the console, in a `source()`d script (finds the script, the definition of `p`, the data object and the CSV with its md5), and in a knitted R Markdown chunk (label, caption, size, chunk code). A failing sniffer is recorded with its error as the reason. Quarto and Shiny detection have not been run.

---

### Task 8: Bundle: directory, single file, restore

**Status:** `[x]`

**Files**
- Create: `R/core-codec.R`, `R/core-bundle.R`, `R/project-html.R`, `R/project-svg.R`, `tests/testthat/test-codec.R`, `tests/testthat/test-bundle.R`

**Checklist**
- [x] Lossless codec for tables (types, NA/NaN/Inf, factors, dates, row names) and metadata
- [x] Directory layout of the design (manifest, context, substrate, layers, projections)
- [x] Single file: projection plus `<script type="application/json" id="gloss-bundle">`; byte-identical directory round trip
- [x] `embed =` all, default, summary, none
- [x] Restore: full, data stripped, plugin missing, plain SVG without a bundle
- [x] 10^5-point single file under 3 MB

**Verification**
- `NOT_CRAN=true Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-bundle.R')"`: 52 expectations pass. Directory → HTML → directory and directory → SVG → directory are byte-identical; `gl_read(gl_write(fig))` is `identical()` to `fig` for substrate, tables, meta, plugins and status (context `expect_equal`). 10^5 rnorm points, 7 × 5 in, default embedding: 2.65 MiB HTML (plain svglite of the same plot: 8.3 MB). Format: ADR-0005.

---

### Task 9: Benchmark sampling frame, split and freeze

**Status:** `[ ]`

**Intent**
- Design §评测设计: the sampling frame, strata, seed, development and held-out split are fixed in `bench/` before M1 starts.

**Checklist**
- [ ] Sampling frame from R Graph Gallery, extension package examples, Bioconductor vignettes, TidyTuesday
- [ ] Stratified random sample of 100–200 figures with code and data; seed recorded
- [ ] Attempted and retained counts with failure reasons
- [ ] Development / held-out split, frozen with a commit

---

### Task 10: Records

**Status:** `[x]`

**Checklist**
- [x] ADRs for settlements made during M0: ADR-0004 (engine dispatch), ADR-0005 (bundle format v0)
- [x] `NEWS.md`, dev log `dev_logs/2026-11-09-m0-substrate.md`, design doc status notes

---

## Scope changes

_(append-only; never edit completed tasks above)_

- 2026-11-09 — **Guides** (axes, legends, strips, legend key ↔ series) are listed in the design's graphics interface but depend on classification; they move to M1 with the rule sets.
- 2026-11-09 — **Masks are refused.** R does not apply an active viewport mask inside a graphics group, so a masked leaf would be drawn unmasked. Capture now aborts when the device writes a `<mask>`. Gradient and pattern fills, clipping paths and gTree-level alpha were checked and capture unchanged. Supporting masks needs a different mechanism (for example, re-applying the mask to the inlined group) and is open.
- 2026-11-09 — **Patchwork panels** are not mapped in M0 (tables only); heatmap and base panels use the probes' native scales, so `gl_to_pixel()` works there in native units.

## Closing notes

Filled in when the plan moves to `done/`.
