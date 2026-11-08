# Design figure sources

Sources for the figures in `dev_docs/design.qmd` and for `man/figures/README-overview.png`. Run every command from the repository root.

| Output | Source | Kind | Rebuild |
|---|---|---|---|
| `../fig-classify-coverage.png` | `fig-classify-coverage.R` | data (numbers from `dev_docs/research/capture-groups/classify.out`) | `Rscript dev_docs/figures/design/src/fig-classify-coverage.R` |
| `../fig-claim-check.png` | `fig-claim-check.R` | data (computed from `mtcars`) | `Rscript dev_docs/figures/design/src/fig-claim-check.R` |
| `../fig-overview.png` | `fig-overview.zh.svg` | schematic | `rsvg-convert -z 1.25 dev_docs/figures/design/src/fig-overview.zh.svg -o dev_docs/figures/design/fig-overview.png` |
| `man/figures/README-overview.png` | `fig-overview.en.svg` | schematic (English twin) | `rsvg-convert -z 1.25 dev_docs/figures/design/src/fig-overview.en.svg -o man/figures/README-overview.png` |
| `../fig-capture.png` | `fig-capture.svg` | schematic (literal values from a real capture) | `rsvg-convert -z 1.25 dev_docs/figures/design/src/fig-capture.svg -o dev_docs/figures/design/fig-capture.png` |
| `../fig-rebase.png` | `fig-rebase.svg` | schematic (design, not measured) | `rsvg-convert -z 1.25 dev_docs/figures/design/src/fig-rebase.svg -o dev_docs/figures/design/fig-rebase.png` |
| `../hero-manuscript-gloss-v1.jpg` | `../hero-manuscript-gloss-v1.prompt.md` | AI-generated hero image, no data | see the sidecar |
| `../fig-perturb.png` | `fig-perturb.R` | data (computed from `mtcars`; one perturbed and one counterfactual version) | `Rscript dev_docs/figures/design/src/fig-perturb.R` |
| `../fig-decisive-v1.png` | `../fig-decisive-v1.prompt.md` | AI-generated schematic, stylized, not data | see the sidecar |
| `../fig-masked-v1.png` | `../fig-masked-v1.prompt.md` | AI-generated schematic, stylized, not data | see the sidecar |

`theme_research.R` is the shared house style: warm canvas, a centred claim title, and a rounded panel. The R scripts need ggplot2 and ragg; `fig-perturb.R` also needs patchwork. The SVGs need `rsvg-convert` with Helvetica Neue, Menlo and a CJK font (Hiragino Sans GB or PingFang SC). After rendering, open the PNG to check how fonts fell back.

Every figure uses the same visual grammar:

| Meaning | Encoding |
|---|---|
| The figure itself (geometry from the device) | grey and ink |
| What code determines (substrate, rules, checks) | blue `#4C75AD`, light fill `#CFE0F4` / `#EEF3FA` |
| Records and their anchors | orange-red `#C8553D`, dotted leader lines |
| A failed check or something to look at | red `#D65451`, always with ✗ |
| A passed check | green `#3B8C5A`, always with ✓ |
| Literal material (code, grob names, values) | monospace |

The R scripts print font-metric warnings from the default PDF device while they assemble the grob. The final PNG is drawn with ragg, so these warnings do not affect it.
