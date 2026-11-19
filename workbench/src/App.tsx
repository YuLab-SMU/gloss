import React, { useEffect, useMemo, useRef, useState } from "react";
import { Panel, PanelGroup, PanelResizeHandle } from "react-resizable-panels";
import {
  AlertTriangle,
  BookOpen,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Command as CommandIcon,
  Compass,
  FolderOpen,
  Image as ImageIcon,
  Microscope,
  Moon,
  Radio,
  ShieldAlert,
  ShieldCheck,
  Sun,
  Table2,
  Upload,
  Wrench,
} from "lucide-react";
import {
  getFigureDisplayTitle,
  resolveNaturalFocus,
  SEMANTIC_STAGES,
  type ReaderLens,
} from "./codec";
import { CommandPalette } from "./components/CommandPalette";
import { DataWorkbenchGrid } from "./components/grid/DataWorkbenchGrid";
import { LeftPanel } from "./components/left/LeftPanel";
import { ProposalModal } from "./components/ProposalModal";
import { ReaderInspector } from "./components/right/ReaderInspector";
import { RightInspector } from "./components/right/RightInspector";
import { DropzoneHero } from "./components/rive/DropzoneHero";
import { StageRail } from "./components/rive/StageRail";
import { FigureStage } from "./components/stage/FigureStage";
import { useWorkbenchStore, type WorkbenchConfig } from "./store/useWorkbenchStore";

declare global {
  interface Window {
    __GLOSS_WORKBENCH_CONFIG__?: WorkbenchConfig;
    __GLOSS_LIVE_API__?: { baseUrl: string };
  }
}

export const App: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const viewMode = useWorkbenchStore((s) => s.viewMode);
  const readerLens = useWorkbenchStore((s) => s.readerLens);
  const theme = useWorkbenchStore((s) => s.theme);
  const bottomOpen = useWorkbenchStore((s) => s.bottomOpen);
  const liveApiBaseUrl = useWorkbenchStore((s) => s.liveApiBaseUrl);

  const setViewMode = useWorkbenchStore((s) => s.setViewMode);
  const setReaderLens = useWorkbenchStore((s) => s.setReaderLens);
  const toggleTheme = useWorkbenchStore((s) => s.toggleTheme);
  const setBottomOpen = useWorkbenchStore((s) => s.setBottomOpen);
  const setCommandOpen = useWorkbenchStore((s) => s.setCommandOpen);
  const loadFromText = useWorkbenchStore((s) => s.loadFromText);
  const loadFromEmbeddedJson = useWorkbenchStore((s) => s.loadFromEmbeddedJson);
  const loadFromFiles = useWorkbenchStore((s) => s.loadFromFiles);
  const setConfig = useWorkbenchStore((s) => s.setConfig);
  const setLiveApiBaseUrl = useWorkbenchStore((s) => s.setLiveApiBaseUrl);
  const setActiveStage = useWorkbenchStore((s) => s.setActiveStage);
  const stepStage = useWorkbenchStore((s) => s.stepStage);
  const clearSelection = useWorkbenchStore((s) => s.clearSelection);
  const setFocusScope = useWorkbenchStore((s) => s.setFocusScope);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const [sampleUrl, setSampleUrl] = useState<string | null>(null);
  const [dragOverlay, setDragOverlay] = useState(false);

  const isReader = viewMode === "reader";

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
  }, [theme]);

  useEffect(() => {
    if (window.__GLOSS_WORKBENCH_CONFIG__) {
      setConfig(window.__GLOSS_WORKBENCH_CONFIG__);
    }
    if (window.__GLOSS_LIVE_API__) {
      setLiveApiBaseUrl(window.__GLOSS_LIVE_API__.baseUrl ?? "");
    }

    const embeddedTag = document.getElementById("gloss-bundle");
    if (embeddedTag && embeddedTag.textContent?.trim()) {
      const title =
        window.__GLOSS_WORKBENCH_CONFIG__?.title ||
        document.title.replace(/\s*[-—].*$/, "") ||
        "gloss-figure.html";
      void loadFromEmbeddedJson(embeddedTag.textContent, title);
      return;
    }

    const params = new URLSearchParams(window.location.search);
    const artifactUrl = params.get("artifact");
    if (artifactUrl) {
      fetch(artifactUrl)
        .then((r) => {
          if (!r.ok) throw new Error(`HTTP ${r.status}`);
          return r.text();
        })
        .then((txt) => {
          const nm = artifactUrl.split("/").pop() || "artifact.html";
          return loadFromText(txt, nm);
        })
        .catch(() => {});
      return;
    }

    if (import.meta.env.DEV) {
      const candidate = "/sample-mtcars-workbench.html";
      const fallback = "/sample-mtcars-context.html";
      fetch(candidate, { method: "HEAD" })
        .then((r) => {
          if (r.ok) {
            setSampleUrl(candidate);
            return;
          }
          return fetch(fallback, { method: "HEAD" }).then((r2) => {
            if (r2.ok) setSampleUrl(fallback);
          });
        })
        .catch(() => {});
    }
  }, [loadFromEmbeddedJson, loadFromText, setConfig, setLiveApiBaseUrl]);

  // Global keyboard shortcuts
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      if (
        target &&
        (target.tagName === "INPUT" ||
          target.tagName === "TEXTAREA" ||
          target.isContentEditable)
      ) {
        return;
      }
      const st = useWorkbenchStore.getState();
      if (!st.bundle || st.commandOpen) return;

      if (e.key === "Escape") {
        clearSelection();
      } else if (!e.metaKey && !e.ctrlKey && !e.altKey && st.viewMode === "inspector") {
        const num = Number(e.key);
        if (num >= 1 && num <= SEMANTIC_STAGES.length) {
          setActiveStage(SEMANTIC_STAGES[num - 1].id);
        } else if (e.key === "[") {
          stepStage(-1);
        } else if (e.key === "]") {
          stepStage(1);
        }
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [clearSelection, setActiveStage, stepStage]);

  const figureTitle = useMemo(() => (bundle ? getFigureDisplayTitle(bundle) : ""), [bundle]);
  const exceptionScope = useMemo(
    () => (bundle ? resolveNaturalFocus(bundle, "exception") : null),
    [bundle]
  );

  const handleLoadSample = async () => {
    if (!sampleUrl) return;
    const res = await fetch(sampleUrl);
    if (!res.ok) return;
    const txt = await res.text();
    await loadFromText(txt, sampleUrl.replace(/^\//, ""));
  };

  const verifiedCount =
    bundle?.derived.bindingsElements.filter((b) => b.status === "verified").length ?? 0;
  const partialOrFailedClaims =
    bundle?.records.filter(
      (r) =>
        r.layer === "claim" &&
        (r.projectionStatus === "partial" || r.projectionStatus === "rejected")
    ).length ?? 0;

  const readerLenses: Array<{ id: ReaderLens; label: string; icon: React.ReactNode }> = [
    { id: "figure", label: "Figure", icon: <ImageIcon className="h-3.5 w-3.5" /> },
    { id: "explore", label: "Explore", icon: <Compass className="h-3.5 w-3.5" /> },
    { id: "findings", label: "Findings", icon: <CheckCircle2 className="h-3.5 w-3.5" /> },
    { id: "story", label: "Story", icon: <BookOpen className="h-3.5 w-3.5" /> },
  ];

  return (
    <div
      className="flex h-screen w-screen flex-col overflow-hidden"
      style={{ background: "var(--bg-app)", color: "var(--ink-primary)" }}
      onDragOver={(e) => {
        if (bundle) {
          e.preventDefault();
          setDragOverlay(true);
        }
      }}
      onDragLeave={(e) => {
        if (e.currentTarget === e.target) setDragOverlay(false);
      }}
      onDrop={(e) => {
        if (bundle && e.dataTransfer.files?.length) {
          e.preventDefault();
          setDragOverlay(false);
          void loadFromFiles(e.dataTransfer.files);
        }
      }}
    >
      {/* Top Header Bar: Calm & Publication-Grade in Scientific Reader Mode; Full Audit Controls in Inspector Mode */}
      <header
        className="flex h-12 shrink-0 items-center justify-between gap-3 border-b px-3.5"
        style={{
          background: "var(--bg-surface)",
          borderColor: "var(--border-subtle)",
        }}
      >
        {/* Left: Brand + Figure Title + Calm Trust Signals */}
        <div className="flex min-w-0 flex-1 items-center gap-2 overflow-hidden">
          <div className="flex shrink-0 items-center gap-1.5">
            <span
              className="flex h-6 w-6 items-center justify-center rounded-md text-xs font-black tracking-tighter text-white"
              style={{
                background:
                  "linear-gradient(135deg, #142238 0%, #2563eb 65%, #0d9488 100%)",
              }}
            >
              gl
            </span>
            <span className="text-sm font-bold tracking-tight" style={{ color: "var(--ink-primary)" }}>
              gloss
            </span>
          </div>

          {bundle && (
            <>
              <span className="shrink-0 text-xs opacity-25">/</span>
              <span
                className="min-w-0 max-w-[210px] truncate text-[13px] font-semibold xl:max-w-[270px] 2xl:max-w-[360px]"
                style={{ color: "var(--ink-primary)" }}
                title={figureTitle}
              >
                {figureTitle}
              </span>

              {liveApiBaseUrl !== null && (
                <span
                  className="inline-flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold"
                  style={{ background: "var(--st-verified-soft)", color: "var(--st-verified)" }}
                >
                  <Radio className="h-3 w-3" />
                  LIVE
                </span>
              )}

              {isReader ? (
                <div className="hidden shrink-0 items-center gap-1.5 lg:flex">
                  {verifiedCount > 0 && (
                    <span
                      className="inline-flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-[10.5px] font-medium"
                      style={{ background: "var(--st-verified-soft)", color: "var(--st-verified)" }}
                      title="Plotted observations checked against source data"
                    >
                      <CheckCircle2 className="h-3 w-3" />
                      Verified
                    </span>
                  )}
                  {partialOrFailedClaims > 0 && (
                    <button
                      type="button"
                      onClick={() => {
                        setReaderLens("findings");
                        if (exceptionScope) setFocusScope(exceptionScope, false);
                      }}
                      className="inline-flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-[10.5px] font-semibold transition-transform hover:scale-[1.02]"
                      style={{ background: "var(--st-warn-soft)", color: "var(--st-warn)" }}
                      title="Click to spotlight the statistical exception on the figure"
                    >
                      <AlertTriangle className="h-3 w-3" />
                      {partialOrFailedClaims} Exception
                    </button>
                  )}
                </div>
              ) : (
                <div className="hidden items-center gap-1.5 lg:flex">
                  <span
                    className="font-mono-num rounded-full px-2 py-0.5 text-[10px] font-semibold"
                    style={{ background: "var(--bg-subtle)", color: "var(--ink-secondary)" }}
                  >
                    {bundle.engine ?? "svg"}
                  </span>
                  <span
                    className="font-mono-num rounded-full px-2 py-0.5 text-[10px] font-semibold"
                    style={{ background: "var(--st-verified-soft)", color: "var(--st-verified)" }}
                  >
                    {verifiedCount} verified bindings
                  </span>
                  {bundle.integrity.checked > 0 && (
                    <span
                      className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold"
                      style={{
                        background:
                          bundle.integrity.mismatches.length === 0
                            ? "var(--st-verified-soft)"
                            : "var(--st-fail-soft)",
                        color:
                          bundle.integrity.mismatches.length === 0
                            ? "var(--st-verified)"
                            : "var(--st-fail)",
                      }}
                    >
                      {bundle.integrity.mismatches.length === 0 ? (
                        <ShieldCheck className="h-3 w-3" />
                      ) : (
                        <ShieldAlert className="h-3 w-3" />
                      )}
                      SHA-256
                    </span>
                  )}
                </div>
              )}
            </>
          )}
        </div>

        {/* Center: Clean 4-Lens Scientific Switcher (Reader Mode only) */}
        {bundle && isReader && (
          <nav
            aria-label="Figure reading lens"
            className="hidden items-center gap-0.5 rounded-xl border p-0.5 md:flex"
            style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
          >
            {readerLenses.map((lens) => {
              const active = readerLens === lens.id;
              return (
                <button
                  key={lens.id}
                  type="button"
                  onClick={() => setReaderLens(lens.id)}
                  className="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-[11.5px] font-semibold transition-all"
                  style={{
                    background: active ? "var(--bg-surface)" : "transparent",
                    color: active ? "var(--st-focus)" : "var(--ink-secondary)",
                    boxShadow: active ? "0 1px 2px rgba(0,0,0,0.08)" : "none",
                  }}
                >
                  {lens.icon}
                  <span>{lens.label}</span>
                </button>
              );
            })}
          </nav>
        )}

        {/* Right: Data Drawer + Reader/Inspector Mode Toggle + Open + Theme */}
        <div className="flex shrink-0 items-center gap-1.5">
          {bundle && (
            <>
              {!isReader && (
                <button
                  type="button"
                  onClick={() => setCommandOpen(true)}
                  className="inline-flex items-center gap-1.5 rounded-lg border px-2 py-1 text-[11px] font-medium transition-colors hover:bg-[var(--bg-subtle)]"
                  style={{
                    borderColor: "var(--border-subtle)",
                    color: "var(--ink-secondary)",
                  }}
                >
                  <CommandIcon className="h-3 w-3" />
                  <kbd className="font-mono-num text-[10px] opacity-70">⌘K</kbd>
                </button>
              )}

              <button
                type="button"
                onClick={() => setBottomOpen(!bottomOpen)}
                className="inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1 text-[11.5px] font-medium transition-colors hover:bg-[var(--bg-subtle)]"
                style={{
                  borderColor: bottomOpen ? "var(--st-focus)" : "var(--border-subtle)",
                  background: bottomOpen ? "var(--st-focus-soft)" : "transparent",
                  color: bottomOpen ? "var(--st-focus)" : "var(--ink-secondary)",
                }}
                title="Toggle source data table"
              >
                <Table2 className="h-3.5 w-3.5" />
                <span className="hidden sm:inline">{isReader ? "Data" : "Grid"}</span>
                {bottomOpen ? <ChevronDown className="h-3 w-3" /> : <ChevronUp className="h-3 w-3" />}
              </button>

              {/* Progressive Disclosure Toggle: Scientific Reader <-> Engineering Inspector */}
              <div
                className="flex items-center rounded-lg border p-0.5 text-[11px] font-semibold"
                style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
                title="Switch between Scientific Reader and Engineering Inspector"
              >
                <button
                  type="button"
                  onClick={() => setViewMode("reader")}
                  className="inline-flex items-center gap-1 rounded-md px-2 py-0.5 transition-colors"
                  style={{
                    background: isReader ? "var(--bg-surface)" : "transparent",
                    color: isReader ? "var(--ink-primary)" : "var(--ink-muted)",
                    boxShadow: isReader ? "0 1px 2px rgba(0,0,0,0.06)" : "none",
                  }}
                >
                  <Microscope className="h-3 w-3" />
                  <span className="hidden sm:inline">Scientific</span>
                </button>
                <button
                  type="button"
                  onClick={() => setViewMode("inspector")}
                  className="inline-flex items-center gap-1 rounded-md px-2 py-0.5 transition-colors"
                  style={{
                    background: !isReader ? "var(--bg-surface)" : "transparent",
                    color: !isReader ? "var(--st-focus)" : "var(--ink-muted)",
                    boxShadow: !isReader ? "0 1px 2px rgba(0,0,0,0.06)" : "none",
                  }}
                >
                  <Wrench className="h-3 w-3" />
                  <span className="hidden sm:inline">Inspector</span>
                </button>
              </div>

              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="rounded-lg border p-1.5 transition-colors hover:bg-[var(--bg-subtle)]"
                style={{
                  borderColor: "var(--border-subtle)",
                  color: "var(--ink-secondary)",
                }}
                title="Open another gloss artifact"
              >
                <FolderOpen className="h-3.5 w-3.5" />
              </button>
            </>
          )}

          <button
            type="button"
            onClick={toggleTheme}
            title={`Switch to ${theme === "paper" ? "Dark Studio" : "Light Paper"}`}
            className="rounded-lg border p-1.5 transition-colors hover:bg-[var(--bg-subtle)]"
            style={{
              borderColor: "var(--border-subtle)",
              color: "var(--ink-secondary)",
            }}
          >
            {theme === "paper" ? <Moon className="h-3.5 w-3.5" /> : <Sun className="h-3.5 w-3.5" />}
          </button>
        </div>

        <input
          ref={fileInputRef}
          type="file"
          accept=".html,.htm,.svg"
          className="hidden"
          onChange={(e) => {
            if (e.target.files?.length) void loadFromFiles(e.target.files);
          }}
        />
      </header>

      {/* Main Content Area */}
      {!bundle ? (
        <div className="min-h-0 flex-1">
          <DropzoneHero
            sampleAvailable={Boolean(sampleUrl)}
            onLoadSample={() => void handleLoadSample()}
          />
        </div>
      ) : (
        <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
          {/* 9-Stage Engineering Pipeline Rail appears cleanly in Inspector Mode */}
          {!isReader && <StageRail />}

          {/* Workspace Panels */}
          <div className="min-h-0 flex-1">
            <PanelGroup direction="horizontal" autoSaveId="gloss-wb-cols-v2">
              <Panel defaultSize={22} minSize={15} maxSize={36}>
                <LeftPanel />
              </Panel>

              <PanelResizeHandle className="resize-handle-h" />

              <Panel defaultSize={52} minSize={32}>
                {bottomOpen ? (
                  <PanelGroup direction="vertical" autoSaveId="gloss-wb-rows-v2">
                    <Panel defaultSize={64} minSize={30}>
                      <FigureStage />
                    </Panel>
                    <PanelResizeHandle className="resize-handle-v" />
                    <Panel defaultSize={36} minSize={18}>
                      <DataWorkbenchGrid />
                    </Panel>
                  </PanelGroup>
                ) : (
                  <FigureStage />
                )}
              </Panel>

              <PanelResizeHandle className="resize-handle-h" />

              <Panel defaultSize={26} minSize={18} maxSize={40}>
                {isReader ? <ReaderInspector /> : <RightInspector />}
              </Panel>
            </PanelGroup>
          </div>
        </div>
      )}

      {/* Drag-and-drop overlay when a bundle is already open */}
      {dragOverlay && (
        <div className="pointer-events-none fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-[2px]">
          <div
            className="flex flex-col items-center gap-2 rounded-2xl border-2 border-dashed px-10 py-8 shadow-2xl"
            style={{
              background: "var(--bg-surface)",
              borderColor: "var(--st-focus)",
              color: "var(--ink-primary)",
            }}
          >
            <Upload className="h-8 w-8" style={{ color: "var(--st-focus)" }} />
            <div className="text-base font-bold">Drop to open a new gloss figure</div>
            <div className="text-xs" style={{ color: "var(--ink-secondary)" }}>
              Decoded locally in your browser with data verification
            </div>
          </div>
        </div>
      )}

      <CommandPalette />
      <ProposalModal />
    </div>
  );
};
