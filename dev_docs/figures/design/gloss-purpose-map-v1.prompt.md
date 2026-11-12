# gloss-purpose-map-v1

普通 R 图、gloss 语义层与终极使用体验。AI 生成的概念示意，不是产品截图、实验数据或工期表。

- **Generated:** built-in `image_gen` tool；2026-11-12。未指定或推断底层模型版本。
- **Source of truth:** `dev_logs/2026-11-12-project-status-audit.md`（代码基线 `b48c373`）；当前 agent-path 计划；设计文档的 M0–M5 能力划分。
- **Purpose:** 用户要求将项目作用、终极目标、里程碑和技术路径形象化。
- **References:** 无图像参考；文字来自本次会话中核对过的项目状态。
- **Rendering:** 原生图片生成；不以代码绘制图形替代图片生成。
- **Final asset:** `gloss-purpose-map-v1.png`；第二轮生成结果，原样复制到项目内；未做像素后处理。
- **Rounds:** 1 次初始生成 + 1 次定向编辑。
- **Checked:** 六类普通 R 图可辨识；输入明确为 R 图对象或绘图代码与数据；透明图层保留原图；目标体验标为示意；已实现与待实现分列；中央卡片只声称配对核验通过。 全图文字与边界经目视检查，无明显裁切、重叠或缺字。

## Revision intent

首轮图把一条自由文字批注旁边写成泛化的“核验通过”。定向修改为“关注这个样本”及“配对核验”，避免暗示代码能证明任意自然语言意见。

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: Chinese illustrated project explainer, first of a two-image set, high resolution landscape 16:10. This is an AI-generated conceptual diagram for a real software research project, NOT a screenshot and NOT experimental data.
Primary request: Make the usefulness of gloss instantly understandable to a Chinese-speaking R visualization researcher who finds architecture prose too abstract. Show ordinary, recognizable R visualization outputs and a vivid ultimate user experience. Mostly pictures, not text boxes. Clean editorial scientific illustration, warm ivory background, ink-navy text, crisp charts, restrained teal and amber highlights, no photorealism, no robots, no decoration without meaning. Large legible simplified Chinese typography, generous space, strong hierarchy.
Title, exact: "gloss：给普通 R 图加上可核验的语义"
Subtitle, exact: "原图几何保留，数据关联与批注叠加"

Composition: Three visual areas read from left to right.
LEFT, roughly 24% width, label "作用于什么". A tidy gallery of six miniature, recognizable scientific charts on paper: scatter plot, bar chart, box plot, colored heatmap, phylogenetic tree, multi-panel composite. Give exact short labels "散点图", "柱状图", "箱线图", "热图", "系统树", "拼图". Under this gallery show a small R code document plus a data-table document joining the charts, caption "R 图对象／绘图代码＋数据". This is not an arbitrary screenshot recognition pipeline.
CENTRE, roughly 36% width, label "gloss 加上什么". An exploded view of ONE ordinary scatterplot sheet with a downward cloud of about 15 precise dots, plus two translucent aligned sheets slightly lifted above it. The bottom sheet carries the same original plot intact, labelled "原图". Middle translucent sheet connects one point to a highlighted table row using a fine leader, labelled "元素 ↔ 数据行". Top sheet carries one note with a small author avatar, a check result, and a modest timestamp icon, labelled "批注＋核验记录". This should feel like adding transparent annotation sheets over a chart, never changing its geometry. Dotted alignment guides tie the same selected point across layers. A clear restrained arrow from LEFT into this stack.
RIGHT, roughly 35% width, a large light-blue goal area with conspicuous badge "终极目标 · 示意". Four compact illustrated outcome vignettes, each with ONE short exact title and no paragraph:
1 "点一下，追到数据": chart cursor selecting a dot, visibly linked to the highlighted row of a small table.
2 "问一句，回答带证据": speech bubble beside a plot linked to a tiny data table and an evidence tick; a question is directed to an assistant, the check comes from code. No claim of omniscience.
3 "加批注，知道谁写、是否核验": note pinned to a plot, avatar, small check/warning symbols, a stack showing records retained.
4 "更新图，批注仍能跟随": two mini versions of a plot connected by an update arrow; same data identity highlighted in both, annotation follows; a small amber detached note has the tiny label "失效需修复". Show continuity plus explicit repair for anything that cannot be reanchored.
Arrow from the centre layered chart into these outcomes.

A slim bottom band with two clearly separated factual statuses:
Teal band text exact "今天已实现：捕获、元素查询、行绑定、图包存取"
Grey-blue band text exact "目标尚待完成：完整批注、交互、更新与 agent 链条"
Footer exact "概念示意，非产品截图｜状态基线：2026-11-12"
Constraints: Show common charts clearly. No quantitative benchmark claims, progress percentages, pretend screenshots, timelines/durations, product logos or watermarks. Do not invent input support outside R. No AI-generated geometry presented as actual gloss output. Small text limited to the labels above. Chinese characters must be correct and readable. Every arrow must have an obvious visual source and destination.
```

## Targeted edit (round 2)

首轮图把一条自由文字批注旁边写成泛化的“核验通过”。定向修改为“关注这个样本”及“配对核验”，避免暗示代码能证明任意自然语言意见。

```text
Edit target: the supplied Chinese gloss purpose infographic. Keep the exact entire composition, layout, charts, Chinese titles, typography, palette, 16:10 canvas, footer, and bottom status bands. Make ONLY this factual text correction in the top annotation card of the CENTRAL stack: replace the current note claiming a "high-value sample" with the exact shorter text "批注：关注这个样本"; replace the generic line "核验：通过（由代码）" with "配对核验：通过（由代码）". This makes clear that code checked the element-to-data-row pairing, not the truth of any free-form human opinion. Keep the author avatar and timestamp. Keep all other image regions unchanged. Ensure the shorter note and check line are beautifully aligned inside the same existing card with no clipping. This remains a conceptual illustration, not a screenshot.
```
