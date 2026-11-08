# fig-sniff-v1

AI-generated schematic for `dev_docs/design.qmd`, 一个文件就能带走整份图包 → 上下文自动嗅探，嗅探不到就留空 (#sec-context) (figure type F2, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0056. Every string was re-read on the quantized file.
- **Checked on the published `fig-sniff-v1.png`:**
  - the seven strings, character by character, each exactly once;
  - five blue chips joined to the plot card by solid blue lines; the git chip is grey, dashed, and joined by a dashed line;
  - no logo or watermark.
- **Mapping to the text:**
  - the six chips = the six rows of `tbl-context`;
  - the git chip is an example of an item that could not be sniffed; it does not mean git is usually missing.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus the Latin word "git"; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "上下文在捕获时自动嗅探，嗅探不到就留空"
Subject:
- Center: a small white card with a grey border containing a tiny grey scatter plot (no text): the figure being captured.
- Around it, six chips arranged in a ring (three on the left, three on the right), each joined to the central card by a thin blue line (#4C75AD). Five chips are blue (#EEF3FA fill, #4C75AD outline and text): "绘图代码", "数据来源与行键", "引擎与扩展", "环境与版本", "文档与输出格式". The sixth chip, bottom right, has a dashed grey outline, empty grey fill and grey text: "项目 git：留空并注明原因"; its connecting line is dashed grey.
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the figure card in the centre with the six chips around it
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA for sniffed items
Text (verbatim, exactly these strings and nothing else): "上下文在捕获时自动嗅探，嗅探不到就留空", "绘图代码", "数据来源与行键", "引擎与扩展", "环境与版本", "文档与输出格式", "项目 git：留空并注明原因"
Constraints: render every string exactly once with exactly these characters and punctuation; no additional text, icons, logos or watermark
```
