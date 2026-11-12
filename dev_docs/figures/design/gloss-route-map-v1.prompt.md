# gloss-route-map-v1

技术路径、M0–M5 能力地图与近期验证主线。AI 生成的概念示意，不是产品截图、实验数据或工期表。

- **Generated:** built-in `image_gen` tool；2026-11-12。未指定或推断底层模型版本。
- **Source of truth:** `dev_logs/2026-11-12-project-status-audit.md`（代码基线 `b48c373`）；当前 agent-path 计划；设计文档的 M0–M5 能力划分。
- **Purpose:** 用户要求将项目作用、终极目标、里程碑和技术路径形象化。
- **References:** 无图像参考；文字来自本次会话中核对过的项目状态。
- **Rendering:** 原生图片生成；不以代码绘制图形替代图片生成。
- **Final asset:** `gloss-route-map-v1.png`；第二轮生成结果，原样复制到项目内；未做像素后处理。
- **Rounds:** 1 次初始生成 + 1 次定向编辑。
- **Checked:** 五站技术路径清楚；提议表流向检查；通过进入记录，失败返回提议者；M0 完成、M1 部分、M4 前置试验、M2/M3/M5 待完成；近期对照明确使用开发图、三组条件，无虚构完成率。 全图文字与边界经目视检查，无明显裁切、重叠或缺字。

## Revision intent

首轮核验节点的箭头有歧义：提议表与检查之间的方向、通过/失败两路的去向需要纠正。第二轮只调整该节点及其相邻连接。

## Prompt (v1)

```text
Use case: infographic-diagram
Asset type: Chinese illustrated technical route and milestone map for gloss; second of a two-image set, high resolution landscape 16:10. Audience: a researcher needing to regain a clear picture of project scope and progress. This is a conceptual status map, not a schedule.
Style: clean scientific editorial illustration, warm ivory background, navy ink, crisp line-art chart/table/document icons, teal for implemented, amber for partial or preliminary, light grey-blue with dashed edges for planned. Generous whitespace, large readable simplified Chinese. Avoid walls of text. No 3D machinery, robots, gratuitous icons, watermarks, photorealism.
Title exact "gloss：技术路径、里程碑与当前位置"
Small legend exact "已完成" (teal) / "部分或试验" (amber) / "待完成" (grey). Footer exact "能力地图，不是工期表｜2026-11-12"

TOP HALF: label "技术路径". Draw a legible visual pipeline with FIVE clearly separated illustrated stations left to right, icons as large as text:
1 a paper scatter chart alongside R code and a table, label "R 图与数据".
2 graphics device outline surrounding a chart, a probe picks out a dot and its layer, label "原绘图设备", second line "捕获页面 · 记录归属".
3 transparent chart linked to a small structured table, label "语义底座", second line "元素 · 图层 · 数据行". Give stations 1–3 teal accents, while making explicit mapping is partial via tiny amber tag "绑定有边界".
4 a verification gate with proposed structured data on one side, green accepted output and a small amber rejected output on the other, label "提交即核验", second line "通过才记入". This station has a dashed grey planned border. Above it, two small actor icons, a person and abstract AI chat bubble, labelled together "人 / AI 提议", with a downward arrow entering ONLY this gate. A small footnote beneath actor label "agent 循环：aisdk". Draw a feedback arrow from rejected output back to proposer.
5 a browser-like chart with a pinned annotation, table and update icon, label "记录与投影", second line "批注 · 交互 · 更新". Dashed grey goal border.
A thin bracket or bottom annotation under station 2–3 exact "几何与检查由代码负责".
Do not suggest the model writes SVG. Do not suggest the full user-facing proposal API exists now. Static bundle save/read does exist, but final interactive view is the goal.

BOTTOM HALF: label "M0—M5 能力地图". Six equal compact cards in a single row. Each card holds milestone code, a concrete icon, title, state, one short caption. No percent-complete bars. No implied durations.
M0 title "可信底座", state "已完成", caption "捕获 · 查询 · 图包", teal.
M1 title "识别与绑定", state "部分完成", caption "绑定已做，角色待做", amber.
M2 title "记录与锚点", state "待完成", caption "批注可追溯、可重挂", grey.
M3 title "核验与交互", state "待完成", caption "声明检查、交互、无障碍", grey.
M4 title "agent 工具", state "前置试验", caption "工具调用已试，API 待做", amber.
M5 title "价值评测", state "待完成", caption "同模型、同预算对照", grey.
Connect cards by a very thin neutral line only, no thick completed timeline. Mark current state near M1 using exact "目前：底座＋部分绑定".

Below the six cards, one prominent amber PRIORITY RIBBON (not another milestone), label "近期主线". Two large steps connected by an arrow:
"gl_tools + propose" with a small tool and validation icon
→ "约 10 张开发图的三组对照" with three tiny equal lanes.
Under the three lanes use only three short labels "模型＋原始材料", "模型＋gloss", "纯代码枚举".
A short statement beneath ribbon exact "先验证核心增益，再扩完整系统".
This ribbon should visually communicate that the thin M4/M5 path is being pulled forward before completing all M1–M3 functionality, without tangled arrows.

Constraints: Preserve the exact M0, M1, M2, M3, M4, M5 codes in correct order and never duplicate them in other cards. M0 complete, M1 partial, M4 preliminary only, M2/M3/M5 not complete. Do not imply the A/B comparison has run. No statistics, invented dates, durations or score bars. Exact labels, no extra paragraphs. High visual clarity, station arrows should not cross.
```

## Targeted edit (round 2)

首轮核验节点的箭头有歧义：提议表与检查之间的方向、通过/失败两路的去向需要纠正。第二轮只调整该节点及其相邻连接。

```text
Edit target: the supplied Chinese gloss roadmap infographic. Preserve all exact text, six M0–M5 cards, state colors, title, footer, bottom priority ribbon, and all illustrations outside the fourth verification station and its immediate connecting arrows. Make ONLY a precise correction to arrows and routing in and beside the station "提交即核验". The intended directed graph is:
- station 3 (语义底座) flows rightwards to the proposal data table within station 4;
- the proposal data table flows RIGHTWARDS into the diamond check. The arrowhead between table and diamond must point toward the diamond, never toward the table;
- the diamond branches to the green top-right box "通过（记入）" and the amber bottom-right box "不通过（返回修改）";
- ONLY the GREEN "通过（记入）" output connects rightwards to station 5 "记录与投影". Draw its outbound connector clearly from the green box into the final station, not from the station border or the failed output;
- ONLY the AMBER "不通过（返回修改）" output has a feedback arrow up to the top "人 / AI 提议" box. Route this loop around the outside of the verification card and make its source visibly begin on the amber box and terminate at the proposer. The green output must NOT feed back to the proposer;
- keep the proposer's downward arrow entering the verification station.
Replace the existing contradictory or ambiguous connectors with these paths. Use clear thin navy lines and triangle arrowheads. Allocate a little more horizontal whitespace between stations 4 and 5 if required to separate the successful and retry routes, but keep all other sections intact. No crossing lines if possible; never route failed proposals into the record/projection station. Do not add any new label or alter any existing Chinese text.
```
