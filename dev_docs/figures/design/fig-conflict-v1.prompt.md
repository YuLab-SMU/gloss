# fig-conflict-v1

AI-generated schematic for `dev_docs/design.qmd`, 语义是锚定在元素上、只追加的记录 → 冲突并存，裁决也是一条记录 (#sec-conflicts) (figure type F3, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0068. Every string was re-read on the quantized file.
- **Checked on the published `fig-conflict-v1.png`:**
  - the seven strings, character by character, each exactly once;
  - both record cards are anchored by dotted orange-red lines to the same ringed dot;
  - record A carries ✗ 检查未通过, record B carries ✓ 检查通过; a red lightning glyph sits under "冲突";
  - the resolution record is joined to both cards by grey dotted lines;
  - no logo or watermark.
- **Mapping to the text:**
  - two contradictory records coexist; the resolution is a third record with rationale and evidence;
  - B wins because its check passed, not because an agent wrote it (#sec-conflicts: a human claim that fails the data should not win).

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus the Latin letters "A", "B" and the word "agent"; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, header bands, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "矛盾的记录可以并存，裁决也是一条记录"
Subject:
- Top center: a small white card with a tiny grey scatter plot; one dot in it is ringed in orange-red. Two dotted orange-red lines (#C8553D) run down from this dot to two record cards.
- Middle row, two record cards side by side with orange-red outlines. Left card header: "记录 A · 人写"; under it a red line with a ✗ (#D65451): "检查未通过". Right card header: "记录 B · agent 写"; under it a green line with a ✓ (#3B8C5A): "检查通过". Between the two cards, a small red jagged lightning-style mark with the red label "冲突".
- Bottom center: a third, wider orange-red record card with a header band, text: "裁决记录：保留 B，附理由和证据". Two thin dotted grey lines run from it up to records A and B.
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; the figure card, then the two records, then the ruling, stacked from top to bottom
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; orange-red #C8553D for records and anchors; red #D65451; green #3B8C5A
Text (verbatim, exactly these strings and nothing else): "矛盾的记录可以并存，裁决也是一条记录", "记录 A · 人写", "检查未通过", "记录 B · agent 写", "检查通过", "冲突", "裁决记录：保留 B，附理由和证据"
Constraints: render every string exactly once with exactly these characters and punctuation; the only other symbols are one ✗ and one ✓; no faces or people; no additional text, icons, logos or watermark
```
