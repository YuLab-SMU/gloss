# fig-rowkey-v1

AI-generated schematic for `dev_docs/design.qmd`, 元素归属 → 行键自动推断，随时可改 (#sec-rowkey) (figure type F8, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0072. Every string was re-read on the quantized file.
- **Checked on the published `fig-rowkey-v1.png`:**
  - the ten strings, character by character, each exactly once;
  - five steps top to bottom with down arrows; only step ① is highlighted, with a green ✓;
  - the red note sits beside step ⑤ only;
  - the `gl_key()` card holds two lines and one small orange-red record chip (outline only, no text);
  - no logo or watermark.
- **Mapping to the text:**
  - steps ①–⑤ = the five inference rules in #sec-rowkey, in the same order;
  - the ✓ on ① shows an example where the first rule holds; it is not a claim about which rule usually wins;
  - the card = re-keying with `gl_key()`, which rewrites data-key selectors as an append-only, reversible record.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus a few Latin words; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "行键自动推断：按顺序尝试，第一个成立的就用"
Subject:
- Left two thirds: a vertical list of five pill-shaped chips connected by short downward grey arrows (#87867F). The first chip is highlighted: blue outline (#4C75AD), light blue fill (#EEF3FA), blue text, with a small green ✓ (#3B8C5A) at its right end. Chips two to four are plain: white fill, grey border, dark grey text. The fifth chip is plain but has a small red note (#D65451) to its right. Chip texts, top to bottom: "① 有意义的行名", "② 代码里用作标签或连接键的列", "③ 唯一且无缺失的列", "④ 唯一的列组合", "⑤ 整行哈希加重复序号". The red note next to chip five: "最容易失效，会在报告里标出".
- Right third: one rounded card with a header band (#F4F2EC). Header text, monospace: "gl_key() 随时改键". Body: two lines in dark grey, one under the other: "数据键选择器跟着改写" and "改写也是一条记录，可以撤回". A small orange-red record chip icon (#C8553D outline, no text) sits beside the second line.
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the list on the left, the card on the right, wide margins
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #EEF3FA; green #3B8C5A; red #D65451; orange-red #C8553D
Text (verbatim, exactly these strings and nothing else): "行键自动推断：按顺序尝试，第一个成立的就用", "① 有意义的行名", "② 代码里用作标签或连接键的列", "③ 唯一且无缺失的列", "④ 唯一的列组合", "⑤ 整行哈希加重复序号", "最容易失效，会在报告里标出", "gl_key() 随时改键", "数据键选择器跟着改写", "改写也是一条记录，可以撤回"
Constraints: render every string exactly once with exactly these characters and punctuation; the only other symbol is one ✓; no additional text, icons, logos or watermark
```
