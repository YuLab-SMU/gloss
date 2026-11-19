import React, { useMemo, useState } from "react";
import {
  AlertTriangle,
  BookOpen,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  Code2,
  Copy,
  Download,
  Eye,
  EyeOff,
  FileJson,
  FolderTree,
  Layers,
  Search,
  ShieldCheck,
  XCircle,
} from "lucide-react";
import {
  buildAriaProjection,
  buildTextProjection,
  buildWebAnnotationProjection,
  type GlossLeaf,
} from "../../codec";
import { useWorkbenchStore, type LeftPanelTab } from "../../store/useWorkbenchStore";
import { CodeViewer } from "./CodeViewer";

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

export const LeftPanel: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const leftTab = useWorkbenchStore((s) => s.leftTab);
  const setLeftTab = useWorkbenchStore((s) => s.setLeftTab);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const selectedLeafId = useWorkbenchStore((s) => s.selectedLeafId);
  const hiddenLeafIds = useWorkbenchStore((s) => s.hiddenLeafIds);
  const selectElement = useWorkbenchStore((s) => s.selectElement);
  const selectLeaf = useWorkbenchStore((s) => s.selectLeaf);
  const toggleLeafVisibility = useWorkbenchStore((s) => s.toggleLeafVisibility);

  const [treeSearch, setTreeSearch] = useState("");
  const [expandedLeaves, setExpandedLeaves] = useState<Record<string, boolean>>({});
  const [codeSubTab, setCodeSubTab] = useState<"r" | "jsonl" | "manifest">("r");
  const [exportFormat, setExportFormat] = useState<"aria" | "text" | "annotation">("aria");
  const [copied, setCopied] = useState(false);

  const leavesByPanel = useMemo(() => {
    if (!bundle) return new Map<string, GlossLeaf[]>();
    const map = new Map<string, GlossLeaf[]>();
    for (const lf of bundle.substrate.leaves) {
      const key = lf.panel ?? "__chrome__";
      const list = map.get(key);
      if (list) list.push(lf);
      else map.set(key, [lf]);
    }
    return map;
  }, [bundle]);

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

  const selectedElSet = new Set(selectedElementIds);
  const hiddenSet = new Set(hiddenLeafIds);
  const q = treeSearch.trim().toLowerCase();

  const handleCopy = async (txt: string) => {
    try {
      await navigator.clipboard.writeText(txt);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // ignore clipboard errors in restricted frames
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
    { id: "structure", label: "Tree", icon: <FolderTree className="h-3.5 w-3.5" /> },
    { id: "context", label: "Context", icon: <BookOpen className="h-3.5 w-3.5" /> },
    { id: "code", label: "Code", icon: <Code2 className="h-3.5 w-3.5" /> },
    { id: "exports", label: "Export", icon: <FileJson className="h-3.5 w-3.5" /> },
  ];

  const contextItems = Object.values(bundle.context);
  const builtinContext = contextItems.filter((c) => BUILTIN_CONTEXT_ITEMS.has(c.item));
  const externalContext = contextItems.filter((c) => !BUILTIN_CONTEXT_ITEMS.has(c.item));
  const contextualRecords = bundle.records.filter((r) => r.workbenchStage === "contextual");

  const panelGroups: Array<{ key: string; title: string; subtitle: string }> = [
    ...bundle.substrate.panels.map((p) => ({
      key: p.id,
      title: p.key ?? p.id,
      subtitle: `${p.id} · ${p.x_type ?? ""} × ${p.y_type ?? ""}`,
    })),
    { key: "__chrome__", title: "Guides, Axes & Chrome", subtitle: "outside panels" },
  ];

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

      {/* TAB 1: STRUCTURE TREE */}
      {leftTab === "structure" && (
        <div className="flex min-h-0 flex-1 flex-col">
          <div className="border-b p-2" style={{ borderColor: "var(--border-subtle)" }}>
            <div
              className="flex items-center gap-1.5 rounded-md border px-2 py-1"
              style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
            >
              <Search className="h-3.5 w-3.5" style={{ color: "var(--ink-muted)" }} />
              <input
                type="text"
                value={treeSearch}
                onChange={(e) => setTreeSearch(e.target.value)}
                placeholder="Filter leaf, role, e65, Mazda..."
                className="w-full bg-transparent text-xs focus:outline-none"
                style={{ color: "var(--ink-primary)" }}
              />
            </div>
          </div>

          <div className="min-h-0 flex-1 overflow-y-auto p-2 text-xs">
            {/* Engine & Page Verdict Summary */}
            <div
              className="mb-2.5 rounded-lg border p-2"
              style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
            >
              <div className="flex items-center justify-between text-[11px]">
                <span className="font-semibold" style={{ color: "var(--ink-primary)" }}>
                  <Layers className="mr-1 inline h-3.5 w-3.5" style={{ color: "var(--st-focus)" }} />
                  {bundle.engine ?? "plain SVG"} engine
                </span>
                <span className="font-mono-num text-[10.5px]" style={{ color: "var(--ink-muted)" }}>
                  {bundle.substrate.leaves.length} leaves · {bundle.substrate.elements.length} els
                </span>
              </div>
            </div>

            {panelGroups.map((pg) => {
              const leaves = (leavesByPanel.get(pg.key) ?? []).filter((lf) => {
                if (!q) return true;
                if (
                  lf.id.toLowerCase().includes(q) ||
                  lf.name.toLowerCase().includes(q) ||
                  lf.path.toLowerCase().includes(q)
                ) {
                  return true;
                }
                const els = bundle.substrate.elements.filter((e) => e.leaf === lf.id);
                return els.some((e) => {
                  const raw = bundle.index.inferredRawByElement.get(e.id);
                  return (
                    e.id.toLowerCase().includes(q) ||
                    (e.text ?? "").toLowerCase().includes(q) ||
                    (raw?.rawKeyLabels.join(" ").toLowerCase().includes(q) ?? false)
                  );
                });
              });

              if (leaves.length === 0) return null;

              return (
                <div key={pg.key} className="mb-3">
                  <div className="mb-1 flex items-center justify-between px-1">
                    <span
                      className="text-[10.5px] font-bold uppercase tracking-wider"
                      style={{ color: "var(--ink-muted)" }}
                    >
                      {pg.title}
                    </span>
                    <span className="font-mono-num text-[10px]" style={{ color: "var(--ink-muted)" }}>
                      {leaves.length}
                    </span>
                  </div>

                  <div className="space-y-0.5">
                    {leaves.map((lf) => {
                      const roleLeaf = bundle.derived.rolesLeaves.find((r) => r.leaf === lf.id);
                      const bindLeaf = bundle.derived.bindingsLeaves.find((b) => b.leaf === lf.id);
                      const isOpen = Boolean(expandedLeaves[lf.id]) || Boolean(q);
                      const isHidden = hiddenSet.has(lf.id);
                      const isSelectedLeaf = selectedLeafId === lf.id;

                      const childEls = isOpen
                        ? bundle.substrate.elements
                            .filter((e) => e.leaf === lf.id)
                            .filter((e) => {
                              if (!q) return true;
                              const raw = bundle.index.inferredRawByElement.get(e.id);
                              return (
                                e.id.toLowerCase().includes(q) ||
                                e.tag.toLowerCase().includes(q) ||
                                (e.text ?? "").toLowerCase().includes(q) ||
                                (raw?.rawKeyLabels.join(" ").toLowerCase().includes(q) ?? false)
                              );
                            })
                            .slice(0, 120)
                        : [];

                      return (
                        <div key={lf.id}>
                          <div
                            className="group flex items-center gap-1 rounded-md px-1 py-1 transition-colors hover:bg-[var(--bg-subtle)]"
                            style={{
                              background: isSelectedLeaf ? "var(--st-focus-soft)" : undefined,
                            }}
                          >
                            <button
                              type="button"
                              onClick={() =>
                                setExpandedLeaves((prev) => ({ ...prev, [lf.id]: !prev[lf.id] }))
                              }
                              className="p-0.5"
                              style={{ color: "var(--ink-muted)" }}
                            >
                              {isOpen ? (
                                <ChevronDown className="h-3 w-3" />
                              ) : (
                                <ChevronRight className="h-3 w-3" />
                              )}
                            </button>

                            <button
                              type="button"
                              onClick={() => selectLeaf(lf.id)}
                              className="flex min-w-0 flex-1 items-center gap-1.5 text-left"
                            >
                              <span
                                className="font-mono-num shrink-0 text-[10.5px] font-semibold"
                                style={{ color: "var(--st-focus)" }}
                              >
                                {lf.id}
                              </span>
                              <span
                                className="truncate text-[11px]"
                                style={{ color: "var(--ink-primary)" }}
                                title={lf.path}
                              >
                                {roleLeaf?.kind ?? lf.name}
                              </span>
                            </button>

                            <div className="flex shrink-0 items-center gap-1">
                              {lf.status !== "ok" && (
                                <span
                                  title={`Leaf status: ${lf.status} (expected ${lf.n_expected}, drawn ${lf.n_drawn})`}
                                  style={{ color: "var(--st-warn)" }}
                                >
                                  <AlertTriangle className="h-3 w-3" />
                                </span>
                              )}
                              {bindLeaf && bindLeaf.verified > 0 && (
                                <span
                                  className="font-mono-num rounded px-1 text-[9.5px] font-semibold"
                                  style={{
                                    background: "var(--st-verified-soft)",
                                    color: "var(--st-verified)",
                                  }}
                                >
                                  {bindLeaf.verified}✓
                                </span>
                              )}
                              <span className="font-mono-num text-[10px]" style={{ color: "var(--ink-muted)" }}>
                                {lf.n_drawn}
                              </span>
                              <button
                                type="button"
                                onClick={() => toggleLeafVisibility(lf.id)}
                                title={isHidden ? "Show leaf" : "Dim/hide leaf on canvas"}
                                className="opacity-40 transition-opacity hover:opacity-100 group-hover:opacity-80"
                                style={{ color: isHidden ? "var(--st-warn)" : "var(--ink-muted)" }}
                              >
                                {isHidden ? <EyeOff className="h-3 w-3" /> : <Eye className="h-3 w-3" />}
                              </button>
                            </div>
                          </div>

                          {isOpen && childEls.length > 0 && (
                            <div
                              className="ml-4 border-l pl-2"
                              style={{ borderColor: "var(--border-subtle)" }}
                            >
                              {childEls.map((el) => {
                                const b = bundle.index.bindingByElement.get(el.id);
                                const raw = bundle.index.inferredRawByElement.get(el.id);
                                const recs = bundle.index.recordsByElement.get(el.id) ?? [];
                                const isSel = selectedElSet.has(el.id);
                                return (
                                  <button
                                    key={el.id}
                                    type="button"
                                    onClick={() => selectElement(el.id)}
                                    className="flex w-full items-center justify-between gap-1 rounded px-1.5 py-0.5 text-left text-[11px] hover:bg-[var(--bg-subtle)]"
                                    style={{
                                      background: isSel ? "var(--st-focus-soft)" : undefined,
                                      color: isSel ? "var(--st-focus)" : "var(--ink-primary)",
                                    }}
                                  >
                                    <span className="flex min-w-0 items-center gap-1.5">
                                      <span className="font-mono-num font-semibold">{el.id}</span>
                                      <span className="truncate text-[10.5px]" style={{ color: "var(--ink-secondary)" }}>
                                        {raw?.rawKeyLabels[0] ?? el.text ?? el.tag}
                                      </span>
                                    </span>
                                    <span className="flex shrink-0 items-center gap-1">
                                      {recs.length > 0 && (
                                        <span
                                          className="h-1.5 w-1.5 rounded-full"
                                          style={{ background: "var(--st-contextual)" }}
                                          title={`${recs.length} semantic record(s)`}
                                        />
                                      )}
                                      {b && (
                                        <span
                                          className="h-1.5 w-1.5 rounded-full"
                                          style={{
                                            background:
                                              b.status === "verified"
                                                ? "var(--st-verified)"
                                                : "var(--st-warn)",
                                          }}
                                          title={`Binding: ${b.status}`}
                                        />
                                      )}
                                    </span>
                                  </button>
                                );
                              })}
                              {lf.n_drawn > 120 && (
                                <div className="px-1.5 py-1 text-[10px]" style={{ color: "var(--ink-muted)" }}>
                                  Showing first 120 of {lf.n_drawn.toLocaleString()} elements (use AG Grid for all rows)
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

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

          {/* Built-in Sniffed Context */}
          <div>
            <div
              className="mb-1.5 text-[10.5px] font-bold uppercase tracking-wider"
              style={{ color: "var(--ink-muted)" }}
            >
              Sniffed Context (gl_context)
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

          {/* External Context Sources (Forward-compatible with extended gl_context plugins) */}
          <div>
            <div
              className="mb-1.5 text-[10.5px] font-bold uppercase tracking-wider"
              style={{ color: "var(--st-contextual)" }}
            >
              External Context Sources
            </div>
            {externalContext.length === 0 && contextualRecords.length === 0 ? (
              <div
                className="rounded-lg border border-dashed p-3 text-[11px] leading-relaxed"
                style={{ borderColor: "var(--border-strong)", color: "var(--ink-muted)" }}
              >
                No external context plugins (<code className="font-mono-num">data_dictionary</code>,{" "}
                <code className="font-mono-num">project_notes</code>,{" "}
                <code className="font-mono-num">ontology</code>,{" "}
                <code className="font-mono-num">user_context</code>) attached to this bundle yet.
              </div>
            ) : (
              <div className="space-y-1.5">
                {externalContext.map((c) => (
                  <div
                    key={c.item}
                    className="rounded-lg border p-2"
                    style={{
                      borderColor: "var(--st-contextual)",
                      background: "var(--st-contextual-soft)",
                    }}
                  >
                    <div className="font-mono-num text-[11px] font-semibold" style={{ color: "var(--st-contextual)" }}>
                      {c.item}
                    </div>
                    <pre className="mt-1 whitespace-pre-wrap break-words font-mono-num text-[10px]" style={{ color: "var(--ink-primary)" }}>
                      {typeof c.value === "string" ? c.value : JSON.stringify(c.value, null, 2)}
                    </pre>
                  </div>
                ))}
                {contextualRecords.map((rec) => (
                  <div
                    key={rec.id}
                    className="rounded-lg border p-2"
                    style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
                  >
                    <div className="flex items-center justify-between text-[10.5px]">
                      <span className="font-semibold" style={{ color: "var(--st-contextual)" }}>
                        {rec.body.source_type ?? rec.body.type ?? "domain_context"}
                      </span>
                      <span className="font-mono-num text-[10px]" style={{ color: "var(--ink-muted)" }}>
                        {rec.body.source ?? rec.provenance.by}
                      </span>
                    </div>
                    <p className="mt-1 text-[11px]" style={{ color: "var(--ink-primary)" }}>
                      {rec.body.text ?? rec.body.description}
                    </p>
                  </div>
                ))}
              </div>
            )}
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
