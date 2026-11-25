import { useState } from 'react';
import {
  ArrowUpRight,
  Check,
  CheckCircle2,
  ChevronRight,
  Clock,
  Copy,
  Cpu,
  FileText,
  Folder,
  Layers,
  Link2,
  Play,
  ShieldCheck,
  Sparkles,
  Terminal,
  X,
} from 'lucide-react';
import {
  ARCHITECTURE_LAYERS,
  ASSET_MAP_JSON,
  BUNDLE_TREE,
  COMPANION_WORK_TREE,
  CONTRACT_LAYERS,
  DESIGN_PRINCIPLES,
  ECOSYSTEM_CONSUMERS,
  END_TO_END_PATHS,
  ENGINE_COVERAGE,
  GLUE_CHAINS,
  PIPELINE_STEPS,
  PROGRESSIVE_SCENARIOS,
  PROJECT_LIVE_STATUS,
  PUBLIC_APIS,
  ROADMAP_STAGES,
  getLayerById,
  traceSampleLineage,
  type AssetNodeId,
  type BundleTreeNode,
  type DrawerTab,
  type LayerId,
} from '../data/glossModel';
import { MAPPING_MODES, type MappingFocusMode } from '../scene/mappingPaths';

export interface ArchitectureDrawerProps {
  open: boolean;
  tab: DrawerTab;
  onChangeTab: (tab: DrawerTab) => void;
  onClose: () => void;
  mappingMode: MappingFocusMode;
  onSelectMappingMode: (mode: MappingFocusMode) => void;
  onRunScenario: (mode: MappingFocusMode, sampleId: string | null) => void;
  focusLayer: LayerId | null;
  onSelectLayer: (id: LayerId) => void;
  focusAsset: AssetNodeId | null;
  tracedSampleId: string | null;
  activePipelineStep: number | null;
  onSelectPipelineStep: (step: number) => void;
}

const TABS: { id: DrawerTab; label: string }[] = [
  { id: 'inspector', label: '映射与层级' },
  { id: 'contract', label: '四层契约' },
  { id: 'assets', label: '内核与资产' },
  { id: 'roadmap', label: '实况与路线' },
];

function BundleTreeList({
  nodes,
  depth = 0,
}: {
  nodes: BundleTreeNode[];
  depth?: number;
}) {
  return (
    <ul
      className={
        depth === 0
          ? 'space-y-1.5'
          : 'mt-1.5 space-y-1.5 border-l border-[#1D2B22]/12 pl-4'
      }
    >
      {nodes.map((node) => (
        <li key={node.name}>
          <div className="flex items-start gap-2 text-xs">
            {node.kind === 'dir' ? (
              <Folder
                className="mt-0.5 h-3.5 w-3.5 shrink-0 text-[#2D603E]"
                aria-hidden="true"
              />
            ) : (
              <FileText
                className="mt-0.5 h-3.5 w-3.5 shrink-0 text-[#DF6A2B]"
                aria-hidden="true"
              />
            )}
            <div className="min-w-0 flex-1">
              <div className="flex items-center justify-between gap-2">
                <div className="flex min-w-0 items-center gap-1.5">
                  <span className="font-mono-tabular truncate font-semibold text-[#1D2B22]">
                    {node.name}
                  </span>
                  {node.badge && (
                    <span
                      className={`shrink-0 rounded px-1.5 py-0.2 text-[10px] font-semibold ${
                        node.badge === 'v1.1'
                          ? 'bg-[#FBF4EC] text-[#C45720]'
                          : node.badge === '外挂协作态'
                            ? 'bg-[#E8F1F4] text-[#274B58]'
                            : 'bg-[#E9F3EC] text-[#234F33]'
                      }`}
                    >
                      {node.badge}
                    </span>
                  )}
                </div>
                {node.size && (
                  <span className="font-mono-tabular shrink-0 text-[11px] text-[#5B6A60]">
                    {node.size}
                  </span>
                )}
              </div>
              <p className="mt-0.5 text-[11px] leading-relaxed text-[#4B5B50]">
                {node.role}
              </p>
            </div>
          </div>
          {node.children && (
            <BundleTreeList nodes={node.children} depth={depth + 1} />
          )}
        </li>
      ))}
    </ul>
  );
}

export function ArchitectureDrawer({
  open,
  tab,
  onChangeTab,
  onClose,
  mappingMode,
  onSelectMappingMode,
  onRunScenario,
  focusLayer,
  onSelectLayer,
  focusAsset,
  tracedSampleId,
  activePipelineStep,
  onSelectPipelineStep,
}: ArchitectureDrawerProps) {
  const [contractSubView, setContractSubView] = useState<
    'layers' | 'glue' | 'scenarios'
  >('layers');
  const [assetSubView, setAssetSubView] = useState<
    'map' | 'bundle' | 'core' | 'eco'
  >('map');
  const [roadmapSubView, setRoadmapSubView] = useState<
    'live' | 'pipeline' | 'stages'
  >('live');
  const [copiedMap, setCopiedMap] = useState(false);

  if (!open) return null;

  const activeLayer = getLayerById(focusLayer ?? 'svg');
  const activeModeSpec =
    MAPPING_MODES.find((m) => m.id === mappingMode) ?? MAPPING_MODES[0];
  const trace = tracedSampleId ? traceSampleLineage(tracedSampleId) : null;

  const handleCopyAssetMap = () => {
    navigator.clipboard?.writeText(ASSET_MAP_JSON).then(() => {
      setCopiedMap(true);
      window.setTimeout(() => setCopiedMap(false), 1800);
    });
  };

  return (
    <aside
      aria-label="gloss 架构规格详情面板"
      className="pointer-events-auto fixed right-4 top-16 z-20 flex max-h-[calc(100vh-204px)] w-[min(468px,calc(100vw-32px))] flex-col overflow-hidden rounded-xl border border-[#1D2B22]/14 bg-[#FCF9F3] shadow-xl"
    >
      {/* Drawer Header & Tabs */}
      <div className="flex items-center justify-between border-b border-[#1D2B22]/10 px-4 py-3">
        <div
          role="tablist"
          aria-label="规格详情分类"
          className="flex items-center gap-1"
        >
          {TABS.map((t) => {
            const active = tab === t.id;
            return (
              <button
                key={t.id}
                role="tab"
                type="button"
                aria-selected={active}
                onClick={() => onChangeTab(t.id)}
                className={`rounded-md px-2.5 py-1 text-xs font-semibold whitespace-nowrap transition-colors ${
                  active
                    ? 'bg-[#2D603E] text-[#FCF9F3]'
                    : 'text-[#4B5B50] hover:bg-[#EFE9DC] hover:text-[#1D2B22]'
                }`}
              >
                {t.label}
              </button>
            );
          })}
        </div>

        <button
          type="button"
          onClick={onClose}
          aria-label="关闭架构详情面板"
          className="rounded-md p-1.5 text-[#4B5B50] transition-colors hover:bg-[#EFE9DC] hover:text-[#1D2B22]"
        >
          <X className="h-4 w-4" aria-hidden="true" />
        </button>
      </div>

      {/* Scrollable Drawer Content */}
      <div className="gloss-scroll flex-1 overflow-y-auto px-4 py-4">
        {tab === 'inspector' && (
          <div className="space-y-5">
            {/* Active 3D Key-Element Mapping Breakdown */}
            <section className="rounded-lg border border-[#2D603E]/22 bg-[#F4F8F5] p-3.5">
              <div className="flex items-baseline justify-between gap-2">
                <h3 className="text-sm font-bold text-[#1D2B22]">
                  {activeModeSpec.title}
                </h3>
                <span className="font-mono-tabular shrink-0 text-[11px] font-semibold text-[#2D603E]">
                  {activeModeSpec.glueTag}
                </span>
              </div>
              <div className="font-mono-tabular mt-1.5 rounded bg-[#EAF2EC] px-2 py-1 text-[11px] leading-relaxed text-[#1E472D]">
                {activeModeSpec.formula}
              </div>
              <p className="mt-2 text-xs leading-relaxed text-[#3A4D41]">
                {activeModeSpec.description}
              </p>

              <ol className="mt-3 space-y-2 border-t border-[#1D2B22]/10 pt-2.5 text-xs">
                {activeModeSpec.steps.map((st, idx) => (
                  <li key={st.anchorName} className="flex items-start gap-2">
                    <span className="font-mono-tabular mt-0.5 text-[11px] font-bold text-[#2D603E]">
                      0{idx + 1}
                    </span>
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-baseline justify-between gap-1">
                        <span className="font-semibold text-[#1D2B22]">
                          {st.anchorName}
                        </span>
                        <span className="font-mono-tabular text-[11px] text-[#5B6A60]">
                          {st.layerLabel}
                        </span>
                      </div>
                      <p className="mt-0.5 text-[11px] leading-relaxed text-[#4B5B50]">
                        {st.detail}
                      </p>
                    </div>
                  </li>
                ))}
              </ol>

              <div className="mt-3 flex flex-wrap gap-1 border-t border-[#1D2B22]/10 pt-2.5">
                {MAPPING_MODES.map((m) => (
                  <button
                    key={m.id}
                    type="button"
                    onClick={() => onSelectMappingMode(m.id)}
                    className={`rounded-md px-2 py-1 text-[11px] font-medium transition-colors ${
                      m.id === mappingMode
                        ? 'bg-[#2D603E] text-[#FCF9F3]'
                        : 'bg-[#E6EFE9] text-[#2D503A] hover:bg-[#D7E6DC]'
                    }`}
                  >
                    {m.label}
                  </button>
                ))}
              </div>
            </section>

            {/* Active Sample Vertical Lineage Trace (Schema v1.1.0) */}
            {trace && (
              <section className="rounded-lg border border-[#DF6A2B]/30 bg-[#FBF4EC] p-3.5">
                <div className="flex items-baseline justify-between gap-2">
                  <h3 className="text-sm font-bold text-[#1D2B22]">
                    样本 {trace.sample.id} ({trace.sample.patientId}) · v1.1 双向溯源
                  </h3>
                  <span className="font-mono-tabular rounded bg-[#DF6A2B]/15 px-1.5 py-0.5 text-[11px] font-semibold text-[#B9501B]">
                    {trace.cardinality} · {trace.lineageTier}
                  </span>
                </div>
                <p className="mt-1 text-xs text-[#4B5B50]">
                  {trace.sample.cohortLabel} · {trace.sample.note}
                </p>

                <dl className="mt-3 space-y-2 text-xs">
                  <div>
                    <dt className="font-semibold text-[#2D603E]">
                      06 SVG 图元与元素外键 (scene.svg + elements.json)
                    </dt>
                    <dd className="font-mono-tabular mt-0.5 break-all text-[11px] text-[#2C3E33]">
                      {trace.svgElement}
                    </dd>
                  </div>
                  <div>
                    <dt className="font-semibold text-[#2D603E]">
                      04–05 语义角色与编辑权限锁 (leaves.json)
                    </dt>
                    <dd className="font-mono-tabular mt-0.5 text-[11px] text-[#2C3E33]">
                      {trace.semanticsLock}
                    </dd>
                  </div>
                  <div>
                    <dt className="font-semibold text-[#2D603E]">
                      03 面板与统一坐标逆变换 (scene.coord + ir.panels)
                    </dt>
                    <dd className="font-mono-tabular mt-0.5 text-[11px] text-[#2C3E33]">
                      {trace.panelMapping}
                    </dd>
                  </div>
                  <div>
                    <dt className="font-semibold text-[#2D603E]">
                      02 色板与项级图例绑定 (ir.scales + ir.guides.entries)
                    </dt>
                    <dd className="font-mono-tabular mt-0.5 text-[11px] text-[#2C3E33]">
                      {trace.scaleRule}
                    </dd>
                    <dd className="font-mono-tabular mt-0.5 text-[11px] text-[#4B5B50]">
                      {trace.guideBinding}
                    </dd>
                  </div>
                  <div>
                    <dt className="font-semibold text-[#2D603E]">
                      02 built_layer1 计算行与丢行账本
                    </dt>
                    <dd className="font-mono-tabular mt-0.5 text-[11px] text-[#2C3E33]">
                      {trace.builtRow}
                    </dd>
                    <dd className="font-mono-tabular mt-0.5 text-[11px] text-[#4B5B50]">
                      {trace.rowAccounting}
                    </dd>
                  </div>
                  <div>
                    <dt className="font-semibold text-[#2D603E]">
                      01 tables/raw.csv 原始行
                    </dt>
                    <dd className="font-mono-tabular mt-0.5 text-[11px] text-[#2C3E33]">
                      {trace.rawRow}
                    </dd>
                  </div>
                </dl>
              </section>
            )}

            {/* Focused Output Asset Callout if User Clicked Asset Map, Bundle, or .gloss.work/ in 3D */}
            {focusAsset && (
              <section
                className={`rounded-lg border p-3.5 ${
                  focusAsset === 'asset-work'
                    ? 'border-[#315C6B]/30 bg-[#EDF4F7]'
                    : 'border-[#2D603E]/25 bg-[#F2F6F3]'
                }`}
              >
                <div className="flex items-center justify-between gap-2">
                  <h3 className="text-sm font-bold text-[#1D2B22]">
                    {focusAsset === 'asset-map'
                      ? 'Asset Map (asset-map.json · v1.1.0)'
                      : focusAsset === 'asset-bundle'
                        ? '只读源包 · Asset Bundle (figure.gloss/)'
                        : '伴随协作态 · Workspace (figure.gloss.work/)'}
                  </h3>
                  <button
                    type="button"
                    onClick={() => {
                      setAssetSubView(
                        focusAsset === 'asset-map' ? 'map' : 'bundle',
                      );
                      onChangeTab('assets');
                    }}
                    className="flex shrink-0 items-center gap-0.5 text-xs font-semibold text-[#2D603E] hover:underline"
                  >
                    <span>查看完整结构</span>
                    <ChevronRight className="h-3.5 w-3.5" aria-hidden="true" />
                  </button>
                </div>
                <p className="mt-1.5 text-xs leading-relaxed text-[#3A4D41]">
                  {focusAsset === 'asset-map'
                    ? '几十 KB 级全局目录与 Engine IR v1.1 摘要（含 scene.coord、panels 双域、layers 丢行账本、11 节点连续 stops、项级 ir.guides 与 edit_policy）。AI 先读此图 + <10 KB texts.json，再按需切片读表。'
                    : focusAsset === 'asset-bundle'
                      ? '只读不可变自包含目录或 .zip 源包：收敛 original.svg、可寻址 scene.svg、144 dpi preview.png、texts.json、带 _raw_row_id 的 CSV/Parquet、groups_*.json、sources/ 与 SHA-256 manifest.json。'
                      : '严守 .gloss/ 只读不可变，由 workspace_state.py 与 focus_bridge.py 在旁侧维护可写协作目录：持久化 focus.json（双向指代）、threads.json（审计问题单/裁决）、patches/（声明式补丁）与 derived/（零位移精修稿）。'}
                </p>
              </section>
            )}

            {/* Active Layer Architectural Specification */}
            <section>
              <div className="flex items-baseline justify-between gap-2">
                <div className="text-xs font-medium text-[#5B6A60]">
                  第 0{activeLayer.stepNumber} 层 · {activeLayer.titleEn}
                </div>
                <span className="font-mono-tabular text-[11px] text-[#5B6A60]">
                  {activeLayer.stepNumber} / 6
                </span>
              </div>
              <h2 className="mt-1 text-lg font-bold text-[#1D2B22]">
                {activeLayer.titleZh}
              </h2>
              <p className="mt-1 text-xs font-medium text-[#2D603E]">
                {activeLayer.tagline}
              </p>

              {/* Real R Source Modules */}
              <div className="mt-2 flex flex-wrap items-center gap-1.5">
                <span className="text-[11px] font-semibold text-[#5B6A60]">
                  R 实现模块：
                </span>
                {activeLayer.rModules.map((mod) => (
                  <code
                    key={mod}
                    className="font-mono-tabular rounded bg-[#EAF2EC] px-1.5 py-0.5 text-[10px] font-semibold text-[#234F33]"
                  >
                    {mod}
                  </code>
                ))}
              </div>

              {/* Plain SVG Pain-Point Callout */}
              <div className="mt-3 rounded-lg border border-[#DF6A2B]/25 bg-[#FBF4EC] px-3 py-2">
                <div className="text-[11px] font-semibold text-[#B9501B]">
                  填补纯 SVG 痛点
                </div>
                <p className="mt-0.5 text-xs leading-relaxed text-[#3A4D41]">
                  {activeLayer.svgPainPoint}
                </p>
              </div>

              <p className="mt-2.5 text-xs leading-relaxed text-[#3A4D41]">
                {activeLayer.description}
              </p>

              {/* Layer Glue Keys */}
              <div className="mt-3">
                <div className="text-[11px] font-semibold text-[#5B6A60]">
                  本层关键粘合编码（Schema v1.1.0）
                </div>
                <div className="mt-1.5 flex flex-wrap gap-1.5">
                  {activeLayer.glueKeys.map((gk) => (
                    <code
                      key={gk}
                      className="font-mono-tabular rounded border border-[#1D2B22]/12 bg-[#F4EFE5] px-2 py-0.5 text-[11px] font-medium text-[#1D2B22]"
                    >
                      {gk}
                    </code>
                  ))}
                </div>
              </div>

              {/* Key Fields Grid */}
              <dl className="mt-4 grid grid-cols-1 gap-2 border-t border-[#1D2B22]/10 pt-3.5">
                {activeLayer.keyFields.map((field) => (
                  <div
                    key={field.label}
                    className="flex items-baseline justify-between gap-3 text-xs"
                  >
                    <dt className="shrink-0 text-[#5B6A60]">{field.label}</dt>
                    <dd className="font-mono-tabular text-right font-medium text-[#1D2B22]">
                      {field.value}
                    </dd>
                  </div>
                ))}
              </dl>

              {/* R / SVG Schema Snippet */}
              <div className="mt-4">
                <div className="text-xs font-semibold text-[#1D2B22]">
                  内核契约示例
                </div>
                <pre className="font-mono-tabular mt-1.5 overflow-x-auto rounded-lg border border-[#1D2B22]/12 bg-[#F4EFE5] p-3 text-[11px] leading-relaxed text-[#1D2B22]">
                  {activeLayer.rSnippet}
                </pre>
              </div>

              {/* Associated Bundle Artifacts */}
              <div className="mt-3.5 text-xs text-[#5B6A60]">
                落盘产物：
                <span className="font-mono-tabular ml-1 text-[#1D2B22]">
                  {activeLayer.bundleFiles.join(' · ')}
                </span>
              </div>

              {/* Quick Layer Jump Strip */}
              <div className="mt-4 flex flex-wrap gap-1.5 border-t border-[#1D2B22]/10 pt-3.5">
                {ARCHITECTURE_LAYERS.map((layer) => (
                  <button
                    key={layer.id}
                    type="button"
                    onClick={() => onSelectLayer(layer.id)}
                    className={`rounded-md px-2 py-1 text-[11px] font-medium transition-colors ${
                      layer.id === activeLayer.id
                        ? 'bg-[#DF6A2B] text-[#FCF9F3]'
                        : 'bg-[#EFE9DC] text-[#3A4D41] hover:text-[#1D2B22]'
                    }`}
                  >
                    0{layer.stepNumber} {layer.shortLabel}
                  </button>
                ))}
              </div>
            </section>
          </div>
        )}

        {tab === 'contract' && (
          <div className="space-y-4">
            {/* Sub-view Switcher: 4 Layers / 3 Glue Chains / 4 Scenarios */}
            <div className="flex items-center gap-1 rounded-lg bg-[#EFE9DC] p-1">
              <button
                type="button"
                onClick={() => setContractSubView('layers')}
                className={`flex flex-1 items-center justify-center gap-1 rounded-md px-2 py-1.5 text-xs font-semibold transition-colors ${
                  contractSubView === 'layers'
                    ? 'bg-[#FCF9F3] text-[#1D2B22] shadow-xs'
                    : 'text-[#4B5B50] hover:text-[#1D2B22]'
                }`}
              >
                <Layers className="h-3.5 w-3.5" aria-hidden="true" />
                <span>4 层分工</span>
              </button>
              <button
                type="button"
                onClick={() => setContractSubView('glue')}
                className={`flex flex-1 items-center justify-center gap-1 rounded-md px-2 py-1.5 text-xs font-semibold transition-colors ${
                  contractSubView === 'glue'
                    ? 'bg-[#FCF9F3] text-[#1D2B22] shadow-xs'
                    : 'text-[#4B5B50] hover:text-[#1D2B22]'
                }`}
              >
                <Link2 className="h-3.5 w-3.5" aria-hidden="true" />
                <span>3 条粘合编码</span>
              </button>
              <button
                type="button"
                onClick={() => setContractSubView('scenarios')}
                className={`flex flex-1 items-center justify-center gap-1 rounded-md px-2 py-1.5 text-xs font-semibold transition-colors ${
                  contractSubView === 'scenarios'
                    ? 'bg-[#FCF9F3] text-[#1D2B22] shadow-xs'
                    : 'text-[#4B5B50] hover:text-[#1D2B22]'
                }`}
              >
                <Sparkles className="h-3.5 w-3.5" aria-hidden="true" />
                <span>4 类实战演练</span>
              </button>
            </div>

            {contractSubView === 'layers' && (
              <div className="space-y-3.5">
                <div>
                  <h2 className="text-sm font-bold text-[#1D2B22]">
                    Schema v1.1.0 四层开放格式分工
                  </h2>
                  <p className="mt-1 text-xs leading-relaxed text-[#4B5B50]">
                    不造私有二进制格式，而是拆成 SVG / PNG / JSON / CSV(Parquet) 四层开放契约 + 旁侧 .gloss.work/ 协作态，闭合全部 23 项最后一公里断层。点击任一条目直接在 3D 抽拉定位对应层级。
                  </p>
                </div>

                {CONTRACT_LAYERS.map((layer) => (
                  <section
                    key={layer.id}
                    className="rounded-lg border border-[#1D2B22]/12 bg-[#F7F3EA]/80 p-3.5"
                  >
                    <div className="flex items-baseline justify-between gap-2">
                      <h3 className="text-sm font-bold text-[#1D2B22]">
                        0{layer.index}. {layer.title}
                      </h3>
                      <span
                        className="font-mono-tabular shrink-0 text-[11px] font-semibold"
                        style={{ color: layer.accentHex }}
                      >
                        层 {layer.index}/4
                      </span>
                    </div>
                    <div className="font-mono-tabular mt-1 text-[11px] text-[#2D603E]">
                      {layer.filesSummary}
                    </div>
                    <p className="mt-1.5 text-xs leading-relaxed text-[#3A4D41]">
                      {layer.positioning}
                    </p>

                    <div className="mt-2 rounded bg-[#FBF4EC] px-2.5 py-1.5 text-[11px] leading-relaxed text-[#6E3B1B]">
                      <span className="font-semibold text-[#B9501B]">
                        纯 SVG 痛点：
                      </span>
                      {layer.svgPainPoint}
                    </div>

                    <div className="mt-2.5 space-y-1.5 border-t border-[#1D2B22]/10 pt-2.5">
                      {layer.components.map((comp) => (
                        <button
                          key={comp.code}
                          type="button"
                          onClick={() => onSelectLayer(comp.targetLayerId)}
                          className="group w-full rounded-md border border-transparent bg-[#FCF9F3] px-2.5 py-2 text-left transition-colors hover:border-[#2D603E]/40 hover:bg-[#F2F7F3]"
                        >
                          <div className="flex items-center justify-between gap-2">
                            <div className="flex min-w-0 items-center gap-1.5">
                              <code className="font-mono-tabular truncate text-[11px] font-semibold text-[#1D2B22] group-hover:text-[#2D603E]">
                                {comp.code}
                              </code>
                              {comp.badge && (
                                <span className="shrink-0 rounded bg-[#FBF4EC] px-1 py-0.2 text-[9.5px] font-bold text-[#C45720]">
                                  {comp.badge}
                                </span>
                              )}
                            </div>
                            <span className="flex shrink-0 items-center gap-0.5 text-[10px] font-medium text-[#5B6A60] group-hover:text-[#2D603E]">
                              <span>3D 抽拉</span>
                              <ArrowUpRight
                                className="h-3 w-3"
                                aria-hidden="true"
                              />
                            </span>
                          </div>
                          <p className="mt-0.5 text-[11px] leading-relaxed text-[#4B5B50]">
                            {comp.meaning}
                          </p>
                        </button>
                      ))}
                    </div>
                  </section>
                ))}
              </div>
            )}

            {contractSubView === 'glue' && (
              <div className="space-y-3.5">
                <div>
                  <h2 className="text-sm font-bold text-[#1D2B22]">
                    三条核心粘合编码：消除下游“靠猜”的断链点
                  </h2>
                  <p className="mt-1 text-xs leading-relaxed text-[#4B5B50]">
                    Schema v1.1 用三条确定性跨文件外键链咬合全部开放文件与伴随工作目录。点击按钮直接在 3D 中点亮动态信息流。
                  </p>
                </div>

                {GLUE_CHAINS.map((chain) => {
                  const isLit = mappingMode === chain.mappingMode;
                  return (
                    <section
                      key={chain.id}
                      className={`rounded-lg border p-3.5 transition-colors ${
                        isLit
                          ? 'border-[#2D603E] bg-[#F2F7F3]'
                          : 'border-[#1D2B22]/12 bg-[#F7F3EA]/80'
                      }`}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <h3 className="text-sm font-bold text-[#1D2B22]">
                          链 0{chain.index} · {chain.title}
                        </h3>
                        <button
                          type="button"
                          onClick={() => onSelectMappingMode(chain.mappingMode)}
                          className={`flex shrink-0 items-center gap-1 rounded-md px-2.5 py-1 text-[11px] font-semibold transition-colors ${
                            isLit
                              ? 'bg-[#2D603E] text-[#FCF9F3]'
                              : 'bg-[#DF6A2B] text-[#FCF9F3] hover:bg-[#C65B22]'
                          }`}
                        >
                          <Play className="h-3 w-3" aria-hidden="true" />
                          <span>{isLit ? '3D 已点亮' : '在 3D 中点亮'}</span>
                        </button>
                      </div>

                      <div className="mt-2 flex flex-wrap gap-1.5">
                        {chain.keys.map((k) => (
                          <code
                            key={k}
                            className="font-mono-tabular rounded border border-[#1D2B22]/14 bg-[#FCF9F3] px-2 py-0.5 text-[11px] font-semibold text-[#1D2B22]"
                          >
                            {k}
                          </code>
                        ))}
                      </div>

                      <div className="mt-2.5 text-[11px] leading-relaxed text-[#4B5B50]">
                        <span className="font-semibold text-[#1D2B22]">
                          串联文件：
                        </span>
                        <span className="font-mono-tabular">
                          {chain.connectedFiles}
                        </span>
                      </div>

                      <p className="mt-2 border-t border-[#1D2B22]/10 pt-2 text-xs leading-relaxed text-[#2C3E33]">
                        <span className="font-semibold text-[#2D603E]">
                          解锁能力：
                        </span>
                        {chain.capability}
                      </p>
                    </section>
                  );
                })}
              </div>
            )}

            {contractSubView === 'scenarios' && (
              <div className="space-y-4">
                <div>
                  <h2 className="text-sm font-bold text-[#1D2B22]">
                    四类已就绪高价值实战场景（立即可用）
                  </h2>
                  <p className="mt-1 text-xs leading-relaxed text-[#4B5B50]">
                    全部由包外 4 个 Agent Skills 与 5 个零依赖 Python CLI 实测跑通。每张卡片均附实跑 CLI 命令与一键 3D 信息流回放。
                  </p>
                </div>

                {PROGRESSIVE_SCENARIOS.map((sc) => (
                  <section
                    key={sc.id}
                    className="rounded-lg border border-[#1D2B22]/14 bg-[#F7F3EA]/85 p-3.5"
                  >
                    <h3 className="text-sm font-bold text-[#1D2B22]">
                      {sc.title}
                    </h3>
                    <div className="mt-0.5 text-[11px] font-medium text-[#5B6A60]">
                      {sc.subtitle}
                    </div>

                    {/* Stage 1: Plain SVG limit vs gloss human value */}
                    <div className="mt-3 grid grid-cols-1 gap-2">
                      <div className="rounded-md bg-[#FBF4EC] px-2.5 py-2 text-xs leading-relaxed text-[#5E361E]">
                        <div className="text-[11px] font-bold text-[#B9501B]">
                          ① 传统痛点
                        </div>
                        <p className="mt-0.5">{sc.plainSvgLimit}</p>
                      </div>
                      <div className="rounded-md bg-[#EDF5EF] px-2.5 py-2 text-xs leading-relaxed text-[#20452D]">
                        <div className="text-[11px] font-bold text-[#2D603E]">
                          gloss Schema v1.1 方案
                        </div>
                        <p className="mt-0.5">{sc.glossValue}</p>
                      </div>
                    </div>

                    {/* Stage 2: Step-by-step encoding choreography */}
                    <ol className="mt-3 space-y-2 border-t border-[#1D2B22]/10 pt-2.5">
                      {sc.encodingSteps.map((st, idx) => (
                        <li
                          key={st.stepTitle}
                          className="rounded-md bg-[#FCF9F3] p-2.5"
                        >
                          <div className="flex items-baseline gap-1.5 text-xs font-bold text-[#1D2B22]">
                            <span className="font-mono-tabular text-[11px] text-[#DF6A2B]">
                              0{idx + 1}
                            </span>
                            <span>{st.stepTitle}</span>
                          </div>
                          <p className="mt-1 text-[11px] leading-relaxed text-[#4B5B50]">
                            {st.detail}
                          </p>
                          <div className="mt-1.5 flex flex-wrap gap-1">
                            {st.keys.map((k) => (
                              <code
                                key={k}
                                className="font-mono-tabular rounded bg-[#F1ECE1] px-1.5 py-0.5 text-[10px] font-medium text-[#2D603E]"
                              >
                                {k}
                              </code>
                            ))}
                          </div>
                        </li>
                      ))}
                    </ol>

                    {/* Real Python CLI command */}
                    <div className="mt-2.5 rounded-md border border-[#1D2B22]/10 bg-[#F2ECE0] p-2">
                      <div className="flex items-center gap-1 text-[10px] font-semibold text-[#5B6A60]">
                        <Terminal className="h-3 w-3" aria-hidden="true" />
                        <span>实测零依赖 CLI</span>
                      </div>
                      <code className="font-mono-tabular mt-1 block overflow-x-auto whitespace-pre-wrap break-all text-[10.5px] leading-relaxed text-[#1D2B22]">
                        {sc.cliCommand}
                      </code>
                    </div>

                    {/* Stage 3: 1-Click 3D Replay CTA */}
                    <button
                      type="button"
                      onClick={() =>
                        onRunScenario(sc.targetMode, sc.targetSampleId)
                      }
                      className="mt-3 flex w-full items-center justify-center gap-1.5 rounded-lg bg-[#2D603E] px-3 py-2 text-xs font-semibold text-[#FCF9F3] transition-colors hover:bg-[#234F33]"
                    >
                      <Play className="h-3.5 w-3.5" aria-hidden="true" />
                      <span>{sc.actionLabel}</span>
                    </button>
                  </section>
                ))}
              </div>
            )}
          </div>
        )}

        {tab === 'assets' && (
          <div className="space-y-4">
            <div className="grid grid-cols-4 gap-1 rounded-lg bg-[#EFE9DC] p-1">
              {[
                { id: 'map', label: 'Asset Map' },
                { id: 'bundle', label: '资产目录' },
                { id: 'core', label: '内核与引擎' },
                { id: 'eco', label: 'Agent 生态' },
              ].map((sv) => (
                <button
                  key={sv.id}
                  type="button"
                  onClick={() =>
                    setAssetSubView(sv.id as 'map' | 'bundle' | 'core' | 'eco')
                  }
                  className={`rounded-md px-1.5 py-1.5 text-[11px] font-semibold whitespace-nowrap transition-colors ${
                    assetSubView === sv.id
                      ? 'bg-[#FCF9F3] text-[#1D2B22] shadow-xs'
                      : 'text-[#4B5B50] hover:text-[#1D2B22]'
                  }`}
                >
                  {sv.label}
                </button>
              ))}
            </div>

            {assetSubView === 'map' && (
              <div>
                <div className="flex items-center justify-between gap-2">
                  <div>
                    <h3 className="text-sm font-bold text-[#1D2B22]">
                      asset-map.json · Schema v1.1.0
                    </h3>
                    <span className="font-mono-tabular text-[11px] text-[#DF6A2B]">
                      ≈ 24 KB · + texts.json (&lt;10 KB) + preview.png
                    </span>
                  </div>
                  <button
                    type="button"
                    onClick={handleCopyAssetMap}
                    className="flex shrink-0 items-center gap-1 rounded-md border border-[#1D2B22]/14 bg-[#F7F3EA] px-2 py-1 text-[11px] font-semibold text-[#2C3E33] transition-colors hover:border-[#2D603E]"
                  >
                    {copiedMap ? (
                      <>
                        <Check className="h-3 w-3 text-[#2F855A]" aria-hidden="true" />
                        <span>已复制</span>
                      </>
                    ) : (
                      <>
                        <Copy className="h-3 w-3" aria-hidden="true" />
                        <span>复制 JSON</span>
                      </>
                    )}
                  </button>
                </div>
                <p className="mt-1.5 text-xs leading-relaxed text-[#4B5B50]">
                  Agent 渐进感知入口：先读几十 KB 目录与 &lt;10 KB 文字索引，结合 144 dpi 快览图判断版式，再按需切片读取 CSV/Parquet。
                </p>
                <pre className="font-mono-tabular mt-3 overflow-x-auto rounded-lg border border-[#1D2B22]/12 bg-[#F4EFE5] p-3 text-[11px] leading-relaxed text-[#1D2B22]">
                  {ASSET_MAP_JSON}
                </pre>
              </div>
            )}

            {assetSubView === 'bundle' && (
              <div className="space-y-4">
                <div>
                  <h3 className="text-sm font-bold text-[#1D2B22]">
                    figure.gloss/ · 只读不可变开放源包（v1.1.0）
                  </h3>
                  <p className="mt-1 text-xs leading-relaxed text-[#4B5B50]">
                    支持目录与 .zip 打包，数据表支持 CSV 与 Apache Parquet（nanoparquet）。源包由 manifest.json SHA-256 封存，绝不原地覆写。
                  </p>
                  <div className="mt-2.5 rounded-lg border border-[#2D603E]/20 bg-[#F7F3EA]/75 p-3.5">
                    <BundleTreeList nodes={BUNDLE_TREE} />
                  </div>
                </div>

                <div>
                  <h3 className="text-sm font-bold text-[#1D2B22]">
                    figure.gloss.work/ · 旁侧共享协作工作态
                  </h3>
                  <p className="mt-1 text-xs leading-relaxed text-[#4B5B50]">
                    严格位于 R 包核心之外，由 workspace_state.py / focus_bridge.py / apply_visual_patch.py 协同维护，支撑跨天跨 Agent 接力。
                  </p>
                  <div className="mt-2.5 rounded-lg border border-[#315C6B]/25 bg-[#EFF5F7]/85 p-3.5">
                    <BundleTreeList nodes={COMPANION_WORK_TREE} />
                  </div>
                </div>
              </div>
            )}

            {assetSubView === 'core' && (
              <div className="space-y-4">
                {/* 8 Canonical Public APIs */}
                <section>
                  <div className="flex items-baseline justify-between">
                    <h3 className="text-sm font-bold text-[#1D2B22]">
                      R 核心包 8 个公开 API（NAMESPACE 严守极简）
                    </h3>
                    <span className="font-mono-tabular text-[11px] text-[#2D603E]">
                      14 文件 · 8,924 LOC
                    </span>
                  </div>
                  <div className="mt-2.5 space-y-2">
                    {PUBLIC_APIS.map((api) => (
                      <div
                        key={api.name}
                        className="rounded-lg border border-[#1D2B22]/12 bg-[#F7F3EA]/80 p-2.5"
                      >
                        <div className="flex items-baseline justify-between gap-2">
                          <code className="font-mono-tabular text-xs font-bold text-[#2D603E]">
                            {api.name}
                          </code>
                          <span className="font-mono-tabular text-[10px] text-[#5B6A60]">
                            {api.sourceFile}
                          </span>
                        </div>
                        <div className="font-mono-tabular mt-1 rounded bg-[#EFE9DC]/80 px-2 py-1 text-[10.5px] leading-snug text-[#1D2B22]">
                          {api.signature}
                        </div>
                        <p className="mt-1 text-[11px] leading-relaxed text-[#4B5B50]">
                          {api.summary}
                        </p>
                      </div>
                    ))}
                  </div>
                </section>

                {/* 5 Built-in Engines + Extensions Hardening */}
                <section className="border-t border-[#1D2B22]/10 pt-4">
                  <div className="flex items-center gap-1.5">
                    <Cpu className="h-4 w-4 text-[#DF6A2B]" aria-hidden="true" />
                    <h3 className="text-sm font-bold text-[#1D2B22]">
                      五大内置引擎 + 科研扩展防腐矩阵
                    </h3>
                  </div>
                  <div className="mt-2.5 space-y-2">
                    {ENGINE_COVERAGE.map((eng) => (
                      <div
                        key={eng.id}
                        className="rounded-lg border border-[#1D2B22]/12 bg-[#FCF9F3] p-3"
                      >
                        <div className="flex items-center justify-between gap-2">
                          <div className="flex items-center gap-2">
                            <span className="text-xs font-bold text-[#1D2B22]">
                              {eng.name}
                            </span>
                            <span
                              className={`font-mono-tabular rounded px-1.5 py-0.5 text-[10px] font-semibold ${
                                eng.dependency === 'Suggests'
                                  ? 'bg-[#FBF4EC] text-[#C45720]'
                                  : 'bg-[#E9F3EC] text-[#234F33]'
                              }`}
                            >
                              {eng.dependency}
                            </span>
                          </div>
                          <span className="font-mono-tabular text-[10.5px] text-[#5B6A60]">
                            {eng.sourceFile} · {eng.loc} LOC
                          </span>
                        </div>
                        <p className="mt-1.5 text-[11px] leading-relaxed text-[#3A4D41]">
                          {eng.highlights}
                        </p>
                        {eng.extensions && (
                          <div className="mt-2 flex flex-wrap gap-1">
                            {eng.extensions.map((ext) => (
                              <span
                                key={ext}
                                className="font-mono-tabular rounded bg-[#F1ECE1] px-1.5 py-0.5 text-[10px] font-medium text-[#2D603E]"
                              >
                                {ext}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </section>
              </div>
            )}

            {assetSubView === 'eco' && (
              <div className="space-y-3">
                <p className="text-xs leading-relaxed text-[#4B5B50]">
                  全部置于 R 包外（<code className="font-mono-tabular">skills/</code> 已在 <code className="font-mono-tabular">.Rbuildignore</code> 排除）：4 个 Agent Skills + 5 个纯 Python 标准库执行器已 100% 就绪，外围 GUI 与活体 MCP 规划在阶段 4。
                </p>
                {ECOSYSTEM_CONSUMERS.map((eco) => (
                  <div
                    key={eco.id}
                    className={`rounded-lg border p-3 ${
                      eco.status === 'implemented'
                        ? 'border-[#2D603E]/20 bg-[#F7F3EA]/80'
                        : 'border-[#315C6B]/22 bg-[#F1F6F8]/75'
                    }`}
                  >
                    <div className="flex items-center justify-between gap-2">
                      <h4 className="text-xs font-bold text-[#1D2B22]">
                        {eco.name}
                      </h4>
                      <span
                        className={`inline-flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                          eco.status === 'implemented'
                            ? 'bg-[#E5F2E9] text-[#1F5432]'
                            : 'bg-[#E2EDF2] text-[#274B58]'
                        }`}
                      >
                        {eco.status === 'implemented' ? (
                          <>
                            <CheckCircle2 className="h-3 w-3" aria-hidden="true" />
                            <span>已就绪</span>
                          </>
                        ) : (
                          <>
                            <Clock className="h-3 w-3" aria-hidden="true" />
                            <span>规划中</span>
                          </>
                        )}
                      </span>
                    </div>
                    <div className="font-mono-tabular mt-1 text-[11px] text-[#2D603E]">
                      {eco.role}
                    </div>
                    {eco.scripts && (
                      <div className="mt-1.5 flex flex-wrap gap-1">
                        {eco.scripts.map((sc) => (
                          <code
                            key={sc}
                            className="font-mono-tabular rounded border border-[#1D2B22]/12 bg-[#FCF9F3] px-1.5 py-0.5 text-[10px] font-semibold text-[#1D2B22]"
                          >
                            {sc}
                          </code>
                        ))}
                      </div>
                    )}
                    <p className="mt-1.5 text-[11px] text-[#5B6A60]">
                      <span className="font-semibold text-[#1D2B22]">输入：</span>
                      {eco.reads}
                    </p>
                    <p className="mt-1 text-xs leading-relaxed text-[#3A4D41]">
                      {eco.example}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {tab === 'roadmap' && (
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-1 rounded-lg bg-[#EFE9DC] p-1">
              {[
                { id: 'live', label: '工程实况' },
                { id: 'pipeline', label: '五层流水线' },
                { id: 'stages', label: '准则与路线' },
              ].map((sv) => (
                <button
                  key={sv.id}
                  type="button"
                  onClick={() =>
                    setRoadmapSubView(sv.id as 'live' | 'pipeline' | 'stages')
                  }
                  className={`rounded-md px-2 py-1.5 text-xs font-semibold transition-colors ${
                    roadmapSubView === sv.id
                      ? 'bg-[#FCF9F3] text-[#1D2B22] shadow-xs'
                      : 'text-[#4B5B50] hover:text-[#1D2B22]'
                  }`}
                >
                  {sv.label}
                </button>
              ))}
            </div>

            {roadmapSubView === 'live' && (
              <div className="space-y-4">
                {/* KPI Metrics Strip */}
                <section className="rounded-lg border border-[#2D603E]/25 bg-[#EFF6F1] p-3.5">
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-1.5">
                      <ShieldCheck
                        className="h-4 w-4 text-[#2D603E]"
                        aria-hidden="true"
                      />
                      <h2 className="text-sm font-bold text-[#1D2B22]">
                        主分支实测验收总览
                      </h2>
                    </div>
                    <span className="font-mono-tabular text-[11px] font-semibold text-[#2D603E]">
                      {PROJECT_LIVE_STATUS.gitCommit}
                    </span>
                  </div>

                  <div className="mt-3 grid grid-cols-3 gap-2">
                    <div className="rounded-md bg-[#FCF9F3] px-2.5 py-2">
                      <div className="font-mono-tabular text-base font-extrabold text-[#2D603E]">
                        {PROJECT_LIVE_STATUS.rTestsPassed}
                      </div>
                      <div className="text-[10.5px] font-medium text-[#4B5B50]">
                        R testthat 全绿
                      </div>
                    </div>
                    <div className="rounded-md bg-[#FCF9F3] px-2.5 py-2">
                      <div className="font-mono-tabular text-base font-extrabold text-[#DF6A2B]">
                        {PROJECT_LIVE_STATUS.issuesClosed}/{PROJECT_LIVE_STATUS.issuesTotal}
                      </div>
                      <div className="text-[10.5px] font-medium text-[#4B5B50]">
                        v1.1 断层闭环
                      </div>
                    </div>
                    <div className="rounded-md bg-[#FCF9F3] px-2.5 py-2">
                      <div className="font-mono-tabular text-base font-extrabold text-[#315C6B]">
                        {PROJECT_LIVE_STATUS.pyWorkflowsPassed}/{PROJECT_LIVE_STATUS.pyWorkflowsTotal}
                      </div>
                      <div className="text-[10.5px] font-medium text-[#4B5B50]">
                        跨语言工作流绿
                      </div>
                    </div>
                  </div>
                </section>

                {/* 5 Architecture Guardrails */}
                <section>
                  <h3 className="text-xs font-bold text-[#1D2B22]">
                    5 项架构护栏（5 / 5 PASS）
                  </h3>
                  <div className="mt-2 space-y-1.5">
                    {PROJECT_LIVE_STATUS.guardrails.map((g) => (
                      <div
                        key={g.id}
                        className="flex items-start gap-2 rounded-lg border border-[#1D2B22]/10 bg-[#F7F3EA]/80 px-2.5 py-2"
                      >
                        <CheckCircle2
                          className="mt-0.5 h-3.5 w-3.5 shrink-0 text-[#2F855A]"
                          aria-hidden="true"
                        />
                        <div className="min-w-0 flex-1">
                          <div className="text-xs font-bold text-[#1D2B22]">
                            {g.name}
                          </div>
                          <div className="mt-0.5 text-[11px] text-[#4B5B50]">
                            {g.detail}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </section>

                {/* 23 Issues Closed across 3 Axes */}
                <section className="border-t border-[#1D2B22]/10 pt-3.5">
                  <h3 className="text-xs font-bold text-[#1D2B22]">
                    Schema v1.1.0 三大主轴 23 项收口进展
                  </h3>
                  <div className="mt-2 space-y-2">
                    {PROJECT_LIVE_STATUS.closureAxes.map((ax) => (
                      <div
                        key={ax.axis}
                        className="rounded-lg border border-[#1D2B22]/12 bg-[#FCF9F3] p-2.5"
                      >
                        <div className="flex items-center justify-between gap-2">
                          <span className="text-xs font-bold text-[#1D2B22]">
                            {ax.title}
                          </span>
                          <span className="font-mono-tabular shrink-0 rounded bg-[#E5F2E9] px-1.5 py-0.5 text-[10.5px] font-bold text-[#1F5432]">
                            {ax.closed}/{ax.total} 闭环
                          </span>
                        </div>
                        <p className="mt-1 text-[11px] leading-relaxed text-[#4B5B50]">
                          {ax.highlights}
                        </p>
                      </div>
                    ))}
                  </div>
                </section>

                {/* 6 Verified End-to-End Engineering Paths (clickable to trigger 3D!) */}
                <section className="border-t border-[#1D2B22]/10 pt-3.5">
                  <h3 className="text-xs font-bold text-[#1D2B22]">
                    6 条已打通端到端工程链路（点击联动 3D）
                  </h3>
                  <div className="mt-2 space-y-2">
                    {END_TO_END_PATHS.map((ep) => (
                      <button
                        key={ep.id}
                        type="button"
                        onClick={() =>
                          onRunScenario(ep.targetMode, ep.targetSampleId)
                        }
                        className="group w-full rounded-lg border border-[#1D2B22]/12 bg-[#F7F3EA]/80 p-2.5 text-left transition-colors hover:border-[#2D603E] hover:bg-[#EFF6F1]"
                      >
                        <div className="flex items-center justify-between gap-2">
                          <span className="text-xs font-bold text-[#1D2B22] group-hover:text-[#2D603E]">
                            0{ep.index}. {ep.title}
                          </span>
                          <Play
                            className="h-3 w-3 shrink-0 text-[#DF6A2B]"
                            aria-hidden="true"
                          />
                        </div>
                        <div className="font-mono-tabular mt-1 text-[10.5px] text-[#2D603E]">
                          {ep.flow}
                        </div>
                        <p className="mt-1 text-[11px] leading-relaxed text-[#4B5B50]">
                          {ep.capability}
                        </p>
                      </button>
                    ))}
                  </div>
                </section>
              </div>
            )}

            {roadmapSubView === 'pipeline' && (
              <div className="space-y-3.5">
                <div>
                  <h2 className="text-sm font-bold text-[#1D2B22]">
                    单次捕获与五层整备流水线
                  </h2>
                  <p className="mt-1 text-xs leading-relaxed text-[#4B5B50]">
                    Asset Map、Asset Bundle、双 SVG 与 144 dpi preview.png 共享同一次冻结捕获态，绝不二次重绘。点击下方任一步骤在左侧 3D 中高亮对应层级。
                  </p>
                </div>

                <div className="space-y-2.5">
                  {PIPELINE_STEPS.map((item) => {
                    const isSelected = activePipelineStep === item.step;
                    return (
                      <button
                        key={item.step}
                        type="button"
                        onClick={() => onSelectPipelineStep(item.step)}
                        className={`w-full rounded-lg border p-3 text-left transition-colors ${
                          isSelected
                            ? 'border-[#DF6A2B] bg-[#FBF4EC]'
                            : 'border-[#1D2B22]/12 bg-[#F7F3EA]/70 hover:border-[#2D603E]/50'
                        }`}
                      >
                        <div className="flex items-baseline justify-between gap-2">
                          <span className="text-xs font-bold text-[#1D2B22]">
                            0{item.step}. {item.titleZh}
                          </span>
                          <span className="font-mono-tabular shrink-0 text-[10.5px] text-[#2D603E]">
                            {item.rSource}
                          </span>
                        </div>
                        <p className="mt-1 text-xs leading-relaxed text-[#3A4D41]">
                          {item.summary}
                        </p>
                        {isSelected && (
                          <div className="mt-2.5 border-t border-[#1D2B22]/10 pt-2">
                            <p className="text-[11px] leading-relaxed text-[#4B5B50]">
                              {item.detail}
                            </p>
                            <div className="font-mono-tabular mt-1.5 text-[11px] text-[#2D603E]">
                              产出：{item.outputArtifacts.join(' · ')}
                            </div>
                          </div>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {roadmapSubView === 'stages' && (
              <div className="space-y-5">
                {/* 5 Core Design Principles (AGENTS.md) */}
                <section>
                  <h2 className="text-sm font-bold text-[#1D2B22]">
                    五大核心架构准则（AGENTS.md）
                  </h2>
                  <div className="mt-2.5 space-y-2">
                    {DESIGN_PRINCIPLES.map((p, idx) => (
                      <div
                        key={p.id}
                        className="rounded-lg border border-[#1D2B22]/10 bg-[#F7F3EA]/80 p-3"
                      >
                        <div className="flex items-baseline justify-between gap-2">
                          <span className="text-xs font-bold text-[#2D603E]">
                            0{idx + 1}. {p.titleZh}
                          </span>
                          <span className="font-mono-tabular shrink-0 text-[10.5px] text-[#5B6A60]">
                            {p.titleEn}
                          </span>
                        </div>
                        <p className="mt-1 text-xs leading-relaxed text-[#3A4D41]">
                          {p.summary}
                        </p>
                      </div>
                    ))}
                  </div>
                </section>

                {/* 4 Progressive Engineering Stages with Live Completion Status */}
                <section className="border-t border-[#1D2B22]/10 pt-4">
                  <h2 className="text-sm font-bold text-[#1D2B22]">
                    四阶段演进路线与剩余拼图
                  </h2>
                  <p className="mt-1 text-xs text-[#4B5B50]">
                    阶段 1–3 与 Schema v1.1.0 已全部收口绿灯；阶段 4 聚焦外围 GUI 交互壳层、活体会话 MCP 与真实论文 Evals。
                  </p>

                  <div className="mt-3 space-y-3">
                    {ROADMAP_STAGES.map((st) => (
                      <div
                        key={st.stage}
                        className={`rounded-lg border p-3 ${
                          st.status === 'done'
                            ? 'border-[#2D603E]/22 bg-[#FCF9F3]'
                            : 'border-[#315C6B]/28 bg-[#F2F7F9]'
                        }`}
                      >
                        <div className="flex items-center justify-between gap-2">
                          <h3 className="text-xs font-bold text-[#1D2B22]">
                            阶段 {st.stage} · {st.title}
                          </h3>
                          <span
                            className={`inline-flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                              st.status === 'done'
                                ? 'bg-[#E5F2E9] text-[#1F5432]'
                                : 'bg-[#E2EDF2] text-[#274B58]'
                            }`}
                          >
                            {st.status === 'done' ? (
                              <>
                                <CheckCircle2 className="h-3 w-3" aria-hidden="true" />
                                <span>已达成</span>
                              </>
                            ) : (
                              <>
                                <Clock className="h-3 w-3" aria-hidden="true" />
                                <span>下一阶段</span>
                              </>
                            )}
                          </span>
                        </div>
                        <p className="mt-1 text-[11px] font-medium text-[#DF6A2B]">
                          {st.positioning}
                        </p>
                        <ul className="mt-2 space-y-1 text-xs text-[#3A4D41]">
                          {st.deliverables.map((d) => (
                            <li key={d} className="leading-relaxed">
                              · {d}
                            </li>
                          ))}
                        </ul>
                        <div className="mt-2 border-t border-[#1D2B22]/8 pt-1.5 text-[11px] text-[#2D603E]">
                          验收：{st.acceptance}
                        </div>
                      </div>
                    ))}
                  </div>
                </section>
              </div>
            )}
          </div>
        )}
      </div>
    </aside>
  );
}
