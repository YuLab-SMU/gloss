# fig-operate-v1

AI-generated schematic for `dev_docs/design.qmd`, 人、R 程序、浏览器和 agent 共用一套操作 → 两个执行环境，同一份词表 (#sec-operate) (figure type F2, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0059. Every string was re-read on the quantized file.
- **Checked on the published `fig-operate-v1.png`:**
  - the twelve strings, character by character, each exactly once (the operation list in monospace, ending in an ellipsis);
  - four caller cards feed one blue vocabulary box, which feeds two runtime cards;
  - no logo or watermark.
- **Mapping to the text:**
  - callers = people, R programs, the browser and agents; the box = `tbl-ops`; the two cards = the R-side and browser-side runtimes.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus a few Latin words; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, header bands, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "人、R 程序、浏览器和 agent 共用一份操作词表"
Subject:
- Top row: four equal white chips with grey borders and dark text, evenly spaced: "人", "R 程序", "浏览器", "agent". Thin grey arrows from all four converge downward onto one central card.
- Center: a wide rounded card with a blue outline (#4C75AD) and light blue fill (#EEF3FA). Header text in blue, bold: "操作词表 v0". Inside, one line of blue monospace text: "select · style · show/hide · overlay · tooltip …".
- Below, the central card splits with two grey arrows into two cards side by side. Left card header: "R 端"; body: "投影时物化进 SVG". Right card header: "浏览器端"; body: "小内核 + 操作插件".
- Bottom center, one line of muted grey text (#87867F): "样式只加类名，不改几何".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; actors, vocabulary, then the two runtimes, top to bottom
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA for the shared vocabulary
Text (verbatim, exactly these strings and nothing else): "人、R 程序、浏览器和 agent 共用一份操作词表", "人", "R 程序", "浏览器", "agent", "操作词表 v0", "select · style · show/hide · overlay · tooltip …", "R 端", "投影时物化进 SVG", "浏览器端", "小内核 + 操作插件", "样式只加类名，不改几何"
Constraints: render every string exactly once with exactly these characters and punctuation; no people, faces or device icons; no additional text, logos or watermark
```
