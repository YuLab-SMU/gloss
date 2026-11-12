# gloss

gloss reads an R figure that has already been drawn and traces every shape back to the grob, panel and data row behind it. People and AI agents can then attach notes to those shapes, and any note that makes a claim is checked against the data. The figure itself is never redrawn.

> **Status, 2026-11-12: capture is implemented and measured; row binding is implemented inside the package and measured, but not exported yet; everything else is design.** `gloss()` captures the page a figure draws and checks its capture against that page. Each drawn element of a layer is paired with a data row, and the pairing is checked by putting the row back through the panel's scales. Roles, records, claim checks, interactive projections and agents are not built. Numbers come from a benchmark of sampled figures with runnable code ([`bench/`](https://github.com/YuLab-SMU/gloss/tree/main/bench)); numbers marked as spikes come from scripts in [`dev_docs/research/`](https://github.com/YuLab-SMU/gloss/tree/main/dev_docs/research).

![Schematic. Left: an unchanged scatter plot. Middle: the substrate, a read-only table linking each drawn element to its leaf grob, panel and data row. Right: three layers of records anchored to those elements by dotted lines. Bottom: four projections: an interactive HTML page, an ARIA tree, a text description and a Web Annotation export.](man/figures/README-overview.png)

## Why

Export the usual faceted mtcars scatter plot with svglite and you get 134 drawn primitives, none of which carries an id. Three of the 35 circles are legend keys, and in the SVG they look exactly like data points. Point at one and ask "which car is that?", and the file has no answer.

![Schematic, AI-generated. Two panels show the same scatter plot with a downward trend. Left, "plain SVG export": a cursor points at one dot under a speech bubble asking "Which car is this?", and the footer reads "134 shapes, 0 ids: no answer". Right, "with gloss": the same dot is ringed in blue and labelled "Mazda RX4 · mtcars row 1 · panel am = 1".](man/figures/README-question-v3.png)

*The same question, put to a plain SVG export and to gloss. Schematic (AI-generated), not a screenshot: the interactive view is not built yet (milestone M3), and the plot is drawn as one simplified panel. The 134 shapes are the svglite export of the faceted mtcars plot described above; Mazda RX4 is row 1 of `mtcars`, with `am = 1`. Prompt, rounds and the one pixel fix: [`README-question-v3.prompt.md`](https://github.com/YuLab-SMU/gloss/blob/main/dev_docs/figures/design/README-question-v3.prompt.md).*

Existing tools each solve half of the problem. ggiraph, gridSVG and maidr tag elements while they are drawn, so the geometry stays exact, but they bind data only for geoms someone has written a handler for. A model reading the SVG can take any figure but has no ground truth: on the same R figures, GPT-4o and DeepSeek-V3 identify element roles with F1 of 0.692 and 0.959, and neither can tell when it is wrong.

## What has been measured

- **Every drawn element can be traced to where it came from.** gloss lets the figure draw its own page and captures that page: on a grid page each leaf grob is delimited by a graphics group plus a probe that draws nothing, and a base page is replayed one display-list entry at a time. On the benchmark's 54 held-out figures (one run, predictions committed first), 50 captures equal the page drawn primitive for primitive, 2 figures differ on every drawing and are reported so, 2 are refused, and none is captured as another figure.
- **Elements bind to data rows without a handler per geom.** Which comparison applies is chosen by the element's tag and the counts, never by the geom's name. On 24 held-out ggplot tree figures (one run, binder frozen, predictions first) 92.6% of layer elements are checked against their row and none fails; every layer element is checked in 18 of the 24. A checked element is either verified or ambiguous (another row of its layer lies within 0.5 pt, as overplotted points do); what cannot be checked is left unbound with its reason. Across the three sets run so far, 17 geom classes from extension packages were paired: 8 are checked whole (two of them partly through rules read from their packages, a kind of rule gloss no longer adds), 5 in part, 4 not at all.
- **Code settles most of the semantics (spike).** Naming-convention rules alone classify 481 of the 486 elements in three test figures. The five that remain are annotation text and a base-graphics legend. Those are the cases an agent handles, and the ones where a classification has to be correctable.
- **Claims are checked, not trusted (spike).** The plot carries the note "heavier = thirstier". The slope of mpg on weight is negative in only 5 of the 6 groups that `geom_smooth()` draws. The exception is automatic 4-cylinder cars, of which there are just 3. gloss shows the note together with its exception instead of presenting it as fact.

## What works now

```r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point() + facet_wrap(~am)

fig <- gloss(p)                      # also patchwork, Heatmap, recordedplot, any grob
gl_elements(fig, list(tag = "circle"))  # every drawn element: leaf, box, style, panel
gl_hit(fig, 2.62, 21, space = "data", panel = "panel2")  # what is drawn at this data point
gl_tables(fig)                       # raw and built tables; mtcars is keyed by its row names
gl_context(fig)                      # code, data, engine, environment, document, git

gl_write(fig, "fig.html")            # the figure, with the whole bundle embedded
fig <- gl_read("fig.html")           # restored exactly
```

Not exported yet: bindings (they are computed and checked inside the package, and the benchmark reads them). Still planned: roles, `gl_annotate()` (staged agents propose records, each one verified), the interactive and accessible projection, and `gl_rebase()` for updated figures.

## Six capabilities

| Capability | What it does | Evidence so far |
|---|---|---|
| Identify | Traces each drawn element to its leaf grob, viewport and panel | Implemented; 50 of 54 held-out figures equal to the page drawn, none captured as another figure |
| Classify | Labels each element as a data mark, guide, reference line, decoration or annotation, using rules first and an agent for the rest | 481 of 486 elements by naming rules alone |
| Organize | Builds the structure tree, the data tree and semantic groups, and maps each onto the others | Structure tree rebuilt for ggplot |
| Attach semantics | Binds elements to data rows; records meaning, relations, checkable claims and narrative as anchored, layered records | Binding implemented internally: 92.6% of layer elements checked on 24 held-out ggplot tree figures, none failed. One claim check run by script; records are design |
| Operate | Provides one set of operations (select, style, show/hide, tooltip, overlay, ...) shared by R, the browser and agents | Design |
| Update | Re-captures after the code or data changes, re-anchors records, and sends only the broken ones for repair | Design |

## The name

A gloss is a note in a medieval manuscript, anchored to a particular word and written by one of many readers over the years, while the text itself stays untouched. gloss does the same for a figure: records are anchored to elements, appended in layers by agents and people, and the geometry is never changed.

## Read more

- [Design](https://github.com/YuLab-SMU/gloss/blob/main/dev_docs/design.qmd) (Chinese): the decisions, the evidence behind each one, risks and milestones.
- [Prior art and measured evidence](https://github.com/YuLab-SMU/gloss/blob/main/dev_docs/research-report.qmd) (Chinese): what ggiraph, gridSVG, maidr, Shiny, plotly, canvasXpress and the literature do, and where each stops.
- [Decisions](https://github.com/YuLab-SMU/gloss/tree/main/dev_docs/decisions): architecture decision records.

## Origin

gloss started on 2026-11-07 as an idea inside [ggai](https://github.com/YuLab-SMU/ggai) under the working name `semsvg`. It became a standalone package on 2026-11-08 ([ggai ADR-0004](https://github.com/YuLab-SMU/ggai/blob/main/dev_docs/decisions/0004-semantic-figure-substrate-as-standalone-package.md)). The two packages do not depend on each other.

## License

MIT
