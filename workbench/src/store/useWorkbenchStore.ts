import { create } from "zustand";
import {
  buildSpatialIndex,
  computeStageStats,
  decodeArtifactText,
  decodeEmbeddedJsonText,
  decodeFileMap,
  SEMANTIC_STAGES,
  type GlossBundle,
  type SemanticStageId,
  type SpatialIndex,
  type StageStatusSummary,
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

  activeStage: SemanticStageId;
  selectedElementIds: string[];
  hoveredElementId: string | null;
  selectedRecordId: string | null;
  selectedLeafId: string | null;
  selectedPanelId: string | null;
  highlightedGroup: HighlightedGroup | null;
  gridFilterElementIds: string[] | null;

  activeTableTab: string;
  leftTab: LeftPanelTab;
  rightTab: RightPanelTab;
  bottomOpen: boolean;
  splitCompare: boolean;
  splitRatio: number;
  theme: WorkbenchTheme;
  commandOpen: boolean;
  hiddenLeafIds: string[];
  config: WorkbenchConfig;

  // Actions
  setConfig: (cfg: WorkbenchConfig) => void;
  loadFromText: (text: string, sourceName?: string) => Promise<void>;
  loadFromEmbeddedJson: (jsonText: string, sourceName?: string) => Promise<void>;
  loadFromFileMap: (files: Map<string, Uint8Array>, sourceName: string) => Promise<void>;
  loadFromFiles: (fileList: FileList | File[]) => Promise<void>;
  clearBundle: () => void;

  setActiveStage: (stage: SemanticStageId) => void;
  stepStage: (delta: -1 | 1) => void;
  selectElement: (id: string | null, additive?: boolean) => void;
  selectElements: (ids: string[]) => void;
  setHoveredElement: (id: string | null) => void;
  selectRecord: (id: string | null) => void;
  selectLeaf: (leafId: string | null) => void;
  selectPanel: (panelId: string | null) => void;
  selectTableRow: (tableName: string, row1: number) => void;
  setHighlightedGroup: (group: HighlightedGroup | null) => void;
  setGridFilterElementIds: (ids: string[] | null) => void;
  toggleLeafVisibility: (leafId: string) => void;

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
  // Pick the richest populated stage so the user immediately sees gloss's value
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
  // Prefer an element that has both semantic records and a verified binding (e.g. e65 Mazda RX4)
  for (const rec of bundle.records) {
    for (const eid of rec.resolvedTargets) {
      if (bundle.index.bindingByElement.has(eid)) return [eid];
    }
  }
  const firstVerified = bundle.derived.bindingsElements.find((b) => b.status === "verified");
  if (firstVerified) return [firstVerified.element];
  return [];
}

function hydrateBundle(
  bundle: GlossBundle,
  config: WorkbenchConfig
): Partial<WorkbenchState> {
  const spatial = buildSpatialIndex(bundle.substrate.elements);
  const stageStats = computeStageStats(bundle);
  const activeStage = chooseInitialStage(bundle, config.initialStage);
  const initialSelected = chooseInitialElement(bundle);
  const defaultTable = bundle.tableOrder[0] ?? "__elements__";

  return {
    bundle,
    spatial,
    stageStats,
    loading: false,
    error: null,
    activeStage,
    selectedElementIds: initialSelected,
    hoveredElementId: null,
    selectedRecordId: null,
    selectedLeafId: null,
    selectedPanelId: null,
    highlightedGroup: null,
    gridFilterElementIds: null,
    hiddenLeafIds: [],
    activeTableTab: defaultTable,
  };
}

export const useWorkbenchStore = create<WorkbenchState>((set, get) => ({
  bundle: null,
  spatial: null,
  stageStats: null,
  loading: false,
  error: null,

  activeStage: "behavior",
  selectedElementIds: [],
  hoveredElementId: null,
  selectedRecordId: null,
  selectedLeafId: null,
  selectedPanelId: null,
  highlightedGroup: null,
  gridFilterElementIds: null,

  activeTableTab: "raw",
  leftTab: "structure",
  rightTab: "chain",
  bottomOpen: true,
  splitCompare: false,
  splitRatio: 0.45,
  theme: "paper",
  commandOpen: false,
  hiddenLeafIds: [],
  config: {},

  setConfig: (cfg) =>
    set((s) => ({
      config: { ...s.config, ...cfg },
      theme: cfg.theme ?? s.theme,
    })),

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
      // Single HTML or SVG artifact
      if (files.length === 1 && /\.(html?|svg)$/i.test(files[0].name)) {
        const text = await files[0].text();
        await get().loadFromText(text, files[0].name);
        return;
      }

      // Directory bundle (.gloss/ dropped or selected via webkitdirectory)
      const map = new Map<string, Uint8Array>();
      let rootName = "gloss-bundle";
      for (const f of files) {
        const relRaw = (f as File & { webkitRelativePath?: string }).webkitRelativePath || f.name;
        const parts = relRaw.replace(/^\/+/, "").split("/");
        if (parts.length > 1) {
          rootName = parts[0];
        }
        // Strip leading directory folder name so paths start with manifest.json, substrate/...
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
      highlightedGroup: null,
      gridFilterElementIds: null,
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
        highlightedGroup: null,
      };
    });
  },

  selectElements: (ids) =>
    set({
      selectedElementIds: Array.from(new Set(ids)),
      selectedRecordId: null,
      highlightedGroup: null,
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
      highlightedGroup: null,
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
      selectedElementIds: els.slice(0, 500), // cap visual selection ring array for dense leaves
      highlightedGroup: null,
    });
  },

  selectPanel: (panelId) => set({ selectedPanelId: panelId }),

  selectTableRow: (tableName, row1) => {
    const bundle = get().bundle;
    if (!bundle) return;
    const ids = bundle.index.elementsByTableRow.get(`${tableName}:${row1}`) ?? [];
    if (ids.length > 0) {
      set({ selectedElementIds: ids, selectedRecordId: null, highlightedGroup: null });
    }
  },

  setHighlightedGroup: (group) => set({ highlightedGroup: group }),

  setGridFilterElementIds: (ids) => set({ gridFilterElementIds: ids }),

  toggleLeafVisibility: (leafId) =>
    set((s) => ({
      hiddenLeafIds: s.hiddenLeafIds.includes(leafId)
        ? s.hiddenLeafIds.filter((x) => x !== leafId)
        : [...s.hiddenLeafIds, leafId],
    })),

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
      highlightedGroup: null,
      gridFilterElementIds: null,
    }),
}));
