# Agentic semantic SVG export

> **History.** Written 2026-11-07 while the idea was incubated inside ggai, so "ggai" below means the host package at the time; that role is now gloss's. It was promoted to a [ggai plan](https://github.com/YuLab-SMU/ggai/blob/main/plan/done/2026-11-07-semantic-svg-phase-1-skeleton.md), which closed on 2026-11-08 as superseded when the work moved into this standalone package ([ggai ADR-0004](https://github.com/YuLab-SMU/ggai/blob/main/dev_docs/decisions/0004-semantic-figure-substrate-as-standalone-package.md)). The current design is [dev_docs/design.qmd](../dev_docs/design.qmd).
> Status: exploration, revised 2026-11-07 after the prior-art survey ([2026-11-07-semantic-svg-prior-art.md](2026-11-07-semantic-svg-prior-art.md)). Rewritten 2026-11-08 to put findings first and to record what became of each part (last section); the 2026-11-07 content and numbers are unchanged.
> Full standalone research report (Chinese, Quarto): [dev_docs/research-report.qmd](../dev_docs/research-report.qmd).
> Date: 2026-11-07. Owner: Yonghe Xia.

**Reading this note.** This is the founding sketch, kept for the record. The spike numbers were measured on 2026-11-07 with throwaway scripts; everything else (the pipeline, the levels, the evaluation) was a proposal that no code implemented. Several parts have since been replaced. Read [What became of it](#what-became-of-it-2026-11-08) before reusing anything here, and treat [design.qmd](../dev_docs/design.qmd) as the authority.

## The idea in one paragraph

An exported R figure knows its geometry and nothing else. ggai already holds what is needed to recover the rest: the plotting code, the data, the built data and the grob tree. So export can be split in two. A deterministic step tags every SVG element with the grob, panel and data row that produced it. An agent then adds what code cannot determine (bindings for unknown layers, meaning, relations, an interaction design), and every claim it makes that touches the data is checked before it reaches the output. **The agent annotates; it never redraws.**

![Archival collage. A glossed manuscript page with a crisp scatter plot as its central block. Four marginal notes in vermilion ink connect to four vermilion dots by straight leader lines. Three of those notes carry a small green tick; the fourth is struck through in red. The plot itself is untouched.](figures/agentic-svg-hero-v1.jpg)

*Figure 1. **The agent annotates; it never redraws.** Hero image (AI-generated), not data, in the same series as the design doc's hero. The central plot is untouched. The vermilion glosses stand for agent annotations, and their leader lines for anchors to single elements. A green tick marks a claim that passed its check against the data; the struck-through gloss is one the checks rejected. Prompt: [`figures/agentic-svg-hero-v1.prompt.md`](figures/agentic-svg-hero-v1.prompt.md).*

## What the spikes showed

1. **The exported SVG cannot tell data from decoration.** svglite drew 134 primitives with 0 ids. There were 35 circles for 32 rows; the 3 extras were legend keys.
2. **The draw order does follow the built data inside a panel.** Panel-1 circles matched `ggplot_build()` rows in order (Spearman 1.0). Draw order alone is still not a safe key, because one grob can emit a different number of elements than expected.
3. **Per-grob capture is feasible across engines.** Wrapping every leaf grob in ggiraph's tracer tagged 133 of 134 primitives with byte-identical geometry: patchwork 139/140, base graphics via gridGraphics 63/64, ComplexHeatmap 227/228. This was a feasibility check only, not the mechanism ggai would use.
4. **A per-grob count check catches misalignment without false alarms on data.** 6 of 62 leaves emitted a different count than expected, and none of them were data marks.

Full numbers and caveats are in [Spike evidence](#spike-evidence-2026-11-07) and the prior-art note, §1.

## Problem: every existing family stops at a fixed set of inputs

R figures (ggplot2, base graphics, grid, ComplexHeatmap, circlize, patchwork) export to SVG with geometry only. Nothing records which element is a data point, which is a legend key, which data row a mark came from, or what an annotation means.

Existing tools cover parts of the problem. Each one stops at a boundary we measured; the evidence for each row is in the prior-art note.

| Family | Examples | What breaks |
|---|---|---|
| Static export | `svglite` | No semantics: 134 drawn primitives, 0 ids. Legend keys look exactly like data marks. |
| Spec translation | `ggplotly`, canvasXpress | Redraws the figure in another engine. Measured drift is 6–32% of pixels, and some failures are silent: patchwork reduced to its last panel, all ggrepel labels dropped, a forest plot turned into a bar chart, smooths drawn as one zig-zag. |
| Raster + hit test | Shiny `nearPoints` | Panel-level only, and the row is guessed at query time. Recovered rows: jitter 1/32, `coord_polar` 0/32, second layer 0/32. Non-ggplot engines get no coordmap at all. |
| Device-level tagging | ggiraph, gridSVG, maidr | Exact geometry and exact grob ids. Data binding only for hand-supported geoms, and unknown layers get nothing. ggiraph also requires rewriting the plot code and choosing the interactions in advance. |
| SVG deconstruction (heuristic or LLM) | DIVI, VisAnatomy baselines, CSL, Athanor | Works on any SVG, but its output is never checked against real data. On R charts, element-role F1 is 0.692 for GPT-4o and 0.959 for DeepSeek-V3: unstable across models, and unverifiable. |

## Thesis (revised): the open, verified part is what no one does

Prior art shows that mapping each SVG element to its grob is feasible with exact geometry: the ggiraph `dsvg` tracer and the maidr marker walk both do it. ggai treats them as methodological reference only. It designs its own capture mechanism and takes neither a dependency on those packages nor code from them. What no one does is the open-world, verified part.

At export time, `ggai` holds the canonical code (ADR-0002), the data, the built data, the grob and viewport tree, and an agent. So:

1. **Deterministic skeleton.** Built on per-grob element capture, not whole-SVG draw-order alignment. Covers S1 for every grob, and S2 wherever built data determines it.
2. **Agentic semantics, the actual contribution:**
   - proposed S2 bindings for layers nobody wrote a processor for;
   - S3 domain meaning;
   - relations between elements (legend key ↔ series, label ↔ point, bracket ↔ group pair, annotation track ↔ cluster);
   - a per-figure S4 interaction design, chosen from a closed vocabulary.
3. **Deterministic compile.** Geometry never passes through the LLM.
4. **Verification gate:**
   - per-grob element counts;
   - every claimed row binding checked against built data;
   - a pixel diff against a reference rendered in the same session.

   Agent claims are tagged Direct, Derived or Speculative; only Direct claims are checked against data.

The design rule is unchanged: the agent annotates; it never redraws. The translation experiments are the strongest evidence for this rule.

## Semantic levels

Renamed from L0–L4 to avoid clashing with Lundgard & Satyanarayan's L1–L4.

| Level | Content | Producer |
|---|---|---|
| S0 | Geometry | Graphics device |
| S1 | Element ↔ grob path, viewport path, layer, panel, guide | Deterministic (tracer or marker walk) |
| S2 | Element ↔ built row ↔ raw row (raw rows through group keys, crosstalk-style nested keys for stat layers) | Deterministic for ggplot layers whose built data determines it; agent-proposed and verified otherwise |
| S3 | Domain meaning and relations | Agent |
| S4 | Interaction intent, from a closed vocabulary (DIVI taxonomy: target × type × input) | Agent |

## Pipeline

```
artifact (code + data)
   |  1. skeleton  [deterministic]
   v
skeleton.svg   stable id on every primitive
skeleton.json  id -> grob path, viewport path, layer, PANEL, group, built row,
               aes values; per-grob expected/emitted counts;
               panel + block boxes (recorded from the viewport tree after drawing)
   |  2. semantics [agent]
   |     input: code + ggai_inspect_artifact() + COMPRESSED skeleton
   |            (groups, counts, bbox; never the full SVG)
   v
semantics.json  roles (VisAnatomy-compatible), relations, S4 interactions,
                a11y text, claim provenance
   |  3. compile   [deterministic]
   v
figure.svg / figure.html
   - data-* attributes; WAI-ARIA Graphics roles; <title>/<desc>
   - embedded data JSON (column allow-list)
   - small runtime: one delegated listener on the root
   - optional targets: MAIDR JSON, crosstalk keys
   |  4. verify    [deterministic]
   v
report  dangling ids = 0; per-grob counts match (fail closed);
        Direct claims verified against built rows; pixel diff vs same-session PNG
```

### Stage 1 details (changed by the survey)

- **Capture.** Element capture is done per grob, by a mechanism ggai designs itself. Phase 1 Task 2 compares three ggai-native candidates: per-leaf isolated rendering, a whole-scene render segmented by expected per-grob counts, and a colour-coded pick render. Within each grob, the expected and emitted element counts must match. On a mismatch, fail closed: record S1 only and never recycle ids.
- **Stable ids.** Grob names carry session counters (`geom_point.points.190`), so ids are derived from structure instead: `p<panel>/l<layer>/<leaf role>/<i>`, or `…/r<built row>` when bound.
- **Viewport path.** Record it for every element; ComplexHeatmap's semantics live there.
- **Coordinate maps.** Record panel and block boxes from the viewport tree after drawing (InteractiveComplexHeatmap's approach), not by re-deriving gtable layout (Shiny's approach, which fails on non-ggplot engines).
- **Dense layers.** Above about 10^4 marks, use a raster layer plus a binary hit-test index keyed by (layer, panel, built row). Measured at 10^5 points: SVG 10.2 MB, PNG 478 KB, index 1.17 MB.
- **Grid-like layers** (heatmaps, tiles): store block boxes plus order vectors, not one node per cell.

## Showcase (revised): figures where closed-world tools fail or stay silent

A plain ComplexHeatmap is no longer a differentiator, because maidr covers heat cells, simple annotations and dendrograms. The showcase should use cases where every closed-world tool fails or stays silent:
- complex annotation tracks and their relation to clusters;
- extension geoms (ggrepel, ggtree);
- forest plots (pointrange);
- stat layers bound back to raw rows;
- patchwork with cross-panel relations.

## Why it fits ggai

- Code is canonical (ADR-0002), so the skeleton can always be rebuilt and re-verified.
- It adds one primitive family and one skill. Under ADR-0003, the knowledge lives in the skill.
- It addresses two TODO items: "HTML / SVG assisted layout" and "semantic editing primitives". A semantic SVG becomes a vector-level editing format, an alternative to raster polish that keeps data fidelity.
- `agent = FALSE` still gives a deterministic S1–S2 export at zero token cost.

## Non-goals

- Replacing plotly or Shiny dashboards.
- The LLM generating geometry.
- The htmlwidget engine.
- Depending on, or copying from, ggiraph, gridSVG, maidr, plotly or canvasXpress. They are methodological reference (and benchmark baselines) only.

## Risks and open questions (revised)

- **Per-grob counts will sometimes mismatch.** Expected for NA grid lines and NaN ribbons, and possible for multi-line text and mixed `pch`. Fail closed and report. Unverified: mismatches caused by clipping.
- **Our own capture code owns every edge case.** Clip paths, masks, patterns, symbol reuse (`<use>`), and grobs whose element count depends on the device. Task 2's bake-off measures these on the benchmark set.
- **Stat layers bind indirectly.** Bind to built rows first, then to raw rows through group keys. The agent explains whatever cannot be derived.
- **Fonts move ggrepel labels.** Placement shifts with font metrics, so the skeleton and the reference PNG must come from the same render session.
- **Scripts in an SVG don't run under `<img>`.** Ship inline SVG or HTML.
- **Embedded data can leak columns.** It needs a column allow-list.
- **Agent cost must stay small.** The agent sees only the compressed skeleton. Cache `semantics.json` by code hash.
- **Evaluation, as proposed on 2026-11-07:**
  - our own benchmark (the seven figures used in the survey, plus base, jitter and dense data);
  - the R subset of VisAnatomy, with an "agent without skeleton" ablation against the published baselines (R charts: GPT-4o 0.692, DeepSeek-V3 0.959);
  - baselines: maidr, ggiraph, plotly, canvasXpress;
  - metrics: tagged share, verified-binding share, relation recall, pixel diff.

## Spike evidence (2026-11-07)

- **svglite alone.** 134 drawn primitives (plus 5 clip-path definition rects), 0 ids. 35 circles for 32 rows: the 3 extras are legend keys. Panel-1 circles match `ggplot_build()` rows in order (Spearman 1.0).
- **Tag everything with the ggiraph tracer** (a feasibility reference only; not the mechanism ggai will use). 133/134 primitives tagged, with byte-identical geometry. 6 of 62 leaves had a count mismatch, none of them data marks. Other engines: patchwork 139/140, base via gridGraphics 63/64, ComplexHeatmap 227/228. Details in the prior-art note, §1.

## What became of it (2026-11-08)

The idea became gloss, and five parts changed on the way. [design.qmd](../dev_docs/design.qmd) is the authority for each.

![Schematic. Left: an unchanged scatter plot. Middle: the substrate, a read-only table linking each drawn element to its leaf grob, panel and data row. Right: three layers of records anchored to those elements by dotted lines. Bottom: four projections: an interactive HTML page, an ARIA tree, a text description and a Web Annotation export.](../man/figures/README-overview.png)

*Figure 2. **What the export pipeline became: the geometry stays put and semantics accumulate as anchored records.** The gloss overview schematic from the README (design, not measured). Compare it with the four-stage pipeline above: the agent is no longer a stage, the output files are projections, and records survive a change to the figure.*

1. **An export pipeline became a long-lived substrate.** A one-shot exporter loses work every time the figure changes. gloss captures the figure once into a read-only substrate, and semantics are append-only records anchored to elements; SVG and HTML are projections of a moment ([ADR-0002](../dev_docs/decisions/0002-semantic-substrate-with-append-only-records.md), design §record). The S0–S4 levels map onto record layers (design, glossary).
2. **The three capture candidates gave way to group delimiting plus a probe.** Each leaf grob is wrapped in a graphics-engine group and a probe that draws nothing, so the device itself says which element belongs to which grob. Count segmentation and per-leaf rendering were rejected; the colour-coded pick stays as a fallback for devices without groups and as an optional cross-check ([ADR-0001](../dev_docs/decisions/0001-capture-by-group-delimiting-and-probes.md), design §capture).
3. **Checking Direct claims only became checking every computable claim.** Each computable claim carries a check that runs on built data, Derived claims included; provenance is still recorded (design §verify). The worked example: the annotation "heavier = thirstier" holds in 5 of 6 groups.
4. **A gate at export became a standing constraint.** Every check re-runs whenever the substrate changes. Failed checks are the only hard constraint; conflicting records may coexist (design §verify, §conflicts).
5. **The evaluation was rebuilt from a research card.** The 2026-11-07 plan had no matched-information baseline, no leakage control, no run-to-run variance and no human-label validation, and its VisAnatomy comparison could not run the same conditions, because VisAnatomy has no plotting code to capture. The replacement is a stratified sample of runnable R figures, a comparison against the same model given the same raw materials, and layered scoring; VisAnatomy's published numbers stay as context only ([design §testing](../dev_docs/design.qmd#sec-testing)).

Unchanged: the agent annotates and never redraws (principle 1), the surveyed packages are methodological reference only, dense layers fall back to a raster plus an index, and the demo figures still target inputs that closed-world tools miss.
