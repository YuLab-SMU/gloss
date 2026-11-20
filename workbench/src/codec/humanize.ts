import { resolveCheckGroupElements } from "./outline";
import type { GlossBundle, GlossCheck, GlossCheckGroup, GlossElement } from "./types";

export type WorkbenchViewMode = "reader" | "inspector";
export type ReaderLens = "figure" | "explore" | "findings" | "story";

export interface ReaderCheckSummary {
  tone: "verified" | "mixed" | "failed" | "neutral";
  label: string;
  actionLabel: string;
  passedCount: number;
  failedCount: number;
  totalCount: number;
}

/**
 * Translate a `gloss` deterministic check into calm, truthful reader-facing wording
 * (preserving epistemic honesty: partial/failed checks are never presented as verified).
 */
export function summarizeCheckForReader(check: GlossCheck): ReaderCheckSummary {
  const totalCount = check.groups.length;
  const passedCount = check.groups.filter((g) => g.passed === true).length;
  const failedCount = check.groups.filter((g) => g.passed === false).length;

  if (check.status === "verified") {
    return {
      tone: "verified",
      label: totalCount > 1 ? `Confirmed across all ${totalCount} items` : "Confirmed in source data",
      actionLabel: "View numbers",
      passedCount,
      failedCount,
      totalCount,
    };
  }
  if (check.status === "partial") {
    return {
      tone: "mixed",
      label:
        failedCount > 0
          ? `${passedCount} of ${totalCount} match · ${failedCount} ${failedCount === 1 ? "exception" : "exceptions"}`
          : `Partially confirmed (${passedCount} of ${totalCount})`,
      actionLabel: failedCount > 0 ? `Inspect ${failedCount}` : "View breakdown",
      passedCount,
      failedCount,
      totalCount,
    };
  }
  if (check.status === "failed" || check.status === "rejected") {
    return {
      tone: "failed",
      label: "Not supported by source data",
      actionLabel: "View details",
      passedCount,
      failedCount,
      totalCount,
    };
  }
  return {
    tone: "neutral",
    label: "Not automatically checked",
    actionLabel: "Details",
    passedCount,
    failedCount,
    totalCount,
  };
}

/** Convert internal panel keys (e.g. `zscore slice 3_1`, `am=1`, `plot1_1`) into clean reader labels. */
export function humanizePanelLabel(panelKey: string | null | undefined): string | null {
  if (!panelKey) return null;
  const trimmed = panelKey.trim();
  if (!trimmed || /^\d+$/.test(trimmed)) return null;
  if (/^plot\d+_\d+$/i.test(trimmed)) {
    const m = trimmed.match(/^plot(\d+)_/i);
    return m ? `Panel ${m[1]}` : null;
  }
  if (/_?slice\s+\d+_\d+$/i.test(trimmed)) {
    return null;
  }
  return trimmed.replace(/=/g, " = ").replace(/\s+=\s+/g, " = ");
}

export interface VariableMeta {
  name: string;
  unit?: string;
  description?: string;
}

/**
 * Extract a column -> { unit, description } lookup map from `context.data_dictionary`
 * (supports both `{ variables: [...] }` from `gl_add_context()` and `{ entries: [...] }` from CSV/JSON files).
 */
export function extractDataDictionaryMap(bundle: GlossBundle): Map<string, VariableMeta> {
  const map = new Map<string, VariableMeta>();
  const dd = bundle.context.data_dictionary;
  if (!dd?.found || !dd.value || typeof dd.value !== "object") return map;

  const val = dd.value as Record<string, unknown>;
  const list = Array.isArray(val.variables)
    ? val.variables
    : Array.isArray(val.entries)
      ? val.entries
      : [];

  for (const item of list) {
    if (!item || typeof item !== "object") continue;
    const obj = item as Record<string, unknown>;
    const nm = String(obj.name ?? obj.column ?? obj.variable ?? "").trim();
    if (!nm) continue;
    map.set(nm, {
      name: nm,
      unit: typeof obj.unit === "string" && obj.unit.trim() ? obj.unit.trim() : undefined,
      description:
        typeof obj.description === "string" && obj.description.trim()
          ? obj.description.trim()
          : undefined,
    });
  }
  return map;
}

/**
 * Derive a clean human figure title from the plot SVG title element or document caption.
 */
export function getFigureDisplayTitle(bundle: GlossBundle): string {
  const docCaption = (bundle.context.doc?.value as Record<string, unknown> | null | undefined)?.caption;
  if (typeof docCaption === "string" && docCaption.trim()) return docCaption.trim();

  const titleCandidates = bundle.substrate.elements.filter((e) => {
    if (e.tag !== "text" || !e.text?.trim()) return false;
    const lf = e.leaf ? bundle.index.leafById.get(e.leaf) : undefined;
    const p = (lf?.path ?? "").toLowerCase();
    if (
      p.includes("subtitle") ||
      p.includes("caption") ||
      p.includes("strip") ||
      p.includes("axis") ||
      p.includes("guide-box") ||
      p.includes("legend")
    ) {
      return false;
    }
    const role = bundle.index.roleByElement.get(e.id);
    return role?.kind === "title" || p.includes("plot.title");
  });
  titleCandidates.sort((a, b) => a.y0 - b.y0);
  if (titleCandidates[0]?.text?.trim()) return titleCandidates[0].text.trim();

  return bundle.sourceName.replace(/\.(html?|svg)$/i, "");
}

/**
 * Derive a clean human subtitle from the plot SVG subtitle element, if present.
 */
export function getFigureSubtitle(bundle: GlossBundle): string | null {
  const sub = bundle.substrate.elements.find((e) => {
    if (e.tag !== "text" || !e.text?.trim()) return false;
    const lf = e.leaf ? bundle.index.leafById.get(e.leaf) : undefined;
    const p = (lf?.path ?? "").toLowerCase();
    const role = bundle.index.roleByElement.get(e.id);
    return p.includes("subtitle") || role?.kind === "subtitle";
  });
  return sub?.text?.trim() ?? null;
}

/**
 * Translate technical `gl_check()` group identifiers (e.g. `"1 / 1"` for `PANEL=1, group=1`)
 * into self-explanatory scientific labels (e.g. `"am = 0 · cyl = 4"`) using panel keys and
 * constant raw variables across the group's bound elements.
 */
export function humanizeCheckGroupLabel(
  bundle: GlossBundle,
  check: GlossCheck,
  tableName: string | undefined,
  groupRow: GlossCheckGroup
): string {
  const rawGroup = String(groupRow.group ?? "");
  if (rawGroup === "all") return "All observations";

  // Row-level checks (`range`, `value`, `exists`): resolve rowname (e.g. gene symbol MKI67) + checked column!
  if (typeof groupRow.row === "number" && groupRow.row >= 1) {
    const tblName = tableName ?? bundle.tableOrder.find((n) => n.startsWith("matrix_") || n.startsWith("built")) ?? "";
    const df = tblName ? bundle.tables[tblName]?.data : null;
    const colArg = typeof check.args.column === "string" ? check.args.column : null;
    const rowLabel = df?.rownames?.[groupRow.row - 1] ?? `Row ${groupRow.row}`;
    return colArg ? `${rowLabel} (${colArg})` : rowLabel;
  }

  // If the check already ran on a human raw table (not opaque numeric built_layer indices like "1 / 1"),
  // keep the descriptive label cleanly!
  const looksOpaqueNumeric = /^\s*\d+(?:\s*\/\s*\d+)*\s*$/.test(rawGroup);
  if (rawGroup && !looksOpaqueNumeric && !rawGroup.includes("PANEL=")) {
    return rawGroup.replace(/\s*\/\s*/g, " · ");
  }

  const els = resolveCheckGroupElements(bundle, check, tableName, groupRow);
  if (els.length === 0) return rawGroup || "Group";

  const parts: string[] = [];

  // 1. Panel key if all group elements share one panel (e.g. "am=0" -> "am = 0")
  const panelIds = new Set(
    els.map((id) => bundle.index.elementById.get(id)?.panel).filter((p): p is string => Boolean(p))
  );
  if (panelIds.size === 1) {
    const pid = Array.from(panelIds)[0];
    const panel = bundle.index.panelById.get(pid);
    if (panel?.key && panel.key !== "1" && !panel.key.endsWith("_1")) {
      parts.push(panel.key.replace(/=/g, " = "));
    }
  }

  // 2. Any referenced discrete raw column that is constant across this group's elements (e.g. "cyl = 4")
  const firstRawName = els
    .map((id) => bundle.index.inferredRawByElement.get(id)?.rawTable)
    .find((n): n is string => Boolean(n));
  const rawTable =
    (firstRawName ? bundle.tables[firstRawName] : null) ??
    bundle.tables["raw"] ??
    Object.values(bundle.tables).find((t) => t.meta.role === "raw");
  const rawDf = rawTable?.data ?? null;
  if (rawTable && rawDf) {
    const panelVarNames = new Set(
      bundle.substrate.panels.map((p) => (p.key ?? "").split("=")[0]?.trim()).filter(Boolean)
    );
    const refCols = rawTable.meta.referenced.filter((c) => !panelVarNames.has(c) && Boolean(rawDf.columns[c]));
    for (const cn of refCols) {
      const vals = new Set<string>();
      for (const eid of els) {
        const rm = bundle.index.inferredRawByElement.get(eid);
        if (!rm || rm.rawTable !== rawTable.meta.name || rm.rawRows.length === 0) continue;
        const v = rawDf.columns[cn].values[rm.rawRows[0] - 1];
        if (v !== null && v !== undefined) vals.add(String(v));
      }
      if (vals.size === 1) {
        parts.push(`${cn} = ${Array.from(vals)[0]}`);
      }
    }
  }

  return parts.length > 0 ? parts.join(" · ") : groupRow.group;
}

/** Human-friendly status phrasing for scientific readers (truthful, never hides failures/uncertainty). */
export function humanizeStatus(status: string): string {
  switch (status) {
    case "verified":
      return "Verified";
    case "partial":
      return "Partial · Exception";
    case "failed":
    case "rejected":
      return "Not Supported";
    case "ambiguous":
      return "Ambiguous";
    case "proposed":
      return "Analyst Note";
    case "speculative":
      return "Hypothesis";
    case "uncheckable":
    case "refused":
      return "Unchecked";
    default:
      return status;
  }
}

export function humanizeCheckKind(kind: string): string {
  switch (kind) {
    case "trend":
      return "Linear Trend Check";
    case "compare":
      return "Group Comparison Check";
    case "count":
      return "Sample Size Check";
    case "range":
      return "Value Range Check";
    case "value":
      return "Exact Value Check";
    case "exists":
      return "Existence Check";
    default:
      return `${kind} Check`;
  }
}

/** Convert snake_case or slug identifiers (e.g. `cross_panel_comparison`) into readable prose. */
export function humanizeToken(raw: string): string {
  const s = raw.trim();
  if (!s) return "";
  if (!s.includes("_")) return s;
  const words = s.replace(/_/g, " ").replace(/\s+/g, " ").trim();
  return words.charAt(0).toUpperCase() + words.slice(1);
}

/** Map engineering-oriented Outline section titles to calm scientific phrasing in Reader mode. */
export function humanizeOutlineLabel(
  id: string,
  label: string,
  subtitle: string | undefined,
  bundle: GlossBundle
): { label: string; subtitle?: string } {
  if (id === "root:figure") {
    const nVerified = bundle.derived.bindingsElements.filter((b) => b.status === "verified").length;
    const nAmb = bundle.derived.bindingsElements.filter((b) => b.status === "ambiguous").length;
    const nPanels = bundle.substrate.panels.length;
    if (nVerified > 0 || nAmb > 0) {
      const countText =
        nAmb > 0 ? `${nVerified} verified · ${nAmb} overlapping` : `${nVerified} observations`;
      return {
        label,
        subtitle: `${countText}${nPanels > 1 ? ` · ${nPanels} panels` : ""}`,
      };
    }
    return { label, subtitle: undefined };
  }
  switch (id) {
    case "root:data":
      return {
        label: "Plotted Data",
        subtitle: subtitle?.replace("bound marks", "observations"),
      };
    case "root:semantics":
      return {
        label: "Notes & Findings",
        subtitle: subtitle?.replace("records", "notes"),
      };
    case "sem:group:claims":
      return { label: "Statistical Findings", subtitle };
    case "sem:group:contextual":
      return { label: "Entity Context", subtitle };
    case "sem:group:analytical":
      return { label: "Observations", subtitle };
    case "sem:group:narrative":
      return { label: "Guided Story", subtitle };
    case "sem:group:relations":
      return { label: "Comparisons", subtitle };
    case "sem:group:behavior":
      return { label: "Interactive Guides", subtitle };
    case "root:chrome":
      return { label: "Titles & Guides", subtitle };
    default:
      return {
        label: humanizeToken(label.replace(/^Panel · /, "").replace(/=/g, " = ").replace(/\s+=\s+/g, " = ")),
        subtitle: subtitle?.replace("marks across panels", "observations").replace("marks", "points"),
      };
  }
}

/**
 * Format a clean human-readable tooltip summary for a hovered mark in Scientific Reader mode.
 */
export function formatReaderTooltip(bundle: GlossBundle, el: GlossElement): {
  title: string;
  subtitle: string | null;
  metrics: Array<{ label: string; value: string; unit?: string }>;
  verified: boolean;
} {
  const dict = extractDataDictionaryMap(bundle);
  const binding = bundle.index.bindingByElement.get(el.id);
  const matCell = bundle.index.matrixCellByElement.get(el.id);
  const panel = el.panel ? bundle.index.panelById.get(el.panel) : null;

  if (matCell) {
    const valStr =
      typeof matCell.value === "number"
        ? matCell.value.toFixed(2).replace(/\.?0+$/, "")
        : String(matCell.value ?? "NA");
    const unitMeta = dict.get(matCell.matrixName);
    return {
      title: `${matCell.rowLabel} × ${matCell.colLabel}`,
      subtitle: panel?.key ?? matCell.matrixName,
      metrics: [
        { label: matCell.matrixName, value: valStr, unit: unitMeta?.unit },
        { label: "row", value: String(matCell.rowIndex) },
        { label: "col", value: String(matCell.colIndex) },
      ],
      verified: binding?.status === "verified",
    };
  }

  const rawMatch = bundle.index.inferredRawByElement.get(el.id);
  const role = bundle.index.roleByElement.get(el.id);

  const title =
    rawMatch?.rawKeyLabels[0] ??
    el.text?.trim() ??
    (role?.kind ? `${role.kind}` : el.tag);

  const metrics: Array<{ label: string; value: string; unit?: string }> = [];
  if (rawMatch && rawMatch.rawRows.length > 0) {
    const rawTbl = bundle.tables[rawMatch.rawTable];
    const df = rawTbl?.data;
    const r0 = rawMatch.rawRows[0] - 1;
    if (df && r0 >= 0 && r0 < df.nrow) {
      const priorityCols = rawTbl.meta.referenced.length > 0 ? rawTbl.meta.referenced : df.names.slice(0, 4);
      for (const cn of priorityCols.slice(0, 4)) {
        if (!df.columns[cn]) continue;
        const v = df.columns[cn].values[r0];
        if (v === null || v === undefined) continue;
        const valStr = typeof v === "number" && !Number.isInteger(v) ? v.toFixed(2).replace(/\.?0+$/, "") : String(v);
        metrics.push({ label: cn, value: valStr, unit: dict.get(cn)?.unit });
      }
    }
  } else if (binding?.table && binding.row) {
    const df = bundle.tables[binding.table]?.data;
    const r0 = binding.row - 1;
    if (df && r0 >= 0 && r0 < df.nrow) {
      for (const cn of ["x", "y"]) {
        const v = df.columns[cn]?.values[r0];
        if (typeof v === "number") {
          metrics.push({ label: cn, value: v.toFixed(2).replace(/\.?0+$/, "") });
        }
      }
    }
  }

  return {
    title,
    subtitle: panel?.key ? panel.key.replace(/=/g, " = ") : null,
    metrics,
    verified: binding?.status === "verified",
  };
}
