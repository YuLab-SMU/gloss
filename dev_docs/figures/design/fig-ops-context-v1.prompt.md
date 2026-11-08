# fig-ops-context-v1

AI-generated schematic for `dev_docs/design.qmd`, 人、R 程序、浏览器和 agent 共用一套操作 → 启用哪些操作，由上下文决定 (figure type F7, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0061. Every string was re-read on the quantized file.
- **Checked on the published `fig-ops-context-v1.png`:**
  - the eight strings, character by character, each exactly once;
  - three context cards with icons (document, heatmap, two facet panels), each with one arrow to one blue operation chip;
  - no logo or watermark.
- **Mapping to the text:**
  - the three examples are quoted from the section; the footnote = defaults come from deterministic rules and the interaction-design stage may change them.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus the Latin words "PDF" and "agent"; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "启用哪些操作，看这张图要去哪里"
Subject: three horizontal rows, evenly spaced. Each row: on the left a white card with a grey border containing a small simple grey pictogram and a short label under it; a grey arrow to the right; on the right a blue chip (#EEF3FA fill, #4C75AD outline and text) naming what is enabled.
- Row 1: pictogram of a printed journal page with a tiny chart on it; label "期刊 PDF". Blue chip: "只投影无障碍信息和文字描述".
- Row 2: pictogram of a small heatmap grid of shaded squares; label "热图". Blue chip: "行列十字高亮".
- Row 3: pictogram of two small side-by-side scatter-plot panels; label "分面散点". Blue chip: "跨面板联动高亮".
- Bottom center, one line of muted grey text (#87867F): "默认由规则给出，agent 可以增减".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; three rows filling the middle; the note at the bottom
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA for enabled operations
Text (verbatim, exactly these strings and nothing else): "启用哪些操作，看这张图要去哪里", "期刊 PDF", "只投影无障碍信息和文字描述", "热图", "行列十字高亮", "分面散点", "跨面板联动高亮", "默认由规则给出，agent 可以增减"
Constraints: render every string exactly once with exactly these characters and punctuation; pictograms contain no text or numbers; no additional text, logos or watermark
```
