# gloss

gloss reads an R figure that has already been drawn, and keeps what it learns.

Every drawn element is traced back to the grob, viewport, panel and data row it came from. On top of that substrate, agents and people add **glosses**: layered, append-only records anchored to elements. Each record has provenance, and each claim carries a check against the data. The figure's geometry is never touched. SVG and HTML files are projections of the substrate and its layers; a single file can carry the whole bundle and be restored later.

The name comes from medieval manuscript glosses: notes anchored to particular words, added by many readers over time, layer upon layer, with the text itself left untouched.

## Status

Design phase. There is no package code yet.

- Design (Chinese): [`dev_docs/design.qmd`](dev_docs/design.qmd)
- Prior art and measured evidence (Chinese): [`dev_docs/research-report.qmd`](dev_docs/research-report.qmd)
- Spike scripts and outputs: [`dev_docs/research/`](dev_docs/research/README.md)
- Decisions: [`dev_docs/decisions/`](dev_docs/decisions/README.md)

## Six capabilities

| Capability | What it does |
|---|---|
| Identify | Every drawn element knows its leaf grob, viewport and panel |
| Classify | Data mark, guide, reference line, decoration or annotation: rules first, an agent for the remainder |
| Organize | Structure tree, data tree and semantic groups, mapped onto each other |
| Attach semantics | Meaning, relations, verifiable claims and narrative, as anchored layered records |
| Operate | One operation vocabulary shared by R, the browser runtime and agents |
| Update | Re-capture after code or data changes, re-anchor, and repair only what broke |

## Planned interface (not implemented)

```r
fig <- gloss(p)                    # ggplot, patchwork, Heatmap, recordedplot, any grob
gl_annotate(fig, model = "...")    # staged agents propose records; every record is verified
gl_write(fig, "fig.html")          # interactive, accessible projection with the bundle embedded
fig <- gl_read("fig.html")         # restore it later and keep working
```

## Origin

gloss started on 2026-11-07 as an idea inside [ggai](https://github.com/YuLab-SMU/ggai) under the working name `semsvg`, and became a standalone package on 2026-11-08 ([ggai ADR-0004](https://github.com/YuLab-SMU/ggai/blob/main/dev_docs/decisions/0004-semantic-figure-substrate-as-standalone-package.md)). The two packages do not depend on each other.

## License

MIT
