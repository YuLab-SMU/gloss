# gloss Workbench (`@gloss/workbench`)

Browser-based semantic artifact viewer and inspector for `gloss` R figure bundles.

## Capabilities

- **Zero-client, 100% local decoding (`src/codec/`)**: Decodes any `.html` or `.svg` file written by `gl_write()` / `gl_workbench()`, or any `.gloss/` bundle directory, directly in the browser using native `DecompressionStream("deflate")` and Web Crypto `SHA-256` integrity verification.
- **Untouched original SVG geometry (Principle 1)**: Mounts `substrate/scene.svg` verbatim with a synchronized, non-destructive `viewBox` overlay layer, pan/zoom, Before/After curtain comparison, and a **Flatbush** spatial index supporting dense-leaf `index.bin` bundles (`10^5+` marks).
- **9-Stage Semantic Ladder Rail**: Step cleanly from `Raw SVG` → `Structure` → `Binding` → `Analytical Meaning` → `Contextual Meaning` → `Relation` → `Claim` → `Narrative` → `Behavior`.
- **AG Grid Community Multi-Table Workbench**: Virtualized tables for `raw`, `built_layer*`, `Bindings`, `Elements`, `Roles`, and `Records` with pinned row-key columns, R special-value badges (`NA`, `NaN`, `Inf`, `-Inf`), deviation meters, CSV export, and bidirectional brushing & linking with the SVG canvas.
- **Evidence Chain & React Flow Lineage DAG**: Inspect substrate facts, checked bindings, inferred raw links, external contextual provenance (`source`, `source_type`, `confidence`, `evidence`), interactive per-group `gl_check()` evidence matrices (click an exception group to highlight its points on the SVG), and interactive provenance graphs.
- **Rive State-Machine Adapter (`src/components/rive/`)**: Integrates `@rive-app/react-canvas` with dynamic SVG state-machine fallbacks. Place custom authored `.riv` files into `public/rive/` (or configure via `window.__GLOSS_WORKBENCH_CONFIG__.riveAssets`) to hot-swap the Stage Rail, Verification Seal, and Dropzone Unfold animations without code changes.
- **CodeMirror 6 & Projections**: Read captured R plotting code, append-only `layers/*.jsonl` logs, and copy/download live WAI-ARIA, Plain-Text, and W3C Web Annotation JSON-LD projections.

## Commands

```bash
pnpm --dir workbench install
pnpm --dir workbench run dev               # Start universal drop-in SPA dev server
pnpm --dir workbench run test              # Run Vitest codec & bundle verification tests
pnpm --dir workbench run typecheck         # TypeScript strict check
pnpm --dir workbench run build             # Standard SPA build -> workbench/dist/
pnpm --dir workbench run build:singlefile  # Full single-file HTML shell -> workbench/dist-singlefile/
pnpm --dir workbench run build:lite        # Zero-WASM lite HTML shell -> workbench/dist-lite/
pnpm --dir workbench run sync:r            # Rebuild single-file shell and sync inst/workbench/workbench-full.html.gz
```

## Generating a Standalone Workbench from R

```r
library(gloss)
# After building fig (and optionally running gl_record / gl_annotate / gl_apply):
gl_workbench(fig, "mtcars-workbench.html")

# The resulting standalone HTML remains 100% lossless and readable back into R:
fig2 <- gl_read("mtcars-workbench.html")
```
