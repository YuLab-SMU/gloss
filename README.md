# gloss

gloss reads an R figure that has already been drawn and traces every shape back to the grob, panel and data row behind it. People and AI agents can then attach notes to those shapes, and any note that makes a claim is checked against the data. The figure itself is never redrawn.

> **Status: M0 (the substrate) is implemented** as of 2026-11-09: capture, geometry queries, tables with inferred row keys, context sniffing, and bundles written as a directory or a single HTML/SVG file. Classification, records, claim checks, interactive projections and agents are still design. Numbers marked as spikes come from scripts in [`dev_docs/research/`](https://github.com/YuLab-SMU/gloss/tree/main/dev_docs/research).

![Schematic. Left: an unchanged scatter plot. Middle: the substrate, a read-only table linking each drawn element to its leaf grob, panel and data row. Right: three layers of records anchored to those elements by dotted lines. Bottom: four projections: an interactive HTML page, an ARIA tree, a text description and a Web Annotation export.](man/figures/README-overview.png)

## Why

Export the usual faceted mtcars scatter plot with svglite and you get 134 drawn primitives, none of which carries an id. Three of the 35 circles are legend keys, and in the SVG they look exactly like data points. Point at one and ask "which car is that?", and the file has no answer.

![Schematic, AI-generated. Two panels show the same scatter plot with a downward trend. Left, "plain SVG export": a cursor points at one dot under a speech bubble asking "Which car is this?", and the footer reads "134 shapes, 0 ids: no answer". Right, "with gloss": the same dot is ringed in blue and labelled "Mazda RX4 · mtcars row 1 · panel am = 1".](man/figures/README-question-v3.png)

*The same question, put to a plain SVG export and to gloss. Schematic (AI-generated), not a screenshot: the interactive view is not built yet (milestone M3), and the plot is drawn as one simplified panel. The 134 shapes are the svglite export of the faceted mtcars plot described above; Mazda RX4 is row 1 of `mtcars`, with `am = 1`. Prompt, rounds and the one pixel fix: [`README-question-v3.prompt.md`](https://github.com/YuLab-SMU/gloss/blob/main/dev_docs/figures/design/README-question-v3.prompt.md).*

Existing tools each solve half of the problem. ggiraph, gridSVG and maidr tag elements while they are drawn, so the geometry stays exact, but they bind data only for geoms someone has written a handler for. A model reading the SVG can take any figure but has no ground truth: on the same R figures, GPT-4o and DeepSeek-V3 identify element roles with F1 of 0.692 and 0.959, and neither can tell when it is wrong.

## What the spikes show

- **Every drawn element can be traced to where it came from.** gloss wraps each leaf grob in a graphics group plus a probe that draws nothing. On six kinds of input (ggplot facets, patchwork, base, ComplexHeatmap, ggrepel, 10,000 points), the output matches plain svglite element for element, and the only unowned element is the device background.
- **Code settles most of the semantics.** Naming-convention rules alone classify 481 of the 486 elements in three test figures. The five that remain are annotation text and a base-graphics legend. Those are the cases an agent handles, and the ones where a classification has to be correctable.
- **Claims are checked, not trusted.** The plot carries the note "heavier = thirstier". The slope of mpg on weight is negative in only 5 of the 6 groups that `geom_smooth()` draws. The exception is automatic 4-cylinder cars, of which there are just 3. gloss shows the note together with its exception instead of presenting it as fact.

## What works now (M0)

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

Still planned: `gl_annotate()` (staged agents propose records, each one verified), the interactive and accessible projection, and `gl_rebase()` for updated figures.

## Six capabilities

| Capability | What it does | Evidence so far |
|---|---|---|
| Identify | Traces each drawn element to its leaf grob, viewport and panel | Implemented (M0); regression-tested on 6 kinds of input |
| Classify | Labels each element as a data mark, guide, reference line, decoration or annotation, using rules first and an agent for the rest | 481 of 486 elements by naming rules alone |
| Organize | Builds the structure tree, the data tree and semantic groups, and maps each onto the others | Structure tree rebuilt for ggplot |
| Attach semantics | Records meaning, relations, checkable claims and narrative as anchored, layered records | One claim check run by script; the rest is design |
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
