# Capture the page the figure draws, not a grob built from the object

> → promoted to [plan/2026-11-11-page-capture.md](../plan/2026-11-11-page-capture.md) on 2026-11-11: the owner chose option 3. Decision recorded in [ADR-0006](../dev_docs/decisions/0006-capture-the-page-the-figure-draws.md). The text below is kept as written.

> Status: idea, for the owner's decision before M1. Not a plan, not an ADR.
> Date: 2026-11-10. Evidence: [`dev_docs/research/capture-fidelity/`](../dev_docs/research/capture-fidelity/README.md), [dev log](../dev_logs/2026-11-10-page-capture-spike.md).

## The finding

Every capture difference found on the development set has one cause: gloss draws a grob that something other than the figure's own code built, and that grob is not always the figure.

| Where the grob comes from | What went wrong on the development set |
|---|---|
| `ggplot_gtable(ggplot_build(x))` instead of the object's `print()` | exts-018 (ggbreak): an uncut plot captured for a cut one; now refused by class |
| `gridGraphics::echoGrob()`, a second implementation of base graphics | 9 of 10 base figures differ from what the code draws (5 by one background rect, 4 by 3 to 34 primitives) |
| `grid.grab()` in the bench's recovery | gallery-056 (treemap): a tree grid cannot index, counted as an error |

Refusing by class, the fix of `efe9936`, does not scale: it refuses a figure gloss captured correctly (gallery-052, ggExtra: the object equals its own `print()`, 83 = 83 primitives; the reported 136 differences came from a reference page holding two figures), and it cannot know the next package's print method.

## The idea

Let the figure draw itself on svglite, by its own print method or its own code, and capture that page.

- **grid page.** Force the grid display list and wrap its leaves in place (probe + group, the mechanism of ADR-0001), then redraw. The engine no longer builds the grob; it keeps what only it knows: tables, panels, description.
- **base page.** Replay the device's display list one entry at a time on svglite, reading the device after each entry. The primitives written between two reads were drawn by that entry. gridGraphics leaves the capture path.
- **Self-check.** The page the figure drew is on the device before gloss touches it, so gloss can compare the captured page with it and with a plain redraw. This is the self-verification the previous dev log asked about, without a second device.

This follows principle 1 more closely than the current base route does: gridGraphics redraws the figure with another renderer.

## What was measured

On the 55 development figures (container, three runs, made after looking; no prediction scored):

| | Engine-built grob (`1b22fe1`) | Page capture (spike) |
|---|---|---|
| Captured | 51 | 54 |
| Refused or error | 3 refused, 1 error | 1: an animation that draws nothing on the device |
| Equal to the page the code drew | 40 (+ 6 known exceptions) | 53 |
| Different | 5 | 1: gallery-059, which differs from itself on any redraw (ggrepel without a seed) |
| Base figures equal | 1 of 10 | 10 of 10 |

- Captured page against a plain redraw from the same random state: 44 of 44 grid pages, primitives and clip regions.
- On hand-built cases: 15 of 16 grid pages and 26 of 26 base pages identical; gridGraphics identical on 0 of the same 26 recorded plots.
- Element tables are identical to today's on the five grid test inputs; leaves differ only in grid's automatic numbering; the engines' panels are identical.
- Base panels and scales read from `par()` place the data within 0.005 pt of the drawn points. The plot call's display-list entry holds the x and y it was given, which is a route to the base data binding listed as open in the design.
- Cost: about the same as today (0.44 s against 0.40 s at 10^4 points); the comparison adds 0.28 s.

## What it does not solve

- **Figures that draw differently each time.** A second drawing differs from the first; gloss can say so, not undo it. Saving the random state works where gloss controls build and draw (ggplot), not for an arbitrary print method.
- **Masks, and leaves with their own group.** Refused as today.
- **Pages mixing base and grid.** Detected, not captured (0 of 55 development figures).
- **A page recorded on another device.** Replay is self-consistent but carries that device's text metrics.
- **Count mismatches inside a leaf.** Unchanged: 31 of 44 grid pages have one.

## What it costs

- An ADR: it changes the engine contract of ADR-0004 (`grob(state)` becomes "draw it") and the unit of ADR-0001 for base figures (a display-list entry, not a gridGraphics grob).
- Base leaves get new names. The classification rules of design §分类 use gridGraphics' names (`graphics-plot-1-points-1`); the entry's call (`C_plotXY`, `C_axis`, `C_title`) would replace them. Not measured.
- Dense leaves as rasters, and tables end to end, are untested on this route.
- The bench's fidelity comparison needs the clip regions (it could not see a lost clip), and a figure that is not deterministic needs a verdict of its own.

## Decision asked of the owner

1. Keep the engine-built grob and the refusal list, and record the 5 different figures as limits.
2. Keep it and add a second drawing to compare with: errors become refusals, including most base figures.
3. Page capture, in two steps: grid pages first (smaller: the engines' drawing step), base pages second, with an ADR and predictions committed before any held-out run.

Recommended: 3. The development set says the current route's failures are structural, and the spike says the alternative is mostly a rearrangement of code that exists.
