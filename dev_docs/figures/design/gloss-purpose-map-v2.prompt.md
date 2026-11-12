# gloss-purpose-map-v2

将图中语义扩展为角色与结构、数据与领域含义、关系与分组、声明与证据、叙事与无障碍、交互与协作。 概念示意，非产品截图、实验结果或工期表。

- **Generated:** built-in `image_gen`，2026-11-12；使用 imagegen skill，未指定或推断底层模型版本，未使用 CLI fallback。
- **Request:** 扩展上一版过于局限于数据行绑定的语义展示；采用用户参考图的浅色科技感、半透明分层、绿色渐变与橙色强调。
- **Source of truth:** `dev_docs/design.qmd` 中分类、层级、关系、声明核验、记录层、锚点、语义、交互、投影与实施计划各节；`plan/2026-11-12-agent-path.md`。实现状态参考既有项目审计及本次读取的 `79cfaa0`，后者已落地最小 `gl_propose()`，完整 agent 路径仍在开发。
- **Scope:** 扩展说明内容，不增加或变更实现计划。首个行绑定实验不是项目全部语义范围。
- **Input image 1:** `gloss-purpose-map-v1.png`，修改对象；保留项目边界，重新设计构图与表现。
- **Input images 2–3:** 用户提供的浅绿玻璃分层参考图，仅作风格参考，不借用其文章、模型、记忆系统或实验数据。
  - `/var/folders/pb/t9j6hdrn0m3g8r50g03107dr0000gn/T/codex-clipboard-5a60e288-ce18-4316-a9e3-aa0e1bf5afce.png`
  - `/var/folders/pb/t9j6hdrn0m3g8r50g03107dr0000gn/T/codex-clipboard-494ca7df-5d17-48ad-91fa-ca75b473e70d.png`
- **Final asset:** `gloss-purpose-map-v2.png`；原生生成输出保存到项目目录，v1 保留。
- **Rounds:** 1 次生成，无定向返修；1672 × 941 PNG，1950903 bytes。
- **Native source:** `/Users/xiayh/.codex/generated_images/01a1d0d8-c77c-7400-b780-688a425f088b/exec-f7972610-e2a5-449b-ba41-bb2809d8a030.png`。
- **Checked:** 全图目视检查；六类语义都有具体图形示例，原图、结构、语义三层可辨，差异声明标为“待核验”，目标与已实现能力分开。中文与边缘无明显缺字、裁切、重叠。保存文件与原生输出逐字节相同，未做像素后处理。
- **SHA-256:** `8ef35e42b7a0b411a137aa2fca68e1326864a263e554d9a94926dff6535a7f05`。

## Generation prompt

```text
Use case: style-transfer / scientific-educational infographic.
Asset: image 1 of a matched pair of Chinese project explanation slides for gloss, an R package.
Input roles: Image 1 is the old gloss purpose diagram to redesign; preserve its project identity and its distinction between current implementation and future goals, but REPLACE its narrow data-row-only explanation and its flat visual design. Images 2 and 3 are STYLE REFERENCES ONLY. Do not reuse their Agent memory, Dreaming, model, Pokemon, benchmark, or other factual content.

Primary request: Create a much broader, concrete visual explanation of figure semantics, in the elegant LIGHT SCIENCE/TECH style of the references. A polished widescreen 16:9 landscape slide, preferably 2560×1440, complete within safe margins. Ivory background, pale sage and mint translucent glass plates with believable thickness, soft cast shadows, dark forest green typography, small orange accents and flowing connectors. Subtle cyan in lower layers. Crisp readable Simplified Chinese sans-serif, generous spacing. More dimensional and technological than the old flat diagram; calm, sophisticated, luminous; no dark cyberpunk. Use light botanical-colored abstract corner ribbons like the reference, very restrained. Tiny human/agent icons allowed but diagrams remain dominant.

Title exact: "gloss：让图中的元素承载多层语义"
Subtitle exact: "从点、线与色块，到角色、关系、证据与可用知识"
Top-left small sequence marker: "01 / 02".

Composition: A large CENTRAL exploded stack of three translucent plates, taking about the middle third of the slide, surrounded by SIX clearly separated visual explanation cards, three on the left and three on the right. Each card has a number, short heading, one concrete MINI-DIAGRAM and at most two short lines of copy. Fine connected leader lines point from the cards to appropriate parts of the central figure. Connections are meaningful, not decorative spaghetti. Bottom a wide quiet takeaway band and small status footer.

Central hero: a scientific MULTIPANEL R FIGURE on the bottom plate, not just a single scatterplot: a two-series plot with axes and a legend, a heatmap with a highlighted row group, a small phylogenetic tree with a highlighted named clade, and a two-group comparison with an interval or comparison bracket. Illustrative charts only; no fabricated research metrics. Their geometry is visibly preserved on the plate. Middle plate is a small structural graph plus data table tied to several plot elements. Top plate is a few small semantic record cards with relation links, an evidence tag, and a review comment. Show anchor connections vertically across the plates so the same marks are grounded. Plate labels exact:
bottom "原图"
middle "数据与结构"
top "语义记录"
Small caption under central hero: "散点 · 热图 · 树 · 复合图"
Small subtle caption: "原图几何保留"

LEFT CARD 1:
Heading exact: "① 角色与结构"
Mini-diagram: one magnified plot with a data dot circled, an axis indicated, a legend swatch and a panel frame visually distinguished.
Copy exact: "数据点、坐标轴、图例、面板"
Second line exact: "知道“它是什么、属于哪里”"

LEFT CARD 2:
Heading exact: "② 数据与领域含义"
Mini-diagram: plotted element connected to a sample card, a DNA/gene icon, and a labeled tree tip, with a small source-document icon. Convey row data AND domain identity/context.
Copy exact: "样本、基因、物种、实验条件"
Second line exact: "含义与来源一起保留"

LEFT CARD 3:
Heading exact: "③ 关系与语义分组"
Mini-diagram: a legend swatch linked to its same-color curve; a tree label linked to a clade; two dashed group outlines spanning panels.
Copy exact: "图例 ↔ 系列；标签 ↔ 分支"
Second line exact: "同一语义分组可跨面板"

RIGHT CARD 4:
Heading exact: "④ 声明与证据"
Mini-diagram: two simple group distributions with comparison bracket, a short claim card attached to the bracket and its evidence/check icon. Use an amber status tag "待核验"; do not put a green truth check on an arbitrary opinion.
Copy exact: "差异、趋势、异常、不确定性"
Second line exact: "可算的核验；推测明确标记"

RIGHT CARD 5:
Heading exact: "⑤ 叙事与无障碍"
Mini-diagram: reading route through panels marked 1→2→3, then a text description card and an audio/navigation icon. Show how a complex figure can be explained step by step.
Copy exact: "阅读顺序、关键结论、文字描述"
Second line exact: "让人和机器都能理解"

RIGHT CARD 6:
Heading exact: "⑥ 交互与协作"
Mini-diagram: the same selected orange sample/group lights up across a scatter panel and a heatmap, next to human and agent comment bubbles and a short revision timeline.
Copy exact: "联动高亮、批注、复核与修订"
Second line exact: "保留来源、状态与历史"

Takeaway band exact, visually prominent but not competing with title:
"一张图，成为可理解、可追问、可审阅、可复用的知识载体"
Small under-band supporting line exact:
"目标设计：语义独立保存；图更新后重新定位与核验"
Footer exact:
"愿景示意｜已实现：捕获、查询、部分绑定、图包｜其余能力分阶段建设"
Small bottom-right date: "2026-11-12".

Accuracy constraints: This is a conceptual vision, NOT a claim these six capabilities are all shipped. No charts with invented numerical performance, no completion percentages. Binding is just ONE grounding layer. Semantics also includes structural role, relations/groups, domain meaning, checkable claims, narrative, accessibility, interaction, provenance and review. A subjective note is not proven by code; only computable claims have computational evidence. Do not imply the agent redraws the original geometry. Do not copy content from the style references. No dense paragraphs, no illegible microscopic UI code, no watermark.
```
