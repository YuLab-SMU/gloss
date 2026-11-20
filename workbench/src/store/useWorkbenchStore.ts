import { create } from "zustand";
import {
  buildSpatialIndex,
  computeStageStats,
  decodeArtifactText,
  decodeEmbeddedJsonText,
  decodeFileMap,
  SEMANTIC_STAGES,
  type FocusScope,
  type GlossBundle,
  type OutlineViewMode,
  type ReaderLens,
  type SemanticStageId,
  type SpatialIndex,
  type StageStatusSummary,
  type WorkbenchViewMode,
} from "../codec";

export type WorkbenchTheme = "paper" | "obsidian";
export type LeftPanelTab = "structure" | "context" | "code" | "exports";
export type RightPanelTab = "chain" | "records" | "lineage";

export interface HighlightedGroup {
  label: string;
  reason?: string;
  status?: string;
  elementIds: string[];
}

export interface WorkbenchConfig {
  view?: WorkbenchViewMode;
  theme?: WorkbenchTheme;
  initialStage?: SemanticStageId;
  title?: string;
  riveAssets?: {
    stageRail?: string;
    verifySeal?: string;
    dropzone?: string;
  };
}

interface WorkbenchState {
  bundle: GlossBundle | null;
  spatial: SpatialIndex | null;
  stageStats: Record<SemanticStageId, StageStatusSummary> | null;
  loading: boolean;
  error: string | null;

  liveApiBaseUrl: string | null;
  proposalModalOpen: boolean;

  viewMode: WorkbenchViewMode;
  readerLens: ReaderLens;
  cleanFigure: boolean;
  walkthroughOpen: boolean;
  storyStepIdx: number;
  activeStage: SemanticStageId;
  selectedElementIds: string[];
  hoveredElementId: string | null;
  selectedRecordId: string | null;
  selectedLeafId: string | null;
  selectedPanelId: string | null;
  /** Unified design-tool Focus / Isolate scope (data layer, subgroup, semantic node, or guide). */
  focusScope: FocusScope | null;
  zoomRequestCounter: number;
  highlightedGroup: HighlightedGroup | null;
  gridFilterElementIds: string[] | null;

  outlineMode: OutlineViewMode;
  activeTableTab: string;
  leftTab: LeftPanelTab;
  rightTab: RightPanelTab;
  bottomOpen: boolean;
  splitCompare: boolean;
  splitRatio: number;
  theme: WorkbenchTheme;
  commandOpen: boolean;
  hiddenLeafIds: string[];
  hiddenElementIds: string[];
  config: WorkbenchConfig;

  // Actions
  setConfig: (cfg: WorkbenchConfig) => void;
  setLiveApiBaseUrl: (url: string | null) => void;
  setProposalModalOpen: (open: boolean) => void;
  loadFromText: (text: string, sourceName?: string) => Promise<void>;
  loadFromEmbeddedJson: (jsonText: string, sourceName?: string) => Promise<void>;
  loadFromFileMap: (files: Map<string, Uint8Array>, sourceName: string) => Promise<void>;
  loadFromFiles: (fileList: FileList | File[]) => Promise<void>;
  refreshLiveBundle: () => Promise<void>;
  clearBundle: () => void;

  setViewMode: (mode: WorkbenchViewMode) => void;
  setReaderLens: (lens: ReaderLens) => void;
  setCleanFigure: (clean: boolean) => void;
  setWalkthroughOpen: (open: boolean) => void;
  setStoryStepIdx: (idx: number) => void;
  setActiveStage: (stage: SemanticStageId) => void;
  stepStage: (delta: -1 | 1) => void;
  selectElement: (id: string | null, additive?: boolean) => void;
  selectElements: (ids: string[]) => void;
  setHoveredElement: (id: string | null) => void;
  selectRecord: (id: string | null) => void;
  selectLeaf: (leafId: string | null) => void;
  selectPanel: (panelId: string | null) => void;
  selectTableRow: (tableName: string, row1: number) => void;
  setFocusScope: (scope: FocusScope | null, autoZoom?: boolean) => void;
  requestZoomToFocus: () => void;
  setHighlightedGroup: (group: HighlightedGroup | null) => void;
  setGridFilterElementIds: (ids: string[] | null) => void;
  toggleLeafVisibility: (leafId: string) => void;
  toggleElementsVisibility: (elementIds: string[]) => void;
  resetVisibility: () => void;

  setOutlineMode: (mode: OutlineViewMode) => void;
  setActiveTableTab: (tab: string) => void;
  setLeftTab: (tab: LeftPanelTab) => void;
  setRightTab: (tab: RightPanelTab) => void;
  setBottomOpen: (open: boolean) => void;
  setSplitCompare: (on: boolean) => void;
  setSplitRatio: (ratio: number) => void;
  setTheme: (theme: WorkbenchTheme) => void;
  toggleTheme: () => void;
  setCommandOpen: (open: boolean) => void;
  clearSelection: () => void;
}

function chooseInitialStage(
  bundle: GlossBundle,
  preferred?: SemanticStageId
): SemanticStageId {
  if (preferred) return preferred;
  const stats = computeStageStats(bundle);
  const order: SemanticStageId[] = [
    "behavior",
    "narrative",
    "claim",
    "relation",
    "contextual",
    "analytical",
    "binding",
    "structure",
    "raw",
  ];
  for (const st of order) {
    if (stats[st].populated) return st;
  }
  return "raw";
}

function chooseInitialElement(bundle: GlossBundle): string[] {
  for (const rec of bundle.records) {
    for (const eid of rec.resolvedTargets) {
      if (bundle.index.bindingByElement.has(eid)) return [eid];
    }
  }
  const firstVerified = bundle.derived.bindingsElements.find((b) => b.status === "verified");
  if (firstVerified) return [firstVerified.element];
  return [];
}

function chooseInitialLens(bundle: GlossBundle): ReaderLens {
  if (bundle.records.some((r) => r.layer === "claim" || r.workbenchStage === "contextual")) {
    return "findings";
  }
  if (bundle.records.some((r) => r.layer === "narrative")) return "story";
  return "explore";
}

function hydrateBundle(
  bundle: GlossBundle,
  config: WorkbenchConfig,
  preserveSelection = false,
  prev?: WorkbenchState
): Partial<WorkbenchState> {
  const spatial = buildSpatialIndex(bundle.substrate.elements);
  const stageStats = computeStageStats(bundle);
  const viewMode = preserveSelection && prev ? prev.viewMode : (config.view ?? prev?.viewMode ?? "reader");
  const readerLens = preserveSelection && prev ? prev.readerLens : chooseInitialLens(bundle);
  const activeStage =
    preserveSelection && prev ? prev.activeStage : chooseInitialStage(bundle, config.initialStage);
  const initialSelected =
    preserveSelection && prev && prev.selectedElementIds.length > 0
      ? prev.selectedElementIds
      : viewMode === "inspector"
        ? chooseInitialElement(bundle)
        : [];
  const defaultTable =
    preserveSelection && prev ? prev.activeTableTab : bundle.tableOrder[0] ?? "__elements__";

  return {
    bundle,
    spatial,
    stageStats,
    loading: false,
    error: null,
    viewMode,
    readerLens,
    cleanFigure: preserveSelection && prev ? prev.cleanFigure : false,
    walkthroughOpen: preserveSelection && prev ? prev.walkthroughOpen : false,
    storyStepIdx: preserveSelection && prev ? prev.storyStepIdx : 0,
    bottomOpen: preserveSelection && prev ? prev.bottomOpen : viewMode === "inspector",
    activeStage,
    selectedElementIds: initialSelected,
    hoveredElementId: null,
    selectedRecordId: preserveSelection && prev ? prev.selectedRecordId : null,
    selectedLeafId: null,
    selectedPanelId: null,
    focusScope: preserveSelection && prev ? prev.focusScope : null,
    highlightedGroup: null,
    gridFilterElementIds: null,
    hiddenLeafIds: preserveSelection && prev ? prev.hiddenLeafIds : [],
    hiddenElementIds: preserveSelection && prev ? prev.hiddenElementIds : [],
    activeTableTab: defaultTable,
  };
}

export const useWorkbenchStore = create<WorkbenchState>((set, get) => ({
  bundle: null,
  spatial: null,
  stageStats: null,
  loading: false,
  error: null,

  liveApiBaseUrl: null,
  proposalModalOpen: false,

  viewMode: "reader",
  readerLens: "findings",
  cleanFigure: false,
  walkthroughOpen: false,
  storyStepIdx: 0,
  activeStage: "behavior",
  selectedElementIds: [],
  hoveredElementId: null,
  selectedRecordId: null,
  selectedLeafId: null,
  selectedPanelId: null,
  focusScope: null,
  zoomRequestCounter: 0,
  highlightedGroup: null,
  gridFilterElementIds: null,

  outlineMode: "semantic",
  activeTableTab: "raw",
  leftTab: "structure",
  rightTab: "chain",
  bottomOpen: false,
  splitCompare: false,
  splitRatio: 0.45,
  theme: "paper",
  commandOpen: false,
  hiddenLeafIds: [],
  hiddenElementIds: [],
  config: {},

  setConfig: (cfg) =>
    set((s) => ({
      config: { ...s.config, ...cfg },
      theme: cfg.theme ?? s.theme,
      viewMode: cfg.view ?? s.viewMode,
      bottomOpen: cfg.view ? cfg.view === "inspector" : s.bottomOpen,
    })),

  setViewMode: (mode) =>
    set((s) => ({
      viewMode: mode,
      bottomOpen: mode === "inspector" ? true : s.bottomOpen,
      leftTab: mode === "reader" && (s.leftTab === "code" || s.leftTab === "exports") ? "structure" : s.leftTab,
      outlineMode: mode === "reader" && s.outlineMode === "grob" ? "semantic" : s.outlineMode,
      splitCompare: mode === "reader" ? false : s.splitCompare,
    })),

  setReaderLens: (lens) => {
    const stageMap: Record<ReaderLens, SemanticStageId> = {
      figure: "raw",
      explore: "analytical",
      findings: "claim",
      story: "narrative",
    };
    set({
      readerLens: lens,
      cleanFigure: lens === "figure",
      walkthroughOpen: lens === "story",
      activeStage: stageMap[lens],
    });
  },

  setCleanFigure: (clean) =>
    set((s) => ({
      cleanFigure: clean,
      walkthroughOpen: clean ? false : s.walkthroughOpen,
      readerLens: clean ? "figure" : s.walkthroughOpen ? "story" : "findings",
      activeStage: clean ? "raw" : "claim",
    })),

  setWalkthroughOpen: (open) =>
    set({
      walkthroughOpen: open,
      cleanFigure: false,
      readerLens: open ? "story" : "findings",
      activeStage: open ? "narrative" : "claim",
    }),

  setStoryStepIdx: (idx) => set({ storyStepIdx: Math.max(0, idx) }),

  setLiveApiBaseUrl: (url) => set({ liveApiBaseUrl: url }),
  setProposalModalOpen: (open) => set({ proposalModalOpen: open }),

  loadFromText: async (text, sourceName = "artifact.html") => {
    set({ loading: true, error: null });
    try {
      const bundle = await decodeArtifactText(text, sourceName);
      set(hydrateBundle(bundle, get().config));
    } catch (err) {
      set({
        loading: false,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  },

  loadFromEmbeddedJson: async (jsonText, sourceName = "artifact.html") => {
    set({ loading: true, error: null });
    try {
      const bundle = await decodeEmbeddedJsonText(jsonText, sourceName);
      set(hydrateBundle(bundle, get().config));
    } catch (err) {
      set({
        loading: false,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  },

  refreshLiveBundle: async () => {
    const base = get().liveApiBaseUrl;
    if (base === null) return;
    const res = await fetch(`${base}/api/bundle`);
    if (!res.ok) throw new Error(`Failed to reload live bundle (HTTP ${res.status})`);
    const txt = await res.text();
    const cur = get();
    const bundle = await decodeEmbeddedJsonText(txt, cur.bundle?.sourceName ?? "live-figure.html");
    set(hydrateBundle(bundle, cur.config, true, cur));
  },

  loadFromFileMap: async (files, sourceName) => {
    set({ loading: true, error: null });
    try {
      const bundle = await decodeFileMap(files, sourceName, "directory");
      set(hydrateBundle(bundle, get().config));
    } catch (err) {
      set({
        loading: false,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  },

  loadFromFiles: async (fileList) => {
    const files = Array.from(fileList);
    if (files.length === 0) return;
    set({ loading: true, error: null });
    try {
      if (files.length === 1 && /\.(html?|svg)$/i.test(files[0].name)) {
        const text = await files[0].text();
        await get().loadFromText(text, files[0].name);
        return;
      }

      const map = new Map<string, Uint8Array>();
      let rootName = "gloss-bundle";
      for (const f of files) {
        const relRaw = (f as File & { webkitRelativePath?: string }).webkitRelativePath || f.name;
        const parts = relRaw.replace(/^\/+/, "").split("/");
        if (parts.length > 1) rootName = parts[0];
        const idxManifest = parts.findIndex((p) =>
          ["manifest.json", "context.json", "substrate", "layers", "projections"].includes(p)
        );
        const relPath =
          idxManifest >= 0 ? parts.slice(idxManifest).join("/") : parts.slice(1).join("/") || f.name;
        const buf = new Uint8Array(await f.arrayBuffer());
        map.set(relPath, buf);
      }
      await get().loadFromFileMap(map, rootName);
    } catch (err) {
      set({
        loading: false,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  },

  clearBundle: () =>
    set({
      bundle: null,
      spatial: null,
      stageStats: null,
      error: null,
      selectedElementIds: [],
      hoveredElementId: null,
      selectedRecordId: null,
      cleanFigure: false,
      walkthroughOpen: false,
      storyStepIdx: 0,
      focusScope: null,
      highlightedGroup: null,
      gridFilterElementIds: null,
      hiddenLeafIds: [],
      hiddenElementIds: [],
    }),

  setActiveStage: (stage) => set({ activeStage: stage }),

  stepStage: (delta) => {
    const cur = get().activeStage;
    const idx = SEMANTIC_STAGES.findIndex((s) => s.id === cur);
    const next = Math.max(0, Math.min(SEMANTIC_STAGES.length - 1, idx + delta));
    set({ activeStage: SEMANTIC_STAGES[next].id });
  },

  selectElement: (id, additive = false) => {
    if (!id) {
      set({ selectedElementIds: [], selectedRecordId: null });
      return;
    }
    set((s) => {
      const next = additive
        ? s.selectedElementIds.includes(id)
          ? s.selectedElementIds.filter((x) => x !== id)
          : [...s.selectedElementIds, id]
        : [id];
      const el = s.bundle?.index.elementById.get(id);
      return {
        selectedElementIds: next,
        selectedLeafId: el?.leaf ?? s.selectedLeafId,
        selectedRecordId: null,
      };
    });
  },

  selectElements: (ids) =>
    set({
      selectedElementIds: Array.from(new Set(ids)),
      selectedRecordId: null,
    }),

  setHoveredElement: (id) => set({ hoveredElementId: id }),

  selectRecord: (id) => {
    const bundle = get().bundle;
    if (!id || !bundle) {
      set({ selectedRecordId: null });
      return;
    }
    const rec = bundle.index.recordById.get(id);
    set({
      selectedRecordId: id,
      selectedElementIds: rec && rec.resolvedTargets.length > 0 ? rec.resolvedTargets : get().selectedElementIds,
    });
  },

  selectLeaf: (leafId) => {
    const bundle = get().bundle;
    if (!leafId || !bundle) {
      set({ selectedLeafId: null });
      return;
    }
    const els = bundle.substrate.elements.filter((e) => e.leaf === leafId).map((e) => e.id);
    set({
      selectedLeafId: leafId,
      selectedElementIds: els.slice(0, 500),
    });
  },

  selectPanel: (panelId) => set({ selectedPanelId: panelId }),

  selectTableRow: (tableName, row1) => {
    const bundle = get().bundle;
    if (!bundle) return;
    const ids = bundle.index.elementsByTableRow.get(`${tableName}:${row1}`) ?? [];
    if (ids.length > 0) {
      set({ selectedElementIds: ids, selectedRecordId: null });
    }
  },

  setFocusScope: (scope, autoZoom = false) => {
    set((s) => {
      const nextSelected =
        scope && scope.elementIds.length > 0 ? scope.elementIds.slice(0, 500) : s.selectedElementIds;
      return {
        focusScope: scope,
        selectedElementIds: scope ? nextSelected : s.selectedElementIds,
        selectedRecordId: scope?.recordId ?? null,
        highlightedGroup:
          scope?.isException
            ? { label: scope.label, status: "exception", elementIds: scope.elementIds }
            : null,
        zoomRequestCounter: autoZoom && scope ? s.zoomRequestCounter + 1 : s.zoomRequestCounter,
      };
    });
  },

  requestZoomToFocus: () => set((s) => ({ zoomRequestCounter: s.zoomRequestCounter + 1 })),

  setHighlightedGroup: (group) =>
    set({
      highlightedGroup: group,
      focusScope: group
        ? {
            id: `check-group:${group.label}`,
            label: `Group ${group.label}`,
            kind: group.status === "exception" ? "exception" : "group",
            elementIds: group.elementIds,
            isException: group.status === "exception",
          }
        : null,
    }),

  setGridFilterElementIds: (ids) => set({ gridFilterElementIds: ids }),

  toggleLeafVisibility: (leafId) =>
    set((s) => ({
      hiddenLeafIds: s.hiddenLeafIds.includes(leafId)
        ? s.hiddenLeafIds.filter((x) => x !== leafId)
        : [...s.hiddenLeafIds, leafId],
    })),

  toggleElementsVisibility: (elementIds) => {
    if (elementIds.length === 0) return;
    set((s) => {
      const cur = new Set(s.hiddenElementIds);
      const allHidden = elementIds.every((id) => cur.has(id));
      if (allHidden) {
        for (const id of elementIds) cur.delete(id);
      } else {
        for (const id of elementIds) cur.add(id);
      }
      return { hiddenElementIds: Array.from(cur) };
    });
  },

  resetVisibility: () => set({ hiddenElementIds: [], hiddenLeafIds: [] }),

  setOutlineMode: (mode) => set({ outlineMode: mode }),
  setActiveTableTab: (tab) => set({ activeTableTab: tab }),
  setLeftTab: (tab) => set({ leftTab: tab }),
  setRightTab: (tab) => set({ rightTab: tab }),
  setBottomOpen: (open) => set({ bottomOpen: open }),
  setSplitCompare: (on) => set({ splitCompare: on }),
  setSplitRatio: (ratio) => set({ splitRatio: Math.max(0.05, Math.min(0.95, ratio)) }),
  setTheme: (theme) => set({ theme }),
  toggleTheme: () => set((s) => ({ theme: s.theme === "paper" ? "obsidian" : "paper" })),
  setCommandOpen: (open) => set({ commandOpen: open }),
  clearSelection: () =>
    set({
      selectedElementIds: [],
      selectedRecordId: null,
      selectedLeafId: null,
      focusScope: null,
      highlightedGroup: null,
      gridFilterElementIds: null,
    }),
}));
