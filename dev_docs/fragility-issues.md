# gloss 问题与缺口全景清单：资产最后一公里 · 智能体三元协作 · 捕获边界脆弱性（已验收归档）

> **归档状态**：**全部 23 项问题已完成 Schema v1.1.0 闭环落地与跨语言回归验证**（R 内核 + 包外 `skills/`，测试基线 811 PASS + Python 端到端全绿）。下文保留原始问题诊断作为历史验收依据；下一阶段演进（包版本 `0.2.0` / Schema `1.2.0`）见 [`kernel-upgrade-plan.md`](kernel-upgrade-plan.md)。  
> **关联架构规范**：[`architecture.md`](architecture.md) · [`closure-plan.md`](closure-plan.md) · [`kernel-upgrade-plan.md`](kernel-upgrade-plan.md) · [`AGENTS.md`](../AGENTS.md)

---

## 1. 核心定位与优先级准则

`gloss` 的核心价值不在于去给全 CRAN 数千个长尾魔改绘图包做 100% 静态逆向适配（**边缘捕获退化是零侵入路线的可接受边界，底线是不抛错、诚实标注**），而在于**其产出的开放资产组织方式，是否为下游消费生态以及“人 ↔ 图表 ↔ 智能体”三元共在协作准备了完备、零猜测的信息链路**。

对照真实下游操作链路（`Workbench` 双向交互刷选、点击图例筛选、超密光栅反查、`gloss-svg-refine` 安全精修、`gloss-audit` 审稿级对账，以及多轮人机协同推理）逐行核查当前代码（`R/*.R` 与 `skills/*`），我们将全部问题划分为**三大主轴、共 23 项具体条目**：

1. **主轴 A — 资产组织“最后一公里”信息断层（`ISS-ASSET-01` ~ `06`，6 项）**：静态 Schema 中导致下游被迫“靠猜”的断链点（核查源码后同时发现多处“做了一半”或口径不一的隐蔽缺陷）。
2. **主轴 B — “人 ↔ 图表 ↔ 智能体”三元共在协作与异构感知缺口（`ISS-AGENT-01` ~ `04`，4 项）**：面向 Token 效率、VLM+符号双通道感知、双向指代（Focus/Overlay）、声明式修改补丁与外挂共享工作态的设计缺口。
3. **主轴 C — 零侵入抓拍的上游耦合与边缘捕获脆弱性（`ISS-EXT/GG/PW/HM/BASE/MIX/SVG/DEV/PROTO`，13 项）**：编译现场观测器的工程防腐层与优雅降级清单。

> **严守内核边界原则（[`AGENTS.md`](../AGENTS.md) Core Principle #2）**  
> 清单中每一项均明确标注**职责落位**：凡不依赖活体 R 会话与图形设备的交互态、补丁指令集与多轮批注流，一律落位在**包外开放契约层**（`skills/`、`Workbench`、`gloss-mcp`），绝不将 `gloss` R 内核撑胖。

---

## 2. 全景问题总览矩阵（23 项）

### 主轴 A：资产组织“最后一公里”信息断层（支撑高精度交互、精修与审稿 — v1.1 全部已验收）

| 编号 | 缺口主题 | 历史诊断与 v1.1 验收实现记录 | 主要受阻的下游场景 | 职责落位 | 验收状态 |
| :--- | :--- | :--- | :--- | :---: | :---: |
| **ISS-ASSET-01** | **行级双向桥接**<br/>（`element ↔ built_row ↔ raw_row`） | 已在 `built_layer*.csv` 增加 `_raw_row_id` / `_group_key` 与 `tables/groups_*.json`，并在 `elements.json` 写出 `built_row_id` / `group_id` / `part_role` | Workbench 悬停看样本、点图筛表、点表高亮图元、箱线图点击反查原始组 | R 内核 Schema | **已验收 (P0)** |
| **ISS-ASSET-02** | **坐标逆变换与连续色板**<br/>（`scene.coord`、统一域空间、连续 `stops`） | 已导出 `scene.coord`，统一 `ggplot`/`base` 的 `x_domain`/`y_domain` 为变换后渲染域并提供 `x_data_domain`/`y_data_domain` 与 11-stop 连续色标 `stops`/`oob`/`na_value` | 拉框刷选（Brushing）、`>10^4` 密集光栅层像素反查数据、连续渐变色板替换 | R 内核 Schema | **已验收 (P0)** |
| **ISS-ASSET-04** | **面板内语义角色与可变性锁**<br/>（`semantic_role`、`edit_policy`、`label_links`、`z_index`） | 已在 `leaves`/`lineage` 输出 `semantic_role`、`edit_policy`、`z_index`、`clip_bbox_pt` 及 `scene.label_links`（v1.2 进一步升级为 `role_contracts` 属性契约） | `gloss-svg-refine` 数学级锁死数据点、移动标签同步牵引引线、防越界被 `<clipPath>` 裁断 | R 内核 Schema | **已验收 (P0)** |
| **ISS-ASSET-06** | **静默丢行账本与统计参数**<br/>（`row_accounting` + 完整 `stat_params`/`geom_params`） | 已合并采集 `stat_params`/`geom_params`/`aes_params`/`position` 参数并记录 `row_accounting`（`n_dropped_na`、`n_dropped_oob`、`dropped_raw_row_ids`） | `gloss-audit` 审稿核查误差棒口径（SD vs SE vs 95% CI）及图注样本量 `n` 与实际落点差异 | R 内核 Schema | **已验收 (P1)** |
| **ISS-ASSET-03** | **图例项级绑定**<br/>（`ir.guides.entries[].items`） | 已在 `ggplot`/`patchwork` 导出项级 `swatch_elements`/`label_elements` 与 colorbar 元素（v1.2 补齐 `ComplexHeatmap` 全项级解析与 `scale_id` 令牌） | Workbench 点击图例项显隐分组；多通道（颜色+形状+线型）精准同步换色 | R 内核 Schema | **已验收 (P1)** |
| **ISS-ASSET-05** | **矩阵切片与跨面板共享轴**<br/>（`axis_group` 与 `order_slice`） | 已为 `ComplexHeatmap` 注释条补建 `annotation` 面板，并在 `ir.panels` 写出 `row_axis_group`/`col_axis_group`/`row_slice_range`/`col_slice_range` 与 `x_axis_group`/`y_axis_group` | 热图悬停某基因时“主图整行 + 侧边注释柱状图”同步高亮；`patchwork` 对齐轴联动 | R 内核多引擎 | **已验收 (P2)** |

### 主轴 B：“人 ↔ 图表 ↔ 智能体”三元共在协作与异构感知（v1.1 全部已验收）

| 编号 | 协作维度 | v1.1 验收实现记录 | 核心收益 | 职责落位 | 验收状态 |
| :--- | :--- | :--- | :--- | :---: | :---: |
| **ISS-AGENT-02** | **智能体异构感知分层**<br/>（`scene/texts.json` 与 `assets/preview.png`） | 已默认剥离 `<10 KB` 紧凑 `scene/texts.json` 并由冻结显示列表零重跑导出 `assets/preview.png` | Agent 仅读 `texts.json` 即可秒抓所有显著性标注与重叠文本；VLM 看 `preview.png` 审美 + 符号表求真零幻觉 | **R 内核轻量增量** | **已验收 (P0)** |
| **ISS-AGENT-01** | **双向指代协议**<br/>（`focus.json` / `overlay.json`） | 已落地 `skills/gloss/scripts/focus_bridge.py`（`box-to-rows` / `rows-to-overlay`）并与 `gl_query()` 双向收敛互通 | 人在前端拉框直接转为符号上下文喂给 AI；AI 查出异常样本直接回投图面高亮与归因便签 | **外围开放契约** + `gl_query` 互转 | **已验收 (P1)** |
| **ISS-AGENT-03** | **双轨修改闭环**<br/>（声明式 Visual Patch + `parent_capture_id`） | 已落地 `apply_visual_patch.py` 执行器与 `gloss(..., parent = ...)` / `call_expr` 版本演化链 | 表现层用 JSON Patch 安全派生避免改坏 SVG；计算层修改 R 代码重跑形成可追溯 `capture_id` 演化链 | **外围协议/脚本** + 内核轻量字段 | **已验收 (P1)** |
| **ISS-AGENT-04** | **多轮人机共享工作态**<br/>（只读源包旁侧 `.gloss.work/` 伴随态） | 已落地 `skills/gloss/SKILL.md` 与 `workspace_state.py`，管理 `focus.json` / `threads.json` / `patches/` / `derived/` | 严守 `.gloss/` 只读不可变前提下，支持跨天、跨会话、跨 Agent 无缝接力 | **纯外围开放契约** | **已验收 (P2)** |

### 主轴 C：零侵入抓拍的上游耦合与边缘捕获脆弱性（v1.1 全部已验收）

| 编号 | 所属模块 | 历史诊断主题 | v1.1 验收实现记录 | 验收状态 |
| :--- | :--- | :--- | :--- | :---: |
| **ISS-EXT-01** | `engine-registry.R` / `capture.R` | 非 `ggplot`/`grob` 可打印外壳对象 | 已增加 `draw_generic_printable()` 嗅探 `gtable` 槽位或 `print`/`show` 自动兜底分派 | **已验收 (P0)** |
| **ISS-GG-01** | `engine-ggplot.R` | 重写 `print.*` 的魔改扩展 | 已增加 `pin_ggplot_stochastic_seeds()` 与基于 `grob_path` 的 `custom_print_heuristic` 回退匹配 | **已验收 (P0)** |
| **ISS-GG-02** | `engine-ggplot.R` | 内部槽位耦合与空图层连坐断链 | 已抽离 `gg_compat_*()` 访问层并改为逐层独立匹配，空 `zeroGrob` 图层不再连坐 | **已验收 (P0)** |
| **ISS-PROTO-01** | `ir-lineage.R` / `query.R` | 血缘精度梯队与框选行收敛 | 已导出 `lineage_tier` / `degradation_reason`，`gl_query(box = ...)` 精确收敛到数据行（含光栅逆投影） | **已验收 (P1)** |
| **ISS-GG-03** | `capture.R` / `ir-lineage.R` | `makeContent()` 动态裂变误判 | 已检测 `is_dynamic_make_content_leaf()` 并标记 `dynamic_makeContent`，防止基数误判为静态 `1:1` | **已验收 (P1)** |
| **ISS-SVG-01** | `capture.R` | 空探针对齐、嵌套 `transform`、圆弧与 CJK 字宽 | 已过滤孤立 `<defs>` 仅对齐有效 `<use>`，补齐椭圆弧极值、祖先矩阵级联与 CJK 宽字符估算 | **已验收 (P1)** |
| **ISS-BASE-01** | `engine-base.R` | `base` 低阶原语参数表提取 | 已补齐 `segments`/`arrows`/`symbols`/`abline`/`xspline`/`text` 调用表与元素桥接 | **已验收 (P1)** |
| **ISS-MIX-01** | `capture.R` | `base` + `grid` 混排页阻断 | 已落地 `make_mixed_fallback_engine()` 降级兜底流，保住 `original.svg`、`elements`/`texts` 与 `sources` | **已验收 (P1)** |
| **ISS-PW-01** | `engine-patchwork.R` | `patchwork` 异构块与随机层 | 已支持 `wrap_elements()` 兼容与 `patchwork_pin_stochastic_seeds()` 非变异种子锁定 | **已验收 (P2)** |
| **ISS-HM-01** | `engine-heatmap.R` | `ComplexHeatmap` 闭包与正则耦合 | 已改为已知热图/注释名字面量最长前缀匹配并扩展 `heatmap_probe_anno_values()` 闭包探测 | **已验收 (P2)** |
| **ISS-GG-04** | `engine-ggplot.R` | 多标度覆盖字段匹配 | 已优先检查图层自身重命名映射再回退至顶层映射 | **已验收 (P2)** |
| **ISS-BASE-02** | `engine-base.R` | `base` 步进回放与引号兼容 | 已同时兼容单/双引号属性与异常回退至未包裹有效 SVG 文档 | **已验收 (P2)** |
| **ISS-DEV-01** | `capture.R` / `engine-base.R` | 多页连续绘图页选择与记录 | 已支持 `gloss(..., page = k)` 按页选取并将跳过的页记录入 `omitted.json` | **已验收 (P3)** |

---

## 3. 主轴 A 详述：资产组织“最后一公里”信息断层（`ISS-ASSET-01` ~ `06`）

### `ISS-ASSET-01`：行级映射断层 —— 缺“图元 ↔ 计算行 ↔ 原始行”的显式桥接
- **源码现状核查**：
  - `R/package-assets.R`（第 269–275 行）：打包时仅为 `raw.csv` 和 `built_layer*.csv` 各自独立生成从 `1` 开始递增的 `_row_id`，两张表之间没有任何外键列；
  - `R/utils.R`（`empty_elements_df`，第 384–410 行）与 `R/capture.R`（第 1178–1202 行）：`elements.json` 仅记录所属 `leaf_id` 和组内 DOM 出现序号 `ordinal`，没有任何关联数据行的字段。
- **下游断链点**：
  1. **`1:1` 图层也不能靠数组下标硬对齐**：`ggplot2` 在生成面板 grob 时会按 `PANEL` 分组、按 `group` 或绘制顺序重排，并静默剔除含 `NA` 或越界（`oob_censor`）的数据行，导致 SVG 某叶子组内的第 `k` 个 `<circle>` 往往不对应 `built_layer1.csv` 的第 `k` 行；
  2. **`built` 无法反查 `raw`**：在统计聚合图层（如箱线图 `StatBoxplot`、柱状汇总 `StatSummary`）中，用户在 Workbench 点击某个箱体想筛选出构成该组的 48 条原始患者记录，仅凭 `built` 表的统计汇总值无法可靠反查 `raw.csv`；
  3. **复合图元（`1:M`）与合并图元（`N:1`）粒度失焦**：一行箱线图计算结果会拆分为箱体、中位线、上下须线、离群点等 6–8 个 SVG 图元；一条折线（`N:1`）由数十行合并为单条 `<polyline>`。鼠标悬停须线或离群点时，前端无法定位它归属哪条统计记录或哪个原始离群样本。
- **最小补齐方案（R 内核 Schema，P0）**：
  - 在 `built_layer*.csv` 中增加显式 `_built_row_id`（或保留 `_row_id` 为计算行主键），并补充回指原始输入表的 `_raw_row_id`（`1:1` 恒等变换层，通过在构建前向输入表注入临时内部追踪列使 `ggplot_build()` 原生透传或基于面板/分组还原）及 `_group_key`（聚合与 `N:1` 图层，必要时辅以轻量分组映射表避免 CSV 塞超长数组字符串）；
  - 在 `elements.json` 中为数据图元补充可选的 `built_row_id` / `group_id`，并为复合几何体补充 `part_role`（如 `box`、`median`、`whisker`、`outlier`、`ribbon`、`line`）。

---

### `ISS-ASSET-02`：坐标逆变换与连续色板断层 —— 缺坐标系基准、域空间语义与连续色标规范
- **源码现状核查（含已发现的跨引擎口径冲突）**：
  - **缺顶层画布坐标基准**：`R/package-assets.R`（第 67–96 行）导出的 `asset-map.json` 未声明 SVG 坐标原点方向（左上角原点、Y 轴向下，与 R `grid` 左下角原点相反）及根 `<svg viewBox>`；
  - **跨引擎 `x_domain` / `y_domain` 口径自相矛盾**：
    - 在 `R/engine-ggplot.R`（第 474–496 行 `ggplot_panel_domain`）中，读取的 `pp$x.range` 是**非线性变换之后、且已包含默认 5% 边缘扩展（expansion）的坐标域**（例如 `scale_x_log10()` 下 `[10, 1000]` 被记为约 `[0.9, 3.1]`）；
    - 而在 `R/engine-base.R`（第 503–504 行）中，代码写了 `if (isTRUE(lr$xlog)) 10^lr$usr[1:2]`，即存成了**反算回变换前的原始数值域**！下游工具若按统一公式做像素逆映射必然算错其中一端；
  - **离散轴与时间轴锚点缺失**：离散轴在面板上的真实定位点（整数 `1, 2, ...` 与两侧扩展留白）及 `Date`/`POSIXct` 的数值基准（天 vs 秒、时区）未在 `ir.panels` 显式结构化；
  - **连续色板表达残缺**：`R/engine-ggplot.R`（第 369–389 行）把连续渐变色板塞进离散结构的 `map` 数组（仅取约 4–5 个刻度点），缺少 `stops`（归一化色标停靠点）、`limits`、`midpoint`、`na_value` 与 `oob` 策略（`censor` vs `squish`）。
- **下游断链点**：拉框刷选（Brushing）、超过 `dense = 10000` 阈值转为 `scene/rasters/*.png` 光栅层后的鼠标悬停反查（此时已无 SVG DOM 图元可点，100% 依赖数学逆投影）、以及连续热图/UMAP 表达量色带重映射全部受阻。
- **最小补齐方案（R 内核 Schema，P0）**：
  - 在 `asset-map.json` 的 `scene`（或顶层 `scene_coord`）显式写入 `{ "unit": "pt", "origin": "top-left", "y_direction": "down", "viewBox": [0, 0, width_pt, height_pt] }`；
  - 统一所有引擎 `ir.panels` 的坐标域规范：明确补齐 `x_trans` / `y_trans`（标准化枚举如 `"identity"`、`"log10"`、`"ln"`、`"sqrt"`、`"reverse"`、`"date"`、`"datetime"`、`"discrete"`）、显式声明 `domain_space`（统一约定变换后线性渲染域 `"transformed"` 并同时提供 `data_domain` 原始值域供展示，明确已含 padding）以及离散轴的 `breaks_pos`；
  - 在 `ir.scales` 中为 `scale_type == "continuous"` 规范化 `limits`、`trans`、`stops`（如 9–17 个等距采样节点 `[{ "pos": 0.0, "domain": ..., "color": "#..." }]`）、`na_value` 与 `oob`。

---

### `ISS-ASSET-03`：图例内部黑盒 —— 缺“图例键图元 ↔ 比例尺定义域值”的细粒度绑定
- **源码现状核查**：
  - `R/engine-ggplot.R`（第 128–137 行）：单张 `ggplot` 图捕获时**根本未生成 `ir$guides` 字段**；
  - `R/engine-patchwork.R`（第 242–285 行）：虽生成了 `ir$guides`，但只记录了整块合并图例的外接框 `bbox_pt` 和所有 `guide-box*` 的粗粒度 `leaf_ids`，未深入图例内部区分不同视觉通道（如 `colour` 图例 vs `shape` 图例）及具体条目；
  - `skills/gloss-svg-refine/scripts/verify_svg_fidelity.py` 目前只能靠遍历 `guide-box*` 下的 Hex 颜色字符串去猜测哪个小方块对应哪个分组。
- **下游断链点**：当多个图例共存、不同分组颜色叠加了 `alpha` 透明度、两个独立图例撞色，或图例表达的是形状（`shape`）、大小（`size`）、线型（`linetype`）而非颜色时，前端“点击图例某项高亮/隐藏对应数据组”以及精修脚本“按语义同步改图元与图例图标”彻底失效。
- **最小补齐方案（R 内核 Schema，P1）**：
  - 在 `ggplot`、`patchwork`、`heatmap` 引擎中统一导出结构化的 `ir.guides` 数组，将每个独立图例（`guide_id`、`aesthetic`、`scale_index`/`title`、`leaf_id`、`bbox_pt`）内部的每个图例项显式映射到具体元素 ID：
    `items: [{ "domain": "Cohort A", "label": "Cohort A (n=48)", "swatch_elements": ["E0381"], "label_elements": ["E0382"] }]`。

---

### `ISS-ASSET-04`：面板内角色混杂 —— 缺叶子/元素级的“语义角色、可变性锁、引线锚点与渲染层序”
- **源码现状核查**：
  - 虽然 `leaves.json` 和 `elements.json` 已具备裁切框坐标（`clip_id`、`clip_x0..clip_y1`，见 `R/capture.R` 第 1071–1094 行），但 `lineage` 与 `leaves.json` 仅靠 `layout_slot`（如 `"panel-1-1"`）和原始 `grob_name` 描述位置；
  - 导致下游 [`skills/gloss-svg-refine/SKILL.md`](../skills/gloss-svg-refine/SKILL.md) 与 `verify_svg_fidelity.py`（第 30–35 行）只能靠硬编码一份不全的 `LABEL_GEOMS` 集合来区分“锁死的数据几何体”与“可微调避让的标签”。
- **下游断链点**：
  1. **同处 `panel` 槽位的权限混同**：面板内同时混杂着**绝对禁止位移的数据几何体**（`geom_point`/`geom_line`）、**允许避让平移的数据标注**（`geom_text_repel`/`annotate("text")`）、**统计参考阈值线**（`geom_hline`/`geom_vline`）以及**纯背景装饰**（`grill` 网格线、面板边框）；
  2. **标签移动后引线脱节**：`ggrepel` 绘制的文字与引导线（`<line>`/`<polyline>`）缺乏显式的 `{ label_element_id, leader_element_id, anchor_pt }` 绑定，精修脚本挪开重叠文字后无法自动重连引线终点；
  3. **越界裁切与遮挡盲区**：缺少显式的全局绘制层序 `z_index`，且当精修工具将靠近面板边缘的标签向外微移 5pt 时，若未察觉该叶子受面板 `<clipPath>` 约束，移动后文字会被直接削掉一半。
- **最小补齐方案（R 内核 Schema，P0）**：
  - 在 `lineage` / `leaves.json` 上补充正交的 `semantic_role`（`data_mark` / `data_label` / `leader_line` / `reference_mark` / `annotation` / `panel_grid` / `panel_frame` / `axis_tick` / `axis_title` / `strip_label` / `guide` / `plot_title`）与默认派生编辑锁提示 `edit_policy`（`geometry_locked` / `style_only` / `movable`）；
  - 在 `leaves.json` 写入从底到顶的 1-based 全局渲染顺序 `z_index`（并将 `clip_x0..clip_y1` 统一整理为易读的 `clip_bbox_pt` 或保持兼容同步提供）；对 `ggrepel` 等带引线标注尽可能提取标签与引线配对线索。

---

### `ISS-ASSET-05`：矩阵切片与共享轴断层 —— `ComplexHeatmap` 与复合子图的跨面板联动失联
- **源码现状核查**：
  - `R/engine-heatmap.R`（第 122–128、196–206 行）：全局聚类重排顺序保存在 `ir$orders[[safe_nm]]` 中，但 `ir$panels` 里每个切片面板仅记录了 `row_slice = 2, col_slice = 1` 的序号，未直接给出该面板对应全局排序向量的起止下标范围；
  - 更关键的是，`R/engine-heatmap.R`（第 234–302 行）仅为热图主体 `heatmap_body` 创建了 `panel`，**所有顶部/底部/左侧/右侧注释条（`HeatmapAnnotation`）叶子的 `panel_id` 全是 `NA`**，也未建立任何跨面板共享轴标识。
- **下游断链点**：在生信分析最刚需的带分裂（`row_split`/`column_split`）+ 多侧注释热图中，用户鼠标悬停主热图第 2 切片某一行基因（尤其是开启了光栅化的密集热图）时，前端无法直接得知它对应全局基因排序的第几项，也无法得知右侧哪几个表达丰度柱状注释条、左侧哪棵聚类树切片与它共享同一段行轴，无法零定制实现跨面板整行/整列同步高亮（同理也适用于 `patchwork` 上下对齐共享 X 轴的多组学轨迹图）。
- **最小补齐方案（R 内核多引擎层，P2）**：
  - 为 `HeatmapAnnotation` 切片补建对应的注释面板（或视口框），并在 `ir.panels` 中引入可选的跨面板联动字段：`row_axis_group` / `col_axis_group`（或通用的 `x_axis_group` / `y_axis_group`）、`row_order_ref` / `col_order_ref` 以及当前面板承载的切片索引区间 `row_slice_range` / `col_slice_range`（如 `[31, 60]`）。

---

### `ISS-ASSET-06`：静默丢行账本缺失与统计参数漏采 —— 审稿级对账的隐形盲区
- **源码现状核查（实锤代码漏采 Bug）**：
  - **图层统计与几何参数漏采**：`R/engine-ggplot.R` 第 288 行当前写的是 `params = sanitize_layer_params(lyr$aes_params)`！在 `ggplot2` 图层对象中，`aes_params` 仅存放手动固定的美学常量（如 `colour = "blue"`），而真正决定统计口径的 `method = "loess"`、`formula = y ~ x`、`level = 0.95`、`bins = 30`、`fun.data = "mean_se"`、`width = 0.2` 分别存放在 **`lyr$stat_params` 与 `lyr$geom_params`（以及 `lyr$position` 参数）** 中——目前这些关键统计参数在导出时**100% 丢失**！
  - **无静默丢行对账单**：虽然 `ggplot_extract_tables()`（第 158–171 行）已正确支持多源输入表（`raw` + `raw_layer1..k`），但当 `raw` 有 100 行而 `built_layer1` 因缺失值（`NA`）或 `scale_*_continuous(limits = ...)` 越界截断只剩 95 行时，资产包没有任何字段记录这 5 行的去向与原因。
- **下游断链点**：`gloss-audit` 面对图上的误差棒或平滑带时，无法从资产包判断画的是 `SD`、`SE` 还是 `95% CI`（或 `90% CI`）；面对图注宣称 `n = 100` 而实际只画了 95 个点的常见审稿硬伤时，无法直接指出哪几个样本 ID 被静默过滤、是因为原始缺失还是人为设轴截断。
- **最小补齐方案（R 内核 Schema，P1）**：
  - 修复 `R/engine-ggplot.R` 参数提取：合并采集 `lyr$stat_params`、`lyr$geom_params`、`lyr$aes_params` 及关键 `position` 参数（将函数对象如 `mean_se` 安全序列化为可识别符号/摘要）；
  - 在 `ir.layers` 中补充 `row_accounting` 结构：`{ "n_raw": 100, "n_built": 95, "n_dropped_na": 3, "n_dropped_oob": 2, "dropped_raw_row_ids": [14, 29, 51, 77, 88] }`。

---

## 4. 主轴 B 详述：“人 ↔ 图表 ↔ 智能体”三元共在协作与感知缺口（`ISS-AGENT-01` ~ `04`）

传统可交互图表（Plotly / ggiraph / Shiny）服务于“人 ↔ 图表”的瞬时浏览器内存闭环；而 `gloss` 天然面向**“人（视觉直觉与决策）↔ 图表（共享图面协议）↔ 智能体（符号计算与确定性批处理）”**的三元协作闭环。

### `ISS-AGENT-01`：缺双向指代协议（Focus / Overlay 统一寻址契约）
- **现状卡点**：
  - **人 → 智能体断层**：用户在 Workbench 用鼠标框选右上角 6 个异常点或点击某块热图切片提问时，缺乏标准交换格式把前端像素选区精准转化为智能体可直接读取的 `{ panel_id, leaf_id, element_ids, table_id, row_ids, bbox_pt }` 上下文包；
  - **智能体 → 人断层**：智能体查完 `raw.csv` 与实验记录定位出“4 个测序深度不足的批次 B 样本”后，只能输出纯文本样本号，无法吐出一份标准叠加层指令让 Workbench 在 `scene.svg` 上瞬间高亮这 4 个点、压暗其余背景并挂出归因便签。
- **职责落位与补齐方案（外围开放契约 + `gl_query` 支撑，P1）**：
  - **包外协议层**：定义轻量的 `gloss-focus` / `gloss-overlay` JSON Schema（含 `capture_id`、`kind: "selection" | "highlight" | "annotation"`、`author: "human" | "agent"`、`targets[]` 与 `note`）；
  - **R 内核配合**：依托 `ISS-ASSET-01`（行级桥接）与 `ISS-ASSET-02`（坐标逆变换），增强 `gl_query()` 使其输入 `box` 时能直接返回框中命中的精确 `row_ids`，输入 `rows` 时能直接返回对应的 `element_ids` 与 `bbox_pt`。

---

### `ISS-AGENT-02`：缺面向智能体的异构感知分层（`scene/texts.json` 剥离 + `assets/preview.png` 快览底图）
- **现状卡点**：
  1. **关键文字淹没在数 MB 的几何坐标海中**：当前 `R/package-assets.R`（第 224–228 行）把所有 SVG 图元混写入单一 `scene/elements.json`。一张含 8,000 个散点的图表，`elements.json` 高达数 MB 且 99% 是 `<circle>` 数值；而真正承载全局语义锚点的标题、轴标签、分面名、图例文字、显著性标记（如 `p = 0.003`）和基因标注仅三五十条。智能体为核对图面文字或检测标签碰撞，被迫读取或解析整份巨型文件，严重浪费上下文窗口与延迟；
  2. **缺少同坐标系标准参考栅格图**：版式平衡感、留白协调度、视觉拥挤感属于多模态视觉（VLM）的强项，而精确读数与统计验算属于符号工具的强项。当前资产包内没有现成的全局栅格预览图，VLM 无法直接“看一眼画面抓审美问题，再查符号表拿零幻觉精确数值”。
- **职责落位与补齐方案（R 内核极轻量增量，P0）**：
  - **独立写出 `scene/texts.json`**（默认开启，通常 `< 10 KB`）：在 `gl_asset_bundle()` 打包时将 `tag == "text"` 的记录连同其精确包围盒、字体字号、旋转角、`leaf_id`、`panel_id` 与 `semantic_role` 单独抽成一份紧凑索引，并在 `asset-map.json -> scene` 中登记摘要；
  - **可选导出 `assets/preview.png`**（如 `gl_asset_bundle(..., preview = TRUE, preview_dpi = 150)` 或默认生成轻量预览）：严格按同一次捕获尺寸（与 `scene_coord` 完全对齐的宽高比）渲染标准 PNG，供智能体与前端零依赖直读。

---

### `ISS-AGENT-03`：修改闭环未分轨 —— 缺表现层声明式补丁规范（Visual Patch Spec）与计算层回源版本链
- **现状卡点**：
  1. **表现层让大模型手改整份 SVG 风险高、开销大**：当前 [`skills/gloss-svg-refine/SKILL.md`](../skills/gloss-svg-refine/SKILL.md) 让智能体自己写 DOM 脚本直接改写 `scene/scene.svg`。大模型直接操控几万行 XML 既浪费输出 Token，又极易误改路径精度、破坏命名空间或漏改同步图例；
  2. **计算层重跑缺入口线索与跨包演化链**：当用户的诉求涉及改变数据或统计模型（如“剔除 2 个质控失败样本重画回归线”“Y 轴改对数刻度”）时，严禁在 SVG 层硬改，必须回写 R 代码重新触发 `gloss()`。但当前 `manifest.json`（`R/package-assets.R` 第 453 行）仅有 `parent_manifest_sha256`（面向 SVG 派生），缺少串联前后两代完整 `.gloss/` 资产包的 `parent_capture_id`，且 `sources` 元数据缺少绘图对象变量名/入口调用位置线索。
- **职责落位与补齐方案（外围协议脚本为主 + 内核轻量字段，P1）**：
  - **轨道 A（表现层，落位 `skills/gloss-svg-refine`）**：定义极简 JSON **Visual Patch Spec**（如 `translate_element`、`remap_scale_palette`、`move_guide`、`set_typography`、`add_callout`）并配套确定性 Python 补丁执行器（内置校验 `edit_policy != "geometry_locked"`、自动联动更新 `ir.guides` 图标与引线端点、自动调用 `verify_svg_fidelity.py` 出具证明）；
  - **轨道 B（计算层，内核轻量字段 + 底座 Skill）**：在 `gloss(..., parent = ...)` / `manifest.json` 支持可选 `parent_capture_id` 记录重算演化血缘，并在 `sources` 的 `runtime_observed` / `sniffed_hint` 中保留捕获时的调用表达式摘要（如 `deparse(substitute(x))`）。

---

### `ISS-AGENT-04`：缺“源包只读不可变 + 外挂共享工作态（Shared Workspace）”的多轮协作规范
- **现状卡点**：真实科研改图往往跨越数天与多个专职角色（第 1 轮出图 → 第 2 轮 `gloss-audit` 标出 3 处统计疑点 → 第 3 轮研究者在 Workbench 逐条批注确认“5 行 NA 系失访写进图注、剔除亚组 C 异常点重跑” → 第 4 轮 `gloss-svg-refine` 终稿排版）。目前审计输出与交互状态都是阅后即焚的会话文本或前端内存，且公共入口底座 [`closure-plan.md`](closure-plan.md) 中的 `gloss` Skill 尚未补齐，跨会话/跨 Agent 接力时上下文全部丢失。
- **职责落位与补齐方案（纯外围开放契约，R 内核零负担，P2）**：
  - 确立**“源包只读，协作外挂”**目录规范：`<figure>.gloss/` 永远保持不可变的编译现场哈希闭环；所有动态交互与协作状态统一存放在旁侧伴随目录（如 `<figure>.gloss.work/` 或项目级 `.gloss-work/<capture_id>/`）：
    - `focus.json`：Workbench 与当前会话 Agent 实时共享的选区/高亮焦点；
    - `threads.json`：锚定在具体 `{ panel_id, leaf_id, row_ids, claim_id }` 上的审计问题单、人工批注与处理状态（`open` / `accepted` / `dismissed` / `recompute_requested`）；
    - `patches/` 与 `derived/`：历次声明式视觉补丁、派生 SVG 及校验回执。

---

## 5. 主轴 C 详述：零侵入抓拍的上游耦合与边缘捕获脆弱性（`ISS-EXT` ~ `ISS-DEV`）

> 本部分问题属于 R 编译现场观测器的底座防线：目标是**消除硬报错、切断局部异常的连坐传染、把隐式断链转化为显式分级标记**。

### 5.1 对象分派与 `ggplot2` / `patchwork` 生态边界
- **`ISS-EXT-01`（非继承外壳对象直接报错，P0）**：`R/engine-registry.R`（第 187–225 行）对未显式注册的 S3/S4 可打印对象（如 `survminer::ggsurvplot`、`pheatmap`、`lattice::trellis`、`ggExtraPlot`）直接 `cli_abort`。应增加**通用可打印对象自动兜底流**：先嗅探标准内嵌槽位（如 `x$gtable`），否则在捕获设备上安全执行 `print(x)` / `show(x)` 并按 `detect_page_kind()` 自动转交 `grid` 或 `base` 引擎；长尾领域对象可通过包外 `gl_register_engine()` 轻量解包配方按需增强。
- **`ISS-GG-01`（自定义 `print.*` 魔改包血缘全断，P0）**：`R/engine-ggplot.R`（第 41–49、643–683 行）遇到 `ggbreak`、`aplot` 等自定义 `print.<cls>` 时 `gtable == NULL`，导致 `child_to_layer` 为空、全图退化为 `unlinked`，且事后二次 `ggplot_build()` 对无种子随机层有坐标偏移风险。应增加基于运行时 `leaves$grob_path` 的 `geom_*` 命名前缀启发式回退匹配，并在绘制前锁定随机种子。
- **`ISS-GG-02`（内部槽位耦合与空图层连坐断链，P0）**：`R/engine-ggplot.R`（第 442–496、656–682 行）直接读取内部槽位，且硬编码 `nk == n_layers + 4L` 与 `length(non_chrome) == n_layers`——只要某图层在某分面数据为空产出 `zeroGrob`，同面板所有其余正常图层全部连坐退化为 `unlinked`。应抽离版本感知的 `gg_compat_*()` 访问层，并改为按每层生成的 grob 名称逐一独立绑定。
- **`ISS-GG-03`（`makeContent()` 动态裂变与基数巧合误判，P1）**：`ggrepel`、`ggforce` 等在 `grid.force()` 期动态增删图元，破坏行序对齐，且当动态增减后的图元总数恰好等于 `n_rows` 时会被 `R/ir-lineage.R`（第 150 行）误标为静态 `"1:1"`。应检测自定义 `makeContent` 方法并显式标记动态绘制属性，结合坐标与文本匹配做二级重绑定。
- **`ISS-GG-04`（`ggnewscale` 多标度同名覆盖，P2）**：`R/engine-ggplot.R`（第 315–325 行）查美学绑定字段时只取首个命中层，导致多套 `colour`/`fill` 标度字段名错配。
- **`ISS-PW-01`（`patchwork` 异构块与第三方随机层，P2）**：`R/engine-patchwork.R`（第 56、178–214、328–348 行）直接跳过 `wrap_elements()`，仅锁定内置 Jitter 未覆盖 `ggbeeswarm` 等第三方随机层，且依赖 `^patchwork-table-[0-9]+$` 内部布局命名正则。

### 5.2 `ComplexHeatmap`、`base` 传统绘图与底层 SVG 解析边界
- **`ISS-HM-01`（`ComplexHeatmap` S4 闭包与命名正则耦合，P2）**：`R/engine-heatmap.R`（第 170、237、420–452 行）依赖 `a@fun@var_env$value` 单一闭包变量（导致 `anno_boxplot`/`anno_mark` 等复杂注释无数据表），且下划线热图名易与 viewport 正则冲突。应改用已知热图/注释名字面量精确匹配并扩展注释闭包白名单探测。
- **`ISS-BASE-01`（`base` 复合函数语义蒸发与原语覆盖不全，P1）**：`R/engine-base.R`（第 425–473 行）仅从 `plotXY`/`rect`/`polygon` 提取参数表，`segments`（箱线图须线/误差棒）、`arrows`、`symbols`、`abline`、`xspline` 均落为 `unlinked`。应补齐常用原语几何表提取。
- **`ISS-BASE-02`（`base` 步进回放与 `svglite` 行级字符串格式耦合，P2）**：`R/engine-base.R`（第 84–127、152–181 行）按单引号与换行正则手拼 SVG 片段，若 `svglite` 改变属性引号或折行格式易触发包裹失效回退。建议改用 `xml2` DOM 增量节点比对。
- **`ISS-MIX-01`（`base` + `grid` 同页混排直接抛错，P1）**：`R/capture.R`（第 85–92 行）遇到 `mixed` 页面直接 `cli_abort`，违背“不充当门禁阻断捕获”原则。应提供 `mixed` 降级兜底流，保住 `original.svg`、`elements.json`/`texts.json` 与 `sources`。
- **`ISS-SVG-01`（空探针废掉整页分组 & 复杂变换/圆弧/中文文本框偏差，P1）**：`R/capture.R`（第 585–610 行）因 `length(top_gids) != n_probe` 在遇到单颗空 grob 时一刀切回退整页无 ID SVG；`parse_single_path_bbox` 未算圆弧 `A/a` 极值，`estimate_text_boxes` 未累乘多层祖先 `<g transform>` 且将中文字符按 `0.6 * font_size` 窄字符估算。
- **`ISS-PROTO-01`（缺显式血缘退化等级说明 & `gl_query(box)` 未收敛到行，P1）**：`R/ir-lineage.R` 未区分“背景装饰无表”与“匹配失败退化为 `unlinked`”；`R/query.R` 空间框选仅筛到面板整表而非框内具体数据行。
- **`ISS-DEV-01`（多页连续出图仅留末页，P3）**：`plot(lm_fit)` 等多页输出前 `N - 1` 页被丢弃且未写入 `omitted.json`。

---

## 6. 分层落地路线图（严守内核极简边界）

为确保 `gloss` R 核心包始终保持轻量、零冗余依赖与 8 个导出函数的极简接口，建议后续分三层推进：

### 第一层：冻结 Schema 核心补齐（R 内核必做，决定下游上限）
1. **打通行级与元素桥接（`ISS-ASSET-01`）**：落地 `built_layer*.csv` 的 `_raw_row_id` / `_group_key` 与 `elements.json` 的 `built_row_id` / `part_role`。
2. **统一坐标逆变换与连续色板契约（`ISS-ASSET-02`）**：新增 `scene_coord`，修正 `ggplot` 与 `base` 的 `x_domain`/`y_domain` 空间口径冲突，补齐 `trans`、`domain_space`、离散 `breaks_pos` 与连续色板 `stops`/`oob`/`na_value`。
3. **落地叶子语义角色、编辑锁与渲染层序（`ISS-ASSET-04`）**：输出 `semantic_role`、`edit_policy`、`z_index` 及标签引线关联，让下游精修脚本彻底告别硬编码猜权限。
4. **智能体感知分层导出（`ISS-AGENT-02`）**：打包时默认拆分极轻量的 `scene/texts.json`，并提供同坐标系 `assets/preview.png` 导出能力。

### 第二层：审稿对账、图例精细化与捕获底座加固（R 内核高 ROI 补强）
1. **补齐统计图层参数与静默丢行账本（`ISS-ASSET-06`）**：修复 `stat_params`/`geom_params` 漏采 Bug，新增 `row_accounting`。
2. **导出细粒度图例项映射与跨面板共享轴（`ISS-ASSET-03`、`ISS-ASSET-05`）**：统一 `ggplot`/`patchwork`/`heatmap` 的项级 `ir.guides`，为热图切片与对齐子图补充 `axis_group` 与 `order_slice`。
3. **消除捕获硬报错与连坐断链（`ISS-EXT-01`、`ISS-GG-01`、`ISS-GG-02`、`ISS-MIX-01`、`ISS-SVG-01`、`ISS-PROTO-01`）**：打通任意可打印对象与混合页安全兜底，修复空图层连坐 `unlinked` 与空探针整页分组回退，增强 `gl_query()` 像素框 ↔ 数据行双向反查。

### 第三层：人机三元协作协议与外围生态（落位包外 `skills/` · `Workbench` · `gloss-mcp`）
1. **补齐底座 `gloss` Skill 与双向指代规范（`ISS-AGENT-01`）**：制定 `focus.json` / `overlay.json` 开放交换格式，打通“人框选喂给 AI ↔ AI 查表回投高亮”。
2. **升级声明式精修闭环与重算演化链（`ISS-AGENT-03`）**：为 `gloss-svg-refine` 增设声明式 Visual Patch Spec 执行器，并在 `manifest.json` 串起计算层重跑的 `parent_capture_id`。
3. **建立只读源包旁侧的 `.gloss-work/` 共享工作态规范（`ISS-AGENT-04`）**：持久化锚定在图面与数据行上的审稿批注、人工裁决与多轮修订历史。
