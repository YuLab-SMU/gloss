# idea

Exploration with no commitment. If a thought might become a plan but hasn't earned that status yet, it lives here. Free-form, may be abandoned.

## When to write here vs elsewhere

- **idea/**: "We might want to do X. Let me sketch it before deciding."
- **plan/**: "We are doing X. Here is the task breakdown."
- **dev_docs/decisions/**: "We decided X. Here's why, so we don't relitigate."

## Conventions

- Filename: `YYYY-MM-DD-<slug>.md`. Keep dates so abandoned ideas can be found later.
- It's fine to abandon. Append a short closing note (`Closed YYYY-MM-DD: rejected because ...`) rather than deleting.
- If an idea matures, promote it: write a plan in `plan/`, link the idea, and add `→ promoted to plan/<file>` at the top.

## Index

- [2026-11-07-agentic-semantic-svg.md](2026-11-07-agentic-semantic-svg.md): the founding idea, written inside ggai. Deterministic element and data binding plus agent-authored, verified semantics; the 2026-11-07 spike numbers; and a closing section on what each part became in gloss. Superseded by [`dev_docs/design.qmd`](../dev_docs/design.qmd).
- [2026-11-07-semantic-svg-prior-art.md](2026-11-07-semantic-svg-prior-art.md): prior art and measured evidence, findings first. For each family (ggiraph/gridSVG/maidr tagging, Shiny and InteractiveComplexHeatmap hit-testing, plotly/canvasXpress translation, the literature) it gives the mechanism, what we measured, and where it stops; also an assessment of REA and Craft Anything.
