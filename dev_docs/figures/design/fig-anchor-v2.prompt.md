# fig-anchor-v2

AI-generated schematic for `dev_docs/design.qmd`, 语义是锚定在元素上、只追加的记录 → 锚点 (#sec-anchor) (figure type F8, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the first prompt below. All ten strings were exact, but three arrows started at single selectors (数据键, 结构路径, 数据空间区域), which read as if each selector had its own outcome. Rejected.
  2. v2 was a precise edit of v1 (second prompt below): one bracket spans the whole ladder and the three arrows leave from its middle. Accepted. Draft v1 was deleted.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0088. Every string was re-read on the quantized file.
- **Checked on the published `fig-anchor-v2.png`:**
  - the ten strings, character by character, each exactly once;
  - six selector chips in the order of `tbl-selectors`, blue fading to grey as stability drops;
  - one bracket spans all six chips; three arrows fan out from its middle to 唯一 (green ✓), 不唯一 (red) and 丢失 (red ✗);
  - the record card is joined to the ladder by a dotted orange-red line;
  - no logo or watermark.
- **Mapping to the text:**
  - ladder = the selector types in `tbl-selectors`, most stable first;
  - bracket = the anchor as a whole resolves to one of three outcomes.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus a few Latin words; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, header bands, pill-shaped chips, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "锚点带多个选择器，按稳定性从高到低依次尝试"
Subject:
- Left third: one small rounded card with an orange-red outline (#C8553D) and very light warm fill, containing three short grey lines that suggest text (no actual text). This is a record. A dotted orange-red line runs from it to the top of a vertical ladder in the middle.
- Middle third: a vertical ladder of six stacked pill-shaped chips, connected by short downward grey arrows (#87867F). The chips fade from strong blue at the top (#4C75AD outline, #CFE0F4 fill) to very pale blue-grey at the bottom (#C8C7BF outline, #F4F2EC fill). Chip texts, top to bottom: "数据键", "数据谓词", "结构路径", "角色", "数据空间区域", "元素 id".
- Right third: three result tags stacked vertically, each joined to the ladder by a thin grey arrow. Top tag: green outline and green text (#3B8C5A) with a ✓: "唯一：记录有效". Middle tag: red outline and red text (#D65451): "不唯一：失效，附上候选". Bottom tag: red outline and red text (#D65451) with a ✗: "丢失：失效".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients except the soft fade across the six chips
Composition/framing: landscape 16:9; title on top; record on the left, ladder in the middle, three results on the right
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD / #CFE0F4 for the selectors; orange-red #C8553D for the record and its dotted anchor line; green #3B8C5A; red #D65451
Text (verbatim, exactly these strings and nothing else): "锚点带多个选择器，按稳定性从高到低依次尝试", "数据键", "数据谓词", "结构路径", "角色", "数据空间区域", "元素 id", "唯一：记录有效", "不唯一：失效，附上候选", "丢失：失效"
Constraints: render every string exactly once with exactly these characters and punctuation; the only other symbols are one ✓ and one ✗; no additional text, icons, logos or watermark
```

## Prompt (v2, edit; reference image `dev_docs/figures/design/fig-anchor-v1.png`, role "edit target")

```text
Use case: precise-object-edit
Input images: Image 1: edit target.
Primary request: change only the connections between the ladder and the three result tags on the right. Remove the three grey arrows that start at individual chips ("数据键", "结构路径", "数据空间区域"). Instead, draw one tall thin grey curly bracket just to the right of the whole six-chip ladder, spanning from the top of the first chip to the bottom of the last chip; from the middle point of that bracket, draw three thin grey arrows that fan out to the three result tags. Keep the three result tags exactly where they are.
Constraints: keep everything else exactly unchanged: the title, the record card and its dotted orange-red line, all six chips, their colors and order, the three result tags with their colors, ✓ and ✗, all fonts and spacing. Text that must remain, exactly once each: "锚点带多个选择器，按稳定性从高到低依次尝试", "数据键", "数据谓词", "结构路径", "角色", "数据空间区域", "元素 id", "唯一：记录有效", "不唯一：失效，附上候选", "丢失：失效". No additional text, icons, logos or watermark.
```
