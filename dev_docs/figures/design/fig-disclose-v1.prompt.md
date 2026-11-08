# fig-disclose-v1

AI-generated schematic for `dev_docs/design.qmd`, agent 只是底座的一个客户端 → 安全、披露与缓存 (figure type F8, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0079. Every string was re-read on the quantized file.
- **Checked on the published `fig-disclose-v1.png`:**
  - the eleven strings, character by character, each exactly once;
  - four stacked steps, `none` at the bottom, each wider step adding to the one below; the "默认" tag points at `summary`, which has the bold blue outline;
  - no logo or watermark.
- **Mapping to the text:**
  - the four disclosure levels of `gl_tools(disclose = )`; the footnote = `embed` is a separate switch (#sec-embed).

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus monospace level names; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "发给模型的数据分四级，默认 summary"
Subject:
- A staircase of four wide steps rising from left to right, each step a rounded bar whose blue fill gets stronger as it rises (from very pale #F4F2EC with grey outline to #CFE0F4 with #4C75AD outline). On each step, a monospace level name in bold followed by a short description in dark sans-serif:
  step 1 (lowest, left): "none" and "只有结构";
  step 2: "schema" and "加上列名、类型、范围";
  step 3: "summary" and "再加分组统计和少量样例"; this step has a thick blue outline and a small blue tag above it: "默认";
  step 4 (highest, right): "rows" and "可以按需取行".
- Below the staircase, one line of muted grey text (#87867F): "单文件内嵌什么，另由 embed 控制".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients except the stepwise fill
Composition/framing: landscape 16:9; title on top; the staircase across the middle; the note at the bottom
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #CFE0F4
Text (verbatim, exactly these strings and nothing else): "发给模型的数据分四级，默认 summary", "none", "只有结构", "schema", "加上列名、类型、范围", "summary", "再加分组统计和少量样例", "默认", "rows", "可以按需取行", "单文件内嵌什么，另由 embed 控制"
Constraints: render every string exactly once with exactly these characters and punctuation; no additional text, icons, logos or watermark
```
