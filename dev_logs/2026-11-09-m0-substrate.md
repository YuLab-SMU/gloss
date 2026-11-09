# 2026-11-09 — M0: the substrate in code

- **Related plan:** [plan/2026-11-09-m0-substrate.md](../plan/2026-11-09-m0-substrate.md) (active; Task 9 open)
- **Related ADRs:** [ADR-0004](../dev_docs/decisions/0004-engine-dispatch-through-the-registry.md) (new), [ADR-0005](../dev_docs/decisions/0005-bundle-format-v0.md) (new), [ADR-0003](../dev_docs/decisions/0003-plugin-based-core.md) (status line amended), [ADR-0001](../dev_docs/decisions/0001-capture-by-group-delimiting-and-probes.md) (implemented)
- **Worked on by:** Yonghe Xia, Claude

## What changed

The package has code. `gloss(x)` captures a figure into a substrate; `gl_write()` and `gl_read()` move it through a directory or a single HTML or SVG file without loss.

| File | What it does |
|---|---|
| `R/core-plugin.R`, `R/core-schema.R` | registry for the eight kinds, validation on registration, the schema language, `gl_test_plugin()` contracts |
| `R/core-substrate.R` | probe + `groupGrob()` wrapping, `<use>` inlining, element and leaf tables, per-leaf counts, dense rasters, `gloss()` |
| `R/core-data.R` | tables, the five row-key rules, `gl_key()` |
| `R/core-codec.R`, `R/core-bundle.R` | lossless JSON and binary encodings, bundle files, packing, restore |
| `R/core-context.R`, `R/context-*.R` | six sniffers: code, data, engine, env, doc, git |
| `R/engine-*.R` | ggplot (built data, facet panels, scales), patchwork (tables), heatmap (matrices, orders, body panels), base (gridGraphics windows), grid |
| `R/project-html.R`, `R/project-svg.R` | single-file projections with the bundle embedded |
| `R/identify.R` | `gl_elements()`, `gl_leaf()`, `gl_panels()`, `gl_hit()`, `gl_near()`, `gl_overlap()`, `gl_to_pixel()`, `gl_to_data()` |

## The completion criteria, measured

1. **Six input classes match plain svglite.** ggplot facets with a smooth, patchwork, base through gridGraphics, ComplexHeatmap, ggrepel and 10^4 points: the captured scene draws the same primitive sequence (tag, attributes, text), and only the device background has no leaf. The faceted mtcars plot gives the spike's numbers again: 134 elements, 62 leaves, 6 count mismatches (gridlines with NA breaks and NaN ribbons).
2. **Lossless round trip.** Directory → HTML → directory and directory → SVG → directory are byte-identical. `gl_read(gl_write(fig))` is `identical()` to `fig` in substrate, tables, meta, plugins and status.
3. **10^5 points under 3 MB.** 2.65 MiB as a single HTML file with default embedding (random normal data, 7 × 5 in). Plain svglite of the same plot is 8.3 MB.

## Things the design did not anticipate

- **svglite reports group support as `compositing`,** not as a `groups` capability. The device check looks for compositing operators.
- **The scene is forced on one page and drawn on the next,** so `svgstring()` returns two pages; capture keeps the last.
- **Masks are lost inside groups.** R does not apply an active viewport mask to a graphics group, so a masked leaf would be drawn unmasked. The per-leaf counts do not catch this, because the element counts are right. Capture now refuses figures whose SVG defines a mask. Gradient and pattern fills, clipping paths and gTree-level alpha were checked and capture unchanged.
- **A rect in a rotated viewport is drawn as two polygons,** fill and border. The count check refuses to bind it, as designed; it is a new entry for the failure taxonomy.
- **jsonlite's `digits = NA` writes 15 significant digits,** which is not lossless. Doubles are now written with the shortest of 15 or 17 digits that parses back exactly, checked through jsonlite itself, and always with a decimal point so that `7` comes back as a double.
- **The size target was missed on the first encoding:** 2.99 MiB with decimal JSON, which is under 3 MiB with no margin. Large numeric columns became binary, the dense index stores width and height instead of x1 and y1, and both are byte-plane shuffled before zlib (Blosc/HDF5's filter). That gave 2.65 MiB. Built columns identical to raw columns (`x` = `wt`) are stored once as references.
- **`substring()` stops at 1,000,000 characters by default.** Reading a 3 MB HTML file lost the closing `</script>`; fixed by passing the end explicitly.
- **A `return()` inside a contract-check expression** returned from the enclosing function, because the expression is a promise evaluated in the caller's frame. Checks now use `if`/`else`.
- **Style parsing dominated capture time** for 10^5 points (4.9 s of the substrate build). Parsing distinct style strings only brought it to 1.8 s. Capture of 10^5 points is about 4.5 s in total, most of it svglite drawing.

## Verification

- `NOT_CRAN=true Rscript -e "devtools::test()"`: 7 files, 45 tests, 268 expectations, 0 failures, 0 skips.
- `R CMD build --no-build-vignettes` and `R CMD check --no-manual`: 0 errors, 0 warnings, 0 notes once `NEWS.md` used a numbered version heading (R's NEWS parser does not read "(development version)").
- Every built-in plugin passes `gl_test_plugin()`; a toy third-party engine registered in a test is dispatched by class and passes its contract.
- The README example was run as written.
- `quarto render dev_docs/design.qmd --to html`: renders; the only warning is a failed Google Fonts download. No unresolved cross-references.

## What's next

- **Task 9 of the plan, before M1 starts:** sample the benchmark (R Graph Gallery, extension package examples, Bioconductor vignettes, TidyTuesday), stratified by engine and chart type, 100–200 figures with code and data, seed recorded; count attempted and retained figures with failure reasons; split development and held-out sets; freeze with a commit.
- Masks: decide whether to support them (re-apply the mask to the inlined group, then check the result against plain svglite) or keep refusing.
- M1: rule sets, guides, structure and data trees, and the element ↔ row binding that the per-leaf counts already gate.
