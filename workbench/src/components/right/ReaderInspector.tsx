import React, { useMemo, useState } from "react";
import {
  AlertCircle,
  ArrowRight,
  ArrowRightLeft,
  BookOpen,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  ExternalLink,
  Sparkles,
  Wrench,
  XCircle,
} from "lucide-react";
import {
  extractDataDictionaryMap,
  getFigureDisplayTitle,
  humanizeCheckGroupLabel,
  humanizePanelLabel,
  resolveCheckGroupElements,
  summarizeCheckForReader,
  type GlossCheck,
  type GlossRecord,
} from "../../codec";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";
import { ContextComposer } from "./ContextComposer";

/**
 * Collapsible, plain-language data check drawer tucked beneath a takeaway.
 * Collapsed by default so the reader reads clean scientific prose first — and can
 * expand in one click to audit exact numbers or spotlight exceptions on the figure.
 */
const CollapsibleDataCheck: React.FC<{
  check: GlossCheck;
  tableName?: string;
  recordId: string;
}> = ({ check, tableName, recordId }) => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const focusScope = useWorkbenchStore((s) => s.focusScope);
  const setFocusScope = useWorkbenchStore((s) => s.setFocusScope);
  const [expanded, setExpanded] = useState(false);
  const [showAllRows, setShowAllRows] = useState(false);

  if (!bundle) return null;

  const summary = summarizeCheckForReader(check);
  const toneColor =
    summary.tone === "verified"
      ? "var(--st-verified)"
      : summary.tone === "mixed"
        ? "var(--st-warn)"
        : summary.tone === "failed"
          ? "var(--st-fail)"
          : "var(--ink-muted)";

  const orderedGroups = [...check.groups].sort((a, b) => {
    const af = a.passed === false ? 0 : 1;
    const bf = b.passed === false ? 0 : 1;
    return af - bf;
  });
  const collapseLimit = 8;
  const visibleGroups =
    showAllRows || orderedGroups.length <= collapseLimit
      ? orderedGroups
      : orderedGroups.slice(0, collapseLimit);

  return (
    <div className="mt-2.5 border-t pt-2" style={{ borderColor: "var(--border-subtle)" }}>
      <button
        type="button"
        onClick={() => setExpanded(!expanded)}
        className="flex w-full items-center justify-between gap-2 text-left text-[11px] transition-opacity hover:opacity-85"
      >
        <span className="inline-flex min-w-0 items-center gap-1.5 font-medium" style={{ color: toneColor }}>
          {summary.tone === "verified" ? (
            <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
          ) : summary.tone === "failed" ? (
            <XCircle className="h-3.5 w-3.5 shrink-0" />
          ) : (
            <AlertCircle className="h-3.5 w-3.5 shrink-0" />
          )}
          <span className="truncate">{summary.label}</span>
        </span>
        <span
          className="inline-flex shrink-0 items-center gap-0.5 text-[10.5px] font-semibold"
          style={{ color: "var(--ink-muted)" }}
        >
          {expanded ? "Hide" : summary.actionLabel}
          {expanded ? <ChevronDown className="h-3 w-3" /> : <ChevronRight className="h-3 w-3" />}
        </span>
      </button>

      {expanded && visibleGroups.length > 0 && (
        <div className="mt-2 space-y-1.5">
          {visibleGroups.map((g, idx) => {
            const niceLabel = humanizeCheckGroupLabel(bundle, check, tableName, g);
            const scopeId = `check:${recordId}:${g.group}`;
            const isActive = focusScope?.id === scopeId;
            const failed = g.passed === false;
            const detailText =
              typeof g.n === "number"
                ? `n = ${g.n}`
                : typeof g.left === "number" && typeof g.right === "number"
                  ? `${g.left.toFixed(2)} vs ${g.right.toFixed(2)}`
                  : null;
            const metricText =
              typeof g.estimate === "number"
                ? g.estimate >= 0
                  ? `+${g.estimate.toFixed(2)}`
                  : g.estimate.toFixed(2)
                : typeof g.left === "number"
                  ? g.left.toFixed(2)
                  : typeof g.value === "number"
                    ? g.value >= 0
                      ? `+${g.value.toFixed(2)}`
                      : g.value.toFixed(2)
                    : null;

            return (
              <button
                key={`${g.group}-${idx}`}
                type="button"
                onClick={() => {
                  if (isActive) {
                    setFocusScope(null);
                    return;
                  }
                  const els = resolveCheckGroupElements(bundle, check, tableName, g);
                  setFocusScope(
                    {
                      id: scopeId,
                      label: niceLabel,
                      kind: failed ? "exception" : "group",
                      elementIds: els,
                      recordId,
                      isException: failed,
                    },
                    false
                  );
                }}
                className="flex w-full items-center justify-between gap-2 rounded-lg border px-2.5 py-1.5 text-left transition-colors hover:bg-[var(--bg-subtle)]"
                style={{
                  borderColor: isActive
                    ? "var(--st-focus)"
                    : failed
                      ? "var(--st-warn)"
                      : "var(--border-subtle)",
                  background: isActive ? "var(--st-focus-soft)" : "var(--bg-canvas)",
                }}
              >
                <div className="min-w-0">
                  <div className="truncate text-[11.5px] font-medium" style={{ color: "var(--ink-primary)" }}>
                    {niceLabel}
                  </div>
                  {detailText && (
                    <div className="font-mono-num text-[10px]" style={{ color: "var(--ink-muted)" }}>
                      {detailText}
                    </div>
                  )}
                </div>
                <div className="flex shrink-0 items-center gap-1.5 font-mono-num text-[11px]">
                  {metricText !== null && (
                    <span
                      className="font-semibold"
                      style={{ color: failed ? "var(--st-warn)" : "var(--ink-primary)" }}
                    >
                      {metricText}
                    </span>
                  )}
                  {g.passed === true && (
                    <CheckCircle2 className="h-3.5 w-3.5" style={{ color: "var(--st-verified)" }} />
                  )}
                  {g.passed === false && (
                    <AlertCircle className="h-3.5 w-3.5" style={{ color: "var(--st-warn)" }} />
                  )}
                </div>
              </button>
            );
          })}
          {orderedGroups.length > collapseLimit && (
            <button
              type="button"
              onClick={() => setShowAllRows(!showAllRows)}
              className="w-full rounded-lg py-1 text-center text-[10.5px] font-semibold hover:bg-[var(--bg-subtle)]"
              style={{ color: "var(--st-focus)" }}
            >
              {showAllRows ? "Show fewer" : `Show all ${orderedGroups.length}`}
            </button>
          )}
        </div>
      )}
    </div>
  );
};

/** Clean prose card for takeaways & notes — zero internal gloss schema labels. */
const ReaderNoteCard: React.FC<{ rec: GlossRecord }> = ({ rec }) => {
  const text = rec.body.text ?? rec.body.description ?? rec.body.alt_text ?? "";
  const isHypothesis = rec.projectionStatus === "speculative";

  return (
    <div
      className="rounded-xl border p-3"
      style={{
        background: "var(--bg-surface)",
        borderColor: "var(--border-subtle)",
        borderStyle: isHypothesis ? "dashed" : "solid",
      }}
    >
      {isHypothesis && (
        <div
          className="mb-1.5 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-medium italic"
          style={{ background: "var(--st-spec-soft)", color: "var(--st-spec)" }}
        >
          Working hypothesis
        </div>
      )}

      {text && (
        <p className="text-[12.5px] leading-relaxed" style={{ color: "var(--ink-primary)" }}>
          {text}
        </p>
      )}

      {rec.body.source && (
        <div className="mt-2 flex items-center gap-1 text-[10.5px]" style={{ color: "var(--ink-muted)" }}>
          <ExternalLink className="h-3 w-3 shrink-0 opacity-70" />
          <span className="min-w-0 truncate" title={rec.body.source}>
            {rec.body.source}
          </span>
        </div>
      )}

      {rec.check && (
        <CollapsibleDataCheck
          check={rec.check}
          tableName={rec.body.check?.table ?? rec.body.table}
          recordId={rec.id}
        />
      )}
    </div>
  );
};

/**
 * Calm, publication-grade Figure Reader side panel.
 * Speaks the reader's scientific language directly; gloss's internal checks,
 * layers, and provenance work invisibly behind the scenes and stay expandable on demand.
 */
export const ReaderInspector: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const focusScope = useWorkbenchStore((s) => s.focusScope);
  const setViewMode = useWorkbenchStore((s) => s.setViewMode);
  const setWalkthroughOpen = useWorkbenchStore((s) => s.setWalkthroughOpen);
  const setStoryStepIdx = useWorkbenchStore((s) => s.setStoryStepIdx);
  const selectElement = useWorkbenchStore((s) => s.selectElement);
  const setFocusScope = useWorkbenchStore((s) => s.setFocusScope);

  const [showAllVars, setShowAllVars] = useState(false);
  const [showChecksOnItem, setShowChecksOnItem] = useState(false);
  const [showTechnical, setShowTechnical] = useState(false);

  const dict = useMemo(() => (bundle ? extractDataDictionaryMap(bundle) : new Map()), [bundle]);

  // Descriptive summary statistics when a subset/group is focused
  const groupSummary = useMemo(() => {
    if (!bundle || !focusScope || focusScope.elementIds.length <= 1) return null;

    const matCells = focusScope.elementIds
      .map((eid) => bundle.index.matrixCellByElement.get(eid))
      .filter((c): c is NonNullable<typeof c> => Boolean(c));
    if (matCells.length > 0) {
      const nums = matCells
        .map((c) => c.value)
        .filter((v): v is number => typeof v === "number" && Number.isFinite(v));
      const rows = Array.from(new Set(matCells.map((c) => c.rowLabel)));
      const cols = Array.from(new Set(matCells.map((c) => c.colLabel)));
      const stats: Array<{ name: string; unit?: string; mean: string; range: string }> = [];
      if (nums.length > 0) {
        const mean = nums.reduce((a, b) => a + b, 0) / nums.length;
        const min = Math.min(...nums);
        const max = Math.max(...nums);
        const mName = matCells[0].matrixName;
        stats.push({
          name: mName,
          unit: dict.get(mName)?.unit,
          mean: mean.toFixed(2).replace(/\.?0+$/, ""),
          range: `${min.toFixed(2)}–${max.toFixed(2)}`,
        });
      }
      return {
        n: matCells.length,
        subtitle: `${rows.length} rows × ${cols.length} columns`,
        stats,
        members: rows.slice(0, 10).map((r) => ({ label: r, elementId: null as string | null })),
      };
    }

    const rawByTable = new Map<string, Array<{ row0: number; eid: string }>>();
    for (const eid of focusScope.elementIds) {
      const rm = bundle.index.inferredRawByElement.get(eid);
      if (rm && rm.rawRows.length > 0) {
        const arr = rawByTable.get(rm.rawTable) ?? [];
        arr.push({ row0: rm.rawRows[0] - 1, eid });
        rawByTable.set(rm.rawTable, arr);
      }
    }
    let bestTableName: string | null = null;
    let bestEntries: Array<{ row0: number; eid: string }> = [];
    for (const [tn, entries] of rawByTable.entries()) {
      if (entries.length > bestEntries.length) {
        bestTableName = tn;
        bestEntries = entries;
      }
    }
    const rawTable = bestTableName ? bundle.tables[bestTableName] : null;
    const df = rawTable?.data;
    if (!rawTable || !df) return null;

    const seenRows = new Set<number>();
    const uniqEntries = bestEntries.filter((e) => {
      if (seenRows.has(e.row0)) return false;
      seenRows.add(e.row0);
      return true;
    });
    if (uniqEntries.length === 0) return null;

    const numericCols = (rawTable.meta.referenced.length > 0 ? rawTable.meta.referenced : df.names).filter((cn) => {
      const t = df.columns[cn]?.rType;
      return t === "double" || t === "integer";
    });
    const stats = numericCols
      .slice(0, 4)
      .map((cn) => {
        const vals = uniqEntries
          .map((e) => df.columns[cn].values[e.row0])
          .filter((v): v is number => typeof v === "number" && Number.isFinite(v));
        if (vals.length === 0) return null;
        const mean = vals.reduce((a, b) => a + b, 0) / vals.length;
        const min = Math.min(...vals);
        const max = Math.max(...vals);
        const meta = dict.get(cn);
        return {
          name: cn,
          unit: meta?.unit,
          mean: mean.toFixed(2).replace(/\.?0+$/, ""),
          range:
            min === max
              ? String(min)
              : `${min.toFixed(2).replace(/\.?0+$/, "")}–${max.toFixed(2).replace(/\.?0+$/, "")}`,
        };
      })
      .filter((x): x is NonNullable<typeof x> => Boolean(x));

    const members = uniqEntries.slice(0, 10).map((e) => {
      let label = `Row ${e.row0 + 1}`;
      if (df.rownames?.[e.row0]) label = df.rownames[e.row0];
      else {
        const keyCol = rawTable.meta.key.find((k) => k !== ".rownames" && df.columns[k]);
        if (keyCol) label = String(df.columns[keyCol].values[e.row0] ?? label);
      }
      return { label, elementId: e.eid };
    });
    return { n: uniqEntries.length, subtitle: `${uniqEntries.length} items`, stats, members };
  }, [bundle, focusScope, dict]);

  // Single selected item (point, bar, or heatmap cell)
  const singleElement = useMemo(() => {
    if (!bundle || selectedElementIds.length !== 1) return null;
    const id = selectedElementIds[0];
    const el = bundle.index.elementById.get(id);
    if (!el) return null;
    const binding = bundle.index.bindingByElement.get(id) ?? null;
    const rawMatch = bundle.index.inferredRawByElement.get(id) ?? null;
    const matCell = bundle.index.matrixCellByElement.get(id) ?? null;
    const panel = el.panel ? bundle.index.panelById.get(el.panel) ?? null : null;
    const records = bundle.index.recordsByElement.get(id) ?? [];

    const variables: Array<{ name: string; value: string; unit?: string; description?: string; primary: boolean }> = [];
    if (matCell) {
      const matMeta = dict.get(matCell.matrixName);
      const df = bundle.tables[matCell.matrixTable]?.data;
      const valStr =
        typeof matCell.value === "number"
          ? `${matCell.value > 0 ? "+" : ""}${matCell.value.toFixed(2).replace(/\.?0+$/, "")}`
          : String(matCell.value ?? "NA");
      variables.push({
        name: matCell.matrixName === "zscore" ? "Expression" : matCell.matrixName,
        value: valStr,
        unit: matMeta?.unit,
        description: matMeta?.description,
        primary: true,
      });
      if (df) {
        const rowVals = df.names
          .map((cn) => df.columns[cn]?.values[matCell.rowIndex - 1])
          .filter((v): v is number => typeof v === "number" && Number.isFinite(v));
        if (rowVals.length > 0) {
          const rMean = rowVals.reduce((a, b) => a + b, 0) / rowVals.length;
          variables.push({
            name: `${matCell.rowLabel} average`,
            value: rMean.toFixed(2),
            unit: `across ${rowVals.length} samples`,
            primary: true,
          });
        }
      }
    } else if (rawMatch && rawMatch.rawRows.length > 0) {
      const tbl = bundle.tables[rawMatch.rawTable];
      const df = tbl?.data;
      const r0 = rawMatch.rawRows[0] - 1;
      if (df && r0 >= 0 && r0 < df.nrow) {
        const refSet = new Set(tbl.meta.referenced);
        const ordered = [
          ...tbl.meta.referenced.filter((c) => Boolean(df.columns[c])),
          ...df.names.filter((c) => !refSet.has(c)),
        ];
        for (const cn of ordered) {
          const v = df.columns[cn]?.values[r0];
          if (v === null || v === undefined) continue;
          const valStr =
            typeof v === "number" && !Number.isInteger(v)
              ? v.toFixed(2).replace(/\.?0+$/, "")
              : String(v);
          const meta = dict.get(cn);
          variables.push({
            name: cn,
            value: valStr,
            unit: meta?.unit,
            description: meta?.description,
            primary: refSet.has(cn),
          });
        }
      }
    }

    const title = matCell
      ? `${matCell.rowLabel} · ${matCell.colLabel}`
      : rawMatch?.rawKeyLabels[0] ?? el.text?.trim() ?? "Selected Item";
    const kicker = matCell
      ? "Heatmap Cell"
      : humanizePanelLabel(panel?.key);

    const linkedPeers: Array<{ id: string; label: string; relation: string }> = [];
    const seenPeers = new Set<string>();
    const addPeer = (peerId: string, relation: string) => {
      if (peerId === id || seenPeers.has(peerId)) return;
      seenPeers.add(peerId);
      const pm = bundle.index.matrixCellByElement.get(peerId);
      const rm = bundle.index.inferredRawByElement.get(peerId);
      const pel = bundle.index.elementById.get(peerId);
      const lbl = pm
        ? `${pm.rowLabel} · ${pm.colLabel}`
        : rm?.rawKeyLabels[0] ?? pel?.text?.trim() ?? peerId;
      linkedPeers.push({ id: peerId, label: lbl, relation });
    };
    for (const lk of bundle.operations.state.links) {
      if (lk.from === id) addPeer(lk.to, lk.relation);
      else if (lk.to === id) addPeer(lk.from, lk.relation);
    }
    for (const r of records) {
      if (r.layer === "relation" && r.resolvedTargets.length >= 2) {
        const peer = r.resolvedTargets.find((t) => t !== id);
        if (peer) addPeer(peer, "Related");
      }
    }

    return { el, binding, panel, records, variables, title, kicker, linkedPeers };
  }, [bundle, selectedElementIds, dict]);

  if (!bundle) return null;

  const takeaways = bundle.records.filter((r) => r.layer === "claim");
  const highlights = bundle.records.filter(
    (r) => r.layer === "meaning" && r.resolvedTargets.length > 0 && (r.body.label || r.workbenchStage === "contextual")
  );
  const narratives = bundle.records
    .filter((r) => r.layer === "narrative" && r.resolvedTargets.length > 0)
    .sort((a, b) => Number(a.body.order ?? 99) - Number(b.body.order ?? 99));
  const userQuestion = (bundle.context.user_context?.value as Record<string, unknown> | null | undefined)?.question;

  // Case A: Focused multi-element subset/group
  if (focusScope && focusScope.elementIds.length > 1) {
    const groupRecs = focusScope.recordId
      ? bundle.records.filter((r) => r.id === focusScope.recordId)
      : bundle.records.filter(
          (r) => r.resolvedTargets.some((t) => focusScope.elementIds.includes(t)) && r.layer !== "behavior" && r.layer !== "narrative"
        );

    return (
      <div className="flex h-full w-full flex-col overflow-hidden" style={{ background: "var(--bg-surface)" }}>
        <ContextComposer />
        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto p-4">
          <div
            className="rounded-2xl border p-3.5"
            style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
          >
            <div className="flex items-center gap-2">
              {focusScope.swatch && (
                <span className="h-3 w-3 shrink-0 rounded-full border border-black/15" style={{ background: focusScope.swatch }} />
              )}
              <h2 className="text-base font-bold tracking-tight" style={{ color: "var(--ink-primary)" }}>
                {focusScope.label}
              </h2>
            </div>
            <p className="mt-1 text-xs" style={{ color: "var(--ink-secondary)" }}>
              {groupSummary ? groupSummary.subtitle : `${focusScope.elementIds.length} elements`}
            </p>
          </div>

          {groupSummary && groupSummary.stats.length > 0 && (
            <section className="space-y-2">
              <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                Summary
              </h3>
              <div className="grid grid-cols-2 gap-2">
                {groupSummary.stats.map((st) => (
                  <div
                    key={st.name}
                    className="rounded-xl border p-2.5"
                    style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
                  >
                    <div className="text-[10.5px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
                      {st.name}
                      {st.unit && <span className="ml-1 font-normal opacity-75">({st.unit})</span>}
                    </div>
                    <div className="font-mono-num mt-1 text-sm font-bold" style={{ color: "var(--ink-primary)" }}>
                      {st.mean}
                      <span className="ml-1 text-[10px] font-normal" style={{ color: "var(--ink-muted)" }}>
                        mean
                      </span>
                    </div>
                    <div className="font-mono-num text-[10px]" style={{ color: "var(--ink-muted)" }}>
                      range {st.range}
                    </div>
                  </div>
                ))}
              </div>
              <div className="flex flex-wrap gap-1 pt-0.5">
                {groupSummary.members.map((m, idx) =>
                  m.elementId ? (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => {
                        setFocusScope(null);
                        selectElement(m.elementId);
                      }}
                      className="rounded-full px-2 py-0.5 text-[10.5px] font-medium transition-colors hover:brightness-95"
                      style={{ background: "var(--bg-subtle)", color: "var(--ink-primary)" }}
                    >
                      {m.label}
                    </button>
                  ) : (
                    <span
                      key={idx}
                      className="rounded-full px-2 py-0.5 text-[10.5px] font-medium"
                      style={{ background: "var(--bg-subtle)", color: "var(--ink-primary)" }}
                    >
                      {m.label}
                    </span>
                  )
                )}
                {groupSummary.n > groupSummary.members.length && (
                  <span className="px-1 text-[10.5px]" style={{ color: "var(--ink-muted)" }}>
                    +{groupSummary.n - groupSummary.members.length} more
                  </span>
                )}
              </div>
            </section>
          )}

          {groupRecs.length > 0 && (
            <section className="space-y-2">
              <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                Notes
              </h3>
              <div className="space-y-2.5">
                {groupRecs.map((rec) => (
                  <ReaderNoteCard key={rec.id} rec={rec} />
                ))}
              </div>
            </section>
          )}
        </div>
      </div>
    );
  }

  // Case B: Single Selected Item (Point / Heatmap Cell / Bar)
  if (singleElement) {
    const visibleVars = showAllVars
      ? singleElement.variables
      : singleElement.variables.filter((v) => v.primary).length > 0
        ? singleElement.variables.filter((v) => v.primary)
        : singleElement.variables.slice(0, 6);

    const itemNotes = singleElement.records.filter(
      (r) => r.layer === "meaning" || r.layer === "relation"
    );
    const itemChecks = singleElement.records.filter((r) => r.layer === "claim");

    return (
      <div className="flex h-full w-full flex-col overflow-hidden" style={{ background: "var(--bg-surface)" }}>
        <ContextComposer />
        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto p-4">
          {/* Calm Entity Hero — zero internal slice IDs or loud badges */}
          <div
            className="rounded-2xl border p-3.5"
            style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
          >
            {singleElement.kicker && (
              <div className="text-[10.5px] font-semibold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                {singleElement.kicker}
              </div>
            )}
            <h2 className="mt-0.5 truncate text-base font-bold tracking-tight" style={{ color: "var(--ink-primary)" }}>
              {singleElement.title}
            </h2>
            {singleElement.binding?.status === "verified" && (
              <div className="mt-1 inline-flex items-center gap-1 text-[11px]" style={{ color: "var(--st-verified)" }}>
                <CheckCircle2 className="h-3 w-3" />
                <span>Matches source data</span>
              </div>
            )}
          </div>

          {/* Interactive Peer Jump (e.g. Gene -> Pathway or Sample -> Comparison) */}
          {singleElement.linkedPeers.length > 0 && (
            <div className="flex flex-wrap gap-1.5">
              {singleElement.linkedPeers.map((peer) => (
                <button
                  key={peer.id}
                  type="button"
                  onClick={() => selectElement(peer.id)}
                  className="inline-flex items-center gap-1.5 rounded-xl border px-2.5 py-1.5 text-[11.5px] font-semibold transition-colors hover:brightness-95"
                  style={{
                    background: "var(--st-focus-soft)",
                    borderColor: "var(--st-focus)",
                    color: "var(--st-focus)",
                  }}
                >
                  <ArrowRightLeft className="h-3.5 w-3.5 shrink-0" />
                  <span>Compare with {peer.label}</span>
                </button>
              ))}
            </div>
          )}

          {/* Measured Values with Units */}
          {visibleVars.length > 0 && (
            <section className="space-y-2">
              <div className="flex items-center justify-between">
                <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                  Values
                </h3>
                {singleElement.variables.length > visibleVars.length && (
                  <button
                    type="button"
                    onClick={() => setShowAllVars(!showAllVars)}
                    className="text-[11px] font-semibold"
                    style={{ color: "var(--st-focus)" }}
                  >
                    {showAllVars ? "Show key only" : `All ${singleElement.variables.length} fields`}
                  </button>
                )}
              </div>
              <div className="grid grid-cols-2 gap-2">
                {visibleVars.map((v) => (
                  <div
                    key={v.name}
                    title={v.description}
                    className="rounded-xl border p-2.5"
                    style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
                  >
                    <div className="truncate text-[10.5px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
                      {v.name}
                    </div>
                    <div className="font-mono-num mt-0.5 text-sm font-bold" style={{ color: "var(--ink-primary)" }}>
                      {v.value}
                    </div>
                    {v.unit && (
                      <div className="truncate text-[10px]" style={{ color: "var(--ink-muted)" }}>
                        {v.unit}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* Notes & Context (clean prose — zero gloss layer labels!) */}
          {itemNotes.length > 0 && (
            <section className="space-y-2">
              <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                Context
              </h3>
              <div className="space-y-2.5">
                {itemNotes.map((rec) => (
                  <ReaderNoteCard key={rec.id} rec={rec} />
                ))}
              </div>
            </section>
          )}

          {/* Related data takeaways (tucked behind a calm collapsible row so item reading stays focused) */}
          {itemChecks.length > 0 && (
            <div className="border-t pt-3" style={{ borderColor: "var(--border-subtle)" }}>
              <button
                type="button"
                onClick={() => setShowChecksOnItem(!showChecksOnItem)}
                className="flex w-full items-center justify-between text-[11px] font-semibold"
                style={{ color: "var(--ink-secondary)" }}
              >
                <span>Related takeaways ({itemChecks.length})</span>
                {showChecksOnItem ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronRight className="h-3.5 w-3.5" />}
              </button>
              {showChecksOnItem && (
                <div className="mt-2 space-y-2">
                  {itemChecks.map((rec) => (
                    <ReaderNoteCard key={rec.id} rec={rec} />
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Subtle Technical Provenance Footer */}
          <div className="border-t pt-3" style={{ borderColor: "var(--border-subtle)" }}>
            <button
              type="button"
              onClick={() => setShowTechnical(!showTechnical)}
              className="flex w-full items-center justify-between text-[11px] font-medium"
              style={{ color: "var(--ink-muted)" }}
            >
              <span className="inline-flex items-center gap-1.5">
                <Wrench className="h-3 w-3" />
                Technical details
              </span>
              {showTechnical ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronRight className="h-3.5 w-3.5" />}
            </button>
            {showTechnical && (
              <div
                className="mt-2 space-y-1.5 rounded-xl border p-2.5 font-mono-num text-[10.5px]"
                style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)", color: "var(--ink-secondary)" }}
              >
                <div>
                  SVG element: {singleElement.el.tag}#{singleElement.el.id} · leaf {singleElement.el.leaf ?? "—"}
                </div>
                {singleElement.binding && (
                  <div>
                    Source: {singleElement.binding.table}[row={singleElement.binding.row}] · dev{" "}
                    {singleElement.binding.dev?.toFixed(3) ?? "—"} pt
                  </div>
                )}
                <button
                  type="button"
                  onClick={() => setViewMode("inspector")}
                  className="mt-1 inline-flex items-center gap-1 font-sans text-[11px] font-semibold"
                  style={{ color: "var(--st-focus)" }}
                >
                  Open Technical Inspector →
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  // Case C: Calm Figure Overview (default landing state)
  return (
    <div className="flex h-full w-full flex-col overflow-hidden" style={{ background: "var(--bg-surface)" }}>
      <ContextComposer />
      <div className="min-h-0 flex-1 space-y-4 overflow-y-auto p-4">
        {/* Clean Figure Overview Header */}
        <div
          className="rounded-2xl border p-3.5"
          style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
        >
          <h2 className="text-sm font-bold leading-snug" style={{ color: "var(--ink-primary)" }}>
            {getFigureDisplayTitle(bundle)}
          </h2>
          {typeof userQuestion === "string" && (
            <p className="mt-2 text-[12px] leading-relaxed" style={{ color: "var(--ink-secondary)" }}>
              {userQuestion}
            </p>
          )}
          <p className="mt-2 text-[11px]" style={{ color: "var(--ink-muted)" }}>
            Hover over the figure to read values, or click any highlighted point or legend item to explore.
          </p>
        </div>

        {/* Key Takeaways (truthful prose + quiet collapsible data check underneath) */}
        {takeaways.length > 0 && (
          <section className="space-y-2">
            <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
              Key Takeaways
            </h3>
            <div className="space-y-2.5">
              {takeaways.map((rec) => (
                <ReaderNoteCard key={rec.id} rec={rec} />
              ))}
            </div>
          </section>
        )}

        {/* Clickable Highlights to Explore */}
        {highlights.length > 0 && (
          <section className="space-y-2">
            <h3 className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
              <Sparkles className="h-3.5 w-3.5" /> Highlights
            </h3>
            <div className="space-y-1.5">
              {highlights.map((rec) => {
                const targetId = rec.resolvedTargets[0];
                const el = targetId ? bundle.index.elementById.get(targetId) : undefined;
                const label = rec.body.label ?? "Highlight";
                const snippet = rec.body.text ?? "";
                return (
                  <button
                    key={rec.id}
                    type="button"
                    onClick={() => {
                      if (targetId) selectElement(targetId);
                    }}
                    className="group flex w-full items-start justify-between gap-2 rounded-xl border p-2.5 text-left transition-colors hover:bg-[var(--bg-subtle)]"
                    style={{ borderColor: "var(--border-subtle)", background: "var(--bg-surface)" }}
                  >
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-1.5">
                        {el && (el.fill || el.stroke) && (
                          <span
                            className="h-2.5 w-2.5 shrink-0 rounded-full border border-black/15"
                            style={{ background: el.fill ?? el.stroke ?? undefined }}
                          />
                        )}
                        <span className="truncate text-[12px] font-semibold" style={{ color: "var(--ink-primary)" }}>
                          {label}
                        </span>
                      </div>
                      {snippet && (
                        <p className="mt-1 line-clamp-2 text-[11px] leading-snug" style={{ color: "var(--ink-secondary)" }}>
                          {snippet}
                        </p>
                      )}
                    </div>
                    <ArrowRight
                      className="mt-0.5 h-3.5 w-3.5 shrink-0 opacity-40 transition-transform group-hover:translate-x-0.5 group-hover:opacity-100"
                      style={{ color: "var(--st-focus)" }}
                    />
                  </button>
                );
              })}
            </div>
          </section>
        )}

        {/* Optional Guided Walkthrough Launcher */}
        {narratives.length > 0 && (
          <button
            type="button"
            onClick={() => {
              setStoryStepIdx(0);
              setWalkthroughOpen(true);
            }}
            className="flex w-full items-center justify-between gap-2 rounded-xl border px-3 py-2.5 text-left transition-colors hover:bg-[var(--bg-subtle)]"
            style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
          >
            <div className="flex items-center gap-2">
              <BookOpen className="h-4 w-4 shrink-0" style={{ color: "var(--st-focus)" }} />
              <div>
                <div className="text-[12px] font-semibold" style={{ color: "var(--ink-primary)" }}>
                  Guided walkthrough
                </div>
                <div className="text-[10.5px]" style={{ color: "var(--ink-muted)" }}>
                  {narratives.length} steps highlighting the main story
                </div>
              </div>
            </div>
            <ArrowRight className="h-3.5 w-3.5 shrink-0" style={{ color: "var(--st-focus)" }} />
          </button>
        )}
      </div>
    </div>
  );
};
