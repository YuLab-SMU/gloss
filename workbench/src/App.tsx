import React, { useEffect, useRef, useState } from "react";
import { Panel, PanelGroup, PanelResizeHandle } from "react-resizable-panels";
import {
  ChevronDown,
  ChevronUp,
  Command as CommandIcon,
  FolderOpen,
  Moon,
  Radio,
  ShieldAlert,
  ShieldCheck,
  Sun,
  Table2,
  Upload,
} from "lucide-react";
import { SEMANTIC_STAGES } from "./codec";
import { CommandPalette } from "./components/CommandPalette";
import { DataWorkbenchGrid } from "./components/grid/DataWorkbenchGrid";
import { LeftPanel } from "./components/left/LeftPanel";
import { ProposalModal } from "./components/ProposalModal";
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
  const theme = useWorkbenchStore((s) => s.theme);
  const bottomOpen = useWorkbenchStore((s) => s.bottomOpen);
  const toggleTheme = useWorkbenchStore((s) => s.toggleTheme);
  const setBottomOpen = useWorkbenchStore((s) => s.setBottomOpen);
  const setCommandOpen = useWorkbenchStore((s) => s.setCommandOpen);
  const loadFromText = useWorkbenchStore((s) => s.loadFromText);
  const loadFromEmbeddedJson = useWorkbenchStore((s) => s.loadFromEmbeddedJson);
  const loadFromFiles = useWorkbenchStore((s) => s.loadFromFiles);
  const setConfig = useWorkbenchStore((s) => s.setConfig);
  const liveApiBaseUrl = useWorkbenchStore((s) => s.liveApiBaseUrl);
  const setLiveApiBaseUrl = useWorkbenchStore((s) => s.setLiveApiBaseUrl);
  const setActiveStage = useWorkbenchStore((s) => s.setActiveStage);
  const stepStage = useWorkbenchStore((s) => s.stepStage);
  const clearSelection = useWorkbenchStore((s) => s.clearSelection);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const [sampleUrl, setSampleUrl] = useState<string | null>(null);
  const [dragOverlay, setDragOverlay] = useState(false);

  // Sync theme attribute on root document
  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
  }, [theme]);

  // Auto-boot from embedded <script id="gloss-bundle">, ?artifact= URL, or detect dev demo
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
        document.title.replace(/\s*—.*$/, "") ||
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
        .catch(() => {
          // stay on dropzone if remote sample isn't available
        });
      return;
    }

    // In Vite dev mode, probe if sample artifact is available for one-click preview
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

  // Global keyboard shortcuts (1..9 stages, arrows, Esc)
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
      if (!useWorkbenchStore.getState().bundle) return;
      if (useWorkbenchStore.getState().commandOpen) return;

      if (e.key === "Escape") {
        clearSelection();
      } else if (!e.metaKey && !e.ctrlKey && !e.altKey) {
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
      (r) => r.layer === "claim" && (r.projectionStatus === "partial" || r.projectionStatus === "rejected")
    ).length ?? 0;

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
      {/* Top Precision Header Bar */}
      <header
        className="flex h-11 shrink-0 items-center justify-between gap-3 border-b px-3"
        style={{
          background: "var(--bg-surface)",
          borderColor: "var(--border-subtle)",
        }}
      >
        <div className="flex min-w-0 items-center gap-2.5">
          {/* Brand mark */}
          <div className="flex items-center gap-1.5">
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
            <span
              className="hidden rounded px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wider sm:inline"
              style={{ background: "var(--bg-subtle)", color: "var(--ink-secondary)" }}
            >
              Workbench
            </span>
          </div>

          {bundle && (
            <>
              <span className="text-xs opacity-30">/</span>
              <span
                className="truncate text-xs font-semibold"
                style={{ color: "var(--ink-primary)" }}
                title={bundle.sourceName}
              >
                {bundle.sourceName}
              </span>

              <div className="hidden items-center gap-1.5 lg:flex">
                {liveApiBaseUrl !== null && (
                  <span
                    className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold"
                    style={{ background: "var(--st-verified-soft)", color: "var(--st-verified)" }}
                  >
                    <Radio className="h-3 w-3" />
                    LIVE R
                  </span>
                )}
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
                {partialOrFailedClaims > 0 && (
                  <span
                    className="font-mono-num rounded-full px-2 py-0.5 text-[10px] font-semibold"
                    style={{ background: "var(--st-warn-soft)", color: "var(--st-warn)" }}
                  >
                    {partialOrFailedClaims} claim exception
                  </span>
                )}
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
            </>
          )}
        </div>

        <div className="flex shrink-0 items-center gap-1.5">
          {bundle && (
            <>
              <button
                type="button"
                onClick={() => setCommandOpen(true)}
                className="inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1 text-[11px] font-medium transition-colors hover:bg-[var(--bg-subtle)]"
                style={{
                  borderColor: "var(--border-subtle)",
                  color: "var(--ink-secondary)",
                }}
              >
                <CommandIcon className="h-3 w-3" />
                <span className="hidden sm:inline">Jump</span>
                <kbd className="font-mono-num text-[10px] opacity-70">⌘K</kbd>
              </button>

              <button
                type="button"
                onClick={() => setBottomOpen(!bottomOpen)}
                className="inline-flex items-center gap-1 rounded-lg border px-2 py-1 text-[11px] font-medium transition-colors hover:bg-[var(--bg-subtle)]"
                style={{
                  borderColor: bottomOpen ? "var(--st-focus)" : "var(--border-subtle)",
                  background: bottomOpen ? "var(--st-focus-soft)" : "transparent",
                  color: bottomOpen ? "var(--st-focus)" : "var(--ink-secondary)",
                }}
                title="Toggle AG Grid data drawer"
              >
                <Table2 className="h-3.5 w-3.5" />
                <span className="hidden sm:inline">Grid</span>
                {bottomOpen ? <ChevronDown className="h-3 w-3" /> : <ChevronUp className="h-3 w-3" />}
              </button>

              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="inline-flex items-center gap-1 rounded-lg border px-2 py-1 text-[11px] font-medium transition-colors hover:bg-[var(--bg-subtle)]"
                style={{
                  borderColor: "var(--border-subtle)",
                  color: "var(--ink-secondary)",
                }}
                title="Open another gloss HTML / SVG artifact"
              >
                <FolderOpen className="h-3.5 w-3.5" />
                <span className="hidden md:inline">Open</span>
              </button>
            </>
          )}

          <button
            type="button"
            onClick={toggleTheme}
            title={`Switch to ${theme === "paper" ? "Obsidian Lab (dark)" : "Paper Studio (light)"}`}
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
          {/* Signature 9-Stage Semantic Ladder Rail */}
          <StageRail />

          {/* 4-Zone Resizable IDE Workspace */}
          <div className="min-h-0 flex-1">
            <PanelGroup direction="horizontal" autoSaveId="gloss-wb-cols-v1">
              {/* LEFT: Structure, Context, R Code, Exports */}
              <Panel defaultSize={22} minSize={15} maxSize={38}>
                <LeftPanel />
              </Panel>

              <PanelResizeHandle className="resize-handle-h" />

              {/* CENTER + BOTTOM: Lossless SVG Stage + AG Grid Multi-Table Drawer */}
              <Panel defaultSize={52} minSize={30}>
                {bottomOpen ? (
                  <PanelGroup direction="vertical" autoSaveId="gloss-wb-rows-v1">
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

              {/* RIGHT: Semantic Evidence Chain, Audit Records, React Flow Lineage DAG */}
              <Panel defaultSize={26} minSize={18} maxSize={42}>
                <RightInspector />
              </Panel>
            </PanelGroup>
          </div>
        </div>
      )}

      {/* Drag-and-drop overlay when a bundle is already open */}
      {dragOverlay && (
        <div
          className="pointer-events-none fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-[2px]"
        >
          <div
            className="flex flex-col items-center gap-2 rounded-2xl border-2 border-dashed px-10 py-8 shadow-2xl"
            style={{
              background: "var(--bg-surface)",
              borderColor: "var(--st-focus)",
              color: "var(--ink-primary)",
            }}
          >
            <Upload className="h-8 w-8" style={{ color: "var(--st-focus)" }} />
            <div className="text-base font-bold">Drop to load new gloss artifact</div>
            <div className="text-xs" style={{ color: "var(--ink-secondary)" }}>
              Replaces current view with full SHA-256 verification
            </div>
          </div>
        </div>
      )}

      <CommandPalette />
      <ProposalModal />
    </div>
  );
};
