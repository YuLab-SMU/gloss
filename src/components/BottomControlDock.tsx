import {
  ChevronDown,
  ChevronUp,
  Eye,
  EyeOff,
  FileCode2,
  Pause,
  Play,
} from 'lucide-react';
import {
  ARCHITECTURE_LAYERS,
  traceSampleLineage,
  type LayerId,
} from '../data/glossModel';
import type { CameraPresetId } from '../scene/layoutMath';
import { MAPPING_MODES, type MappingFocusMode } from '../scene/mappingPaths';

export interface BottomControlDockProps {
  explode: number;
  onChangeExplode: (value: number) => void;
  layerOffset: number;
  onChangeLayerOffset: (value: number) => void;
  flowPlaying: boolean;
  onToggleFlowPlaying: () => void;
  focusLayer: LayerId | null;
  onSelectFocusLayer: (id: LayerId | null) => void;
  mappingMode: MappingFocusMode;
  onSelectMappingMode: (mode: MappingFocusMode) => void;
  tracedSampleId: string | null;
  onSelectSample: (sampleId: string | null) => void;
  cameraPreset: CameraPresetId;
  onSelectCameraPreset: (preset: CameraPresetId) => void;
  showLabels: boolean;
  onToggleLabels: () => void;
  drawerOpen: boolean;
  onToggleDrawer: () => void;
  collapsed: boolean;
  onToggleCollapsed: () => void;
}

const FEATURED_SAMPLES = [
  { id: 'S1', label: 'S1' },
  { id: 'S14', label: 'S14' },
  { id: 'S19', label: 'S19' },
];

const CAMERA_PRESETS: { id: CameraPresetId; label: string }[] = [
  { id: 'isometric', label: '等轴' },
  { id: 'tiled', label: '平铺' },
  { id: 'top', label: '合图' },
  { id: 'side', label: '剖面' },
];

export function BottomControlDock({
  explode,
  onChangeExplode,
  layerOffset,
  onChangeLayerOffset,
  flowPlaying,
  onToggleFlowPlaying,
  focusLayer,
  onSelectFocusLayer,
  mappingMode,
  onSelectMappingMode,
  tracedSampleId,
  onSelectSample,
  cameraPreset,
  onSelectCameraPreset,
  showLabels,
  onToggleLabels,
  drawerOpen,
  onToggleDrawer,
  collapsed,
  onToggleCollapsed,
}: BottomControlDockProps) {
  const trace = tracedSampleId ? traceSampleLineage(tracedSampleId) : null;
  const activeModeSpec =
    MAPPING_MODES.find((m) => m.id === mappingMode) ?? MAPPING_MODES[0];
  const focusedLayerSpec = focusLayer
    ? ARCHITECTURE_LAYERS.find((l) => l.id === focusLayer) ?? null
    : null;
  const explodePct = Math.round(explode * 100);
  const offsetPct = Math.round(layerOffset * 100);

  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-0 z-30 flex flex-col items-center px-3 pb-3 sm:pb-4">
      {/* Attached Collapse / Expand Handle */}
      <button
        type="button"
        onClick={onToggleCollapsed}
        aria-expanded={!collapsed}
        aria-label={collapsed ? '展开底部控制栏' : '收起底部控制栏'}
        className="pointer-events-auto mb-1.5 flex items-center gap-1.5 rounded-t-lg border border-[#1D2B22]/14 bg-[#FCF9F3] px-3.5 py-1 text-xs font-medium text-[#3A4D41] shadow-sm transition-colors duration-150 hover:text-[#1D2B22] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#2D603E]"
      >
        {collapsed ? (
          <>
            <ChevronUp className="h-3.5 w-3.5" aria-hidden="true" />
            <span>展开控制栏</span>
          </>
        ) : (
          <>
            <ChevronDown className="h-3.5 w-3.5" aria-hidden="true" />
            <span>收起控制栏</span>
          </>
        )}
      </button>

      {/* Collapsible Unified Horizontal Dock */}
      <section
        aria-label="3D 架构映射控制栏"
        className={`pointer-events-auto w-full max-w-[1220px] rounded-xl border border-[#1D2B22]/14 bg-[#FCF9F3] px-4 py-2.5 shadow-lg transition-transform duration-200 ease-out ${
          collapsed
            ? 'pointer-events-none hidden translate-y-[125%] opacity-0'
            : 'translate-y-0 opacity-100'
        }`}
      >
        {/* Row 1: Vertical Spacing | Waterfall Stagger Offset | 5 Glue-Code Mapping Modes | Camera Presets */}
        <div className="flex flex-wrap items-center justify-between gap-2.5 lg:flex-nowrap">
          <div className="flex shrink-0 flex-wrap items-center gap-3">
            {/* Exploded Spacing Slider */}
            <div className="flex items-center gap-1.5">
              <label
                htmlFor="explode-slider"
                className="whitespace-nowrap text-xs font-semibold text-[#1D2B22]"
              >
                层间距
              </label>
              <input
                id="explode-slider"
                type="range"
                min={0}
                max={100}
                step={1}
                value={explodePct}
                onChange={(e) => onChangeExplode(Number(e.target.value) / 100)}
                className="gloss-slider w-16 sm:w-20"
              />
              <span className="font-mono-tabular w-8 text-right text-xs font-semibold text-[#2D603E]">
                {explodePct}%
              </span>
            </div>

            {/* Stagger / Waterfall Offset Slider */}
            <div className="flex items-center gap-1.5">
              <label
                htmlFor="offset-slider"
                className="whitespace-nowrap text-xs font-semibold text-[#1D2B22]"
              >
                层偏移
              </label>
              <input
                id="offset-slider"
                type="range"
                min={0}
                max={100}
                step={1}
                value={offsetPct}
                onChange={(e) => onChangeLayerOffset(Number(e.target.value) / 100)}
                className="gloss-slider w-16 sm:w-20"
              />
              <span className="font-mono-tabular w-8 text-right text-xs font-semibold text-[#DF6A2B]">
                {offsetPct}%
              </span>
            </div>
          </div>

          {/* 5 Glue-Code & Semantic Mapping Views */}
          <div
            role="group"
            aria-label="粘合编码三维映射模式"
            className="flex flex-wrap items-center gap-0.5 rounded-lg bg-[#EFE9DC] p-1"
          >
            {MAPPING_MODES.map((mode) => {
              const active = mappingMode === mode.id && focusLayer === null;
              return (
                <button
                  key={mode.id}
                  type="button"
                  aria-pressed={active}
                  onClick={() => onSelectMappingMode(mode.id)}
                  className={`whitespace-nowrap rounded-md px-2.5 py-1 text-xs font-medium transition-colors ${
                    active
                      ? 'bg-[#2D603E] text-[#FCF9F3] shadow-xs'
                      : 'text-[#3A4D41] hover:bg-[#FCF9F3]/75 hover:text-[#1D2B22]'
                  }`}
                >
                  {mode.label}
                </button>
              );
            })}
          </div>

          {/* Camera Angle Presets */}
          <div
            role="group"
            aria-label="镜头视角预设"
            className="flex shrink-0 items-center gap-0.5 rounded-lg bg-[#EFE9DC] p-1"
          >
            {CAMERA_PRESETS.map((preset) => {
              const active = cameraPreset === preset.id && focusLayer === null;
              return (
                <button
                  key={preset.id}
                  type="button"
                  onClick={() => onSelectCameraPreset(preset.id)}
                  className={`whitespace-nowrap rounded-md px-2 py-1 text-xs font-medium transition-colors ${
                    active
                      ? 'bg-[#FCF9F3] text-[#1D2B22] shadow-xs'
                      : 'text-[#4B5B50] hover:text-[#1D2B22]'
                  }`}
                >
                  {preset.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Hairline Divider */}
        <div className="my-2 h-px w-full bg-[#1D2B22]/10" />

        {/* Row 2: Single-Layer Drawer Pull-Out Focus | Sample Tracer | Live Status | Utility Actions */}
        <div className="flex flex-wrap items-center justify-between gap-2.5 lg:flex-nowrap">
          <div className="flex min-w-0 flex-1 flex-wrap items-center gap-2 lg:flex-nowrap">
            {/* Single-Layer Pull-Out Focus Selector */}
            <div className="flex shrink-0 items-center gap-1.5">
              <span className="whitespace-nowrap text-xs font-semibold text-[#1D2B22]">
                抽拉聚焦
              </span>
              <div
                role="group"
                aria-label="单层抽拉聚焦"
                className="flex items-center gap-0.5 rounded-lg bg-[#EFE9DC] p-0.5"
              >
                <button
                  type="button"
                  aria-pressed={focusLayer === null}
                  onClick={() => onSelectFocusLayer(null)}
                  className={`whitespace-nowrap rounded-md px-2 py-0.5 text-xs font-medium transition-colors ${
                    focusLayer === null
                      ? 'bg-[#2D603E] text-[#FCF9F3]'
                      : 'text-[#3A4D41] hover:text-[#1D2B22]'
                  }`}
                >
                  全部
                </button>
                {ARCHITECTURE_LAYERS.map((layer) => {
                  const active = focusLayer === layer.id;
                  return (
                    <button
                      key={layer.id}
                      type="button"
                      aria-pressed={active}
                      aria-label={`抽拉聚焦第 ${layer.stepNumber} 层：${layer.titleZh}`}
                      title={`0${layer.stepNumber} ${layer.titleZh}`}
                      onClick={() => onSelectFocusLayer(active ? null : layer.id)}
                      className={`font-mono-tabular whitespace-nowrap rounded-md px-1.5 py-0.5 text-xs font-semibold transition-colors ${
                        active
                          ? 'bg-[#DF6A2B] text-[#FCF9F3]'
                          : 'text-[#3A4D41] hover:bg-[#FCF9F3]/80 hover:text-[#1D2B22]'
                      }`}
                    >
                      0{layer.stepNumber}
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="hidden h-4 w-px shrink-0 bg-[#1D2B22]/12 lg:block" />

            {/* Sample Lineage Tracer */}
            <div className="flex shrink-0 items-center gap-1">
              <span className="whitespace-nowrap text-xs font-semibold text-[#4B5B50]">
                单点
              </span>
              {FEATURED_SAMPLES.map((item) => {
                const active = tracedSampleId === item.id;
                return (
                  <button
                    key={item.id}
                    type="button"
                    aria-pressed={active}
                    onClick={() => onSelectSample(active ? null : item.id)}
                    className={`font-mono-tabular whitespace-nowrap rounded-md border px-2 py-0.5 text-xs font-semibold transition-colors ${
                      active
                        ? 'border-[#DF6A2B] bg-[#DF6A2B] text-[#FCF9F3]'
                        : 'border-[#1D2B22]/14 bg-[#F7F3EA] text-[#2C3E33] hover:border-[#2D603E]'
                    }`}
                  >
                    {item.label}
                  </button>
                );
              })}
              {tracedSampleId && (
                <button
                  type="button"
                  onClick={() => onSelectSample(null)}
                  className="whitespace-nowrap px-1 py-0.5 text-xs font-medium text-[#5B6A60] underline-offset-2 hover:text-[#1D2B22] hover:underline"
                >
                  清除
                </button>
              )}
            </div>

            {/* Clean unboxed live focus / lineage / formula readout */}
            {focusedLayerSpec ? (
              <div
                aria-live="polite"
                className="min-w-0 truncate text-xs text-[#33463A]"
                title={`已抽拉聚焦第 0${focusedLayerSpec.stepNumber} 层：${focusedLayerSpec.titleZh} — ${focusedLayerSpec.tagline}`}
              >
                <span className="font-semibold text-[#DF6A2B]">
                  0{focusedLayerSpec.stepNumber} {focusedLayerSpec.titleZh}
                </span>
                <span className="mx-1.5 text-[#1D2B22]/25" aria-hidden="true">
                  ·
                </span>
                <span className="font-mono-tabular text-[11px] text-[#2D603E]">
                  {focusedLayerSpec.rModules[0]}
                </span>
                <span className="mx-1.5 text-[#1D2B22]/25" aria-hidden="true">
                  ·
                </span>
                <span>{focusedLayerSpec.tagline}</span>
              </div>
            ) : trace ? (
              <div
                aria-live="polite"
                className="font-mono-tabular flex min-w-0 items-center gap-1.5 truncate text-xs text-[#33463A]"
              >
                <span className="font-bold text-[#1D2B22]">
                  {trace.sample.id} ({trace.sample.patientId})
                </span>
                <span aria-hidden="true">·</span>
                <span>_raw_row_id={trace.sample.rowId}</span>
                <span aria-hidden="true">·</span>
                <span
                  style={{ color: trace.sample.colorHex }}
                  className="font-semibold"
                >
                  {trace.sample.elementId} / {trace.sample.leafId}
                </span>
                <span aria-hidden="true">·</span>
                <span className="text-[#2D603E]">[geometry_locked]</span>
              </div>
            ) : (
              <div
                aria-live="polite"
                className="font-mono-tabular min-w-0 truncate text-xs text-[#4B5B50]"
                title={activeModeSpec.formula}
              >
                {activeModeSpec.formula}
              </div>
            )}
          </div>

          <div className="flex shrink-0 items-center gap-1.5">
            <button
              type="button"
              onClick={onToggleFlowPlaying}
              aria-pressed={flowPlaying}
              aria-label={flowPlaying ? '暂停动态信息流' : '开启动态信息流'}
              className={`flex items-center gap-1 whitespace-nowrap rounded-md border px-2 py-1 text-xs font-medium transition-colors ${
                flowPlaying
                  ? 'border-[#2D603E]/35 bg-[#EEF5F0] text-[#234F33] hover:border-[#2D603E]'
                  : 'border-[#1D2B22]/14 bg-[#F7F3EA] text-[#4B5B50] hover:border-[#2D603E]'
              }`}
            >
              {flowPlaying ? (
                <Pause className="h-3.5 w-3.5" aria-hidden="true" />
              ) : (
                <Play className="h-3.5 w-3.5" aria-hidden="true" />
              )}
              <span>{flowPlaying ? '流动中' : '已暂停'}</span>
            </button>

            <button
              type="button"
              onClick={onToggleLabels}
              aria-pressed={showLabels}
              className="flex items-center gap-1 whitespace-nowrap rounded-md border border-[#1D2B22]/14 bg-[#F7F3EA] px-2 py-1 text-xs font-medium text-[#2C3E33] transition-colors hover:border-[#2D603E]"
            >
              {showLabels ? (
                <Eye className="h-3.5 w-3.5" aria-hidden="true" />
              ) : (
                <EyeOff className="h-3.5 w-3.5" aria-hidden="true" />
              )}
              <span>{showLabels ? '标注' : '无标'}</span>
            </button>

            <button
              type="button"
              onClick={onToggleDrawer}
              aria-expanded={drawerOpen}
              className={`flex items-center gap-1.5 whitespace-nowrap rounded-md border px-2.5 py-1 text-xs font-semibold transition-colors ${
                drawerOpen
                  ? 'border-[#2D603E] bg-[#2D603E] text-[#FCF9F3]'
                  : 'border-[#2D603E]/40 bg-[#FCF9F3] text-[#2D603E] hover:bg-[#2D603E] hover:text-[#FCF9F3]'
              }`}
            >
              <FileCode2 className="h-3.5 w-3.5" aria-hidden="true" />
              <span>{drawerOpen ? '关闭契约' : '四层契约'}</span>
            </button>
          </div>
        </div>
      </section>
    </div>
  );
}
