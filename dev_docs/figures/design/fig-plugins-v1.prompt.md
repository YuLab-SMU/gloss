# fig-plugins-v1

AI-generated schematic for `dev_docs/design.qmd`, 核心只管五件事，其余都是插件 (#sec-plugins) (figure type F2, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0061. Every string was re-read on the quantized file.
- **Checked on the published `fig-plugins-v1.png`:**
  - the eleven strings, character by character, each exactly once;
  - one blue core pill with eight grey plug tiles around it, each joined by a thin grey line;
  - no logo or watermark.
- **Mapping to the text:**
  - core pill = the five things the core owns; the eight tiles = the eight extension points in `tbl-plugins`.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus a few Latin words; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "核心只管五件事，其余八类都通过 gl_register() 注册"
Subject:
- Center: one rounded rectangle with a solid blue outline (#4C75AD) and light blue fill (#EEF3FA), with blue bold text on one line: "核心：底座 · 锚点 · 记录 · 核验 · 注册表".
- Around the center, eight equal white tiles with thin grey borders, arranged evenly: three above, three below, one on the left and one on the right. Each tile has a tiny grey plug-socket pictogram on its left and dark text. Each tile is joined to the central rectangle by a short thin grey line. Tile texts: "引擎", "分类规则", "层", "检查原语", "操作", "投影与导出", "上下文嗅探", "agent 阶段".
- Bottom center, one line of muted grey text (#87867F): "内置插件和第三方插件走同一条路".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the core in the middle with the eight tiles around it; the note at the bottom
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA for the core
Text (verbatim, exactly these strings and nothing else): "核心只管五件事，其余八类都通过 gl_register() 注册", "核心：底座 · 锚点 · 记录 · 核验 · 注册表", "引擎", "分类规则", "层", "检查原语", "操作", "投影与导出", "上下文嗅探", "agent 阶段", "内置插件和第三方插件走同一条路"
Constraints: render every string exactly once with exactly these characters and punctuation; no additional text, logos or watermark
```
