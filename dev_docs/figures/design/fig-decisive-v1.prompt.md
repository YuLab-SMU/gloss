# fig-decisive-v1

AI-generated schematic for `dev_docs/design.qmd`, section 研究卡片 (figure type F7, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08. The first round was accepted.
- **Post-processing:** resized to 1600 px wide, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x … -colors 128 -dither None PNG8:out.png`). After quantization every string was re-checked and is still legible.
- **Checked:**
  - the nine strings, character by character, each exactly once: "同一个模型、同样的材料和预算，只差底座", "同一个模型 · 同样的预算", "条件 A：原始材料", "代码 · 数据 · 构建数据 · grob 树 · SVG", "只读 R 沙箱", "条件 B：gloss 底座", "底座的只读工具", "propose：提交即校验", "按三层计分：角色 · 绑定 · 声明核验";
  - one hexagon;
  - blue only on condition B;
  - no logo or watermark.
- **Mapping to the doc:** the two cards are conditions A and B in `tbl-eval-conditions`. The shared chip is the matched model and budget. The bottom line is the three layers named in the research card's main claim.

## Prompt

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). All visible text is Simplified Chinese plus a few Latin words; render the Chinese characters exactly.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "同一个模型、同样的材料和预算，只差底座"
Subject:
- Just below the title, centered, one small rounded chip (white #FDFCF9, thin grey border #C8C7BF) with a plain outlined hexagon icon in grey at its left, and the text "同一个模型 · 同样的预算" in dark grey. Two thin grey lines branch from the bottom of this chip down to the tops of two cards.
- Two large rounded-rectangle cards side by side below, equal size, thin grey border #C8C7BF. Each card has a top header band (#F4F2EC) and a lighter body (#FDFCF9).
- Left card header, bold dark text: "条件 A：原始材料". Left card body: two stacked pill-shaped chips with grey fill (#EEECE5) and dark grey text: upper chip "代码 · 数据 · 构建数据 · grob 树 · SVG", lower chip "只读 R 沙箱".
- Right card header, bold dark text: "条件 B：gloss 底座". Right card body: two stacked pill-shaped chips with light blue fill (#EEF3FA), blue outline and blue text (#4C75AD): upper chip "底座的只读工具", lower chip "propose：提交即校验".
- Below both cards, centered and spanning their width, one line of muted grey text (#87867F): "按三层计分：角色 · 绑定 · 声明核验".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top, the shared chip, the two cards, then the scoring line; wide margins
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF, #EEECE5; blue #4C75AD with fill #EEF3FA for condition B only; nothing else saturated
Text (verbatim, exactly these strings and nothing else): "同一个模型、同样的材料和预算，只差底座", "同一个模型 · 同样的预算", "条件 A：原始材料", "代码 · 数据 · 构建数据 · grob 树 · SVG", "只读 R 沙箱", "条件 B：gloss 底座", "底座的只读工具", "propose：提交即校验", "按三层计分：角色 · 绑定 · 声明核验"
Constraints: render every string exactly once with exactly these characters and punctuation (full-width colon "：", middle dot "·"); no additional text, icons other than the one hexagon, logos or watermark
```
