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
- [2026-11-10-page-capture.md](2026-11-10-page-capture.md): capture the page the figure's own code draws (grid display list wrapped in place; base display list replayed entry by entry) instead of a grob an engine builds. Root causes of the development-set differences, the spike's numbers (54 of 55 captured, 53 equal), what it does not solve, and the decision asked of the owner before M1. Promoted 2026-11-11 to [plan/done/2026-11-11-page-capture.md](../plan/done/2026-11-11-page-capture.md) and ADR-0006.
- [2026-11-12-binding-proposals.md](2026-11-12-binding-proposals.md): after ADR-0009 (proposed), who states a binding the engine cannot: an enumeration by code over a closed proposal vocabulary, or a model. The residue of the two development sets sorted by what it lacks (5232 elements in 32 of 83 figures), the vocabulary, a research card, the thinnest experiment and what each result would change. For the owner's decision; nothing run.
