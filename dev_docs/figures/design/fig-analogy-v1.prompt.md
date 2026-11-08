# fig-analogy-v1

AI-generated illustration for `dev_docs/design.qmd`, 简单地说 → 贯穿全文的类比：手抄本批注 (#sec-analogy) (figure type F15/F16, analogy illustration in the hero's series).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `high` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/hero-manuscript-gloss-v1.jpg`, role "style anchor" (composition not copied)
- **Rounds:**
  1. v1 from the prompt below; accepted in the first round.
- **Post-processing:** `magick fig-analogy-v1.png -resize 1600x -strip -quality 86 fig-analogy-v1.jpg`; the PNG was not kept.
- **Checked on the published `fig-analogy-v1.jpg`:**
  - the five strings, character by character, each exactly once: "手抄本批注与 gloss 一一对应", "正文一笔不改 = 图的几何", "批注 = 记录", "引线 = 锚点", "不同笔迹 = 不同作者";
  - the central scatter plot is crisp, with sharp dots and a downward trend;
  - two vermilion glosses, each joined by one straight vermilion leader line that ends on a dot;
  - "批注 = 记录" points at a vermilion gloss, "引线 = 锚点" at a leader line, "正文一笔不改 = 图的几何" into the plot, and "不同笔迹 = 不同作者" at a gloss in a different hand;
  - the marginal script is illegible by design; no logo or watermark.
- **Mapping to the text:**
  - page text, never rewritten = the figure's geometry;
  - glosses = records;
  - leader lines = anchors;
  - different hands = different authors (people or agents).

## Prompt (v1)

```text
Use case: scientific-educational
Asset type: analogy illustration for a Chinese design document (an analogy, not the system itself). Visible text is Simplified Chinese plus the Latin word "gloss"; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its medium for the manuscript page: aged vellum, brown iron-gall ink marginal glosses in several hands, a crisp modern scatter plot printed in dark ink as the central block, vermilion leader lines. Do not copy its composition.
Primary request: one glossed manuscript page, seen flat and straight-on, placed in the centre of a plain warm ivory canvas (#F0EEE6) with wide empty margins on the left and right. The central block is a crisp scatter plot in dark ink (about twenty sharp round dots). In the page margins, illegible script-like glosses in brown ink in clearly different handwriting styles; two of the glosses are in vermilion ink (#C8553D) and connect to two dots with fine straight vermilion leader lines that end exactly on those dots.
Around the page, on the ivory canvas outside it, four clean modern callout labels in dark sans-serif (#1F1E1D) on small white rounded tags with thin grey borders (#C8C7BF), each joined by a thin straight grey line (#87867F) to the part it names:
- left, upper: "正文一笔不改 = 图的几何", line ending on the central scatter plot
- right, upper: "批注 = 记录", line ending on a vermilion marginal gloss
- right, lower: "引线 = 锚点", line ending on a vermilion leader line
- left, lower: "不同笔迹 = 不同作者", line ending on a brown marginal gloss
Title (verbatim, centered at top on the ivory canvas, bold sans-serif, near-black #1F1E1D): "手抄本批注与 gloss 一一对应"
Style/medium: flat high-resolution scan of a real archival page combined with clean modern editorial callouts; no perspective distortion
Composition/framing: landscape 16:9; title on top; the page in the centre occupying about half the width; callouts in the ivory space on both sides
Color palette: parchment, sepia and brown ink; vermilion #C8553D for the two glosses and their leader lines; warm ivory canvas #F0EEE6; callout tags white with grey borders
Text (verbatim, exactly these strings and nothing else): "手抄本批注与 gloss 一一对应", "正文一笔不改 = 图的几何", "批注 = 记录", "引线 = 锚点", "不同笔迹 = 不同作者"
Constraints: render every string exactly once with exactly these characters; the glosses on the page are illegible script with no readable letters; no additional text, logos or watermark
```
