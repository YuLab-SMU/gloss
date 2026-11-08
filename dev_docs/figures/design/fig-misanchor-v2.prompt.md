# fig-misanchor-v2

AI-generated schematic for `dev_docs/design.qmd`, 风险与未决问题 (#sec-risks), selector-fallback bullet (figure type F3, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below. All strings were exact, but card 3 showed two dots inside the dashed region, so the region was no longer a unique match and the story broke.
  2. v2 = v1 plus an ImageMagick fix: the extra dot was painted over with the sampled card colour, `magick fig-misanchor-v1.png -fill "srgb(249,247,242)" -draw "circle 1487,570 1500,570" fig-misanchor-v2.png`. Draft v1 was deleted.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0057. Every string was re-read on the quantized file.
- **Checked on the published `fig-misanchor-v2.png`:**
  - the five strings and the chip labels, character by character; "数据键" and "区域" appear once in card 1 and once in card 2;
  - card 1: the record is attached to the ringed dot inside the dashed blue region;
  - card 2: that dot is gone (dashed ghost circle), "数据键" is crossed out in red, and a different dot lies inside the region;
  - card 3: exactly one dot inside the region, ringed, with the record attached and a red ✗ beside it;
  - no logo or watermark.
- **Mapping to the text:**
  - the worked example in the selector-fallback risk: a data-key selector is lost after a data subset, and the region selector silently resolves to another car;
  - the footer = one possible rule, to be decided in M2; this is an open design question, not an observed failure.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic (three-step comic strip) for a Chinese design document (stylized, not data). Visible text is Simplified Chinese only; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, header bands, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "选择器回退可能悄悄挂错目标"
Subject: three equal rounded cards in a row, left to right, joined by thin grey arrows. Each card has a header band with its caption and a body with a small scatter plot of grey dots on two thin axes. In every card a light blue dashed rectangle (#4C75AD, thin) marks the same small region of the plot.
- Card 1 header: "记录挂在一辆车上". Body: an orange-red record chip (#C8553D outline, no text) at the top right with a dotted orange-red line ending on one dot inside the dashed region; that dot is ringed in orange-red. Under the plot, two small chips side by side: a blue chip "数据键" and a light blue chip "区域".
- Card 2 header: "换了数据子集，数据键丢失". Body: the ringed dot is gone (a faint grey dashed empty circle marks where it was); a different grey dot now sits inside the dashed region. Under the plot, the chip "数据键" is crossed out with a red ✗ (#D65451) and the chip "区域" is plain.
- Card 3 header: "区域里恰好有另一辆车：唯一，但挂错了". Body: the dotted orange-red line from the record chip now ends on the other dot inside the region, which is ringed in red (#D65451) with a small red ✗.
- Under the three cards, centered, one line of dark grey text: "一种做法：前面的选择器丢失、后面的成功时，按不唯一处理".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; three cards in a row; the note at the bottom
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD for selectors; orange-red #C8553D for the record and its anchor; red #D65451 for the failure
Text (verbatim): "选择器回退可能悄悄挂错目标", "记录挂在一辆车上", "换了数据子集，数据键丢失", "区域里恰好有另一辆车：唯一，但挂错了", "一种做法：前面的选择器丢失、后面的成功时，按不唯一处理"; plus the chip labels "数据键" and "区域", each appearing once in card 1 and once in card 2. Nothing else.
Constraints: exactly these characters and punctuation; the only other symbols are two ✗; no car pictures, no axis labels or numbers; no additional text, logos or watermark
```
