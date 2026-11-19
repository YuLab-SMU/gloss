import React, { useMemo, useState } from "react";
import {
  BookOpen,
  Check,
  CheckCircle2,
  Code2,
  Copy,
  Download,
  FileJson,
  FolderTree,
  ShieldCheck,
  XCircle,
} from "lucide-react";
import {
  buildAriaProjection,
  buildTextProjection,
  buildWebAnnotationProjection,
  type GlossContextItem,
} from "../../codec";
import { useWorkbenchStore, type LeftPanelTab } from "../../store/useWorkbenchStore";
import { CodeViewer } from "./CodeViewer";
import { OutlineTree } from "./OutlineTree";

const BUILTIN_CONTEXT_ITEMS = new Set(["code", "data", "engine", "env", "doc", "git"]);

function extractRCode(bundle: NonNullable<ReturnType<typeof useWorkbenchStore.getState>["bundle"]>): string {
  const codeVal = bundle.context.code?.value as Record<string, unknown> | null | undefined;
  if (!codeVal) {
    return "# No R plotting code was captured in context.json.";
  }
  const chunk = codeVal.chunk as Record<string, unknown> | undefined;
  const script = codeVal.script as Record<string, unknown> | undefined;
  const parts: string[] = [];
  if (typeof codeVal.call === "string") {
    parts.push(`# Captured call:\n# ${codeVal.call}`);
  }
  if (Array.isArray(codeVal.definition) && codeVal.definition.length > 0) {
    parts.push(`# Plot expression definition:\n${codeVal.definition.join("\n")}`);
  }
  if (typeof chunk?.code === "string") {
    parts.push(`# Knitr chunk (${String(chunk.label ?? "unnamed")}):\n${chunk.code}`);
  } else if (typeof script?.code === "string") {
    parts.push(`# Source file: ${String(script.path ?? "")}\n${script.code}`);
  }
  return parts.length > 0 ? parts.join("\n\n") : JSON.stringify(codeVal, null, 2);
}

const ExternalContextCard: React.FC<{ item: GlossContextItem }> = ({ item }) => {
  const val = item.value as Record<string, unknown> | null;
  if (!item.found || !val) return null;

  // Render structured data_dictionary variables cleanly
  if (item.item === "data_dictionary" && Array.isArray(val.variables)) {
    const vars = val.variables as Array<Record<string, unknown>>;
    return (
      <div
        className="rounded-lg border p-2.5"
        style={{ borderColor: "var(--st-contextual)", background: "var(--bg-surface)" }}
      >
        <div className="mb-1.5 flex items-center justify-between">
          <span className="font-mono-num text-[11px] font-bold" style={{ color: "var(--st-contextual)" }}>
            data_dictionary
          </span>
          {typeof val.source === "string" && (
            <span className="truncate text-[9.5px]" style={{ color: "var(--ink-muted)" }}>
              {val.source}
            </span>
          )}
        </div>
        <div className="space-y-1.5">
          {vars.map((v, i) => (
            <div
              key={i}
              className="rounded border px-2 py-1 text-[10.5px]"
              style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
            >
              <div className="flex items-center justify-between gap-2">
                <code className="font-mono-num font-bold" style={{ color: "var(--ink-primary)" }}>
                  {String(v.name ?? v.column ?? "")}
                </code>
                {v.unit !== undefined && (
                  <span
                    className="font-mono-num rounded px-1.5 py-0 text-[9.5px]"
                    style={{ background: "var(--st-contextual-soft)", color: "var(--st-contextual)" }}
                  >
                    {String(v.unit)}
                  </span>
                )}
              </div>
              {v.description !== undefined && (
                <div className="mt-0.5 text-[10px]" style={{ color: "var(--ink-secondary)" }}>
                  {String(v.description)}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    );
  }

  // Render dataset_documentation (Rd help summaries)
  if (item.item === "dataset_documentation" && Array.isArray(val.datasets)) {
    const docs = val.datasets as Array<Record<string, unknown>>;
    return (
      <div
        className="rounded-lg border p-2.5"
        style={{ borderColor: "var(--st-contextual)", background: "var(--bg-surface)" }}
      >
        <div className="mb-1 flex items-center justify-between">
          <span className="font-mono-num text-[11px] font-bold" style={{ color: "var(--st-contextual)" }}>
            dataset_documentation
          </span>
          <span className="text-[9.5px]" style={{ color: "var(--ink-muted)" }}>
            R package help
          </span>
        </div>
        {docs.map((d, i) => (
          <div key={i} className="mt-1 space-y-0.5 text-[10.5px]">
            <div className="font-semibold" style={{ color: "var(--ink-primary)" }}>
              {String(d.package ?? "")}::{String(d.dataset ?? "")} — {String(d.title ?? "")}
            </div>
            {typeof d.description === "string" && (
              <p className="leading-snug" style={{ color: "var(--ink-secondary)" }}>
                {d.description}
              </p>
            )}
          </div>
        ))}
      </div>
    );
  }

  // Render user_context (question + audience)
  if (item.item === "user_context") {
    return (
      <div
        className="rounded-lg border p-2.5"
        style={{ borderColor: "var(--st-focus)", background: "var(--st-focus-soft)" }}
      >
        <div className="mb-1 font-mono-num text-[11px] font-bold" style={{ color: "var(--st-focus)" }}>
          user_context
        </div>
        {typeof val.question === "string" && (
          <div className="text-[11px] font-medium" style={{ color: "var(--ink-primary)" }}>
            “{val.question}”
          </div>
        )}
        {typeof val.audience === "string" && (
          <div className="mt-1 text-[10px]" style={{ color: "var(--ink-secondary)" }}>
            Audience: <strong>{val.audience}</strong>
          </div>
        )}
      </div>
    );
  }

  // Generic external context card (literature, project_notes, ontology, external_metadata)
  return (
    <div
      className="rounded-lg border p-2.5"
      style={{ borderColor: "var(--border-strong)", background: "var(--bg-surface)" }}
    >
      <div className="flex items-center justify-between gap-2">
        <span className="font-mono-num text-[11px] font-bold" style={{ color: "var(--st-contextual)" }}>
          {item.item}
        </span>
        {typeof val.source === "string" && (
          <span className="truncate text-[9.5px]" style={{ color: "var(--ink-muted)" }}>
            {val.source}
          </span>
        )}
      </div>
      {typeof val.citation === "string" ? (
        <p className="mt-1 text-[10.5px] leading-snug" style={{ color: "var(--ink-primary)" }}>
          {val.citation}
          {typeof val.doi === "string" && (
            <span className="ml-1 font-mono-num text-[10px]" style={{ color: "var(--ink-muted)" }}>
              (DOI: {val.doi})
            </span>
          )}
        </p>
      ) : typeof val.excerpt === "string" ? (
        <pre className="mt-1 max-h-32 overflow-auto whitespace-pre-wrap font-mono-num text-[10px]" style={{ color: "var(--ink-secondary)" }}>
          {val.excerpt}
        </pre>
      ) : (
        <pre className="mt-1 max-h-32 overflow-auto whitespace-pre-wrap break-words font-mono-num text-[10px]" style={{ color: "var(--ink-secondary)" }}>
          {JSON.stringify(val, null, 2)}
        </pre>
      )}
    </div>
  );
};

export const LeftPanel: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const leftTab = useWorkbenchStore((s) => s.leftTab);
  const setLeftTab = useWorkbenchStore((s) => s.setLeftTab);

  const [codeSubTab, setCodeSubTab] = useState<"r" | "jsonl" | "manifest">("r");
  const [exportFormat, setExportFormat] = useState<"aria" | "text" | "annotation">("aria");
  const [copied, setCopied] = useState(false);

  const jsonlCombined = useMemo(() => {
    if (!bundle) return "";
    const parts: string[] = [];
    for (const [nm, st] of Object.entries(bundle.layers)) {
      if (st.events.length === 0) continue;
      parts.push(`// layers/${nm}.jsonl (${st.events.length} event${st.events.length === 1 ? "" : "s"})`);
      for (const ev of st.events) {
        parts.push(JSON.stringify(ev.raw, null, 2));
      }
    }
    return parts.length > 0 ? parts.join("\n\n") : "// No append-only layer events recorded yet.";
  }, [bundle]);

  const exportContent = useMemo(() => {
    if (!bundle) return "";
    if (exportFormat === "aria") return JSON.stringify(buildAriaProjection(bundle), null, 2);
    if (exportFormat === "annotation") {
      return JSON.stringify(buildWebAnnotationProjection(bundle), null, 2);
    }
    return buildTextProjection(bundle);
  }, [bundle, exportFormat]);

  if (!bundle) return null;

  const handleCopy = async (txt: string) => {
    try {
      await navigator.clipboard.writeText(txt);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // ignore
    }
  };

  const handleDownload = (txt: string, filename: string) => {
    const blob = new Blob([txt], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  };

  const navTabs: Array<{ id: LeftPanelTab; label: string; icon: React.ReactNode }> = [
    { id: "structure", label: "Outline", icon: <FolderTree className="h-3.5 w-3.5" /> },
    { id: "context", label: "Context", icon: <BookOpen className="h-3.5 w-3.5" /> },
    { id: "code", label: "Code", icon: <Code2 className="h-3.5 w-3.5" /> },
    { id: "exports", label: "Export", icon: <FileJson className="h-3.5 w-3.5" /> },
  ];

  const contextItems = Object.values(bundle.context);
  const builtinContext = contextItems.filter((c) => BUILTIN_CONTEXT_ITEMS.has(c.item));
  const externalFound = contextItems.filter((c) => !BUILTIN_CONTEXT_ITEMS.has(c.item) && c.found);
  const externalMissing = contextItems.filter((c) => !BUILTIN_CONTEXT_ITEMS.has(c.item) && !c.found);
  const contextualRecords = bundle.records.filter((r) => r.workbenchStage === "contextual");

  return (
    <div
      className="flex h-full w-full flex-col overflow-hidden"
      style={{ background: "var(--bg-surface)" }}
    >
      {/* Top 4-tab switcher */}
      <div
        className="grid grid-cols-4 border-b p-1"
        style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
      >
        {navTabs.map((t) => {
          const active = leftTab === t.id;
          return (
            <button
              key={t.id}
              type="button"
              onClick={() => setLeftTab(t.id)}
              className="flex items-center justify-center gap-1 rounded-md py-1.5 text-[11px] font-semibold transition-colors"
              style={{
                background: active ? "var(--bg-surface)" : "transparent",
                color: active ? "var(--st-focus)" : "var(--ink-secondary)",
                boxShadow: active ? "0 1px 2px rgba(0,0,0,0.08)" : "none",
              }}
            >
              {t.icon}
              <span>{t.label}</span>
            </button>
          );
        })}
      </div>

      {/* TAB 1: DESIGN-TOOL OUTLINE TREE + MULTI-LEVEL FOCUS */}
      {leftTab === "structure" && <OutlineTree />}

      {/* TAB 2: CONTEXT & EXTERNAL SOURCES */}
      {leftTab === "context" && (
        <div className="min-h-0 flex-1 space-y-3 overflow-y-auto p-3 text-xs">
          {/* Integrity & Bundle Health */}
          <div
            className="rounded-lg border p-2.5"
            style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
          >
            <div className="mb-1.5 flex items-center justify-between">
              <span className="flex items-center gap-1.5 font-semibold" style={{ color: "var(--ink-primary)" }}>
                <ShieldCheck className="h-3.5 w-3.5" style={{ color: "var(--st-verified)" }} />
                Bundle Integrity
              </span>
              <span
                className="font-mono-num rounded-full px-2 py-0.5 text-[10px] font-semibold"
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
                {bundle.integrity.mismatches.length === 0
                  ? `${bundle.integrity.passed}/${bundle.integrity.checked} SHA-256 OK`
                  : `${bundle.integrity.mismatches.length} Mismatch`}
              </span>
            </div>
            <div className="grid grid-cols-2 gap-1 font-mono-num text-[10.5px]" style={{ color: "var(--ink-secondary)" }}>
              <div>format: v{bundle.formatVersion ?? "—"}</div>
              <div>embed: {bundle.embed ?? "—"}</div>
              <div>gloss: {bundle.glossVersion ?? "—"}</div>
              <div>files: {bundle.files.length}</div>
            </div>
          </div>

          {/* External Context Sources (Task 5A) */}
          <div>
            <div
              className="mb-1.5 flex items-center justify-between text-[10.5px] font-bold uppercase tracking-wider"
              style={{ color: "var(--st-contextual)" }}
            >
              <span>External Context ({externalFound.length})</span>
            </div>
            {externalFound.length === 0 && contextualRecords.length === 0 ? (
              <div
                className="rounded-lg border border-dashed p-3 text-[11px] leading-relaxed"
                style={{ borderColor: "var(--border-strong)", color: "var(--ink-muted)" }}
              >
                Attach domain metadata with <code className="font-mono-num">gl_add_context()</code>{" "}
                (<code className="font-mono-num">data_dictionary</code>,{" "}
                <code className="font-mono-num">project_notes</code>,{" "}
                <code className="font-mono-num">ontology</code>,{" "}
                <code className="font-mono-num">literature</code>,{" "}
                <code className="font-mono-num">user_context</code>).
              </div>
            ) : (
              <div className="space-y-2">
                {externalFound.map((c) => (
                  <ExternalContextCard key={c.item} item={c} />
                ))}
                {externalMissing.length > 0 && (
                  <div className="flex flex-wrap gap-1 pt-0.5">
                    {externalMissing.map((m) => (
                      <span
                        key={m.item}
                        title={m.reason ?? "not attached"}
                        className="font-mono-num rounded border border-dashed px-1.5 py-0.5 text-[9.5px]"
                        style={{ borderColor: "var(--border-strong)", color: "var(--ink-muted)" }}
                      >
                        {m.item}: empty
                      </span>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Core Sniffed Context */}
          <div>
            <div
              className="mb-1.5 text-[10.5px] font-bold uppercase tracking-wider"
              style={{ color: "var(--ink-muted)" }}
            >
              Core Capture Context (gl_context)
            </div>
            <div className="space-y-1.5">
              {builtinContext.map((c) => (
                <div
                  key={c.item}
                  className="rounded-lg border p-2"
                  style={{ borderColor: "var(--border-subtle)", background: "var(--bg-surface)" }}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-mono-num font-semibold" style={{ color: "var(--ink-primary)" }}>
                      {c.item}
                    </span>
                    {c.found ? (
                      <span
                        className="inline-flex items-center gap-1 text-[10px] font-semibold"
                        style={{ color: "var(--st-verified)" }}
                      >
                        <CheckCircle2 className="h-3 w-3" /> found
                      </span>
                    ) : (
                      <span
                        className="inline-flex items-center gap-1 text-[10px]"
                        style={{ color: "var(--ink-muted)" }}
                      >
                        <XCircle className="h-3 w-3" /> empty
                      </span>
                    )}
                  </div>
                  {!c.found && c.reason && (
                    <p className="mt-1 text-[10.5px]" style={{ color: "var(--ink-muted)" }}>
                      {c.reason}
                    </p>
                  )}
                  {c.found && c.item === "engine" && Boolean(c.value && typeof c.value === "object") && (
                    <p className="mt-1 font-mono-num text-[10.5px]" style={{ color: "var(--ink-secondary)" }}>
                      {JSON.stringify(c.value).slice(0, 140)}
                    </p>
                  )}
                  {c.found && c.item === "git" && Boolean(c.value && typeof c.value === "object") && (
                    <p className="mt-1 font-mono-num text-[10.5px]" style={{ color: "var(--ink-secondary)" }}>
                      branch: {String((c.value as Record<string, unknown>).branch ?? "—")} · commit:{" "}
                      {String((c.value as Record<string, unknown>).commit ?? "—").slice(0, 8)}
                    </p>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: CODE & APPEND-ONLY JSONL LOG (CodeMirror 6) */}
      {leftTab === "code" && (
        <div className="flex min-h-0 flex-1 flex-col">
          <div
            className="flex items-center gap-1 border-b px-2 py-1.5 text-[11px]"
            style={{ borderColor: "var(--border-subtle)" }}
          >
            {(
              [
                ["r", "R Code"],
                ["jsonl", "Layers JSONL"],
                ["manifest", "Operations"],
              ] as const
            ).map(([k, lbl]) => (
              <button
                key={k}
                type="button"
                onClick={() => setCodeSubTab(k)}
                className="rounded px-2 py-0.5 font-medium"
                style={{
                  background: codeSubTab === k ? "var(--st-focus-soft)" : "transparent",
                  color: codeSubTab === k ? "var(--st-focus)" : "var(--ink-secondary)",
                }}
              >
                {lbl}
              </button>
            ))}
          </div>
          <div className="min-h-0 flex-1 overflow-auto">
            {codeSubTab === "r" && <CodeViewer value={extractRCode(bundle)} language="r" />}
            {codeSubTab === "jsonl" && <CodeViewer value={jsonlCombined} language="json" />}
            {codeSubTab === "manifest" && (
              <CodeViewer value={JSON.stringify(bundle.operations, null, 2)} language="json" />
            )}
          </div>
        </div>
      )}

      {/* TAB 4: PROJECTIONS & EXPORTS */}
      {leftTab === "exports" && (
        <div className="flex min-h-0 flex-1 flex-col">
          <div
            className="flex items-center justify-between border-b px-2 py-1.5 text-[11px]"
            style={{ borderColor: "var(--border-subtle)" }}
          >
            <div className="flex items-center gap-1">
              {(
                [
                  ["aria", "ARIA"],
                  ["text", "Text"],
                  ["annotation", "W3C Anno"],
                ] as const
              ).map(([k, lbl]) => (
                <button
                  key={k}
                  type="button"
                  onClick={() => setExportFormat(k)}
                  className="rounded px-2 py-0.5 font-medium"
                  style={{
                    background: exportFormat === k ? "var(--st-focus-soft)" : "transparent",
                    color: exportFormat === k ? "var(--st-focus)" : "var(--ink-secondary)",
                  }}
                >
                  {lbl}
                </button>
              ))}
            </div>
            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => void handleCopy(exportContent)}
                className="rounded p-1 hover:bg-[var(--bg-subtle)]"
                title="Copy projection"
                style={{ color: "var(--ink-secondary)" }}
              >
                {copied ? <Check className="h-3.5 w-3.5" style={{ color: "var(--st-verified)" }} /> : <Copy className="h-3.5 w-3.5" />}
              </button>
              <button
                type="button"
                onClick={() =>
                  handleDownload(
                    exportContent,
                    `gloss-${exportFormat}.${exportFormat === "text" ? "txt" : "json"}`
                  )
                }
                className="rounded p-1 hover:bg-[var(--bg-subtle)]"
                title="Download projection"
                style={{ color: "var(--ink-secondary)" }}
              >
                <Download className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
          <div className="min-h-0 flex-1 overflow-auto">
            <CodeViewer
              value={exportContent}
              language={exportFormat === "text" ? "text" : "json"}
            />
          </div>
        </div>
      )}
    </div>
  );
};
