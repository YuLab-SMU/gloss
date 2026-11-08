# fig-restore-v1

AI-generated schematic for `dev_docs/design.qmd`, 一个文件就能带走整份图包 → 恢复时先看手里有什么 (figure type F7, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0070. Every string was re-read on the quantized file.
- **Checked on the published `fig-restore-v1.png`:**
  - the nine strings, character by character, each exactly once;
  - four rows, one arrow each; outcome outlines: green with ✓ (complete), amber (partial) twice, grey (geometry only);
  - no logo or watermark.
- **Mapping to the text:**
  - the four rows = the four bullets of the section, in order.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus the Latin word "SVG"; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "恢复时，手里有什么就恢复什么"
Subject: four horizontal rows, evenly spaced. Each row: a white input chip with a grey border on the left, a grey arrow, and a result chip on the right.
- Row 1: input "完整的单文件" → result chip with green outline and text (#3B8C5A) and a ✓: "完整图包".
- Row 2: input "剥离了数据的单文件" → result chip with amber outline (#E9A23B) and dark text: "底座和各层；绑定标为缺数据".
- Row 3: input "用到的插件没装" → result chip with amber outline (#E9A23B) and dark text: "照常恢复；相关记录标为缺插件".
- Row 4: input "普通 SVG" → result chip with grey outline and grey text: "只有几何，从识别开始重建".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; four rows in the middle with wide margins
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; green #3B8C5A; amber #E9A23B for partial recovery
Text (verbatim, exactly these strings and nothing else): "恢复时，手里有什么就恢复什么", "完整的单文件", "完整图包", "剥离了数据的单文件", "底座和各层；绑定标为缺数据", "用到的插件没装", "照常恢复；相关记录标为缺插件", "普通 SVG", "只有几何，从识别开始重建"
Constraints: render every string exactly once with exactly these characters and punctuation; the only other symbol is one ✓; no additional text, icons, logos or watermark
```
