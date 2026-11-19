import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { AgGridReact } from "ag-grid-react";
import {
  AllCommunityModule,
  ModuleRegistry,
  themeQuartz,
  type ColDef,
  type GridApi,
  type ICellRendererParams,
} from "ag-grid-community";
import {
  AlertTriangle,
  Download,
  Filter,
  KeyRound,
  Search,
  Table2,
  X,
} from "lucide-react";
import { dfToObjects, type DecodedDataFrame, type GlossTable } from "../../codec";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";

ModuleRegistry.registerModules([AllCommunityModule]);

const HEX_COLOR_RE = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/;

function statusColors(status: string): { bg: string; fg: string; dashed?: boolean } {
  switch (status) {
    case "verified":
    case "classified":
    case "ok":
    case "unique":
      return { bg: "var(--st-verified-soft)", fg: "var(--st-verified)" };
    case "ambiguous":
    case "partial":
    case "partial_data":
    case "proposed":
      return { bg: "var(--st-warn-soft)", fg: "var(--st-warn)" };
    case "failed":
    case "rejected":
    case "invalid":
    case "missing":
    case "missing_data":
      return { bg: "var(--st-fail-soft)", fg: "var(--st-fail)" };
    case "speculative":
    case "unbound":
    case "uncheckable":
      return { bg: "var(--st-spec-soft)", fg: "var(--st-spec)", dashed: true };
    default:
      return { bg: "var(--bg-subtle)", fg: "var(--ink-secondary)" };
  }
}

const StatusBadgeRenderer: React.FC<ICellRendererParams> = ({ value }) => {
  if (value === null || value === undefined || value === "") {
    return <span className="font-mono-num text-[10.5px] opacity-40">NA</span>;
  }
  const s = String(value);
  const c = statusColors(s);
  return (
    <span
      className="inline-flex items-center rounded-full px-2 py-0.5 text-[10.5px] font-semibold leading-none"
      style={{
        background: c.bg,
        color: c.fg,
        border: c.dashed ? `1px dashed ${c.fg}` : "none",
      }}
    >
      {s}
    </span>
  );
};

const DeviationRenderer: React.FC<ICellRendererParams> = ({ value }) => {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return <span className="font-mono-num text-[10.5px] opacity-40">—</span>;
  }
  const pct = Math.min(100, (value / 0.5) * 100);
  const warn = value > 0.35;
  return (
    <div className="flex h-full items-center gap-2 font-mono-num text-[11px]">
      <span className="w-12 text-right">{value.toFixed(3)}</span>
      <div className="h-1.5 w-14 overflow-hidden rounded-full bg-[var(--bg-subtle)]">
        <div
          className="h-full rounded-full"
          style={{
            width: `${Math.max(4, pct)}%`,
            background: warn ? "var(--st-warn)" : "var(--st-verified)",
          }}
        />
      </div>
    </div>
  );
};

const RValueCellRenderer: React.FC<
  ICellRendererParams & { df?: DecodedDataFrame | null; colName?: string }
> = ({ value, node, df, colName }) => {
  const rowIdx0 =
    typeof (node?.data as Record<string, unknown> | undefined)?.__rowIdx0 === "number"
      ? ((node.data as Record<string, unknown>).__rowIdx0 as number)
      : -1;
  const special =
    df && colName && rowIdx0 >= 0 ? df.columns[colName]?.specials.get(rowIdx0) : undefined;

  if (special) {
    return (
      <span
        className="font-mono-num rounded px-1 py-0.5 text-[10px] font-semibold"
        style={{
          background: special === "NA" ? "var(--bg-subtle)" : "var(--st-warn-soft)",
          color: special === "NA" ? "var(--ink-muted)" : "var(--st-warn)",
        }}
      >
        {special}
      </span>
    );
  }
  if (value === null || value === undefined) {
    return <span className="font-mono-num text-[10.5px] opacity-40">NA</span>;
  }
  if (typeof value === "string" && HEX_COLOR_RE.test(value)) {
    return (
      <span className="inline-flex items-center gap-1.5 font-mono-num text-[11px]">
        <span
          className="h-3 w-3 shrink-0 rounded-full border border-black/20"
          style={{ background: value }}
        />
        <span>{value}</span>
      </span>
    );
  }
  if (typeof value === "number") {
    const txt = Number.isInteger(value) ? String(value) : value.toFixed(3).replace(/\.?0+$/, "");
    return <span className="font-mono-num">{txt}</span>;
  }
  return <span>{String(value)}</span>;
};

export const DataWorkbenchGrid: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const activeTableTab = useWorkbenchStore((s) => s.activeTableTab);
  const setActiveTableTab = useWorkbenchStore((s) => s.setActiveTableTab);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const selectElement = useWorkbenchStore((s) => s.selectElement);
  const selectRecord = useWorkbenchStore((s) => s.selectRecord);
  const selectTableRow = useWorkbenchStore((s) => s.selectTableRow);
  const setGridFilterElementIds = useWorkbenchStore((s) => s.setGridFilterElementIds);
  const gridFilterElementIds = useWorkbenchStore((s) => s.gridFilterElementIds);
  const theme = useWorkbenchStore((s) => s.theme);

  const gridApiRef = useRef<GridApi | null>(null);
  const [quickFilter, setQuickFilter] = useState("");
  const [filteredCount, setFilteredCount] = useState<number | null>(null);

  const agTheme = useMemo(
    () =>
      themeQuartz.withParams(
        theme === "obsidian"
          ? {
              backgroundColor: "#111827",
              foregroundColor: "#e8eef8",
              headerBackgroundColor: "#1a2335",
              headerTextColor: "#cbd5e1",
              borderColor: "#243047",
              rowHoverColor: "rgba(96, 165, 250, 0.12)",
              selectedRowBackgroundColor: "rgba(96, 165, 250, 0.22)",
              oddRowBackgroundColor: "#0e1524",
              fontSize: 12,
              headerFontSize: 11,
              rowHeight: 28,
              headerHeight: 30,
            }
          : {
              backgroundColor: "#ffffff",
              foregroundColor: "#142238",
              headerBackgroundColor: "#f4f2ec",
              headerTextColor: "#4a5a73",
              borderColor: "#e4dfd4",
              rowHoverColor: "rgba(37, 99, 235, 0.06)",
              selectedRowBackgroundColor: "rgba(37, 99, 235, 0.14)",
              oddRowBackgroundColor: "#faf9f5",
              fontSize: 12,
              headerFontSize: 11,
              rowHeight: 28,
              headerHeight: 30,
            }
      ),
    [theme]
  );

  // Build rows & column definitions for the active tab
  const { rowData, columnDefs, tableMeta } = useMemo(() => {
    if (!bundle) {
      return { rowData: [], columnDefs: [] as ColDef[], tableMeta: null as GlossTable["meta"] | null };
    }

    if (activeTableTab === "__elements__") {
      const rows = bundle.substrate.elements.map((e) => {
        const b = bundle.index.bindingByElement.get(e.id);
        const r = bundle.index.roleByElement.get(e.id);
        return {
          ...e,
          role: r?.role ?? null,
          kind: r?.kind ?? null,
          binding_status: b?.status ?? "unbound",
          bound_table: b?.table ?? null,
          bound_row: b?.row ?? null,
        };
      });
      const cols: ColDef[] = [
        { field: "id", headerName: "Element", pinned: "left", width: 90, cellClass: "font-mono-num font-semibold" },
        { field: "tag", headerName: "Tag", width: 85 },
        { field: "binding_status", headerName: "Binding", width: 110, cellRenderer: StatusBadgeRenderer },
        { field: "role", headerName: "Role", width: 115 },
        { field: "kind", headerName: "Kind", width: 110 },
        { field: "leaf", headerName: "Leaf", width: 80, cellClass: "font-mono-num" },
        { field: "panel", headerName: "Panel", width: 85 },
        { field: "bound_table", headerName: "Table", width: 115 },
        { field: "bound_row", headerName: "Row", width: 70, cellClass: "font-mono-num" },
        { field: "fill", headerName: "Fill", width: 105, cellRenderer: RValueCellRenderer },
        { field: "stroke", headerName: "Stroke", width: 105, cellRenderer: RValueCellRenderer },
        { field: "text", headerName: "Text", width: 150 },
        { field: "x0", headerName: "x0 (pt)", width: 80, cellRenderer: RValueCellRenderer },
        { field: "y0", headerName: "y0 (pt)", width: 80, cellRenderer: RValueCellRenderer },
        { field: "stable_id", headerName: "Stable ID", width: 165, cellClass: "font-mono-num" },
      ];
      return { rowData: rows, columnDefs: cols, tableMeta: null };
    }

    if (activeTableTab === "__bindings__") {
      const rows = bundle.derived.bindingsElements.map((b) => {
        const rawMatch = bundle.index.inferredRawByElement.get(b.element);
        return {
          ...b,
          inferred_raw: rawMatch ? rawMatch.rawKeyLabels.join(", ") : null,
          raw_join_status: rawMatch?.status ?? null,
        };
      });
      const cols: ColDef[] = [
        { field: "element", headerName: "Element", pinned: "left", width: 95, cellClass: "font-mono-num font-semibold" },
        { field: "status", headerName: "Status", width: 105, cellRenderer: StatusBadgeRenderer },
        { field: "table", headerName: "Built Table", width: 120 },
        { field: "row", headerName: "Row", width: 75, cellClass: "font-mono-num" },
        { field: "inferred_raw", headerName: "Raw Entity (Inferred)", width: 170 },
        { field: "raw_join_status", headerName: "Raw Join", width: 100, cellRenderer: StatusBadgeRenderer },
        { field: "dev", headerName: "Dev (pt vs 0.5)", width: 145, cellRenderer: DeviationRenderer },
        { field: "leaf", headerName: "Leaf", width: 85, cellClass: "font-mono-num" },
        { field: "n_rows", headerName: "n_rows", width: 85, cellClass: "font-mono-num" },
      ];
      return { rowData: rows, columnDefs: cols, tableMeta: null };
    }

    if (activeTableTab === "__roles__") {
      const rows = bundle.derived.rolesElements;
      const cols: ColDef[] = [
        { field: "element", headerName: "Element", pinned: "left", width: 95, cellClass: "font-mono-num font-semibold" },
        { field: "role", headerName: "Role", width: 120 },
        { field: "kind", headerName: "Kind", width: 115 },
        { field: "status", headerName: "Status", width: 110, cellRenderer: StatusBadgeRenderer },
        { field: "rule", headerName: "Rule", width: 140 },
        { field: "cue", headerName: "Cue", width: 140 },
        { field: "leaf", headerName: "Leaf", width: 85, cellClass: "font-mono-num" },
        { field: "flagged", headerName: "Flagged", width: 85 },
        { field: "reason", headerName: "Reason", flex: 1, minWidth: 160 },
      ];
      return { rowData: rows, columnDefs: cols, tableMeta: null };
    }

    if (activeTableTab === "__records__") {
      const rows = bundle.records.map((r) => ({
        id: r.id,
        layer: r.layer,
        stage: r.workbenchStage,
        status: r.projectionStatus,
        anchor_status: r.anchor_status,
        check_kind: r.check?.kind ?? null,
        check_status: r.check?.status ?? null,
        targets: r.resolvedTargets.join(", "),
        by: r.provenance.by,
        source: r.body.source ?? r.body.source_type ?? null,
        text: r.body.text ?? r.body.description ?? r.body.alt_text ?? "",
      }));
      const cols: ColDef[] = [
        { field: "layer", headerName: "Layer", pinned: "left", width: 95, cellClass: "font-semibold" },
        { field: "status", headerName: "Status", width: 110, cellRenderer: StatusBadgeRenderer },
        { field: "stage", headerName: "Stage", width: 105 },
        { field: "targets", headerName: "Targets", width: 110, cellClass: "font-mono-num" },
        { field: "text", headerName: "Semantic Content", flex: 1, minWidth: 260 },
        { field: "check_kind", headerName: "Check", width: 90 },
        { field: "check_status", headerName: "Check Status", width: 115, cellRenderer: StatusBadgeRenderer },
        { field: "source", headerName: "External Source", width: 150 },
        { field: "by", headerName: "By", width: 100 },
        { field: "id", headerName: "Record ID", width: 185, cellClass: "font-mono-num" },
      ];
      return { rowData: rows, columnDefs: cols, tableMeta: null };
    }

    // Standard bundle data table (`raw`, `built_layer1`, ...)
    const tbl = bundle.tables[activeTableTab];
    if (!tbl) return { rowData: [], columnDefs: [] as ColDef[], tableMeta: null };
    if (!tbl.data) {
      return { rowData: [], columnDefs: [] as ColDef[], tableMeta: tbl.meta };
    }

    const df = tbl.data;
    const rawObjects = dfToObjects(df);
    const rows = rawObjects.map((obj, idx) => {
      const row1 = idx + 1;
      const linkedEls = bundle.index.elementsByTableRow.get(`${tbl.meta.name}:${row1}`) ?? [];
      return {
        ...obj,
        __row1: row1,
        __rowIdx0: idx,
        __elements: linkedEls.join(", "),
        __elementList: linkedEls,
      };
    });

    const keySet = new Set(tbl.meta.key);
    const cols: ColDef[] = [
      {
        field: "__row1",
        headerName: "#",
        pinned: "left",
        width: 56,
        cellClass: "font-mono-num opacity-70",
      },
    ];

    if (df.rownames) {
      cols.push({
        field: ".rownames",
        headerName: keySet.has(".rownames") ? "🔑 .rownames" : ".rownames",
        headerTooltip: keySet.has(".rownames")
          ? `Row Key (rule ${tbl.meta.key_rule ?? "?"}): ${tbl.meta.key_basis ?? ""}`
          : "R row names",
        pinned: "left",
        width: 155,
        cellClass: "font-semibold",
      });
    }

    cols.push({
      field: "__elements",
      headerName: "Elements",
      pinned: "left",
      width: 96,
      cellClass: "font-mono-num",
    });

    for (const colName of df.names) {
      const isKey = keySet.has(colName);
      const colInfo = df.columns[colName];
      cols.push({
        field: colName,
        headerName: isKey ? `🔑 ${colName}` : colName,
        headerTooltip: `${colName} (${colInfo?.rType ?? "unknown"})${
          isKey ? ` · Row Key (rule ${tbl.meta.key_rule ?? "?"}: ${tbl.meta.key_basis ?? ""})` : ""
        }`,
        pinned: isKey ? "left" : undefined,
        minWidth: 86,
        width: colInfo?.rType === "character" || colInfo?.rType === "factor" ? 115 : 92,
        cellRenderer: RValueCellRenderer,
        cellRendererParams: { df, colName },
      });
    }

    return { rowData: rows, columnDefs: cols, tableMeta: tbl.meta };
  }, [bundle, activeTableTab]);

  // Figure -> AG Grid sync: scroll & highlight matching row(s) when SVG selection changes
  useEffect(() => {
    const api = gridApiRef.current;
    if (!api || !bundle || selectedElementIds.length === 0) return;

    const selectedSet = new Set(selectedElementIds);
    let firstMatchedIdx: number | null = null;

    api.forEachNode((node) => {
      const d = node.data as Record<string, unknown> | undefined;
      if (!d) return;
      let match = false;
      if (activeTableTab === "__elements__") {
        match = selectedSet.has(String(d.id ?? ""));
      } else if (activeTableTab === "__bindings__" || activeTableTab === "__roles__") {
        match = selectedSet.has(String(d.element ?? ""));
      } else if (activeTableTab === "__records__") {
        const targets = String(d.targets ?? "")
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean);
        match = targets.some((t) => selectedSet.has(t));
      } else {
        const els = (d.__elementList as string[] | undefined) ?? [];
        match = els.some((eid) => selectedSet.has(eid));
      }
      node.setSelected(match, false);
      if (match && firstMatchedIdx === null && node.rowIndex !== null) {
        firstMatchedIdx = node.rowIndex;
      }
    });

    if (firstMatchedIdx !== null) {
      api.ensureIndexVisible(firstMatchedIdx, "middle");
    }
  }, [selectedElementIds, bundle, activeTableTab]);

  const handleFilterChanged = useCallback(() => {
    const api = gridApiRef.current;
    if (!api) return;
    const total = rowData.length;
    const displayed = api.getDisplayedRowCount();
    setFilteredCount(displayed < total ? displayed : null);
  }, [rowData.length]);

  const syncDisplayedRowsToFigure = useCallback(() => {
    const api = gridApiRef.current;
    if (!api) return;
    const ids: string[] = [];
    api.forEachNodeAfterFilter((node) => {
      const d = node.data as Record<string, unknown> | undefined;
      if (!d) return;
      if (activeTableTab === "__elements__") {
        if (d.id) ids.push(String(d.id));
      } else if (activeTableTab === "__bindings__" || activeTableTab === "__roles__") {
        if (d.element) ids.push(String(d.element));
      } else if (Array.isArray(d.__elementList)) {
        for (const eid of d.__elementList) ids.push(String(eid));
      }
    });
    setGridFilterElementIds(ids.length > 0 ? Array.from(new Set(ids)) : null);
  }, [activeTableTab, setGridFilterElementIds]);

  if (!bundle) return null;

  const tabs: Array<{ id: string; label: string; count: number; warn?: boolean }> = [
    ...bundle.tableOrder.map((nm) => ({
      id: nm,
      label: nm,
      count: bundle.tables[nm]?.meta.nrow ?? 0,
      warn:
        bundle.tables[nm]?.meta.status === "partial_data" ||
        bundle.tables[nm]?.meta.status === "missing_data",
    })),
    { id: "__bindings__", label: "Bindings", count: bundle.derived.bindingsElements.length },
    { id: "__elements__", label: "Elements", count: bundle.substrate.elements.length },
    { id: "__roles__", label: "Roles", count: bundle.derived.rolesElements.length },
    { id: "__records__", label: "Records", count: bundle.records.length },
  ];

  return (
    <div
      className="flex h-full w-full flex-col overflow-hidden"
      style={{ background: "var(--bg-surface)" }}
    >
      {/* Tab Strip + AG Grid Toolbar */}
      <div
        className="flex flex-wrap items-center justify-between gap-2 border-b px-2.5 py-1.5"
        style={{ borderColor: "var(--border-subtle)" }}
      >
        <div className="flex items-center gap-1 overflow-x-auto">
          <Table2 className="mr-1 h-3.5 w-3.5 shrink-0" style={{ color: "var(--ink-muted)" }} />
          {tabs.map((t) => {
            const active = t.id === activeTableTab;
            return (
              <button
                key={t.id}
                type="button"
                onClick={() => {
                  setActiveTableTab(t.id);
                  setFilteredCount(null);
                }}
                className="inline-flex shrink-0 items-center gap-1.5 rounded-md px-2 py-1 text-[11.5px] font-medium transition-colors"
                style={{
                  background: active ? "var(--st-focus-soft)" : "transparent",
                  color: active ? "var(--st-focus)" : "var(--ink-secondary)",
                }}
              >
                <span>{t.label}</span>
                <span
                  className="font-mono-num rounded px-1 text-[10px]"
                  style={{
                    background: active ? "var(--bg-surface)" : "var(--bg-subtle)",
                    color: active ? "var(--st-focus)" : "var(--ink-muted)",
                  }}
                >
                  {t.count.toLocaleString()}
                </span>
                {t.warn && <AlertTriangle className="h-3 w-3" style={{ color: "var(--st-warn)" }} />}
              </button>
            );
          })}
        </div>

        <div className="flex items-center gap-2">
          {tableMeta && (
            <span
              className="hidden items-center gap-1 rounded px-2 py-0.5 text-[10.5px] md:inline-flex"
              style={{ background: "var(--bg-subtle)", color: "var(--ink-secondary)" }}
              title={tableMeta.key_basis ?? undefined}
            >
              <KeyRound className="h-3 w-3" style={{ color: "var(--st-verified)" }} />
              key: <code className="font-mono-num font-semibold">{tableMeta.key.join(" + ") || "none"}</code>
              {tableMeta.key_rule !== null ? ` (rule ${tableMeta.key_rule})` : ""}
            </span>
          )}

          {filteredCount !== null && (
            <button
              type="button"
              onClick={syncDisplayedRowsToFigure}
              className="inline-flex items-center gap-1 rounded-md px-2 py-1 text-[11px] font-semibold text-white"
              style={{ background: "var(--st-focus)" }}
            >
              <Filter className="h-3 w-3" />
              Sync {filteredCount} rows to Figure
            </button>
          )}
          {gridFilterElementIds && (
            <button
              type="button"
              onClick={() => setGridFilterElementIds(null)}
              className="inline-flex items-center gap-1 rounded-md border px-2 py-1 text-[11px]"
              style={{ borderColor: "var(--border-strong)", color: "var(--ink-secondary)" }}
            >
              Clear Sync <X className="h-3 w-3" />
            </button>
          )}

          <div
            className="flex items-center gap-1.5 rounded-md border px-2 py-0.5"
            style={{
              background: "var(--bg-canvas)",
              borderColor: "var(--border-subtle)",
            }}
          >
            <Search className="h-3 w-3" style={{ color: "var(--ink-muted)" }} />
            <input
              type="text"
              value={quickFilter}
              onChange={(e) => setQuickFilter(e.target.value)}
              placeholder="Filter rows..."
              className="w-28 bg-transparent text-[11.5px] focus:outline-none sm:w-36"
              style={{ color: "var(--ink-primary)" }}
            />
            {quickFilter && (
              <button type="button" onClick={() => setQuickFilter("")}>
                <X className="h-3 w-3" style={{ color: "var(--ink-muted)" }} />
              </button>
            )}
          </div>

          <button
            type="button"
            onClick={() => gridApiRef.current?.exportDataAsCsv({ fileName: `gloss-${activeTableTab}.csv` })}
            title="Export active table to CSV"
            className="rounded-md border p-1 hover:bg-[var(--bg-subtle)]"
            style={{ borderColor: "var(--border-subtle)", color: "var(--ink-secondary)" }}
          >
            <Download className="h-3.5 w-3.5" />
          </button>
        </div>
      </div>

      {/* Partial/Missing Data Transparency Banner (Invariant: never degrade silently) */}
      {tableMeta && (tableMeta.status === "partial_data" || tableMeta.status === "missing_data") && (
        <div
          className="flex items-center gap-2 border-b px-3 py-1 text-[11px]"
          style={{
            background: "var(--st-warn-soft)",
            borderColor: "var(--border-subtle)",
            color: "var(--st-warn)",
          }}
        >
          <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
          <span>
            <strong>{tableMeta.status}</strong> (embed={tableMeta.embedded})
            {tableMeta.dropped.length > 0 ? ` · dropped columns: ${tableMeta.dropped.join(", ")}` : ""}
            {tableMeta.not_stored.length > 0 ? ` · not stored: ${tableMeta.not_stored.join("; ")}` : ""}
          </span>
        </div>
      )}

      {/* AG Grid Body */}
      <div className="min-h-0 flex-1 w-full">
        {tableMeta && tableMeta.status === "missing_data" ? (
          <div className="flex h-full items-center justify-center p-6 text-center text-xs" style={{ color: "var(--ink-muted)" }}>
            Table <strong>{tableMeta.name}</strong> was written with <code>embed = &quot;{tableMeta.embedded}&quot;</code> (no rows embedded).
            Columns: {tableMeta.columnNames.join(", ")}.
          </div>
        ) : (
          <AgGridReact
            theme={agTheme}
            suppressFieldDotNotation={true}
            rowData={rowData}
            columnDefs={columnDefs}
            quickFilterText={quickFilter}
            defaultColDef={{
              sortable: true,
              filter: true,
              resizable: true,
              floatingFilter: false,
            }}
            rowSelection={{ mode: "multiRow", checkboxes: false, enableClickSelection: true }}
            animateRows={false}
            onGridReady={(e) => {
              gridApiRef.current = e.api;
            }}
            onFilterChanged={handleFilterChanged}
            onRowClicked={(e) => {
              const d = e.data as Record<string, unknown> | undefined;
              if (!d) return;
              if (activeTableTab === "__elements__" && d.id) {
                selectElement(String(d.id));
              } else if ((activeTableTab === "__bindings__" || activeTableTab === "__roles__") && d.element) {
                selectElement(String(d.element));
              } else if (activeTableTab === "__records__" && d.id) {
                selectRecord(String(d.id));
              } else if (typeof d.__row1 === "number") {
                selectTableRow(activeTableTab, d.__row1);
              }
            }}
          />
        )}
      </div>
    </div>
  );
};
