# fig-milestones-v1

AI-generated schematic for `dev_docs/design.qmd`, 实施计划：到 M3 为止不依赖大模型 (#sec-plan) (figure type F8, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0053. Every string was re-read on the quantized file.
- **Checked on the published `fig-milestones-v1.png`:**
  - the nine strings, character by character, each exactly once;
  - M0–M3 are blue and sit under the blue bracket; M4–M5 are orange-red and sit under the orange-red bracket;
  - no dates or durations; no logo or watermark.
- **Mapping to the text:**
  - the six milestones of `tbl-plan`; pill widths follow the text, not the effort.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic (timeline) for a Chinese design document (stylized, not data; no dates). Visible text is Simplified Chinese plus milestone codes; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "到 M3 为止不依赖大模型"
Subject:
- A horizontal timeline line across the middle, with six evenly spaced milestone chips sitting on it, left to right. The first four chips are blue (#EEF3FA fill, #4C75AD outline and text); the last two chips are orange-red (#FBF1EC fill, #C8553D outline and text). Chip texts, left to right: "M0 底座", "M1 识别 + 分类 + 分层", "M2 记录与锚点", "M3 语义化 + 操作 + 投影", "M4 agent 阶段", "M5 评测".
- Above the first four chips, one long blue bracket spanning them, with blue text above it: "不依赖大模型，已经是可用的工具".
- Above the last two chips, one orange-red bracket spanning them, with orange-red text above it: "接入 agent，做评测".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; brackets above the timeline; chips on the line; wide margins
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA for deterministic milestones; orange-red #C8553D / #FBF1EC for agent milestones
Text (verbatim, exactly these strings and nothing else): "到 M3 为止不依赖大模型", "M0 底座", "M1 识别 + 分类 + 分层", "M2 记录与锚点", "M3 语义化 + 操作 + 投影", "M4 agent 阶段", "M5 评测", "不依赖大模型，已经是可用的工具", "接入 agent，做评测"
Constraints: render every string exactly once with exactly these characters and punctuation; no dates or numbers other than those in the strings; no additional text, icons, logos or watermark
```
