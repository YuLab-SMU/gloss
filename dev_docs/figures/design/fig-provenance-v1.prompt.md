# fig-provenance-v1

AI-generated schematic for `dev_docs/design.qmd`, 每条可计算的声明都带一条检查 → 声明的三种出处 (#sec-provenance) (figure type F7, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0065. Every string was re-read on the quantized file.
- **Checked on the published `fig-provenance-v1.png`:**
  - the ten strings, character by character, each exactly once;
  - Direct and Derived carry a blue table icon and a green ✓ rule; Speculative carries a grey speech bubble and a dashed rule box;
  - no logo or watermark.
- **Mapping to the text:**
  - the three cards = Direct, Derived, Speculative in #sec-provenance; the rule lines quote that section.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus three English words; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, header bands, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "声明的出处，决定它要不要检查、能不能当事实"
Subject: three equal rounded cards side by side, thin grey border (#C8C7BF), each with a header band (#F4F2EC) and a light body (#FDFCF9).
- Card 1 header, bold monospace: "Direct". Body, dark grey: "从构建数据直接读出". Bottom of the body, a green (#3B8C5A) line with a ✓: "必须带检查，且检查通过".
- Card 2 header, bold monospace: "Derived". Body, dark grey: "由数据计算得出". Bottom of the body, a green (#3B8C5A) line with a ✓: "必须带检查".
- Card 3 header, bold monospace: "Speculative". Body, dark grey: "领域上的推测". Bottom of the body, a muted grey (#87867F) line inside a dashed grey outline: "只能以推测的身份投影".
- In cards 1 and 2, between the body text and the bottom line, a tiny blue (#4C75AD) table icon of three thin rows; in card 3 the same space holds a small grey question-mark-shaped speech bubble outline with no text inside.
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the three cards in one row with equal gaps and wide margins
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD for the data icons; green #3B8C5A for the two checks
Text (verbatim, exactly these strings and nothing else): "声明的出处，决定它要不要检查、能不能当事实", "Direct", "从构建数据直接读出", "必须带检查，且检查通过", "Derived", "由数据计算得出", "必须带检查", "Speculative", "领域上的推测", "只能以推测的身份投影"
Constraints: render every string exactly once with exactly these characters and punctuation; the only other symbols are two ✓; no additional text, icons, logos or watermark
```
