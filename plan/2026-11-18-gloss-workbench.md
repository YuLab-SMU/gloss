# gloss Artifact Viewer Workbench (v1 Static + Codec + Contextual Provenance)

> Status: active (v1 static workbench complete; v2 live `httpuv` mode & new external `gl_context()` plugins open).
> Date opened: 2026-11-18. Owner: Yonghe Xia.

**Goal:** Deliver a browser-based single-file and drop-in **gloss Workbench** (`gl_workbench()` + `workbench/` React/TypeScript/AG Grid/Rive/React Flow/CodeMirror/Flatbush app) that decodes any `v0.3.0` `gloss-bundle` locally with SHA-256 verification, exposes all 9 analytical + contextual semantic stages without redrawing original SVG geometry, and round-trips losslessly through `gl_read()`.

**Why now:** Capture, checked bindings, append-only semantic records, closed checks, operations, projections and staged agents are all implemented ([dev_logs/2026-11-18-agent-first-binding.md](../dev_logs/2026-11-18-agent-first-binding.md)), but inspecting a single gloss artifact still required jumping between R console outputs and minimal HTML projections.

**Research-card clause:** Infrastructure for human inspection, open-world semantic audit, and sharing verifiable figures (supports M3–M6 human audit and external contextual semantics without touching the core evaluation benchmarks).

**Starting state (measured):**
- Host suite from prior closing log (`2026-11-18-agent-first-binding.md`): 23 files, 1648 expectations, 0 failures, 0 skips (`NOT_CRAN=true Rscript -e "devtools::test()"`).
- No client-side `gloss-bundle` decoder existed (`inst/js/gloss-core.js` was 98 lines reading only `window.__GLOSS_RUNTIME_CONFIG__`).
- `core_layer_body_schema()` lacked optional `source`, `source_type`, `confidence` fields.

**Assumptions to test:**
1. Browser native `DecompressionStream("deflate")` + TypeScript binary unshuffling decodes real `v0.3.0` bundles (`dev_docs/demo/mtcars-context.html`, `mtcars-bundle/`, and `10^5`/`10^4` dense `index.bin` leaves) faithfully with 100% SHA-256 integrity. (Tested in Task 1.)
2. A full-featured single-file workbench (React 19 + AG Grid Community + Rive + React Flow + CodeMirror 6 + Flatbush) builds cleanly under 3.5 MiB uncompressed / 1 MiB gzipped, stays out of the R CRAN source tarball except for a compact gzipped shell (`< 700 KB`), and round-trips losslessly through `gl_read()`. (Tested in Tasks 2–3.)
3. All 9 semantic stages, AG Grid bidirectional brushing, partial-claim exception highlighting, and untouched SVG overlays render cleanly in a real browser with zero console errors or visual overlaps. (Tested in Task 4.)

**Architecture:** Standalone Vite + React 19 + TypeScript frontend in `workbench/` (ignored from R builds via `.Rbuildignore`), dual-built into a drop-in SPA and single-file shells (`full` with Rive runtime, `lite` zero-WASM). R exposes `gl_workbench()` and the `"workbench"` projection plugin (`R/project-workbench.R`), injecting `embed_script(fig, embed)` into `inst/workbench/workbench-full.html.gz` (656 KB). `R/core-record.R` adds optional external-context provenance fields (`source`, `source_type`, `confidence`). Core lightweight HTML projection (`R/project-html.R`) is untouched.

**Out of scope (for v1):** Live `httpuv` R-session server (`gl_workbench_serve()`), new external `gl_context()` sniffer plugins (`data_dictionary`, `ontology`, etc.), and editing/re-running `gl_annotate()` from the browser (tracked as Task 5).

**Tech stack:** R (base + existing `gloss` imports only), React 19, TypeScript 5.9, Vite 6 + `vite-plugin-singlefile`, Tailwind CSS v4, AG Grid Community v33, `@rive-app/react-canvas`, `@xyflow/react`, CodeMirror 6, Flatbush, Zustand, Radix UI, `react-resizable-panels`, `cmdk`, Vitest.

**Done when:**
- `@gloss/bundle-codec` Vitest tests pass on real `mtcars-context.html`, `mtcars-bundle/`, shuffled binary vectors, dense `index.bin`, and plain SVG fallback;
- `tsc --noEmit` and `full`/`lite`/SPA Vite builds succeed;
- `gl_workbench()` passes R `testthat` round-trip and `gl_test_plugin("projection", "workbench")`, and full host suite + `R CMD check --no-manual` are green;
- Real browser inspection of generated `dev_docs/demo/mtcars-workbench.html` shows 0 console/page errors and verified visual/interactive checks across all panels.

---

## Progress tracking

**Current state**
- Frontend Vitest: 1 file, 5 tests, 0 failures (`node workbench/node_modules/vitest/vitest.mjs run --config vite.config.ts --root workbench`, 2026-11-18).
- Single-file shell sizes: `full` = `2,339.13 kB` (`676.05 kB` gzipped; `inst/workbench/workbench-full.html.gz` = `656 KB`), `lite` = `1,943.47 kB` (`573.92 kB` gzipped).
- Full R host suite (`R_LIBS_USER=/nonexistent NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-18): 24 files, 1602 expectations passed, 0 failures, 0 warnings, 8 environment skips (`aisdk` 5, `sf` 1, `showtext` 2, outside sandbox user library).
- `R CMD check --no-manual` (`_R_CHECK_FORCE_SUGGESTS_=false R_LIBS_USER=/nonexistent`): install, installed size, codoc, Rd, examples, and `testthat.R` all `OK` (the sole warning/note came from the untracked pre-existing `City bike-share demand/` folder in the workspace root).

**Overall progress**
- [x] Task 1: `@gloss/bundle-codec` client-side decoder & Vitest verification
- [x] Task 2: Workbench UI (4-zone IDE layout, Rive adapter + 9-stage rail, lossless SVG canvas, AG Grid 6-tab grid, CodeMirror 6, React Flow lineage, `⌘K`)
- [x] Task 3: R integration (`gl_workbench()`, `"workbench"` projection plugin, external record provenance fields, lossless round-trip tests)
- [x] Task 4: Live browser verification & visual polish on real `mtcars-workbench.html`
- [ ] Task 5: v2 follow-up — external `gl_context()` plugins (`data_dictionary`, `project_notes`, `user_context`, `ontology`) and local live `gl_workbench_serve()` mode _(stub)_

---

### Task 1: `@gloss/bundle-codec` client-side decoder & Vitest verification

**Status:** `[x]`

**Result**
- `node workbench/node_modules/vitest/vitest.mjs run --config vite.config.ts --root workbench` → 1 file, 5 passed, 0 failed (519 ms). Verified SHA-256 integrity on `dev_docs/demo/mtcars-context.html` (21 files, 125 elements, 32 verified bindings, 3 records, 4 operations), directory decode on `dev_docs/demo/mtcars-bundle/`, shuffled `f64le`/`i32le` vectors with R `NA`/`NaN`/`±Inf`, 10,000-point dense `index.bin` + Flatbush hit-testing (14 ms), and plain-SVG geometry-only fallback.

### Task 2: Workbench UI & dual single-file builds

**Status:** `[x]`

**Result**
- `tsc -p workbench/tsconfig.json --noEmit` → 0 errors.
- Full single-file build (`vite.singlefile.config.ts`) → `2,339.13 kB` (`676.05 kB` gzipped) in 2.39 s.
- Lite single-file build (`VITE_WORKBENCH_MODE=lite`) → `1,943.47 kB` (`573.92 kB` gzipped) in 1.89 s.
- Standard SPA build (`vite.config.ts`) → `dist/index.html` + `45.18 kB` CSS + `2,292.65 kB` JS.

### Task 3: R integration (`gl_workbench()` + extended contextual record fields)

**Status:** `[x]`

**Result**
- Added `R/project-workbench.R` (`gl_workbench()`, `register_projection_workbench()`), registered in `R/zzz.R`, added optional `"source?"`, `"source_type?"`, `"confidence?"` to `R/core-record.R`, packaged `inst/workbench/workbench-full.html.gz` (656 KB), added `^workbench$` to `.Rbuildignore`.
- `R_LIBS_USER=/nonexistent Rscript -e "devtools::load_all(quiet=TRUE); testthat::test_file('tests/testthat/test-workbench.R'); testthat::test_file('tests/testthat/test-plugin.R'); testthat::test_file('tests/testthat/test-hygiene.R')"` → `12 + 92 + 1 = 105` passed, 0 failures, 0 warnings, 0 skips.
- `Rscript dev_docs/demo/workbench-demo.R` → wrote `dev_docs/demo/mtcars-workbench.html` (`2,363,126` bytes); `gl_read()` round-trip identical elements (`TRUE`), bindings (`TRUE`), records (`10`).

### Task 4: Live browser verification & visual polish

**Status:** `[x]`

**Result**
- Live Chromium inspection of `http://127.0.0.1:4188/mtcars-workbench.html` at `1440×900`: 0 console errors, 0 uncaught page errors.
- First pass caught 3 concrete defects: (1) AG Grid treated `field: ".rownames"` as dot-notation causing empty cells (`suppressFieldDotNotation={true}` fixed it); (2) R `check_trend` group labels use `"1 / 1"` (`/` separator) and group button click bubbled to `RecordCard` (`stopPropagation()` + `/` split fixed exception highlighting of the 3 auto 4-cyl points); (3) duplicate relation arcs & panel-edge leader callout collided (staggered bezier arcs with white pill backs + panel-clamped callout fixed both).
- Second browser pass verified all 3 fixes cleanly with 0 console/page errors.

### Task 5: External `gl_context()` plugins & local live `gl_workbench_serve()` mode

**Status:** `[ ]` _(stub; to be detailed once v1 workbench feedback is reviewed)_

---

## Scope changes

- None yet.
