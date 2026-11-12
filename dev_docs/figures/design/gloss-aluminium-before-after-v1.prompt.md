# gloss-aluminium-before-after-v1

用同一张材料科学图展示加上 gloss 前后的目标体验；六类语义分别落在曲线、坐标轴、图例、跨面板比较点、数值声明、图解和审阅线程上。

- **Generated:** built-in `image_gen`，2026-11-12；使用 imagegen skill，未指定或推断底层模型版本，未使用 CLI fallback。
- **Input image 1:** `gloss-aluminium-original-v1.png`，由 R 对 NIST mds2-3090 中三次实际实验的原始数据绘图；图形与数值依据。
- **Input image 2:** `gloss-route-map-v2.png`，仅作浅色科技感、半透明绿色界面和橙色强调的风格参考。
- **Source data:** [NIST 数据集](https://data.nist.gov/od/id/mds2-3090)；本地文件与处理过程见 `data/aluminium-6061/README.md` 和 `src/gloss-aluminium-example.R`。
- **Scientific scope:** 试验 4655、4886、5327；每条曲线对应一次实验，非重复样本均值。初始温度、平均应变率、加热时间均不同。只核对选定实验的数值顺序，不推断温度因果效应。
- **Product scope:** AI 绘制的目标界面概念图，非已上线产品截图。数值计算来自独立 R 脚本，不宣称已通过 gloss 的完整声明、叙事或审阅系统执行。
- **Final asset:** `gloss-aluminium-before-after-v1.png`；图片生成原生输出原样复制到项目。
- **Exact research artifact:** `gloss-aluminium-original-v1.png` / `.svg` 为可复现 R 图；精确科学数据以此及 CSV 为准。
- **Rounds:** 1 次生成，无返修调用；输出 1586 × 992 PNG，1872113 bytes。
- **Native source:** `/Users/xiayh/.codex/generated_images/01a1d0d8-c77c-7400-b780-688a425f088b/exec-2aeb681a-0b20-40bf-a1c0-0dcad30ca79b.png`。
- **Checked:** 全图目视检查：前后均包含相同的双面板、三色曲线、初始温度及舍入应力；六类语义分别锚定角色说明、试验信息、关联高亮、数值检查、图解导航和审阅线程。元数据与 R 输出一致；明确标出目标界面和示例批注。无明显裁切、遮挡关键数据、文字缺失或布局重叠。
- **SHA-256:** `02535150913c94ae50b6de21aebb0e1c5d9ebc6d54bf787b37db1e76eeb36c92`。工作区图片与原生生成输出逐字节相同，无像素后处理。

## Generation prompt

```text
Use case: compositing / scientific-educational UI mockup.
Create ONE polished Chinese before/after comparison image showing how gloss could be used on ONE concrete scientific figure. This is a target product experience concept, not a screenshot of a shipping application.
Input roles:
- Image 1 is the ACTUAL scientific figure, rendered in R from NIST public experimental data. Use it as the visual and numerical ground truth. Place the SAME two-panel figure before and after; its curves, axes, values, legend mapping and panel ordering must remain the same. Preserve the real slightly noisy curves; do not substitute generic smooth schematic curves.
- Image 2 is STYLE ONLY: the earlier gloss technical map. Borrow its ivory, translucent mint glass, forest green typography, restrained orange accents, soft shadows and fine lines. DO NOT copy its architecture diagrams, roadmap, milestones or wording.

Subject: materials science, 6061-T6 aluminum alloy under dynamic compression. Absolutely NO biology, DNA, cells, medical topics, cybersecurity, shields, hacking or network diagrams. The research figure is the protagonist.
Format: large landscape 16:10, ideally 2560×1600. Big readable Simplified Chinese sans-serif. High-end light scientific software interface with soft 3D framing, while charts themselves are FLAT, sharp and unobstructed. Do not wrap the plots on tilted planes. Generous white space and ample margins.

Main title exact: "同一张科研图，加上 gloss 之后"
Subtitle exact: "6061-T6 铝合金压缩实验：六类语义落到曲线、图例、比较和审阅上"

LAYOUT:
LEFT about 28% width is the BEFORE: a plain paper-like panel titled "之前：静态科研图". Include the entire two-panel source figure at an easily legible size, with its three stress-strain curves (a) and three comparison points (b). Keep the scientific content correct. The long original footnote can be condensed to short exact label "NIST 真实数据 · R 绘图". Below it a small caption "读者自行对照图例、查数据与理解结论".
A small elegant orange arrow points to the right, labeled "叠加语义".
RIGHT about 68% width is the AFTER: a large realistic flat-on browser/app window titled "之后：围绕图中对象工作". This must feel like an actual product view, NOT six generic infographic cards. The workspace includes the same original two-panel plot occupying the LEFT 60% of this window and an inspector/sidebar occupying the RIGHT 40%. A top toolbar and bottom reading strip complete the window.
Use SIX numbered orange/green badges ①–⑥ placed directly at the corresponding UI controls or plot objects. Each badge has its semantic category in a short caption. Their placement should make it obvious how every category applies to THIS figure.

Scientific truth to preserve:
Panel (a): horizontal axis true strain ε, 0 to 0.5, unitless; vertical axis true stress σ, 0 to 500 MPa. Three measured traces:
dark green = initial 23°C, experiment 4655, upper curve around 350–400 MPa, ends at strain about 0.33;
cyan = initial 305°C, experiment 4886, middle curve around 220–270 MPa, ends about 0.384;
orange = initial 499°C, experiment 5327, lower curve around 80–95 MPa, ends about 0.459.
Keep the source's subtle uncertainty bands; they are data-file stress uncertainties, NOT replicate spread or 95% confidence intervals.
Vertical dashed guide at ε = 0.10.
Panel (b): horizontal initial temperature at 23, 305, 499°C; vertical stress in MPa. Same colors. Values at ε=0.10 from linear interpolation are 371, 252, 79 MPa (rounded). DO NOT invent performance metrics or significant differences.
Temperature is INITIAL temperature, not continuous measured temperature. Each curve is a single different experiment; this is not a controlled causal comparison.

EXACT UI STATES and SIX SEMANTIC CATEGORIES:
① "角色与结构" — a small active object-outline icon near panel (a) title, with a tiny outline list or tidy callout:
"图 → 面板(a) → 曲线"
A short tag connected to the shaded band reads "阴影：应力不确定度".
A small readable unit tag by the axis reads "ε 无量纲 · σ 单位 MPa".
This shows that axes, curves and the band have different roles.

② "数据与领域含义" — the CYAN 305°C curve is selected. Put a small orange selection ring on it near ε=0.10 and a cursor. A leader connects this selected curve to the TOP of the inspector with heading "选中：试验 4886". Inspector text exact:
"材料：6061-T6 铝合金"
"初始温度：305°C"
"平均应变率：2900 s⁻¹"
"原始数据行：91"
"ε ≈ 0.10，σ ≈ 252 MPa"
Small source chip exact: "NIST · 4886 CSV"
A small button exact "查看原始数据".
These are real metadata and rounded data from the selected trial, not invented values.

③ "关系与分组" — clearly show the cyan legend item "305°C · 4886", the cyan curve in panel (a), and the cyan 252 MPa point in panel (b) all selected together via small matching rings/background highlight. Thin connector or consistent glow shows the relationship. Do not shift or redraw the original marks.
Small nearby caption exact "同一试验：图例 ↔ 曲线 ↔ 比较点".
The other two traces stay visible.

④ "声明与证据" — middle inspector card with heading "这三次试验的数值比较". A checked green card with EXACT large line:
"ε = 0.10：371 > 252 > 79 MPa"
Small explanation exact:
"按各曲线线性插值，数值检查通过"
Small scope badge exact "仅限这三次试验"
Button exact "查看计算依据"
This verifies a numerical ordering only; never label a causal explanation or general temperature effect as proven. Use a clean numeric check, not a shield/security graphic.

⑤ "叙事与无障碍" — top toolbar includes a speaker icon and exact buttons "听图解" and "键盘导航". Bottom of the after workspace includes a small ordered reading strip, connected to the panels:
"实验条件 → 曲线走势 → 同应变比较"
A short accessible-text preview exact:
"在 ε = 0.10 处，三次试验应力约为 371、252、79 MPa。"
No long essay, no six disconnected cards.

⑥ "交互与协作" — bottom inspector is an anchored review thread with the selected cyan series shown as its target. A human avatar + exact heading "审阅者 A · 示例批注", and exact note:
"应变率也不同，先别归因于温度。"
Amber status "待复核"
Small visible controls "回复" and "查看历史"
A quiet line "锚定：试验 4886 · 保留修订记录".
This is a proposed review feature; do not imply a real scientist left this comment.

Footer in a slim full-width band:
Main exact: "图形保留；对象有含义，结论有依据，交互与审阅围绕同一对象展开。"
Small exact: "真实数据重绘｜gloss 目标体验示意，非已上线界面｜来源：NIST mds2-3090"
The UI can include the brand name gloss but no implementation details, code, APIs, milestones or JSON.

Readability requirements: Prioritize the actual selected curve, the large comparison numbers, and the anchored review. Six badge captions are short and readable. Both BEFORE and AFTER contain the same (a) and (b) panels and the same colors/values. Keep all six badges present exactly once as category labels (tiny object rings may repeat without numbers). Keep callouts outside data wherever possible. Never hide the entire chart under cards. The result should let a reader immediately imagine clicking, inspecting, comparing, listening and reviewing this real figure.
```
