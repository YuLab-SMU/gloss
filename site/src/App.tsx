import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ARCHITECTURE_LAYERS,
  getPipelineHighlightLayers,
  type AssetNodeId,
  type DrawerTab,
  type LayerId,
} from './data/glossModel';
import {
  LAYER_ORDER,
  type CameraPresetId,
  type LayoutMode,
} from './scene/layoutMath';
import { MAPPING_MODES, type MappingFocusMode } from './scene/mappingPaths';
import { GlossViewport3D } from './components/GlossViewport3D';
import { TopBar } from './components/TopBar';
import { BottomControlDock } from './components/BottomControlDock';
import { ArchitectureDrawer } from './components/ArchitectureDrawer';

export default function App() {
  const [explode, setExplode] = useState<number>(0.88);
  const [layerOffset, setLayerOffset] = useState<number>(0.3);
  const [layoutMode, setLayoutMode] = useState<LayoutMode>('stacked');
  const [flowPlaying, setFlowPlaying] = useState<boolean>(true);
  const [mappingMode, setMappingMode] = useState<MappingFocusMode>('overview');
  const [focusLayer, setFocusLayer] = useState<LayerId | null>(null);
  const [focusAsset, setFocusAsset] = useState<AssetNodeId | null>(null);
  const [tracedSampleId, setTracedSampleId] = useState<string | null>(null);
  const [cameraPreset, setCameraPreset] = useState<CameraPresetId>('isometric');
  const [cameraRevision, setCameraRevision] = useState<number>(0);
  const [showLabels, setShowLabels] = useState<boolean>(true);
  const [dockCollapsed, setDockCollapsed] = useState<boolean>(false);
  const [drawerOpen, setDrawerOpen] = useState<boolean>(false);
  const [drawerTab, setDrawerTab] = useState<DrawerTab>('contract');
  const [activePipelineStep, setActivePipelineStep] = useState<number | null>(
    null,
  );

  const highlightLayers = useMemo<LayerId[]>(() => {
    if (drawerOpen && drawerTab === 'roadmap' && activePipelineStep !== null) {
      return getPipelineHighlightLayers(activePipelineStep);
    }
    return [];
  }, [drawerOpen, drawerTab, activePipelineStep]);

  const activeModeSpec = useMemo(
    () => MAPPING_MODES.find((m) => m.id === mappingMode) ?? MAPPING_MODES[0],
    [mappingMode],
  );

  const focusedLayerSpec = useMemo(
    () =>
      focusLayer
        ? ARCHITECTURE_LAYERS.find((l) => l.id === focusLayer) ?? null
        : null,
    [focusLayer],
  );

  const activeNav: 'spatial' | DrawerTab = drawerOpen ? drawerTab : 'spatial';

  const handleChangeExplode = useCallback((value: number) => {
    setExplode(value);
    if (value > 0.02) {
      setLayoutMode((prev) => {
        if (prev === 'tiled') {
          setCameraPreset('isometric');
          setCameraRevision((r) => r + 1);
          return 'stacked';
        }
        return prev;
      });
    }
  }, []);

  const handleChangeLayerOffset = useCallback((value: number) => {
    setLayerOffset(value);
    if (value > 0.02) {
      setLayoutMode((prev) => {
        if (prev === 'tiled') {
          setExplode((e) => (e < 0.4 ? 0.88 : e));
          setCameraPreset('isometric');
          setCameraRevision((r) => r + 1);
          return 'stacked';
        }
        return prev;
      });
    }
  }, []);

  const handleSelectMappingMode = useCallback(
    (mode: MappingFocusMode) => {
      setMappingMode(mode);
      setFocusLayer(null);
      setFocusAsset(null);
      setActivePipelineStep(null);
      if (mode !== 'point-lineage' && mode !== 'overview') {
        setTracedSampleId(null);
      }
      if (layoutMode === 'stacked') {
        setExplode((prev) => (prev < 0.78 ? 0.88 : prev));
        if (mode === 'panel-grid') {
          setLayerOffset(0);
        } else if (mode === 'overview') {
          setLayerOffset((prev) => (prev === 0 ? 0.3 : prev));
        }
        setCameraPreset('isometric');
      } else {
        setCameraPreset('tiled');
      }
      setFlowPlaying(true);
      setCameraRevision((r) => r + 1);
    },
    [layoutMode],
  );

  const handleRunScenario = useCallback(
    (mode: MappingFocusMode, sampleId: string | null) => {
      setMappingMode(mode);
      setTracedSampleId(sampleId);
      setFocusLayer(null);
      setFocusAsset(null);
      setActivePipelineStep(null);
      if (layoutMode === 'stacked') {
        setExplode((prev) => (prev < 0.85 ? 0.88 : prev));
        setLayerOffset(mode === 'panel-grid' ? 0 : 0.3);
        setCameraPreset('isometric');
      } else {
        setCameraPreset('tiled');
      }
      setFlowPlaying(true);
      setCameraRevision((r) => r + 1);
    },
    [layoutMode],
  );

  const handleSelectNav = useCallback(
    (nav: 'spatial' | DrawerTab) => {
      if (nav === 'spatial') {
        setDrawerOpen(false);
        setActivePipelineStep(null);
        setFocusAsset(null);
        setCameraPreset(layoutMode === 'tiled' ? 'tiled' : 'isometric');
        setCameraRevision((r) => r + 1);
        return;
      }
      setDrawerTab(nav);
      setDrawerOpen(true);
      if (nav === 'contract') {
        setFocusLayer(null);
        setFocusAsset(null);
        setActivePipelineStep(null);
        if (layoutMode === 'stacked') {
          setExplode((prev) => (prev < 0.8 ? 0.88 : prev));
          setCameraPreset('isometric');
        }
        setCameraRevision((r) => r + 1);
      } else if (nav === 'assets') {
        setFocusLayer(null);
        setActivePipelineStep(null);
        setTracedSampleId(null);
        setMappingMode('asset-export');
        setCameraPreset(layoutMode === 'tiled' ? 'tiled' : 'assets');
        setCameraRevision((r) => r + 1);
      } else if (nav === 'roadmap') {
        setFocusLayer(null);
        setFocusAsset(null);
        setActivePipelineStep(null);
        if (layoutMode === 'stacked') {
          setExplode(0.88);
          setCameraPreset('isometric');
        }
        setCameraRevision((r) => r + 1);
      }
    },
    [layoutMode],
  );

  const handleResetView = useCallback(() => {
    setLayoutMode('stacked');
    setMappingMode('overview');
    setFocusLayer(null);
    setFocusAsset(null);
    setActivePipelineStep(null);
    setTracedSampleId(null);
    setExplode(0.88);
    setLayerOffset(0.3);
    setFlowPlaying(true);
    setCameraPreset('isometric');
    setCameraRevision((r) => r + 1);
  }, []);

  const handleSelectLayerFrom3D = useCallback((id: LayerId) => {
    setFocusAsset(null);
    setActivePipelineStep(null);
    setFocusLayer(id);
    setDrawerTab('inspector');
    setDrawerOpen(true);
    setCameraRevision((r) => r + 1);
  }, []);

  const handleSelectLayerFromDock = useCallback((id: LayerId | null) => {
    setFocusAsset(null);
    setActivePipelineStep(null);
    setFocusLayer(id);
    if (id !== null) {
      setDrawerTab('inspector');
    }
    setCameraRevision((r) => r + 1);
  }, []);

  const handleSelectSampleFrom3D = useCallback(
    (sampleId: string) => {
      setTracedSampleId(sampleId);
      setMappingMode('point-lineage');
      setFocusLayer(null);
      setFocusAsset(null);
      setActivePipelineStep(null);
      if (layoutMode === 'stacked') {
        setExplode((prev) => (prev < 0.78 ? 0.88 : prev));
        setCameraPreset('isometric');
      } else {
        setCameraPreset('tiled');
      }
      setFlowPlaying(true);
      setDrawerTab('inspector');
      setDrawerOpen(true);
      setCameraRevision((r) => r + 1);
    },
    [layoutMode],
  );

  const handleSelectSampleFromDock = useCallback(
    (sampleId: string | null) => {
      setTracedSampleId(sampleId);
      if (sampleId) {
        setMappingMode('point-lineage');
        setFocusLayer(null);
        setFocusAsset(null);
        setActivePipelineStep(null);
        if (layoutMode === 'stacked') {
          setExplode((prev) => (prev < 0.78 ? 0.88 : prev));
          setCameraPreset('isometric');
        } else {
          setCameraPreset('tiled');
        }
        setFlowPlaying(true);
        setCameraRevision((r) => r + 1);
      }
    },
    [layoutMode],
  );

  const handleSelectAsset = useCallback((assetId: AssetNodeId) => {
    setMappingMode('asset-export');
    setFocusLayer(null);
    setActivePipelineStep(null);
    setTracedSampleId(null);
    setFocusAsset(assetId);
    setDrawerTab('inspector');
    setDrawerOpen(true);
    setCameraRevision((r) => r + 1);
  }, []);

  const handleSelectCameraPreset = useCallback((preset: CameraPresetId) => {
    setFocusLayer(null);
    setFocusAsset(null);
    setCameraPreset(preset);
    if (preset === 'tiled') {
      // Flat-tiled blueprint spread: vertical layer spacing = 0, auto-arranged 3x2 grid with arched routes
      setLayoutMode('tiled');
      setExplode(0);
      setLayerOffset(0);
    } else {
      setLayoutMode('stacked');
      if (preset === 'top') {
        setExplode(0.05);
        setLayerOffset(0);
      } else if (preset === 'side') {
        setExplode((prev) => (prev < 0.45 ? 0.88 : prev));
        setLayerOffset(0);
      } else if (preset === 'isometric') {
        setExplode((prev) => (prev < 0.45 ? 0.88 : prev));
        setLayerOffset((prev) => (prev === 0 ? 0.3 : prev));
      }
    }
    setCameraRevision((r) => r + 1);
  }, []);

  const handleSelectPipelineStep = useCallback(
    (step: number) => {
      setActivePipelineStep(step);
      setFocusLayer(null);
      setFocusAsset(null);
      if (layoutMode === 'stacked') {
        setExplode(0.9);
      }
    },
    [layoutMode],
  );

  const handleToggleDrawerFromDock = useCallback(() => {
    setDrawerOpen((prev) => {
      if (!prev) {
        setDrawerTab('contract');
        return true;
      }
      setActivePipelineStep(null);
      return false;
    });
  }, []);

  // Keyboard shortcuts: H toggles dock, T toggles tiled/stacked, 1-6 focus layers, 0 clears focus, R resets, Escape closes
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (
        e.target instanceof HTMLInputElement ||
        e.target instanceof HTMLTextAreaElement
      ) {
        return;
      }
      if (e.key === 'h' || e.key === 'H') {
        setDockCollapsed((prev) => !prev);
      } else if (e.key === 't' || e.key === 'T') {
        handleSelectCameraPreset(layoutMode === 'tiled' ? 'isometric' : 'tiled');
      } else if (e.key === 'r' || e.key === 'R') {
        handleResetView();
      } else if (e.key === 'Escape') {
        setDrawerOpen(false);
        setFocusLayer(null);
        setFocusAsset(null);
        setActivePipelineStep(null);
      } else if (e.key >= '1' && e.key <= '6') {
        const idx = Number(e.key) - 1;
        const layerId = LAYER_ORDER[idx];
        if (layerId) handleSelectLayerFromDock(layerId);
      } else if (e.key === '0') {
        handleSelectLayerFromDock(null);
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [
    layoutMode,
    handleSelectCameraPreset,
    handleResetView,
    handleSelectLayerFromDock,
  ]);

  return (
    <main
      className="relative h-screen w-screen overflow-hidden bg-[#F4EFE5] text-[#1D2B22]"
      data-layout-mode={layoutMode}
      data-mapping-mode={mappingMode}
      data-active-layer={focusLayer ?? 'all'}
      data-active-asset={focusAsset ?? 'none'}
      data-explode={Math.round(explode * 100)}
      data-layer-offset={Math.round(layerOffset * 100)}
      data-flow-playing={flowPlaying ? 'true' : 'false'}
      data-traced-sample={tracedSampleId ?? 'none'}
      data-drawer-open={drawerOpen ? 'true' : 'false'}
      data-dock-collapsed={dockCollapsed ? 'true' : 'false'}
    >
      {/* Top 3-Zone Navigation Bar */}
      <TopBar
        activeNav={activeNav}
        onSelectNav={handleSelectNav}
        onResetView={handleResetView}
      />

      {/* Full-Viewport 3D Architecture Scene */}
      <div className="h-full w-full pt-14">
        <GlossViewport3D
          explode={explode}
          layerOffset={layerOffset}
          layoutMode={layoutMode}
          flowPlaying={flowPlaying}
          mappingMode={mappingMode}
          focusLayer={focusLayer}
          focusAsset={focusAsset}
          highlightLayers={highlightLayers}
          tracedSampleId={tracedSampleId}
          cameraPreset={cameraPreset}
          cameraRevision={cameraRevision}
          showLabels={showLabels}
          drawerOpen={drawerOpen}
          onSelectLayer={handleSelectLayerFrom3D}
          onSelectSample={handleSelectSampleFrom3D}
          onSelectAsset={handleSelectAsset}
        />
      </div>

      {/* Subtle Top-Left Minimal Architectural Context Caption */}
      {!dockCollapsed && (
        <div className="pointer-events-none fixed left-5 top-[70px] z-10 hidden max-w-[420px] sm:block">
          <div className="text-xs font-semibold text-[#2D603E]">
            {focusedLayerSpec
              ? `${layoutMode === 'tiled' ? '平铺单层定位' : '单层抽拉聚焦'}：0${focusedLayerSpec.stepNumber} ${focusedLayerSpec.titleZh}`
              : layoutMode === 'tiled'
                ? `平铺总览（层间距 0%）· ${activeModeSpec.label}`
                : `${activeModeSpec.title} · ${activeModeSpec.glueTag}`}
          </div>
          <p className="mt-0.5 text-[11px] leading-relaxed text-[#526358]">
            {focusedLayerSpec
              ? focusedLayerSpec.svgPainPoint
              : layoutMode === 'tiled'
                ? '3×2 同平面展开（01→02→03 / 04→05→06）+ 中央走廊分层拱桥自动避让连线'
                : activeModeSpec.formula}
          </p>
        </div>
      )}

      {/* On-Demand Right Architecture Specification Drawer (Closed by default) */}
      <ArchitectureDrawer
        open={drawerOpen}
        tab={drawerTab}
        onChangeTab={(nextTab) => {
          setDrawerTab(nextTab);
          if (nextTab !== 'roadmap') {
            setActivePipelineStep(null);
          }
        }}
        onClose={() => {
          setDrawerOpen(false);
          setActivePipelineStep(null);
        }}
        mappingMode={mappingMode}
        onSelectMappingMode={handleSelectMappingMode}
        onRunScenario={handleRunScenario}
        focusLayer={focusLayer}
        onSelectLayer={(id) => {
          setFocusLayer(id);
          setFocusAsset(null);
          setDrawerTab('inspector');
          setCameraRevision((r) => r + 1);
        }}
        focusAsset={focusAsset}
        tracedSampleId={tracedSampleId}
        activePipelineStep={activePipelineStep}
        onSelectPipelineStep={handleSelectPipelineStep}
      />

      {/* Collapsible Unified Bottom Control Dock */}
      <BottomControlDock
        explode={explode}
        onChangeExplode={handleChangeExplode}
        layerOffset={layerOffset}
        onChangeLayerOffset={handleChangeLayerOffset}
        flowPlaying={flowPlaying}
        onToggleFlowPlaying={() => setFlowPlaying((prev) => !prev)}
        focusLayer={focusLayer}
        onSelectFocusLayer={handleSelectLayerFromDock}
        mappingMode={mappingMode}
        onSelectMappingMode={handleSelectMappingMode}
        tracedSampleId={tracedSampleId}
        onSelectSample={handleSelectSampleFromDock}
        cameraPreset={cameraPreset}
        onSelectCameraPreset={handleSelectCameraPreset}
        showLabels={showLabels}
        onToggleLabels={() => setShowLabels((prev) => !prev)}
        drawerOpen={drawerOpen}
        onToggleDrawer={handleToggleDrawerFromDock}
        collapsed={dockCollapsed}
        onToggleCollapsed={() => setDockCollapsed((prev) => !prev)}
      />
    </main>
  );
}
