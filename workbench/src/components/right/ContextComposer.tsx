import React, { useMemo, useState } from "react";
import { CircleAlert, Send, Sparkles } from "lucide-react";
import { resolveNaturalFocus, type FocusScope } from "../../codec";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";

interface ContextPacket {
  request?: {
    intent?: string;
    focus?: {
      elements?: unknown[];
      rows?: Record<string, unknown[]>;
      matched_by?: string[];
      unresolved?: string[];
    };
  };
  sections?: {
    context?: Record<string, { found?: boolean }>;
    semantics?: unknown[];
  };
  omitted?: unknown[];
  actions?: Array<{ name?: string }>;
  digest?: string;
}

interface AssembleResponse {
  ok?: boolean;
  packet?: ContextPacket;
  error?: string;
}

function focusForQuestion(bundle: NonNullable<ReturnType<typeof useWorkbenchStore.getState>["bundle"]>, question: string, scope: FocusScope | null, selected: string[]) {
  if (scope && scope.elementIds.length > 0) return { elements: scope.elementIds };
  if (selected.length > 0) return { elements: selected };
  const natural = resolveNaturalFocus(bundle, question);
  if (natural && natural.elementIds.length > 0) return { elements: natural.elementIds };
  return { query: question };
}

export const ContextComposer: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const liveApiBaseUrl = useWorkbenchStore((s) => s.liveApiBaseUrl);
  const focusScope = useWorkbenchStore((s) => s.focusScope);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const [question, setQuestion] = useState("");
  const [packet, setPacket] = useState<ContextPacket | null>(null);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const focusLabel = focusScope?.label ?? (selectedElementIds.length > 0 ? `${selectedElementIds.length} selected elements` : "the whole figure");
  const packetStats = useMemo(() => {
    if (!packet) return null;
    const rows = Object.values(packet.request?.focus?.rows ?? {}).reduce((sum, values) => sum + values.length, 0);
    const contextNames = Object.entries(packet.sections?.context ?? {})
      .filter(([, item]) => item?.found)
      .map(([name]) => name);
    const actions = (packet.actions ?? []).map((action) => action.name).filter((name): name is string => Boolean(name));
    return { rows, contextNames, actions };
  }, [packet]);

  if (!bundle) return null;

  const assemble = async () => {
    const text = question.trim();
    if (!text) return;
    setError(null);
    setPacket(null);
    if (liveApiBaseUrl === null) {
      setError("Connect the Workbench to a live R session to assemble this turn.");
      return;
    }
    setPending(true);
    try {
      const res = await fetch(`${liveApiBaseUrl}/api/context/assemble`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          question: text,
          focus: focusForQuestion(bundle, text, focusScope, selectedElementIds),
          disclose: "summary",
        }),
      });
      const body = (await res.json()) as AssembleResponse;
      if (!res.ok || !body.ok || !body.packet) throw new Error(body.error ?? `Context assembly failed (HTTP ${res.status})`);
      setPacket(body.packet);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setPending(false);
    }
  };

  return (
    <section
      className="border-b px-3.5 py-3"
      style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
    >
      <div className="mb-2 flex items-center justify-between gap-2">
        <div className="flex min-w-0 items-center gap-1.5">
          <Sparkles className="h-3.5 w-3.5 shrink-0" style={{ color: "var(--st-contextual)" }} />
          <span className="text-[11.5px] font-semibold" style={{ color: "var(--ink-primary)" }}>
            Ask about this figure
          </span>
        </div>
        <span className="truncate text-[10px]" style={{ color: "var(--ink-muted)" }} title={focusLabel}>
          focus · {focusLabel}
        </span>
      </div>
      <form
        className="flex items-end gap-1.5"
        onSubmit={(event) => {
          event.preventDefault();
          void assemble();
        }}
      >
        <textarea
          value={question}
          onChange={(event) => setQuestion(event.target.value)}
          rows={2}
          placeholder="Ask for an explanation, a check, or the next experiment"
          className="min-w-0 flex-1 resize-none rounded-lg border px-2.5 py-2 text-[11.5px] leading-snug outline-none"
          style={{ borderColor: "var(--border-subtle)", background: "var(--bg-surface)", color: "var(--ink-primary)" }}
        />
        <button
          type="submit"
          disabled={pending || !question.trim()}
          className="inline-flex h-9 shrink-0 items-center gap-1 rounded-lg px-2.5 text-[10.5px] font-semibold transition-opacity disabled:cursor-not-allowed disabled:opacity-40"
          style={{ background: "var(--st-focus)", color: "white" }}
          title={liveApiBaseUrl === null ? "Requires a live R session" : "Assemble a bounded context packet"}
        >
          <Send className="h-3 w-3" />
          {pending ? "Reading" : "Assemble"}
        </button>
      </form>
      {error && (
        <div className="mt-2 flex items-start gap-1.5 text-[10.5px]" style={{ color: "var(--st-fail)" }}>
          <CircleAlert className="mt-0.5 h-3 w-3 shrink-0" />
          <span>{error}</span>
        </div>
      )}
      {packet && packetStats && (
        <div className="mt-2 rounded-lg border p-2" style={{ borderColor: "var(--border-subtle)", background: "var(--bg-surface)" }}>
          <div className="flex items-center justify-between gap-2 text-[10.5px]">
            <span className="font-semibold" style={{ color: "var(--ink-primary)" }}>
              {packet.request?.intent ?? "explain"} context packet
            </span>
            <span className="font-mono-num" style={{ color: "var(--ink-muted)" }}>
              {packet.digest?.slice(0, 10) ?? "—"}
            </span>
          </div>
          <div className="mt-1.5 flex flex-wrap gap-1.5 text-[10px]" style={{ color: "var(--ink-secondary)" }}>
            <span>{packet.request?.focus?.elements?.length ?? 0} elements</span>
            <span>·</span>
            <span>{packetStats.rows} rows</span>
            <span>·</span>
            <span>{packet.sections?.semantics?.length ?? 0} records</span>
            {packet.omitted && packet.omitted.length > 0 && <span>· {packet.omitted.length} deferred reads</span>}
          </div>
          {packetStats.contextNames.length > 0 && (
            <div className="mt-1 truncate text-[10px]" style={{ color: "var(--st-contextual)" }} title={packetStats.contextNames.join(", ")}>
              sources · {packetStats.contextNames.join(", ")}
            </div>
          )}
          {packetStats.actions.length > 0 && (
            <div className="mt-1 truncate text-[10px]" style={{ color: "var(--ink-muted)" }} title={packetStats.actions.join(", ")}>
              next · {packetStats.actions.join(", ")}
            </div>
          )}
        </div>
      )}
    </section>
  );
};
