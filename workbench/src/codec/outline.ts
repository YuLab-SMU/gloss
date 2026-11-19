import type {
  GlossBundle,
  GlossCheck,
  GlossCheckGroup,
  GlossElement,
  GlossRecord,
} from "./types";

export type OutlineViewMode = "semantic" | "data" | "grob";

export type OutlineIconKind =
  | "figure"
  | "frame"
  | "data"
  | "group"
  | "point"
  | "text"
  | "image"
  | "legend"
  | "axis"
  | "grid"
  | "claim"
  | "exception"
  | "context"
  | "relation"
  | "narrative"
  | "behavior"
  | "leaf";

export interface OutlineNode {
  id: string;
  label: string;
  subtitle?: string;
  icon: OutlineIconKind;
  swatch?: string | null;
  /** All SVG element IDs represented by this node (for Focus, Zoom, and Eye visibility). */
  elementIds: string[];
  /** Number of semantic records anchored to this node or its subtree (blue circular badge). */
  recordCount: number;
  /** True when a partial/failed claim or warning belongs to this node. */
  hasWarning?: boolean;
  /** Optional direct link to a semantic record or check group. */
  recordId?: string;
  leafId?: string;
  stageHint?: "raw" | "structure" | "binding" | "analytical" | "contextual" | "relation" | "claim" | "narrative" | "behavior";
  defaultExpanded?: boolean;
  children: OutlineNode[];
}

export interface FocusScope {
  id: string;
  label: string;
  kind: OutlineIconKind;
  elementIds: string[];
  recordId?: string;
  swatch?: string | null;
  isException?: boolean;
}

/** Resolve elements belonging to a gl_check() group row (e.g. `1 / 1`, `PANEL=1, group=2`, `all`). */
export function resolveCheckGroupElements(
  bundle: GlossBundle,
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
  const matched: string[] = [];
  for (let r = 0; r < df.nrow; r += 1) {
    const ok = keyPairs.every(([col, val]) => {
      const colData = df.columns[col];
      if (!colData) return false;
      return String(colData.values[r] ?? "") === val;
    });
    if (ok) {
      const els = bundle.index.elementsByTableRow.get(`${tblName}:${r + 1}`) ?? [];
      matched.push(...els);
    }
  }
  return Array.from(new Set(matched));
}

interface DataGroupInfo {
  key: string;
  label: string;
  swatch: string | null;
  elementIds: string[];
}

/**
 * Infer clean human-readable data groups (e.g. `cyl = 4`, `cyl = 6`, `cyl = 8`) from
 * built_layer aesthetic groups + referenced raw columns (without hardcoding any dataset).
 */
function inferDataGroups(bundle: GlossBundle, candidateElementIds?: Set<string>): DataGroupInfo[] {
  const bindings = bundle.derived.bindingsElements.filter(
    (b) => b.table && b.row && b.status !== "unbound" && (!candidateElementIds || candidateElementIds.has(b.element))
  );
  if (bindings.length === 0) return [];

  const rawTable = bundle.tables["raw"] ?? Object.values(bundle.tables).find((t) => t.meta.role === "raw");
  const rawDf = rawTable?.data ?? null;

  // Group bound elements by their built (colour || fill || group) aesthetic signature
  const buckets = new Map<string, { swatch: string | null; elements: string[]; builtGroupVals: Set<string> }>();
  for (const b of bindings) {
    const builtDf = b.table ? bundle.tables[b.table]?.data : null;
    if (!builtDf || !b.row || b.row < 1 || b.row > builtDf.nrow) continue;
    const r0 = b.row - 1;
    const colourVal = builtDf.columns["colour"]?.values[r0];
    const fillVal = builtDf.columns["fill"]?.values[r0];
    const groupVal = builtDf.columns["group"]?.values[r0];
    const swatch =
      typeof colourVal === "string" && colourVal.startsWith("#")
        ? colourVal
        : typeof fillVal === "string" && fillVal.startsWith("#")
          ? fillVal
          : null;
    const sig = swatch ?? (groupVal !== null && groupVal !== undefined ? `group:${String(groupVal)}` : "all");
    let bucket = buckets.get(sig);
    if (!bucket) {
      bucket = { swatch, elements: [], builtGroupVals: new Set() };
      buckets.set(sig, bucket);
    }
    bucket.elements.push(b.element);
    if (groupVal !== null && groupVal !== undefined) bucket.builtGroupVals.add(String(groupVal));
  }

  // Try to discover a referenced raw discrete column that is constant within every bucket (e.g. `cyl`)
  let namingColumn: string | null = null;
  if (rawDf && rawTable && buckets.size > 1) {
    const panelKeys = new Set(
      bundle.substrate.panels.map((p) => (p.key ?? "").split("=")[0]?.trim()).filter(Boolean)
    );
    const candidates = rawTable.meta.referenced.filter((cn) => !panelKeys.has(cn) && Boolean(rawDf.columns[cn]));
    for (const cn of candidates) {
      const allConstant = Array.from(buckets.values()).every((bucket) => {
        const vals = new Set<string>();
        for (const eid of bucket.elements) {
          const rm = bundle.index.inferredRawByElement.get(eid);
          if (!rm || rm.rawRows.length === 0) continue;
          const v = rawDf.columns[cn].values[rm.rawRows[0] - 1];
          if (v !== null && v !== undefined) vals.add(String(v));
        }
        return vals.size === 1;
      });
      if (allConstant) {
        namingColumn = cn;
        break;
      }
    }
  }

  const groups: DataGroupInfo[] = [];
  let idx = 1;
  for (const [sig, bucket] of buckets.entries()) {
    let label = `Group ${idx}`;
    if (namingColumn && rawDf) {
      for (const eid of bucket.elements) {
        const rm = bundle.index.inferredRawByElement.get(eid);
        if (rm && rm.rawRows.length > 0) {
          const v = rawDf.columns[namingColumn].values[rm.rawRows[0] - 1];
          if (v !== null && v !== undefined) {
            label = `${namingColumn} = ${String(v)}`;
            break;
          }
        }
      }
    } else if (bucket.builtGroupVals.size === 1) {
      label = `group ${Array.from(bucket.builtGroupVals)[0]}`;
    } else if (bucket.swatch) {
      label = `series ${bucket.swatch}`;
    }
    groups.push({
      key: sig,
      label,
      swatch: bucket.swatch,
      elementIds: bucket.elements,
    });
    idx += 1;
  }

  groups.sort((a, b) => a.label.localeCompare(b.label, undefined, { numeric: true }));
  return groups;
}

function countRecordsForElements(bundle: GlossBundle, elementIds: string[]): number {
  const seen = new Set<string>();
  for (const eid of elementIds) {
    const recs = bundle.index.recordsByElement.get(eid);
    if (!recs) continue;
    for (const r of recs) seen.add(r.id);
  }
  return seen.size;
}

function elementDisplayLabel(bundle: GlossBundle, el: GlossElement): string {
  const raw = bundle.index.inferredRawByElement.get(el.id);
  if (raw && raw.rawKeyLabels.length > 0) return raw.rawKeyLabels[0];
  if (el.text && el.text.trim()) return el.text.trim();
  const role = bundle.index.roleByElement.get(el.id);
  return role?.kind ? `${role.kind} (${el.id})` : `${el.tag}#${el.id}`;
}

function buildEntityChildren(bundle: GlossBundle, elementIds: string[], prefix: string): OutlineNode[] {
  return elementIds.slice(0, 80).map((eid) => {
    const el = bundle.index.elementById.get(eid);
    const recs = bundle.index.recordsByElement.get(eid) ?? [];
    const binding = bundle.index.bindingByElement.get(eid);
    return {
      id: `${prefix}:el:${eid}`,
      label: el ? elementDisplayLabel(bundle, el) : eid,
      subtitle: binding ? `${eid} · row ${binding.row}` : eid,
      icon: "point" as const,
      swatch: el?.fill ?? el?.stroke ?? null,
      elementIds: [eid],
      recordCount: recs.length,
      hasWarning:
        binding?.status === "ambiguous" ||
        recs.some((r) => r.projectionStatus === "partial" || r.projectionStatus === "rejected"),
      stageHint: recs.length > 0 ? "contextual" : "binding",
      children: [],
    };
  });
}

function buildSemanticRecordsBranch(bundle: GlossBundle): OutlineNode | null {
  if (bundle.records.length === 0) return null;

  const claims = bundle.records.filter((r) => r.layer === "claim");
  const contextual = bundle.records.filter((r) => r.workbenchStage === "contextual");
  const analytical = bundle.records.filter((r) => r.workbenchStage === "analytical");
  const relations = bundle.records.filter((r) => r.layer === "relation");
  const narratives = bundle.records
    .filter((r) => r.layer === "narrative")
    .sort((a, b) => Number(a.body.order ?? 99) - Number(b.body.order ?? 99));
  const behaviors = bundle.records.filter((r) => r.layer === "behavior" || r.layer === "overlay");

  const children: OutlineNode[] = [];

  if (claims.length > 0) {
    const claimNodes: OutlineNode[] = claims.map((rec) => {
      const check = rec.check;
      const tblName = rec.body.check?.table ?? rec.body.table;
      const exceptionChildren: OutlineNode[] = [];
      let allCoveredEls = [...rec.resolvedTargets];

      if (check && check.groups.length > 0) {
        for (const g of check.groups) {
          const gEls = resolveCheckGroupElements(bundle, check, tblName, g);
          if (g.passed === false) {
            exceptionChildren.push({
              id: `sem:exc:${rec.id}:${g.group}`,
              label: `Exception · ${g.group} (n=${g.n})`,
              subtitle:
                typeof g.estimate === "number"
                  ? `slope ${g.estimate >= 0 ? "+" : ""}${g.estimate.toFixed(3)} · failed ${check.kind}`
                  : "failed check",
              icon: "exception",
              elementIds: gEls,
              recordCount: 1,
              hasWarning: true,
              recordId: rec.id,
              stageHint: "claim",
              children: buildEntityChildren(bundle, gEls, `exc-${rec.id}`),
            });
          }
          if (allCoveredEls.length <= 1 && gEls.length > 0) {
            allCoveredEls = Array.from(new Set([...allCoveredEls, ...gEls]));
          }
        }
      }

      const txt = rec.body.text ?? rec.id;
      return {
        id: `sem:rec:${rec.id}`,
        label: txt.length > 44 ? `${txt.slice(0, 44)}…` : txt,
        subtitle: `${rec.projectionStatus}${check ? ` · ${check.kind}` : ""}`,
        icon: rec.projectionStatus === "partial" || rec.projectionStatus === "rejected" ? "exception" : "claim",
        elementIds: allCoveredEls,
        recordCount: 1,
        hasWarning: rec.projectionStatus === "partial" || rec.projectionStatus === "rejected",
        recordId: rec.id,
        stageHint: "claim",
        defaultExpanded: exceptionChildren.length > 0,
        children: exceptionChildren,
      };
    });

    children.push({
      id: "sem:group:claims",
      label: "Claims & Checks",
      subtitle: `${claims.length} checked`,
      icon: "claim",
      elementIds: Array.from(new Set(claimNodes.flatMap((n) => n.elementIds))),
      recordCount: claims.length,
      hasWarning: claimNodes.some((n) => n.hasWarning),
      stageHint: "claim",
      defaultExpanded: true,
      children: claimNodes,
    });
  }

  const pushRecGroup = (
    id: string,
    label: string,
    icon: OutlineIconKind,
    recs: GlossRecord[],
    stageHint: OutlineNode["stageHint"],
    defaultExpanded = false
  ) => {
    if (recs.length === 0) return;
    const nodes: OutlineNode[] = recs.map((rec, idx) => {
      const headline =
        rec.body.label ??
        (rec.layer === "narrative" ? `Step ${rec.body.order ?? idx + 1}` : null) ??
        rec.body.type ??
        rec.layer;
      const bodyText = rec.body.text ?? rec.body.description ?? "";
      return {
        id: `sem:rec:${rec.id}`,
        label:
          rec.layer === "narrative"
            ? `${headline} · ${bodyText.slice(0, 30)}${bodyText.length > 30 ? "…" : ""}`
            : headline && bodyText
              ? `${headline}`
              : bodyText.slice(0, 42),
        subtitle: rec.body.source ?? (bodyText ? bodyText.slice(0, 48) : rec.projectionStatus),
        icon,
        elementIds: rec.resolvedTargets,
        recordCount: 1,
        recordId: rec.id,
        stageHint,
        children: [],
      };
    });
    children.push({
      id,
      label,
      subtitle: `${recs.length}`,
      icon,
      elementIds: Array.from(new Set(nodes.flatMap((n) => n.elementIds))),
      recordCount: recs.length,
      stageHint,
      defaultExpanded,
      children: nodes,
    });
  };

  pushRecGroup("sem:group:contextual", "Contextual Meaning", "context", contextual, "contextual", true);
  pushRecGroup("sem:group:analytical", "Analytical Meaning", "data", analytical, "analytical", false);
  pushRecGroup("sem:group:relations", "Relations", "relation", relations, "relation", true);
  pushRecGroup("sem:group:narrative", "Reading Narrative", "narrative", narratives, "narrative", true);
  pushRecGroup("sem:group:behavior", "Interactive Behavior", "behavior", behaviors, "behavior", false);

  return {
    id: "root:semantics",
    label: "Natural-Language Semantics",
    subtitle: `${bundle.records.length} records`,
    icon: "context",
    elementIds: Array.from(new Set(children.flatMap((c) => c.elementIds))),
    recordCount: bundle.records.length,
    hasWarning: children.some((c) => c.hasWarning),
    defaultExpanded: true,
    children,
  };
}

function buildTypographyAndGuidesBranch(bundle: GlossBundle): OutlineNode | null {
  const boundSet = new Set(bundle.derived.bindingsElements.map((b) => b.element));
  const chromeEls = bundle.substrate.elements.filter((e) => !boundSet.has(e.id));
  if (chromeEls.length === 0) return null;

  const titles: GlossElement[] = [];
  const legends: GlossElement[] = [];
  const axes: GlossElement[] = [];
  const gridsBg: GlossElement[] = [];
  const other: GlossElement[] = [];

  for (const el of chromeEls) {
    const role = bundle.index.roleByElement.get(el.id);
    const leaf = el.leaf ? bundle.index.leafById.get(el.leaf) : undefined;
    const leafPath = `${leaf?.path ?? ""} ${leaf?.name ?? ""}`.toLowerCase();
    const roleKind = (role?.kind ?? "").toLowerCase();
    const path = `${leafPath} ${roleKind}`.toLowerCase();

    if (
      (leafPath.includes("plot.title") ||
        leafPath.includes("plot.subtitle") ||
        leafPath.includes("plot.caption") ||
        leafPath.includes("plot.tag") ||
        roleKind === "title" ||
        roleKind === "subtitle" ||
        roleKind === "caption") &&
      !leafPath.includes("strip") &&
      !leafPath.includes("axis") &&
      !leafPath.includes("guide-box") &&
      !leafPath.includes("legend")
    ) {
      titles.push(el);
    } else if (leafPath.includes("guide-box") || leafPath.includes("legend") || roleKind === "legend" || roleKind === "legend_key" || roleKind === "legend_label" || roleKind === "legend_title") {
      legends.push(el);
    } else if (leafPath.includes("axis") || leafPath.includes("tick") || leafPath.includes("strip") || leafPath.includes("lab") || roleKind.includes("axis") || roleKind.includes("strip") || roleKind.includes("tick")) {
      axes.push(el);
    } else if (path.includes("grid") || path.includes("background") || path.includes("border") || !el.leaf) {
      gridsBg.push(el);
    } else {
      other.push(el);
    }
  }

  const children: OutlineNode[] = [];

  // Promote individual Title / Subtitle / Caption text nodes in top-to-bottom visual order
  titles.sort((a, b) => a.y0 - b.y0);
  for (const el of titles) {
    if (el.tag === "text" && el.text?.trim()) {
      const leaf = el.leaf ? bundle.index.leafById.get(el.leaf) : undefined;
      const kindLabel = (leaf?.path ?? "").toLowerCase().includes("subtitle")
        ? "Subtitle"
        : (leaf?.path ?? "").toLowerCase().includes("caption")
          ? "Caption"
          : "Title";
      children.push({
        id: `chrome:title:${el.id}`,
        label: kindLabel,
        subtitle: el.text.trim(),
        icon: "text",
        elementIds: [el.id],
        recordCount: countRecordsForElements(bundle, [el.id]),
        stageHint: "structure",
        children: [],
      });
    }
  }

  if (legends.length > 0) {
    const legendText = legends.find((e) => e.tag === "text" && e.text?.trim())?.text?.trim();
    children.push({
      id: "chrome:legend",
      label: legendText ? `Legend · ${legendText}` : "Legend",
      subtitle: `${legends.length} shapes`,
      icon: "legend",
      elementIds: legends.map((e) => e.id),
      recordCount: countRecordsForElements(bundle, legends.map((e) => e.id)),
      stageHint: "structure",
      children: [],
    });
  }

  if (axes.length > 0) {
    children.push({
      id: "chrome:axes",
      label: "Axes, Strips & Ticks",
      subtitle: `${axes.length} elements`,
      icon: "axis",
      elementIds: axes.map((e) => e.id),
      recordCount: countRecordsForElements(bundle, axes.map((e) => e.id)),
      stageHint: "structure",
      children: [],
    });
  }

  if (gridsBg.length > 0) {
    children.push({
      id: "chrome:grid",
      label: "Gridlines & Backgrounds",
      subtitle: `${gridsBg.length} shapes`,
      icon: "grid",
      elementIds: gridsBg.map((e) => e.id),
      recordCount: countRecordsForElements(bundle, gridsBg.map((e) => e.id)),
      stageHint: "structure",
      children: [],
    });
  }

  if (other.length > 0) {
    children.push({
      id: "chrome:other",
      label: "Other Decorations",
      subtitle: `${other.length} shapes`,
      icon: "frame",
      elementIds: other.map((e) => e.id),
      recordCount: countRecordsForElements(bundle, other.map((e) => e.id)),
      stageHint: "structure",
      children: [],
    });
  }

  return {
    id: "root:chrome",
    label: "Typography & Guides",
    subtitle: `${chromeEls.length} elements`,
    icon: "frame",
    elementIds: chromeEls.map((e) => e.id),
    recordCount: countRecordsForElements(bundle, chromeEls.map((e) => e.id)),
    defaultExpanded: true,
    children,
  };
}

/**
 * Build the left-panel Outline tree in one of three design/audit perspectives:
 * - `semantic`: Figma/BioRender-style human-readable Outline (Data & Groups + Natural-Language Semantics + Typography & Guides)
 * - `data`: Data-first hierarchy (All Data -> Cross-Panel Aesthetic Groups -> Facet Panels -> Entities)
 * - `grob`: Raw capture leaf hierarchy (Panels -> Leaves L001.. -> Primitives)
 */
export function buildOutlineTree(bundle: GlossBundle, mode: OutlineViewMode): OutlineNode[] {
  const titleCandidates = bundle.substrate.elements.filter((e) => {
    if (e.tag !== "text" || !e.text?.trim()) return false;
    const lf = e.leaf ? bundle.index.leafById.get(e.leaf) : undefined;
    const p = (lf?.path ?? "").toLowerCase();
    if (p.includes("subtitle") || p.includes("caption") || p.includes("strip") || p.includes("axis") || p.includes("guide")) {
      return false;
    }
    const role = bundle.index.roleByElement.get(e.id);
    return role?.kind === "title" || p.includes("plot.title") || p.includes("title");
  });
  titleCandidates.sort((a, b) => a.y0 - b.y0);
  const figureTitle = titleCandidates[0]?.text?.trim() ?? bundle.sourceName;

  const allElementIds = bundle.substrate.elements.map((e) => e.id);
  const allBoundIds = bundle.derived.bindingsElements
    .filter((b) => b.status !== "unbound")
    .map((b) => b.element);

  if (mode === "grob") {
    const panels = bundle.substrate.panels;
    const panelGroups: Array<{ id: string; label: string; leafFilter: (panel: string | null) => boolean }> = [
      ...panels.map((p) => ({
        id: `grob:panel:${p.id}`,
        label: `Panel · ${p.key ?? p.id}`,
        leafFilter: (panel: string | null) => panel === p.id,
      })),
      {
        id: "grob:chrome",
        label: "Guides, Axes & Chrome",
        leafFilter: (panel: string | null) => !panel || !panels.some((p) => p.id === panel),
      },
    ];

    const children: OutlineNode[] = panelGroups
      .map((pg): OutlineNode | null => {
        const leaves = bundle.substrate.leaves.filter((l) => pg.leafFilter(l.panel));
        if (leaves.length === 0) return null;
        const leafNodes: OutlineNode[] = leaves.map((lf) => {
          const els = bundle.substrate.elements.filter((e) => e.leaf === lf.id);
          const roleLf = bundle.derived.rolesLeaves.find((r) => r.leaf === lf.id);
          const ids = els.map((e) => e.id);
          return {
            id: `grob:leaf:${lf.id}`,
            label: `${lf.id} · ${roleLf?.kind ?? lf.name}`,
            subtitle: `${lf.n_drawn} el${lf.status !== "ok" ? ` · ${lf.status}` : ""}`,
            icon: roleLf?.role === "data" ? "data" : "leaf",
            elementIds: ids,
            recordCount: countRecordsForElements(bundle, ids),
            hasWarning: lf.status !== "ok",
            leafId: lf.id,
            stageHint: "structure",
            children: buildEntityChildren(bundle, ids, `grob-${lf.id}`),
          };
        });
        const pIds = leafNodes.flatMap((n) => n.elementIds);
        return {
          id: pg.id,
          label: pg.label,
          subtitle: `${leaves.length} leaves`,
          icon: "frame",
          elementIds: pIds,
          recordCount: countRecordsForElements(bundle, pIds),
          defaultExpanded: true,
          children: leafNodes,
        };
      })
      .filter((n): n is OutlineNode => n !== null);

    return [
      {
        id: "grob:root",
        label: `Figure · ${figureTitle}`,
        subtitle: `${bundle.engine ?? "svg"} · ${bundle.substrate.leaves.length} leaves`,
        icon: "figure",
        elementIds: allElementIds,
        recordCount: bundle.records.length,
        defaultExpanded: true,
        children,
      },
    ];
  }

  if (mode === "data") {
    const crossPanelGroups = inferDataGroups(bundle);
    const groupNodes: OutlineNode[] = crossPanelGroups.map((g) => ({
      id: `data:group:${g.key}`,
      label: g.label,
      subtitle: `${g.elementIds.length} marks across panels`,
      icon: "group",
      swatch: g.swatch,
      elementIds: g.elementIds,
      recordCount: countRecordsForElements(bundle, g.elementIds),
      stageHint: "analytical",
      defaultExpanded: false,
      children: buildEntityChildren(bundle, g.elementIds, `dg-${g.key}`),
    }));

    const panelNodes: OutlineNode[] = bundle.substrate.panels.map((p) => {
      const pBound = allBoundIds.filter((eid) => bundle.index.elementById.get(eid)?.panel === p.id);
      const subGroups = inferDataGroups(bundle, new Set(pBound));
      return {
        id: `data:panel:${p.id}`,
        label: `Panel · ${p.key ?? p.id}`,
        subtitle: `${pBound.length} data marks`,
        icon: "frame",
        elementIds: pBound,
        recordCount: countRecordsForElements(bundle, pBound),
        stageHint: "binding",
        defaultExpanded: true,
        children: subGroups.map((sg) => ({
          id: `data:panel:${p.id}:g:${sg.key}`,
          label: sg.label,
          subtitle: `${sg.elementIds.length} marks`,
          icon: "group",
          swatch: sg.swatch,
          elementIds: sg.elementIds,
          recordCount: countRecordsForElements(bundle, sg.elementIds),
          stageHint: "analytical",
          children: buildEntityChildren(bundle, sg.elementIds, `dpg-${p.id}-${sg.key}`),
        })),
      };
    });

    return [
      {
        id: "data:all",
        label: "All Bound Data Marks",
        subtitle: `${allBoundIds.length} verified/bound`,
        icon: "data",
        elementIds: allBoundIds,
        recordCount: countRecordsForElements(bundle, allBoundIds),
        defaultExpanded: true,
        children: [
          ...(groupNodes.length > 0
            ? [
                {
                  id: "data:by-group",
                  label: "By Data Group (Cross-Panel)",
                  subtitle: `${groupNodes.length} groups`,
                  icon: "group" as const,
                  elementIds: allBoundIds,
                  recordCount: countRecordsForElements(bundle, allBoundIds),
                  defaultExpanded: true,
                  children: groupNodes,
                },
              ]
            : []),
          ...(panelNodes.length > 0
            ? [
                {
                  id: "data:by-panel",
                  label: "By Facet Panel",
                  subtitle: `${panelNodes.length} panels`,
                  icon: "frame" as const,
                  elementIds: allBoundIds,
                  recordCount: countRecordsForElements(bundle, allBoundIds),
                  defaultExpanded: true,
                  children: panelNodes,
                },
              ]
            : []),
        ],
      },
    ];
  }

  // Default: `semantic` Figma/BioRender-style Outline
  const topChildren: OutlineNode[] = [];

  // 1. Data Layers (organized by panel + inferred data groups!)
  if (allBoundIds.length > 0) {
    const dataChildren: OutlineNode[] = [];
    if (bundle.substrate.panels.length > 1) {
      for (const p of bundle.substrate.panels) {
        const pBound = allBoundIds.filter((eid) => bundle.index.elementById.get(eid)?.panel === p.id);
        const subGroups = inferDataGroups(bundle, new Set(pBound));
        dataChildren.push({
          id: `sem:panel:${p.id}`,
          label: `Panel · ${p.key ?? p.id}`,
          subtitle: `${pBound.length} marks`,
          icon: "frame",
          elementIds: pBound,
          recordCount: countRecordsForElements(bundle, pBound),
          stageHint: "binding",
          defaultExpanded: true,
          children: subGroups.map((sg) => ({
            id: `sem:panel:${p.id}:g:${sg.key}`,
            label: sg.label,
            subtitle: `${sg.elementIds.length} marks`,
            icon: "group",
            swatch: sg.swatch,
            elementIds: sg.elementIds,
            recordCount: countRecordsForElements(bundle, sg.elementIds),
            stageHint: "analytical",
            children: buildEntityChildren(bundle, sg.elementIds, `spg-${p.id}-${sg.key}`),
          })),
        });
      }
    } else {
      const groups = inferDataGroups(bundle);
      for (const g of groups) {
        dataChildren.push({
          id: `sem:g:${g.key}`,
          label: g.label,
          subtitle: `${g.elementIds.length} marks`,
          icon: "group",
          swatch: g.swatch,
          elementIds: g.elementIds,
          recordCount: countRecordsForElements(bundle, g.elementIds),
          stageHint: "analytical",
          children: buildEntityChildren(bundle, g.elementIds, `sg-${g.key}`),
        });
      }
    }

    topChildren.push({
      id: "root:data",
      label: "Data Layer",
      subtitle: `${allBoundIds.length} bound marks`,
      icon: "data",
      elementIds: allBoundIds,
      recordCount: countRecordsForElements(bundle, allBoundIds),
      stageHint: "binding",
      defaultExpanded: true,
      children: dataChildren,
    });
  }

  // 2. Natural-Language Semantics (Claims + Exceptions + Contextual + Relations + Narrative + Behavior)
  const semBranch = buildSemanticRecordsBranch(bundle);
  if (semBranch) topChildren.push(semBranch);

  // 3. Typography & Guides (Title, Subtitle, Legend, Axes, Gridlines)
  const chromeBranch = buildTypographyAndGuidesBranch(bundle);
  if (chromeBranch) topChildren.push(chromeBranch);

  return [
    {
      id: "root:figure",
      label: figureTitle,
      subtitle: `${bundle.engine ?? "svg"} · ${bundle.substrate.elements.length} elements`,
      icon: "figure",
      elementIds: allElementIds,
      recordCount: bundle.records.length,
      hasWarning: topChildren.some((c) => c.hasWarning),
      defaultExpanded: true,
      children: topChildren,
    },
  ];
}

/**
 * Resolve a natural-language focus query (e.g. "cyl 6", "exception", "Mazda", "legend", "am=1")
 * across outline nodes, data groups, entities, and semantic records.
 */
export function resolveNaturalFocus(bundle: GlossBundle, rawQuery: string): FocusScope | null {
  const q = rawQuery.trim().toLowerCase();
  if (!q) return null;

  const semanticTree = buildOutlineTree(bundle, "semantic");
  const dataTree = buildOutlineTree(bundle, "data");

  const flatten = (nodes: OutlineNode[]): OutlineNode[] =>
    nodes.flatMap((n) => [n, ...flatten(n.children)]);

  const allNodes = [...flatten(dataTree), ...flatten(semanticTree)];

  // 1. Prefer exact or strong semantic/data group label match (e.g. "cyl = 6", "exception", "legend", "title")
  const tokens = q.split(/\s+/).filter(Boolean);
  const scored = allNodes
    .filter((n) => n.elementIds.length > 0 && n.id !== "root:figure" && n.id !== "data:all")
    .map((n) => {
      const lbl = n.label.toLowerCase();
      const hay = `${lbl} ${(n.subtitle ?? "").toLowerCase()}`;
      let score = 0;
      if (lbl === q) score += 140;
      else if (lbl.includes(q)) score += 95;
      else if (tokens.every((t) => lbl.includes(t))) score += 80;
      else if (hay.includes(q)) score += 50;
      else if (tokens.every((t) => hay.includes(t))) score += 35;

      if (score > 0) {
        // Prefer cross-panel data groups when querying a data group (e.g. "cyl 6")
        if (n.id.startsWith("data:group:")) score += 12;
        if (n.icon === "exception") score += 10;
        score += Math.max(0, 10 - Math.log2(n.elementIds.length + 1));
      }
      return { node: n, score };
    })
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score);

  if (scored.length > 0) {
    const best = scored[0].node;
    return {
      id: best.id,
      label: best.label,
      kind: best.icon,
      elementIds: best.elementIds,
      recordId: best.recordId,
      swatch: best.swatch,
      isException: best.icon === "exception",
    };
  }

  // 2. Fallback: search raw entities & element IDs directly
  const matchedEls: string[] = [];
  for (const el of bundle.substrate.elements) {
    const raw = bundle.index.inferredRawByElement.get(el.id);
    const hay = `${el.id} ${el.text ?? ""} ${raw?.rawKeyLabels.join(" ") ?? ""}`.toLowerCase();
    if (tokens.every((t) => hay.includes(t))) matchedEls.push(el.id);
  }
  if (matchedEls.length > 0) {
    return {
      id: `nl:${q}`,
      label: `"${rawQuery.trim()}" (${matchedEls.length})`,
      kind: "point",
      elementIds: matchedEls,
    };
  }

  return null;
}
