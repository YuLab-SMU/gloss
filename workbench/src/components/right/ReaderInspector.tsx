import React, { useMemo, useState } from "react";
import {
  AlertTriangle,
  ArrowRightLeft,
  BookOpen,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  ExternalLink,
  Microscope,
  ShieldCheck,
  Sparkles,
  Wrench,
  XCircle,
} from "lucide-react";
import {
  extractDataDictionaryMap,
  getFigureDisplayTitle,
  humanizeCheckGroupLabel,
  humanizeCheckKind,
  humanizeStatus,
  resolveCheckGroupElements,
  type GlossCheck,
  type GlossRecord,
} from "../../codec";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";
import { VerificationSeal } from "../rive/VerificationSeal";

function badgeStyle(status: string): React.CSSProperties {
  switch (status) {
    case "verified":
      return { background: "var(--st-verified-soft)", color: "var(--st-verified)" };
    case "partial":
    case "ambiguous":
    case "proposed":
      return { background: "var(--st-warn-soft)", color: "var(--st-warn)" };
    case "failed":
    case "rejected":
      return { background: "var(--st-fail-soft)", color: "var(--st-fail)" };
    case "speculative":
      return {
        background: "var(--st-spec-soft)",
        color: "var(--st-spec)",
        border: "1px dashed var(--st-spec)",
      };
    default:
      return { background: "var(--bg-subtle)", color: "var(--ink-secondary)" };
  }
}

const ScientificCheckBlock: React.FC<{
  check: GlossCheck;
  tableName?: string;
  recordId: string;
}> = ({ check, tableName, recordId }) => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const focusScope = useWorkbenchStore((s) => s.focusScope);
  const setFocusScope = useWorkbenchStore((s) => s.setFocusScope);
  const [showAllRows, setShowAllRows] = useState(false);

  if (!bundle) return null;

  // For wide row-level checks (e.g. 24 heatmap genes), surface failed exceptions first and let user expand all
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
    <div
      className="mt-2.5 rounded-xl border p-2.5"
      style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
    >
      <div className="mb-2 flex items-center justify-between gap-2">
        <span className="text-[11px] font-semibold" style={{ color: "var(--ink-primary)" }}>
          {humanizeCheckKind(check.kind)}
        </span>
        <span
          className="rounded-full px-2 py-0.5 text-[10px] font-semibold"
          style={badgeStyle(check.status)}
        >
          {humanizeStatus(check.status)}
        </span>
      </div>

      {visibleGroups.length > 0 && (
        <div className="space-y-1.5">
          {visibleGroups.map((g, idx) => {
            const niceLabel = humanizeCheckGroupLabel(bundle, check, tableName, g);
            const scopeId = `check:${recordId}:${g.group}`;
            const isActive = focusScope?.id === scopeId;
            const failed = g.passed === false;
            const subLine =
              typeof g.n === "number"
                ? `${g.n} observations${failed ? " · click to spotlight" : ""}`
                : typeof g.left === "number" && typeof g.right === "number"
                  ? `${g.left.toFixed(2)} vs ${g.right.toFixed(2)}${failed ? " · click to spotlight" : ""}`
                  : typeof g.value === "number"
                    ? `${failed ? "Outside range · click to spotlight" : "Within expected range"}`
                    : failed
                      ? "Exception · click to spotlight"
                      : "Passed check";
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
                    : typeof g.n === "number" && check.kind === "count"
                      ? `n=${g.n}`
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
                      ? "var(--st-fail)"
                      : "var(--border-subtle)",
                  background: failed ? "var(--st-fail-soft)" : "var(--bg-surface)",
                }}
              >
                <div className="min-w-0">
                  <div className="truncate text-[11.5px] font-semibold" style={{ color: "var(--ink-primary)" }}>
                    {niceLabel}
                  </div>
                  <div className="text-[10px]" style={{ color: "var(--ink-muted)" }}>
                    {subLine}
                  </div>
                </div>
                <div className="flex shrink-0 items-center gap-1.5 font-mono-num text-[11px]">
                  {metricText !== null && (
                    <span
                      className="font-semibold"
                      style={{ color: failed ? "var(--st-fail)" : "var(--ink-primary)" }}
                    >
                      {metricText}
                    </span>
                  )}
                  {g.passed === true && (
                    <CheckCircle2 className="h-3.5 w-3.5" style={{ color: "var(--st-verified)" }} />
                  )}
                  {g.passed === false && (
                    <XCircle className="h-3.5 w-3.5" style={{ color: "var(--st-fail)" }} />
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
              {showAllRows ? "Show top 8 only" : `Show all ${orderedGroups.length} checked items`}
            </button>
          )}
        </div>
      )}
    </div>
  );
};

const ScientificRecordCard: React.FC<{ rec: GlossRecord }> = ({ rec }) => {
  const text = rec.body.text ?? rec.body.description ?? rec.body.alt_text ?? "";
  const confidence = typeof rec.body.confidence === "number" ? rec.body.confidence : null;
  const isClaim = rec.layer === "claim";

  return (
    <div
      className="rounded-xl border p-3"
      style={{ background: "var(--bg-surface)", borderColor: "var(--border-subtle)" }}
    >
      <div className="flex items-center justify-between gap-2">
        <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
          {isClaim ? (
            rec.projectionStatus === "partial" || rec.projectionStatus === "rejected" ? (
              <AlertTriangle className="h-3.5 w-3.5" style={{ color: "var(--st-warn)" }} />
            ) : (
              <ShieldCheck className="h-3.5 w-3.5" style={{ color: "var(--st-verified)" }} />
            )
          ) : (
            <Sparkles className="h-3.5 w-3.5" style={{ color: "var(--st-contextual)" }} />
          )}
          {isClaim
            ? "Statistical Finding"
            : rec.workbenchStage === "contextual"
              ? "Domain Context"
              : rec.layer === "relation"
                ? "Comparison"
                : "Data Observation"}
        </span>
        <span
          className="rounded-full px-2 py-0.5 text-[10px] font-semibold"
          style={badgeStyle(rec.projectionStatus)}
        >
          {humanizeStatus(rec.projectionStatus)}
        </span>
      </div>

      {text && (
        <p className="mt-2 text-[12.5px] leading-relaxed" style={{ color: "var(--ink-primary)" }}>
          {text}
        </p>
      )}

      {(rec.body.source || confidence !== null) && (
        <div
          className="mt-2 flex flex-wrap items-center justify-between gap-2 border-t pt-2 text-[10.5px]"
          style={{ borderColor: "var(--border-subtle)", color: "var(--ink-muted)" }}
        >
          {rec.body.source && (
            <span
              className="inline-flex min-w-0 max-w-full items-center gap-1"
              style={{ color: "var(--st-contextual)" }}
              title={rec.body.source}
            >
              <ExternalLink className="h-3 w-3 shrink-0" />
              <span className="min-w-0 truncate">{rec.body.source}</span>
            </span>
          )}
          {confidence !== null && (
            <span className="font-mono-num shrink-0">Confidence {Math.round(confidence * 100)}%</span>
          )}
        </div>
      )}

      {rec.check && (
        <ScientificCheckBlock
          check={rec.check}
          tableName={rec.body.check?.table ?? rec.body.table}
          recordId={rec.id}
        />
      )}
    </div>
  );
};

/**
 * Calm, publication-grade right panel designed for biologists, statisticians,
 * and pharma reviewers: leads with human entity/group facts, units, domain
 * interpretation, and statistical verification — tucking engineering details
 * behind a collapsible accordion.
 */
export const ReaderInspector: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const focusScope = useWorkbenchStore((s) => s.focusScope);
  const setViewMode = useWorkbenchStore((s) => s.setViewMode);
  const setReaderLens = useWorkbenchStore((s) => s.setReaderLens);
  const setStoryStepIdx = useWorkbenchStore((s) => s.setStoryStepIdx);
  const selectElement = useWorkbenchStore((s) => s.selectElement);

  const [showAllVars, setShowAllVars] = useState(false);
  const [showTechnical, setShowTechnical] = useState(false);

  const dict = useMemo(() => (bundle ? extractDataDictionaryMap(bundle) : new Map()), [bundle]);

  // Compute summary stats when a multi-element data group is focused (supports single-plot, patchwork & ComplexHeatmap slices!)
  const groupSummary = useMemo(() => {
    if (!bundle || !focusScope || focusScope.elementIds.length <= 1) return null;

    // ComplexHeatmap matrix slice summary
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
        subtitle: `${rows.length} rows × ${cols.length} columns (${matCells.length} cells)`,
        stats,
        names: rows.slice(0, 10),
      };
    }

    // Dynamic raw table lookup (works across patchwork plot1_raw, plot2_raw, ...)
    const rawNames = new Map<string, number[]>();
    for (const eid of focusScope.elementIds) {
      const rm = bundle.index.inferredRawByElement.get(eid);
      if (rm && rm.rawRows.length > 0) {
        const arr = rawNames.get(rm.rawTable) ?? [];
        arr.push(rm.rawRows[0] - 1);
        rawNames.set(rm.rawTable, arr);
      }
    }
    let bestTableName: string | null = null;
    let bestRows: number[] = [];
    for (const [tn, rows] of rawNames.entries()) {
      if (rows.length > bestRows.length) {
        bestTableName = tn;
        bestRows = rows;
      }
    }
    const rawTable = bestTableName ? bundle.tables[bestTableName] : null;
    const df = rawTable?.data;
    if (!rawTable || !df) return null;

    const uniqRows = Array.from(new Set(bestRows));
    if (uniqRows.length === 0) return null;

    const numericCols = (rawTable.meta.referenced.length > 0 ? rawTable.meta.referenced : df.names).filter((cn) => {
      const t = df.columns[cn]?.rType;
      return t === "double" || t === "integer";
    });
    const stats = numericCols.slice(0, 4).map((cn) => {
      const vals = uniqRows
        .map((r) => df.columns[cn].values[r])
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
        range: min === max ? String(min) : `${min.toFixed(2).replace(/\.?0+$/, "")}–${max.toFixed(2).replace(/\.?0+$/, "")}`,
      };
    }).filter((x): x is NonNullable<typeof x> => Boolean(x));

    const names = uniqRows.slice(0, 8).map((r) => {
      if (df.rownames?.[r]) return df.rownames[r];
      const keyCol = rawTable.meta.key.find((k) => k !== ".rownames" && df.columns[k]);
      return keyCol ? String(df.columns[keyCol].values[r] ?? `Row ${r + 1}`) : `Row ${r + 1}`;
    });
    return { n: uniqRows.length, subtitle: `${uniqRows.length} data observations`, stats, names };
  }, [bundle, focusScope, dict]);

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
          ? matCell.value.toFixed(2).replace(/\.?0+$/, "")
          : String(matCell.value ?? "NA");
      variables.push(
        { name: matCell.matrixName, value: valStr, unit: matMeta?.unit, description: matMeta?.description, primary: true },
        { name: "Feature / Row", value: matCell.rowLabel, primary: true },
        { name: "Sample / Col", value: matCell.colLabel, primary: true }
      );
      if (df) {
        const rowVals = df.names
          .map((cn) => df.columns[cn]?.values[matCell.rowIndex - 1])
          .filter((v): v is number => typeof v === "number" && Number.isFinite(v));
        if (rowVals.length > 0) {
          const rMean = rowVals.reduce((a, b) => a + b, 0) / rowVals.length;
          variables.push({
            name: `${matCell.rowLabel} mean`,
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
          const valStr = typeof v === "number" && !Number.isInteger(v) ? v.toFixed(2).replace(/\.?0+$/, "") : String(v);
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
      ? `${matCell.rowLabel} × ${matCell.colLabel}`
      : rawMatch?.rawKeyLabels[0] ?? el.text?.trim() ?? "Selected Element";
    const status = records.some((r) => r.projectionStatus === "partial")
      ? "partial"
      : binding?.status === "verified"
        ? "verified"
        : binding?.status ?? "proposed";

    const linkedPeers: Array<{ id: string; label: string; relation: string }> = [];
    const seenPeers = new Set<string>();
    const addPeer = (peerId: string, relation: string) => {
      if (peerId === id || seenPeers.has(peerId)) return;
      seenPeers.add(peerId);
      const rm = bundle.index.inferredRawByElement.get(peerId);
      const pel = bundle.index.elementById.get(peerId);
      const lbl = rm?.rawKeyLabels[0] ?? pel?.text?.trim() ?? peerId;
      linkedPeers.push({ id: peerId, label: lbl, relation });
    };
    for (const lk of bundle.operations.state.links) {
      if (lk.from === id) addPeer(lk.to, lk.relation);
      else if (lk.to === id) addPeer(lk.from, lk.relation);
    }
    for (const r of records) {
      if (r.layer === "relation" && r.resolvedTargets.length >= 2) {
        const peer = r.resolvedTargets.find((t) => t !== id);
        if (peer) addPeer(peer, "Related observation");
      }
    }

    return { el, binding, rawMatch, panel, records, variables, title, status, linkedPeers };
  }, [bundle, selectedElementIds, dict]);

  if (!bundle) return null;

  const claims = bundle.records.filter((r) => r.layer === "claim");
  const narratives = bundle.records
    .filter((r) => r.layer === "narrative")
    .sort((a, b) => Number(a.body.order ?? 99) - Number(b.body.order ?? 99));
  const userQuestion = (bundle.context.user_context?.value as Record<string, unknown> | null | undefined)?.question;
  const verifiedTotal = bundle.derived.bindingsElements.filter((b) => b.status === "verified").length;

  // Case A: Focused multi-element group (e.g., `cyl = 6` or `Exception · am = 0 · cyl = 4`)
  if (focusScope && focusScope.elementIds.length > 1) {
    const groupRecs = focusScope.recordId
      ? bundle.records.filter((r) => r.id === focusScope.recordId)
      : bundle.records.filter((r) =>
          r.resolvedTargets.some((t) => focusScope.elementIds.includes(t)) && r.layer !== "behavior"
        );

    return (
      <div className="flex h-full w-full flex-col overflow-hidden" style={{ background: "var(--bg-surface)" }}>
        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto p-4">
          {/* Group Hero */}
          <div
            className="rounded-2xl border p-3.5"
            style={{
              background: focusScope.isException ? "var(--st-warn-soft)" : "var(--bg-canvas)",
              borderColor: focusScope.isException ? "var(--st-warn)" : "var(--border-subtle)",
            }}
          >
            <div className="flex items-start justify-between gap-2">
              <div>
                <div className="text-[10.5px] font-semibold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                  {focusScope.isException ? "Statistical Exception" : "Focused Subset"}
                </div>
                <div className="mt-0.5 flex items-center gap-2">
                  {focusScope.swatch && (
                    <span className="h-3 w-3 rounded-full border border-black/15" style={{ background: focusScope.swatch }} />
                  )}
                  <h2 className="text-base font-bold tracking-tight" style={{ color: "var(--ink-primary)" }}>
                    {focusScope.label}
                  </h2>
                </div>
                <p className="mt-1 text-xs" style={{ color: "var(--ink-secondary)" }}>
                  {groupSummary ? groupSummary.subtitle : `${focusScope.elementIds.length} figure elements`}
                </p>
              </div>
              <VerificationSeal status={focusScope.isException ? "partial" : "verified"} size={36} showLabel={false} />
            </div>
          </div>

          {/* Automatic Group Descriptive Statistics */}
          {groupSummary && groupSummary.stats.length > 0 && (
            <section className="space-y-2">
              <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                Group Summary Statistics
              </h3>
              <div className="grid grid-cols-2 gap-2">
                {groupSummary.stats.map((st) => (
                  <div
                    key={st.name}
                    className="rounded-xl border p-2.5"
                    style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
                  >
                    <div className="text-[10.5px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
                      {st.name}{" "}
                      {st.unit && <span className="font-normal opacity-75">({st.unit})</span>}
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
                {groupSummary.names.map((nm, idx) => (
                  <span
                    key={idx}
                    className="rounded-full px-2 py-0.5 text-[10.5px] font-medium"
                    style={{ background: "var(--bg-subtle)", color: "var(--ink-primary)" }}
                  >
                    {nm}
                  </span>
                ))}
                {groupSummary.n > groupSummary.names.length && (
                  <span className="px-1 text-[10.5px]" style={{ color: "var(--ink-muted)" }}>
                    +{groupSummary.n - groupSummary.names.length} more
                  </span>
                )}
              </div>
            </section>
          )}

          {/* Related Findings & Context */}
          {groupRecs.length > 0 && (
            <section className="space-y-2">
              <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                Findings & Context
              </h3>
              <div className="space-y-2.5">
                {groupRecs.map((rec) => (
                  <ScientificRecordCard key={rec.id} rec={rec} />
                ))}
              </div>
            </section>
          )}
        </div>
      </div>
    );
  }

  // Case B: Single Observation Selected (e.g. Mazda RX4)
  if (singleElement) {
    const visibleVars = showAllVars
      ? singleElement.variables
      : singleElement.variables.filter((v) => v.primary).length > 0
        ? singleElement.variables.filter((v) => v.primary)
        : singleElement.variables.slice(0, 6);

    const contextualAndAnalytical = singleElement.records.filter(
      (r) => r.layer === "meaning" || r.layer === "relation"
    );
    const relevantClaims =
      singleElement.records.filter((r) => r.layer === "claim").length > 0
        ? singleElement.records.filter((r) => r.layer === "claim")
        : claims;

    return (
      <div className="flex h-full w-full flex-col overflow-hidden" style={{ background: "var(--bg-surface)" }}>
        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto p-4">
          {/* Clean Scientific Entity Hero */}
          <div
            className="flex items-start justify-between gap-3 rounded-2xl border p-3.5"
            style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
          >
            <div className="min-w-0">
              <div className="text-[10.5px] font-semibold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                {singleElement.panel?.key ? singleElement.panel.key.replace(/=/g, " = ") : "Selected Observation"}
              </div>
              <h2 className="mt-0.5 truncate text-base font-bold tracking-tight" style={{ color: "var(--ink-primary)" }}>
                {singleElement.title}
              </h2>
              <div className="mt-1 flex items-center gap-1.5 text-[11px]" style={{ color: "var(--st-verified)" }}>
                <CheckCircle2 className="h-3.5 w-3.5" />
                <span>
                  {singleElement.binding?.status === "verified"
                    ? "Verified against plotted data"
                    : "Visual figure element"}
                </span>
              </div>
            </div>
            <VerificationSeal status={singleElement.status} size={38} showLabel={false} />
          </div>

          {/* Interactive Comparison Shortcut (guides user to explore linked observations) */}
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

          {/* Measured Data Values with Units */}
          {visibleVars.length > 0 && (
            <section className="space-y-2">
              <div className="flex items-center justify-between">
                <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                  Data Values
                </h3>
                {singleElement.variables.length > visibleVars.length && (
                  <button
                    type="button"
                    onClick={() => setShowAllVars(!showAllVars)}
                    className="text-[11px] font-semibold"
                    style={{ color: "var(--st-focus)" }}
                  >
                    {showAllVars ? "Show key only" : `All ${singleElement.variables.length} variables`}
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
                    <div className="text-[10.5px] font-semibold" style={{ color: "var(--ink-secondary)" }}>
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

          {/* Domain Context & Notes */}
          {contextualAndAnalytical.length > 0 && (
            <section className="space-y-2">
              <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                Interpretation & Context
              </h3>
              <div className="space-y-2.5">
                {contextualAndAnalytical.map((rec) => (
                  <ScientificRecordCard key={rec.id} rec={rec} />
                ))}
              </div>
            </section>
          )}

          {/* Statistical Findings & Checks */}
          {relevantClaims.length > 0 && (
            <section className="space-y-2">
              <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                Statistical Verification ({relevantClaims.length})
              </h3>
              <div className="space-y-2.5">
                {relevantClaims.map((rec) => (
                  <ScientificRecordCard key={rec.id} rec={rec} />
                ))}
              </div>
            </section>
          )}

          {/* Collapsible Technical Audit Details (tucked cleanly out of the scientist's way) */}
          <div className="border-t pt-3" style={{ borderColor: "var(--border-subtle)" }}>
            <button
              type="button"
              onClick={() => setShowTechnical(!showTechnical)}
              className="flex w-full items-center justify-between text-[11px] font-medium"
              style={{ color: "var(--ink-muted)" }}
            >
              <span className="inline-flex items-center gap-1.5">
                <Wrench className="h-3 w-3" />
                Technical provenance & audit details
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
                    Binding: {singleElement.binding.table}[row={singleElement.binding.row}] · dev{" "}
                    {singleElement.binding.dev?.toFixed(3) ?? "—"} pt
                  </div>
                )}
                <button
                  type="button"
                  onClick={() => setViewMode("inspector")}
                  className="mt-1 inline-flex items-center gap-1 font-sans text-[11px] font-semibold"
                  style={{ color: "var(--st-focus)" }}
                >
                  Open full Engineering Inspector →
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  // Case C: Figure-Level Scientific Summary (when nothing is selected)
  return (
    <div className="flex h-full w-full flex-col overflow-hidden" style={{ background: "var(--bg-surface)" }}>
      <div className="min-h-0 flex-1 space-y-4 overflow-y-auto p-4">
        <div
          className="rounded-2xl border p-3.5"
          style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
        >
          <div className="flex items-start justify-between gap-2">
            <div>
              <div className="inline-flex items-center gap-1 text-[10.5px] font-semibold uppercase tracking-wider" style={{ color: "var(--st-verified)" }}>
                <Microscope className="h-3.5 w-3.5" /> Scientific Summary
              </div>
              <h2 className="mt-1 text-sm font-bold leading-snug" style={{ color: "var(--ink-primary)" }}>
                {getFigureDisplayTitle(bundle)}
              </h2>
              <p className="mt-1 text-xs" style={{ color: "var(--ink-secondary)" }}>
                {verifiedTotal} verified observations · {claims.length} checked claim(s). Click any point or group to inspect.
              </p>
            </div>
            <VerificationSeal
              status={claims.some((c) => c.projectionStatus === "partial") ? "partial" : "verified"}
              size={36}
              showLabel={false}
            />
          </div>
          {typeof userQuestion === "string" && (
            <div
              className="mt-3 rounded-lg border px-2.5 py-2 text-[11.5px] italic"
              style={{ borderColor: "var(--border-subtle)", background: "var(--bg-surface)", color: "var(--ink-secondary)" }}
            >
              “{userQuestion}”
            </div>
          )}
        </div>

        {/* Guided Reading Walkthrough */}
        {narratives.length > 0 && (
          <section className="space-y-2">
            <h3 className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
              <BookOpen className="h-3.5 w-3.5" /> Guided Reading ({narratives.length} steps)
            </h3>
            <div className="space-y-2">
              {narratives.map((n, idx) => (
                <button
                  key={n.id}
                  type="button"
                  onClick={() => {
                    setStoryStepIdx(idx);
                    setReaderLens("story");
                    if (n.resolvedTargets[0]) selectElement(n.resolvedTargets[0]);
                  }}
                  className="flex w-full items-start gap-2.5 rounded-xl border p-2.5 text-left transition-colors hover:bg-[var(--bg-subtle)]"
                  style={{ borderColor: "var(--border-subtle)", background: "var(--bg-surface)" }}
                >
                  <span
                    className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-[10.5px] font-bold text-white"
                    style={{ background: "var(--st-focus)" }}
                  >
                    {Number(n.body.order ?? idx + 1)}
                  </span>
                  <span className="text-[12px] leading-snug" style={{ color: "var(--ink-primary)" }}>
                    {n.body.text}
                  </span>
                </button>
              ))}
            </div>
          </section>
        )}

        {/* Key Claims */}
        {claims.length > 0 && (
          <section className="space-y-2">
            <h3 className="text-[11px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
              Checked Statistical Findings
            </h3>
            <div className="space-y-2.5">
              {claims.map((rec) => (
                <ScientificRecordCard key={rec.id} rec={rec} />
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
};
