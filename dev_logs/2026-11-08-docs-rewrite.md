# 2026-11-08 — Rewrite README and design doc with the research-writing method

- **Related plan:** none (documentation patch; M0 is still next)
- **Related ADRs:** none changed. ADR-0001 to ADR-0003 and the research report were deliberately left as they are, following the "immutable once accepted" and "kept as researched" conventions.
- **Worked on by:** Yonghe Xia, Claude

## What changed

The README and `dev_docs/design.qmd` now open with the findings, title each section with its conclusion, and label every number as either measured or design-only. The design content is unchanged apart from the two notes below.

**`dev_docs/design.qmd`**
- The opening follows "problem → gap → what gloss does". It then states the document's stage, asks four questions, and answers them with five decisions; each decision carries its evidence and a figure reference. The previous changelog-style opening ("this version turns the converter into a substrate") now lives in a closing section, "与上一版的区别".
- The body is organised by decision, not by capability, and every section has a takeaway callout. The per-capability interfaces moved to appendix A, so nothing was dropped. A check that every inline code token, number and `gl_*` name in the old file appears in the new one found 175 of 175.
- Evidence ladders: each measured decision now names the rival explanation and what it would predict before giving the result: order alignment versus ggiraph's silent mislabel, models reading the SVG versus the 0.692/0.959 F1 gap, and the "heavier = thirstier" note versus 5 of 6 groups.
- One sustained analogy, the manuscript gloss: a part-by-part mapping table, plus three places where the analogy breaks (verification, the no-interpolation rule, invalidation).
- New sections: what the design cannot show yet; a risks list in which each item opens with its conclusion; a glossary saying what each named concept is *not*. The glossary separates 层 (gloss layer) from 图层 (ggplot layer).
- Two content notes, both recorded in the doc. First, the "heavier = thirstier" claim was called Direct and is now Derived, consistent with the doc's own definitions and with the research report. Second, a new open question: selector fallback can silently point at the wrong element, for example when a data key is lost but a data-space region still resolves to another car. The doc proposes treating that as ambiguous; the decision is left for M2.

**Figures** (`dev_docs/figures/design/`, sources in `src/`, with a README covering how to rebuild them and the visual grammar)
- `fig-overview.png`: key schematic of the figure → substrate → records → projections. An English twin is used for the README at `man/figures/README-overview.png`.
- `fig-capture.png`: the group + probe mechanism. Its literal values (leaf007, vp path, box, 19 circles) come from a real capture of the running example.
- `fig-classify-coverage.png`: waffle chart of 486 elements, 481 correct by naming rules. The two base-legend misclassifications are `graphics-plot-1-rect-1` and `graphics-plot-1-segments-1`; they were confirmed by listing the leaves.
- `fig-claim-check.png`: per-group slopes of mpg on wt. Five are negative; automatic 4-cylinder is +3.07 with n = 3.
- `fig-rebase.png`: one record under three edits, giving unique, missing and ambiguous. Labelled as design, not measured.
- `hero-manuscript-gloss-v1.jpg`: AI-generated hero image (Flare low draft, then Sunburst 2.6 high), with a `.prompt.md` sidecar. The caption says it is AI-generated.

**README:** a one-sentence description of what the package does, the status line, the overview figure, why the package exists, three measured findings, the planned interface, the capability table with an evidence column, the name, and further reading. Links into `dev_docs/` are now absolute GitHub URLs, because `dev_docs/` is not in the package tarball.

**`dev_docs/README.md`:** index entries updated for the new design structure and `figures/design/`.

## Verification

- Spikes re-run from `/tmp`: `classify.R` (132/134, 292/292, 59/60), `hierarchy.R` (panel 2 smooth 9 vs 12 elements), and the per-group slopes (`lm(mpg ~ wt)` by `am` × `cyl`). All match the numbers in the doc.
- `quarto render dev_docs/design.qmd --to html`: no warnings, and no unresolved `?@` cross-references.
- Relative links and anchors in the four changed Markdown/Quarto files: 0 broken.
- Every figure PNG was opened and checked for overflowing text, font fallback and leader lines that end on their targets.

## What's next

- Open the M0 plan as before.
- When the research report or the ADRs are next revised, decide whether to apply the same method. They were out of scope here by choice.
- M2 must settle the selector-fallback question raised in the design doc's risks section.
