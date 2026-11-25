export type LayerId =
  | 'code'
  | 'ir'
  | 'panels'
  | 'axes'
  | 'layers'
  | 'svg';

export type AssetNodeId = 'asset-map' | 'asset-bundle' | 'asset-work';

export type DrawerTab = 'inspector' | 'contract' | 'assets' | 'roadmap';

export interface SamplePoint {
  id: string;
  rowId: number;
  patientId: string;
  pc1: number;
  pc2: number;
  group: 'A' | 'B';
  cohortLabel: string;
  colorHex: string;
  panelId: 'P1' | 'P2';
  leafId: 'L004' | 'L005';
  elementId: string;
  note: string;
}

export interface ArchitectureLayer {
  id: LayerId;
  index: number; // 0 (bottom) to 5 (top)
  stepNumber: number; // 1..6
  shortLabel: string;
  titleZh: string;
  titleEn: string;
  tagline: string;
  svgPainPoint: string;
  glueKeys: string[];
  description: string;
  accentHex: string;
  rModules: string[];
  keyFields: { label: string; value: string }[];
  rSnippet: string;
  bundleFiles: string[];
}

export interface ContractComponentSpec {
  code: string;
  meaning: string;
  targetLayerId: LayerId;
  badge?: string;
}

export interface ContractLayerSpec {
  id: 'nav-semantic' | 'dual-visual' | 'dual-table' | 'provenance-contract';
  index: number;
  title: string;
  filesSummary: string;
  positioning: string;
  svgPainPoint: string;
  accentHex: string;
  components: ContractComponentSpec[];
}

export interface GlueChainSpec {
  id: 'visual-addressing' | 'data-semantics' | 'integrity-lineage';
  index: number;
  title: string;
  keys: string[];
  connectedFiles: string;
  capability: string;
  mappingMode: 'panel-grid' | 'point-lineage' | 'asset-export';
  accentHex: string;
}

export interface ProgressiveScenario {
  id:
    | 'zero-error-trace'
    | 'safe-lock-refine'
    | 'reviewer-audit'
    | 'dual-track-collab';
  title: string;
  subtitle: string;
  plainSvgLimit: string;
  glossValue: string;
  encodingSteps: { stepTitle: string; detail: string; keys: string[] }[];
  actionLabel: string;
  targetMode: 'point-lineage' | 'panel-grid' | 'scale-color' | 'asset-export';
  targetSampleId: string | null;
  cliCommand: string;
}

export interface PipelineStep {
  step: number;
  titleZh: string;
  titleEn: string;
  summary: string;
  detail: string;
  highlightLayers: LayerId[];
  outputArtifacts: string[];
  rSource: string;
}

export interface BundleTreeNode {
  name: string;
  kind: 'dir' | 'file';
  size?: string;
  badge?: string;
  role: string;
  children?: BundleTreeNode[];
}

export interface PublicApiSpec {
  name: string;
  signature: string;
  sourceFile: string;
  summary: string;
}

export interface EngineSupportSpec {
  id: string;
  name: string;
  sourceFile: string;
  loc: number;
  dependency: 'Imports' | 'Suggests';
  highlights: string;
  extensions?: string[];
}

export interface EcosystemConsumer {
  id: string;
  name: string;
  role: string;
  status: 'implemented' | 'planned';
  scripts?: string[];
  reads: string;
  example: string;
}

export interface EndToEndPathSpec {
  id: string;
  index: number;
  title: string;
  flow: string;
  capability: string;
  targetMode: 'overview' | 'panel-grid' | 'point-lineage' | 'scale-color' | 'asset-export';
  targetSampleId: string | null;
}

export interface GuardrailSpec {
  id: string;
  name: string;
  detail: string;
  pass: boolean;
}

export interface ClosureAxisSpec {
  axis: 'A' | 'B' | 'C';
  title: string;
  closed: number;
  total: number;
  highlights: string;
}

export interface ProjectLiveStatus {
  schemaVersion: string;
  packageVersion: string;
  gitCommit: string;
  rFiles: number;
  rLoc: number;
  exportsCount: number;
  enginesCount: number;
  rTestsPassed: number;
  rTestsFailed: number;
  rTestsSkipped: number;
  rTestFiles: number;
  pyWorkflowsPassed: number;
  pyWorkflowsTotal: number;
  issuesClosed: number;
  issuesTotal: number;
  guardrails: GuardrailSpec[];
  closureAxes: ClosureAxisSpec[];
}

export interface RoadmapStage {
  stage: number;
  title: string;
  status: 'done' | 'planned';
  positioning: string;
  deliverables: string[];
  acceptance: string;
}

export interface DesignPrinciple {
  id: string;
  titleZh: string;
  titleEn: string;
  summary: string;
}

export interface SampleLineageTrace {
  sample: SamplePoint;
  rawRow: string;
  builtRow: string;
  scaleRule: string;
  guideBinding: string;
  panelMapping: string;
  svgElement: string;
  semanticsLock: string;
  rowAccounting: string;
  cardinality: '1:1';
  lineageTier: 'row_exact';
}

export const PROJECT_LIVE_STATUS: ProjectLiveStatus = {
  schemaVersion: '1.1.0',
  packageVersion: '0.1.0',
  gitCommit: '5f51d03 (main)',
  rFiles: 14,
  rLoc: 8924,
  exportsCount: 8,
  enginesCount: 5,
  rTestsPassed: 839,
  rTestsFailed: 0,
  rTestsSkipped: 0,
  rTestFiles: 15,
  pyWorkflowsPassed: 4,
  pyWorkflowsTotal: 4,
  issuesClosed: 23,
  issuesTotal: 23,
  guardrails: [
    {
      id: 'exports',
      name: '8 个公开 API 严格对齐',
      detail: 'NAMESPACE 仅导出 8 个核心函数，零接口膨胀',
      pass: true,
    },
    {
      id: 'suggests',
      name: '第三方引擎全量隔离 Suggests',
      detail: 'ggplot2 / patchwork / ComplexHeatmap / nanoparquet 均在 Suggests',
      pass: true,
    },
    {
      id: 'cran',
      name: 'CRAN 零污染卫生检查',
      detail: '0 <<- 超赋值 · 0 .GlobalEnv 写入 · 默认 tempdir() · 0 残留 Rplots*.pdf',
      pass: true,
    },
    {
      id: 'boundary',
      name: '内核极简边界护栏',
      detail: '14 个精炼 R 文件（8,924 LOC），Agent/Patch/Audit 全部置于包外 skills/',
      pass: true,
    },
    {
      id: 'tests',
      name: '跨语言回归测试全绿',
      detail: 'R testthat 839/839 PASS（15 测试文件）· Python 工作流 4/4 PASS',
      pass: true,
    },
  ],
  closureAxes: [
    {
      axis: 'A',
      title: '主轴 A · 资产最后一公里信息断层',
      closed: 6,
      total: 6,
      highlights:
        '行级双向桥接（built_row_id/_raw_row_id/part_role）、跨引擎统一坐标逆变换与 11 节点连续 stops、项级 ir.guides、semantic_role/edit_policy/z_index、热图共享轴切片区间、stat_params 与 row_accounting 静默丢行账本',
    },
    {
      axis: 'B',
      title: '主轴 B · 人 ↔ 图表 ↔ 智能体三元协作',
      closed: 4,
      total: 4,
      highlights:
        '异构感知分层（<10 KB texts.json + 144dpi preview.png）、双向指代协议（focus_bridge.py）、声明式 Visual Patch 与 parent_capture_id 双轨闭环、只读源包 + .gloss.work/ 伴随工作态',
    },
    {
      axis: 'C',
      title: '主轴 C · 零侵入抓拍防腐与优雅降级',
      closed: 13,
      total: 13,
      highlights:
        '非继承外壳通用兜底（pheatmap/ggsurvplot）、ggbreak 自定义 print.* 启发式恢复、zeroGrob 防连坐、ggrepel 动态 makeContent 与 label_links、CJK 字宽修正、base 原语全覆盖、混合页兜底与多页 page=k',
    },
  ],
};

// 20 deterministic PCA samples matching the reference cluster layout
export const PCA_SAMPLES: SamplePoint[] = [
  { id: 'S1', rowId: 1, patientId: 'PT-1001', pc1: -6.2, pc2: -7.4, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0041', note: '基线对照组典型样本' },
  { id: 'S2', rowId: 2, patientId: 'PT-1002', pc1: -5.8, pc2: -5.2, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0042', note: '常规表达分布核心区' },
  { id: 'S3', rowId: 3, patientId: 'PT-1003', pc1: -4.9, pc2: -7.1, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0043', note: '对照组低 PC2 边界点' },
  { id: 'S4', rowId: 4, patientId: 'PT-1004', pc1: -4.6, pc2: -4.2, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0044', note: '组 A 质心邻近样本' },
  { id: 'S5', rowId: 5, patientId: 'PT-1005', pc1: -3.9, pc2: -2.1, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0045', note: '过渡区间样本' },
  { id: 'S6', rowId: 6, patientId: 'PT-1006', pc1: -3.7, pc2: -7.3, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0046', note: '对照组下缘稳定样本' },
  { id: 'S7', rowId: 7, patientId: 'PT-1007', pc1: -3.4, pc2: -5.0, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0047', note: '重复测序高一致样本' },
  { id: 'S8', rowId: 8, patientId: 'PT-1008', pc1: -2.6, pc2: -4.6, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0048', note: '组 A 右侧内聚点' },
  { id: 'S9', rowId: 9, patientId: 'PT-1009', pc1: -2.5, pc2: -1.8, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0049', note: '轻度响应边缘样本' },
  { id: 'S10', rowId: 10, patientId: 'PT-1010', pc1: -1.5, pc2: 0.6, group: 'A', cohortLabel: 'Group A (Control)', colorHex: '#2F855A', panelId: 'P1', leafId: 'L004', elementId: 'E0050', note: '组 A 右上边界离群候选' },

  { id: 'S11', rowId: 11, patientId: 'PT-2011', pc1: 3.6, pc2: -0.2, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0051', note: '处理组早期响应起点' },
  { id: 'S12', rowId: 12, patientId: 'PT-2012', pc1: 4.5, pc2: 2.3, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0052', note: '处理组中段主簇样本' },
  { id: 'S13', rowId: 13, patientId: 'PT-2013', pc1: 4.9, pc2: -0.1, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0053', note: '低 PC2 处理组样本' },
  { id: 'S14', rowId: 14, patientId: 'PT-2014', pc1: 5.5, pc2: 5.4, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0054', note: '强响应核心样本' },
  { id: 'S15', rowId: 15, patientId: 'PT-2015', pc1: 5.8, pc2: 2.6, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0055', note: '组 B 质心代表样本' },
  { id: 'S16', rowId: 16, patientId: 'PT-2016', pc1: 6.2, pc2: 0.0, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0056', note: '组 B 底部基准点' },
  { id: 'S17', rowId: 17, patientId: 'PT-2017', pc1: 6.9, pc2: 2.4, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0057', note: '高 PC1 稳定响应点' },
  { id: 'S18', rowId: 18, patientId: 'PT-2018', pc1: 7.4, pc2: 4.4, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0058', note: '高剂量通路激活样本' },
  { id: 'S19', rowId: 19, patientId: 'PT-2019', pc1: 7.8, pc2: 7.8, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0059', note: '右上极值离群样本（需核查批次）' },
  { id: 'S20', rowId: 20, patientId: 'PT-2020', pc1: 8.2, pc2: 4.9, group: 'B', cohortLabel: 'Group B (Treated)', colorHex: '#DF6A2B', panelId: 'P2', leafId: 'L005', elementId: 'E0060', note: '高 PC1 右缘样本' },
];

export const ARCHITECTURE_LAYERS: ArchitectureLayer[] = [
  {
    id: 'code',
    index: 0,
    stepNumber: 1,
    shortLabel: '代码与数据',
    titleZh: '代码与数据',
    titleEn: 'Code, Raw Tables & Sources',
    tagline: '原始样本表（CSV / Parquet）、绘图源码、多页选择与重跑演化链',
    svgPainPoint:
      '纯 SVG 丢掉了未画上图的样本主键（如 patient_id）、原始样本量 n、多页裁剪边界，也无法证明出自哪份 R 代码、调用表达式与包版本。',
    glueKeys: [
      '_row_id',
      'call_expr',
      'parent_capture_id',
      'provenance_mode',
      'table_format="parquet"',
    ],
    description:
      '强制在 tables/raw.csv（超大表支持 nanoparquet 写出 tables/raw.parquet）首列写入 1-based _row_id，并在 tables/schema.json 保留因子水平与时区；同时在 sources/ 归档代码、文档与 session.json（含 deparse(substitute(x)) 调用表达式），通过 parent 参数串联计算层重跑演化链 parent_capture_id，多页输入按 page=k 选择并在 omitted.json 留痕。',
    accentHex: '#2D603E',
    rModules: ['R/capture.R', 'R/sources.R', 'R/package-assets.R'],
    keyFields: [
      { label: '原始输入表', value: 'tables/raw.csv 或 .parquet（1-based _row_id）' },
      { label: '类型与因子声明', value: 'tables/schema.json（factor levels / tz / stat_role）' },
      { label: '重跑版本链 (Track B)', value: 'gloss(p, parent = old_cap) → parent_capture_id' },
      { label: '来源可信级别', value: 'explicit · runtime_observed (+ call_expr) · sniffed_hint' },
      { label: '边界透明披露', value: 'omitted.json（裁剪表/列/行及被跳过的多页）' },
    ],
    rSnippet: `cap <- gloss(
  ggplot(df, aes(PC1, PC2, colour = group)) +
    geom_point(size = 3) + theme_classic(),
  sources = list(code = "plot_pca.R", docs = "methods.md"),
  preview = TRUE, preview_dpi = 144,
  page = NULL, parent = prev_bundle_dir
)
gl_asset_bundle(cap, "fig.gloss", table_format = "csv")`,
    bundleFiles: [
      'tables/raw.csv (.parquet)',
      'tables/schema.json',
      'sources/session.json',
      'omitted.json',
    ],
  },
  {
    id: 'ir',
    index: 1,
    stepNumber: 2,
    shortLabel: 'Engine IR',
    titleZh: 'Engine IR 引擎中间态',
    titleEn: 'Engine Intermediate Representation (v1.1)',
    tagline: '带 _raw_row_id 的计算表、静默丢行账本、连续 stops 色板与聚类序',
    svgPainPoint:
      '纯 SVG 丢掉了统计参数（SD/SE/95% CI）、被 NA 或 limits 静默剔除的行号、连续色标停靠点、聚合组回指关系以及热图绘制期才定型的聚类重排。',
    glueKeys: [
      '_raw_row_id / _group_key',
      'row_accounting',
      'ir.layers.params',
      'ir.scales (map + stops)',
      'ir.orders',
    ],
    description:
      '在绘图瞬间直接从 R 内存提取 Schema v1.1 Engine IR：built_layer*.csv 写入 _raw_row_id（1:1 透传回指）或 _group_key + tables/groups_*.json（聚合回指）；ir.layers 完整采集 stat_params/geom_params（method/formula/level/fun.data）与 row_accounting（精确区分 n_dropped_na 与 n_dropped_oob 行号）；ir.scales 兼顾离散 map 与连续 11 节点 stops/midpoint/na_value/oob；ir.orders 锁定 ComplexHeatmap 绘制期聚类置换。',
    accentHex: '#356D4A',
    rModules: [
      'R/engine-ggplot.R',
      'R/engine-heatmap.R',
      'R/engine-patchwork.R',
      'R/ir-lineage.R',
    ],
    keyFields: [
      { label: '行级双向桥接', value: 'built_layer*.csv (_raw_row_id / _group_key) + groups_*.json' },
      { label: '静默丢行账本', value: 'row_accounting: n_raw / n_built / n_dropped_na / n_dropped_oob' },
      { label: '统计与几何参数', value: 'ir.layers.params (method / formula / level / fun.data / bins)' },
      { label: '离散+连续色板字典', value: 'ir.scales: map + 11 节点 stops / midpoint / na_value / oob' },
      { label: '绘制期排序锁', value: 'ir.orders (ComplexHeatmap row_order / column_order)' },
    ],
    rSnippet: `# asset-map.json#/ir/layers[0] (Schema v1.1.0)
{
  "geom": "GeomPoint", "stat": "StatIdentity",
  "params": { "size": 3, "na.rm": false },
  "row_accounting": {
    "n_raw": 20, "n_built": 20,
    "n_dropped_na": 0, "n_dropped_oob": 0,
    "dropped_raw_row_ids": []
  }
}`,
    bundleFiles: [
      'asset-map.json#/ir',
      'tables/built_layer1.csv',
      'tables/groups_built_layer*.json',
    ],
  },
  {
    id: 'panels',
    index: 2,
    stepNumber: 3,
    shortLabel: '面板布局',
    titleZh: '面板与统一坐标逆变换',
    titleEn: 'Panels, Viewports & Inverse Transforms',
    tagline: '左上角 scene.coord 基准 + 变换/原始双域 + 跨面板共享轴组',
    svgPainPoint:
      '不同引擎对数轴/翻转轴定义域口径不一，热图主图与侧边注释条切片脱节，超密图层光栅化后更完全依赖数学逆投影才能框选反查数据行。',
    glueKeys: [
      'scene.coord (top-left)',
      'domain_space: "transformed"',
      'x_data_domain / x_trans',
      'row_axis_group / row_slice_range',
    ],
    description:
      '顶层声明 scene.coord（pt 单位、左上角原点、Y 向下、viewBox）；跨 5 大引擎统一输出渲染空间 x_domain/y_domain（domain_space="transformed"，含 expansion）与原始数值域 x_data_domain/y_data_domain、x_trans/y_trans；为 ComplexHeatmap 切片与 HeatmapAnnotation 补齐 row_slice_range 与共享轴组 row_axis_group/col_axis_group，使超密光栅图也能经逆投影精准 box-to-rows。',
    accentHex: '#467D58',
    rModules: ['R/ir-lineage.R', 'R/engine-patchwork.R', 'R/engine-heatmap.R', 'R/query.R'],
    keyFields: [
      { label: '全局坐标基准', value: 'scene.coord: { unit: "pt", origin: "top-left", y_direction: "down" }' },
      { label: '双域口径统一', value: 'x_domain (transformed) + x_data_domain + x_trans ("log-10"等)' },
      { label: '跨面板共享轴', value: 'x_axis_group / row_axis_group + row_slice_range (热图/拼图)' },
      { label: '光栅逆投影支撑', value: 'panel_px_to_rendered() 支持 >10^4 点光栅框选反查' },
    ],
    rSnippet: `# asset-map.json#/ir/panels[0] (Schema v1.1.0)
{
  "panel_id": "P1", "bbox_pt": [48.0, 26.0, 412.0, 314.0],
  "domain_space": "transformed", "expansion_included": true,
  "x_domain": [-10.0, 10.0], "x_data_domain": [-10.0, 10.0],
  "x_trans": "identity", "x_axis_group": "scale_x_1"
}`,
    bundleFiles: ['asset-map.json#/scene/coord', 'asset-map.json#/ir/panels', 'scene/leaves.json'],
  },
  {
    id: 'axes',
    index: 3,
    stepNumber: 4,
    shortLabel: '坐标与标注',
    titleZh: '语义锁、项级图例与文字索引',
    titleEn: 'Edit Locks, Item Guides & texts.json',
    tagline: '显式 edit_policy 权限锁 + 项级 ir.guides + <10 KB 文字快读层',
    svgPainPoint:
      '传统 SVG 里数据点、标签、图例与轴刻度混为一谈，Agent 要找一条 p 值或检测标签重叠得硬啃数 MB 的 elements.json，挪动标签还容易拉断 ggrepel 引线或撞上 clipPath 裁断。',
    glueKeys: [
      'semantic_role / edit_policy',
      'scene/texts.json (<10 KB)',
      'ir.guides.entries',
      'scene.label_links',
      'z_index / clip_bbox_pt',
    ],
    description:
      'Schema v1.1 为每片叶子与文本注入正交 semantic_role 与 edit_policy（geometry_locked / style_only / movable）、1-based 全局层序 z_index 与裁切框 clip_bbox_pt；默认剥离 <10 KB 的 scene/texts.json 供 Agent 秒读全量标题/刻度/显著性标注；导出项级 ir.guides.entries（swatch_elements ↔ label_elements ↔ domain）及 ggrepel 的 label_links 引线配对。',
    accentHex: '#598A67',
    rModules: ['R/ir-lineage.R', 'R/capture.R', 'R/engine-ggplot.R', 'R/package-assets.R'],
    keyFields: [
      { label: '显式编辑权限锁', value: 'edit_policy: geometry_locked · style_only · movable' },
      { label: '异构文本快读层', value: 'scene/texts.json (< 10 KB 全量文字锚点与 CJK 修正框)' },
      { label: '项级图例映射', value: 'ir.guides.entries: domain ↔ swatch_elements + label_elements' },
      { label: '引线与层序裁切', value: 'scene.label_links (ggrepel) + z_index + clip_bbox_pt' },
    ],
    rSnippet: `# ir.guides.entries[0] & scene/texts.json
{
  "guide_id": "G1", "kind": "legend", "aesthetic": "colour",
  "items": [
    { "domain": "A", "label": "Group A (Control)",
      "swatch_elements": ["E0381"], "label_elements": ["E0382"] }
  ]
}`,
    bundleFiles: [
      'scene/texts.json',
      'scene/leaves.json',
      'scene/elements.json',
      'asset-map.json#/ir/guides',
    ],
  },
  {
    id: 'layers',
    index: 4,
    stepNumber: 5,
    shortLabel: '图层 Layers',
    titleZh: '图层血缘、组件角色与防腐层',
    titleEn: 'Geom Layers, Row Bridges & Hardening',
    tagline: '元素级 built_row_id/part_role + 显式 lineage_tier + 扩展包防腐',
    svgPainPoint:
      '扁平几何体分不清箱线图须线/中位线对应哪组数据，单层空分面（zeroGrob）易引发连坐断链，ggrepel/sf/ggtree/ggbreak 等科研扩展包更是频繁破坏行序对齐。',
    glueKeys: [
      'built_row_id / part_role',
      'lineage_tier (row_exact / group_linked)',
      'cardinality',
      'dense = 10000',
    ],
    description:
      '数据图元自带 built_row_id / group_id 与复合几何 part_role（point/box/median/whisker/outlier）；lineage 显式标注血缘精密度梯队 lineage_tier（row_exact / group_linked / layer_linked / chrome）及 degradation_reason；全面通过 ggrepel、sf（WKT+CRS）、ggtree、ggbreak、pheatmap/ggsurvplot 通用兜底与 zeroGrob 防连坐测试，超密层（dense > 10,000）自动透明切片。',
    accentHex: '#DF6A2B',
    rModules: ['R/ir-lineage.R', 'R/engine-registry.R', 'R/engine-base.R', 'R/capture.R'],
    keyFields: [
      { label: '元素级行/组件桥', value: 'elements.json: built_row_id · group_id · part_role' },
      { label: '显式血缘精密度', value: 'lineage_tier: row_exact · group_linked · layer_linked · chrome' },
      { label: '复杂扩展防腐', value: 'ggrepel · sf · ggtree · ggbreak · zeroGrob 隔离 · 混合页兜底' },
      { label: '超密光栅退化', value: 'dense > 10,000 → scene/rasters/L*.png + 逆投影可查' },
    ],
    rSnippet: `# asset-map.json#/lineage[3] (Schema v1.1.0)
{
  "leaf_id": "L004", "panel_id": "P1", "layer_id": 1,
  "table_id": "built_layer1", "cardinality": "1:1",
  "semantic_role": "data_mark", "edit_policy": "geometry_locked",
  "lineage_tier": "row_exact", "degradation_reason": null
}`,
    bundleFiles: [
      'asset-map.json#/lineage',
      'scene/elements.json',
      'scene/rasters/*.png',
    ],
  },
  {
    id: 'svg',
    index: 5,
    stepNumber: 6,
    shortLabel: '结构化 SVG',
    titleZh: '三模视觉层与密码学封条',
    titleEn: 'Tri-Modal Visual Layer & Integrity Seal',
    tagline: '不可变 original.svg + 可寻址 scene.svg + 同坐标 preview.png + 声明式派生',
    svgPainPoint:
      '裸 SVG 既无法让 VLM 零成本一眼感知版式拥挤度，又缺乏可寻址锁与防篡改封条；让大模型直接手改数万行 XML 极易移偏数据点或破坏命名空间。',
    glueKeys: [
      '<g id="L004" data-gloss-leaf="L004">',
      'assets/preview.png (144dpi)',
      'capture_id / sha256',
      'parent_manifest_sha256',
    ],
    description:
      '单次冻结显示列表同时派生：只读基准 assets/original.svg、展开 <use> 并挂载 data-gloss-leaf 的 scene/scene.svg，以及像素对齐的 assets/preview.png（不重跑 RNG，供 VLM 审美快览）。manifest.json 写入全量 sha256 封条；下游通过 apply_visual_patch.py 声明式编译派生图至 .gloss.work/derived/，并由 verify_svg_fidelity.py 数学级拦截任何几何走样。',
    accentHex: '#234F33',
    rModules: ['R/capture.R', 'R/package-assets.R'],
    keyFields: [
      { label: '只读基准存档', value: 'assets/original.svg（永不覆写）' },
      { label: '可寻址工作底图', value: 'scene/scene.svg（<g id="L..." data-gloss-leaf>）' },
      { label: 'VLM 同坐标快览', value: 'assets/preview.png（冻结显示列表光栅化 · 144 dpi）' },
      { label: '防篡改与派生校验', value: 'manifest.json (sha256) → .gloss.work/derived-manifest.json' },
    ],
    rSnippet: `<svg id="scene.svg" viewBox="0 0 504 360">
  <g id="L004" data-gloss-leaf="L004">
    <!-- semantic_role=data_mark · edit_policy=geometry_locked -->
    <circle cx="128.4" cy="249.6" r="4.2" fill="#2F855A"/>
  </g>
</svg>`,
    bundleFiles: [
      'assets/original.svg',
      'assets/preview.png',
      'scene/scene.svg',
      'manifest.json',
    ],
  },
];

/**
 * The 4-Layer Open Contract (Schema v1.1.0 四层开放契约分工)
 */
export const CONTRACT_LAYERS: ContractLayerSpec[] = [
  {
    id: 'nav-semantic',
    index: 1,
    title: '导航与语义层（含异构快读索引）',
    filesSummary: 'asset-map.json (≈24 KB) + scene/texts.json (<10 KB)',
    positioning: '整套资产包的“全局目录单 + 编译器中间态（Engine IR v1.1）”，让 Agent 几十 KB 掌握全景。',
    svgPainPoint:
      '纯 SVG 动辄几十 MB 且缺乏语义角色、静默丢行账本与连续色标，AI 读不进上下文，靠视觉估计极易幻觉。',
    accentHex: '#DF6A2B',
    components: [
      {
        code: 'scene.coord + ir.panels',
        meaning: '顶层声明左上角原点与 viewBox；各子图统一输出变换后渲染域 x_domain、原始值域 x_data_domain、x_trans 及热图/拼图共享轴组（row_axis_group / row_slice_range）。',
        targetLayerId: 'panels',
        badge: 'v1.1',
      },
      {
        code: 'ir.layers (params + row_accounting)',
        meaning: '完整采集 stat_params/geom_params（method/level/fun.data）及静默丢行账本（n_dropped_na / n_dropped_oob / dropped_raw_row_ids）。',
        targetLayerId: 'ir',
        badge: 'v1.1',
      },
      {
        code: 'ir.scales (map + stops) + ir.guides.entries',
        meaning: '离散色板映射 + 连续 11 节点 stops/midpoint/oob，并与项级图例（swatch_elements ↔ label_elements ↔ domain）双向绑定。',
        targetLayerId: 'axes',
        badge: 'v1.1',
      },
      {
        code: 'lineage (semantic_role / edit_policy / lineage_tier)',
        meaning: '显式声明基数（1:1/N:1/1:M/stat_aggregated）、编辑权限锁（geometry_locked/style_only/movable）与血缘精密度梯队（row_exact/group_linked/chrome）。',
        targetLayerId: 'layers',
        badge: 'v1.1',
      },
      {
        code: 'scene/texts.json (<10 KB)',
        meaning: '默认从巨型 elements.json 剥离全部文字锚点（标题、刻度、显著性 p 值、基因名），支持 Agent 零噪音秒检文本碰撞与数值。',
        targetLayerId: 'axes',
        badge: 'v1.1',
      },
    ],
  },
  {
    id: 'dual-visual',
    index: 2,
    title: '三模视觉底图层',
    filesSummary: 'original.svg + scene.svg + preview.png + leaves/elements.json + rasters/',
    positioning: '同时服务基准归档、确定性 DOM 寻址、VLM 审美快览与超密光栅防卡顿。',
    svgPainPoint:
      'svglite 默认混用匿名 <defs>/<use> 符号、无引线绑定、无预览图、超大点数撑爆浏览器，修改后难以验真。',
    accentHex: '#234F33',
    components: [
      {
        code: 'assets/original.svg + assets/preview.png',
        meaning: 'original.svg 保留设备未改动字节；preview.png（144 dpi）基于同一冻结显示列表光栅化，像素严格对齐 scene.coord，零重绘 RNG 风险。',
        targetLayerId: 'svg',
        badge: 'v1.1',
      },
      {
        code: 'scene/scene.svg + scene.label_links',
        meaning: '展开 <use> 并注入稳定 <g id="L..." data-gloss-leaf="L...">；记录 ggrepel 标签 ↔ 引线 ↔ 锚点配对，移动标签自动牵引引线。',
        targetLayerId: 'svg',
        badge: 'v1.1',
      },
      {
        code: 'scene/leaves.json (z_index / clip_bbox_pt)',
        meaning: '记录 grob 路径、版面槽位、从底到顶 1-based z_index、生效 <clipPath> 裁切框以及 semantic_role / edit_policy。',
        targetLayerId: 'axes',
        badge: 'v1.1',
      },
      {
        code: 'scene/elements.json (built_row_id / part_role)',
        meaning: '单图元包围盒、字号/锚点/CJK 修正框，并附带 built_row_id、group_id 及复合几何 part_role（box/median/whisker/outlier）。',
        targetLayerId: 'layers',
        badge: 'v1.1',
      },
      {
        code: 'scene/rasters/*.png (dense = 10000)',
        meaning: '超密非文本层自动生成透明光栅切片，轴/文字保持矢量，配合面板逆投影依然支持像素框选反查原始数据行。',
        targetLayerId: 'layers',
      },
    ],
  },
  {
    id: 'dual-table',
    index: 3,
    title: '双表数据与行级桥接层',
    filesSummary: 'raw + built_layer* (CSV/Parquet) + groups_*.json + schema.json',
    positioning: '用跨语言开放表格打通 element ↔ built_row ↔ raw_row 双向精确索引。',
    svgPainPoint:
      '即使同时保存了 raw 和 built 表，缺少 _raw_row_id 外键与聚合分组索引时，面对 NA 丢行或箱线图聚合仍无法反查原始样本。',
    accentHex: '#2F855A',
    components: [
      {
        code: 'tables/raw.csv 或 .parquet (_row_id)',
        meaning: '原始输入表，首列写 1-based _row_id；大表可通过 table_format="parquet"（nanoparquet）无损写出，Python/DuckDB 秒读。',
        targetLayerId: 'code',
        badge: 'v1.1',
      },
      {
        code: 'tables/built_layer*.csv (_raw_row_id / _group_key / stat_role)',
        meaning: '引擎计算后的坐标与统计中间表：1:1 图层透传 _raw_row_id；聚合/N:1 图层附 _group_key 与 stat_role（median/quartile/interval/se）。',
        targetLayerId: 'ir',
        badge: 'v1.1',
      },
      {
        code: 'tables/groups_built_layer*.json',
        meaning: '轻量聚合回指索引，记录箱线图/直方图/均值误差棒的每个统计分组由哪些原始 raw _row_id 构成。',
        targetLayerId: 'ir',
        badge: 'v1.1',
      },
      {
        code: 'tables/schema.json',
        meaning: '声明字段类型、R 因子水平顺序（factor levels）、时区及 stat_role 统计列角色，跨语言读取零丢序。',
        targetLayerId: 'code',
      },
    ],
  },
  {
    id: 'provenance-contract',
    index: 4,
    title: '溯源封条与伴随协作层',
    filesSummary: 'sources/ + omitted.json + manifest.json + 旁侧 .gloss.work/',
    positioning: '严守源包只读不可变，同时支持双轨修改演化链与多轮人机协同持久化。',
    svgPainPoint:
      '孤立 SVG 无出生证明、无重算版本链，审计问题单与排版修订状态在多轮对话后阅后即焚。',
    accentHex: '#467D58',
    components: [
      {
        code: 'sources/ (provenance_mode + call_expr)',
        meaning: '归档 code/、docs/ 与 session.json（记录捕获调用表达式、包版本、Git 状态），区分 explicit / runtime_observed / sniffed_hint。',
        targetLayerId: 'code',
      },
      {
        code: 'omitted.json',
        meaning: '透明披露打包时裁剪的表/列/行以及多页输入被跳过的页码（page=k），杜绝 AI 把子集误判为全量。',
        targetLayerId: 'code',
      },
      {
        code: 'manifest.json (capture_id / parent_capture_id / sha256)',
        meaning: '全量文件 SHA-256 封条；Track B 计算层重跑通过 parent_capture_id 串联前后两代完整资产包。',
        targetLayerId: 'svg',
        badge: 'v1.1',
      },
      {
        code: '旁侧 .gloss.work/ (focus / threads / patches / derived)',
        meaning: '严守 .gloss/ 只读不可变，所有交互选区、审稿问题单（accepted/dismissed/recompute_requested）、声明式补丁与派生 SVG 统一外挂落盘。',
        targetLayerId: 'svg',
        badge: 'v1.1',
      },
    ],
  },
];

/**
 * The 3 Core Glue-Code Chains (Schema v1.1.0 三条核心粘合编码)
 */
export const GLUE_CHAINS: GlueChainSpec[] = [
  {
    id: 'visual-addressing',
    index: 1,
    title: '视觉寻址与编辑锁链',
    keys: [
      'leaf_id (L004)',
      'panel_id (P1/P2)',
      'semantic_role + edit_policy',
      'ir.guides.entries',
    ],
    connectedFiles:
      'scene.svg (<g data-gloss-leaf>) ↔ leaves.json (z_index/clip_bbox_pt) ↔ texts.json ↔ ir.guides.entries & ir.panels (scene.coord)',
    capability:
      '用显式 edit_policy（geometry_locked / style_only / movable）锁死数据图元与刻度数字、放行标签避让并自动牵引 ggrepel 引线，经项级 ir.guides 同步换色。',
    mappingMode: 'panel-grid',
    accentHex: '#2F855A',
  },
  {
    id: 'data-semantics',
    index: 2,
    title: '行级双向语义桥接链',
    keys: [
      'built_row_id ↔ _raw_row_id',
      '_group_key + groups_*.json',
      'part_role / stat_role',
      'row_accounting',
    ],
    connectedFiles:
      'elements.json (built_row_id/part_role) ↔ built_layer*.csv (_raw_row_id/stat_role) ↔ groups_*.json ↔ raw.csv (_row_id) + ir.layers.row_accounting',
    capability:
      '矢量层走元素外键、超密光栅层走面板坐标逆变换，均能双向贯通像素选区 ↔ 原始样本行（focus_bridge.py），并自动揪出 NA / limits 静默丢弃行号。',
    mappingMode: 'point-lineage',
    accentHex: '#DF6A2B',
  },
  {
    id: 'integrity-lineage',
    index: 3,
    title: '完整性封条与双轨演化链',
    keys: [
      'capture_id / sha256',
      'parent_manifest_sha256 (Track A)',
      'parent_capture_id (Track B)',
      '.gloss.work/',
    ],
    connectedFiles:
      'manifest.json ↔ original.svg + preview.png + scene.svg + tables/* ↔ .gloss.work/ (patches/ + derived-manifest.json + threads.json)',
    capability:
      '单次捕获冻结随机态；排版微调走 Track A 声明式补丁 + 数学级零位移校验，改数据/模型走 Track B 回源重跑串联 parent_capture_id，全程只读不可变。',
    mappingMode: 'asset-export',
    accentHex: '#234F33',
  },
];

/**
 * 4 High-Value Real-World Progressive Scenarios (四类实战场景演练)
 */
export const PROGRESSIVE_SCENARIOS: ProgressiveScenario[] = [
  {
    id: 'zero-error-trace',
    title: '场景一：像素选区 ↔ 原始样本行双向反查（含超密光栅）',
    subtitle: '以右上角极值离群样本 S19 (PT-2019) 为例 · focus_bridge.py',
    plainSvgLimit:
      '普通 SVG 只能目测像素估数，遇 >10,000 点单细胞 UMAP 导 PNG 则彻底失明，AI 查出异常样本后也无法回投到图面高亮。',
    glossValue:
      '人框选像素区直达原始样本 ID（box-to-rows），AI 筛出异常行直接回投高亮压暗叠加图（rows-to-overlay）。',
    encodingSteps: [
      {
        stepTitle: '异构感知先行（<35 KB 秒读全景）',
        detail:
          '先读 asset-map.json（scene.coord + ir.panels 双域 + lineage）与 <10 KB 的 scene/texts.json，必要时用 preview.png 视觉快览，不把数 MB elements.json 塞爆上下文。',
        keys: ['asset-map.json', 'scene/texts.json', 'assets/preview.png'],
      },
      {
        stepTitle: '行级外键 + 逆投影双保险反查',
        detail:
          '矢量图元经 E0059 → built_row_id=19 → built_layer1._raw_row_id=19 → raw.csv (PT-2019)；超密光栅层经 panel_px_to_rendered() 数学逆投影同样精准命中原始行。',
        keys: ['built_row_id=19', '_raw_row_id=19', 'panel_px_to_rendered'],
      },
      {
        stepTitle: '回投高亮叠加图与共享焦点',
        detail:
          'focus_bridge.py rows-to-overlay 生成 .gloss.work/focus.json 与 derived/highlight-overlay.svg，圈出目标点、压暗背景并挂出归因便签。',
        keys: ['focus.json', 'highlight-overlay.svg', 'focus_bridge.py'],
      },
    ],
    actionLabel: '在 3D 中演练 S19 离群点 6 层溯源',
    targetMode: 'point-lineage',
    targetSampleId: 'S19',
    cliCommand:
      'python3 skills/gloss/scripts/focus_bridge.py rows-to-overlay --bundle fig.gloss --table raw --rows 19 --svg-out fig.gloss.work/derived/highlight-overlay.svg',
  },
  {
    id: 'safe-lock-refine',
    title: '场景二：声明式视觉补丁 → 零走样出版级精修',
    subtitle: 'Track A 表现层闭环 · apply_visual_patch.py + verify_svg_fidelity.py',
    plainSvgLimit:
      '让大模型直接手改几万行裸 SVG XML 既浪费输出 Token，又极易拖偏数据点、拉断 ggrepel 引线或漏改图例色块。',
    glossValue:
      '大模型只吐十几行声明式 JSON Patch，由确定性执行器按 edit_policy 锁自动联动编译并出具密码学零位移回执。',
    encodingSteps: [
      {
        stepTitle: '按显式 edit_policy 划分绝对安全边界',
        detail:
          'L004/L005 数据点与坐标轴刻度标为 geometry_locked（严禁挪动坐标或改字）；标题/数据标签/图例标签标为 movable，网格与背景标为 style_only。',
        keys: ['geometry_locked', 'movable', 'style_only', 'clip_bbox_pt'],
      },
      {
        stepTitle: '声明式补丁自动联动色板与引线',
        detail:
          'apply_visual_patch.py 执行 set_typography、remap_scale_palette（凭 ir.guides.entries 同步替换散点与图例 swatch）、translate_label（自动牵引 scene.label_links 引线）与 add_callout。',
        keys: ['gloss-visual-patch', 'ir.guides.entries', 'scene.label_links'],
      },
      {
        stepTitle: '密码学封条 + 几何容差自动验真',
        detail:
          '输出至 .gloss.work/derived/ 并写入 derived-manifest.json（含 parent_manifest_sha256），自动调用 verify_svg_fidelity.py 拦截任何数据点位移或文字篡改。',
        keys: ['parent_manifest_sha256', 'verify_svg_fidelity.py', 'tol <= 0.05pt'],
      },
    ],
    actionLabel: '在 3D 中点亮安全锁与视觉寻址链',
    targetMode: 'panel-grid',
    targetSampleId: null,
    cliCommand:
      'python3 skills/gloss-svg-refine/scripts/apply_visual_patch.py --bundle fig.gloss --patch fig.gloss.work/patches/pub-v1.json --out fig.gloss.work/derived/fig-pub.svg',
  },
  {
    id: 'reviewer-audit',
    title: '场景三：投稿前“审稿级”图文数据对账与静默丢行预警',
    subtitle: '论文/图注定量核验 · audit_bundle.py + row_accounting',
    plainSvgLimit:
      '图注宣称 n=100 实际因坐标轴截断只画了 95 个点；正文写 SD 实际画的是 SE 或 90% CI；重跑数据后正文 p 值漏改。',
    glossValue:
      '脱离 R 进程离线核验 SHA-256、raw/built 双表统计口径、误差棒参数与静默丢行行号，输出四级中性裁决账单。',
    encodingSteps: [
      {
        stepTitle: '完整性校验 + 静默丢行账本扫描',
        detail:
          '先验 manifest.json 哈希与 omitted.json 裁剪边界，再查 ir.layers.row_accounting 精确揪出因 NA（n_dropped_na）或 limits 越界（n_dropped_oob）被静默剔除的原始行号。',
        keys: ['row_accounting', 'dropped_raw_row_ids', 'omitted.json'],
      },
      {
        stepTitle: '核查统计参数口径与双表原值',
        detail:
          '从 ir.layers.params 读取 method/formula/level/fun.data（区分 mean_se 与 95% CI），在 raw 表验样本量/均值、在 built 表凭 stat_role 与 groups_*.json 验误差棒与箱线分位。',
        keys: ['ir.layers.params', 'stat_role', 'groups_*.json'],
      },
      {
        stepTitle: '出具四级对账单并持久化问题单',
        detail:
          '逐条判定 VERIFIED / ROUNDING_DRIFT / MISMATCH / UNVERIFIABLE_FROM_BUNDLE，并通过 --emit-threads 自动写入 .gloss.work/threads.json 供作者裁决。',
        keys: ['audit_bundle.py', 'threads.json', 'MISMATCH'],
      },
    ],
    actionLabel: '在 3D 中点亮双表与色板语义流',
    targetMode: 'scale-color',
    targetSampleId: null,
    cliCommand:
      'python3 skills/gloss-audit/scripts/audit_bundle.py --bundle fig.gloss --claims claims.json --emit-threads fig.gloss.work/threads.json',
  },
  {
    id: 'dual-track-collab',
    title: '场景四：双轨分流修改与 .gloss.work/ 多轮持久化协作',
    subtitle: '只读源包 + 伴随工作态 + 可溯源报告 · workspace_state.py & gloss-report',
    plainSvgLimit:
      '真实科研改图横跨数天与多角色（审计 → 作者裁决 → 重跑数据 → 终稿精修），传统会话上下文阅后即焚，源图屡被原地覆盖。',
    glossValue:
      '源包 .gloss/ 永久只读不可变，排版微调走 Track A，改数据/模型走 Track B 串联 parent_capture_id，全链路状态外挂持久化。',
    encodingSteps: [
      {
        stepTitle: 'Track A（表现层）vs Track B（计算层）严格分流',
        detail:
          '调字号/换色/避让标签走 Track A 补丁写入 .gloss.work/derived/；剔除质控失败样本或改对数轴严禁硬改 SVG，必须改 R 脚本重跑 gloss(p, parent = old_cap)。',
        keys: ['Track A: Visual Patch', 'Track B: parent_capture_id'],
      },
      {
        stepTitle: '旁侧 .gloss.work/ 共享人机工作态',
        detail:
          'workspace_state.py 维护 workspace.json、focus.json、threads.json（open / accepted / dismissed / recompute_requested）、patches/ 与 derived/，跨天跨 Agent 无缝接力。',
        keys: ['workspace.json', 'threads.json', 'workspace_state.py'],
      },
      {
        stepTitle: 'gloss-report 强制行级证据引用',
        detail:
          '面向多面板 patchwork 与多切片 ComplexHeatmap 合成解读报告，每条定量结论强制附带 [tables/#_row_id, panel, leaf, sources#sha256] 锚点。',
        keys: ['gloss-report', 'ir.orders', '行级强制引用'],
      },
    ],
    actionLabel: '在 3D 中点亮完整资产包与 .gloss.work/ 双轨流',
    targetMode: 'asset-export',
    targetSampleId: null,
    cliCommand:
      'python3 skills/gloss/scripts/workspace_state.py init --bundle fig.gloss',
  },
];

export const PIPELINE_STEPS: PipelineStep[] = [
  {
    step: 1,
    titleZh: '单次捕获、插桩与快览光栅',
    titleEn: 'Single-Draw Capture & Preview',
    summary: '在 svglite 绘图瞬间拦截，单次渲染同时产出 original.svg、可寻址 scene.svg 与 144 dpi preview.png。',
    detail:
      '通过 groupGrob 包裹与绘图期 viewport 探针展开 <use>、注入稳定叶子 ID（L001...）、计算含 CJK 修正的精确包围盒与 <clipPath>，并直接从冻结显示列表光栅化 preview.png（绝不二次执行用户代码或 RNG）；支持非继承对象通用打印兜底、base+grid 混合页兜底与多页 page=k 选择。',
    highlightLayers: ['svg', 'panels'],
    outputArtifacts: ['assets/original.svg', 'assets/preview.png', 'scene/scene.svg', 'scene/leaves.json'],
    rSource: 'R/capture.R (1,881 LOC)',
  },
  {
    step: 2,
    titleZh: '五引擎中间态与行桥接提取',
    titleEn: 'Engine IR & Row-Bridge Extraction',
    summary: '直读 R 内存中的 built 表（含 _raw_row_id）、统计参数、静默丢行账本、连续 stops 色板、项级图例与聚类序。',
    detail:
      '覆盖 ggplot2、patchwork（无副作用锁 jitter 种子 + 合并图例）、ComplexHeatmap（聚类 ir.orders + 切片区间 + 共享轴注释条）、base（步进回放全原语）、grid 及 gl_register_engine() 扩展注册；自动采集 stat_params/geom_params 与 row_accounting（区分 NA 与 limits 越界行号）。',
    highlightLayers: ['ir', 'layers'],
    outputArtifacts: ['asset-map.json#/ir', 'tables/built_layer*.csv', 'tables/groups_*.json'],
    rSource: 'R/engine-*.R (3,697 LOC)',
  },
  {
    step: 3,
    titleZh: '语义角色、编辑锁与结构血缘',
    titleEn: 'Semantics, Locks & Lineage',
    summary: '构建 element ↔ built_row ↔ raw_row 桥接，注入 semantic_role、edit_policy、z_index 与 lineage_tier。',
    detail:
      '为每个数据图元绑定 built_row_id / group_id / part_role（如 box/median/whisker）；按正交规则赋予 edit_policy（geometry_locked / style_only / movable）与 lineage_tier（row_exact / group_linked / layer_linked / chrome）；自动识别 ggrepel 引线配对 label_links 并隔离 zeroGrob 空分面防连坐。',
    highlightLayers: ['svg', 'layers', 'axes', 'panels'],
    outputArtifacts: ['asset-map.json#/lineage', 'scene/elements.json', 'scene/texts.json'],
    rSource: 'R/ir-lineage.R (651 LOC)',
  },
  {
    step: 4,
    titleZh: '来源清单与计算演化链盘点',
    titleEn: 'Source Inventory & Capture Chain',
    summary: '汇总脚本、文档、session.json（含 call_expr）与 parent_capture_id，标注 provenance_mode。',
    detail:
      '区分 explicit（显式传入）、runtime_observed（R 会话直测对象、包版本、Git 状态与 deparse(substitute(x)) 入口表达式）及 sniffed_hint（Quarto/knitr 轻量线索）；当通过 gloss(p, parent = old_cap) 重算时自动串联 parent_capture_id。',
    highlightLayers: ['code'],
    outputArtifacts: ['sources/code/', 'sources/docs/', 'sources/session.json'],
    rSource: 'R/sources.R (423 LOC)',
  },
  {
    step: 5,
    titleZh: '分层开放序列化与旁侧协作',
    titleEn: 'Layered Serialization & Companion State',
    summary: '零重绘派生几十 KB Asset Map、自包含 Asset Bundle（dir/zip, CSV/Parquet）并衔接只读外挂 .gloss.work/。',
    detail:
      '全部采用 UTF-8 SVG、JSON、CSV/Parquet 开放格式与 SHA-256 manifest.json 封条；默认剥离 <10 KB scene/texts.json；裁剪表/列/行及跳过页码透明写入 omitted.json；包外 4 个 Skill + 5 个纯 Python CLI 离线消费并把协作态写入 .gloss.work/。',
    highlightLayers: ['svg', 'ir', 'code'],
    outputArtifacts: ['asset-map.json', 'figure.gloss/', 'manifest.json', 'figure.gloss.work/'],
    rSource: 'R/package-assets.R (736 LOC)',
  },
];

export const ASSET_MAP_JSON = `{
  "format": "gloss-asset-map",
  "schema_version": "1.1.0",
  "capture_id": "sha256:9f4c2a...81e0",
  "parent_capture_id": "sha256:3a1e0b...42c1",
  "page": {
    "engine": "ggplot",
    "engine_version": "4.0.3",
    "device": "svglite 2.2.2",
    "width_pt": 504.0,
    "height_pt": 360.0,
    "preview_dpi": 144,
    "pages": 1
  },
  "scene": {
    "coord": {
      "unit": "pt",
      "origin": "top-left",
      "y_direction": "down",
      "viewBox": [0, 0, 504.0, 360.0]
    },
    "original_svg": { "path": "assets/original.svg", "bytes": 18420 },
    "scene_svg": { "path": "scene/scene.svg", "bytes": 19680 },
    "preview_png": {
      "path": "assets/preview.png",
      "dpi": 144,
      "width_px": 1008,
      "height_px": 720,
      "scale_from_pt": 2.0
    },
    "texts": { "path": "scene/texts.json", "n_texts": 24, "bytes": 4120 },
    "label_links": [],
    "n_panels": 2,
    "n_leaves": 18,
    "n_elements": 412
  },
  "ir": {
    "panels": [
      {
        "panel_id": "P1",
        "bbox_pt": [48.0, 26.0, 412.0, 314.0],
        "domain_space": "transformed",
        "expansion_included": true,
        "x_domain": [-10.0, 10.0],
        "x_data_domain": [-10.0, 10.0],
        "y_domain": [-10.0, 10.0],
        "y_data_domain": [-10.0, 10.0],
        "x_trans": "identity",
        "y_trans": "identity",
        "x_axis_group": "scale_x_1",
        "coord": "CoordCartesian"
      }
    ],
    "layers": [
      {
        "layer_id": 1,
        "geom": "GeomPoint",
        "stat": "StatIdentity",
        "params": { "size": 3, "na.rm": false },
        "aes": { "x": "PC1", "y": "PC2", "colour": "group" },
        "raw_table": "raw",
        "built_table": "built_layer1",
        "row_accounting": {
          "n_raw": 20,
          "n_built": 20,
          "n_dropped_na": 0,
          "n_dropped_oob": 0,
          "dropped_raw_row_ids": []
        }
      }
    ],
    "scales": [
      {
        "aesthetic": "colour",
        "field": "group",
        "scale_type": "discrete",
        "map": [
          { "domain": "A", "value": "#2F855A", "label": "Group A (Control)" },
          { "domain": "B", "value": "#DF6A2B", "label": "Group B (Treated)" }
        ]
      }
    ],
    "guides": {
      "entries": [
        {
          "guide_id": "G1",
          "kind": "legend",
          "aesthetic": "colour",
          "items": [
            {
              "domain": "A",
              "label": "Group A (Control)",
              "swatch_elements": ["E0381"],
              "label_elements": ["E0382"]
            },
            {
              "domain": "B",
              "label": "Group B (Treated)",
              "swatch_elements": ["E0383"],
              "label_elements": ["E0384"]
            }
          ]
        }
      ]
    },
    "orders": {}
  },
  "lineage": [
    {
      "leaf_id": "L004",
      "grob_name": "geom_point.points.42",
      "layout_slot": "panel-1-1",
      "panel_id": "P1",
      "layer_id": 1,
      "table_id": "built_layer1",
      "cardinality": "1:1",
      "semantic_role": "data_mark",
      "edit_policy": "geometry_locked",
      "lineage_tier": "row_exact",
      "degradation_reason": null,
      "n_rows": 10,
      "n_elements": 10
    }
  ]
}`;

export const BUNDLE_TREE: BundleTreeNode[] = [
  {
    name: 'figure.gloss/',
    kind: 'dir',
    badge: '只读不可变',
    role: 'Schema v1.1.0 自包含开放图资产包（目录或 .zip）',
    children: [
      {
        name: 'manifest.json',
        kind: 'file',
        size: '2.1 KB',
        role: '契约封条：capture_id、parent_capture_id（Track B）与全量文件 sha256',
      },
      {
        name: 'asset-map.json',
        kind: 'file',
        size: '24 KB',
        role: '全局索引与 Engine IR：scene.coord、panels 双域、layers 丢行账本、scales/stops、项级 guides 与 lineage',
      },
      {
        name: 'omitted.json',
        kind: 'file',
        size: '0.4 KB',
        role: '边界披露：裁剪的表/列/行及多页输入跳过的页码（page=k）',
      },
      {
        name: 'assets/',
        kind: 'dir',
        role: '只读原始基准与 VLM 快览图',
        children: [
          {
            name: 'original.svg',
            kind: 'file',
            size: '18.4 KB',
            role: 'svglite 设备直接输出的未改动原始 SVG 字节',
          },
          {
            name: 'preview.png',
            kind: 'file',
            size: '68 KB',
            badge: 'v1.1',
            role: '冻结显示列表光栅化的像素对齐快览图（144 dpi），供 VLM 审美巡检',
          },
        ],
      },
      {
        name: 'scene/',
        kind: 'dir',
        role: '可寻址结构化工作底图与异构文字索引',
        children: [
          {
            name: 'scene.svg',
            kind: 'file',
            size: '19.7 KB',
            role: '展开 <use> 并注入 <g id="L..." data-gloss-leaf> 的工作底图',
          },
          {
            name: 'texts.json',
            kind: 'file',
            size: '4.1 KB',
            badge: 'v1.1',
            role: '<10 KB 全量文字锚点（标题/刻度/p 值/基因名 + 语义角色），免读数 MB elements.json',
          },
          {
            name: 'leaves.json',
            kind: 'file',
            size: '6.8 KB',
            role: '叶子档案：grob 路径、槽位、z_index、clip_bbox_pt、semantic_role 与 edit_policy',
          },
          {
            name: 'elements.json',
            kind: 'file',
            size: '34.2 KB',
            role: '单图元几何表：包围盒、CJK 修正框、字号锚点及 built_row_id / group_id / part_role',
          },
          {
            name: 'rasters/',
            kind: 'dir',
            role: '可选：dense > 10,000 超密非文本层的透明光栅切片 (*.png)',
          },
        ],
      },
      {
        name: 'tables/',
        kind: 'dir',
        role: '跨语言双表与聚合回指索引（支持 CSV / Parquet）',
        children: [
          {
            name: 'schema.json',
            kind: 'file',
            size: '1.5 KB',
            role: '字段类型、factor levels、时区及 stat_role 统计列语义',
          },
          {
            name: 'raw.csv (.parquet)',
            kind: 'file',
            size: '2.1 KB',
            role: '原始输入表（1-based _row_id；大表可选 table_format="parquet"）',
          },
          {
            name: 'built_layer1.csv',
            kind: 'file',
            size: '2.9 KB',
            badge: 'v1.1',
            role: '引擎计算表（含 _raw_row_id / _group_key 与 stat_role）',
          },
          {
            name: 'groups_built_layer*.json',
            kind: 'file',
            size: '0.8 KB',
            badge: 'v1.1',
            role: '聚合图层（如箱线图/误差棒）每个分组对应原始 raw _row_id 的回指字典',
          },
        ],
      },
      {
        name: 'sources/',
        kind: 'dir',
        role: '出生证明与环境快照',
        children: [
          {
            name: 'code/plot_pca.R',
            kind: 'file',
            size: '1.5 KB',
            role: '绘图源码快照（provenance_mode: explicit）',
          },
          {
            name: 'docs/methods.md',
            kind: 'file',
            size: '3.2 KB',
            role: '数据字典、实验设计说明或图注草稿',
          },
          {
            name: 'session.json',
            kind: 'file',
            size: '2.6 KB',
            role: 'R 与包版本、Git 状态及捕获调用表达式 call_expr（runtime_observed）',
          },
        ],
      },
    ],
  },
];

export const COMPANION_WORK_TREE: BundleTreeNode[] = [
  {
    name: 'figure.gloss.work/',
    kind: 'dir',
    badge: '外挂协作态',
    role: '旁侧可写协作目录：多轮审稿、框选焦点、声明式补丁与派生终稿（绝不修改源包）',
    children: [
      {
        name: 'workspace.json',
        kind: 'file',
        size: '0.5 KB',
        role: '锚定 source_capture_id 与 source_manifest_sha256',
      },
      {
        name: 'focus.json',
        kind: 'file',
        size: '1.1 KB',
        role: '人 ↔ Agent 双向指代焦点（box-to-rows / rows-to-overlay 统一交换契约）',
      },
      {
        name: 'threads.json',
        kind: 'file',
        size: '2.4 KB',
        role: '锚定在 panel/leaf/row 上的审计问题单与人工裁决（open / accepted / dismissed / recompute_requested）',
      },
      {
        name: 'patches/',
        kind: 'dir',
        role: '声明式 gloss-visual-patch JSON 补丁指令（十几行 JSON 替代手改 XML）',
      },
      {
        name: 'derived/',
        kind: 'dir',
        role: '出版级派生 SVG、highlight-overlay.svg 与 derived-manifest.json（含 parent_manifest_sha256）',
      },
    ],
  },
];

export const PUBLIC_APIS: PublicApiSpec[] = [
  {
    name: 'gloss()',
    signature:
      'gloss(x, sources = NULL, width = NULL, height = NULL, dense = 10000, engine = NULL, preview = TRUE, preview_dpi = 144, page = NULL, parent = NULL, ...)',
    sourceFile: 'R/capture.R',
    summary: '绘图编译现场单次抓拍，返回含双 SVG、preview.png、Engine IR、血缘与来源清单的 gloss_capture 对象。',
  },
  {
    name: 'gl_asset_map()',
    signature: 'gl_asset_map(cap, path = NULL)',
    sourceFile: 'R/package-assets.R',
    summary: '从同一次内存捕获态零重绘派生几十 KB 轻量 asset-map.json 全局索引目录。',
  },
  {
    name: 'gl_asset_bundle()',
    signature:
      'gl_asset_bundle(cap, path = NULL, select = NULL, rows = NULL, format = c("dir", "zip"), table_format = c("csv", "parquet"), overwrite = TRUE)',
    sourceFile: 'R/package-assets.R',
    summary: '打包自包含开放资产目录或 .zip，支持表/列/行筛选、Parquet 写出与 omitted.json 透明披露。',
  },
  {
    name: 'gl_scene()',
    signature: 'gl_scene(cap)',
    sourceFile: 'R/query.R',
    summary: '检视内存中的 scene.coord、双 SVG、leaves、elements、label_links、guides 与 lineage。',
  },
  {
    name: 'gl_tables()',
    signature: 'gl_tables(cap, name = NULL)',
    sourceFile: 'R/query.R',
    summary: '直接读取捕获的 raw 与 built_layer*（含 _raw_row_id）数据表。',
  },
  {
    name: 'gl_sources()',
    signature: 'gl_sources(cap)',
    sourceFile: 'R/query.R',
    summary: '返回全部来源材料清单（含 provenance_mode、字节数与 SHA-256）。',
  },
  {
    name: 'gl_query()',
    signature:
      'gl_query(cap, panel = NULL, leaf = NULL, box = NULL, table = NULL, rows = NULL)',
    sourceFile: 'R/query.R',
    summary: '内存态空间/结构/行切片双向反查：box 可收敛至精确数据行（含光栅逆投影），rows 可反查命中图元。',
  },
  {
    name: 'gl_register_engine()',
    signature: 'gl_register_engine(name, classes, capture_fn, ...)',
    sourceFile: 'R/engine-registry.R',
    summary: '开放第三方绘图引擎扩展注册；未注册的可打印外壳对象（pheatmap/ggsurvplot）亦自动走通用兜底流。',
  },
];

export const ENGINE_COVERAGE: EngineSupportSpec[] = [
  {
    id: 'ggplot',
    name: 'ggplot2',
    sourceFile: 'R/engine-ggplot.R',
    loc: 1882,
    dependency: 'Suggests',
    highlights:
      '单次构建提取 raw/built（_raw_row_id + groups_*.json）、离散/11 节点连续 stops 色板、stat/geom_params、row_accounting 丢行账本、项级 ir.guides.entries、zeroGrob 防连坐',
    extensions: ['ggrepel (label_links)', 'sf (WKT + CRS)', 'ggtree', 'ggbreak (启发式恢复)', 'ggnewscale'],
  },
  {
    id: 'heatmap',
    name: 'ComplexHeatmap',
    sourceFile: 'R/engine-heatmap.R',
    loc: 720,
    dependency: 'Suggests',
    highlights:
      '捕获 draw() 期聚类重排 ir.orders（row_order/column_order）、切片区间 row_slice_range/col_slice_range、主图与多侧 HeatmapAnnotation 跨面板共享轴组',
    extensions: ['rowAnnotation / columnAnnotation', 'anno_boxplot / anno_mark', 'row_split / column_split'],
  },
  {
    id: 'patchwork',
    name: 'patchwork',
    sourceFile: 'R/engine-patchwork.R',
    loc: 327,
    dependency: 'Suggests',
    highlights:
      '无副作用锁定子图随机抖动（geom_jitter）种子、子图命名空间隔离（p1_raw / p2_P1）、guides="collect" 合并图例项映射及跨子图对齐共享轴',
    extensions: ['guides = "collect"', 'wrap_elements()', 'geom_jitter 种子锁定'],
  },
  {
    id: 'base',
    name: 'base (graphics)',
    sourceFile: 'R/engine-base.R',
    loc: 729,
    dependency: 'Imports',
    highlights:
      'par(mfrow)/layout()/par(new=TRUE) 分步回放、plotXY/rect/polygon/segments/arrows/symbols/abline 全原语参数提取、与 ggplot 口径统一的坐标逆变换、多页 page=k 选择',
    extensions: ['plot(lm_fit) 多页选择', 'base + grid 混合页兜底'],
  },
  {
    id: 'grid',
    name: 'grid & 通用兜底',
    sourceFile: 'R/engine-grid.R',
    loc: 39,
    dependency: 'Imports',
    highlights:
      '原生 grobTree / gtable 插桩，并承接 pheatmap、survminer::ggsurvplot、lattice::trellis 等非继承外壳对象的零报错自动捕获兜底',
    extensions: ['pheatmap', 'ggsurvplot', 'lattice::trellis'],
  },
];

export const ECOSYSTEM_CONSUMERS: EcosystemConsumer[] = [
  {
    id: 'skill-gloss',
    name: '底座入口协议：skills/gloss',
    role: 'SKILL.md + focus_bridge.py + workspace_state.py',
    status: 'implemented',
    scripts: ['focus_bridge.py', 'workspace_state.py'],
    reads: '渐进读取 asset-map.json → scene/texts.json → assets/preview.png → 按需切片 CSV/Parquet',
    example: 'box-to-rows（含光栅逆投影）↔ rows-to-overlay（生成 highlight-overlay.svg），管理旁侧 .gloss.work/ 协作态',
  },
  {
    id: 'skill-refine',
    name: '出版精修执行器：skills/gloss-svg-refine',
    role: 'SKILL.md + apply_visual_patch.py + verify_svg_fidelity.py',
    status: 'implemented',
    scripts: ['apply_visual_patch.py', 'verify_svg_fidelity.py'],
    reads: 'scene.svg + leaves.json (edit_policy) + ir.guides.entries + scene.label_links',
    example: '编译声明式 gloss-visual-patch JSON（换字体、同步换色、避让标签牵引引线），自动拦截任何几何走样',
  },
  {
    id: 'skill-audit',
    name: '审稿统计审计：skills/gloss-audit',
    role: 'SKILL.md + audit_bundle.py',
    status: 'implemented',
    scripts: ['audit_bundle.py'],
    reads: 'manifest.json + omitted.json + ir.layers (params/row_accounting) + raw/built 表',
    example: '核对论文/图注原子声明，揪出 NA/limits 静默丢行与误差棒口径偏差，输出 threads.json 供作者裁决',
  },
  {
    id: 'skill-report',
    name: '可溯源报告合成：skills/gloss-report',
    role: 'SKILL.md（强制行级/面板/叶子/源码引用契约）',
    status: 'implemented',
    reads: '多包 asset-map.json + audit_bundle.py 统计摘要 + ir.orders + sources/',
    example: '面向多面板 patchwork / ComplexHeatmap 合成结构化分析报告，杜绝纯视觉估算幻觉',
  },
  {
    id: 'workbench',
    name: '独立静态前端：Workbench',
    role: '纯浏览器交互工作台（零 R 依赖）',
    status: 'planned',
    reads: '拖入 .gloss/ 目录或 .zip + 读写 .gloss.work/focus.json & threads.json',
    example: '鼠标刷选散点/点击图例项显隐分组、图层树巡检、原图 vs 派生图 Diff 对比与 AI 双向指代',
  },
  {
    id: 'mcp',
    name: '活体 R 会话桥接：gloss-mcp',
    role: 'RStudio / Positron 4 工具极薄 MCP（capture_figure / get_asset_map / query_slice / create_bundle）',
    status: 'planned',
    reads: '直连当前活体 R 会话内存态（无需先全量落盘）',
    example: '面对 50 万细胞单细胞 UMAP 边画边聊，按像素区域实时内存切片问答并按需导出子集包',
  },
];

export const END_TO_END_PATHS: EndToEndPathSpec[] = [
  {
    id: 'e2e-open-read',
    index: 1,
    title: 'R 编译现场 → 开放资产包 → 跨语言离线直读',
    flow: 'R 绘图对象 → gloss() → gl_asset_bundle(.gloss/) → Python / DuckDB / SQL / JS',
    capability: '含 SHA-256 manifest.json 与 tables/schema.json，脱离后台 R 进程零失真消费。',
    targetMode: 'asset-export',
    targetSampleId: null,
  },
  {
    id: 'e2e-progressive',
    index: 2,
    title: '智能体渐进式双通道感知路径（Token 效率）',
    flow: 'asset-map.json (≈24 KB) → scene/texts.json (<10 KB) → assets/preview.png → 按需切片读表',
    capability: 'VLM 审美快览 + 符号表零幻觉求真，免把整棵 SVG DOM 或百万行大表塞爆上下文。',
    targetMode: 'overview',
    targetSampleId: null,
  },
  {
    id: 'e2e-bidir',
    index: 3,
    title: '图面像素框 ↔ 底层原始数据行双向反查（含超密光栅）',
    flow: 'box-to-rows (built_row_id / 逆投影) ↔ rows-to-overlay (focus.json + highlight-overlay.svg)',
    capability: '矢量层走元素外键，>10^4 点光栅层走面板逆投影数学公式，均直达 raw 表具体行号。',
    targetMode: 'point-lineage',
    targetSampleId: 'S19',
  },
  {
    id: 'e2e-patch',
    index: 4,
    title: '声明式视觉补丁 → 自动联动编译 → 密码学防走样校验',
    flow: 'gloss-visual-patch JSON → apply_visual_patch.py → derived/*.svg → verify_svg_fidelity.py',
    capability: '自动执行 edit_policy 锁、ir.guides 项级换色与 ggrepel 引线牵引，确定性拦截几何走样。',
    targetMode: 'panel-grid',
    targetSampleId: null,
  },
  {
    id: 'e2e-audit',
    index: 5,
    title: '论文定量声明拆解 → 双表核验 → 静默丢行预警',
    flow: '原子声明 JSON + .gloss/ → audit_bundle.py → 结构化对账单 + threads.json',
    capability: '同时核对 raw 样本量、built 误差棒口径（fun.data/level）与 row_accounting 静默丢行。',
    targetMode: 'scale-color',
    targetSampleId: null,
  },
  {
    id: 'e2e-dual-track',
    index: 6,
    title: '双轨修改分流与 .gloss.work/ 多轮持久化协作',
    flow: 'Track A (parent_manifest_sha256) ‖ Track B (gloss parent_capture_id) + .gloss.work/',
    capability: '源包 .gloss/ 只读不可变，审计问题单、人工裁决与历次派生稿全部持久化在旁侧工作目录。',
    targetMode: 'asset-export',
    targetSampleId: null,
  },
];

export const ROADMAP_STAGES: RoadmapStage[] = [
  {
    stage: 1,
    title: '契约定型与单引擎内核底座',
    status: 'done',
    positioning: '攻克 svglite 单次双 SVG、精确视口探针与 8 函数极简表面',
    deliverables: [
      'R/capture.R 单次渲染产出 original.svg + scene.svg + preview.png',
      'ggplot2 引擎提取 raw/built、scales、layers 与结构血缘',
      'CRAN 卫生护栏与 8 个核心导出函数严格收敛',
    ],
    acceptance: '单次捕获绝不重绘，零 <<- / .GlobalEnv 污染，8/8 API 对齐',
  },
  {
    stage: 2,
    title: '多引擎全覆盖与复杂扩展防腐',
    status: 'done',
    positioning: '覆盖 R 科研绘图五大体系并消除边缘扩展硬报错与连坐断链',
    deliverables: [
      '补齐 patchwork（锁 jitter 种子/合并图例）、ComplexHeatmap（ir.orders/共享轴注释条）、base、grid',
      '打通 ggrepel / sf / ggtree / ggbreak 与非继承外壳（pheatmap/ggsurvplot）通用兜底',
      '超密光栅切片（dense = 10000）、Parquet 大表（nanoparquet）与多页 page=k',
    ],
    acceptance: '5/5 内置引擎 + 扩展包测试集全绿（test-extensions.R 31 PASS）',
  },
  {
    stage: 3,
    title: 'Schema v1.1.0 23 项断层闭环与包外 Agent 工具链',
    status: 'done',
    positioning: '完整闭合主轴 A/B/C 全部 23 项问题，Agent/CLI 离线场景 100% 就绪',
    deliverables: [
      '行级桥接（built_row_id/_raw_row_id/groups_*.json）、统一逆变换、11 节点连续 stops、项级 ir.guides',
      '显式 semantic_role / edit_policy / lineage_tier、row_accounting 丢行账本、<10 KB texts.json',
      '包外 4 个 Agent Skills + 5 个零依赖 Python CLI 执行器（focus_bridge / workspace_state / apply_visual_patch / verify_svg_fidelity / audit_bundle）',
    ],
    acceptance: 'R testthat 839/839 PASS · Python 工作流 4/4 PASS · 5/5 护栏全过',
  },
  {
    stage: 4,
    title: '外围交互壳层与真实论文 Evals 打磨',
    status: 'planned',
    positioning: '内核与确定性校验器已封稳，聚焦人类交互体验与实战评测',
    deliverables: [
      '独立静态前端 Workbench：浏览器拖入 .gloss 实现鼠标刷选、图层树与原图/派生 Diff',
      '极薄活体会话桥接 gloss-mcp：RStudio / Positron 未落盘即席抓取与内存切片 4 工具',
      '连续渐变热图/光栅 colorbar 补丁重绘增强 + 3–5 组真实生信/临床多面板论文图端到端 Agent Evals',
    ],
    acceptance: '人类研究者在浏览器直接框选与 AI 双向指代联动，真实论文审稿精修评测闭环',
  },
];

export const DESIGN_PRINCIPLES: DesignPrinciple[] = [
  {
    id: 'capture-at-source',
    titleZh: '现场提取 · 行车记录仪而非门禁',
    titleEn: 'Compiler Source Map, Not Gatekeeper',
    summary: '在 R 绘图编译现场直读引擎内存态与结构血缘，忠实记录不抛错阻断；统计审计与几何验证由上层按需执行。',
  },
  {
    id: 'strict-boundary',
    titleZh: '严守极简内核边界',
    titleEn: 'Strict In-Core Boundary',
    summary: 'R 包仅处理必须依赖活体 R 会话与图形设备的捕获、IR 提取与打包；Agent Skill、补丁器、MCP 与前端全置包外。',
  },
  {
    id: 'single-capture',
    titleZh: '单次捕获、绝不重绘',
    titleEn: 'Single Capture, Layered Payload',
    summary: 'Asset Map、Asset Bundle、双 SVG 与 preview.png 均派生自同一次冻结捕获态，天然锁死 jitter / UMAP 随机态。',
  },
  {
    id: 'file-first',
    titleZh: '文件优先与零私有编码',
    titleEn: 'File-First Open Formats',
    summary: '全量采用 UTF-8 SVG / JSON / CSV(Parquet) 开放格式，脱离常驻 R 进程即可被 Python / DuckDB / JS / Agent 直读。',
  },
  {
    id: 'minimal-surface',
    titleZh: '极简表面与零依赖膨胀',
    titleEn: 'Minimal Surface (8 Exports)',
    summary: 'NAMESPACE 严格收敛于 8 个核心函数，五大绘图引擎的第三方包全部隔离于 DESCRIPTION Suggests。',
  },
];

export function getLayerById(id: LayerId): ArchitectureLayer {
  const found = ARCHITECTURE_LAYERS.find((l) => l.id === id);
  if (!found) {
    throw new Error(`Unknown architecture layer: ${id}`);
  }
  return found;
}

export function getPipelineHighlightLayers(stepNumber: number): LayerId[] {
  const step = PIPELINE_STEPS.find((s) => s.step === stepNumber);
  return step ? [...step.highlightLayers] : [];
}

export function traceSampleLineage(sampleId: string): SampleLineageTrace | null {
  const sample = PCA_SAMPLES.find((s) => s.id === sampleId);
  if (!sample) return null;

  const swatchEl = sample.group === 'A' ? 'E0381' : 'E0383';
  const labelEl = sample.group === 'A' ? 'E0382' : 'E0384';

  return {
    sample,
    rawRow: `_row_id=${sample.rowId}, patient_id="${sample.patientId}", sample="${sample.id}", PC1=${sample.pc1.toFixed(1)}, PC2=${sample.pc2.toFixed(1)}, group="${sample.group}"`,
    builtRow: `_row_id=${sample.rowId}, _raw_row_id=${sample.rowId}, x=${sample.pc1.toFixed(1)}, y=${sample.pc2.toFixed(1)}, colour="${sample.colorHex}", PANEL=${sample.panelId === 'P1' ? 1 : 2}, stat_role="identity"`,
    scaleRule: `ir.scales: domain "${sample.group}" ↔ value "${sample.colorHex}" ↔ label "${sample.cohortLabel}"`,
    guideBinding: `ir.guides.entries[0]: domain "${sample.group}" ↔ swatch [${swatchEl}] + label [${labelEl}]`,
    panelMapping: `panel_id="${sample.panelId}" · domain_space="transformed" · x_trans="identity" · x_data_domain=[-10, 10] · origin="top-left"`,
    svgElement: `<g id="${sample.leafId}" data-gloss-leaf="${sample.leafId}"><circle id="${sample.elementId}" built_row_id="${sample.rowId}" part_role="point" fill="${sample.colorHex}" /></g>`,
    semanticsLock: `semantic_role="data_mark" · edit_policy="geometry_locked" · lineage_tier="row_exact" · z_index=${sample.leafId === 'L004' ? 4 : 5}`,
    rowAccounting: `row_accounting: n_raw=20, n_built=20, n_dropped_na=0, n_dropped_oob=0`,
    cardinality: '1:1',
    lineageTier: 'row_exact',
  };
}
