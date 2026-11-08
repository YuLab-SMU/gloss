# fig-views-v3

AI-generated schematic for `dev_docs/design.qmd`, 代码能确定的不交给模型 → 从 grob 树重建结构 (#sec-hierarchy) (figure type F7, stylized; not data).

- **Generated:** `openai/gpt-image-2.6-sunburst` · quality `medium` · size `1824x1024` · n 1 · 2026-11-08
- **Reference image:** `dev_docs/figures/design/fig-decisive-v1.png`, role "style anchor" (layout and text not copied)
- **Rounds:**
  1. v1 from the prompt below. Nine of ten strings were exact; the right card's footer read "表自构建数据" instead of "来自构建数据".
  2. v2 was a text-localization edit of v1 asking for that one character (second prompt below). The character was still wrong. Rejected.
  3. v3 = v1 plus a deterministic fix with PIL: the wrong first character was painted over with the sampled card colour `(249, 248, 243)` in the box `[1166, 447, 1211, 491]`, and "来" was drawn in Hiragino Sans GB W6 (`/System/Library/Fonts/Hiragino Sans GB.ttc`, index 2) at 37 px, position `(1171, 451)`, colour `(122, 119, 113)`, sampled from the neighbouring characters. Drafts v1 and v2 were deleted.
- **Post-processing:** Resized to 1600 px wide with metadata stripped, then quantized to a 128-colour PNG8 (`magick in.png -resize 1600x -strip r.png && magick r.png -colors 128 -dither None PNG8:out.png`). Normalized RMSE between the resize and the quantized file: 0.0064. Every string was re-read on the quantized file.
- **Checked on the published `fig-views-v3.png`:**
  - the ten strings on v3, character by character, each exactly once; the redrawn "来" matches the weight and colour of "自构建数据" at 100% and 300% zoom;
  - a row of twelve dark dots is linked by blue lines to both trees above and by dashed orange-red lines to two dashed orange-red groups below;
  - no logo or watermark.
- **Mapping to the text:**
  - top left = structure tree (from the grob tree); top right = data tree (from built data); bottom = semantic groups defined by an agent or a person;
  - the dots in the middle = the same drawn elements seen by all three views.

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: explanatory schematic for a Chinese design document (stylized, not data). Visible text is Simplified Chinese plus the Latin letter "B" and the word "agent"; render every character exactly.
Input images: Image 1: style anchor from the same document. Match its canvas color, rounded cards and thin grey borders, header bands, fonts, colors and spacing. Do not copy its layout and do not copy any of its text.
Scene/backdrop: flat warm ivory canvas, color #F0EEE6
Title (verbatim, centered at top, bold sans-serif, near-black #1F1E1D): "同一批元素，三种视角，互相映射"
Subject:
- Across the middle of the canvas, a horizontal row of about twelve small dark grey dots: the drawn elements.
- Above the row, two cards side by side. Left card header: "结构树"; body: a small blue (#4C75AD) tree diagram of thin lines and small nodes, with one line of monospace text under the tree: "图 → 面板 → 图层 → 标记"; footer in muted grey (#87867F): "来自 grob 树". Right card header: "数据树"; body: another small blue tree diagram, with the monospace line "表 → 系列 → 行"; footer in muted grey: "来自构建数据". Thin blue lines run from the leaves of both trees down to the dots, so each dot is reached from both trees.
- Below the row, one card centered. Header: "语义分组"; body: two orange-red (#C8553D) dashed rounded outlines that each enclose a few of the dots above them via dotted orange-red lines, and the text inside the card: "离群点 · 处理组 B"; footer in muted grey: "由 agent 或人定义".
Style/medium: clean flat vector-style editorial diagram, generous whitespace, no shadows, no gradients
Composition/framing: landscape 16:9; title on top; two tree cards above, the element row in the middle, the grouping card below
Color palette: canvas #F0EEE6; ink #1F1E1D; greys #3D3D3A, #87867F, #C8C7BF; blue #4C75AD for what code determines; orange-red #C8553D for what people or agents define
Text (verbatim, exactly these strings and nothing else): "同一批元素，三种视角，互相映射", "结构树", "图 → 面板 → 图层 → 标记", "来自 grob 树", "数据树", "表 → 系列 → 行", "来自构建数据", "语义分组", "离群点 · 处理组 B", "由 agent 或人定义"
Constraints: render every string exactly once with exactly these characters and punctuation; no node labels other than these strings; no additional text, icons, logos or watermark
```

## Prompt (v2, edit; reference image `dev_docs/figures/design/fig-views-v1.png`, role "edit target")

```text
Use case: text-localization
Input images: Image 1: edit target.
Primary request: replace only the grey footer text in the right card, which currently reads "表自构建数据", with exactly "来自构建数据" (the first character must be 来, not 表). Use the same font, size, color and position.
Constraints: change only that one footer text; preserve everything else exactly: layout, both trees, all blue lines, the dots, the semantic grouping card with its dashed orange-red outlines, all other text, typography, colors and spacing. Text that must appear, exactly once each: "同一批元素，三种视角，互相映射", "结构树", "图 → 面板 → 图层 → 标记", "来自 grob 树", "数据树", "表 → 系列 → 行", "来自构建数据", "语义分组", "离群点 · 处理组 B", "由 agent 或人定义". No additional text.
```
