import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  ChevronLeft,
  ChevronRight,
  Columns2,
  Crosshair,
  Eye,
  Hand,
  Maximize2,
  MousePointerClick,
  RotateCcw,
  ScanSearch,
  Sparkles,
  ZoomIn,
  ZoomOut,
} from "lucide-react";
import {
  buildOutlineTree,
  formatReaderTooltip,
  humanizeToken,
  SEMANTIC_STAGES,
  svgPointToData,
  type GlossElement,
  type SemanticStageId,
} from "../../codec";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";

function stageIndex(id: SemanticStageId): number {
  return SEMANTIC_STAGES.findIndex((s) => s.id === id);
}

/**
 * Mount the original svglite SVG DOM untouched (Principle 1), stripping any script/on* handlers
 * (Safety invariant) without modifying geometry or data-gloss-* attributes.
 */
function sanitizeOriginalSvg(svgString: string): SVGSVGElement | null {
  const parser = new DOMParser();
  const doc = parser.parseFromString(svgString, "image/svg+xml");
  const svg = doc.querySelector("svg");
  if (!svg) return null;

  svg.querySelectorAll("script, foreignObject").forEach((n) => n.remove());
  const all = svg.querySelectorAll("*");
  for (let i = 0; i < all.length; i += 1) {
    const el = all[i];
    const attrs = Array.from(el.attributes);
    for (const a of attrs) {
      if (a.name.toLowerCase().startsWith("on")) {
        el.removeAttribute(a.name);
      }
    }
  }
  svg.setAttribute("width", "100%");
  svg.setAttribute("height", "100%");
  svg.style.display = "block";
  svg.style.userSelect = "none";
  return svg;
}

function elementCenter(el: GlossElement): { x: number; y: number } {
  return { x: (el.x0 + el.x1) / 2, y: (el.y0 + el.y1) / 2 };
}

export const FigureStage: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const spatial = useWorkbenchStore((s) => s.spatial);
  const viewMode = useWorkbenchStore((s) => s.viewMode);
  const readerLens = useWorkbenchStore((s) => s.readerLens);
  const storyStepIdx = useWorkbenchStore((s) => s.storyStepIdx);
  const activeStage = useWorkbenchStore((s) => s.activeStage);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const hoveredElementId = useWorkbenchStore((s) => s.hoveredElementId);
  const focusScope = useWorkbenchStore((s) => s.focusScope);
  const zoomRequestCounter = useWorkbenchStore((s) => s.zoomRequestCounter);
  const highlightedGroup = useWorkbenchStore((s) => s.highlightedGroup);
  const gridFilterElementIds = useWorkbenchStore((s) => s.gridFilterElementIds);
  const splitCompare = useWorkbenchStore((s) => s.splitCompare);
  const splitRatio = useWorkbenchStore((s) => s.splitRatio);
  const hiddenLeafIds = useWorkbenchStore((s) => s.hiddenLeafIds);
  const hiddenElementIds = useWorkbenchStore((s) => s.hiddenElementIds);

  const selectElement = useWorkbenchStore((s) => s.selectElement);
  const setHoveredElement = useWorkbenchStore((s) => s.setHoveredElement);
  const setFocusScope = useWorkbenchStore((s) => s.setFocusScope);
  const requestZoomToFocus = useWorkbenchStore((s) => s.requestZoomToFocus);
  const setReaderLens = useWorkbenchStore((s) => s.setReaderLens);
  const setStoryStepIdx = useWorkbenchStore((s) => s.setStoryStepIdx);
  const setSplitCompare = useWorkbenchStore((s) => s.setSplitCompare);
  const setSplitRatio = useWorkbenchStore((s) => s.setSplitRatio);
  const clearSelection = useWorkbenchStore((s) => s.clearSelection);

  const containerRef = useRef<HTMLDivElement>(null);
  const svgHostRef = useRef<HTMLDivElement>(null);
  const [zoom, setZoom] = useState(1);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [isPanning, setIsPanning] = useState(false);
  const panStartRef = useRef({ x: 0, y: 0, panX: 0, panY: 0 });
  const [cursorSvg, setCursorSvg] = useState<{ x: number; y: number } | null>(null);
  const [draggingSplit, setDraggingSplit] = useState(false);

  const isReader = viewMode === "reader";
  const curStageIdx = stageIndex(activeStage);
  const isPureFigure = isReader ? readerLens === "figure" : curStageIdx === 0;

  // Mount original SVG verbatim whenever bundle changes
  useEffect(() => {
    const host = svgHostRef.current;
    if (!host || !bundle) return;
    host.replaceChildren();
    const cleanSvg = sanitizeOriginalSvg(bundle.substrate.sceneSvg);
    if (cleanSvg) {
      host.appendChild(document.importNode(cleanSvg, true));
    }
    setZoom(1);
    setPan({ x: 0, y: 0 });
  }, [bundle]);

  // Precompute cross-panel data groups so clicking a Legend item in the SVG filters that group interactively!
  const dataGroups = useMemo(() => {
    if (!bundle) return [];
    const dt = buildOutlineTree(bundle, "data");
    const byGroup = dt[0]?.children.find((c) => c.id === "data:by-group");
    return byGroup?.children ?? [];
  }, [bundle]);

  // Precompute narrative stops for interactive Story walkthrough
  const narrativeStops = useMemo(() => {
    if (!bundle) return [];
    return bundle.records
      .filter((r) => r.layer === "narrative" && r.resolvedTargets.length > 0)
      .sort((a, b) => Number(a.body.order ?? 99) - Number(b.body.order ?? 99))
      .map((r, idx) => ({
        order: Number(r.body.order ?? idx + 1),
        record: r,
        element: bundle.index.elementById.get(r.resolvedTargets[0]) ?? null,
      }))
      .filter((s): s is { order: number; record: typeof s.record; element: GlossElement } =>
        Boolean(s.element)
      );
  }, [bundle]);

  // Sync story step selection when user enters Story lens or steps Prev/Next
  const activeStoryStop =
    isReader && readerLens === "story" && narrativeStops.length > 0
      ? narrativeStops[Math.min(storyStepIdx, narrativeStops.length - 1)]
      : null;

  useEffect(() => {
    if (activeStoryStop) {
      selectElement(activeStoryStop.element.id);
    }
  }, [activeStoryStop, selectElement]);

  // Apply non-destructive visibility toggles + Focus / Grid Sync spotlighting on original SVG nodes
  useEffect(() => {
    const host = svgHostRef.current;
    if (!host || !bundle) return;
    const activeSubset =
      focusScope?.elementIds ?? highlightedGroup?.elementIds ?? gridFilterElementIds ?? null;
    const subsetSet = activeSubset ? new Set(activeSubset) : null;
    const hiddenLeafSet = new Set(hiddenLeafIds);
    const hiddenElSet = new Set(hiddenElementIds);

    const focusingNonData =
      subsetSet !== null &&
      Array.from(subsetSet).some((id) => !bundle.index.bindingByElement.has(id));

    const nodes = host.querySelectorAll<SVGElement>("[data-gloss-element]");
    nodes.forEach((node) => {
      const id = node.getAttribute("data-gloss-element") ?? "";
      const el = bundle.index.elementById.get(id);
      if (hiddenElSet.has(id) || (el?.leaf && hiddenLeafSet.has(el.leaf))) {
        node.style.opacity = "0.05";
        return;
      }
      if (!subsetSet || isPureFigure) {
        node.style.opacity = "";
        return;
      }
      const isBound = bundle.index.bindingByElement.has(id);
      if (!el?.leaf) {
        node.style.opacity = "";
        return;
      }
      if (subsetSet.has(id)) {
        node.style.opacity = "1";
      } else if (focusingNonData) {
        node.style.opacity = "0.14";
      } else if (isBound) {
        node.style.opacity = "0.14";
      } else {
        node.style.opacity = focusScope ? "0.48" : "";
      }
    });
  }, [
    bundle,
    focusScope,
    highlightedGroup,
    gridFilterElementIds,
    hiddenLeafIds,
    hiddenElementIds,
    isPureFigure,
  ]);

  // Smooth Zoom-to-Focus when triggered
  useEffect(() => {
    if (zoomRequestCounter === 0 || !bundle || !focusScope || !svgHostRef.current) return;
    const els = focusScope.elementIds
      .map((id) => bundle.index.elementById.get(id))
      .filter((e): e is GlossElement => Boolean(e));
    if (els.length === 0) return;

    const vb = bundle.substrate.viewBox;
    const minX = Math.min(...els.map((e) => Math.min(e.x0, e.x1)));
    const minY = Math.min(...els.map((e) => Math.min(e.y0, e.y1)));
    const maxX = Math.max(...els.map((e) => Math.max(e.x0, e.x1)));
    const maxY = Math.max(...els.map((e) => Math.max(e.y0, e.y1)));

    const boxW = Math.max(48, maxX - minX + 44);
    const boxH = Math.max(40, maxY - minY + 44);
    const targetZoom = Math.max(
      1.05,
      Math.min(3.4, Math.min(vb.width / boxW, vb.height / boxH) * 0.78)
    );

    const rect = svgHostRef.current.getBoundingClientRect();
    const baseW = rect.width / Math.max(0.1, zoom);
    const baseH = rect.height / Math.max(0.1, zoom);
    const cxFrac = ((minX + maxX) / 2 - vb.x) / vb.width - 0.5;
    const cyFrac = ((minY + maxY) / 2 - vb.y) / vb.height - 0.5;

    setZoom(+targetZoom.toFixed(2));
    setPan({
      x: Math.round(-cxFrac * baseW * targetZoom),
      y: Math.round(-cyFrac * baseH * targetZoom),
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [zoomRequestCounter]);

  // Expose live `window.gloss` API
  useEffect(() => {
    if (!bundle) return;
    const win = window as unknown as Record<string, unknown>;
    win.gloss = {
      version: bundle.glossVersion ?? "0.1.0",
      mode: "workbench",
      substrateId: bundle.substrateId,
      elements: () => bundle.substrate.elements,
      bindings: () => bundle.derived.bindingsElements,
      records: () => bundle.records,
      operations: bundle.operations.specs,
      select: (ids: string | string[]) =>
        selectElement(Array.isArray(ids) ? ids[0] ?? null : ids),
      setStage: (stage: SemanticStageId) => useWorkbenchStore.getState().setActiveStage(stage),
    };
  }, [bundle, selectElement]);

  const dataReadout = useMemo(() => {
    if (!bundle || !cursorSvg) return null;
    return svgPointToData(bundle, cursorSvg.x, cursorSvg.y);
  }, [bundle, cursorSvg]);

  // Build relation edges (only revealed interactively when hovered/selected, or in Inspector Relation stage!)
  const relationArcs = useMemo(() => {
    if (!bundle) return [];
    const arcs: Array<{
      from: GlossElement;
      to: GlossElement;
      label: string;
      verified: boolean;
      pairKey: string;
      pairIndex: number;
    }> = [];
    const pairCounts = new Map<string, number>();
    const addArc = (from: GlossElement, to: GlossElement, label: string, verified: boolean) => {
      const pairKey = [from.id, to.id].sort().join("--");
      const pairIndex = pairCounts.get(pairKey) ?? 0;
      pairCounts.set(pairKey, pairIndex + 1);
      arcs.push({ from, to, label: humanizeToken(label), verified, pairKey, pairIndex });
    };
    for (const lk of bundle.operations.state.links) {
      const a = bundle.index.elementById.get(lk.from);
      const b = bundle.index.elementById.get(lk.to);
      if (a && b) addArc(a, b, lk.relation, true);
    }
    for (const rec of bundle.records) {
      if (rec.layer === "relation" && rec.resolvedTargets.length >= 2) {
        const a = bundle.index.elementById.get(rec.resolvedTargets[0]);
        const b = bundle.index.elementById.get(rec.resolvedTargets[1]);
        if (a && b) {
          addArc(
            a,
            b,
            rec.body.type ?? rec.body.text ?? "Comparison",
            rec.projectionStatus === "verified"
          );
        }
      }
    }
    return arcs;
  }, [bundle]);

  // Interactive cue points: marks that have attached semantic notes, links, or tooltips
  const interactiveCueIds = useMemo(() => {
    if (!bundle) return [] as string[];
    const set = new Set<string>();
    for (const r of bundle.records) {
      for (const id of r.resolvedTargets) set.add(id);
    }
    for (const op of bundle.operations.specs) {
      for (const id of op.targets) set.add(id);
    }
    return Array.from(set).filter((id) => bundle.index.bindingByElement.has(id));
  }, [bundle]);

  const ambientBindings = useMemo(
    () => (bundle ? bundle.derived.bindingsElements.slice(0, 600) : []),
    [bundle]
  );

  const contextualRecords = useMemo(
    () =>
      bundle
        ? bundle.records.filter((r) => r.workbenchStage === "contextual" && r.resolvedTargets.length > 0)
        : [],
    [bundle]
  );

  if (!bundle) return null;

  const { viewBox } = bundle.substrate;
  const aspectRatio = viewBox.width / Math.max(1, viewBox.height);

  const clientToSvgCoords = (clientX: number, clientY: number): { x: number; y: number } | null => {
    const host = svgHostRef.current;
    if (!host) return null;
    const rect = host.getBoundingClientRect();
    if (rect.width <= 0 || rect.height <= 0) return null;
    const x = viewBox.x + ((clientX - rect.left) / rect.width) * viewBox.width;
    const y = viewBox.y + ((clientY - rect.top) / rect.height) * viewBox.height;
    return { x, y };
  };

  /**
   * Match an SVG legend item (colour swatch or label text) to a cross-panel data group
   * so hovering guides the user and clicking filters that group interactively.
   */
  const matchLegendGroup = (hit: GlossElement) => {
    const lf = hit.leaf ? bundle.index.leafById.get(hit.leaf) : undefined;
    const role = bundle.index.roleByElement.get(hit.id);
    const lp = `${lf?.path ?? ""} ${lf?.name ?? ""}`.toLowerCase();
    const isLegendEl =
      lp.includes("guide-box") ||
      lp.includes("legend") ||
      (role?.kind ?? "").toLowerCase().includes("legend");
    if (!isLegendEl || dataGroups.length === 0) return null;

    const color = (hit.fill ?? hit.stroke ?? "").toLowerCase();
    const txt = (hit.text ?? "").trim().toLowerCase();

    return (
      dataGroups.find((g) => {
        if (color && g.swatch && g.swatch.toLowerCase() === color) return true;
        if (txt) {
          const rhs = g.label.split("=").pop()?.trim().toLowerCase();
          if (rhs && rhs === txt) return true;
        }
        return false;
      }) ?? null
    );
  };

  const tryHandleLegendClick = (hit: GlossElement): boolean => {
    const matchedGroup = matchLegendGroup(hit);
    if (!matchedGroup) return false;
    if (focusScope?.id === matchedGroup.id) {
      setFocusScope(null);
    } else {
      setFocusScope({
        id: matchedGroup.id,
        label: matchedGroup.label,
        kind: "group",
        swatch: matchedGroup.swatch,
        elementIds: matchedGroup.elementIds,
      });
    }
    return true;
  };

  const handleStageMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (draggingSplit && svgHostRef.current) {
      const rect = svgHostRef.current.getBoundingClientRect();
      setSplitRatio((e.clientX - rect.left) / Math.max(1, rect.width));
      return;
    }
    if (isPanning) {
      setPan({
        x: panStartRef.current.panX + (e.clientX - panStartRef.current.x),
        y: panStartRef.current.panY + (e.clientY - panStartRef.current.y),
      });
      return;
    }
    const pt = clientToSvgCoords(e.clientX, e.clientY);
    if (!pt) return;
    setCursorSvg(pt);
    if (isPureFigure || !spatial) {
      setHoveredElement(null);
      return;
    }
    const hit = spatial.hitTest(pt.x, pt.y, Math.max(3, 6 / zoom));
    setHoveredElement(hit?.id ?? null);
  };

  const handleStageClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (isPanning || draggingSplit || isPureFigure) return;
    const pt = clientToSvgCoords(e.clientX, e.clientY);
    if (!pt || !spatial) return;
    const hit = spatial.hitTest(pt.x, pt.y, Math.max(3, 6 / zoom));
    if (hit) {
      if (tryHandleLegendClick(hit)) return;
      selectElement(hit.id, e.shiftKey || e.metaKey);
    } else {
      clearSelection();
    }
  };

  const handleWheel = (e: React.WheelEvent<HTMLDivElement>) => {
    if (!e.ctrlKey && !e.metaKey) return;
    e.preventDefault();
    const factor = e.deltaY < 0 ? 1.12 : 0.89;
    setZoom((z) => Math.max(0.4, Math.min(8, +(z * factor).toFixed(3))));
  };

  const hoveredEl = hoveredElementId ? bundle.index.elementById.get(hoveredElementId) ?? null : null;
  const hoveredBinding = hoveredElementId
    ? bundle.index.bindingByElement.get(hoveredElementId) ?? null
    : null;
  const hoveredRaw = hoveredElementId
    ? bundle.index.inferredRawByElement.get(hoveredElementId) ?? null
    : null;
  const hoveredRole = hoveredElementId
    ? bundle.index.roleByElement.get(hoveredElementId) ?? null
    : null;
  const hoveredTooltip = hoveredElementId
    ? bundle.operations.state.tooltips[hoveredElementId] ?? null
    : null;
  const hoveredLegendGroup = hoveredEl ? matchLegendGroup(hoveredEl) : null;
  const hoveredReaderTip = hoveredEl ? formatReaderTooltip(bundle, hoveredEl) : null;

  const activeFocusIds = new Set([
    ...selectedElementIds,
    ...(hoveredElementId ? [hoveredElementId] : []),
  ]);

  // Decide WHICH overlays appear — interaction-driven and completely uncluttered in Reader mode!
  const showStructureFrames = !isReader && curStageIdx >= 1;
  const showAmbientBindingRings = !isReader && curStageIdx === 2;

  // Relations: in Inspector Relation stage show all; otherwise reveal dynamically on hover/selection
  // (and deduplicate per pair in Reader mode so at most one graceful comparison arc appears).
  const seenReaderPairs = new Set<string>();
  const visibleRelationArcs = relationArcs.filter((arc) => {
    if (isPureFigure) return false;
    if (!isReader && curStageIdx === 5) return true;
    if (isReader && readerLens === "story") return false;
    const touchesFocus = activeFocusIds.has(arc.from.id) || activeFocusIds.has(arc.to.id);
    if (!touchesFocus) return false;
    if (isReader) {
      if (seenReaderPairs.has(arc.pairKey)) return false;
      seenReaderPairs.add(arc.pairKey);
    }
    return true;
  });

  // Contextual pins & behavior leader callouts: rendered in Inspector mode for full auditability,
  // while Reader mode delivers the exact same context & findings through hover tooltips and the
  // calm right-hand ReaderInspector instead of stamping text boxes over the figure!
  const visibleContextualRecords = contextualRecords.filter((rec) => {
    if (isPureFigure || isReader) return false;
    if (curStageIdx === 4) return true;
    const tid = rec.resolvedTargets[0];
    return activeFocusIds.has(tid);
  });

  const visibleBehaviorOverlays = bundle.operations.state.overlays.filter((ov) => {
    if (isPureFigure || isReader) return false;
    if (curStageIdx < 8) return false;
    return ov.targets.some((id) => activeFocusIds.has(id));
  });

  // Quiet interactive cue dots: gently guide the user toward points that have rich notes/relations/behaviors
  const showInteractiveCues =
    !isPureFigure &&
    !(isReader && readerLens === "story") &&
    (isReader ? readerLens === "explore" || readerLens === "findings" : curStageIdx >= 8);

  const selectedElements = selectedElementIds
    .map((id) => bundle.index.elementById.get(id))
    .filter((e): e is GlossElement => Boolean(e));

  const overlayClipPath =
    !isReader && splitCompare ? `inset(0 0 0 ${(splitRatio * 100).toFixed(2)}%)` : undefined;

  return (
    <div
      className="relative flex h-full w-full flex-col overflow-hidden"
      style={{ background: "var(--bg-canvas)" }}
    >
      {/* Calm Stage Toolbar */}
      <div
        className="flex items-center justify-between gap-2 border-b px-3 py-1.5 text-xs"
        style={{
          background: "var(--bg-surface)",
          borderColor: "var(--border-subtle)",
        }}
      >
        <div className="flex min-w-0 items-center gap-2">
          {!isReader && (
            <>
              <span className="font-semibold" style={{ color: "var(--ink-primary)" }}>
                {SEMANTIC_STAGES[curStageIdx]?.label}
              </span>
              <span className="hidden text-[11px] sm:inline" style={{ color: "var(--ink-muted)" }}>
                · {SEMANTIC_STAGES[curStageIdx]?.zhLabel}
              </span>
            </>
          )}

          {isReader && !focusScope && (
            <span className="inline-flex items-center gap-1.5 text-[11.5px]" style={{ color: "var(--ink-secondary)" }}>
              <Hand className="h-3.5 w-3.5" style={{ color: "var(--st-focus)" }} />
              {readerLens === "figure"
                ? "Original published figure (overlays off)"
                : readerLens === "story"
                  ? `Guided reading walkthrough (${narrativeStops.length} steps)`
                  : "Hover points · Click legend to filter · Click ringed points for notes"}
            </span>
          )}

          {bundle.sourceKind === "plain-svg" && (
            <span
              className="rounded-full px-2 py-0.5 text-[10px] font-semibold"
              style={{ background: "var(--st-warn-soft)", color: "var(--st-warn)" }}
            >
              Geometry Only
            </span>
          )}

          {focusScope && (
            <div
              className="inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-[11px] font-semibold"
              style={{
                borderColor: focusScope.isException ? "var(--st-warn)" : "var(--st-focus)",
                background: focusScope.isException ? "var(--st-warn-soft)" : "var(--st-focus-soft)",
                color: focusScope.isException ? "var(--st-warn)" : "var(--st-focus)",
              }}
            >
              {focusScope.swatch ? (
                <span className="h-2 w-2 rounded-full" style={{ background: focusScope.swatch }} />
              ) : (
                <Crosshair className="h-3 w-3" />
              )}
              <span className="max-w-[200px] truncate">
                Focus: {focusScope.label} ({focusScope.elementIds.length})
              </span>
              <button
                type="button"
                onClick={requestZoomToFocus}
                title="Zoom & center viewport on focused scope"
                className="ml-0.5 rounded px-1 hover:bg-black/10"
              >
                <ScanSearch className="h-3 w-3" />
              </button>
              <button
                type="button"
                onClick={() => {
                  setFocusScope(null);
                  setZoom(1);
                  setPan({ x: 0, y: 0 });
                }}
                title="Exit focus (Esc)"
                className="rounded px-1 hover:bg-black/10"
              >
                ×
              </button>
            </div>
          )}

          {!focusScope && gridFilterElementIds && (
            <button
              type="button"
              onClick={() => useWorkbenchStore.getState().setGridFilterElementIds(null)}
              className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10.5px] font-semibold"
              style={{ background: "var(--st-focus-soft)", color: "var(--st-focus)" }}
            >
              Table filter ({gridFilterElementIds.length}) ×
            </button>
          )}
        </div>

        <div className="flex shrink-0 items-center gap-1">
          {!isReader && (
            <>
              <button
                type="button"
                onClick={() => setSplitCompare(!splitCompare)}
                disabled={curStageIdx === 0}
                title="Compare Raw SVG (left) vs current semantic stage (right)"
                className="inline-flex items-center gap-1 rounded-md border px-2 py-1 text-[11px] font-medium transition-colors disabled:opacity-40"
                style={{
                  borderColor: splitCompare ? "var(--st-focus)" : "var(--border-subtle)",
                  background: splitCompare ? "var(--st-focus-soft)" : "transparent",
                  color: splitCompare ? "var(--st-focus)" : "var(--ink-secondary)",
                }}
              >
                <Columns2 className="h-3.5 w-3.5" />
                Compare
              </button>
              <div className="mx-1 h-4 w-[1px]" style={{ background: "var(--border-subtle)" }} />
            </>
          )}

          <button
            type="button"
            onClick={() => setZoom((z) => Math.max(0.4, +(z / 1.2).toFixed(2)))}
            title="Zoom out"
            className="rounded p-1 hover:bg-[var(--bg-subtle)]"
            style={{ color: "var(--ink-secondary)" }}
          >
            <ZoomOut className="h-3.5 w-3.5" />
          </button>
          <span
            className="font-mono-num min-w-[40px] text-center text-[11px]"
            style={{ color: "var(--ink-secondary)" }}
          >
            {Math.round(zoom * 100)}%
          </span>
          <button
            type="button"
            onClick={() => setZoom((z) => Math.min(8, +(z * 1.2).toFixed(2)))}
            title="Zoom in"
            className="rounded p-1 hover:bg-[var(--bg-subtle)]"
            style={{ color: "var(--ink-secondary)" }}
          >
            <ZoomIn className="h-3.5 w-3.5" />
          </button>
          <button
            type="button"
            onClick={() => {
              setZoom(1);
              setPan({ x: 0, y: 0 });
            }}
            title="Fit figure"
            className="rounded p-1 hover:bg-[var(--bg-subtle)]"
            style={{ color: "var(--ink-secondary)" }}
          >
            <Maximize2 className="h-3.5 w-3.5" />
          </button>
          {(selectedElementIds.length > 0 || focusScope) && (
            <button
              type="button"
              onClick={() => {
                clearSelection();
                setZoom(1);
                setPan({ x: 0, y: 0 });
              }}
              title="Reset view (Esc)"
              className="rounded p-1 hover:bg-[var(--bg-subtle)]"
              style={{ color: "var(--ink-secondary)" }}
            >
              <RotateCcw className="h-3.5 w-3.5" />
            </button>
          )}
        </div>
      </div>

      {/* Main Interactive Viewport */}
      <div
        ref={containerRef}
        className={`${isReader ? "" : "stage-grid-bg"} relative flex flex-1 items-center justify-center overflow-hidden p-5`}
        style={{ cursor: isPanning ? "grabbing" : isPureFigure ? "default" : "pointer" }}
        onWheel={handleWheel}
        onMouseDown={(e) => {
          if (e.button === 1 || (e.button === 0 && e.altKey)) {
            setIsPanning(true);
            panStartRef.current = { x: e.clientX, y: e.clientY, panX: pan.x, panY: pan.y };
          }
        }}
        onMouseMove={handleStageMouseMove}
        onMouseUp={() => {
          setIsPanning(false);
          setDraggingSplit(false);
        }}
        onMouseLeave={() => {
          setIsPanning(false);
          setDraggingSplit(false);
          setHoveredElement(null);
          setCursorSvg(null);
        }}
        onClick={handleStageClick}
      >
        {/* Clean publication card hosting the untouched svglite SVG + interaction-driven overlay */}
        <div
          className="relative rounded-2xl border bg-white"
          style={{
            width: `min(94%, calc(82vh * ${aspectRatio.toFixed(4)}))`,
            aspectRatio: `${viewBox.width} / ${viewBox.height}`,
            transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
            transformOrigin: "center center",
            transition: isPanning ? "none" : "transform 200ms cubic-bezier(0.22, 1, 0.36, 1)",
            borderColor: "var(--border-subtle)",
            boxShadow: "var(--shadow-card)",
          }}
        >
          {/* Layer A: Original untouched SVG from svglite */}
          <div ref={svgHostRef} className="h-full w-full overflow-hidden rounded-2xl" />

          {/* Layer B: Non-destructive, interaction-driven overlay in exact viewBox space */}
          {!isPureFigure && (
            <svg
              viewBox={`${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`}
              className="pointer-events-none absolute inset-0 h-full w-full overflow-visible rounded-2xl"
              style={{ clipPath: overlayClipPath }}
            >
              <defs>
                <marker
                  id="gloss-arrow"
                  viewBox="0 0 10 10"
                  refX="8"
                  refY="5"
                  markerWidth="6"
                  markerHeight="6"
                  orient="auto-start-reverse"
                >
                  <path d="M 0 1 L 10 5 L 0 9 z" fill="#2563eb" />
                </marker>
              </defs>

              {/* Inspector Structure stage only: subtle panel frames */}
              {showStructureFrames &&
                bundle.substrate.panels.map((p) => (
                  <g key={p.id}>
                    <rect
                      x={Math.min(p.x0, p.x1)}
                      y={Math.min(p.y0, p.y1)}
                      width={Math.abs(p.x1 - p.x0)}
                      height={Math.abs(p.y1 - p.y0)}
                      fill="none"
                      stroke="#2563eb"
                      strokeOpacity={curStageIdx === 1 ? 0.42 : 0.12}
                      strokeWidth={0.9}
                      strokeDasharray="4 3"
                    />
                    {curStageIdx === 1 && (
                      <text
                        x={Math.min(p.x0, p.x1) + 4}
                        y={Math.min(p.y0, p.y1) + 11}
                        fontSize="8.5"
                        fontWeight="600"
                        fill="#2563eb"
                        fillOpacity="0.85"
                      >
                        {p.id} ({p.key ?? "panel"})
                      </text>
                    )}
                  </g>
                ))}

              {/* Inspector Binding stage only: ambient verified/ambiguous rings */}
              {showAmbientBindingRings &&
                ambientBindings.map((b) => {
                  const el = bundle.index.elementById.get(b.element);
                  if (!el) return null;
                  const c = elementCenter(el);
                  const r = Math.max(4.5, Math.max(el.x1 - el.x0, el.y1 - el.y0) / 2 + 2.2);
                  const stroke =
                    b.status === "verified"
                      ? "#0d9488"
                      : b.status === "ambiguous"
                        ? "#d97706"
                        : "#dc2626";
                  return (
                    <circle
                      key={`bind-${b.element}`}
                      cx={c.x}
                      cy={c.y}
                      r={r}
                      fill="none"
                      stroke={stroke}
                      strokeWidth={1.2}
                      strokeOpacity={0.68}
                    />
                  );
                })}

              {/* Whisper-quiet interactive affordance rings on annotated points (guiding user to hover/click, NOT dumping static text!) */}
              {showInteractiveCues &&
                interactiveCueIds.map((eid) => {
                  if (activeFocusIds.has(eid)) return null;
                  const el = bundle.index.elementById.get(eid);
                  if (!el) return null;
                  const c = elementCenter(el);
                  return (
                    <g key={`cue-${eid}`}>
                      <circle
                        cx={c.x}
                        cy={c.y}
                        r={6.8}
                        fill="none"
                        stroke="#2563eb"
                        strokeWidth={1.15}
                        strokeOpacity={0.55}
                        strokeDasharray="2 2"
                      />
                    </g>
                  );
                })}

              {/* Interactive contextual pin (appears on hover/selection, never statically stamped!) */}
              {visibleContextualRecords.map((rec) => {
                const el = bundle.index.elementById.get(rec.resolvedTargets[0]);
                if (!el) return null;
                const c = elementCenter(el);
                const panel = el.panel ? bundle.index.panelById.get(el.panel) : undefined;
                const hasOverlay = visibleBehaviorOverlays.some((ov) => ov.targets.includes(el.id));
                const label =
                  bundle.index.inferredRawByElement.get(el.id)?.rawKeyLabels[0] ??
                  rec.body.label ??
                  "Note";
                const pillW = Math.min(130, label.length * 5.2 + 14);
                const maxRight = panel ? Math.max(panel.x0, panel.x1) - 4 : viewBox.x + viewBox.width - 4;
                const px =
                  c.x + 10 + pillW > maxRight ? Math.max(viewBox.x + 4, c.x - pillW - 10) : c.x + 10;
                const py = hasOverlay ? c.y + 18 : c.y - 16;
                return (
                  <g key={`ctx-${rec.id}`}>
                    <circle
                      cx={c.x}
                      cy={c.y}
                      r={8}
                      fill="none"
                      stroke="#7c3aed"
                      strokeWidth={1.4}
                      strokeDasharray="3 2"
                    />
                    <g transform={`translate(${px}, ${py})`}>
                      <rect
                        x="0"
                        y="-9"
                        width={pillW}
                        height="16"
                        rx="4"
                        fill="#f5f3ff"
                        stroke="#7c3aed"
                        strokeWidth="0.9"
                      />
                      <text x="6" y="2" fontSize="8" fontWeight="600" fill="#5b21b6">
                        {label.slice(0, 22)}
                      </text>
                    </g>
                  </g>
                );
              })}

              {/* Interactive relation arc (revealed dynamically when hovering or selecting either endpoint!) */}
              {visibleRelationArcs.map((arc, idx) => {
                const p1 = elementCenter(arc.from);
                const p2 = elementCenter(arc.to);
                const mx = (p1.x + p2.x) / 2;
                const nearTop = Math.min(p1.y, p2.y) < viewBox.y + viewBox.height * 0.36;
                const bow = nearTop
                  ? 34 + arc.pairIndex * 18
                  : arc.pairIndex % 2 === 0
                    ? -(28 + arc.pairIndex * 16)
                    : 34 + (arc.pairIndex - 1) * 16;
                const my = (p1.y + p2.y) / 2 + bow;
                const txt = arc.label.length > 42 ? `${arc.label.slice(0, 41)}…` : arc.label;
                const pillW = txt.length * 4.35 + 16;
                const clampedMx = Math.max(
                  viewBox.x + pillW / 2 + 8,
                  Math.min(viewBox.x + viewBox.width - pillW / 2 - 8, mx)
                );
                const labelY = bow < 0 ? my - 6 : my + 12;
                return (
                  <g key={`rel-${idx}`}>
                    <path
                      d={`M ${p1.x} ${p1.y} Q ${mx} ${my} ${p2.x} ${p2.y}`}
                      fill="none"
                      stroke={arc.verified ? "#2563eb" : "#d97706"}
                      strokeWidth={1.5}
                      strokeDasharray={arc.verified ? undefined : "4 3"}
                      markerEnd="url(#gloss-arrow)"
                    />
                    <rect
                      x={clampedMx - pillW / 2}
                      y={labelY - 10}
                      width={pillW}
                      height="13.5"
                      rx="4"
                      fill="#ffffff"
                      fillOpacity="0.96"
                      stroke={arc.verified ? "#93c5fd" : "#fcd34d"}
                      strokeWidth="0.8"
                    />
                    <text
                      x={clampedMx}
                      y={labelY - 1}
                      textAnchor="middle"
                      fontSize="7.5"
                      fontWeight="600"
                      fill={arc.verified ? "#1d4ed8" : "#b45309"}
                    >
                      {txt}
                    </text>
                  </g>
                );
              })}

              {/* Exception / Check Group pulsing amber halos */}
              {highlightedGroup?.elementIds.map((eid) => {
                const el = bundle.index.elementById.get(eid);
                if (!el) return null;
                const c = elementCenter(el);
                return (
                  <circle
                    key={`grp-${eid}`}
                    cx={c.x}
                    cy={c.y}
                    r={9.5}
                    fill="#fef3c7"
                    fillOpacity="0.35"
                    stroke="#d97706"
                    strokeWidth={2}
                    className="gloss-pulse"
                  />
                );
              })}

              {/* Story Walkthrough: in Reader Story lens highlight ONE active step cleanly; in Inspector Narrative stage show full numbered path */}
              {isReader && readerLens === "story" && activeStoryStop && (() => {
                const c = elementCenter(activeStoryStop.element);
                return (
                  <g>
                    <circle
                      cx={c.x}
                      cy={c.y}
                      r={11}
                      fill="#2563eb"
                      fillOpacity="0.14"
                      stroke="#2563eb"
                      strokeWidth="2"
                      className="gloss-pulse"
                    />
                    <g transform={`translate(${c.x - 13}, ${c.y - 13})`}>
                      <circle cx="0" cy="0" r="8" fill="#2563eb" />
                      <text x="0" y="3" textAnchor="middle" fontSize="9" fontWeight="700" fill="#ffffff">
                        {activeStoryStop.order}
                      </text>
                    </g>
                  </g>
                );
              })()}

              {!isReader && curStageIdx === 7 && narrativeStops.length > 0 && (
                <g>
                  {narrativeStops.length > 1 && (
                    <polyline
                      points={narrativeStops
                        .map((s) => {
                          const c = elementCenter(s.element);
                          return `${c.x},${c.y}`;
                        })
                        .join(" ")}
                      fill="none"
                      stroke="#2563eb"
                      strokeWidth="1.2"
                      strokeDasharray="3 3"
                      strokeOpacity="0.65"
                    />
                  )}
                  {narrativeStops.map((s) => {
                    const c = elementCenter(s.element);
                    return (
                      <g key={`nar-${s.record.id}`} transform={`translate(${c.x - 12}, ${c.y - 12})`}>
                        <circle cx="0" cy="0" r="7.5" fill="#2563eb" />
                        <text x="0" y="3" textAnchor="middle" fontSize="8.5" fontWeight="700" fill="#ffffff">
                          {s.order}
                        </text>
                      </g>
                    );
                  })}
                </g>
              )}

              {/* Interactive checked leader callout (appears dynamically when user hovers/selects the anchored point!) */}
              {visibleBehaviorOverlays.map((ov, idx) => {
                const els = ov.targets
                  .map((id) => bundle.index.elementById.get(id))
                  .filter((e): e is GlossElement => Boolean(e));
                if (els.length === 0) return null;
                const minX = Math.min(...els.map((e) => e.x0));
                const minY = Math.min(...els.map((e) => e.y0));
                const maxX = Math.max(...els.map((e) => e.x1));
                const maxY = Math.max(...els.map((e) => e.y1));
                const cx = (minX + maxX) / 2;
                const cy = (minY + maxY) / 2;
                const color =
                  ov.status === "verified"
                    ? "#0d9488"
                    : ov.status === "speculative"
                      ? "#64748b"
                      : "#2563eb";
                const bg = ov.status === "verified" ? "#f0fdfa" : "#f8fafc";
                const panel = els[0].panel ? bundle.index.panelById.get(els[0].panel) : undefined;
                const panelRight = panel ? Math.max(panel.x0, panel.x1) - 4 : viewBox.x + viewBox.width - 6;
                const panelLeft = panel ? Math.min(panel.x0, panel.x1) + 4 : viewBox.x + 6;
                const labelW = Math.min(185, Math.max(85, ov.text.length * 4.5 + 16));
                const tx =
                  cx + 16 + labelW <= panelRight
                    ? cx + 16
                    : Math.max(panelLeft, Math.min(panelRight - labelW, cx - labelW - 14));
                const ty = Math.max(viewBox.y + 18, cy - 30);

                return (
                  <g key={`ov-${idx}`}>
                    <circle cx={cx} cy={cy} r="7" fill="none" stroke={color} strokeWidth="1.6" />
                    <line
                      x1={cx}
                      y1={cy}
                      x2={tx < cx ? tx + labelW : tx}
                      y2={ty + 8}
                      stroke={color}
                      strokeWidth="1.15"
                    />
                    {ov.text && (
                      <g transform={`translate(${tx}, ${ty})`}>
                        <rect
                          x="0"
                          y="0"
                          width={labelW}
                          height="18"
                          rx="5"
                          fill={bg}
                          stroke={color}
                          strokeWidth="1"
                        />
                        <text x="7" y="12" fontSize="8" fontWeight="600" fill={color}>
                          {ov.text.slice(0, 42)}
                        </text>
                      </g>
                    )}
                  </g>
                );
              })}

              {/* Focus Scope subtle dashed frame (when focusing a data group, panel, or guide) */}
              {focusScope &&
                focusScope.elementIds.length > 1 &&
                focusScope.elementIds.length < bundle.substrate.elements.length && (() => {
                  const fEls = focusScope.elementIds
                    .map((id) => bundle.index.elementById.get(id))
                    .filter((e): e is GlossElement => Boolean(e));
                  if (fEls.length === 0) return null;
                  const fx0 = Math.min(...fEls.map((e) => Math.min(e.x0, e.x1))) - 6;
                  const fy0 = Math.min(...fEls.map((e) => Math.min(e.y0, e.y1))) - 6;
                  const fx1 = Math.max(...fEls.map((e) => Math.max(e.x0, e.x1))) + 6;
                  const fy1 = Math.max(...fEls.map((e) => Math.max(e.y0, e.y1))) + 6;
                  const strokeColor = focusScope.isException ? "#d97706" : "#2563eb";
                  return (
                    <rect
                      x={fx0}
                      y={fy0}
                      width={Math.max(12, fx1 - fx0)}
                      height={Math.max(12, fy1 - fy0)}
                      rx="6"
                      fill={strokeColor}
                      fillOpacity="0.035"
                      stroke={strokeColor}
                      strokeWidth="1.2"
                      strokeDasharray="4 3"
                    />
                  );
                })()}

              {/* Selected elements crisp blue focus rings */}
              {selectedElements.map((el) => {
                const pad = 3.5;
                const isPointLike =
                  el.tag === "circle" || (el.x1 - el.x0 < 12 && el.y1 - el.y0 < 12);
                const c = elementCenter(el);
                return (
                  <g key={`sel-${el.id}`}>
                    {isPointLike ? (
                      <>
                        <circle
                          cx={c.x}
                          cy={c.y}
                          r={Math.max(7.2, (el.x1 - el.x0) / 2 + 4.2)}
                          fill="#2563eb"
                          fillOpacity="0.12"
                          stroke="#2563eb"
                          strokeWidth="2"
                        />
                      </>
                    ) : (
                      <rect
                        x={el.x0 - pad}
                        y={el.y0 - pad}
                        width={Math.max(6, el.x1 - el.x0 + pad * 2)}
                        height={Math.max(6, el.y1 - el.y0 + pad * 2)}
                        rx="3"
                        fill="#2563eb"
                        fillOpacity="0.08"
                        stroke="#2563eb"
                        strokeWidth="1.8"
                      />
                    )}
                  </g>
                );
              })}

              {/* Hovered element clean hover halo */}
              {hoveredEl && (
                <rect
                  x={hoveredEl.x0 - 3}
                  y={hoveredEl.y0 - 3}
                  width={Math.max(6, hoveredEl.x1 - hoveredEl.x0 + 6)}
                  height={Math.max(6, hoveredEl.y1 - hoveredEl.y0 + 6)}
                  rx="3"
                  fill="none"
                  stroke="#0f172a"
                  strokeOpacity="0.65"
                  strokeWidth="1.1"
                  strokeDasharray="2.5 2"
                />
              )}
            </svg>
          )}

          {/* Before / After Curtain Slider Handle (Inspector mode) */}
          {!isReader && splitCompare && curStageIdx > 0 && (
            <div
              className="absolute inset-y-0 z-20 flex items-center"
              style={{ left: `${splitRatio * 100}%` }}
            >
              <div className="h-full w-[2px]" style={{ background: "var(--st-focus)" }} />
              <button
                type="button"
                aria-label="Drag comparison divider"
                onMouseDown={(e) => {
                  e.stopPropagation();
                  setDraggingSplit(true);
                }}
                className="pointer-events-auto -ml-3.5 flex h-7 w-7 cursor-ew-resize items-center justify-center rounded-full border-2 bg-white shadow-md"
                style={{ borderColor: "var(--st-focus)", color: "var(--st-focus)" }}
              >
                <Columns2 className="h-3.5 w-3.5" />
              </button>
              <span
                className="pointer-events-none absolute left-2 top-2 rounded px-1.5 py-0.5 text-[9.5px] font-semibold text-white"
                style={{ background: "var(--st-focus)" }}
              >
                {SEMANTIC_STAGES[curStageIdx]?.shortLabel}
              </span>
              <span className="pointer-events-none absolute right-2 top-2 rounded bg-slate-800/85 px-1.5 py-0.5 text-[9.5px] font-semibold text-white">
                Raw SVG
              </span>
            </div>
          )}

          {/* Interactive Floating Hover Tooltip (Human scientific format in Reader mode; full technical metadata in Inspector mode) */}
          {hoveredEl && !isPureFigure && (
            <div
              className="pointer-events-none absolute z-30 max-w-[270px] rounded-xl border px-3 py-2 text-[11.5px] shadow-lg"
              style={{
                left: `${Math.min(
                  72,
                  Math.max(
                    3,
                    (((hoveredEl.x0 + hoveredEl.x1) / 2 - viewBox.x) / viewBox.width) * 100 + 2
                  )
                )}%`,
                top: `${Math.max(2, ((hoveredEl.y0 - viewBox.y) / viewBox.height) * 100 - 18)}%`,
                background: "var(--bg-surface)",
                borderColor: "var(--border-strong)",
                color: "var(--ink-primary)",
                boxShadow: "var(--shadow-float)",
              }}
            >
              {isReader && hoveredLegendGroup ? (
                <div>
                  <div className="flex items-center gap-1.5 font-bold" style={{ color: "var(--ink-primary)" }}>
                    {hoveredLegendGroup.swatch && (
                      <span
                        className="h-2.5 w-2.5 rounded-full border border-black/20"
                        style={{ background: hoveredLegendGroup.swatch }}
                      />
                    )}
                    <span>{hoveredLegendGroup.label}</span>
                  </div>
                  <div className="mt-0.5 text-[10.5px]" style={{ color: "var(--st-focus)" }}>
                    {focusScope?.id === hoveredLegendGroup.id
                      ? "Click to show all groups"
                      : `Click to filter ${hoveredLegendGroup.elementIds.length} observations`}
                  </div>
                </div>
              ) : isReader && hoveredReaderTip ? (
                <div>
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-bold" style={{ color: "var(--ink-primary)" }}>
                      {hoveredReaderTip.title}
                    </span>
                    {hoveredReaderTip.verified && (
                      <span
                        className="rounded-full px-1.5 py-0.5 text-[9.5px] font-semibold"
                        style={{ background: "var(--st-verified-soft)", color: "var(--st-verified)" }}
                      >
                        Verified
                      </span>
                    )}
                  </div>
                  {hoveredReaderTip.subtitle && (
                    <div className="text-[10.5px]" style={{ color: "var(--ink-muted)" }}>
                      {hoveredReaderTip.subtitle}
                    </div>
                  )}
                  {hoveredReaderTip.metrics.length > 0 && (
                    <div className="mt-1.5 flex flex-wrap gap-x-2.5 gap-y-0.5 font-mono-num text-[10.5px]">
                      {hoveredReaderTip.metrics.map((m) => (
                        <span key={m.label}>
                          <span style={{ color: "var(--ink-muted)" }}>{m.label}: </span>
                          <strong>{m.value}</strong>
                        </span>
                      ))}
                    </div>
                  )}
                  {hoveredEl && interactiveCueIds.includes(hoveredEl.id) && (
                    <div className="mt-1 text-[10px] font-medium" style={{ color: "var(--st-focus)" }}>
                      Click to open context & findings →
                    </div>
                  )}
                </div>
              ) : (
                <div>
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-mono-num font-bold" style={{ color: "var(--st-focus)" }}>
                      {hoveredEl.tag}#{hoveredEl.id}
                    </span>
                    {hoveredBinding && (
                      <span
                        className="rounded px-1.5 py-0.5 text-[9.5px] font-semibold uppercase"
                        style={{
                          background:
                            hoveredBinding.status === "verified"
                              ? "var(--st-verified-soft)"
                              : "var(--st-warn-soft)",
                          color:
                            hoveredBinding.status === "verified"
                              ? "var(--st-verified)"
                              : "var(--st-warn)",
                        }}
                      >
                        {hoveredBinding.status}
                      </span>
                    )}
                  </div>
                  {curStageIdx >= 8 && hoveredTooltip ? (
                    <div className="mt-1 font-medium">{hoveredTooltip}</div>
                  ) : (
                    <div className="mt-0.5 space-y-0.5 text-[10.5px]" style={{ color: "var(--ink-secondary)" }}>
                      {hoveredRaw && (
                        <div className="font-semibold" style={{ color: "var(--ink-primary)" }}>
                          {hoveredRaw.rawKeyLabels.join(", ")} ({hoveredRaw.status})
                        </div>
                      )}
                      {hoveredBinding && (
                        <div className="font-mono-num">
                          {hoveredBinding.table}[row={hoveredBinding.row}] · dev{" "}
                          {hoveredBinding.dev?.toFixed(2) ?? "—"} pt
                        </div>
                      )}
                      {hoveredRole && (
                        <div>
                          role: {hoveredRole.role ?? "—"} {hoveredRole.kind ? `(${hoveredRole.kind})` : ""}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Interactive Guided Story Stepper Bar (in Reader Story lens!) */}
        {isReader && readerLens === "story" && activeStoryStop && (
          <div
            className="absolute bottom-4 left-1/2 z-30 flex w-[min(92%,560px)] -translate-x-1/2 items-center justify-between gap-3 rounded-2xl border px-4 py-2.5 shadow-xl"
            style={{
              background: "var(--bg-surface)",
              borderColor: "var(--st-focus)",
              boxShadow: "var(--shadow-float)",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex min-w-0 items-start gap-2.5">
              <span
                className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-xs font-bold text-white"
                style={{ background: "var(--st-focus)" }}
              >
                {activeStoryStop.order}
              </span>
              <div className="min-w-0">
                <div className="text-[10px] font-bold uppercase tracking-wider" style={{ color: "var(--st-focus)" }}>
                  Step {storyStepIdx + 1} of {narrativeStops.length}
                </div>
                <p className="text-xs leading-snug" style={{ color: "var(--ink-primary)" }}>
                  {activeStoryStop.record.body.text}
                </p>
              </div>
            </div>
            <div className="flex shrink-0 items-center gap-1">
              <button
                type="button"
                disabled={storyStepIdx <= 0}
                onClick={() => setStoryStepIdx(Math.max(0, storyStepIdx - 1))}
                className="rounded-lg border p-1.5 disabled:opacity-35 hover:bg-[var(--bg-subtle)]"
                style={{ borderColor: "var(--border-subtle)" }}
                aria-label="Previous step"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <button
                type="button"
                disabled={storyStepIdx >= narrativeStops.length - 1}
                onClick={() => setStoryStepIdx(Math.min(narrativeStops.length - 1, storyStepIdx + 1))}
                className="rounded-lg border p-1.5 disabled:opacity-35 hover:bg-[var(--bg-subtle)]"
                style={{ borderColor: "var(--border-subtle)" }}
                aria-label="Next step"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Bottom Interactive Guidance & Coordinate HUD */}
      <div
        className="flex flex-wrap items-center justify-between gap-2 border-t px-3 py-1.5 text-[11px]"
        style={{
          background: "var(--bg-surface)",
          borderColor: "var(--border-subtle)",
          color: "var(--ink-secondary)",
        }}
      >
        <div className="flex items-center gap-3 font-mono-num">
          {!isReader && (
            <span className="inline-flex items-center gap-1">
              <MousePointerClick className="h-3 w-3" style={{ color: "var(--st-focus)" }} />
              {cursorSvg ? `SVG (${cursorSvg.x.toFixed(1)}, ${cursorSvg.y.toFixed(1)}) pt` : "Hover figure"}
            </span>
          )}
          {dataReadout ? (
            <span style={{ color: "var(--st-verified)" }}>
              {(dataReadout.panel.key ?? dataReadout.panel.id).replace(/=/g, " = ")}
              {dataReadout.dataX !== null ? ` · x = ${dataReadout.dataX.toFixed(2)}` : ""}
              {dataReadout.dataY !== null ? ` · y = ${dataReadout.dataY.toFixed(2)}` : ""}
            </span>
          ) : (
            isReader && (
              <span className="font-sans text-[11px]" style={{ color: "var(--ink-muted)" }}>
                Move cursor over plot to read values
              </span>
            )
          )}
        </div>

        <div className="flex items-center gap-2 text-[10.5px]" style={{ color: "var(--ink-muted)" }}>
          {(hiddenLeafIds.length > 0 || hiddenElementIds.length > 0) && (
            <span className="inline-flex items-center gap-1" style={{ color: "var(--st-warn)" }}>
              <Eye className="h-3 w-3" /> {hiddenElementIds.length || hiddenLeafIds.length} hidden
            </span>
          )}
          {isReader && narrativeStops.length > 0 && readerLens !== "story" && (
            <button
              type="button"
              onClick={() => {
                setStoryStepIdx(0);
                setReaderLens("story");
              }}
              className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10.5px] font-semibold"
              style={{ background: "var(--st-focus-soft)", color: "var(--st-focus)" }}
            >
              <Sparkles className="h-3 w-3" />
              Start {narrativeStops.length}-step story
            </button>
          )}
          {!isReader && <span>Ctrl/⌘ + Scroll to zoom · Alt + Drag to pan · Click legend to filter</span>}
        </div>
      </div>
    </div>
  );
};
