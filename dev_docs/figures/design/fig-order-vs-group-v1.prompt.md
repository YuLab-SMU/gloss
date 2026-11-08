# fig-order-vs-group-v1

AI-generated schematic for `dev_docs/design.qmd`, 元素归属由图形设备给出 → 被否决的方案 (figure type F3, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0075. Every string was re-read on the quantized file.
- **Checked on the published `fig-order-vs-group-v1.png`:**
  - the title, the two card headers, "c 被标成了第二个标签的 id，没有警告", "group 1" and "group 2", character by character;
  - left card: a, b, c, d tagged id 1, id 1, id 2 (red, with ✗), id 2. This is ggiraph's `rep(each = )` recycling of 2 ids over 4 elements;
  - right card: a, b, c inside the dashed blue group 1, d alone in group 2, with a green ✓;
  - no logo or watermark.
- **Mapping to the text:**
  - the measured case in the research report: labels `"a\nb\nc"` and `"d"` emit 4 `text` elements, and line c silently gets the second label's id;
  - right card = group delimiting with `groupGrob()` (ADR-0001).

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus short Latin labels; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, header bands, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "按顺序分配 id 会悄悄错位，按组划界不会"
Subject: two equal rounded cards side by side, each with a header band (#F4F2EC) and a light body (#FDFCF9).
- Left card header: "按顺序：第 i 个 id 给第 i 个元素". Body: four small white monospace text tiles in a row with thin grey borders, showing the letters a, b, c, d (one letter per tile, in this order). Under each tile a small id tag: under a "id 1", under b "id 1", under c "id 2", under d "id 2". The id tags are grey, except the tag under c, which is red (#D65451) with a small ✗. Below the row, one red line of text: "c 被标成了第二个标签的 id，没有警告".
- Right card header: "按组：设备把元素放进各自的组". Body: the same four tiles a, b, c, d. Tiles a, b and c are enclosed together in one dashed blue rounded outline (#4C75AD) labelled above it in blue monospace "group 1"; tile d is enclosed alone in a second dashed blue outline labelled "group 2". A small green ✓ (#3B8C5A) sits at the lower right of the card.
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; two cards side by side with wide margins
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD for groups; red #D65451 for the wrong id; green #3B8C5A
Text (verbatim): the title; the two headers "按顺序：第 i 个 id 给第 i 个元素" and "按组：设备把元素放进各自的组"; the letters "a", "b", "c", "d" exactly once in each card; the tags "id 1" twice and "id 2" twice in the left card only; "c 被标成了第二个标签的 id，没有警告" once; "group 1" and "group 2" once each in the right card. Nothing else.
Constraints: exactly these characters and punctuation; the only other symbols are one ✗ and one ✓; no additional text, icons, logos or watermark
```
