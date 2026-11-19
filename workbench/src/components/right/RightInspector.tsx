import React, { useMemo, useState } from "react";
import {
  Activity,
  CheckCircle2,
  Database,
  ExternalLink,
  GitBranch,
  Link2,
  ListChecks,
  Sparkles,
  Tag,
  XCircle,
} from "lucide-react";
import type { GlossCheck, GlossCheckGroup, GlossRecord } from "../../codec";
import { useWorkbenchStore, type RightPanelTab } from "../../store/useWorkbenchStore";
import { VerificationSeal } from "../rive/VerificationSeal";
import { LineageDag } from "./LineageDag";

function pillStyle(status: string): React.CSSProperties {
  switch (status) {
    case "verified":
    case "unique":
    case "classified":
      return { background: "var(--st-verified-soft)", color: "var(--st-verified)" };
    case "partial":
    case "ambiguous":
    case "proposed":
    case "inferred":
      return { background: "var(--st-warn-soft)", color: "var(--st-warn)" };
    case "failed":
    case "rejected":
    case "invalid":
    case "missing":
      return { background: "var(--st-fail-soft)", color: "var(--st-fail)" };
    case "speculative":
    case "uncheckable":
      return {
        background: "var(--st-spec-soft)",
        color: "var(--st-spec)",
        border: "1px dashed var(--st-spec)",
      };
    default:
      return { background: "var(--bg-subtle)", color: "var(--ink-secondary)" };
  }
}

/**
 * Resolve which SVG elements belong to a check group row (e.g. `cyl=4, am=0` or `PANEL=1 | group=2`),
 * so clicking an exception row in a Claim Check immediately highlights those marks on the figure!
 */
function findElementsForCheckGroup(
  bundle: NonNullable<ReturnType<typeof useWorkbenchStore.getState>["bundle"]>,
  check: GlossCheck,
  tableName: string | undefined,
  groupRow: GlossCheckGroup
): string[] {
  const tblName = tableName ?? bundle.tableOrder.find((n) => n.startsWith("built")) ?? "built_layer1";
  const tbl = bundle.tables[tblName];
  if (!tbl?.data) return [];

  if (groupRow.group === "all") {
    return bundle.derived.bindingsElements
      .filter((b) => b.table === tblName)
      .map((b) => b.element);
  }

  const byCols = Array.isArray(check.args.by)
    ? check.args.by.map(String)
    : typeof check.args.by === "string"
      ? [check.args.by]
      : [];

  // Parse `col1=val1, col2=val2`, `val1 | val2`, or R check_trend's `val1 / val2`
  const keyPairs: Array<[string, string]> = [];
  const parts = String(groupRow.group).split(/\s*(?:[,|]|\/)\s*/);
  parts.forEach((part, idx) => {
    const eq = part.indexOf("=");
    if (eq > 0) {
      keyPairs.push([part.slice(0, eq).trim(), part.slice(eq + 1).trim()]);
    } else if (byCols[idx]) {
      keyPairs.push([byCols[idx], part.trim()]);
    }
  });

  if (keyPairs.length === 0) return [];
  const df = tbl.data;
  const matchedElements: string[] = [];
  for (let r = 0; r < df.nrow; r += 1) {
    const ok = keyPairs.every(([col, val]) => {
      const colData = df.columns[col];
      if (!colData) return false;
      return String(colData.values[r] ?? "") === val;
    });
    if (ok) {
      const els = bundle.index.elementsByTableRow.get(`${tblName}:${r + 1}`) ?? [];
      matchedElements.push(...els);
    }
  }
  return Array.from(new Set(matchedElements));
}

const CheckEvidenceCard: React.FC<{
  check: GlossCheck;
  tableName?: string;
}> = ({ check, tableName }) => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const setHighlightedGroup = useWorkbenchStore((s) => s.setHighlightedGroup);
  const highlightedGroup = useWorkbenchStore((s) => s.highlightedGroup);

  if (!bundle) return null;

  return (
    <div
      className="mt-2 rounded-lg border p-2"
      style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
    >
      <div className="mb-1.5 flex items-center justify-between text-[10.5px]">
        <span className="font-mono-num font-bold" style={{ color: "var(--ink-primary)" }}>
          gl_check(&quot;{check.kind}&quot;)
        </span>
        <span className="rounded-full px-2 py-0.5 text-[9.5px] font-semibold" style={pillStyle(check.status)}>
          {check.status}
        </span>
      </div>

      {check.reason && (
        <p className="mb-1.5 text-[10.5px]" style={{ color: "var(--ink-secondary)" }}>
          {check.reason}
        </p>
      )}

      {check.groups.length > 0 && (
        <div className="space-y-1">
          <div className="flex items-center justify-between text-[9.5px] uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
            <span>Group Evidence ({check.groups.length}) — click to highlight</span>
            <span>Est / Pass</span>
          </div>
          {check.groups.map((g, i) => {
            const isActive = highlightedGroup?.label === g.group;
            const failed = g.passed === false;
            return (
              <button
                key={`${g.group}-${i}`}
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  if (isActive) {
                    setHighlightedGroup(null);
                    return;
                  }
                  const els = findElementsForCheckGroup(bundle, check, tableName, g);
                  setHighlightedGroup({
                    label: g.group,
                    status: failed ? "exception" : "passed",
                    elementIds: els,
                  });
                }}
                className="flex w-full items-center justify-between gap-2 rounded-md border px-2 py-1 text-left text-[11px] transition-colors hover:bg-[var(--bg-subtle)]"
                style={{
                  borderColor: isActive
                    ? "var(--st-focus)"
                    : failed
                      ? "var(--st-fail)"
                      : "var(--border-subtle)",
                  background: failed ? "var(--st-fail-soft)" : "var(--bg-surface)",
                }}
              >
                <div className="min-w-0 flex-1">
                  <div className="truncate font-mono-num text-[10.5px] font-semibold" style={{ color: "var(--ink-primary)" }}>
                    {g.group}
                  </div>
                  <div className="font-mono-num text-[9.5px]" style={{ color: "var(--ink-muted)" }}>
                    {typeof g.n === "number"
                      ? `n = ${g.n}`
                      : typeof g.left === "number" && typeof g.right === "number"
                        ? `${g.left.toFixed(2)} vs ${g.right.toFixed(2)}`
                        : typeof g.value === "number"
                          ? `val = ${g.value.toFixed(2)}`
                          : typeof g.row === "number"
                            ? `row ${g.row}`
                            : "checked"}
                  </div>
                </div>
                <div className="flex shrink-0 items-center gap-1.5 font-mono-num text-[10.5px]">
                  {typeof g.estimate === "number" && (
                    <span style={{ color: failed ? "var(--st-fail)" : "var(--ink-primary)" }}>
                      {g.estimate >= 0 ? `+${g.estimate.toFixed(3)}` : g.estimate.toFixed(3)}
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
        </div>
      )}
    </div>
  );
};

const RecordCard: React.FC<{ rec: GlossRecord; compact?: boolean }> = ({ rec, compact = false }) => {
  const selectRecord = useWorkbenchStore((s) => s.selectRecord);
  const selectedRecordId = useWorkbenchStore((s) => s.selectedRecordId);
  const isSel = selectedRecordId === rec.id;

  const text = rec.body.text ?? rec.body.description ?? rec.body.alt_text ?? "";
  const confidence = typeof rec.body.confidence === "number" ? rec.body.confidence : null;

  return (
    <div
      onClick={() => selectRecord(rec.id)}
      className="cursor-pointer rounded-lg border p-2.5 transition-colors"
      style={{
        background: "var(--bg-surface)",
        borderColor: isSel ? "var(--st-focus)" : "var(--border-subtle)",
        boxShadow: isSel ? "0 0 0 1px var(--st-focus)" : undefined,
      }}
    >
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-1.5">
          <span
            className="rounded px-1.5 py-0.5 text-[9.5px] font-bold uppercase"
            style={{
              background:
                rec.workbenchStage === "contextual" ? "var(--st-contextual-soft)" : "var(--bg-subtle)",
              color:
                rec.workbenchStage === "contextual" ? "var(--st-contextual)" : "var(--ink-secondary)",
            }}
          >
            {rec.layer}
          </span>
          {rec.body.type && (
            <span className="font-mono-num text-[10px]" style={{ color: "var(--ink-muted)" }}>
              {rec.body.type}
            </span>
          )}
        </div>
        <span
          className="rounded-full px-2 py-0.5 text-[9.5px] font-semibold"
          style={pillStyle(rec.projectionStatus)}
        >
          {rec.projectionStatus}
        </span>
      </div>

      {text && (
        <p className="mt-1.5 text-[11.5px] leading-snug" style={{ color: "var(--ink-primary)" }}>
          {text}
        </p>
      )}

      {/* External context provenance metadata (source / source_type / confidence / evidence) */}
      {Boolean(rec.body.source || rec.body.source_type || confidence !== null || (rec.body.evidence !== undefined && rec.body.evidence !== null)) && (
        <div
          className="mt-2 space-y-1 rounded-md border px-2 py-1.5 text-[10.5px]"
          style={{
            borderColor: "var(--border-subtle)",
            background: "var(--bg-canvas)",
          }}
        >
          {(rec.body.source || rec.body.source_type) && (
            <div className="flex items-center justify-between gap-2">
              <span className="inline-flex items-center gap-1 font-medium" style={{ color: "var(--st-contextual)" }}>
                <ExternalLink className="h-3 w-3" />
                {rec.body.source ?? "external context"}
              </span>
              {rec.body.source_type && (
                <span className="font-mono-num text-[9.5px]" style={{ color: "var(--ink-muted)" }}>
                  {rec.body.source_type}
                </span>
              )}
            </div>
          )}
          {confidence !== null && (
            <div className="flex items-center gap-2 font-mono-num text-[10px]" style={{ color: "var(--ink-secondary)" }}>
              <span>confidence</span>
              <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-[var(--bg-subtle)]">
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${Math.round(confidence * 100)}%`,
                    background: "var(--st-contextual)",
                  }}
                />
              </div>
              <span>{Math.round(confidence * 100)}%</span>
            </div>
          )}
          {rec.body.evidence !== undefined && rec.body.evidence !== null && (
            <div className="font-mono-num text-[10px]" style={{ color: "var(--ink-secondary)" }}>
              evidence: {typeof rec.body.evidence === "string" ? rec.body.evidence : JSON.stringify(rec.body.evidence)}
            </div>
          )}
        </div>
      )}

      {rec.check && (
        <CheckEvidenceCard check={rec.check} tableName={rec.body.check?.table ?? rec.body.table} />
      )}

      {!compact && (
        <div
          className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 border-t pt-1.5 font-mono-num text-[9.5px]"
          style={{ borderColor: "var(--border-subtle)", color: "var(--ink-muted)" }}
        >
          <span>by: {rec.provenance.by}</span>
          {rec.provenance.stage && <span>stage: {rec.provenance.stage}</span>}
          <span>anchor: {rec.anchor_status}</span>
          {rec.resolvedTargets.length > 0 && <span>→ {rec.resolvedTargets.join(", ")}</span>}
          {rec.depends_on.length > 0 && <span>deps: {rec.depends_on.length}</span>}
        </div>
      )}
    </div>
  );
};

export const RightInspector: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const rightTab = useWorkbenchStore((s) => s.rightTab);
  const setRightTab = useWorkbenchStore((s) => s.setRightTab);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const selectElement = useWorkbenchStore((s) => s.selectElement);
  const [layerFilter, setLayerFilter] = useState<string>("all");

  const primaryId = selectedElementIds[0] ?? null;

  const elementData = useMemo(() => {
    if (!bundle || !primaryId) return null;
    const el = bundle.index.elementById.get(primaryId);
    if (!el) return null;
    const leaf = el.leaf ? bundle.index.leafById.get(el.leaf) ?? null : null;
    const panel = el.panel ? bundle.index.panelById.get(el.panel) ?? null : null;
    const role = bundle.index.roleByElement.get(primaryId) ?? null;
    const binding = bundle.index.bindingByElement.get(primaryId) ?? null;
    const rawMatch = bundle.index.inferredRawByElement.get(primaryId) ?? null;

    // Pull built row key-values
    let builtValues: Array<[string, string]> = [];
    if (binding?.table && binding.row) {
      const df = bundle.tables[binding.table]?.data;
      if (df && binding.row >= 1 && binding.row <= df.nrow) {
        builtValues = df.names.map((nm) => {
          const v = df.columns[nm]?.values[binding.row! - 1];
          return [nm, v === null || v === undefined ? "NA" : String(v)];
        });
      }
    }

    // Pull inferred raw row key-values
    let rawValues: Array<[string, string]> = [];
    if (rawMatch && rawMatch.rawRows.length > 0) {
      const df = bundle.tables[rawMatch.rawTable]?.data;
      const r0 = rawMatch.rawRows[0] - 1;
      if (df && r0 >= 0 && r0 < df.nrow) {
        rawValues = df.names.map((nm) => {
          const v = df.columns[nm]?.values[r0];
          return [nm, v === null || v === undefined ? "NA" : String(v)];
        });
      }
    }

    const records = bundle.index.recordsByElement.get(primaryId) ?? [];
    const ops = bundle.operations.specs.filter(
      (op) => op.targets.includes(primaryId) || op.from_targets.includes(primaryId) || op.to_targets.includes(primaryId)
    );

    const overallStatus =
      records.some((r) => r.projectionStatus === "rejected" || r.projectionStatus === "failed")
        ? "rejected"
        : records.some((r) => r.projectionStatus === "partial")
          ? "partial"
          : binding?.status === "verified"
            ? "verified"
            : binding?.status ?? "unbound";

    return {
      el,
      leaf,
      panel,
      role,
      binding,
      rawMatch,
      builtValues,
      rawValues,
      records,
      ops,
      overallStatus,
    };
  }, [bundle, primaryId]);

  if (!bundle) return null;

  const navTabs: Array<{ id: RightPanelTab; label: string; icon: React.ReactNode }> = [
    { id: "chain", label: "Chain", icon: <Link2 className="h-3.5 w-3.5" /> },
    { id: "records", label: `Records (${bundle.records.length})`, icon: <ListChecks className="h-3.5 w-3.5" /> },
    { id: "lineage", label: "Lineage DAG", icon: <GitBranch className="h-3.5 w-3.5" /> },
  ];

  const figureSealStatus =
    bundle.integrity.mismatches.length > 0
      ? "failed"
      : bundle.records.some((r) => r.projectionStatus === "partial")
        ? "partial"
        : bundle.derived.bindingsElements.some((b) => b.status === "verified")
          ? "verified"
          : "proposed";

  const filteredRecords =
    layerFilter === "all"
      ? bundle.records
      : bundle.records.filter((r) => r.layer === layerFilter || r.workbenchStage === layerFilter);

  return (
    <div
      className="flex h-full w-full flex-col overflow-hidden"
      style={{ background: "var(--bg-surface)" }}
    >
      {/* Top 3-tab switcher */}
      <div
        className="grid grid-cols-3 border-b p-1"
        style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
      >
        {navTabs.map((t) => {
          const active = rightTab === t.id;
          return (
            <button
              key={t.id}
              type="button"
              onClick={() => setRightTab(t.id)}
              className="flex items-center justify-center gap-1 rounded-md py-1.5 text-[11px] font-semibold transition-colors"
              style={{
                background: active ? "var(--bg-surface)" : "transparent",
                color: active ? "var(--st-focus)" : "var(--ink-secondary)",
                boxShadow: active ? "0 1px 2px rgba(0,0,0,0.08)" : "none",
              }}
            >
              {t.icon}
              <span className="truncate">{t.label}</span>
            </button>
          );
        })}
      </div>

      {/* TAB 1: FULL SEMANTIC EVIDENCE CHAIN */}
      {rightTab === "chain" && (
        <div className="min-h-0 flex-1 space-y-3 overflow-y-auto p-3 text-xs">
          {elementData ? (
            <>
              {/* Hero Element Identity + Rive Verification Seal */}
              <div
                className="flex items-center justify-between gap-2 rounded-xl border p-3"
                style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
              >
                <div className="min-w-0">
                  <div className="flex items-center gap-1.5">
                    <span className="font-mono-num text-sm font-bold" style={{ color: "var(--st-focus)" }}>
                      {elementData.el.tag}#{elementData.el.id}
                    </span>
                    {selectedElementIds.length > 1 && (
                      <span
                        className="font-mono-num rounded-full px-1.5 py-0 text-[10px] font-semibold"
                        style={{ background: "var(--st-focus-soft)", color: "var(--st-focus)" }}
                      >
                        +{selectedElementIds.length - 1}
                      </span>
                    )}
                  </div>
                  <div className="mt-0.5 truncate text-[11.5px] font-semibold" style={{ color: "var(--ink-primary)" }}>
                    {elementData.rawMatch?.rawKeyLabels[0] ??
                      elementData.el.text ??
                      elementData.role?.kind ??
                      "Substrate element"}
                  </div>
                  {elementData.el.stable_id && (
                    <div className="font-mono-num text-[9.5px]" style={{ color: "var(--ink-muted)" }}>
                      stable: {elementData.el.stable_id}
                    </div>
                  )}
                </div>
                <VerificationSeal status={elementData.overallStatus} size={36} showLabel={false} />
              </div>

              {/* 1. Substrate / Graphic Facts */}
              <section className="space-y-1.5">
                <div className="flex items-center gap-1.5 text-[10.5px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                  <Tag className="h-3 w-3" /> 1. 图形事实 · Substrate Facts
                </div>
                <div
                  className="grid grid-cols-2 gap-x-2 gap-y-1 rounded-lg border p-2.5 font-mono-num text-[11px]"
                  style={{ borderColor: "var(--border-subtle)", background: "var(--bg-surface)" }}
                >
                  <div>
                    <span style={{ color: "var(--ink-muted)" }}>leaf: </span>
                    {elementData.el.leaf ?? "—"}
                  </div>
                  <div>
                    <span style={{ color: "var(--ink-muted)" }}>panel: </span>
                    {elementData.panel?.key ?? elementData.el.panel ?? "chrome"}
                  </div>
                  <div>
                    <span style={{ color: "var(--ink-muted)" }}>role: </span>
                    {elementData.role?.role ?? "—"}
                  </div>
                  <div>
                    <span style={{ color: "var(--ink-muted)" }}>kind: </span>
                    {elementData.role?.kind ?? "—"}
                  </div>
                  <div className="col-span-2 text-[10px]" style={{ color: "var(--ink-secondary)" }}>
                    bbox: [{elementData.el.x0.toFixed(2)}, {elementData.el.y0.toFixed(2)}] → [
                    {elementData.el.x1.toFixed(2)}, {elementData.el.y1.toFixed(2)}] pt
                  </div>
                  {(elementData.el.fill || elementData.el.stroke) && (
                    <div className="col-span-2 flex items-center gap-3 text-[10px]">
                      {elementData.el.fill && (
                        <span className="inline-flex items-center gap-1">
                          <span
                            className="h-2.5 w-2.5 rounded-full border border-black/20"
                            style={{ background: elementData.el.fill }}
                          />
                          fill {elementData.el.fill}
                        </span>
                      )}
                      {elementData.el.stroke && (
                        <span className="inline-flex items-center gap-1">
                          <span
                            className="h-2.5 w-2.5 rounded-full border border-black/20"
                            style={{ background: elementData.el.stroke }}
                          />
                          stroke {elementData.el.stroke}
                        </span>
                      )}
                    </div>
                  )}
                </div>
              </section>

              {/* 2. Checked Binding + Inferred Raw Row */}
              <section className="space-y-1.5">
                <div className="flex items-center gap-1.5 text-[10.5px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                  <Database className="h-3 w-3" /> 2. 数据绑定 · Code-Checked Binding
                </div>
                {elementData.binding ? (
                  <div
                    className="space-y-2 rounded-lg border p-2.5"
                    style={{ borderColor: "var(--border-subtle)", background: "var(--bg-surface)" }}
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-mono-num text-[11.5px] font-bold" style={{ color: "var(--ink-primary)" }}>
                        {elementData.binding.table}[row = {elementData.binding.row}]
                      </span>
                      <span
                        className="rounded-full px-2 py-0.5 text-[9.5px] font-semibold"
                        style={pillStyle(elementData.binding.status)}
                      >
                        {elementData.binding.status} · {elementData.binding.dev?.toFixed(2) ?? "—"} pt
                      </span>
                    </div>
                    {elementData.builtValues.length > 0 && (
                      <div className="flex flex-wrap gap-1">
                        {elementData.builtValues
                          .filter(([, v]) => v !== "NA")
                          .slice(0, 8)
                          .map(([k, v]) => (
                            <span
                              key={k}
                              className="font-mono-num rounded px-1.5 py-0.5 text-[10px]"
                              style={{ background: "var(--bg-subtle)", color: "var(--ink-primary)" }}
                            >
                              <span style={{ color: "var(--ink-muted)" }}>{k}=</span>
                              {v}
                            </span>
                          ))}
                      </div>
                    )}

                    {/* Transparent Inferred Raw Entity */}
                    {elementData.rawMatch && (
                      <div
                        className="border-t pt-2"
                        style={{ borderColor: "var(--border-subtle)" }}
                      >
                        <div className="mb-1 flex items-center justify-between">
                          <span className="text-[11px] font-semibold" style={{ color: "var(--ink-primary)" }}>
                            Raw: {elementData.rawMatch.rawKeyLabels.join(", ")}
                          </span>
                          <span
                            className="rounded-full px-1.5 py-0.5 text-[9px] font-semibold"
                            style={pillStyle(elementData.rawMatch.status)}
                            title={`Matched by ${elementData.rawMatch.matchedColumns.join(", ")} (not yet a formal persisted raw-link binding)`}
                          >
                            {elementData.rawMatch.status}
                          </span>
                        </div>
                        <div className="flex flex-wrap gap-1">
                          {elementData.rawValues.slice(0, 8).map(([k, v]) => (
                            <span
                              key={k}
                              className="font-mono-num rounded px-1.5 py-0.5 text-[10px]"
                              style={{ background: "var(--bg-canvas)", color: "var(--ink-secondary)" }}
                            >
                              <span style={{ color: "var(--ink-muted)" }}>{k}=</span>
                              {v}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  <div
                    className="rounded-lg border border-dashed p-2.5 text-[11px]"
                    style={{ borderColor: "var(--border-strong)", color: "var(--ink-muted)" }}
                  >
                    Unbound element (e.g. guide, chrome, or count-mismatched leaf).
                  </div>
                )}
              </section>

              {/* 3. Anchored Semantic Records (Analytical, Contextual, Relation, Claim, Narrative, Behavior) */}
              <section className="space-y-1.5">
                <div className="flex items-center gap-1.5 text-[10.5px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                  <Sparkles className="h-3 w-3" /> 3. 语义与核验记录 · Anchored Records ({elementData.records.length})
                </div>
                {elementData.records.length > 0 ? (
                  <div className="space-y-2">
                    {elementData.records.map((rec) => (
                      <RecordCard key={rec.id} rec={rec} />
                    ))}
                  </div>
                ) : (
                  <div
                    className="rounded-lg border border-dashed p-2.5 text-[11px]"
                    style={{ borderColor: "var(--border-strong)", color: "var(--ink-muted)" }}
                  >
                    No semantic records directly anchored to <code className="font-mono-num">{elementData.el.id}</code>.
                    Check the <strong>Records</strong> tab for figure-level claims & narratives.
                  </div>
                )}
              </section>

              {/* 4. Materialised Behavior Operations */}
              {elementData.ops.length > 0 && (
                <section className="space-y-1.5">
                  <div className="flex items-center gap-1.5 text-[10.5px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                    <Activity className="h-3 w-3" /> 4. 交互操作 · Active Operations ({elementData.ops.length})
                  </div>
                  <div className="space-y-1.5">
                    {elementData.ops.map((op, i) => (
                      <div
                        key={`${op.op}-${i}`}
                        className="rounded-lg border px-2.5 py-2 text-[11px]"
                        style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
                      >
                        <div className="flex items-center justify-between">
                          <span className="font-mono-num font-bold" style={{ color: "var(--st-focus)" }}>
                            op: {op.op}
                            {op.kind ? ` (${op.kind})` : op.style ? ` (${op.style})` : ""}
                          </span>
                          {op.basis_status && (
                            <span
                              className="rounded-full px-1.5 py-0.5 text-[9px] font-semibold"
                              style={pillStyle(op.basis_status)}
                            >
                              basis: {op.basis_status}
                            </span>
                          )}
                        </div>
                        {op.text && (
                          <div className="mt-1 text-[10.5px]" style={{ color: "var(--ink-secondary)" }}>
                            {op.text}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </section>
              )}
            </>
          ) : (
            /* Figure-level overview when no individual element is selected */
            <div className="space-y-3">
              <div
                className="flex items-center justify-between gap-3 rounded-xl border p-3"
                style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
              >
                <div>
                  <div className="text-xs font-bold" style={{ color: "var(--ink-primary)" }}>
                    Figure Overview
                  </div>
                  <div className="mt-0.5 text-[11px]" style={{ color: "var(--ink-secondary)" }}>
                    Click any mark on the figure or row in AG Grid to inspect its full chain.
                  </div>
                </div>
                <VerificationSeal status={figureSealStatus} size={36} showLabel={false} />
              </div>

              {bundle.records.length > 0 && (
                <div className="space-y-2">
                  <div className="text-[10.5px] font-bold uppercase tracking-wider" style={{ color: "var(--ink-muted)" }}>
                    Semantic Highlights
                  </div>
                  {bundle.records.slice(0, 6).map((rec) => (
                    <RecordCard key={rec.id} rec={rec} />
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* TAB 2: ALL RECORDS AUDIT LIST */}
      {rightTab === "records" && (
        <div className="flex min-h-0 flex-1 flex-col">
          <div
            className="flex flex-wrap items-center gap-1 border-b p-2 text-[10.5px]"
            style={{ borderColor: "var(--border-subtle)" }}
          >
            {["all", "meaning", "contextual", "relation", "claim", "narrative", "behavior"].map(
              (f) => (
                <button
                  key={f}
                  type="button"
                  onClick={() => setLayerFilter(f)}
                  className="rounded-full px-2 py-0.5 font-medium capitalize"
                  style={{
                    background: layerFilter === f ? "var(--st-focus-soft)" : "var(--bg-subtle)",
                    color: layerFilter === f ? "var(--st-focus)" : "var(--ink-secondary)",
                  }}
                >
                  {f}
                </button>
              )
            )}
          </div>
          <div className="min-h-0 flex-1 space-y-2 overflow-y-auto p-3">
            {filteredRecords.length === 0 ? (
              <div className="p-4 text-center text-xs" style={{ color: "var(--ink-muted)" }}>
                No semantic records in filter &quot;{layerFilter}&quot;.
              </div>
            ) : (
              filteredRecords.map((rec) => (
                <div key={rec.id}>
                  <RecordCard rec={rec} />
                  {rec.resolvedTargets.length > 0 && (
                    <div className="mt-1 flex flex-wrap gap-1 px-1">
                      {rec.resolvedTargets.slice(0, 6).map((eid) => (
                        <button
                          key={eid}
                          type="button"
                          onClick={() => selectElement(eid)}
                          className="font-mono-num rounded border px-1.5 py-0.5 text-[9.5px] hover:bg-[var(--st-focus-soft)]"
                          style={{ borderColor: "var(--border-subtle)", color: "var(--st-focus)" }}
                        >
                          focus {eid}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              ))
            )}
          </div>
        </div>
      )}

      {/* TAB 3: REACT FLOW LINEAGE DAG */}
      {rightTab === "lineage" && (
        <div className="min-h-0 flex-1">
          <LineageDag />
        </div>
      )}
    </div>
  );
};
