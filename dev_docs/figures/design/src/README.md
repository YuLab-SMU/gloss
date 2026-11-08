# Design figure sources

Sources for the figures in `dev_docs/design.qmd` and for the README figures in `man/figures/`. Run every command from the repository root.

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
| `../fig-analogy-v1.jpg` | `../fig-analogy-v1.prompt.md` | AI-generated analogy illustration in the hero's series, no data | see the sidecar |
| `../fig-order-vs-group-v1.png` | `../fig-order-vs-group-v1.prompt.md` | AI-generated schematic of the measured ggiraph misbinding | see the sidecar |
| `../fig-rowkey-v1.png` | `../fig-rowkey-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-cues-v1.png` | `../fig-cues-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-views-v3.png` | `../fig-views-v3.prompt.md` | AI-generated schematic, design; one character redrawn with PIL | see the sidecar |
| `../fig-provenance-v1.png` | `../fig-provenance-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-verify-loop-v1.png` | `../fig-verify-loop-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-anchor-v2.png` | `../fig-anchor-v2.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-log-v1.png` | `../fig-log-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-conflict-v1.png` | `../fig-conflict-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-agent-tools-v3.png` | `../fig-agent-tools-v3.prompt.md` | AI-generated schematic, design; one stray mark removed with PIL | see the sidecar |
| `../fig-disclose-v1.png` | `../fig-disclose-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-operate-v1.png` | `../fig-operate-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-ops-context-v1.png` | `../fig-ops-context-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-bundle-v1.png` | `../fig-bundle-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-restore-v1.png` | `../fig-restore-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-sniff-v1.png` | `../fig-sniff-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-plugins-v1.png` | `../fig-plugins-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-milestones-v1.png` | `../fig-milestones-v1.prompt.md` | AI-generated schematic, design | see the sidecar |
| `../fig-misanchor-v2.png` | `../fig-misanchor-v2.prompt.md` | AI-generated schematic of an open risk; one extra dot painted out | see the sidecar |
| `man/figures/README-question-v3.png` | `../README-question-v3.prompt.md` | AI-generated schematic for the README, not a screenshot; one extra dot painted out | see the sidecar |

`theme_research.R` is the shared house style: warm canvas, a centred claim title, and a rounded panel. The R scripts need ggplot2 and ragg; `fig-perturb.R` also needs patchwork. The SVGs need `rsvg-convert` with Helvetica Neue, Menlo and a CJK font (Hiragino Sans GB or PingFang SC). After rendering, open the PNG to check how fonts fell back.

The AI-generated schematics follow the same grammar: each prompt lists the hex colours and every visible string, and each sidecar records the checks. Their post-processing is the same for all of them: resize to 1600 px, strip metadata, quantize to a 128-colour PNG8 without dithering, then re-read every string. Pixel fixes are made with ImageMagick or PIL from colours sampled in the image, never by another generation round after the third.

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
