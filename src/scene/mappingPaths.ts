import { PCA_SAMPLES, type LayerId } from '../data/glossModel';
import {
  BASE_STACK_Y,
  LAYER_ORDER,
  PLATE_DEPTH,
  PLATE_WIDTH,
  PLOT_LOCAL_BOUNDS,
  getAssetCardTransforms,
  mapDataToPlateLocal,
  type LayerTransform,
  type LayoutMode,
} from './layoutMath';

export type MappingFocusMode =
  | 'overview'
  | 'panel-grid'
  | 'point-lineage'
  | 'scale-color'
  | 'asset-export';

export interface MappingModeSpec {
  id: MappingFocusMode;
  label: string;
  title: string;
  glueTag: string;
  formula: string;
  description: string;
  steps: { layerLabel: string; anchorName: string; detail: string }[];
}

export const MAPPING_MODES: MappingModeSpec[] = [
  {
    id: 'overview',
    label: '全览经纬',
    title: 'Schema v1.1 四层开放契约与三条粘合编码全览',
    glueTag: 'v1.1.0 · 4 层契约 + .gloss.work/',
    formula:
      'edit_policy 编辑锁 · built_row_id↔_raw_row_id 行桥 · Track A/B 封条',
    description:
      '二维平面承载 R 编译现场 6 层结构语义，三维动态信息流沿 Schema v1.1 三条粘合编码贯通至只读源包（Asset Map / .gloss/）与旁侧协作工作态（.gloss.work/）。',
    steps: [
      {
        layerLabel: '粘合编码 01',
        anchorName: '视觉寻址与编辑锁 · semantic_role / edit_policy',
        detail: '显式区分 geometry_locked 数据区、movable 文本标签与项级 ir.guides.entries',
      },
      {
        layerLabel: '粘合编码 02',
        anchorName: '行级双向桥 · built_row_id ↔ _raw_row_id',
        detail: '矢量图元走外键、>10^4 光栅走面板逆投影，双通道零误差直达原始行与 row_accounting',
      },
      {
        layerLabel: '异构感知层',
        anchorName: 'asset-map.json + texts.json (<10 KB) + preview.png',
        detail: 'VLM 视觉快览 + 极轻符号锚点，零幻觉精确查表与碰撞检测',
      },
      {
        layerLabel: '粘合编码 03',
        anchorName: '完整性封条与双轨演化 · Track A / Track B',
        detail: 'Track A 补丁写入 .gloss.work/derived/（parent_manifest_sha256）；Track B 重算串联 parent_capture_id',
      },
    ],
  },
  {
    id: 'panel-grid',
    label: '视觉寻址链',
    title: '粘合编码 01 · 视觉寻址、统一逆变换与编辑权限锁',
    glueTag: 'scene.coord · edit_policy · ir.guides',
    formula:
      'scene.svg <g id="L004"> ↔ leaves.json (z_index/edit_policy/clip_bbox_pt) ↔ texts.json ↔ ir.panels (domain_space)',
    description:
      '高亮锁定数据区（geometry_locked · L004/L005）与可安全精修区（movable · guide-box* / axis-title），以 scene.coord（左上角原点）与双域投影对齐 P1/P2 及共享轴组。',
    steps: [
      {
        layerLabel: '03 面板布局',
        anchorName: 'scene.coord + ir.panels (transformed / data_domain)',
        detail: '跨 5 引擎统一变换后渲染域、原始值域、x_trans 与热图/拼图共享轴组',
      },
      {
        layerLabel: '04 坐标与标注',
        anchorName: 'edit_policy 锁 + scene/texts.json (<10 KB)',
        detail: '显式标注 movable / style_only / geometry_locked，记录 z_index、clip_bbox_pt 与 label_links',
      },
      {
        layerLabel: '05 图层 Layers',
        anchorName: '[锁定] data_mark · L004 / L005 (row_exact)',
        detail: '每个数据图元绑定 built_row_id / part_role；>10,000 点退化为光栅仍支持逆投影',
      },
      {
        layerLabel: '06 结构化 SVG',
        anchorName: 'apply_visual_patch.py 声明式编译 + 零位移验真',
        detail: '按 edit_policy 自动拦截数据位移、牵引 ggrepel 引线并由 verify_svg_fidelity.py 验真',
      },
    ],
  },
  {
    id: 'point-lineage',
    label: '数据语义链',
    title: '粘合编码 02 · 行级双向语义桥（box ↔ rows 反查）',
    glueTag: 'built_row_id ↔ _raw_row_id · row_accounting',
    formula:
      'raw.csv (_row_id) ──▶ built_layer1 (_raw_row_id / stat_role) ──▶ P1/P2 逆投影 ──▶ E0059 (built_row_id=19)',
    description:
      '动态追踪原始样本如何经 _raw_row_id（聚合层走 _group_key + groups_*.json）与 row_accounting 静默丢行账本进入计算表，再通过 1:1 精确外键贯通至 SVG 图元，支撑 focus_bridge.py 双向指代。',
    steps: [
      {
        layerLabel: '01 双表原始层',
        anchorName: 'raw.csv / .parquet (_row_id + patient_id)',
        detail: '保留业务主键与 schema.json 因子水平顺序，超大表可选 nanoparquet',
      },
      {
        layerLabel: '02 引擎计算表',
        anchorName: 'built_layer1 (_raw_row_id) + row_accounting',
        detail: '显式透传原始行号、记录 stat_params（SD/SE/CI）并登记 NA/OOB 静默丢行行号',
      },
      {
        layerLabel: '03–04 坐标映射',
        anchorName: 'Panel P1/P2 统一逆投影 (panel_px_to_rendered)',
        detail: '同时支持矢量选区与 >10^4 光栅图层的像素框选反查',
      },
      {
        layerLabel: '05–06 图元血缘',
        anchorName: 'lineage_tier="row_exact" · focus_bridge.py',
        detail: '支持 box-to-rows 查表与 rows-to-overlay 回投 highlight-overlay.svg',
      },
    ],
  },
  {
    id: 'scale-color',
    label: '色板字典链',
    title: '视觉通道字典与项级图例绑定：ir.scales + ir.guides.entries',
    glueTag: 'map + 11 stops · swatch_elements',
    formula:
      'aes(colour=group) ──▶ ir.scales (map/stops) ──▶ ir.guides.entries (E0381/E0382) + L004/L005 原子换色',
    description:
      '展示 ir.scales（离散 map + 连续 11 节点 stops/midpoint/oob）如何通过项级 ir.guides.entries 精确绑定每个图例 swatch 与 label 图元，实现期刊换肤原子同步不漏改。',
    steps: [
      {
        layerLabel: '01 代码与数据',
        anchorName: 'aes(colour = group) + stat_params',
        detail: '源码声明颜色与统计通道绑定，捕获期自动保留原始表达式与参数',
      },
      {
        layerLabel: '02 Engine IR',
        anchorName: 'ir.scales（离散 map + 连续 11 节点 stops）',
        detail: '确定性提取 domain ↔ value ↔ label 及连续色标 midpoint / na_value / oob',
      },
      {
        layerLabel: '04 坐标与标注',
        anchorName: 'ir.guides.entries 项级 swatch/label 绑定',
        detail: '精确到单个图例色块 ID（E0381/E0383）与文本 ID（E0382/E0384），摆脱猜颜色',
      },
      {
        layerLabel: '05–06 图层与 SVG',
        anchorName: 'remap_scale_palette 原子同步换色',
        detail: 'apply_visual_patch.py 同步改写数据散点与对应图例项，经审计确保语义零漂移',
      },
    ],
  },
  {
    id: 'asset-export',
    label: '完整性契约链',
    title: '粘合编码 03 · 不可变源包、伴随工作态与双轨演化链',
    glueTag: 'capture_id · .gloss.work/ · Track A/B',
    formula:
      '单次捕获 ▶ .gloss/ (只读) ▶ .gloss.work/ (Track A) ↩ 01 (Track B)',
    description:
      '单次渲染产出轻量 Asset Map 与只读 .gloss/ 源包（双 SVG + preview.png + texts.json + CSV/Parquet）；表现层补丁与审稿状态写入旁侧 .gloss.work/（Track A），数据/模型重算则回源 R 脚本串联 parent_capture_id（Track B）。',
    steps: [
      {
        layerLabel: '索引与异构快览',
        anchorName: 'asset-map.json + texts.json + preview.png',
        detail: '几十 KB 索引 + <10 KB 文字表 + 144 dpi 快览图，Token 效率极致优化',
      },
      {
        layerLabel: '只读源包 .gloss/',
        anchorName: 'manifest.json (capture_id + 全量 sha256)',
        detail: '双 SVG、带 _raw_row_id 的双表、groups_*.json、sources/ 与 omitted.json 永久不可变',
      },
      {
        layerLabel: 'Track A · 伴随态',
        anchorName: '.gloss.work/ (focus / threads / patches / derived)',
        detail: '持久化框选焦点、审稿问题单、Visual Patch 与 derived-manifest.json (parent_manifest_sha256)',
      },
      {
        layerLabel: 'Track B · 计算重跑',
        anchorName: 'gloss(p, parent = old_cap) → parent_capture_id',
        detail: '涉及删样本或改模型时回改 R 脚本重跑，形成跨代密码学演化链',
      },
    ],
  },
];

/**
 * Single source of truth for exact 2D anchor positions (local x, z on each flat 2D sheet)
 * shared by BOTH plateTextures.ts (2D canvas rendering) AND buildGlossScene.ts (3D mapping threads).
 */
export const SHEET_ANCHORS = {
  // Layer 1 (code)
  codeAesColour: { x: -1.45, z: -0.34 },
  codeGeomPoint: { x: -1.45, z: 0.14 },
  codeRawS1: { x: 1.55, z: -0.26 },
  codeRawS14: { x: 1.55, z: 0.08 },
  codeRawS19: { x: 1.55, z: 0.42 },
  codeSourcesRight: { x: PLATE_WIDTH / 2 - 0.12, z: 0.78 },

  // Layer 2 (ir)
  irBuiltS1: { x: -1.45, z: -0.44 },
  irBuiltS14: { x: -1.45, z: 0.28 },
  irBuiltS19: { x: -1.45, z: 0.64 },
  irScaleA: { x: 0.52, z: -0.18 },
  irScaleB: { x: 0.52, z: 0.24 },
  irOrdersGeom: { x: 2.08, z: -0.18 },
  irExportRight: { x: PLATE_WIDTH / 2 - 0.12, z: -0.18 },

  // Layer 4 & 6 Legend (guide-box)
  legendGroupA: { x: PLOT_LOCAL_BOUNDS.maxX + 0.48, z: PLOT_LOCAL_BOUNDS.minZ + 0.46 },
  legendGroupB: { x: PLOT_LOCAL_BOUNDS.maxX + 0.48, z: PLOT_LOCAL_BOUNDS.minZ + 0.78 },

  // Layer 5 cluster centers (L004 Group A & L005 Group B)
  clusterA: mapDataToPlateLocal(-4.0, -4.5),
  clusterB: mapDataToPlateLocal(6.0, 2.8),

  // Stacked right-wing default positions (also available via getAssetCardTransforms)
  assetMapPos: { x: 5.85, y: 4.5, z: -0.92 },
  assetBundlePos: { x: 5.85, y: 2.58, z: 0.08 },
  assetWorkPos: { x: 5.85, y: 0.66, z: 1.08 },
} as const;

/**
 * Panel P1 and P2 corner coordinates on the plot plane (exact match with plateTextures.ts).
 */
export function getPanelSubRects() {
  const { minX, maxX, minZ, maxZ } = PLOT_LOCAL_BOUNDS;
  const w = maxX - minX;
  const padX = 0.08;
  const padZ = 0.08;
  const midX = minX + w * 0.5;

  return {
    p1: {
      minX: minX + padX,
      maxX: midX - 0.05,
      minZ: minZ + padZ,
      maxZ: maxZ - padZ,
    },
    p2: {
      minX: midX + 0.05,
      maxX: maxX - padX,
      minZ: minZ + padZ,
      maxZ: maxZ - padZ,
    },
  };
}

export interface MappingCurveDef {
  id: string;
  category: 'point' | 'scale' | 'panel' | 'asset' | 'recipe';
  colorHex: string;
  points: [number, number, number][];
  emphasized: boolean;
  opacity: number;
  dashed?: boolean;
  flowSpeed: number;
  anchorNodes: [number, number, number][];
}

export interface MeridianLineDef {
  points: [number, number, number][];
  colorHex: string;
  opacity: number;
  kind: 'frame' | 'panel-p1' | 'panel-p2' | 'axis-tick';
}

export interface FlowCalloutBadge {
  id: string;
  position: [number, number, number];
  code: string;
  role: string;
  colorHex: string;
}

function getSampleRawAnchor(sampleId: string): { x: number; z: number } {
  if (sampleId === 'S14') return SHEET_ANCHORS.codeRawS14;
  if (sampleId === 'S19') return SHEET_ANCHORS.codeRawS19;
  const sample = PCA_SAMPLES.find((s) => s.id === sampleId);
  if (sample && sample.group === 'B') return SHEET_ANCHORS.codeRawS14;
  return SHEET_ANCHORS.codeRawS1;
}

function getSampleBuiltAnchor(sampleId: string): { x: number; z: number } {
  if (sampleId === 'S14') return SHEET_ANCHORS.irBuiltS14;
  if (sampleId === 'S19') return SHEET_ANCHORS.irBuiltS19;
  const sample = PCA_SAMPLES.find((s) => s.id === sampleId);
  if (sample && sample.group === 'B') return SHEET_ANCHORS.irBuiltS14;
  return SHEET_ANCHORS.irBuiltS1;
}

const UPPER_LAYERS: LayerId[] = ['panels', 'axes', 'layers', 'svg'];

function atSheet(
  transforms: Record<LayerId, LayerTransform>,
  layer: LayerId,
  lx: number,
  lz: number,
  dy = 0.015,
): [number, number, number] {
  const t = transforms[layer];
  return [t.x + lx, t.y + dy, t.z + lz];
}

function midPoint(
  a: [number, number, number],
  b: [number, number, number],
  offset: [number, number, number] = [0, 0, 0],
): [number, number, number] {
  return [
    (a[0] + b[0]) * 0.5 + offset[0],
    (a[1] + b[1]) * 0.5 + offset[1],
    (a[2] + b[2]) * 0.5 + offset[2],
  ];
}

/**
 * Generates a sleek, low-profile architectural bus/arch curve between two coplanar anchors
 * in flat-tiled mode.
 * - Cross-row hops exit cleanly into the dedicated central horizontal corridor (z = laneZ in [-0.55, 0.55])
 *   at a low, distortion-free elevation (y ≈ BASE_STACK_Y + 0.34..0.52), glide horizontally along the open
 *   corridor, and sweep down into the target sheet—never projecting upward across Row 1 text.
 * - Same-row adjacent hops form crisp low bridges across the column gutter.
 */
function buildTiledArch(
  a: [number, number, number],
  b: [number, number, number],
  archHeight: number,
  laneZ = 0,
): [number, number, number][] {
  const baseY = Math.max(a[1], b[1]);
  const crossesCorridor = (a[2] < -0.5 && b[2] > 0.5) || (a[2] > 0.5 && b[2] < -0.5);

  if (crossesCorridor) {
    // Low-profile S-bus routed squarely through the central corridor between Row 1 and Row 2
    const corridorY = baseY + Math.min(0.46, Math.max(0.28, archHeight * 0.25));
    const entryX = a[0] + (b[0] - a[0]) * 0.12;
    const exitX = a[0] + (b[0] - a[0]) * 0.88;
    const p1: [number, number, number] = [entryX, corridorY, laneZ];
    const pMid: [number, number, number] = [
      (a[0] + b[0]) * 0.5,
      corridorY + 0.05,
      laneZ,
    ];
    const p2: [number, number, number] = [exitX, corridorY, laneZ];
    return [a, p1, pMid, p2, b];
  }

  // Same-row adjacent hop: ultra-sleek low bridge clearing the sheet edge & gutter without foreshortened occlusion
  const lowLift = Math.min(0.54, Math.max(0.3, archHeight * 0.34));
  const midZ = (a[2] + b[2]) * 0.5 + laneZ;
  const pMid: [number, number, number] = [
    (a[0] + b[0]) * 0.5,
    baseY + lowLift,
    midZ,
  ];
  return [a, pMid, b];
}

/**
 * Generates multi-layer coordinate meridians (经纬线) in stacked mode, OR clean
 * drafting-table compilation rails & panel bridges in flat-tiled mode (zero spaghetti clutter).
 */
export function computeMeridianGridLines(
  transforms: Record<LayerId, LayerTransform>,
  mode: MappingFocusMode,
  layoutMode: LayoutMode = 'stacked',
): MeridianLineDef[] {
  const lines: MeridianLineDef[] = [];
  const isGridFocus = mode === 'panel-grid';
  const isOverview = mode === 'overview';

  if (layoutMode === 'tiled') {
    const railY = BASE_STACK_Y + 0.012;
    const hw = PLATE_WIDTH / 2;
    const hd = PLATE_DEPTH / 2;

    // 1. Clean sequential compilation spine rails on the drafting table (01→02→03, corridor S-bend 03→04, 04→05→06)
    const railOpacity = isGridFocus ? 0.32 : 0.44;
    // Row 1 gutters: 01 -> 02 and 02 -> 03
    lines.push({
      points: [
        [transforms.code.x + hw + 0.06, railY, transforms.code.z],
        [transforms.ir.x - hw - 0.06, railY, transforms.ir.z],
      ],
      colorHex: '#2D603E',
      opacity: railOpacity,
      kind: 'frame',
    });
    lines.push({
      points: [
        [transforms.ir.x + hw + 0.06, railY, transforms.ir.z],
        [transforms.panels.x - hw - 0.06, railY, transforms.panels.z],
      ],
      colorHex: '#2D603E',
      opacity: railOpacity,
      kind: 'frame',
    });

    // Dedicated central corridor S-channel rail from 03 (Row 1 right) -> 04 (Row 2 left)
    lines.push({
      points: [
        [transforms.panels.x, railY, transforms.panels.z + hd + 0.08],
        [transforms.panels.x, railY, 0],
        [transforms.axes.x, railY, 0],
        [transforms.axes.x, railY, transforms.axes.z - hd - 0.08],
      ],
      colorHex: '#5A7665',
      opacity: railOpacity * 0.9,
      kind: 'frame',
    });

    // Row 2 gutters: 04 -> 05 and 05 -> 06
    lines.push({
      points: [
        [transforms.axes.x + hw + 0.06, railY, transforms.axes.z],
        [transforms.layers.x - hw - 0.06, railY, transforms.layers.z],
      ],
      colorHex: '#2D603E',
      opacity: railOpacity,
      kind: 'frame',
    });
    lines.push({
      points: [
        [transforms.layers.x + hw + 0.06, railY, transforms.layers.z],
        [transforms.svg.x - hw - 0.06, railY, transforms.svg.z],
      ],
      colorHex: '#DF6A2B',
      opacity: railOpacity,
      kind: 'frame',
    });

    // Subtle corridor baseline rails across the 3-column spread
    const corridorXLeft = transforms.code.x - hw - 0.4;
    const corridorXRight = transforms.panels.x + hw + 0.4;
    lines.push({
      points: [
        [corridorXLeft, railY, -0.58],
        [corridorXRight, railY, -0.58],
      ],
      colorHex: '#8EA295',
      opacity: 0.24,
      kind: 'axis-tick',
    });
    lines.push({
      points: [
        [corridorXLeft, railY, 0.58],
        [corridorXRight, railY, 0.58],
      ],
      colorHex: '#8EA295',
      opacity: 0.24,
      kind: 'axis-tick',
    });

    // 2. Clean elevated Panel P1 / P2 coordinate alignment arches across 03 panels -> 05 layers -> 06 svg
    const { p1, p2 } = getPanelSubRects();
    const p1Center = [(p1.minX + p1.maxX) * 0.5, (p1.minZ + p1.maxZ) * 0.5] as const;
    const p2Center = [(p2.minX + p2.maxX) * 0.5, (p2.minZ + p2.maxZ) * 0.5] as const;
    const panelOp = isGridFocus ? 0.66 : isOverview ? 0.13 : 0.07;

    const p1AtPanels = atSheet(transforms, 'panels', p1Center[0], p1Center[1], 0.02);
    const p1AtLayers = atSheet(transforms, 'layers', p1Center[0], p1Center[1], 0.02);
    const p1AtSvg = atSheet(transforms, 'svg', p1Center[0], p1Center[1], 0.02);

    lines.push({
      points: buildTiledArch(p1AtPanels, p1AtLayers, 1.35, -0.32),
      colorHex: '#2F855A',
      opacity: panelOp,
      kind: 'panel-p1',
    });
    lines.push({
      points: buildTiledArch(p1AtLayers, p1AtSvg, 1.1, -0.25),
      colorHex: '#2F855A',
      opacity: panelOp,
      kind: 'panel-p1',
    });

    const p2AtPanels = atSheet(transforms, 'panels', p2Center[0], p2Center[1], 0.02);
    const p2AtLayers = atSheet(transforms, 'layers', p2Center[0], p2Center[1], 0.02);
    const p2AtSvg = atSheet(transforms, 'svg', p2Center[0], p2Center[1], 0.02);

    lines.push({
      points: buildTiledArch(p2AtPanels, p2AtLayers, 1.6, 0.28),
      colorHex: '#DF6A2B',
      opacity: panelOp,
      kind: 'panel-p2',
    });
    lines.push({
      points: buildTiledArch(p2AtLayers, p2AtSvg, 1.32, 0.25),
      colorHex: '#DF6A2B',
      opacity: panelOp,
      kind: 'panel-p2',
    });

    // In panel-grid focus, add crisp P1/P2 top-bottom corner registration bridges from 03 panels directly to 06 svg
    if (isGridFocus) {
      const p1TopPanels = atSheet(transforms, 'panels', p1.minX, p1.minZ, 0.02);
      const p1TopSvg = atSheet(transforms, 'svg', p1.minX, p1.minZ, 0.02);
      const p2BotPanels = atSheet(transforms, 'panels', p2.maxX, p2.maxZ, 0.02);
      const p2BotSvg = atSheet(transforms, 'svg', p2.maxX, p2.maxZ, 0.02);
      lines.push({
        points: buildTiledArch(p1TopPanels, p1TopSvg, 2.05, -0.45),
        colorHex: '#2F855A',
        opacity: 0.58,
        kind: 'panel-p1',
      });
      lines.push({
        points: buildTiledArch(p2BotPanels, p2BotSvg, 2.15, 0.45),
        colorHex: '#DF6A2B',
        opacity: 0.58,
        kind: 'panel-p2',
      });
    }

    return lines;
  }

  // Stacked 3D mode: continuous vertical coordinate meridians (经纬线)
  const hw = PLATE_WIDTH / 2 - 0.14;
  const hd = PLATE_DEPTH / 2 - 0.14;
  const outerCorners: [number, number][] = [
    [-hw, -hd],
    [hw, -hd],
    [-hw, hd],
    [hw, hd],
  ];
  for (const [cx, cz] of outerCorners) {
    lines.push({
      points: LAYER_ORDER.map((id) => atSheet(transforms, id, cx, cz, 0.005)),
      colorHex: '#6F8476',
      opacity: isGridFocus ? 0.36 : 0.2,
      kind: 'frame',
    });
  }

  const { p1, p2 } = getPanelSubRects();
  const p1Corners: [number, number][] = [
    [p1.minX, p1.minZ],
    [p1.maxX, p1.minZ],
    [p1.minX, p1.maxZ],
    [p1.maxX, p1.maxZ],
  ];
  const p2Corners: [number, number][] = [
    [p2.minX, p2.minZ],
    [p2.maxX, p2.minZ],
    [p2.minX, p2.maxZ],
    [p2.maxX, p2.maxZ],
  ];

  const panelOpacity = isGridFocus ? 0.78 : isOverview ? 0.36 : 0.16;
  for (const [px, pz] of p1Corners) {
    lines.push({
      points: UPPER_LAYERS.map((id) => atSheet(transforms, id, px, pz, 0.008)),
      colorHex: '#2F855A',
      opacity: panelOpacity,
      kind: 'panel-p1',
    });
  }
  for (const [px, pz] of p2Corners) {
    lines.push({
      points: UPPER_LAYERS.map((id) => atSheet(transforms, id, px, pz, 0.008)),
      colorHex: '#DF6A2B',
      opacity: panelOpacity,
      kind: 'panel-p2',
    });
  }

  const tickOpacity = isGridFocus ? 0.62 : isOverview ? 0.24 : 0.1;
  for (const tick of [-5, 0, 5]) {
    const xPt = mapDataToPlateLocal(tick, -10);
    lines.push({
      points: UPPER_LAYERS.map((id) =>
        atSheet(transforms, id, xPt.x, PLOT_LOCAL_BOUNDS.maxZ, 0.006),
      ),
      colorHex: '#2D603E',
      opacity: tickOpacity,
      kind: 'axis-tick',
    });
    const yPt = mapDataToPlateLocal(-10, tick);
    lines.push({
      points: UPPER_LAYERS.map((id) =>
        atSheet(transforms, id, PLOT_LOCAL_BOUNDS.minX, yPt.z, 0.006),
      ),
      colorHex: '#2D603E',
      opacity: tickOpacity,
      kind: 'axis-tick',
    });
  }

  return lines;
}

/**
 * Generates semantic Source-Map splines with automatic height-tiered parabolic arches
 * in flat-tiled mode (preventing sheet intersections and keeping parallel flows cleanly separated).
 */
export function computeMappingPaths(
  mode: MappingFocusMode,
  tracedSampleId: string | null,
  transforms: Record<LayerId, LayerTransform>,
  layoutMode: LayoutMode = 'stacked',
): MappingCurveDef[] {
  const curves: MappingCurveDef[] = [];
  const isTiled = layoutMode === 'tiled';

  const isOverview = mode === 'overview';
  const isPointFocus = mode === 'point-lineage' || tracedSampleId !== null;
  const isScaleFocus = mode === 'scale-color';
  const isGridFocus = mode === 'panel-grid';
  const isAssetFocus = mode === 'asset-export';

  const assetCards = getAssetCardTransforms(layoutMode);

  const addSampleChain = (
    sampleId: string,
    emphasized: boolean,
    opacity: number,
  ) => {
    const sample = PCA_SAMPLES.find((s) => s.id === sampleId);
    if (!sample) return;
    const rawA = getSampleRawAnchor(sample.id);
    const builtA = getSampleBuiltAnchor(sample.id);
    const pt = mapDataToPlateLocal(sample.pc1, sample.pc2);

    const pCode = atSheet(transforms, 'code', rawA.x, rawA.z, 0.025);
    const pIr = atSheet(transforms, 'ir', builtA.x, builtA.z, 0.025);
    const pPanels = atSheet(transforms, 'panels', pt.x, pt.z, 0.025);
    const pAxes = atSheet(transforms, 'axes', pt.x, pt.z, 0.025);
    const pLayers = atSheet(transforms, 'layers', pt.x, pt.z, 0.025);
    const pSvg = atSheet(transforms, 'svg', pt.x, pt.z, 0.025);

    if (isTiled) {
      // Distinct elevation & corridor lanes for Group A vs Group B so dual traces never collide
      const laneBias = sample.group === 'A' ? -0.34 : 0.34;
      const heightBias = sample.group === 'A' ? 0 : 0.28;

      // Hop 1: 01 code -> 02 ir (clean low arch across Row 1 left gutter)
      curves.push({
        id: `tiled-pt-12-${sample.id}`,
        category: 'point',
        colorHex: sample.colorHex,
        points: buildTiledArch(pCode, pIr, 1.05 + heightBias, laneBias * 0.45),
        emphasized,
        opacity,
        flowSpeed: emphasized ? 0.44 : 0.3,
        anchorNodes: [pCode, pIr],
      });

      // Hop 2: 02 ir -> 03 panels (clean arch across Row 1 right gutter)
      curves.push({
        id: `tiled-pt-23-${sample.id}`,
        category: 'point',
        colorHex: sample.colorHex,
        points: buildTiledArch(pIr, pPanels, 1.15 + heightBias, laneBias * 0.45),
        emphasized,
        opacity,
        flowSpeed: emphasized ? 0.44 : 0.3,
        anchorNodes: [pPanels],
      });

      // Hop 3: 03 panels -> 04 axes (graceful central-corridor cross-row bridge)
      curves.push({
        id: `tiled-pt-34-${sample.id}`,
        category: 'point',
        colorHex: sample.colorHex,
        points: buildTiledArch(pPanels, pAxes, 1.65 + heightBias, laneBias),
        emphasized,
        opacity,
        flowSpeed: emphasized ? 0.36 : 0.24,
        anchorNodes: [pAxes],
      });

      // Hop 4: 04 axes -> 05 layers (clean arch across Row 2 left gutter)
      curves.push({
        id: `tiled-pt-45-${sample.id}`,
        category: 'point',
        colorHex: sample.colorHex,
        points: buildTiledArch(pAxes, pLayers, 1.08 + heightBias, laneBias * 0.45),
        emphasized,
        opacity,
        flowSpeed: emphasized ? 0.44 : 0.3,
        anchorNodes: [pLayers],
      });

      // Hop 5: 05 layers -> 06 svg (clean arch across Row 2 right gutter)
      curves.push({
        id: `tiled-pt-56-${sample.id}`,
        category: 'point',
        colorHex: sample.colorHex,
        points: buildTiledArch(pLayers, pSvg, 1.15 + heightBias, laneBias * 0.45),
        emphasized,
        opacity,
        flowSpeed: emphasized ? 0.44 : 0.3,
        anchorNodes: [pSvg],
      });
      return;
    }

    curves.push({
      id: `point-lower-${sample.id}`,
      category: 'point',
      colorHex: sample.colorHex,
      points: [pCode, midPoint(pCode, pIr), pIr, midPoint(pIr, pPanels), pPanels],
      emphasized,
      opacity,
      flowSpeed: emphasized ? 0.32 : 0.22,
      anchorNodes: [pCode, pIr, pPanels],
    });

    curves.push({
      id: `point-upper-${sample.id}`,
      category: 'point',
      colorHex: sample.colorHex,
      points: [pPanels, pAxes, pLayers, pSvg],
      emphasized,
      opacity,
      flowSpeed: emphasized ? 0.36 : 0.24,
      anchorNodes: [pAxes, pLayers, pSvg],
    });
  };

  // 1. Data Semantic Chain (样本行 -> built 表 -> SVG 图元) or Clean Edge-to-Edge Tiled Overview Spine
  if (tracedSampleId) {
    addSampleChain(tracedSampleId, true, 0.94);
    if (isOverview && !isTiled) {
      const companion = tracedSampleId === 'S1' ? 'S14' : 'S1';
      addSampleChain(companion, false, 0.22);
    }
  } else if (mode === 'point-lineage') {
    addSampleChain('S1', true, 0.94);
    addSampleChain('S14', true, 0.94);
  } else if (isOverview) {
    if (isTiled) {
      // Ultra-clean edge-to-edge compilation spine across gutters + open central corridor (zero text occlusion!)
      const hw = PLATE_WIDTH / 2 - 0.08;
      const hd = PLATE_DEPTH / 2 - 0.08;
      const eCodeR = atSheet(transforms, 'code', hw, 0, 0.025);
      const eIrL = atSheet(transforms, 'ir', -hw, 0, 0.025);
      const eIrR = atSheet(transforms, 'ir', hw, 0, 0.025);
      const ePanelsL = atSheet(transforms, 'panels', -hw, 0, 0.025);
      const ePanelsBot = atSheet(transforms, 'panels', 0, hd, 0.025);
      const eAxesTop = atSheet(transforms, 'axes', 0, -hd, 0.025);
      const eAxesR = atSheet(transforms, 'axes', hw, 0, 0.025);
      const eLayersL = atSheet(transforms, 'layers', -hw, 0, 0.025);
      const eLayersR = atSheet(transforms, 'layers', hw, 0, 0.025);
      const eSvgL = atSheet(transforms, 'svg', -hw, 0, 0.025);

      curves.push({
        id: 'tiled-spine-01-02',
        category: 'point',
        colorHex: '#2F855A',
        points: buildTiledArch(eCodeR, eIrL, 0.9, 0),
        emphasized: false,
        opacity: 0.72,
        flowSpeed: 0.42,
        anchorNodes: [eCodeR, eIrL],
      });
      curves.push({
        id: 'tiled-spine-02-03',
        category: 'point',
        colorHex: '#2F855A',
        points: buildTiledArch(eIrR, ePanelsL, 0.9, 0),
        emphasized: false,
        opacity: 0.72,
        flowSpeed: 0.42,
        anchorNodes: [eIrR, ePanelsL],
      });
      // Smooth central-corridor sweep strictly inside z = 0 open channel between Row 1 and Row 2
      curves.push({
        id: 'tiled-spine-03-04',
        category: 'panel',
        colorHex: '#356D4A',
        points: [
          ePanelsBot,
          [ePanelsBot[0] - 0.6, BASE_STACK_Y + 0.34, 0],
          [0, BASE_STACK_Y + 0.38, 0],
          [eAxesTop[0] + 0.6, BASE_STACK_Y + 0.34, 0],
          eAxesTop,
        ],
        emphasized: false,
        opacity: 0.68,
        flowSpeed: 0.24,
        anchorNodes: [ePanelsBot, eAxesTop],
      });
      curves.push({
        id: 'tiled-spine-04-05',
        category: 'scale',
        colorHex: '#DF6A2B',
        points: buildTiledArch(eAxesR, eLayersL, 0.9, 0),
        emphasized: false,
        opacity: 0.72,
        flowSpeed: 0.42,
        anchorNodes: [eAxesR, eLayersL],
      });
      curves.push({
        id: 'tiled-spine-05-06',
        category: 'scale',
        colorHex: '#DF6A2B',
        points: buildTiledArch(eLayersR, eSvgL, 0.9, 0),
        emphasized: false,
        opacity: 0.72,
        flowSpeed: 0.42,
        anchorNodes: [eLayersR, eSvgL],
      });
    } else {
      addSampleChain('S1', false, 0.66);
      addSampleChain('S14', false, 0.66);
    }
  }

  // 2. Visual Addressing Chain dedicated flows in panel-grid mode (L004 / L005 lock + guide-box slot)
  if (isGridFocus) {
    const pLeg4 = atSheet(
      transforms,
      'axes',
      SHEET_ANCHORS.legendGroupA.x,
      SHEET_ANCHORS.legendGroupA.z,
      0.025,
    );
    const pLeg6 = atSheet(
      transforms,
      'svg',
      SHEET_ANCHORS.legendGroupA.x,
      SHEET_ANCHORS.legendGroupA.z,
      0.025,
    );
    const pClusterA3 = atSheet(
      transforms,
      'panels',
      SHEET_ANCHORS.clusterA.x,
      SHEET_ANCHORS.clusterA.z,
      0.025,
    );
    const pClusterA5 = atSheet(
      transforms,
      'layers',
      SHEET_ANCHORS.clusterA.x,
      SHEET_ANCHORS.clusterA.z,
      0.025,
    );
    const pClusterA6 = atSheet(
      transforms,
      'svg',
      SHEET_ANCHORS.clusterA.x,
      SHEET_ANCHORS.clusterA.z,
      0.025,
    );
    const pClusterB3 = atSheet(
      transforms,
      'panels',
      SHEET_ANCHORS.clusterB.x,
      SHEET_ANCHORS.clusterB.z,
      0.025,
    );
    const pClusterB5 = atSheet(
      transforms,
      'layers',
      SHEET_ANCHORS.clusterB.x,
      SHEET_ANCHORS.clusterB.z,
      0.025,
    );
    const pClusterB6 = atSheet(
      transforms,
      'svg',
      SHEET_ANCHORS.clusterB.x,
      SHEET_ANCHORS.clusterB.z,
      0.025,
    );

    if (isTiled) {
      curves.push({
        id: 'tiled-panel-l004-a',
        category: 'panel',
        colorHex: '#2F855A',
        points: buildTiledArch(pClusterA3, pClusterA5, 1.45, -0.36),
        emphasized: true,
        opacity: 0.92,
        flowSpeed: 0.38,
        anchorNodes: [pClusterA3, pClusterA5],
      });
      curves.push({
        id: 'tiled-panel-l004-b',
        category: 'panel',
        colorHex: '#2F855A',
        points: buildTiledArch(pClusterA5, pClusterA6, 1.15, -0.22),
        emphasized: true,
        opacity: 0.92,
        flowSpeed: 0.42,
        anchorNodes: [pClusterA6],
      });
      curves.push({
        id: 'tiled-panel-l005-a',
        category: 'panel',
        colorHex: '#DF6A2B',
        points: buildTiledArch(pClusterB3, pClusterB5, 1.75, 0.34),
        emphasized: true,
        opacity: 0.92,
        flowSpeed: 0.38,
        anchorNodes: [pClusterB3, pClusterB5],
      });
      curves.push({
        id: 'tiled-panel-l005-b',
        category: 'panel',
        colorHex: '#DF6A2B',
        points: buildTiledArch(pClusterB5, pClusterB6, 1.38, 0.22),
        emphasized: true,
        opacity: 0.92,
        flowSpeed: 0.42,
        anchorNodes: [pClusterB6],
      });
      // Guide-box safety-slot bus sweeping cleanly along the front corridor BELOW Row 2 (04 axes -> 06 svg)
      const frontBusZ = transforms.svg.z + PLATE_DEPTH * 0.5 + 0.55;
      curves.push({
        id: 'tiled-panel-guide-slot',
        category: 'panel',
        colorHex: '#C45720',
        points: [
          pLeg4,
          [pLeg4[0] + 0.85, BASE_STACK_Y + 0.34, frontBusZ],
          [(pLeg4[0] + pLeg6[0]) * 0.5, BASE_STACK_Y + 0.38, frontBusZ],
          [pLeg6[0] - 0.85, BASE_STACK_Y + 0.34, frontBusZ],
          pLeg6,
        ],
        emphasized: true,
        opacity: 0.94,
        flowSpeed: 0.32,
        anchorNodes: [pLeg4, pLeg6],
      });
    } else {
      curves.push({
        id: 'panel-leaf-l004',
        category: 'panel',
        colorHex: '#2F855A',
        points: [pClusterA3, pClusterA5, pClusterA6],
        emphasized: true,
        opacity: 0.9,
        flowSpeed: 0.34,
        anchorNodes: [pClusterA3, pClusterA5, pClusterA6],
      });
      curves.push({
        id: 'panel-leaf-l005',
        category: 'panel',
        colorHex: '#DF6A2B',
        points: [pClusterB3, pClusterB5, pClusterB6],
        emphasized: true,
        opacity: 0.9,
        flowSpeed: 0.34,
        anchorNodes: [pClusterB3, pClusterB5, pClusterB6],
      });
      curves.push({
        id: 'panel-guide-slot',
        category: 'panel',
        colorHex: '#C45720',
        points: [pLeg4, midPoint(pLeg4, pLeg6, [0.15, 0, 0]), pLeg6],
        emphasized: true,
        opacity: 0.92,
        flowSpeed: 0.38,
        anchorNodes: [pLeg4, pLeg6],
      });
    }
  }

  // 3. Scale & Color Dictionary Chains
  const scaleOpacity = isScaleFocus
    ? 0.96
    : isOverview
      ? isTiled
        ? 0.72
        : 0.62
      : isPointFocus
        ? 0.12
        : 0.14;

  const pCodeAes = atSheet(
    transforms,
    'code',
    SHEET_ANCHORS.codeAesColour.x,
    SHEET_ANCHORS.codeAesColour.z,
    0.025,
  );
  const pIrScaleA = atSheet(
    transforms,
    'ir',
    SHEET_ANCHORS.irScaleA.x,
    SHEET_ANCHORS.irScaleA.z,
    0.025,
  );
  const pIrScaleB = atSheet(
    transforms,
    'ir',
    SHEET_ANCHORS.irScaleB.x,
    SHEET_ANCHORS.irScaleB.z,
    0.025,
  );
  const pLegendA4 = atSheet(
    transforms,
    'axes',
    SHEET_ANCHORS.legendGroupA.x,
    SHEET_ANCHORS.legendGroupA.z,
    0.025,
  );
  const pLegendA6 = atSheet(
    transforms,
    'svg',
    SHEET_ANCHORS.legendGroupA.x,
    SHEET_ANCHORS.legendGroupA.z,
    0.025,
  );
  const pLegendB4 = atSheet(
    transforms,
    'axes',
    SHEET_ANCHORS.legendGroupB.x,
    SHEET_ANCHORS.legendGroupB.z,
    0.025,
  );
  const pLegendB6 = atSheet(
    transforms,
    'svg',
    SHEET_ANCHORS.legendGroupB.x,
    SHEET_ANCHORS.legendGroupB.z,
    0.025,
  );

  if (isTiled) {
    // Only draw tiled scale-color arcs in scale-color focus so overview & other focused modes stay clutter-free
    if (isScaleFocus) {
      curves.push({
        id: 'tiled-scale-code-ir-a',
        category: 'scale',
        colorHex: '#2F855A',
        points: buildTiledArch(pCodeAes, pIrScaleA, 1.35, -0.55),
        emphasized: isScaleFocus,
        opacity: scaleOpacity,
        flowSpeed: isScaleFocus ? 0.42 : 0.25,
        anchorNodes: [pCodeAes, pIrScaleA],
      });

      curves.push({
        id: 'tiled-scale-code-ir-b',
        category: 'scale',
        colorHex: '#DF6A2B',
        points: buildTiledArch(pCodeAes, pIrScaleB, 1.65, 0.35),
        emphasized: isScaleFocus,
        opacity: scaleOpacity,
        flowSpeed: isScaleFocus ? 0.42 : 0.25,
        anchorNodes: [pIrScaleB],
      });

      // IR Scale -> Legend on 04 axes (through corridor) and -> Legend on 06 svg
      curves.push({
        id: 'tiled-scale-a-legend4',
        category: 'scale',
        colorHex: '#2F855A',
        points: buildTiledArch(pIrScaleA, pLegendA4, 1.5, -0.42),
        emphasized: isScaleFocus,
        opacity: scaleOpacity,
        flowSpeed: isScaleFocus ? 0.38 : 0.24,
        anchorNodes: [pLegendA4],
      });
      curves.push({
        id: 'tiled-scale-b-legend6',
        category: 'scale',
        colorHex: '#DF6A2B',
        points: buildTiledArch(pIrScaleB, pLegendB6, 2.05, 0.42),
        emphasized: isScaleFocus,
        opacity: scaleOpacity,
        flowSpeed: isScaleFocus ? 0.36 : 0.22,
        anchorNodes: [pLegendB6],
      });
    }

    if (isScaleFocus) {
      const pClusterA5 = atSheet(
        transforms,
        'layers',
        SHEET_ANCHORS.clusterA.x,
        SHEET_ANCHORS.clusterA.z,
        0.025,
      );
      const pClusterA6 = atSheet(
        transforms,
        'svg',
        SHEET_ANCHORS.clusterA.x,
        SHEET_ANCHORS.clusterA.z,
        0.025,
      );
      const pClusterB5 = atSheet(
        transforms,
        'layers',
        SHEET_ANCHORS.clusterB.x,
        SHEET_ANCHORS.clusterB.z,
        0.025,
      );
      const pClusterB6 = atSheet(
        transforms,
        'svg',
        SHEET_ANCHORS.clusterB.x,
        SHEET_ANCHORS.clusterB.z,
        0.025,
      );

      curves.push({
        id: 'tiled-scale-a-cluster',
        category: 'scale',
        colorHex: '#2F855A',
        points: buildTiledArch(pIrScaleA, pClusterA5, 1.4, -0.18),
        emphasized: true,
        opacity: 0.94,
        flowSpeed: 0.4,
        anchorNodes: [pClusterA5],
      });
      curves.push({
        id: 'tiled-scale-a-cluster-svg',
        category: 'scale',
        colorHex: '#2F855A',
        points: buildTiledArch(pClusterA5, pClusterA6, 1.15, -0.25),
        emphasized: true,
        opacity: 0.92,
        flowSpeed: 0.44,
        anchorNodes: [pClusterA6],
      });
      curves.push({
        id: 'tiled-scale-b-cluster',
        category: 'scale',
        colorHex: '#DF6A2B',
        points: buildTiledArch(pIrScaleB, pClusterB5, 1.7, 0.18),
        emphasized: true,
        opacity: 0.94,
        flowSpeed: 0.4,
        anchorNodes: [pClusterB5],
      });
      curves.push({
        id: 'tiled-scale-b-cluster-svg',
        category: 'scale',
        colorHex: '#DF6A2B',
        points: buildTiledArch(pClusterB5, pClusterB6, 1.4, 0.25),
        emphasized: true,
        opacity: 0.92,
        flowSpeed: 0.44,
        anchorNodes: [pClusterB6],
      });
      // Legend 04 -> Legend 06 sweep cleanly along the front corridor BELOW 05 Layers
      const scaleFrontZ = transforms.svg.z + PLATE_DEPTH * 0.5 + 0.55;
      curves.push({
        id: 'tiled-scale-legend-sync',
        category: 'scale',
        colorHex: '#2F855A',
        points: [
          pLegendA4,
          [pLegendA4[0] + 0.85, BASE_STACK_Y + 0.34, scaleFrontZ],
          [(pLegendA4[0] + pLegendA6[0]) * 0.5, BASE_STACK_Y + 0.38, scaleFrontZ],
          [pLegendA6[0] - 0.85, BASE_STACK_Y + 0.34, scaleFrontZ],
          pLegendA6,
        ],
        emphasized: true,
        opacity: 0.9,
        flowSpeed: 0.32,
        anchorNodes: [pLegendA6],
      });
    }
  } else {
    curves.push({
      id: 'scale-code-to-ir-a',
      category: 'scale',
      colorHex: '#2F855A',
      points: [pCodeAes, midPoint(pCodeAes, pIrScaleA, [0, 0, -0.05]), pIrScaleA],
      emphasized: isScaleFocus,
      opacity: scaleOpacity,
      flowSpeed: isScaleFocus ? 0.36 : 0.2,
      anchorNodes: [pCodeAes, pIrScaleA],
    });

    curves.push({
      id: 'scale-code-to-ir-b',
      category: 'scale',
      colorHex: '#DF6A2B',
      points: [pCodeAes, midPoint(pCodeAes, pIrScaleB, [0, 0, 0.08]), pIrScaleB],
      emphasized: isScaleFocus,
      opacity: scaleOpacity,
      flowSpeed: isScaleFocus ? 0.36 : 0.2,
      anchorNodes: [pIrScaleB],
    });

    curves.push({
      id: 'scale-a-to-legend',
      category: 'scale',
      colorHex: '#2F855A',
      points: [
        pIrScaleA,
        midPoint(pIrScaleA, pLegendA4, [0.3, 0.05, -0.18]),
        pLegendA4,
        pLegendA6,
      ],
      emphasized: isScaleFocus,
      opacity: scaleOpacity,
      flowSpeed: isScaleFocus ? 0.32 : 0.18,
      anchorNodes: [pLegendA4, pLegendA6],
    });

    curves.push({
      id: 'scale-b-to-legend',
      category: 'scale',
      colorHex: '#DF6A2B',
      points: [
        pIrScaleB,
        midPoint(pIrScaleB, pLegendB4, [0.35, 0.05, -0.08]),
        pLegendB4,
        pLegendB6,
      ],
      emphasized: isScaleFocus,
      opacity: scaleOpacity,
      flowSpeed: isScaleFocus ? 0.32 : 0.18,
      anchorNodes: [pLegendB4, pLegendB6],
    });

    if (isScaleFocus) {
      const pClusterA5 = atSheet(
        transforms,
        'layers',
        SHEET_ANCHORS.clusterA.x,
        SHEET_ANCHORS.clusterA.z,
      );
      const pClusterA6 = atSheet(
        transforms,
        'svg',
        SHEET_ANCHORS.clusterA.x,
        SHEET_ANCHORS.clusterA.z,
      );
      const pClusterB5 = atSheet(
        transforms,
        'layers',
        SHEET_ANCHORS.clusterB.x,
        SHEET_ANCHORS.clusterB.z,
      );
      const pClusterB6 = atSheet(
        transforms,
        'svg',
        SHEET_ANCHORS.clusterB.x,
        SHEET_ANCHORS.clusterB.z,
      );

      curves.push({
        id: 'scale-a-to-cluster',
        category: 'scale',
        colorHex: '#2F855A',
        points: [
          pIrScaleA,
          midPoint(pIrScaleA, pClusterA5, [-0.15, 0.05, 0.12]),
          pClusterA5,
          pClusterA6,
        ],
        emphasized: true,
        opacity: 0.92,
        flowSpeed: 0.34,
        anchorNodes: [pClusterA5],
      });
      curves.push({
        id: 'scale-b-to-cluster',
        category: 'scale',
        colorHex: '#DF6A2B',
        points: [
          pIrScaleB,
          midPoint(pIrScaleB, pClusterB5, [0.1, 0.05, -0.08]),
          pClusterB5,
          pClusterB6,
        ],
        emphasized: true,
        opacity: 0.92,
        flowSpeed: 0.34,
        anchorNodes: [pClusterB5],
      });
    }
  }

  // 4. Open Asset Integrity, Companion .gloss.work/ & Dual-Track Streams
  const assetOpacity = isAssetFocus ? 0.96 : isOverview ? (isTiled ? 0.78 : 0.56) : 0.16;
  const mapTarget = assetCards['asset-map'];
  const bundleTarget = assetCards['asset-bundle'];
  const workTarget = assetCards['asset-work'];

  if (isTiled) {
    // Only render right-wing export streams in overview (clean edge bridges) or asset-export focus (full dual-track topology)
    if (isOverview || isAssetFocus) {
      const pPanelsRight = atSheet(transforms, 'panels', PLATE_WIDTH / 2 - 0.08, 0, 0.025);
      const pIrTop = atSheet(transforms, 'ir', 0.4, -PLATE_DEPTH / 2 + 0.12, 0.025);
      const pSvgRight = atSheet(transforms, 'svg', PLATE_WIDTH / 2 - 0.08, 0, 0.025);
      const pCodeBot = atSheet(transforms, 'code', 1.4, -PLATE_DEPTH / 2 + 0.12, 0.025);
      const pCodeFront = atSheet(transforms, 'code', -0.4, PLATE_DEPTH / 2 - 0.12, 0.025);

      const mapInLeft: [number, number, number] = [
        mapTarget.x - 1.32,
        mapTarget.y + 0.04,
        mapTarget.z - 0.12,
      ];
      const mapInTop: [number, number, number] = [
        mapTarget.x - 1.32,
        mapTarget.y + 0.04,
        mapTarget.z + 0.35,
      ];
      const bundleInLeft: [number, number, number] = [
        bundleTarget.x - 1.32,
        bundleTarget.y + 0.04,
        bundleTarget.z + 0.12,
      ];
      const bundleInTop: [number, number, number] = [
        bundleTarget.x - 1.32,
        bundleTarget.y + 0.04,
        bundleTarget.z - 0.32,
      ];
      const bundleOutBot: [number, number, number] = [
        bundleTarget.x,
        bundleTarget.y + 0.04,
        bundleTarget.z + 0.96,
      ];
      const workInTop: [number, number, number] = [
        workTarget.x,
        workTarget.y + 0.04,
        workTarget.z - 0.96,
      ];
      const workOutLeft: [number, number, number] = [
        workTarget.x - 1.32,
        workTarget.y + 0.04,
        workTarget.z + 0.2,
      ];

      // 03 panels -> Asset Map (clean short right-gutter bridge)
      curves.push({
        id: 'tiled-export-panels-map',
        category: 'asset',
        colorHex: '#DF6A2B',
        points: buildTiledArch(pPanelsRight, mapInLeft, 0.95, -0.05),
        emphasized: isAssetFocus,
        opacity: isAssetFocus ? 0.94 : 0.72,
        flowSpeed: isAssetFocus ? 0.42 : 0.28,
        anchorNodes: [pPanelsRight],
      });

      // 06 SVG -> Asset Bundle (clean short right-gutter bridge)
      curves.push({
        id: 'tiled-export-svg-bundle',
        category: 'asset',
        colorHex: '#2D603E',
        points: buildTiledArch(pSvgRight, bundleInLeft, 0.95, 0.05),
        emphasized: isAssetFocus,
        opacity: isAssetFocus ? 0.94 : 0.72,
        flowSpeed: isAssetFocus ? 0.42 : 0.28,
        anchorNodes: [pSvgRight],
      });

      // Track A: Immutable Asset Bundle (.gloss/) -> Companion Workspace (.gloss.work/)
      curves.push({
        id: 'tiled-export-bundle-work',
        category: 'asset',
        colorHex: '#315C6B',
        points: buildTiledArch(bundleOutBot, workInTop, 0.95, 0),
        emphasized: isAssetFocus,
        opacity: isAssetFocus ? 0.95 : 0.74,
        flowSpeed: isAssetFocus ? 0.44 : 0.26,
        anchorNodes: [bundleOutBot, workInTop],
      });

      if (isAssetFocus) {
        // 02 IR -> Asset Map along sleek back perimeter rail (never cuts across 03 panels text)
        const backRailZ = transforms.panels.z - PLATE_DEPTH * 0.5 - 0.62;
        curves.push({
          id: 'tiled-export-ir-map',
          category: 'asset',
          colorHex: '#DF6A2B',
          points: [
            pIrTop,
            [transforms.ir.x + 1.8, BASE_STACK_Y + 0.36, backRailZ],
            [transforms.panels.x + PLATE_WIDTH * 0.42, BASE_STACK_Y + 0.36, backRailZ],
            mapInLeft,
          ],
          emphasized: true,
          opacity: 0.92,
          flowSpeed: 0.32,
          anchorNodes: [pIrTop],
        });

        // 06 SVG -> Asset Map
        curves.push({
          id: 'tiled-export-svg-map',
          category: 'asset',
          colorHex: '#DF6A2B',
          points: buildTiledArch(pSvgRight, mapInTop, 1.0, 0.1),
          emphasized: true,
          opacity: 0.9,
          flowSpeed: 0.36,
          anchorNodes: [pSvgRight],
        });

        // 01 Code & raw.csv -> Asset Bundle via clean outer back-and-right perimeter bus
        const outerBackZ = transforms.ir.z - PLATE_DEPTH * 0.5 - 0.95;
        curves.push({
          id: 'tiled-export-code-bundle',
          category: 'asset',
          colorHex: '#2D603E',
          points: [
            pCodeBot,
            [transforms.ir.x, BASE_STACK_Y + 0.38, outerBackZ],
            [transforms.panels.x + PLATE_WIDTH * 0.58, BASE_STACK_Y + 0.38, outerBackZ * 0.4],
            bundleInTop,
          ],
          emphasized: true,
          opacity: 0.9,
          flowSpeed: 0.26,
          anchorNodes: [pCodeBot],
        });

        // Track B: Recomputation feedback (.gloss.work/ recompute_requested -> Layer 01 Code via outer front rail)
        const frontRailZ = transforms.svg.z + PLATE_DEPTH * 0.5 + 0.78;
        curves.push({
          id: 'tiled-track-b-recompute',
          category: 'asset',
          colorHex: '#315C6B',
          points: [
            workOutLeft,
            [transforms.layers.x, BASE_STACK_Y + 0.34, frontRailZ],
            [transforms.code.x - PLATE_WIDTH * 0.38, BASE_STACK_Y + 0.34, frontRailZ * 0.3],
            pCodeFront,
          ],
          emphasized: false,
          opacity: 0.72,
          dashed: true,
          flowSpeed: 0.22,
          anchorNodes: [workOutLeft, pCodeFront],
        });
      }
    }
  } else {
    const pIrRight = atSheet(
      transforms,
      'ir',
      SHEET_ANCHORS.irExportRight.x,
      SHEET_ANCHORS.irExportRight.z,
    );
    const pSvgRight = atSheet(transforms, 'svg', PLATE_WIDTH / 2 - 0.12, -0.55);
    const pCodeRight = atSheet(
      transforms,
      'code',
      SHEET_ANCHORS.codeSourcesRight.x,
      SHEET_ANCHORS.codeSourcesRight.z,
    );
    const pLayersRight = atSheet(transforms, 'layers', PLATE_WIDTH / 2 - 0.12, 0.52);

    const mapInMid: [number, number, number] = [
      mapTarget.x - 0.98,
      mapTarget.y,
      mapTarget.z,
    ];
    const mapInTop: [number, number, number] = [
      mapTarget.x - 0.98,
      mapTarget.y + 0.24,
      mapTarget.z,
    ];
    const bundleInBot: [number, number, number] = [
      bundleTarget.x - 0.98,
      bundleTarget.y - 0.12,
      bundleTarget.z,
    ];
    const bundleInTop: [number, number, number] = [
      bundleTarget.x - 0.98,
      bundleTarget.y + 0.22,
      bundleTarget.z,
    ];
    const bundleOutWork: [number, number, number] = [
      bundleTarget.x - 0.12,
      bundleTarget.y - 0.78,
      bundleTarget.z + 0.16,
    ];
    const workInTop: [number, number, number] = [
      workTarget.x - 0.12,
      workTarget.y + 0.78,
      workTarget.z - 0.16,
    ];
    const workOutLeft: [number, number, number] = [
      workTarget.x - 0.98,
      workTarget.y - 0.08,
      workTarget.z + 0.12,
    ];

    curves.push({
      id: 'export-ir-to-map',
      category: 'asset',
      colorHex: '#DF6A2B',
      points: [pIrRight, midPoint(pIrRight, mapInMid, [0.35, 0.2, 0]), mapInMid],
      emphasized: isAssetFocus,
      opacity: assetOpacity,
      flowSpeed: isAssetFocus ? 0.36 : 0.2,
      anchorNodes: [pIrRight],
    });

    curves.push({
      id: 'export-svg-to-map',
      category: 'asset',
      colorHex: '#DF6A2B',
      points: [pSvgRight, midPoint(pSvgRight, mapInTop, [0.35, 0.15, 0]), mapInTop],
      emphasized: isAssetFocus,
      opacity: assetOpacity,
      flowSpeed: isAssetFocus ? 0.34 : 0.19,
      anchorNodes: [pSvgRight],
    });

    curves.push({
      id: 'export-code-to-bundle',
      category: 'asset',
      colorHex: '#2D603E',
      points: [
        pCodeRight,
        midPoint(pCodeRight, bundleInBot, [0.35, -0.08, 0]),
        bundleInBot,
      ],
      emphasized: isAssetFocus,
      opacity: assetOpacity,
      flowSpeed: isAssetFocus ? 0.34 : 0.19,
      anchorNodes: [pCodeRight],
    });

    curves.push({
      id: 'export-svg-to-bundle',
      category: 'asset',
      colorHex: '#2D603E',
      points: [
        pLayersRight,
        midPoint(pLayersRight, bundleInTop, [0.35, 0.05, 0]),
        bundleInTop,
      ],
      emphasized: isAssetFocus,
      opacity: assetOpacity,
      flowSpeed: isAssetFocus ? 0.36 : 0.2,
      anchorNodes: [pLayersRight],
    });

    // Track A: Immutable Bundle (.gloss/) -> Companion Workspace (.gloss.work/)
    curves.push({
      id: 'export-bundle-to-work',
      category: 'asset',
      colorHex: '#315C6B',
      points: [
        bundleOutWork,
        midPoint(bundleOutWork, workInTop, [0.22, 0, 0.1]),
        workInTop,
      ],
      emphasized: isAssetFocus,
      opacity: isAssetFocus ? 0.96 : isOverview ? 0.64 : 0.18,
      flowSpeed: isAssetFocus ? 0.38 : 0.2,
      anchorNodes: [bundleOutWork, workInTop],
    });

    // Track B: Recomputation loop (.gloss.work/ -> Layer 01 Code via parent_capture_id)
    if (isAssetFocus) {
      const pCodeTrackB = atSheet(transforms, 'code', 1.95, 1.55, 0.025);
      curves.push({
        id: 'export-work-track-b-recompute',
        category: 'asset',
        colorHex: '#315C6B',
        points: [
          workOutLeft,
          midPoint(workOutLeft, pCodeTrackB, [0.1, -0.15, 0.85]),
          pCodeTrackB,
        ],
        emphasized: false,
        opacity: 0.72,
        dashed: true,
        flowSpeed: 0.24,
        anchorNodes: [workOutLeft, pCodeTrackB],
      });
    }
  }

  return curves;
}

/**
 * Generates 2-3 high-signal 3D floating Glue-Code & Component Meaning callout badges
 * positioned cleanly along the active information-flow chains in both stacked and flat-tiled layouts.
 */
export function computeFlowCallouts(
  mode: MappingFocusMode,
  tracedSampleId: string | null,
  transforms: Record<LayerId, LayerTransform>,
  layoutMode: LayoutMode = 'stacked',
): FlowCalloutBadge[] {
  const isTiled = layoutMode === 'tiled';
  const assetCards = getAssetCardTransforms(layoutMode);

  if (mode === 'panel-grid') {
    if (isTiled) {
      return [
        {
          id: 'badge-panel-bbox',
          position: [
            (transforms.ir.x + transforms.panels.x) * 0.5,
            BASE_STACK_Y + 0.35,
            0.15,
          ],
          code: 'scene.coord · domain_space',
          role: '左上角原点 + 变换/原始双域',
          colorHex: '#2D603E',
        },
        {
          id: 'badge-lock-panel',
          position: [
            transforms.svg.x + 1.0,
            BASE_STACK_Y + 0.35,
            0.15,
          ],
          code: 'edit_policy: geometry_locked',
          role: 'data_mark 锁死 · 零位移验真',
          colorHex: '#2F855A',
        },
        {
          id: 'badge-edit-guide',
          position: [
            transforms.layers.x,
            BASE_STACK_Y + 0.35,
            transforms.svg.z + PLATE_DEPTH * 0.5 + 0.62,
          ],
          code: 'edit_policy: movable · texts.json',
          role: '可安全避让并自动牵引引线',
          colorHex: '#DF6A2B',
        },
      ];
    }

    const pLock = atSheet(transforms, 'svg', -0.45, -0.25, 0.18);
    const pGuide = atSheet(
      transforms,
      'svg',
      SHEET_ANCHORS.legendGroupA.x + 0.15,
      SHEET_ANCHORS.legendGroupA.z,
      0.18,
    );
    const pPrism = atSheet(transforms, 'panels', 0.1, 1.48, 0.12);
    return [
      {
        id: 'badge-lock-panel',
        position: pLock,
        code: 'edit_policy: geometry_locked',
        role: 'data_mark 锁死 · 零位移验真',
        colorHex: '#2F855A',
      },
      {
        id: 'badge-edit-guide',
        position: pGuide,
        code: 'edit_policy: movable · texts.json',
        role: '项级 ir.guides · 安全重排',
        colorHex: '#DF6A2B',
      },
      {
        id: 'badge-panel-bbox',
        position: pPrism,
        code: 'scene.coord · domain_space',
        role: '统一坐标逆变换 + 共享轴',
        colorHex: '#2D603E',
      },
    ];
  }

  if (mode === 'point-lineage' || tracedSampleId !== null) {
    const sample =
      PCA_SAMPLES.find((s) => s.id === (tracedSampleId ?? 'S1')) ?? PCA_SAMPLES[0];

    if (isTiled) {
      return [
        {
          id: 'badge-lineage-raw',
          position: [
            (transforms.code.x + transforms.ir.x) * 0.5,
            BASE_STACK_Y + 0.35,
            0.12,
          ],
          code: `_raw_row_id = ${sample.rowId}`,
          role: 'raw.csv ↔ built_layer1 透传',
          colorHex: '#2D603E',
        },
        {
          id: 'badge-lineage-mid',
          position: [0.0, BASE_STACK_Y + 0.35, 0.12],
          code: `row_accounting · 0 dropped`,
          role: `PC1 ${sample.pc1.toFixed(1)}, PC2 ${sample.pc2.toFixed(1)}`,
          colorHex: sample.colorHex,
        },
        {
          id: 'badge-lineage-svg',
          position: [
            (transforms.layers.x + transforms.svg.x) * 0.5,
            BASE_STACK_Y + 0.35,
            0.12,
          ],
          code: `${sample.elementId} · built_row_id=${sample.rowId}`,
          role: `row_exact → ${sample.patientId}`,
          colorHex: sample.colorHex,
        },
      ];
    }

    const pt = mapDataToPlateLocal(sample.pc1, sample.pc2);
    const pSvg = atSheet(transforms, 'svg', pt.x, pt.z, 0.22);
    const pMid = atSheet(transforms, 'axes', pt.x + 0.15, pt.z, 0.15);
    const rawA = getSampleRawAnchor(sample.id);
    const builtA = getSampleBuiltAnchor(sample.id);
    const pLow = midPoint(
      atSheet(transforms, 'code', rawA.x, rawA.z),
      atSheet(transforms, 'ir', builtA.x, builtA.z),
      [0, 0.08, 0],
    );
    return [
      {
        id: 'badge-lineage-svg',
        position: pSvg,
        code: `${sample.elementId} · built_row_id=${sample.rowId}`,
        role: `row_exact → ${sample.patientId}`,
        colorHex: sample.colorHex,
      },
      {
        id: 'badge-lineage-mid',
        position: pMid,
        code: `row_accounting · stat_role`,
        role: `PC1 ${sample.pc1.toFixed(1)}, PC2 ${sample.pc2.toFixed(1)}`,
        colorHex: sample.colorHex,
      },
      {
        id: 'badge-lineage-raw',
        position: pLow,
        code: `_raw_row_id = ${sample.rowId}`,
        role: 'raw.csv ↔ built_layer1 桥接',
        colorHex: '#2D603E',
      },
    ];
  }

  if (mode === 'scale-color') {
    if (isTiled) {
      return [
        {
          id: 'badge-scale-dict',
          position: [
            (transforms.code.x + transforms.ir.x) * 0.5,
            BASE_STACK_Y + 0.35,
            0.12,
          ],
          code: 'ir.scales (map + 11 stops)',
          role: '离散映射 + 连续色标 midpoint/oob',
          colorHex: '#2D603E',
        },
        {
          id: 'badge-scale-cluster',
          position: [0.0, BASE_STACK_Y + 0.35, 0.15],
          code: 'remap_scale_palette',
          role: '声明式补丁原子换色不漏改',
          colorHex: '#2F855A',
        },
        {
          id: 'badge-scale-legend',
          position: [
            transforms.layers.x,
            BASE_STACK_Y + 0.35,
            transforms.svg.z + PLATE_DEPTH * 0.5 + 0.62,
          ],
          code: 'ir.guides.entries (E0381)',
          role: '项级 swatch 与 label 同步联动',
          colorHex: '#DF6A2B',
        },
      ];
    }

    const pDict = atSheet(transforms, 'ir', SHEET_ANCHORS.irScaleA.x, SHEET_ANCHORS.irScaleA.z, 0.22);
    const pLeg = atSheet(transforms, 'svg', SHEET_ANCHORS.legendGroupA.x, SHEET_ANCHORS.legendGroupA.z, 0.22);
    const pClus = atSheet(transforms, 'layers', SHEET_ANCHORS.clusterA.x, SHEET_ANCHORS.clusterA.z, 0.22);
    return [
      {
        id: 'badge-scale-dict',
        position: pDict,
        code: 'ir.scales (map + 11 stops)',
        role: '离散字典 + 连续色标',
        colorHex: '#2D603E',
      },
      {
        id: 'badge-scale-legend',
        position: pLeg,
        code: 'ir.guides.entries',
        role: '项级 swatch/label 同步',
        colorHex: '#DF6A2B',
      },
      {
        id: 'badge-scale-cluster',
        position: pClus,
        code: 'remap_scale_palette',
        role: 'L004 / L005 原子换色',
        colorHex: '#2F855A',
      },
    ];
  }

  if (mode === 'asset-export') {
    if (isTiled) {
      return [
        {
          id: 'badge-export-map',
          position: [
            transforms.panels.x + 1.8,
            BASE_STACK_Y + 0.35,
            transforms.panels.z - PLATE_DEPTH * 0.5 - 0.55,
          ],
          code: 'asset-map.json + texts.json',
          role: 'v1.1 异构感知 · VLM+符号双通道',
          colorHex: '#DF6A2B',
        },
        {
          id: 'badge-export-bundle',
          position: [
            transforms.svg.x + PLATE_WIDTH * 0.5 + 1.45,
            BASE_STACK_Y + 0.35,
            0.2,
          ],
          code: 'Track A · parent_manifest_sha256',
          role: '只读 .gloss/ → .gloss.work/ 补丁',
          colorHex: '#2D603E',
        },
        {
          id: 'badge-export-trackb',
          position: [
            transforms.layers.x,
            BASE_STACK_Y + 0.35,
            transforms.svg.z + PLATE_DEPTH * 0.5 + 0.85,
          ],
          code: 'Track B · parent_capture_id',
          role: '改数据/模型回源 R 脚本重跑',
          colorHex: '#315C6B',
        },
      ];
    }

    const pMapMid = midPoint(
      atSheet(transforms, 'svg', PLATE_WIDTH / 2 - 0.12, -0.55),
      [assetCards['asset-map'].x - 1.0, assetCards['asset-map'].y, assetCards['asset-map'].z],
      [-0.45, 0.35, -0.25],
    );
    const pBundleMid = midPoint(
      atSheet(transforms, 'layers', PLATE_WIDTH / 2 - 0.12, 0.52),
      [assetCards['asset-bundle'].x - 1.0, assetCards['asset-bundle'].y, assetCards['asset-bundle'].z],
      [-0.9, -0.25, 0.25],
    );
    const pWorkMid = midPoint(
      atSheet(transforms, 'code', 1.95, 1.55),
      [assetCards['asset-work'].x - 1.0, assetCards['asset-work'].y, assetCards['asset-work'].z],
      [-0.35, 0.15, 0.72],
    );
    return [
      {
        id: 'badge-export-map',
        position: pMapMid,
        code: 'asset-map.json + texts.json',
        role: 'v1.1 异构感知 · AI 秒读目录',
        colorHex: '#DF6A2B',
      },
      {
        id: 'badge-export-bundle',
        position: pBundleMid,
        code: 'capture_id · preview.png',
        role: '只读不可变 .gloss/ 源包',
        colorHex: '#2D603E',
      },
      {
        id: 'badge-export-work',
        position: pWorkMid,
        code: 'Track A/B · .gloss.work/',
        role: '补丁派生 + threads + parent_capture_id',
        colorHex: '#315C6B',
      },
    ];
  }

  // Overview: cleanly surface the 3 Schema v1.1 Glue-Code Chains right inside open parchment corridors
  if (isTiled) {
    return [
      {
        id: 'badge-overview-data',
        position: [
          (transforms.code.x + transforms.ir.x) * 0.5,
          BASE_STACK_Y + 0.35,
          0.15,
        ],
        code: '② 行级桥接链 · _raw_row_id',
        role: 'raw ↔ built ↔ built_row_id',
        colorHex: '#DF6A2B',
      },
      {
        id: 'badge-overview-visual',
        position: [
          (transforms.ir.x + transforms.panels.x) * 0.5,
          BASE_STACK_Y + 0.35,
          0.15,
        ],
        code: '① 寻址编辑锁 · edit_policy',
        role: 'geometry_locked · texts.json',
        colorHex: '#2F855A',
      },
      {
        id: 'badge-overview-integrity',
        position: [
          assetCards['asset-bundle'].x - 1.75,
          BASE_STACK_Y + 0.35,
          1.78,
        ],
        code: '③ 双轨封条 · .gloss.work/',
        role: '只读源包 + 伴随协作态',
        colorHex: '#315C6B',
      },
    ];
  }

  const pVisual = atSheet(transforms, 'svg', -1.15, -1.25, 0.2);
  const pData = midPoint(
    atSheet(transforms, 'ir', SHEET_ANCHORS.irBuiltS1.x, SHEET_ANCHORS.irBuiltS1.z),
    atSheet(transforms, 'panels', SHEET_ANCHORS.clusterA.x, SHEET_ANCHORS.clusterA.z),
    [-0.1, 0.15, 0.15],
  );
  const pIntegrity = midPoint(
    atSheet(transforms, 'code', SHEET_ANCHORS.codeSourcesRight.x, SHEET_ANCHORS.codeSourcesRight.z),
    [assetCards['asset-work'].x - 1.0, assetCards['asset-work'].y, assetCards['asset-work'].z],
    [-0.55, 0.28, 0.72],
  );
  return [
    {
      id: 'badge-overview-visual',
      position: pVisual,
      code: '① 寻址编辑锁 · edit_policy',
      role: 'geometry_locked · ir.guides',
      colorHex: '#2F855A',
    },
    {
      id: 'badge-overview-data',
      position: pData,
      code: '② 行级桥接链 · _raw_row_id',
      role: 'raw ↔ built ↔ built_row_id',
      colorHex: '#DF6A2B',
    },
    {
      id: 'badge-overview-integrity',
      position: pIntegrity,
      code: '③ 双轨封条 · .gloss.work/',
      role: '只读源包 + 伴随协作态',
      colorHex: '#315C6B',
    },
  ];
}
