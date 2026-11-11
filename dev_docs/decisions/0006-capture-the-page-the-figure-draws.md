# ADR-0006: Capture the page the figure draws, not a grob built from the object

- **Status:** Accepted
- **Date:** 2026-11-11
- **Deciders:** Yonghe Xia (chose option 3 of [idea/2026-11-10-page-capture.md](../../idea/2026-11-10-page-capture.md) on 2026-11-11)
- **Related:** amends [ADR-0001](0001-capture-by-group-delimiting-and-probes.md) (what is wrapped; base figures) and [ADR-0004](0004-engine-dispatch-through-the-registry.md) (engine contract); [plan/2026-11-11-page-capture.md](../../plan/2026-11-11-page-capture.md); [dev log of the spike](../../dev_logs/2026-11-10-page-capture-spike.md); [research/capture-fidelity/](../research/capture-fidelity/README.md)

## Context

`gloss()` draws a grob that something other than the figure's own code built, and that grob is not always the figure:

| Where the grob comes from | What went wrong on the development set |
|---|---|
| `ggplot_gtable(ggplot_build(x))` instead of the object's `print()` | exts-018 (ggbreak): an uncut plot captured for a cut one, with no error |
| `gridGraphics::echoGrob()`, a second implementation of base graphics | 9 of 10 base figures differ from what the code draws |
| `grid.grab()` in the bench's recovery | gallery-056 (treemap): a tree grid cannot index, though the page redraws |

The fix tried first, refusing objects with their own `print()` method (`efe9936`), refuses by class. It refuses gallery-052 (ggExtra), whose capture was correct, and it cannot know the next package's print method. The invariant "refuse rather than degrade silently" therefore holds only for classes already seen, and gloss has no page of its own to compare a capture with.

## Evidence

All of it is from spike code outside `R/` (`dev_docs/research/capture-fidelity/`), on hand-built cases and on the 55 development figures, in runs made after looking at the development results. No prediction was scored and the held-out set was not read or run.

| | Engine-built grob (`1b22fe1`, run `2026-11-10-1424`) | Page capture (spike, run `2026-11-10-1731`) |
|---|---|---|
| Captured, of 55 | 51 | 54 |
| Equal to the page the code drew | 40, and 6 known exceptions | 53 |
| Different | 5 | 1 (gallery-059, which differs from itself on any redraw) |
| Refused or error | 3 refused, 1 error | 1 (gallery-053, an animation that draws nothing) |
| Base figures equal | 1 of 10 | 10 of 10 |

- Grid pages: the captured page equals a plain redraw from the same random state in 44 of 44, primitives and clip regions.
- Hand-built cases: 15 of 16 grid pages and 26 of 26 base pages identical; gridGraphics identical on 0 of the same 26 recorded plots (`s1`, `s2`).
- Element tables are identical to today's on five grid test inputs; the engines' panels are identical (`s5`).
- Time: 0.44 s against 0.40 s at 10^4 points; the comparison adds 0.28 s (`s4`).

Not measured: dense leaves as rasters, tables end to end, and base leaves (names, expected counts, classification) on this route.

## Decision

**gloss lets its input draw itself on gloss's svglite device and captures that page.** The engine no longer hands the core a grob.

1. **The page.** An object is drawn the way R displays it (`print(x)`, or `show(x)` for S4); a function is called; a recorded plot is replayed. The page this leaves on the device is the figure, and it is the reference every later check compares with.
2. **Two routes, chosen by what is on the device's display list.**
   - *Grid page.* The display list is forced and its leaves wrapped in place (probe plus group, the mechanism of ADR-0001, unchanged), then redrawn by grid.
   - *Base page.* The display list is replayed one entry at a time and the device is read after each entry. The leaf is a display-list entry; its elements are those the device wrote during that entry. No count is estimated and nothing is aligned by order: the boundary is observed on the device. gridGraphics leaves the capture path.
   - A page that mixes base and grid, and a page with nothing on it, are refused with the reason.
3. **Self-check at capture.** gloss compares the captured page with the page the input drew, primitives and clip regions.
   - Equal: captured.
   - Not equal, and a plain redraw from the same random state also differs from the first drawing: the figure is not deterministic. It is captured, the verdict is stored in the figure and reported; it is never silent.
   - Not equal while the plain redraw is equal: capture changed the figure. This aborts.
4. **Engine contract** (amends ADR-0004).
   - `grob(state)` is no longer part of it. Dispatch by declared class through the registry is unchanged.
   - An engine keeps what only it knows: `prepare`, `tables`, `panels`, `describe`, `example`.
   - An engine may supply its own drawing step only to keep something the drawing returns (ComplexHeatmap's drawn list). Its page must equal the page `print(x)` draws; the contract test checks this on the engine's example.
   - Tables and panels are the engine's statements about the page. Where gloss cannot show they describe the page drawn (a print method that draws something other than the built object), they are withheld with the reason, as a leaf with a count mismatch is not bound.
   - An input whose class does not fix the page kind (a function, a recorded plot) goes to the engine that declares both the class and the kind of page drawn.
5. **The refusal by class is removed** once grid pages are captured this way: an object with its own print method is captured as what that method draws.
6. **Order of work.** Grid pages first, base pages second. Until the second step lands, base figures stay on gridGraphics with their recorded differences.

Field names, the order of calls and the stored form of the verdict are settled in the plan, with contract tests. Unchanged: one svglite session for metrics and rendering, masks and leaves with their own group are refused, a leaf whose counts do not match is not bindable.

## Alternatives considered

- **Keep the engine-built grob and record the 5 different figures as limits** (option 1). Rejected: the failures are structural, and one of them was silent.
- **Keep it and draw `print(x)` a second time to compare** (option 2). Rejected: it turns wrong figures into refusals, including most base figures (9 of 10 on the development set), and still captures a grob the figure did not draw.
- **Extend the refusal list by class.** Rejected: it already refuses a correct capture and is always one package behind.

## Consequences

### Positive

- One cause removed instead of five figures patched: custom print methods, gridGraphics' differences and `grid.grab()`'s trees are no longer on the path.
- gloss holds the reference page, so "refuse rather than degrade" can be checked for any class, inside the package.
- Closer to principle 1 for base figures: the base graphics engine replays its own display list, where gridGraphics redrew the figure with another implementation.
- The plot call's display-list entry holds the x and y it was given: a route to base data binding, open in the design.

### Negative / accepted tradeoffs

- The base route reads the structure of a recorded plot, which R documents as subject to change between versions. The self-check catches a change as a difference; a test per supported R version is needed.
- Base leaves get new names (the entry's call, not gridGraphics' `graphics-plot-1-points-1`), so the base part of the classification rules in design §分类 has to be measured again.
- A figure that draws differently each time is reported, not fixed. The random state can be restored only where gloss runs build and draw itself.
- A page recorded on another device is replayed with that device's text metrics.
- Third-party engines written against `grob(state)` must change. None is known outside this repository.
- ADR-0001's evidence row for base (`echoGrob`, "identical") described a regression property of wrapping, not fidelity to the code's drawing; it stops applying when the base step lands.

### Follow-ups

- [plan/2026-11-11-page-capture.md](../../plan/2026-11-11-page-capture.md): implementation in two steps, each measured on the development set with the package, not the spike.
- The bench's comparison gains clip regions and a verdict for figures that are not deterministic.
- Predictions committed before any held-out capture run; the engine route at its last commit is the matched baseline on the same figures.
- Design doc §元素归属 rewritten when the grid step lands; gridGraphics removed from `Suggests` when the base step lands.

### Revisit when

- The package implementation does not reproduce the spike on the development set: any figure captured as different from its own page without the self-check saying so.
- A class of figures appears that draws on the device in a way neither route can attribute (mixed pages were 0 of 55; if they reach a few percent of a sampled set, they need a route).
- A supported R version changes the recorded-plot structure so that entry-by-entry replay no longer equals `replayPlot()`.
- The self-check costs more than capture itself at 10^5 points and cannot be made cheaper.
