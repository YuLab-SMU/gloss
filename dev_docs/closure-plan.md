# gloss 全阶段闭环补齐跟踪计划（Closure Plan）

本跟踪文档用于严格对照三阶段设计蓝图与 [`dev_docs/architecture.md`](architecture.md)，逐项完成并验收除 **“配极简底座 `gloss` Skill 并用真实大模型跑通工作流一”**（用户明确暂缓项）之外的全部剩余目标。

---

## 范围说明

- **明确排除项（Out of Scope for This Batch）**
  - `[ ]` *(暂缓)* 阶段 1.4：编写底座 `gloss` Skill 并用真实大模型跑通工作流一。
- **本轮必须 100% 闭环的 5 大工作流（Tracks T1–T5）**

---

## Track 1：冻结协议 Schema v1.0 关键字段补齐（阶段 2.3）

| ID | 目标项 | 涉及文件 | 验收标准 | 状态 |
| :--- | :--- | :--- | :--- | :---: |
| **T1.1** | `elements.json` 补齐文本排版与样式属性（`font_size`、`font_family`、`text_anchor`、`rotation`、`stroke_width`、`opacity`） | `R/utils.R`, `R/capture.R` | `grid`/`ggplot`/`base` 导出的 `elements` 均保留完整字体、锚点、旋转角与描边宽度，供 `gloss-svg-refine` 直接消费 | `[x]` |
| **T1.2** | `elements.json` 与 `leaves.json` 补齐生效 `<clipPath>` 裁切框（`clip_id`、`clip_x0`、`clip_y0`、`clip_x1`、`clip_y1`） | `R/utils.R`, `R/capture.R`, `R/engine-base.R` | 准确解析 `svglite` `<defs><clipPath>` 并关联每个图元与叶子的生效裁切矩形（面板点坐标） | `[x]` |
| **T1.3** | `extract_layout_slot()` 图例槽位修正（`guide-box*` 外层优先，防止图例背景/标题误归为画布 `background`/`title`） | `R/capture.R` | `ggplot2` 与 `patchwork` 图例框内所有叶子统一标记为 `guide-box*` 槽位 | `[x]` |
| **T1.4** | `ir.layers` 与 `tables/schema.json` 补齐统计列语义角色（置信区间 `ymin`/`ymax`/`xmin`/`xmax`、分位数 `lower`/`middle`/`upper`、标准误 `se`、聚合计数 `count`/`density`） | `R/utils.R`, `R/ir-lineage.R`, `R/engine-ggplot.R` | 带统计汇总/平滑/箱线图的 `built_layer*` 自动标注统计语义角色，供 `gloss-audit` 精确对账 | `[x]` |

---

## Track 2：多引擎深水区细节收口（阶段 3.1）

| ID | 目标项 | 涉及文件 | 验收标准 | 状态 |
| :--- | :--- | :--- | :--- | :---: |
| **T2.1** | `patchwork` 含随机抖动子图（`geom_jitter` / `PositionJitterdodge`）单次种子锁定，消除二次构建坐标偏移 | `R/engine-patchwork.R` | 无显式种子的 `geom_jitter` 子图在 `p<i>_built_layer*` 与 `scene.svg` 圆心坐标相关系数 `> 0.9999`（零 `.GlobalEnv` 写入） | `[x]` |
| **T2.2** | `patchwork` 跨子图统一图例（`guides = "collect"`）坐标与归属映射 | `R/engine-patchwork.R` | 在 `ir$guides`（或面板/图例元数据）记录合并图例框 `bbox_pt`、`collected = TRUE` 及所属 `leaf_ids` | `[x]` |
| **T2.3** | `ComplexHeatmap` 注释条（`HeatmapAnnotation` / `rowAnnotation`）叶子血缘归属与复杂注释表提取 | `R/engine-heatmap.R` | `annotation_<name>_<slice>` 叶子在 `lineage` 中准确关联到 `anno_<side>_<ht>`（或单列注释表）与对应 `layer_id`、基数，不再遗留为 `unlinked` | `[x]` |

---

## Track 3：高频复杂扩展包真实中性兼容性测试集（阶段 3.2）

| ID | 目标项 | 涉及文件 | 验收标准 | 状态 |
| :--- | :--- | :--- | :--- | :---: |
| **T3.1** | `ggrepel`（`geom_text_repel` / `geom_label_repel` 绘图期 `makeContent()` 动态避让标签与引线）真实捕获与打包测试 | `tests/testthat/test-extensions.R`, `DESCRIPTION` | 零报错完成 `gloss()` -> `gl_asset_bundle()`，标签文本与引线线段完整进入 `elements.json` | `[x]` |
| **T3.2** | `sf`（`geom_sf` + `CoordSf` 带孔多边形地理矢量）真实捕获与 CSV/Schema 序列化测试 | `tests/testthat/test-extensions.R`, `DESCRIPTION` | `sfc` 几何列安全序列化，`<path>` 包围盒有限且准确，`CoordSf` 面板域完整记录 | `[x]` |
| **T3.3** | `ggtree`（系统发育树自定义图层与布局）真实捕获与资产包测试 | `tests/testthat/test-extensions.R` | 树拓扑分支与叶节点标签零报错捕获并完整导出 `.gloss/` 资产包 | `[x]` |
| **T3.4** | `ggbreak`（及重写 `print.*` 的断轴/复合扩展）兼容性测试 | `tests/testthat/test-extensions.R` | 含 `skip_if_not_installed("ggbreak")` 真实断轴用例及通用 `print.*` 包装器中性记录断言 | `[x]` |

---

## Track 4：超大表可选 Parquet 写入支持（阶段 3.3）

| ID | 目标项 | 涉及文件 | 验收标准 | 状态 |
| :--- | :--- | :--- | :--- | :---: |
| **T4.1** | `gl_asset_bundle()` 新增 `table_format = c("csv", "parquet")` 可选 Parquet 序列化 | `R/package-assets.R`, `DESCRIPTION`, `tests/testthat/test-package-assets.R` | 指定 `table_format = "parquet"` 时写出标准 `tables/<id>.parquet`（保留 1-based `_row_id`），同步更新包内 `asset-map.json`、`tables/schema.json` 与 `manifest.json` SHA-256，跨 Python/DuckDB/R 直接可读 | `[x]` |

---

## Track 5：核心下游 AI 工作流落地与防走样/对账脚本（阶段 2.1 & 2.2，包外 `skills/`）

> 严格遵守 [`AGENTS.md`](../AGENTS.md) **Core Principle #2（Strict In-Core Boundary）**：所有 Skill 与下游审计/校验脚本均置于包外顶层 `skills/` 目录，并在 `.Rbuildignore` 中排除，绝不污染 R 核心包。

| ID | 目标项 | 涉及文件 | 验收标准 | 状态 |
| :--- | :--- | :--- | :--- | :---: |
| **T5.1** | 落地 `gloss-svg-refine`（工作流二）+ 派生资产规范（`derived-manifest.json` 含 `parent_manifest_sha256`）+ 独立零依赖 Python 数据图元几何防走样校验脚本 | `skills/gloss-svg-refine/SKILL.md`, `skills/gloss-svg-refine/scripts/verify_svg_fidelity.py` | 校验脚本自动验证 `parent_manifest_sha256`、数据层图元数量、几何中心容差与文本未篡改；对合规排版美化放行（PASS），对挪动数据点坐标或篡改数值标签精准拦截（FAIL） | `[x]` |
| **T5.2** | 落地 `gloss-audit`（工作流三）+ 独立零依赖 Python 图文统计对账脚本 | `skills/gloss-audit/SKILL.md`, `skills/gloss-audit/scripts/audit_bundle.py` | 自动读取 `.gloss/` 包中的 `asset-map.json`、`tables/*.csv`、`schema.json` 与 `omitted.json`，输出样本量 `n`、分组均值/中位数/IQR、区间极值与比例尺核查报告 | `[x]` |
| **T5.3** | 落地 `gloss-report`（多面板与项目级可追溯图表解读报告 Skill） | `skills/gloss-report/SKILL.md` | 定义强制溯源引用规范（每条结论绑定 `table_id` + `_row_id` + `panel_id` + `leaf_id` + `sources/`）与报告结构模板 | `[x]` |
| **T5.4** | 端到端跨语言自动化验收测试（R 导出 `.gloss/` -> Python 派生精修防走样正反例测试 + Python 统计对账测试） | `skills/tests/test_workflows.py` | `python3 skills/tests/test_workflows.py` 全绿通过 | `[x]` |

---

## Track 6：Project Map 同步、文档更新与全量 CRAN 零告警封版验证

| ID | 目标项 | 涉及文件 | 验收标准 | 状态 |
| :--- | :--- | :--- | :--- | :---: |
| **T6.1** | 更新 `.project-map/build_map.R` 自动识别 `skills/` 中已落地的外部组件并在 LikeC4 地图点绿 | `.project-map/build_map.R`, `.project-map/model/90-live-status.c4`, `.project-map/status.json` | `likec4 build` 零报错，`skill_refine`/`skill_audit`/`skill_report` 自动更新状态与源码链接 | `[x]` |
| **T6.2** | 全量 `devtools::test()`、`python3 skills/tests/test_workflows.py`、`R CMD build`（含 Vignette）与 `R CMD check --no-manual` 零 ERROR / WARNING / NOTE | 全仓 | 全部测试 100% PASS，`R CMD check` 输出 `Status: OK` | `[x]` |
