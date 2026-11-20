# 2026-11-18 — gloss Artifact Viewer Workbench v1

- **Related plan:** [plan/2026-11-18-gloss-workbench.md](../plan/2026-11-18-gloss-workbench.md) (active; Tasks 1–4 complete, Task 5 open)
- **Related ADRs:** [ADR-0005](../dev_docs/decisions/0005-bundle-format-v0.md) (bundle format v0)
- **Worked on by:** Antigravity

## What changed

- **Frontend Workbench (`workbench/`, excluded from CRAN tarball via `.Rbuildignore`)**:
  - `@gloss/bundle-codec` (`workbench/src/codec/`): pure TypeScript client-side decoder for `gloss-bundle` v0.x (native `DecompressionStream("deflate")`, u32-BE unpacking, Web Crypto SHA-256 manifest verification, `f64le`/`i32le` byte-unshuffling, shared column references, `index.bin` dense-leaf decoding + Flatbush R-tree spatial index, derived compaction expansion, JSONL layer materialization, transparent plain-SVG geometry-only degradation, and WAI-ARIA / Text / W3C Web Annotation projections).
  - UI workspace (`workbench/src/components/`):
    - Top header + signature 9-Stage Semantic Ladder Rail (`Raw SVG → Structure → Binding → Analytical → Contextual → Relation → Claim → Narrative → Behavior`) backed by `@rive-app/react-canvas` State Machine adapter (`RiveAdapter.tsx`, `StageRail.tsx`, `VerificationSeal.tsx`, `DropzoneHero.tsx`) with native SVG fallbacks and hot-swap `.riv` asset slots.
    - Central lossless `FigureStage.tsx` mounting the original `svglite` SVG untouched (Principle 1, scripts/`on*` stripped), synchronized non-destructive `viewBox` overlay, pan/zoom, Before/After curtain comparison slider, Flatbush hit-testing, and SVG↔data coordinate HUD.
    - Bottom `DataWorkbenchGrid.tsx` using **AG Grid Community v33+** across `raw`, `built_layer*`, `Bindings`, `Elements`, `Roles`, and `Records` with pinned row-key columns, R special-value renderers (`NA`/`NaN`/`±Inf`), hex swatches, `dev` bars, CSV export, and bidirectional brushing & linking with the SVG canvas.
    - Left panel (`LeftPanel.tsx`, `CodeViewer.tsx`): Structure tree with leaf visibility toggles, sniffed & external context cards + SHA-256 integrity status, CodeMirror 6 R code & JSONL event log viewer, and ARIA/Text/Web Annotation exports.
    - Right inspector (`RightInspector.tsx`, `LineageDag.tsx`): 4-section evidence chain (Substrate Facts, Code-Checked Binding + transparently labeled `inferred` raw entity, Anchored Records with external `source`/`source_type`/`confidence`/`evidence`, Active Operations), interactive per-group `gl_check()` matrix that highlights exception points on the SVG, audit records tab, and interactive React Flow (`@xyflow/react`) provenance DAG.
    - Global `⌘K` command palette (`CommandPalette.tsx`) and dual themes (`Paper Studio` light / `Obsidian Lab` dark).
- **R Package Integration**:
  - `R/project-workbench.R`: added `gl_workbench()` and registered the `"workbench"` projection plugin in `R/zzz.R`, embedding the identical `<script type="application/json" id="gloss-bundle">` payload into `inst/workbench/workbench-full.html.gz` (656 KB) so exported HTML files round-trip losslessly via `gl_read()`.
  - `R/core-record.R`: extended `core_layer_body_schema()` with optional `"source?"`, `"source_type?"`, and `"confidence?"` fields for external contextual semantics.
  - `tests/testthat/test-workbench.R`, `man/gl_workbench.Rd`, `NAMESPACE`, `NEWS.md`, `dev_docs/demo/workbench-demo.R`.

## Measured

- **Frontend typecheck & Vitest**:
  - `node workbench/node_modules/typescript/bin/tsc -p workbench/tsconfig.json --noEmit` → 0 errors.
  - `node workbench/node_modules/vitest/vitest.mjs run --config vite.config.ts --root workbench` → 1 file, 5 tests passed, 0 failed (519 ms): verified real `dev_docs/demo/mtcars-context.html` (21 files, SHA-256 100% pass, 125 elements, 32 verified bindings, `e65 -> Mazda RX4`), directory bundle `dev_docs/demo/mtcars-bundle/`, shuffled `f64le`/`i32le` binary vectors with R specials, 10,000-point dense `index.bin` + Flatbush hit-testing (14 ms), and plain-SVG fallback.
- **Single-file build sizes**:
  - `full` (`vite.singlefile.config.ts`, includes `@rive-app/react-canvas` + AG Grid + React Flow + CodeMirror 6): `2,339.13 kB` uncompressed / `676.05 kB` gzipped (`inst/workbench/workbench-full.html.gz` = `656 KB`).
  - `lite` (`VITE_WORKBENCH_MODE=lite`, zero-WASM stub): `1,943.47 kB` uncompressed / `573.92 kB` gzipped (`-395.66 kB` uncompressed).
  - Generated showcase `dev_docs/demo/mtcars-workbench.html` (`Rscript dev_docs/demo/workbench-demo.R`): `2,363,126` bytes; `gl_read()` round-trip identical elements (`TRUE`), bindings (`TRUE`), records (`10`).
- **R test suite (before → after)**:
  - Prior closing log (`2026-11-18-agent-first-binding.md`): 23 files, 1648 expectations, 0 failures, 0 skips.
  - After (`R_LIBS_USER=/nonexistent NOT_CRAN=true Rscript -e "devtools::test()"`): **24 files, 1602 expectations passed, 0 failures, 0 warnings, 8 environment skips** (`aisdk` 5, `sf` 1, `showtext` 2, installed in `~/Library/R/arm64/4.5/library` outside the tool sandbox). Targeted new tests `test-workbench.R` (`12` pass), `test-plugin.R` (`92` pass, including `projection/workbench` contract), and `test-hygiene.R` (`1` pass): 0 failures, 0 warnings, 0 skips.
- **Package check**:
  - `_R_CHECK_FORCE_SUGGESTS_=false R_LIBS_USER=/nonexistent R CMD check --no-manual` → install, installed size, non-ASCII, codoc, Rd, examples, and `testthat.R` all `OK`. The sole warning/note came from the pre-existing untracked `City bike-share demand/` directory in the repo root; `workbench/` was cleanly excluded from the tarball.
- **Live browser inspection** (`http://127.0.0.1:4188/mtcars-workbench.html` at `1440×900`):
  - 0 console errors, 0 uncaught page errors; verified 9-stage rail, untouched SVG + staggered relation arcs + panel-clamped leader callouts, AG Grid pinned `.rownames` column (`Mazda RX4` etc.), clickable partial-claim exception group highlighting 3 automatic 4-cylinder points, React Flow lineage DAG, CodeMirror 6 R code, Before/After curtain compare, and Obsidian dark theme.
- **Not run**:
  - Bench Docker container suite (`bench/docker/run.sh`) was not required because no graphics-device capture code was modified.
  - Live `aisdk`/`sf`/`showtext` tests were skipped because macOS sandbox restricts reading `~/Library/R/arm64/4.5/library/`.

## Surprises

- **Base R `substring(x, first)` defaults `last = 1000000L`.** Because the single-file workbench HTML template is ~2.34 MB (> 1,000,000 chars), omitting `last = nchar(haystack)` in `replace_literal_once()` truncated the tail and dropped the second injection marker. Fixed immediately by passing `nchar(haystack)`. → `R/project-workbench.R` and covered by `test-workbench.R`.
- **Single-file JS bundle must never contain a literal `<script ... id="gloss-bundle">` string.** Wrapping `embeddedTag.textContent` back into a fake `<script>` string inside `App.tsx` would have caused R's `extract_embedded()` regex to match `<head>` JS instead of the `<body>` bundle tag. Added `decodeEmbeddedJsonText()` directly and verified 0 matches in the compiled shell. → `workbench/src/codec/decodeBundle.ts`, `App.tsx`, and verified by `gl_read()` round-trip test.
- **AG Grid treats leading dots (`field: ".rownames"`) as nested dot-notation.** Real browser inspection caught empty cells in the pinned `.rownames` column despite data being decoded. Fixed with `suppressFieldDotNotation={true}` and verified visually. → `workbench/src/components/grid/DataWorkbenchGrid.tsx`.
- **R `check_trend()` formats multi-column group labels with `" / "` (e.g. `"1 / 1"`), and clicking a group button inside `RecordCard` bubbled to `selectRecord()`.** Live browser inspection caught that clicking the exception group did not pulse the 3 exception points. Fixed with `e.stopPropagation()` and splitting group keys on `/\s*(?:[,|]|\/)\s*/`, then verified 3 amber pulsing exception points in the browser. → `workbench/src/components/right/RightInspector.tsx`.
- **Duplicate cross-panel relation arcs and right-edge leader callouts collided on the SVG overlay.** Fixed by staggering arcs on opposing bezier bows with pill backdrops and clamping leader callouts inside panel bounds. → `workbench/src/components/stage/FigureStage.tsx`.

## What's next

- Task 5 in `plan/2026-11-18-gloss-workbench.md`: add read-only external `gl_context()` plugins (`data_dictionary`, `project_notes`, `user_context`, `ontology`) so contextual semantics flow automatically into `gl_annotate()` and the Workbench's External Context panel, and optionally add `gl_workbench_serve()` (`httpuv`) for live R-session stage execution and interactive human `gl_propose()`.
- Author bespoke `.riv` binary animations in Rive Editor and drop them into `workbench/public/rive/` to hot-swap the Stage Rail, Verification Seal, and Dropzone Unfold fallbacks with zero code changes.

---

## Follow-up update (2026-11-18, later same session — Outline Tree, Multi-Level Focus, External Context & Live Mode)

- **Related plan:** [plan/done/2026-11-18-gloss-workbench.md](../plan/done/2026-11-18-gloss-workbench.md) (closed)

### What changed

- **Design-tool Outline & Multi-Level Focus (`workbench/src/codec/outline.ts`, `OutlineTree.tsx`, `FigureStage.tsx`, `CommandPalette.tsx`, `ProposalModal.tsx`)**:
  - Replaced the raw leaf list with a Figma/BioRender-inspired **Outline** panel offering three views (`Outline`, `Data Groups`, `SVG / Grob`), vertical tree rails, type icons, color swatches, circular semantic record count badges, hover focus crosshairs, per-node eye visibility toggles, quick focus chips, natural-language focus search (`Focus: cyl 6, exception, Mazda, legend...`), Zoom-to-Focus framing, and a bottom `+ Add semantic note / claim` modal (live-submitting when connected to `gl_workbench_serve()`, or generating copyable `gl_record()` R code when static).
  - Upgraded the left `Context` tab to render rich cards for `data_dictionary` variable tables, `dataset_documentation` Rd help, `project_notes`, `literature`, and `user_context`.
- **External `gl_context()` plugins & Live Mode (`R/context-external.R`, `R/workbench-live.R`, `DESCRIPTION`, `R/zzz.R`)**:
  - Registered seven read-only external context plugins (`data_dictionary`, `project_notes`, `dataset_documentation`, `ontology`, `literature`, `external_metadata`, `user_context`) and exported `gl_add_context()` with `payload_issues()` safety checks.
  - Exported `gl_workbench_serve()` (optional `httpuv` in `Suggests`) backed by a pure unit-tested router `workbench_live_handler()` (`/`, `/api/status`, `/api/bundle`, `/api/propose`, `/api/check`, `/api/context`).
  - Updated `tests/testthat/test-context.R` (expanded built-in context catalog from 6 to 13 items + external sniffing & round-trip tests), added `tests/testthat/test-workbench-live.R`, and refreshed `dev_docs/demo/workbench-demo.R`.

### Measured

- Frontend Vitest: `2 files, 6 passed, 0 failed` (58 ms), covering `outline.ts` data-group inference (`cyl = 4/6/8`), natural-language focus (`"cyl 6"` → 7 marks, `"exception"` → 3 marks, `"legend"` → `Legend · Cylinders`), and `Title`/`Subtitle` ordering on `mtcars-workbench.html`.
- Single-file build sizes: `full` = `2,384.70 kB` (`687.18 kB` gzipped; `inst/workbench/workbench-full.html.gz` = `667 KB`); `lite` = `1,988.98 kB` (`585.18 kB` gzipped); `dev_docs/demo/mtcars-workbench.html` = `2,412,107` bytes with `gl_read()` round-trip identical.
- Full R host suite (`R_LIBS_USER=/nonexistent NOT_CRAN=true Rscript -e "devtools::test()"`): **25 files, 1642 expectations passed, 0 failures, 0 warnings, 8 sandbox skips** (`aisdk` 5, `sf` 1, `showtext` 2). Targeted new/updated suites: `test-context.R` (`44`), `test-workbench-live.R` (`19`), `test-plugin.R` (`99`), `test-workbench.R` (`12`) — all 0 failures, 0 warnings, 0 skips.
- Live Chromium verification (`http://127.0.0.1:4188/mtcars-workbench.html`, `1440×900`): 0 console errors, 0 uncaught page errors; confirmed `cyl = 6` focus + dashed frame + AG Grid sync, Zoom-to-Focus (`167%`), natural-language `exception` focus, 46-element gridline hide/restore via Eye toggle, External Context cards, and Proposal modal.

### Surprises

- **ggplot2 facet strip paths include `titleGrob` and classify with `role = "guide"`, and `subtitle` precedes `title` in SVG draw order.** Initial Outline classification picked `"am: 0"` and `"Faceted by..."` as the plot title and labeled Legend as `"Legend · am: 0"`. Fixed by distinguishing `guide-box`/`legend` from `strip`/`axis` and sorting title candidates top-to-bottom by `y0`, locked in with Vitest assertions. → `workbench/src/codec/outline.ts` and `outline.test.ts`.
- **`utils::help(name)` uses NSE on its first argument.** Calling `utils::help(name)` inside `dataset_rd_summary()` looked up the literal topic `"name"` instead of the variable's value; passing `topic = (name)` fixed Rd help extraction for `datasets::mtcars`. → `R/context-external.R` and `test-context.R`.
- **`read_req_body()` evaluated `$read` before `is.character()` on test string inputs.** Fixed by checking `is.character(inp)` first. → `R/workbench-live.R` and `test-workbench-live.R`.

---

## Follow-up update (2026-11-19 — Scientific Reader Default View & Interaction-Driven Behavior)

- **Triggered by:** Owner review of the live workbench noting (1) the default UI felt too engineering-heavy for statisticians, biologists, and pharma users, and (2) `behavior` annotations were statically drawn onto the figure instead of guiding users to interact.

### What changed

- **Progressive disclosure (`view = "reader" | "inspector"`)** (`R/project-workbench.R`, `R/workbench-live.R`, `workbench/src/store/useWorkbenchStore.ts`, `workbench/src/App.tsx`):
  - Default landing view is now **Scientific Reader** (`view = "reader"`), replacing the 9-stage developer pipeline rail and bottom grid with a calm 4-lens switcher (`Figure | Explore | Findings | Story`), `Verified Data` / clickable `1 Exception` pills, on-demand `Data` drawer, and a top-right `Scientific | Inspector` switch.
  - Full 9-stage rail, `SVG / Grob` tree, SHA-256 integrity panel, R Code / JSONL tabs, React Flow lineage DAG, and raw element/binding audit tables remain one click away in `Inspector` mode (or via `gl_workbench(..., view = "inspector")`).
- **Humanized scientific presentation (`workbench/src/codec/humanize.ts`, `ReaderInspector.tsx`, `OutlineTree.tsx`, `LeftPanel.tsx`, `DataWorkbenchGrid.tsx`)**:
  - Added `humanizeCheckGroupLabel()` translating technical check group keys (`"1 / 1"`) into self-explanatory labels (`"am = 0 · cyl = 4"`), `humanizeStatus()`, `humanizeCheckKind()`, `humanizeToken()`, `humanizeOutlineLabel()`, `extractDataDictionaryMap()`, and `formatReaderTooltip()`.
  - Built `ReaderInspector.tsx`: opens on a **Scientific Summary** with research question, clickable **Guided Reading** steps, and **Checked Statistical Findings**; selecting a data group computes **Group Summary Statistics** (`mean`, `range` with units from `data_dictionary`); selecting an observation leads with measured values + units, domain context/citations, interactive peer comparison button (`Compare with Hornet 4 Drive`), statistical verification, and a collapsed `Technical provenance & audit details` footer.
  - Compacted Outline indentation and hover-revealed action icons so entity and subgroup labels render cleanly without truncation.
- **Interaction-driven behavior (`workbench/src/components/stage/FigureStage.tsx`)**:
  - Default `reader` landing state starts with empty selection (`selectedElementIds: []`), leaving the original `svglite` SVG completely uncluttered except for whisper-quiet dotted cue rings on annotated marks.
  - Static contextual pills and leader callouts are no longer stamped over the figure in `reader` mode; instead, hovering points reveals unit-aware tooltips with interaction hints, hovering/clicking SVG legend keys (`4`, `6`, `8`) displays `"Click to filter N observations"` and filters the matching data group across panels, clicking/hovering linked points reveals one deduplicated comparison arc (`6-cyl: manual vs auto`), and the `Story` lens drives an interactive floating step-by-step bar (`Step 1 of 3`, persisted in Zustand across `Data` drawer toggles).

### Measured

- **TypeScript & Vitest:** `tsc --noEmit` (0 errors); Vitest `2 files, 6 passed, 0 failed` (610 ms), including humanized exception labels (`am = 0 · cyl = 4`), `humanizeToken()`, and `humanizeOutlineLabel()`.
- **Single-file builds & demo:**
  - `full`: `2,422.75 kB` (`696.60 kB` gzip; `inst/workbench/workbench-full.html.gz` = `677 KB`).
  - `lite`: `2,026.79 kB` (`593.94 kB` gzip).
  - `dev_docs/demo/mtcars-workbench.html`: `2,450,161` bytes; `gl_read()` round-trip identical (`elements: TRUE`, `bindings: TRUE`, `records: 10`).
- **Full R test suite (before → after):**
  - Before: 25 files, `1642` passed, `0` failed, `0` warnings, `8` sandbox skips.
  - After (`R_LIBS_USER=/nonexistent NOT_CRAN=true Rscript -e "devtools::test()"`): **25 files, `1646` passed, `0` failed, `0` warnings, `8` sandbox skips** (`aisdk` 5, `sf` 1, `showtext` 2), including new `view = "reader"` / `view = "inspector"` tests in `test-workbench.R` (`16` pass) and `test-workbench-live.R` (`19` pass).
- **Live Chromium verification (`http://127.0.0.1:4188/mtcars-workbench.html`, `1440×900`):**
  - `0` console errors, `0` uncaught page errors.
  - Verified clean uncluttered initial landing state (`Scientific Summary` + `Guided Reading (3 steps)` + `Checked Statistical Findings`, 0 static boxes/arcs on SVG), SVG legend hover tooltip + click group filter (`cyl = 6` with Group Summary Stats), Story stepper persistence on `Step 2 of 3` across `Data` drawer open/close, single deduplicated comparison arc + `Compare with Hornet 4 Drive` interactive jump on clicking `Mazda RX4`, and non-overflowing citations.

### Surprises

- **Toggling the `Data` drawer unmounted `FigureStage` and reset local Story stepper state from Step 2 back to Step 1.** Caught during live browser testing because `App.tsx` switches between `<PanelGroup><FigureStage />...</PanelGroup>` and `<FigureStage />`. Fixed by moving `storyStepIdx` into Zustand (`useWorkbenchStore.ts`) and re-verified in Chromium (`staysOnStep2AfterDataOpen: true`).
- **Default `vite build` builds the SPA (`dist/`), not `dist-singlefile/index.html`.** Single-file and lite builds require `--config vite.singlefile.config.ts` (and `VITE_WORKBENCH_MODE=lite`). Caught immediately from Vite output before syncing `inst/workbench/workbench-full.html.gz`.

---

## Follow-up update (2026-11-19 — 5 High-Difficulty Scientific Cases & Engine-Grade Workbench Hardening)

- **Triggered by:** Owner asked to push far beyond `mtcars` ("上难度") and build all 5 high-difficulty scientific / pharma / bioinformatics showcase cases.

### What changed

- **5 Reproducible High-Difficulty Showcase Scripts + Gallery Launcher (`dev_docs/demo/cases/`, `dev_docs/demo/index.html`)**:
  1. `case1-clinical-trial.R` (`patchwork`, real `survival::colon`, `n = 929`): Kaplan-Meier OS curves + 95% CI ribbons + 1–5y landmarks paired with a 10-subgroup Cox PH forest plot (`NEJM 1990` context; verified arm trend + partial subgroup CI check surfacing 6 inconclusive subgroups; cross-panel `5y OS -> Overall HR 0.69` link).
  2. `case2-rnaseq-volcano.R` (`patchwork` + `ggrepel`): 2,400-gene Anti-PD-1 melanoma differential expression volcano plot paired with Hallmark/GO GSEA enrichment dotplot (`GO`/`MSigDB` ontology; verified DE counts + partial pathway check surfacing 4 resistance/exclusion programs; `CXCL9 -> IFN-gamma` and `CTNNB1 -> WNT` links).
  3. `case3-scrna-umap.R` (`patchwork`): 1,800-cell TME UMAP atlas (8 Leiden clusters) + 8×10 canonical marker dotplot (`Cell Ontology CL:*`; verified cluster sample sizes + partial marker cutoff check flagging `M1 Macrophage`; explicit `speculative` hypothesis badge on M2 TAM).
  4. `case4-pkpd-er.R` (`patchwork`): 48-patient 4-cohort oral kinase inhibitor PK concentration-time spaghetti curves (`geom_line` multi-row bindings) + therapeutic window (`120–450 ng/mL`) paired with RECIST Exposure-Response scatter (`FDA Project Optimus`; verified E-R shrinkage trend + partial cohort safety ceiling check flagging `200 mg QD` and CYP3A4 poor metabolizer `PT-100-09`).
  5. `case5-multiomics-heatmap.R` (pure `ComplexHeatmap` / `grid`, non-ggplot2): 24 PAM50 genes × 36 breast tumor biopsies (`864` vector cells, `use_raster = FALSE`) split into 3 gene modules × 3 molecular subtypes with clinical top annotations (`Subtype`, `ER`, `Stage`, `Ki-67 %` barplot) and hierarchical dendrograms (`St. Gallen` pathology context; verified `LumA_04` range check + partial `LumA_11` range check flagging discordant `MKI67 = +2.35`).
- **Engine-Grade Codec & Workbench Fixes Uncovered by Stress Testing**:
  - `workbench/src/codec/decodeBundle.ts`, `types.ts`: added `buildMatrixCellIndex()` (`matrixCellByElement`) decoding `engine-heatmap.R` column-major flat indices `(col - 1) * nrow + row` into exact `(rowLabel, colLabel, value)` cells and indexing matrix rows so clicking a gene row in AG Grid highlights all 36 cells across the heatmap; rewrote `inferRawJoins()` to O(N) hash-indexed multi-plot `patchwork` lookup (`plot{k}_built_layer* -> plot{k}_raw`) supporting continuous `(x, y)` pairs, discrete×discrete dotplots, and continuous×discrete forest/pathway plots; normalized all 6 `gl_check()` schemas (`trend`, `count`, `compare`, `range`, `value`, `exists`) so row-level checks never have `undefined` group keys.
  - `workbench/src/codec/spatial.ts`: prioritized exact point-in-box containment for edge-to-edge `ComplexHeatmap` tiles and dense scatterplots.
  - `workbench/src/codec/outline.ts`, `humanize.ts`, `ReaderInspector.tsx`, `RightInspector.tsx`, `DataWorkbenchGrid.tsx`, `OutlineTree.tsx`, `FigureStage.tsx`, `App.tsx`: per-raw-table `patchwork` group naming; continuous-gradient guard (`> 16` swatches skips hex-color explosion); `ComplexHeatmap` slice/cell inspection and `zscore Matrix` grid tab; multi-panel `Panel 1 Data` / `Panel 2 Data` reader tabs; check-kind-aware metric formatting (eliminating `(n = undefined)`) with failed-first collapsible lists for wide checks; responsive top-header title truncation preventing badge overlap; downward-bowed comparison arcs when endpoints sit in the upper 36% of the figure.

### Measured

- **Showcase artifacts (all `gl_read()` round-trip identical = `TRUE`)**:
  - Case 1 (`case1-clinical-trial.html`): `2,472,012` bytes | `128` elements | `38` verified | claims: `1 verified (3/3)`, `1 partial (4/10 pass, 6 fail)`.
  - Case 2 (`case2-rnaseq-volcano.html`): `2,659,612` bytes | `2,512` elements | `1,381` verified, `1,039` ambiguous (dense overlap, `0` failed) | claims: `1 verified (3/3)`, `1 partial (6/10 pass, 4 fail)`.
  - Case 3 (`case3-scrna-umap.html`): `2,614,918` bytes | `1,981` elements | `1,708` verified, `172` ambiguous (`0` failed) | claims: `1 verified (8/8)`, `1 partial (7/8 pass, 1 fail)`.
  - Case 4 (`case4-pkpd-er.html`): `2,472,560` bytes | `175` elements | `101 / 101` verified (`0` ambiguous, `0` failed) | claims: `1 verified (1/1)`, `1 partial (3/4 pass, 1 fail)`.
  - Case 5 (`case5-multiomics-heatmap.html`): `2,523,240` bytes | `1,445` elements | `864 / 864` verified (`0` ambiguous, `0` failed) | claims: `1 verified (24/24)`, `1 partial (18/24 pass, 6 fail)`.
- **Frontend & R verification**:
  - `tsc --noEmit`: 0 errors; Vitest: `2 files, 7 passed, 0 failed` (added regression test decoding real `case5-multiomics-heatmap.html`, asserting `864` matrix cells, `MKI67 × LumA_11 = 2.35`, and zero `"undefined"` labels).
  - Single-file builds: `full` = `2,433.44 kB` (`699.82 kB` gzip; `inst/workbench/workbench-full.html.gz` = `680 KB`); `lite` = `2,037.32 kB` (`597.33 kB` gzip).
  - Full R test suite (`R_LIBS_USER=/nonexistent NOT_CRAN=true Rscript -e "devtools::test()"`): **25 files, `1646` passed, `0` failed, `0` warnings, `8` sandbox skips** (unchanged before → after: `1646 → 1646`).
  - Live Chromium (`1440×900`) verification across all 5 cases + `index.html`: **0 console errors, 0 uncaught page errors, 0 `"undefined"` strings**; confirmed Case 5 `ComplexHeatmap` cell spotlight (`MKI67 × LumA_11`), `zscore Matrix` (`24` rows), Case 1–2 header clearance & arc routing.

### Surprises

- **Row-level `gl_check()` plugins (`range`, `value`, `exists`) return `{ row, value, passed }` with NO `group` column, and `check_compare` returns `{ group, left, right, passed }` with NO `n` column.** The first browser test on Case 5 (`ComplexHeatmap` with `check_range`) immediately threw `TypeError: Cannot read properties of undefined (reading 'includes')`, and Cases 1–4 displayed `(n = undefined)` on `check_compare` exceptions. Fixed universally in `normalizeCheck()`, `humanizeCheckGroupLabel()`, `resolveCheckGroupElements()`, `outline.ts`, `ReaderInspector.tsx`, and `RightInspector.tsx`, and locked down with a Vitest regression test on Case 5.
- **`gl_check()` `by` argument must be an atomic character vector (`c("arm")`), not a list (`list("arm")`).** Passing `list(...)` caused `semantic_check_groups()` (`table[by]`) to return `refused: invalid subscript type 'list'`. Caught by our R claim audit script before browser testing.
- **`ComplexHeatmap` body bindings use flat column-major matrix indices `(col - 1) * nrow + row` in `bindings$row`, and continuous heatmap fill gradients exceed discrete group palettes.** Adding dedicated `matrixCellByElement` decoding and guarding `inferDataGroups()` against `> 16` unique hex colors turned `ComplexHeatmap` into a first-class interactive workbench citizen.

---

## Follow-up update (2026-11-20 — Reader view speaks the reader's language, not gloss's)

- **Triggered by:** Owner, looking at Case 5: gloss's own terms (`claim`, `gl_check`, layers) were being shown to readers as UI ("我们的专业术语直接应用到了交互中，这是不对的"). A failed `range` check was titled `Statistical Finding` above the very sentence the data contradicted.

### What changed

- Reader Outline is now figure-first (`Groups` / `Heatmap Regions` / `Panels`, `Highlights`, collapsed `Figure Layout`) via a new `buildOutlineTree(bundle, "reader")`; gloss layer folders (`Statistical Findings`, `Entity Context`, `Comparisons`, `Guided Story`) only appear in Inspector.
- Claims render as `Key Takeaways` prose with a collapsed one-line data check from `summarizeCheckForReader()` (`Confirmed across all 24 items`, `18 of 24 match · 6 exceptions · Inspect 6`, `Not supported by source data`). Partial/failed checks are never shown as confirmed; the evidence rows stay one click away and still spotlight the figure.
- Top bar: removed the 4-lens switcher and the `Exception` pill; replaced with `Walkthrough` (optional, dismissible), `Clean view`, `Data`, `Reader | Inspector`. Long titles truncate instead of pushing actions off screen.
- Right panel: no `Analyst Note`, `Confidence %`, `ZSCORE SLICE 3_1`, `Feature / Row`; speculative notes carry a quiet `Working hypothesis` tag. Background tab renders `Variable Guide`, `References`, `Terminology & Ontology`, `Study Details` as prose instead of snake_case headers and JSON.
- Showcase claims rewritten to state what the data shows (e.g. Case 5 `LumA_11`: five expected Luminal/ER drivers plus one discordant `MKI67 = +2.35`), and walkthrough text no longer instructs UI clicks.

### Measured

- `tsc --noEmit` 0 errors; Vitest `2 files, 7 passed` (new assertion: Reader outline for Case 5 contains `Heatmap Regions` / `Highlights` and none of `Entity Context`, `Statistical Findings`, `Natural-Language Semantics`).
- Shell `full` `2,438.42 kB` (`700.03 kB` gzip); `lite` `2,042.40 kB` (`598.12 kB` gzip). All 6 showcase HTMLs regenerated, `gl_read()` round-trip `TRUE`.
- Targeted R tests: `test-workbench.R` 15 pass, `test-workbench-live.R` 19 pass (no `R/` or `tests/` change in this unit).
- Chromium 1440×900: Cases 1 and 5 have 0 console/page errors and 0 occurrences of the forbidden jargon list on the landing screen; `Inspect 6` expands/collapses; Case 1 long-title header overflow found and fixed.

### Surprises

- Removing the lens switcher exposed that the long Case 1 title had been held in check only by the switcher's fixed width; the header needed `overflow-hidden` + `flex-1 truncate` on the title. → `workbench/src/App.tsx`.
