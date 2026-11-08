# Semantic SVG export: prior art and measured evidence

> Companion to [2026-11-07-agentic-semantic-svg.md](2026-11-07-agentic-semantic-svg.md).
> **History.** Written while the idea was incubated inside ggai; "ggai" below means the host package at the time, now gloss. The methodology-only decision at the end of §1 carries over unchanged: gloss takes no dependency on the surveyed packages and copies no code from them. "Plan Task 2" refers to the [closed ggai plan](https://github.com/YuLab-SMU/ggai/blob/main/plan/done/2026-11-07-semantic-svg-phase-1-skeleton.md); the capture mechanism it asked for is now [ADR-0001](../dev_docs/decisions/0001-capture-by-group-delimiting-and-probes.md).
> Date: 2026-11-07. Owner: Yonghe Xia. Rewritten 2026-11-08 to put findings first and to give every prior work its result and its limit; no measurement changed.
> Method: four parallel investigations (device tagging, raster hit-testing, spec translation, literature), each combining source reading with two reverse-engineering tools, [REA](https://github.com/morluto/rea) 6.8.0 and [Craft Anything](https://github.com/storytold/craft-anything) 0.5.0, for runtime evidence.
> Raw reports, scripts and captures are archived in [`dev_docs/research/`](../dev_docs/research/README.md), including `reports/{ggiraph-gridsvg,shiny-static-interaction,translation-canvasxpress-plotly,literature-ecosystem}.md`. The full Chinese report is [`dev_docs/research-report.qmd`](../dev_docs/research-report.qmd).

**How to read the numbers.** Counts, pixel diffs and recovery rates were measured by us on 2026-11-07 with the scripts in `dev_docs/research/`. Literature results are the authors' own figures, as recorded in the research report's comparison table; we did not re-run them.

## Findings

Every existing family is strong on one axis and stops at a boundary we could measure. None combines faithful geometry, an open world and semantics checked against data.

![Schematic. A small scatter plot on the left sends four lanes to the right: redraw in another engine, hit-test a raster image, tag elements at the device, ask a model to read the SVG. Each lane ends at a red bar labelled with its boundary: the figure changes, the row is guessed, unknown layers get no data, nothing checks the answer. A dashed blue box on the right, reached by no lane, reads: same geometry, any input, checked against data.](figures/prior-art-routes-v4.png)

*Figure 1. **Every existing route stops at a boundary.** Schematic (AI-generated), not data. Each lane is one family from the table below, and each red label is the boundary we measured or found reported. plotly and canvasXpress drifted 6–32% of pixels (§3). Shiny recovered 0 of 32 rows under `coord_polar` (§2). maidr's unknown-layer processor returns empty data (§1). On R charts, GPT-4o and DeepSeek-V3 reach element-role F1 of 0.692 and 0.959, and nothing checks either answer (§4). Prompt, rounds and the one pixel fix: [`figures/prior-art-routes-v4.prompt.md`](figures/prior-art-routes-v4.prompt.md).*

1. **Redrawing in another engine changes the figure, sometimes without a warning.** On five test figures, plotly and canvasXpress differed from the original by 6–32% of pixels. plotly kept only the last panel of a patchwork and dropped all 32 ggrepel labels; canvasXpress turned a forest plot into a bar chart with the axes swapped (§3).
2. **Hit-testing a raster guesses the row, and the guess fails off the easy path.** Shiny's `nearPoints` recovered 32 of 32 rows on eight plain layouts, but 1 of 32 with `geom_jitter`, 0 of 32 under `coord_polar`, and 0 of 32 for any layer after the first (§2).
3. **Device-level tagging gets geometry and grob identity exactly, but binds data only where someone wrote a processor.** maidr has about 40 per-geom processors, and its unknown-layer processor returns empty data. Wrapping every leaf grob in ggiraph's tracer tagged 133 of 134 primitives with byte-identical geometry (§1).
4. **Reading the SVG with a model works on any input, and nothing checks the answer.** On the R charts in VisAnatomy, element-role F1 is 0.692 for GPT-4o and 0.959 for DeepSeek-V3, and neither model can tell which of its answers are wrong (§4).

What is left to build, and what is not:

- **Still open:** data binding for layers no processor knows, proposed by an agent and verified against built data; meaning and relations between elements (legend key ↔ series, label ↔ point, bracket ↔ group pair, annotation track ↔ cluster) as first-class output; a per-figure interaction design chosen from a closed vocabulary; a verification gate.
- **Already done elsewhere:** grob ↔ SVG element tagging (ggiraph, gridSVG, maidr), LLM role labelling (VisAnatomy, CSL), ARIA output (Vega, maidr).

| Family | Examples | Geometry | S1 structure | S2 data binding | S3 meaning | S4 interaction | World |
|---|---|---|---|---|---|---|---|
| **Spec translation** (redraw in another engine) | `plotly::ggplotly`, canvasXpress | Redrawn; measured drift 6–32% of pixels | Trace ↔ layer | Partial; raw rows need `highlight_key()` | none | Engine's fixed set | Closed. Unsupported input is dropped, often silently. |
| **Raster + data-space hit test** | Shiny `plotOutput` + `nearPoints` | Exact (PNG) | Panel only, ggplot only | Nearest-neighbour guess at query time | none | Click/brush/hover | Closed |
| **Raster + recorded positions** | InteractiveComplexHeatmap | Exact (PNG) | Heatmap/slice | Exact for matrix cells | none | Fixed | ComplexHeatmap only |
| **Device-level tagging** | ggiraph `dsvg`, gridSVG, **maidr** | Exact | ggiraph: three-way role split. gridSVG and maidr: every grob. | ggiraph: `*_interactive` geoms only. maidr: about 40 hand-written geom processors. | ggiraph: user tooltip text | Fixed menu (ggiraph) or a11y runtime (maidr) | Closed. Unknown layers get no data. |
| **SVG deconstruction, heuristic or LLM** | DIVI, Mystique, VisAnatomy baselines, CSL, Athanor | Kept | Inferred (role F1 about 0.84; on R charts GPT-4o 0.692 vs DeepSeek-V3 0.959) | Inferred | LLM, unverified | NL-authored or fixed | Open, but ungrounded |

> Naming note: "Semantic SVG / SSVG" is already used by CSL (arXiv 2026), and "L1–L4" is Lundgard & Satyanarayan's model of semantic content in chart descriptions (TVCG 2022). The idea doc therefore uses **S0–S4** for our levels.

## 1. Device-level tagging is exact, and binds data only for known geoms: ggiraph, gridSVG, maidr

### ggiraph (0.9.2 installed; source 0.9.7.007)

**How it works.**
- `layer_interactive()` swaps in `GeomInteractive*` and carries `data_id` and `tooltip` through `ggplot_build` as ordinary aesthetics (`R/layer_interactive.R:6-81`).
- `draw_panel` adds the class `interactive_<cls>_grob` (`R/ipar.R:217-334`).
- `drawDetails.interactive_*_grob` turns a C++ tracer on, draws, and turns it off (`R/interactive_points_grob.R:18-25`). While the tracer is on, the `dsvg` device records each element it creates (`src/dsvg_dev.cpp:117-120`, spot-checked). Value *i* is then assigned to the *i*-th emitted element (`R/tracers.R:42-87`).

**What we measured.** Wrapping *every* leaf grob of the spike plot in the tracer tagged **133 of 134** primitives. The one exception is the device's own background rect. Spot-checked: each element carries `data-ggai-path` (full grob path), `data-ggai-i` (index within the grob) and `data-ggai-class`. Once the ids are stripped, the geometry is byte-identical to plain `print(p)`.
- The same method on other engines: patchwork 139/140, base graphics via `gridGraphics` 63/64, ComplexHeatmap 227/228.
- In ComplexHeatmap, the meaning sits in viewport names (`z_heatmap_body_1_1`, `z_dend_row_1`, `annotation_cyl_1`).

**The count check makes draw order checkable.** 6 of 62 leaves emitted a different number of elements than expected. All of them were grid lines with NA breaks or a NaN ribbon; none were data marks. With a tracer, the draw-order risk shrinks from "align the whole SVG" to "check the count inside each grob".

**Where it stops.**
- **Silent misbinding.** Labels `"a\nb\nc"` and `"d"` emit 4 text elements. Line "c" gets the second label's id, with no warning (Figure 2).
- **A count mismatch drops everything.** 4 elements for 3 ids: ggiraph warns and drops them all.
- **Overlap blocks clicks.** Clicking "Valiant" selected "Merc 280C".
- **Unstable ids.** The canvas id is random and `_eN` is a running counter.
- **Untagged by default.** Without the tag-everything wrapper, plain ggplot layers, base `plot()` and ComplexHeatmap (0 of 212 elements) get no ids.

![Schematic. Left card, "By order: the i-th id goes to the i-th element": four letter tiles a, b, c, d tagged id 1, id 1, id 2 and id 2; the id 2 under c is red with a cross, and a red line reads "c gets the second label's id, with no warning". Right card, "By group: the device puts each element in its group": a, b and c sit in a dashed blue box labelled group 1, d alone in group 2, with a green tick.](figures/prior-art-order-v1.png)

*Figure 2. **Assigning ids by order misbinds silently; grouping does not.** Schematic (AI-generated), not data; the case is the measured one above. ggiraph recycles 2 ids over 4 elements with `rep(each = )` and assigns them in order, so line c gets id 2. When the device puts each leaf's output in its own group, membership comes from the device, not from order. This is the mechanism gloss adopted (design doc, ADR-0001). English twin of the design doc's figure. Prompt: [`figures/prior-art-order-v1.prompt.md`](figures/prior-art-order-v1.prompt.md).*

**JS runtime.** One delegated listener sits on the `<svg>` root (Craft `web-listeners-list`: 0 listeners on marks, 5–6 on the root, all pointing to `MouseHandler.handleEvent`). Elements are found with attribute selectors and styled by toggling classes; non-interactive marks get `pointer-events: none`.

### gridSVG (CRAN 1.7-7, 2025-10-31)

**What we measured.** It works with ggplot2 4.x. Export takes about 0.5 s, and 1.12% of pixels differ from svglite. Element ids are indexed by data, e.g. `geom_point.points.190.1.3`, and a selector/XPath mapping file is written alongside.

**Where it stops.**
- Grob names carry session counters, so ids are not stable across runs.
- The default `strict=TRUE` strips `data-*` attributes.
- `grid.garnish` must run after `grid.force()`.

### maidr (CRAN 0.5.0, 2026-09-29, GPL-3; mechanism spot-checked)

**How it works** (`R/svg_export.R`):
1. `grid.force()` + `grid.grab()` the scene.
2. Walk it the way gridSVG does, redrawing each grob onto svglite. Before each draw call, insert an invisible text marker `@@maidr-svg-mark@@k`.
3. Read the markers back and remove them.

The result is gridSVG-compatible `<g id="<name>.<k>">` with exact geometry. This also solves draw-order alignment without a custom device.

**Where it stops.**
- Data comes from about 40 per-geom processors across ggplot2, base R, lattice, patchwork, pheatmap and ComplexHeatmap (heat cells, simple annotations and dendrograms; marked experimental).
- `Ggplot2UnknownLayerProcessor` returns empty data and empty selectors, so the system is closed-world.
- The runtime is a fixed accessibility layer: keyboard navigation, screen reader, sonification, braille.

**What this family leaves open.** Per-grob capture has now been shown feasible twice. Unknown layers, meaning, interaction design, relations and verification are not done by any of the three.

**Decision (2026-11-07).** These packages are methodological reference only. ggai takes no dependency on them, copies no code, and designs its own capture mechanism (plan Task 2). They remain available as comparison baselines in dev scripts.

## 2. Raster hit-testing recovers rows only on the easy path: Shiny, InteractiveComplexHeatmap

### Shiny `plotOutput` (cited from the 1.14-dev source; ran 1.11.1, same coordmap code)

**How it works.**
- `getGgplotCoordmap` (`R/render-plot.R:579`) emits one entry per panel: data domain, pixel range, log base, and facet values.
- Column names come from the **first layer only** (`:704`, spot-checked).
- The coordmap is deliberately kept out of the DOM (`srcts/src/bindings/output/image.ts:111`, spot-checked).
- `nearPoints()` / `brushedPoints()` project the raw columns to pixels and filter by distance.

**What we measured.** We clicked the drawn position of each of 32 points and checked whether `nearPoints` recovered the right row:

| Case | Recovered |
|---|---|
| plain, facet_wrap, facet_grid, free scales, coord_flip, log, reverse, coord_fixed | 32/32 each |
| discrete x | 27/32 (the misses are the overplotted ties) |
| `geom_jitter` | 1/32 |
| `coord_polar` | 0/32 |
| any layer after the first | 0/32 |

![Schematic. Inside a plot card, three pairs of marks: a hollow grey circle (raw position) joined by a thin line to a solid dot (drawn, jittered position). A fourth solid dot, labelled "click", is far from its own hollow circle above it; a red dashed line runs from it to the nearest hollow circle, which is red, crossed out, and labelled "nearest raw row: a different row". Footer: "geom_jitter: 1 of 32 rows recovered".](figures/prior-art-hittest-v2.png)

*Figure 3. **Hit-testing guesses the row from the raw columns.** Schematic (AI-generated), not data; the footer is the measured result in the table above. `nearPoints()` projects the raw columns to pixels and returns the nearest row. `geom_jitter` moves each drawn point away from its raw position, so a click on a drawn point can land nearest to another row's raw position. Prompt and the rejected first round: [`figures/prior-art-hittest-v2.prompt.md`](figures/prior-art-hittest-v2.prompt.md).*

**Where it stops.**
- Engines without a real coordmap: patchwork, lattice, grid and ComplexHeatmap get a meaningless whole-image coordmap (a click on a live patchwork sent `x=0.5`). Base `par(mfrow)` maps only the last panel.
- Legend clicks are dropped. A brush cannot cross facets.
- Related upstream issues, all open: rstudio/shiny#2411, #1703, #2422, #2938, #2300.

### InteractiveComplexHeatmap

**How it works.** `htPositionsOnDevice` (`R/interactive.R:560`) records each heatmap block's device box with `deviceLoc` right after `draw()`. A click maps to a cell by fraction × slice size over the cluster order.

**What we measured.** 80,000 cells need only a 6-row, 4.5 KB position table, and the exact cell is recovered. It works off Shiny, on a plain PNG device (Figure 4).

![Schematic. Two heatmap slices, each inside a dashed blue box labelled "block boxes recorded after draw()", feed an arrow into a card titled "position table", captioned "6 rows, 4.5 KB for 80,000 cells". In the lower slice one cell is outlined in orange-red under a cursor, and a line from it reads "click → cell by fraction × slice size".](figures/prior-art-ich-v1.png)

*Figure 4. **Positions recorded after drawing map a click to the exact cell.** Schematic (AI-generated), not data; the numbers are the measured ones above. InteractiveComplexHeatmap records each block's device box right after `draw()`; a click's fraction across a block, times the slice size, picks the cell in cluster order. No guessing is involved, which is why it recovers the exact cell where Shiny's nearest-neighbour test does not (Figure 3). Prompt: [`figures/prior-art-ich-v1.prompt.md`](figures/prior-art-ich-v1.prompt.md).*

**Where it stops.** Annotation values are joined by index, for 4 annotation types only. Dendrograms, annotation tracks and legends cannot be clicked.

### Dense layers favour a raster plus an index (measured)

At 10^5 points:

| Output | Size |
|---|---|
| Plain svglite SVG (no ids yet) | 10.2 MB |
| PNG | 478 KB |
| Binary point index | 1.17 MB raw |

A raster plus an index is a viable fallback for dense layers.

## 3. Translating to another engine changes the figure: plotly, canvasXpress

### How they work

**plotly.** `ggplotly` → `gg2list` (a copy of the ggplot2 build pipeline, `R/ggplotly.R:216`) → `layers2traces`.
- Tooltips are built from the aesthetic mapping (`R/layers2traces.R:7-76`).
- An unsupported geom hits `geom2trace.default`, which emits a warning and returns `list()`, so the layer disappears (`R/layers2traces.R:986-994`, spot-checked).
- There is no patchwork method.
- `highlight_key()` attaches crosstalk keys, nested per summarised row for stat layers.

**canvasXpress.** `canvasXpress()` → `ggplot.as.list()` → `gg_cxplot()`, which ships raw data, aes, the flattened theme and a per-layer `{geom, stat, params}` list.
- The JS calls `geom_<name>` only if such a handler exists, so geoms without one are skipped with no warning. We found this in the restored 4 MB bundle with Craft `js-sources-restore`.
- 63 geom handlers. The engine re-fits smooths and re-places repel labels itself.
- The JS licence is source-available and free only while the attribution mark is visible: borrow ideas, don't depend on it.

### What we measured (700×500 px; diff = share of pixels off by more than 16 levels; SSIM in brackets)

| Figure | svglite baseline | plotly | canvasXpress |
|---|---|---|---|
| (a) facet + lm + colour + annotate | 1.6% (0.97) | 7.5% (0.82); data correct, legend keys lose the line | 24.7% (0.57). One black zig-zag through all fits, copied into both panels; annotation clipped (screenshot checked). |
| (b) patchwork | 2.2% | **only the last panel, no warning** (screenshot checked), 26.6% | both panels, 18.9%; tiny fonts, collisions |
| (c) ggrepel | 4.8% | warns, **all 32 labels dropped**, 6.5% | own label placement, 8.6%; no leader lines |
| (d) ComplexHeatmap | 2.0% | error, or blank when wrapped as a grob | error, or stack overflow when wrapped as a grob |
| (e) pointrange forest plot | 1.6% | correct, 5.7% | **silently a bar chart with the axes swapped** (screenshot checked), 31.8% |

![Three rows of real screenshots, three columns each. Patchwork: svglite shows both panels (2.2% of pixels differ); plotly shows only the box plot, framed red (26.6%); canvasXpress shows both panels (18.9%). ggrepel: svglite shows labelled points (4.8%); plotly shows points with no labels, framed red (6.5%); canvasXpress shows its own small labels (8.6%). Forest plot: svglite (1.6%) and plotly (5.7%) show point ranges; canvasXpress shows a bar chart with swapped axes, framed red (31.8%).](figures/prior-art-redraw-evidence.png)

*Figure 5. **Redrawing in another engine changed the figure, sometimes without a warning.** Real 700×500 screenshots from the 2026-11-07 experiments, for three of the five test figures. Columns: the svglite baseline, `plotly::ggplotly()`, `canvasXpress()`. Red frames mark the failures in the table above. Under each shot is the share of pixels off by more than 16 levels against the ggplot2 PNG, read from `dev_docs/research/translate/pixel_diffs.csv`. Built by [`figures/src/prior-art-redraw-evidence.R`](figures/src/prior-art-redraw-evidence.R).*

**A pixel diff alone cannot catch these failures.** plotly dropped every label and still scored better than canvasXpress. Verification needs per-layer element counts and row bindings as well.

## 4. The literature reconstructs charts after the fact; only D3 Deconstructor reaches the real data, and only for D3

Results below are the authors' figures as recorded in the research report (`research-report.qmd`, comparison table and references), which checked them against the primary sources. We did not re-run any of these systems.

| Work | Input | Recovers | Reported result | Where it stops |
|---|---|---|---|---|
| ReVision (Savva et al., UIST 2011) | Bitmap | Chart type; marks and data for bar and pie charts | Classification 96%; bar-chart data extraction 71% | Approximate data, closed set of chart types |
| D3 Deconstructor (Harper & Agrawala, UIST 2014) | Running D3 page | Data, mark attributes, mappings | Exact binding through D3's `__data__` | D3 only |
| Poco & Heer (CGF/EuroVis 2017) | Bitmap | Text roles, mark types, encoding spec | Text-role F1 ≥ 98% | Bitmap input, no element binding |
| ChartDetective (Masson et al., CHI 2023) | Vector PDF/SVG | Axes, series, data | Relative error 0.11% | Semi-automatic: a person guides it |
| Mystique (Chen et al., TVCG 2024) | SVG | Axes, legend, layout | Axes/legend > 85%, layout 96% | Heuristics plus a wizard; for layout reuse |
| DIVI (Snyder & Heer, TVCG 2024) | SVG from ggplot2, matplotlib and others | Axes, legend, marks, inferred data fields; an interaction taxonomy | Runtime heuristics; no accuracy figure recorded | Box plots, densities and smooths cannot be inferred from the SVG alone |
| VisAnatomy (Chen et al., TVCG/VIS 2025, https://github.com/hdi-umd/VisAnatomy) | 942 SVG charts from 50+ tools, including R | 383k labelled elements: type, role, grouping, encoding | LLM role labelling mean F1 ≈ 0.84; **on R charts, GPT-4o 0.692 vs DeepSeek-V3 0.959** (checked against arXiv 2410.12268 §3.1) | Labels are a corpus; the baselines have no ground truth at run time |
| CSL (arXiv 2606.09782) | Deployed SVG | Mark type, visual role, data role | Accuracy 0.82–0.86; grouping primitives before prompting beats prompting on the whole SVG | Has deterministic checks, but its only input is the SVG, so nothing is checked against the source data. Calls its output "SSVG". |
| Athanor (arXiv 2601.17736) | SVG | Roles, scales, a constraint model; NL-authored interaction | Case studies, no accuracy reported | No accuracy data |

Also related, with no result recorded in our notes: MSC (Liu, Chen & Hooker, TVCG 2025), which represents a visualization scene as manipulable semantic components.

CSL's grouping result supports sending the agent a compressed skeleton instead of the full SVG.

**Chart-to-code** (ChartMimic, Plot2Code, ChartCoder, ChartEdit). All of these regenerate the chart. On ChartEdit, GPT-4o scores 59.96 without the source code and 89.96 with it. Having the code is the single largest factor, which supports keeping code canonical.

**Accessibility.**
- WAI-ARIA Graphics Module 1.0 (W3C Rec 2018).
- SVG-AAM (Working Draft).
- Vega ≥ 5.11 ARIA output.
- Olli; Data Navigator (TVCG 2024); Chartability (CGF 2022); MAIDR (CHI 2024).

**Claim provenance.** Blanco, Zong & Satyanarayan (arXiv 2026) sort model-generated claims about charts into Direct, Derived and Speculative. In their example the chart shows 342 penguins while the source table has 344 rows, so a check has to run against the built, filtered data, not the raw table (research report, accessibility section).

## 5. Lessons for ggai (methodology only, no dependencies)

| From | Lesson | Why |
|---|---|---|
| ggiraph `dsvg` tracer, maidr marker walk | Capture elements per grob, not by whole-SVG draw order | Proven feasible; ggai designs its own mechanism (plan Task 2) |
| Our own tag-everything experiment | Per-leaf expected-vs-emitted count; **fail closed** | ggiraph's `rep(each=)` recycling misbinds silently |
| ComplexHeatmap viewports | Record the viewport path for every element | That is where heatmap semantics live |
| InteractiveComplexHeatmap | Panel and block boxes recorded from the viewport tree **after drawing** | Shiny's re-derived gtable maths breaks on every non-ggplot engine |
| InteractiveComplexHeatmap + Shiny scale measurement | Grid-like layers: block boxes + order vectors. Dense layers (≳10^4 marks): raster + binary index keyed by (layer, panel, built row). | 10^5-point SVG = 10.2 MB |
| plotly | Tooltip-from-aesthetics as a free default | Cheap baseline before the agent adds anything |
| crosstalk | Key/set model, with nested keys for stat layers | Our S2 group-key binding; interoperates with DT and plotly |
| ggiraph JS | One delegated listener on the root; attribute selectors; class toggling; `pointer-events: none` on decoration; nearest-mark picking | Small, proven runtime design |
| WAI-ARIA Graphics + Vega | Root `graphics-document`, panels as nested documents, layers/guides `graphics-object`, marks `graphics-symbol`; decoration hidden; no per-item ARIA on dense layers | Standard target for the compile step |
| maidr | What an accessibility runtime needs from the data (navigation order, per-series values) | Informs our a11y fields; interop with its schema is not planned |
| VisAnatomy | Role taxonomy plus its R subset as an evaluation set; "agent without skeleton" ablation against the published R-chart baselines (0.692 / 0.959) | External, citable benchmark |
| DIVI | Interaction taxonomy (target × type × input) as the closed S4 vocabulary | Constrains the agent's interaction design |
| Claim provenance work | Tag agent claims Direct / Derived / Speculative; verify Direct claims against built rows | Makes S3 auditable |

Two of these lessons have since changed in the gloss design. The VisAnatomy comparison is now a same-condition "SVG only" arm on gloss's own benchmark, with the published numbers kept as context only, because VisAnatomy has no plotting code for gloss to capture. Verification now covers every computable claim, Derived ones included. See [design §testing](../dev_docs/design.qmd#sec-testing) and [§verify](../dev_docs/design.qmd#sec-verify).

## 6. The reverse-engineering tools found what source reading could not

Source reading explained the mechanisms. The tools added real payloads, actual listener placement, silent drops and drift measurements.

| Use | Best tool | Notes |
|---|---|---|
| Wire payloads (websocket frames, click/brush inputs) | REA `capture-browser-scenario` | Kept the 181 KB coordmap frame and showed that a base-plot click sends nothing. No drag; clicks only at element centres. |
| Which element actually has listeners | Craft `web-listeners-list` | Decisive for ggiraph (0 on marks, 5–6 on the root). Both tools stop at jQuery's dispatcher for Shiny. |
| Reading a minified engine | Craft `js-sources-restore` + `js-function-explain` | Exposed canvasXpress's silent geom skip. REA `analyze-web-bundle` timed out on the 4 MB bundle (30 s and 240 s). |
| Source map recovery | REA `analyze-web-bundle` | Recovered 148 Shiny TS module paths, which proved the deployed JS matches the clone |
| Pixel comparison | Both | Identical changed-pixel counts on all 31 comparisons. REA screenshots were exact 700×500; Craft's were 756×469. |
| Static JS analysis of small bundles | Neither | Both missed ggiraph's single `addEventListener`. REA misread `Map.get('pointerover')` as network endpoints and timed out on the 310 KB 0.9.2 bundle. |

**Friction.**
- The Craft CLI does not keep a browser open between invocations. It has to be driven through MCP mode or an external CDP endpoint, and most page tools need `--deep`.
- Neither tool can hover or drag at coordinates; small Playwright/CDP scripts filled the gap.
