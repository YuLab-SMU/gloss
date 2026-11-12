# gloss-route-map-v2

用多类结构化提议、分类型核验、记录与多种呈现解释技术路径，并保留 M0–M5 及近期实验的真实状态。 概念示意，非产品截图、实验结果或工期表。

- **Generated:** built-in `image_gen`，2026-11-12；使用 imagegen skill，未指定或推断底层模型版本，未使用 CLI fallback。
- **Request:** 扩展上一版过于局限于数据行绑定的语义展示；采用用户参考图的浅色科技感、半透明分层、绿色渐变与橙色强调。
- **Source of truth:** `dev_docs/design.qmd` 中分类、层级、关系、声明核验、记录层、锚点、语义、交互、投影与实施计划各节；`plan/2026-11-12-agent-path.md`。实现状态参考既有项目审计及本次读取的 `79cfaa0`，后者已落地最小 `gl_propose()`，完整 agent 路径仍在开发。
- **Scope:** 扩展说明内容，不增加或变更实现计划。首个行绑定实验不是项目全部语义范围。
- **Input image 1:** `gloss-route-map-v1.png`，修改对象；保留项目边界，重新设计构图与表现。
- **Input images 2–3:** 用户提供的浅绿玻璃分层参考图，仅作风格参考，不借用其文章、模型、记忆系统或实验数据。
  - `/var/folders/pb/t9j6hdrn0m3g8r50g03107dr0000gn/T/codex-clipboard-5a60e288-ce18-4316-a9e3-aa0e1bf5afce.png`
  - `/var/folders/pb/t9j6hdrn0m3g8r50g03107dr0000gn/T/codex-clipboard-494ca7df-5d17-48ad-91fa-ca75b473e70d.png`
- **Final asset:** `gloss-route-map-v2.png`；原生生成输出保存到项目目录，v1 保留。
- **Rounds:** 1 次生成，无定向返修；1672 × 941 PNG，1989779 bytes。
- **Native source:** `/Users/xiayh/.codex/generated_images/01a1d0d8-c77c-7400-b780-688a425f088b/exec-bd50cdf5-ddf1-4fec-8450-1fff3aa71195.png`。
- **Checked:** 全图目视检查；提议进入核验，检查通过的事实及明确标记的推测进入记录，失败箭头返回提议者；图更新箭头回到核验。M0 已完成、M1 部分完成、M4 开发中、M2/M3/M5 待完成；顶部是目标路径。中文与边缘无明显缺字、裁切、重叠。保存文件与原生输出逐字节相同，未做像素后处理。
- **SHA-256:** `da9c0277d3d4663382fb20fd7d11a10c91964e0c7eb813b1fe5d6c857bbae3cb`。

## Generation prompt

```text
Use case: style-transfer / scientific-educational infographic.
Asset: image 2 of the matched pair of Chinese gloss project explanation slides.
Input roles: Image 1 is the old gloss technical roadmap to redesign; preserve the overall project/implementation-vs-goal distinction, but widen the semantic payload beyond row binding and replace the flat styling. Images 2 and 3 are STYLE REFERENCES ONLY, for material, layout rhythm, typography, depth and colors. Never copy their memory/Dreaming/model claims or numbers.

Primary request: a polished widescreen 16:9 landscape Chinese roadmap, preferably 2560×1440, with luminous translucent sage/mint glass, ivory backdrop, forest-green headers, orange emphasis, soft shadows, subtle cyan lower plates, fine clean technical connections. Use the light dimensional science/technology editorial infographic style from the reference. Plenty of breathing room and readable Simplified Chinese sans-serif. Complete safe margins. This is a conceptual architecture plus capability status map, not a delivery schedule.

Title exact: "gloss：多层语义如何生成、核验与使用"
Subtitle exact: "行绑定是起点；完整目标覆盖含义、关系、声明、叙事与交互"
Top-left sequence marker: "02 / 02".

LAYOUT: top half for a clear left-to-right technical journey; below it one row of SIX milestone tiles; bottom a narrow current-priority experiment band. Keep every section readable. Use visual miniatures rather than paragraphs.

TOP TECHNICAL JOURNEY, five distinct stages from left to right:
STAGE 1 (~14% width): show original R chart on a glass window plus R/code and table, with more than a scatter plot (heatmap/tree visible).
Heading exact "原图与数据"
Caption exact "由原绘图设备捕获"
STAGE 2 (~17%): a few translucent structural plates, with plot mark, axis, legend, panel hierarchy and a table visibly joined.
Heading exact "可查询的底座"
Caption exact "元素 · 结构 · 数据 · 上下文"
Small bottom tag spanning stages1–2 exact "几何与确定规则由代码负责"
STAGE 3 (~18%): human and small professional robot icons above a stack of different structured proposal cards with labels "含义" "关系" "声明" "叙事" "交互", not merely one data table.
Heading exact "人 / AI 提议"
Caption exact "共用结构化入口"
Small caption exact "agent 循环：aisdk"
A clear arrow leads from substrate to proposer, then from proposer into validation.
STAGE 4 (~25%): central visible verification gate/shield "提交即核验", with compact subtitle "格式 · 锚点 · 声明检查". Distinguish exactly THREE branches:
green branch card "事实：检查通过"
pale amber branch card "推测：明确标记"
orange failure branch card "失败：返回修改"
Green and pale-amber branches go right to record storage (speculative records stay visibly labeled, never become verified facts). Failure branch arrow curves back to stage3's proposer. NO failure→storage arrow. No direct proposer→storage bypass.
Tiny supporting caption below validation exact "通过检查 ≠ 所有观点已被证明"
STAGE 5 (~22%): stacked transparent record layers next to a small multi-panel interactive figure window, a text/accessibility card, and a review-history icon. Highlight links between plot panels; include a small feedback arc from update to recheck.
Heading exact "记录与多种呈现"
Caption exact "联动 · 讲解 · 无障碍 · 审阅"
Small update loop label exact "图更新 → 重新定位与核验"
Record storage miniature shows exact short tags "来源" "状态" "依赖" "版本".
Arrows in technical journey must unambiguously show proposal→validation→accepted records; failed proposal→repair. Treat the full top journey as goal architecture, do not color it entirely completed.
Small section tag above journey: "目标技术路径".

MILESTONE SECTION:
Heading exact "M0—M5：能力地图"
Small legend with colors+words (not color alone): green "已完成", orange "部分 / 开发中", gray "待完成".
Six evenly spaced translucent rounded glass tiles, same size. Slight orange focus on M1 and M4. Each tile contains milestone id, icon, heading, status, and a single detail line.
M0:
"可信底座"
green status "已完成"
detail "捕获 · 查询 · 图包"
M1:
"识别与组织"
orange status "部分完成"
detail "绑定已有，角色与分层待做"
M2:
"记录与锚点"
gray status "待完成"
detail "可追溯 · 可重挂"
M3:
"语义与呈现"
gray status "待完成"
detail "声明核验 · 交互 · 无障碍"
M4:
"agent 工具"
orange status "开发中"
detail "工具试验与最小提议入口"
M5:
"价值评测"
gray status "待完成"
detail "同模型 · 同预算对照"
Avoid sequential completion implied by uniform green arrows: these are capabilities, and M4 work can begin before full M2/M3.

BOTTOM CURRENT PRIORITY BAND with very restrained amber glow:
Left bold tag exact "近期主线"
Middle exact "最小工具与提议入口"
Arrow to three experiment cards under heading exact "开发图上的三组对照"
Card1 "模型 + 原始材料"
Card2 "模型 + gloss"
Card3 "纯代码枚举"
Small takeaway exact "先检验核心增益，再扩展完整语义系统"
Footer exact: "能力地图，非工期表｜完整闭环仍在建设｜2026-11-12"

Accuracy constraints: gloss is an R package whose geometry is captured from the original device; agents never write SVG or redraw original marks. aisdk owns the agent loop. Human/AI proposals are schema-constrained data. Strict invalid proposals cannot be accepted; an accepted opinion is explicitly an opinion, never a proven fact. Verification re-runs after substrate changes. Do not imply full semantic records, interaction/accessibility/projection or update are already implemented. Avoid any invented metric, benchmark number, scheduled date, or completion percentage. The tiny status text must be legible. No memory/Dreaming content from reference images.
```
