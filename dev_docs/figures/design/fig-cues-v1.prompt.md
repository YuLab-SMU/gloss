# fig-cues-v1

AI-generated schematic for `dev_docs/design.qmd`, 代码能确定的不交给模型 → 分类要回答什么 (#sec-classify) (figure type F2, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0063. Every string was re-read on the quantized file.
- **Checked on the published `fig-cues-v1.png`:**
  - the nine strings, character by character, each exactly once;
  - three blue cue chips feed a grid of solid blue squares; three white squares with orange-red outlines sit at the end of the grid;
  - the residue goes to the agent card, then to the record card;
  - no numbers anywhere; no logo or watermark.
- **Mapping to the text:**
  - cue chips = the three kinds of deterministic cues, in order of reliability;
  - solid blue squares = elements classified by rules; outlined squares = the residue (annotation text, base legend);
  - the square counts are illustrative; the measured 481/486 is in `fig-classify-coverage.png`.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus a few Latin words; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "规则先分，残余交给 agent，纠正写成记录"
Subject, left to right:
- Left: three stacked blue chips (#EEF3FA fill, #4C75AD outline and text), top to bottom: "① 对象本身", "② 命名惯例", "③ 代码". A small grey caption above the stack: "按可靠程度排列". Grey arrows from all three converge to the right.
- Middle: a wide blue block made of many small blue squares (like a waffle of elements), labelled under it in blue: "规则分好的元素". At its right edge, a few small white squares with orange-red outlines (#C8553D), labelled under them in orange-red: "残余：注释文字、base 图例".
- Right: a grey arrow from the residual squares to an orange-red rounded card with orange-red bold text: "agent". From the agent card, an orange-red arrow to a small orange-red record card at the far right, labelled: "纠正也是一条带来源的记录".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the flow runs left to right across the middle
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA for code-determined parts; orange-red #C8553D for the residual, the agent and its record
Text (verbatim, exactly these strings and nothing else): "规则先分，残余交给 agent，纠正写成记录", "按可靠程度排列", "① 对象本身", "② 命名惯例", "③ 代码", "规则分好的元素", "残余：注释文字、base 图例", "agent", "纠正也是一条带来源的记录"
Constraints: render every string exactly once with exactly these characters and punctuation; no additional text, icons, logos or watermark
```
