# gloss Artifact Viewer Workbench (v1 Static + Design-Tool Outline + External Context + Live Mode)

> Status: completed (2026-11-18).
> Date opened: 2026-11-18. Owner: Yonghe Xia.

**Goal:** Deliver a browser-based single-file, drop-in, and live-R-session **gloss Workbench** (`gl_workbench()`, `gl_workbench_serve()`, external `gl_context()` plugins + `gl_add_context()`, and the `workbench/` React 19 / TypeScript / AG Grid / Rive / React Flow / CodeMirror / Flatbush app with Figma/BioRender-style Outline & Multi-Level Focus) that decodes any `v0.3.0` `gloss-bundle` locally with SHA-256 verification, exposes all 9 analytical + contextual semantic stages without redrawing original SVG geometry, and round-trips losslessly through `gl_read()`.

**Why now:** Capture, checked bindings, append-only semantic records, closed checks, operations, projections and staged agents were all implemented ([dev_logs/2026-11-18-agent-first-binding.md](../../dev_logs/2026-11-18-agent-first-binding.md)), while human inspection and external domain context attachment lacked a unified browser interface.

**Research-card clause:** Infrastructure for human inspection, open-world semantic audit, external contextual grounding, and sharing verifiable figures (supports M3–M6 human audit without altering core evaluation benchmarks).

**Starting state (measured):**
- Host suite from prior closing log (`2026-11-18-agent-first-binding.md`): 23 files, 1648 expectations, 0 failures, 0 skips (`NOT_CRAN=true Rscript -e "devtools::test()"`).
- No client-side `gloss-bundle` decoder existed (`inst/js/gloss-core.js` was 98 lines reading only `window.__GLOSS_RUNTIME_CONFIG__`).
- `core_layer_body_schema()` lacked optional `source`, `source_type`, `confidence` fields; `gl_context()` had 6 core sniffers (`code`, `data`, `engine`, `env`, `doc`, `git`).

**Assumptions to test:**
1. Browser native `DecompressionStream("deflate")` + TypeScript binary unshuffling decodes real `v0.3.0` bundles faithfully with 100% SHA-256 integrity. (Confirmed in Task 1.)
2. A full-featured single-file workbench (React 19 + AG Grid Community + Rive + React Flow + CodeMirror 6 + Flatbush) stays under 3.5 MiB uncompressed / 1 MiB gzipped, excludes `workbench/` from CRAN tarballs except for a compact gzipped shell (`< 700 KB`), and round-trips losslessly through `gl_read()`. (Confirmed in Tasks 2–3.)
3. All 9 semantic stages, Figma/BioRender-style Outline & Multi-Level Focus (data layer, inferred data groups, natural-language semantic nodes, guides), AG Grid bidirectional brushing, partial-claim exception highlighting, and external context cards render cleanly in a real browser with 0 console errors. (Confirmed in Tasks 4–5.)

**Architecture:** Standalone Vite + React 19 + TypeScript frontend in `workbench/` (ignored from R builds via `.Rbuildignore`), dual-built into a drop-in SPA and single-file shells (`full` with Rive runtime, `lite` zero-WASM). R exposes `gl_workbench()`, the `"workbench"` projection plugin (`R/project-workbench.R`), `gl_workbench_serve()` (`R/workbench-live.R`, optional `httpuv`), seven read-only external context plugins + `gl_add_context()` (`R/context-external.R`), and optional provenance fields on `R/core-record.R`. Core lightweight HTML projection (`R/project-html.R`) is untouched.

**Out of scope:** Authoring custom binary `.riv` animation files in Rive Editor (the adapter & hot-swap slots are ready; dynamic SVG state-machine fallbacks ship today) and running `gl_annotate()` live LLM stages inside the HTTP handler.

**Tech stack:** R (base + existing `gloss` imports; optional `httpuv` in `Suggests`), React 19, TypeScript 5.9, Vite 6 + `vite-plugin-singlefile`, Tailwind CSS v4, AG Grid Community v33, `@rive-app/react-canvas`, `@xyflow/react`, CodeMirror 6, Flatbush, Zustand, Radix UI, `react-resizable-panels`, `cmdk`, Vitest.

---

## Progress tracking

**Final state**
- Frontend Vitest: 2 files, 6 tests, 0 failures (`node workbench/node_modules/vitest/vitest.mjs run --config vite.config.ts --root workbench`, 2026-11-18).
- Frontend TypeScript: `tsc -p workbench/tsconfig.json --noEmit` → 0 errors.
- Single-file shell sizes: `full` = `2,384.70 kB` (`687.18 kB` gzipped; `inst/workbench/workbench-full.html.gz` = `667 KB`), `lite` = `1,988.98 kB` (`585.18 kB` gzipped).
- Full R host suite (`R_LIBS_USER=/nonexistent NOT_CRAN=true Rscript -e "devtools::test()"`, 2026-11-18): **25 files, 1642 expectations passed, 0 failures, 0 warnings, 8 sandbox environment skips** (`aisdk` 5, `sf` 1, `showtext` 2).
- `R CMD check --no-manual` (`_R_CHECK_FORCE_SUGGESTS_=false R_LIBS_USER=/nonexistent`): install, installed size, non-ASCII, codoc, Rd, examples, and `testthat.R` all `OK`.

**Overall progress**
- [x] Task 1: `@gloss/bundle-codec` client-side decoder & Vitest verification
- [x] Task 2: Workbench UI (4-zone IDE layout, Rive adapter + 9-stage rail, lossless SVG canvas, AG Grid 6-tab grid, CodeMirror 6, React Flow lineage, `⌘K`)
- [x] Task 3: R integration (`gl_workbench()`, `"workbench"` projection plugin, external record provenance fields, lossless round-trip tests)
- [x] Task 4: Live browser verification & visual polish on real `mtcars-workbench.html`
- [x] Task 5: Design-tool Outline Tree & Multi-Level Focus (`Outline` / `Data Groups` / `SVG / Grob`, Zoom-to-Focus, per-node visibility, natural-language focus), external `gl_context()` plugins + `gl_add_context()`, and local live `gl_workbench_serve()` mode

---

### Task 1–4 Summary

- See [dev_logs/2026-11-18-gloss-workbench.md](../../dev_logs/2026-11-18-gloss-workbench.md) for per-task commands, measurements, and browser-verified defect fixes.

### Task 5: Design-tool Outline + Multi-Level Focus + External `gl_context()` + `gl_workbench_serve()`

**Status:** `[x]`

**Result**
- Frontend: added `workbench/src/codec/outline.ts` + `outline.test.ts`, `workbench/src/components/left/OutlineTree.tsx`, `workbench/src/components/ProposalModal.tsx`, upgraded `FigureStage.tsx` (Focus spotlighting, dashed focus frame, Zoom-to-Focus, per-element eye visibility), `LeftPanel.tsx` (structured External Context cards), `CommandPalette.tsx` (Focus targets in `⌘K`), and `App.tsx` (`LIVE R` indicator).
- R backend: added `R/context-external.R` (7 read-only context plugins + `gl_add_context()`), `R/workbench-live.R` (`gl_workbench_serve()` + pure `workbench_live_handler()`), updated `DESCRIPTION` (`Suggests: httpuv`), `R/zzz.R`, `NAMESPACE`, `man/`, `tests/testthat/test-context.R` (`44` pass), `tests/testthat/test-workbench-live.R` (`19` pass), `dev_docs/demo/workbench-demo.R`.
- Verified: Vitest `2 files, 6 passed`; `tsc --noEmit` 0 errors; live browser verification on `mtcars-workbench.html` (`0` console/page errors; confirmed `cyl = 6` focus, Zoom-to-Focus `167%`, natural-language `exception` focus highlighting 3 auto 4-cyl points, `Gridlines & Backgrounds` 46-element hide/restore, External Context cards, and Proposal modal); full R suite `25 files, 1642 passed, 0 failed, 0 warnings, 8 sandbox skips`.

---

## Closing notes

- **End state vs starting state:** 23 → 25 R test files (`1642` passed, `0` failed, `0` warnings, `8` sandbox skips for user-library packages), plus 2 frontend Vitest files (`6` passed) and live Chromium visual verification.
- **Assumptions confirmed:** Native `DecompressionStream("deflate")` + SHA-256 verification works cleanly in browsers; single-file workbench fits in `687 kB` gzipped (`667 KB` in `inst/workbench/workbench-full.html.gz`) and round-trips losslessly via `gl_read()`; data-group & natural-language Outline Focus works generically from bundle tables and derived bindings without dataset hardcoding.
- **Next slice:** Author custom `.riv` assets in Rive Editor to drop into `workbench/public/rive/`, and optionally add live `gl_annotate()` stage execution inside `gl_workbench_serve()` once a fixed model gateway token is configured.
- **Links:** [dev_logs/2026-11-18-gloss-workbench.md](../../dev_logs/2026-11-18-gloss-workbench.md), [NEWS.md](../../NEWS.md).
