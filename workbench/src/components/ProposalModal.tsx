import React, { useState } from "react";
import { Check, CheckCircle2, Copy, Radio, Sparkles, X, XCircle } from "lucide-react";
import { useWorkbenchStore } from "../store/useWorkbenchStore";

export const ProposalModal: React.FC = () => {
  const open = useWorkbenchStore((s) => s.proposalModalOpen);
  const setOpen = useWorkbenchStore((s) => s.setProposalModalOpen);
  const bundle = useWorkbenchStore((s) => s.bundle);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const focusScope = useWorkbenchStore((s) => s.focusScope);
  const liveApiBaseUrl = useWorkbenchStore((s) => s.liveApiBaseUrl);
  const refreshLiveBundle = useWorkbenchStore((s) => s.refreshLiveBundle);

  const [layer, setLayer] = useState<"meaning" | "claim" | "relation" | "narrative">("meaning");
  const [text, setText] = useState("");
  const [source, setSource] = useState("");
  const [sourceType, setSourceType] = useState("dataset_metadata");
  const [provenance, setProvenance] = useState<"derived" | "speculative" | "direct">("derived");
  const [confidence, setConfidence] = useState("0.9");

  // Optional check fields for claim layer
  const [checkTable, setCheckTable] = useState("built_layer1");
  const [checkExpect, setCheckExpect] = useState<"negative" | "positive" | "zero">("negative");
  const [submitting, setSubmitting] = useState(false);
  const [feedback, setFeedback] = useState<{ ok: boolean; msg: string } | null>(null);
  const [copied, setCopied] = useState(false);

  if (!open || !bundle) return null;

  const targetId =
    selectedElementIds[0] ??
    focusScope?.elementIds[0] ??
    bundle.derived.bindingsElements[0]?.element ??
    bundle.substrate.elements[0]?.id ??
    "e1";

  const builtTables = bundle.tableOrder.filter((t) => bundle.tables[t]?.meta.role !== "raw");

  const buildPayload = () => {
    const body: Record<string, unknown> = { text: text.trim() };
    if (layer === "meaning") {
      body.type = source.trim() ? "domain_interpretation" : "analytical_meaning";
      body.provenance = provenance;
      if (source.trim()) {
        body.source = source.trim();
        body.source_type = sourceType;
      }
      const confNum = Number(confidence);
      if (Number.isFinite(confNum) && confNum >= 0 && confNum <= 1) {
        body.confidence = confNum;
      }
    } else if (layer === "claim") {
      body.check = {
        kind: "trend",
        table: builtTables.includes(checkTable) ? checkTable : builtTables[0] ?? "built_layer1",
        args: { response: "y", predictor: "x", expect: checkExpect },
      };
    }
    return {
      layer,
      anchor: { element: targetId },
      body,
      by: "workbench-user",
    };
  };

  const rSnippet = () => {
    const p = buildPayload();
    if (layer === "claim") {
      return `fig <- gl_record(\n  fig, "claim", gl_anchor(element = "${targetId}"),\n  list(\n    text = ${JSON.stringify(text.trim() || "Describe your checkable claim")},\n    check = list(kind = "trend", table = "${(p.body.check as Record<string, string>).table}", args = list(response = "y", predictor = "x", expect = "${checkExpect}"))\n  ),\n  by = "analyst"\n)`;
    }
    return `fig <- gl_record(\n  fig, "${layer}", gl_anchor(element = "${targetId}"),\n  list(\n    type = "${String(p.body.type ?? layer)}",\n    text = ${JSON.stringify(text.trim() || "Write your contextual or analytical note")},${
      source.trim()
        ? `\n    source = ${JSON.stringify(source.trim())},\n    source_type = "${sourceType}",`
        : ""
    }\n    provenance = "${provenance}",\n    confidence = ${Number(confidence) || 0.9}\n  ),\n  by = "analyst"\n)`;
  };

  const handleSubmitLive = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!text.trim() || liveApiBaseUrl === null) return;
    setSubmitting(true);
    setFeedback(null);
    try {
      const res = await fetch(`${liveApiBaseUrl}/api/propose`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(buildPayload()),
      });
      const json = (await res.json()) as { ok?: boolean; error?: string; record?: { status?: string } };
      if (!res.ok || !json.ok) {
        setFeedback({ ok: false, msg: json.error ?? `Rejected (HTTP ${res.status})` });
      } else {
        await refreshLiveBundle();
        setFeedback({
          ok: true,
          msg: `Committed to live R session (${json.record?.status ?? "recorded"}).`,
        });
        setText("");
      }
    } catch (err) {
      setFeedback({ ok: false, msg: err instanceof Error ? err.message : String(err) });
    } finally {
      setSubmitting(false);
    }
  };

  const handleCopyR = async () => {
    try {
      await navigator.clipboard.writeText(rSnippet());
      setCopied(true);
      setTimeout(() => setCopied(false), 1600);
    } catch {
      // ignore
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4 backdrop-blur-[1px]"
      onClick={() => setOpen(false)}
    >
      <div
        className="w-full max-w-lg overflow-hidden rounded-2xl border shadow-2xl"
        style={{
          background: "var(--bg-surface)",
          borderColor: "var(--border-strong)",
          boxShadow: "var(--shadow-float)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div
          className="flex items-center justify-between border-b px-4 py-3"
          style={{ borderColor: "var(--border-subtle)" }}
        >
          <div className="flex items-center gap-2">
            <Sparkles className="h-4 w-4" style={{ color: "var(--st-focus)" }} />
            <span className="text-sm font-bold" style={{ color: "var(--ink-primary)" }}>
              Propose Semantic Record
            </span>
            <span
              className="font-mono-num rounded-full px-2 py-0.5 text-[10px] font-semibold"
              style={{
                background: liveApiBaseUrl !== null ? "var(--st-verified-soft)" : "var(--bg-subtle)",
                color: liveApiBaseUrl !== null ? "var(--st-verified)" : "var(--ink-secondary)",
              }}
            >
              {liveApiBaseUrl !== null ? "Live R Session" : "Static Mode · R Snippet"}
            </span>
          </div>
          <button
            type="button"
            onClick={() => setOpen(false)}
            className="rounded p-1 hover:bg-[var(--bg-subtle)]"
            style={{ color: "var(--ink-muted)" }}
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <form onSubmit={handleSubmitLive} className="space-y-3 p-4 text-xs">
          <div className="flex items-center justify-between gap-2 rounded-lg border px-3 py-2" style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}>
            <span style={{ color: "var(--ink-secondary)" }}>Anchor Target</span>
            <code className="font-mono-num font-bold" style={{ color: "var(--st-focus)" }}>
              element = {targetId}
            </code>
          </div>

          <div className="grid grid-cols-4 gap-1.5">
            {(["meaning", "claim", "relation", "narrative"] as const).map((l) => (
              <button
                key={l}
                type="button"
                onClick={() => setLayer(l)}
                className="rounded-lg border py-1.5 text-xs font-semibold capitalize"
                style={{
                  borderColor: layer === l ? "var(--st-focus)" : "var(--border-subtle)",
                  background: layer === l ? "var(--st-focus-soft)" : "transparent",
                  color: layer === l ? "var(--st-focus)" : "var(--ink-secondary)",
                }}
              >
                {l}
              </button>
            ))}
          </div>

          <div>
            <label className="mb-1 block text-[11px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
              Semantic Statement
            </label>
            <textarea
              rows={3}
              value={text}
              onChange={(e) => setText(e.target.value)}
              placeholder={
                layer === "claim"
                  ? "e.g., Heavier cars have lower fuel economy in built_layer1."
                  : "e.g., This mark corresponds to an activated T-cell cluster based on CD3D/IL7R."
              }
              className="w-full rounded-lg border p-2 text-xs focus:outline-none"
              style={{
                background: "var(--bg-canvas)",
                borderColor: "var(--border-subtle)",
                color: "var(--ink-primary)",
              }}
            />
          </div>

          {layer === "meaning" && (
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="mb-1 block text-[10.5px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
                  External Source (optional)
                </label>
                <input
                  type="text"
                  value={source}
                  onChange={(e) => setSource(e.target.value)}
                  placeholder="sample_annotation.csv / DOI"
                  className="w-full rounded-lg border px-2 py-1.5 text-xs focus:outline-none"
                  style={{
                    background: "var(--bg-canvas)",
                    borderColor: "var(--border-subtle)",
                    color: "var(--ink-primary)",
                  }}
                />
              </div>
              <div>
                <label className="mb-1 block text-[10.5px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
                  Source Type & Confidence
                </label>
                <div className="flex gap-1.5">
                  <select
                    value={sourceType}
                    onChange={(e) => setSourceType(e.target.value)}
                    className="flex-1 rounded-lg border px-1.5 py-1.5 text-[11px]"
                    style={{
                      background: "var(--bg-canvas)",
                      borderColor: "var(--border-subtle)",
                      color: "var(--ink-primary)",
                    }}
                  >
                    <option value="dataset_metadata">dataset_metadata</option>
                    <option value="data_dictionary">data_dictionary</option>
                    <option value="ontology">ontology</option>
                    <option value="literature">literature</option>
                    <option value="project_notes">project_notes</option>
                  </select>
                  <input
                    type="number"
                    min="0"
                    max="1"
                    step="0.05"
                    value={confidence}
                    onChange={(e) => setConfidence(e.target.value)}
                    className="font-mono-num w-16 rounded-lg border px-2 py-1.5 text-xs"
                    style={{
                      background: "var(--bg-canvas)",
                      borderColor: "var(--border-subtle)",
                      color: "var(--ink-primary)",
                    }}
                  />
                </div>
              </div>
              <div className="col-span-2 flex items-center gap-2">
                <span className="text-[10.5px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
                  Provenance:
                </span>
                {(["direct", "derived", "speculative"] as const).map((p) => (
                  <button
                    key={p}
                    type="button"
                    onClick={() => setProvenance(p)}
                    className="rounded-full px-2.5 py-0.5 text-[10.5px] font-semibold"
                    style={{
                      background: provenance === p ? "var(--st-contextual-soft)" : "var(--bg-subtle)",
                      color: provenance === p ? "var(--st-contextual)" : "var(--ink-secondary)",
                    }}
                  >
                    {p}
                  </button>
                ))}
              </div>
            </div>
          )}

          {layer === "claim" && (
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="mb-1 block text-[10.5px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
                  Check Table
                </label>
                <select
                  value={checkTable}
                  onChange={(e) => setCheckTable(e.target.value)}
                  className="w-full rounded-lg border px-2 py-1.5 text-xs"
                  style={{
                    background: "var(--bg-canvas)",
                    borderColor: "var(--border-subtle)",
                    color: "var(--ink-primary)",
                  }}
                >
                  {(builtTables.length ? builtTables : ["built_layer1"]).map((t) => (
                    <option key={t} value={t}>
                      {t}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-[10.5px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
                  Expected Linear Trend (y ~ x)
                </label>
                <select
                  value={checkExpect}
                  onChange={(e) => setCheckExpect(e.target.value as "negative" | "positive" | "zero")}
                  className="w-full rounded-lg border px-2 py-1.5 text-xs"
                  style={{
                    background: "var(--bg-canvas)",
                    borderColor: "var(--border-subtle)",
                    color: "var(--ink-primary)",
                  }}
                >
                  <option value="negative">negative</option>
                  <option value="positive">positive</option>
                  <option value="zero">zero</option>
                </select>
              </div>
            </div>
          )}

          {/* In static mode, show copyable reproducible R gl_record() call */}
          {liveApiBaseUrl === null && (
            <div
              className="rounded-lg border p-2.5"
              style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
            >
              <div className="mb-1 flex items-center justify-between text-[10.5px]">
                <span style={{ color: "var(--ink-muted)" }}>
                  Static HTML is read-only. Paste into R (or launch via <code>gl_workbench_serve()</code>):
                </span>
                <button
                  type="button"
                  onClick={() => void handleCopyR()}
                  className="inline-flex items-center gap-1 font-semibold"
                  style={{ color: "var(--st-focus)" }}
                >
                  {copied ? <Check className="h-3 w-3" /> : <Copy className="h-3 w-3" />}
                  {copied ? "Copied" : "Copy R"}
                </button>
              </div>
              <pre
                className="max-h-36 overflow-auto whitespace-pre-wrap font-mono-num text-[10.5px]"
                style={{ color: "var(--ink-primary)" }}
              >
                {rSnippet()}
              </pre>
            </div>
          )}

          {feedback && (
            <div
              className="flex items-center gap-2 rounded-lg border px-3 py-2 text-xs font-medium"
              style={{
                background: feedback.ok ? "var(--st-verified-soft)" : "var(--st-fail-soft)",
                borderColor: feedback.ok ? "var(--st-verified)" : "var(--st-fail)",
                color: feedback.ok ? "var(--st-verified)" : "var(--st-fail)",
              }}
            >
              {feedback.ok ? <CheckCircle2 className="h-4 w-4" /> : <XCircle className="h-4 w-4" />}
              <span>{feedback.msg}</span>
            </div>
          )}

          <div className="flex items-center justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={() => setOpen(false)}
              className="rounded-lg border px-3 py-1.5 text-xs font-semibold"
              style={{ borderColor: "var(--border-strong)", color: "var(--ink-secondary)" }}
            >
              Close
            </button>
            {liveApiBaseUrl !== null && (
              <button
                type="submit"
                disabled={submitting || !text.trim()}
                className="inline-flex items-center gap-1.5 rounded-lg px-3.5 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
                style={{ background: "var(--st-focus)" }}
              >
                <Radio className="h-3.5 w-3.5" />
                {submitting ? "Checking in R..." : "Verify & Commit in R"}
              </button>
            )}
          </div>
        </form>
      </div>
    </div>
  );
};
