# ADR-0001: Capture elements by graphics-group delimiting plus probes

- **Status:** Accepted
- **Date:** 2026-11-08 (mechanism verified 2026-11-07)
- **Deciders:** Yonghe Xia
- **Related:** [design: 底座](../design.qmd), [research/capture-groups/](../research/capture-groups/), [research report](../research-report.qmd)

## Context

Every capability in gloss starts from knowing which leaf grob, viewport and panel produced each drawn SVG element. The research report listed three candidate mechanisms, and each had a hard flaw:

- rendering each leaf in isolation: clip paths and `<defs>` have to be rebuilt when the pieces are stitched together;
- rendering the whole figure and splitting it by expected element counts: one wrong estimate shifts every later element;
- colour-coded picking: unreliable with transparency, gradients and patterns.

Prior art (ggiraph's `dsvg` tracer, gridSVG, maidr) proves per-grob capture is feasible, but gloss takes no dependency on those packages and copies no code from them.

## Decision

**Wrap every leaf of the `grid.force()`d scene in a graphics group plus a zero-output probe, render once with plain svglite, and inline the groups.**

```r
gTree(children = gList(probe(id), groupGrob(leaf_without_vp)), vp = leaf$vp)
```

- `groupGrob()` (R >= 4.2) makes the device put everything the leaf draws into its own group. svglite >= 2.2 writes `<defs><g id="group-k">…</g></defs>` plus a `<use href="#group-k"/>` at the original position. **Attribution comes from the device**, not from guessing or order alignment.
- The leaf's `vp` is hoisted to the outer gTree; otherwise viewports that gridGraphics locates by name are not found.
- The probe draws nothing. At draw time it records `current.vpPath()` and the device box of its viewport, so coordinate mapping comes for free.
- `<use>` elements are replaced by their group content, so event targets are the real primitives and styles apply to them directly.
- Font metrics and rendering happen in the same session (ggrepel's layout depends on it).
- If the device does not support groups, fall back to colour-coded picking and say so in the result.

## Evidence

| Input | Leaves | Drawn primitives | vs plain svglite | Unowned |
|---|---|---|---|---|
| ggplot facets + smooth | 60 | 132 | identical | 1 (device background) |
| patchwork | 82 | 184 | identical | 1 |
| base via gridGraphics `echoGrob` | 14 | 60 | identical | 1 |
| ComplexHeatmap with annotations and dendrograms | 14 | 275 | identical | 1 |
| ggrepel (positions computed at draw time) | 51 | 115 | identical | 1 |
| 10^4-point scatter | 13 | 10034 | identical; 3.1 s for three renders | 1 |

"Identical" means every drawn primitive has the same tag, attributes and text. This is a regression property (wrapping did not change the figure), not a capability. On ComplexHeatmap the probes return named viewports such as `z_heatmap_body_1_1`, `z_dend_row_1` and `annotation_cyl_1`.

## Alternatives considered

- **Per-leaf isolated rendering, whole-SVG split by counts, colour picking as the primary mechanism.** Rejected for the flaws above; colour picking is kept as a fallback and an optional cross-check.
- **Using ggiraph, gridSVG or maidr for capture.** Rejected by the prior-art rule: reference only.

## Consequences

### Positive

- One render, public grid API, ordinary svglite; works for every grid-based engine, and for base graphics through gridGraphics.
- Viewport paths and device boxes for every leaf, with no trace in the SVG.

### Negative / accepted tradeoffs

- Requires R >= 4.2 and svglite >= 2.2.
- Still to verify: masks, pattern fills, clipping grobs, gTree-level alpha, and event and style behaviour after inlining.

### Follow-ups

- Implement in `R/core-substrate.R` (M0).
- Regression test: inlined output identical to plain svglite on the six inputs; only the device background unowned.
