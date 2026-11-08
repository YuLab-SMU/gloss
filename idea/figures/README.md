# Figures for the idea notes

Run every command from the repository root.

| File | Used in | Kind | Source or rebuild |
|---|---|---|---|
| `prior-art-routes-v4.png` | `2026-11-07-semantic-svg-prior-art.md` | AI-generated schematic, stylized, not data | `prior-art-routes-v4.prompt.md` (prompt, rounds, the ImageMagick fix) |
| `prior-art-redraw-evidence.png` | `2026-11-07-semantic-svg-prior-art.md`, §3 | real screenshots from `dev_docs/research/translate/shots/`, with pixel shares from `pixel_diffs.csv` | `Rscript idea/figures/src/prior-art-redraw-evidence.R` |
| `agentic-svg-hero-v1.jpg` | `2026-11-07-agentic-semantic-svg.md` | AI-generated hero image, no data | `agentic-svg-hero-v1.prompt.md` |

The R script uses the house style in `dev_docs/figures/design/src/theme_research.R`. Its visual grammar is listed in `dev_docs/figures/design/src/README.md`.
