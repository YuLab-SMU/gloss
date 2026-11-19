import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Columns2,
  Eye,
  Maximize2,
  MousePointerClick,
  RotateCcw,
  ZoomIn,
  ZoomOut,
} from "lucide-react";
import {
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
  const activeStage = useWorkbenchStore((s) => s.activeStage);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const hoveredElementId = useWorkbenchStore((s) => s.hoveredElementId);
  const highlightedGroup = useWorkbenchStore((s) => s.highlightedGroup);
  const gridFilterElementIds = useWorkbenchStore((s) => s.gridFilterElementIds);
  const splitCompare = useWorkbenchStore((s) => s.splitCompare);
  const splitRatio = useWorkbenchStore((s) => s.splitRatio);
  const hiddenLeafIds = useWorkbenchStore((s) => s.hiddenLeafIds);

  const selectElement = useWorkbenchStore((s) => s.selectElement);
  const setHoveredElement = useWorkbenchStore((s) => s.setHoveredElement);
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

  const curStageIdx = stageIndex(activeStage);

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

  // Apply non-destructive visibility toggles for hidden leaves via CSS class on original SVG nodes
  useEffect(() => {
    const host = svgHostRef.current;
    if (!host || !bundle) return;
    const hiddenSet = new Set(hiddenLeafIds);
    const nodes = host.querySelectorAll<SVGElement>("[data-gloss-element]");
    nodes.forEach((node) => {
      const id = node.getAttribute("data-gloss-element") ?? "";
      const el = bundle.index.elementById.get(id);
      if (el?.leaf && hiddenSet.has(el.leaf)) {
        node.style.opacity = "0.06";
      } else {
        node.style.opacity = "";
      }
    });
  }, [bundle, hiddenLeafIds]);

  // Apply gentle fade to non-filtered elements when AG Grid filter sync or group highlight is active
  useEffect(() => {
    const host = svgHostRef.current;
    if (!host || !bundle) return;
    const activeSubset =
      highlightedGroup?.elementIds ?? gridFilterElementIds ?? null;
    const subsetSet = activeSubset ? new Set(activeSubset) : null;
    const hiddenSet = new Set(hiddenLeafIds);

    const nodes = host.querySelectorAll<SVGElement>("[data-gloss-element]");
    nodes.forEach((node) => {
      const id = node.getAttribute("data-gloss-element") ?? "";
      const el = bundle.index.elementById.get(id);
      if (el?.leaf && hiddenSet.has(el.leaf)) {
        node.style.opacity = "0.06";
        return;
      }
      if (!subsetSet || curStageIdx === 0) {
        node.style.opacity = "";
        return;
      }
      const isBound = bundle.index.bindingByElement.has(id);
      if (isBound && !subsetSet.has(id)) {
        node.style.opacity = "0.18";
      } else {
        node.style.opacity = "";
      }
    });
  }, [bundle, highlightedGroup, gridFilterElementIds, hiddenLeafIds, curStageIdx]);

  // Expose live `window.gloss` read-only workbench API for agents / console users
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
    if (curStageIdx === 0 || !spatial) {
      setHoveredElement(null);
      return;
    }
    const hit = spatial.hitTest(pt.x, pt.y, Math.max(3, 6 / zoom));
    setHoveredElement(hit?.id ?? null);
  };

  const handleStageClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (isPanning || draggingSplit) return;
    if (curStageIdx === 0) return;
    const pt = clientToSvgCoords(e.clientX, e.clientY);
    if (!pt || !spatial) return;
    const hit = spatial.hitTest(pt.x, pt.y, Math.max(3, 6 / zoom));
    if (hit) {
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

  // Build relation edges from relation records & operation links (stagger duplicate endpoint pairs)
  const relationArcs = useMemo(() => {
    const arcs: Array<{
      from: GlossElement;
      to: GlossElement;
      label: string;
      verified: boolean;
      pairIndex: number;
    }> = [];
    const pairCounts = new Map<string, number>();
    const addArc = (from: GlossElement, to: GlossElement, label: string, verified: boolean) => {
      const key = [from.id, to.id].sort().join("--");
      const pairIndex = pairCounts.get(key) ?? 0;
      pairCounts.set(key, pairIndex + 1);
      arcs.push({ from, to, label, verified, pairIndex });
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
            rec.body.type ?? rec.body.text ?? "relation",
            rec.projectionStatus === "verified"
          );
        }
      }
    }
    return arcs;
  }, [bundle]);

  // Narrative stops for Stage 7+
  const narrativeStops = useMemo(() => {
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

  // Bound elements (cap rendered ambient rings at 600 so 10^5 dense leaves never bloat SVG DOM)
  const ambientBindings = useMemo(
    () => bundle.derived.bindingsElements.slice(0, 600),
    [bundle]
  );

  // Contextual callouts for Stage 4+
  const contextualRecords = useMemo(
    () => bundle.records.filter((r) => r.workbenchStage === "contextual" && r.resolvedTargets.length > 0),
    [bundle]
  );

  const selectedElements = selectedElementIds
    .map((id) => bundle.index.elementById.get(id))
    .filter((e): e is GlossElement => Boolean(e));

  const overlayClipPath = splitCompare
    ? `inset(0 0 0 ${(splitRatio * 100).toFixed(2)}%)`
    : undefined;

  return (
    <div className="relative flex h-full w-full flex-col overflow-hidden" style={{ background: "var(--bg-canvas)" }}>
      {/* Stage Toolbar */}
      <div
        className="flex items-center justify-between gap-2 border-b px-3 py-1.5 text-xs"
        style={{
          background: "var(--bg-surface)",
          borderColor: "var(--border-subtle)",
        }}
      >
        <div className="flex items-center gap-2">
          <span className="font-semibold" style={{ color: "var(--ink-primary)" }}>
            {SEMANTIC_STAGES[curStageIdx]?.label}
          </span>
          <span className="hidden text-[11px] sm:inline" style={{ color: "var(--ink-muted)" }}>
            · {SEMANTIC_STAGES[curStageIdx]?.zhLabel}
          </span>
          {bundle.sourceKind === "plain-svg" && (
            <span
              className="rounded-full px-2 py-0.5 text-[10px] font-semibold"
              style={{ background: "var(--st-warn-soft)", color: "var(--st-warn)" }}
            >
              Geometry Only (No Bundle)
            </span>
          )}
          {highlightedGroup && (
            <button
              type="button"
              onClick={() => useWorkbenchStore.getState().setHighlightedGroup(null)}
              className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10.5px] font-semibold"
              style={{ background: "var(--st-warn-soft)", color: "var(--st-warn)" }}
              title="Click to clear highlighted check group"
            >
              Group: {highlightedGroup.label} ({highlightedGroup.elementIds.length}) ×
            </button>
          )}
          {gridFilterElementIds && (
            <button
              type="button"
              onClick={() => useWorkbenchStore.getState().setGridFilterElementIds(null)}
              className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10.5px] font-semibold"
              style={{ background: "var(--st-focus-soft)", color: "var(--st-focus)" }}
            >
              Grid Sync ({gridFilterElementIds.length} marks) ×
            </button>
          )}
        </div>

        <div className="flex items-center gap-1">
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

          <button
            type="button"
            onClick={() => setZoom((z) => Math.max(0.4, +(z / 1.2).toFixed(2)))}
            title="Zoom out"
            className="rounded p-1 hover:bg-[var(--bg-subtle)]"
            style={{ color: "var(--ink-secondary)" }}
          >
            <ZoomOut className="h-3.5 w-3.5" />
          </button>
          <span className="font-mono-num min-w-[40px] text-center text-[11px]" style={{ color: "var(--ink-secondary)" }}>
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
            title="Fit to stage"
            className="rounded p-1 hover:bg-[var(--bg-subtle)]"
            style={{ color: "var(--ink-secondary)" }}
          >
            <Maximize2 className="h-3.5 w-3.5" />
          </button>
          {selectedElementIds.length > 0 && (
            <button
              type="button"
              onClick={clearSelection}
              title="Clear selection (Esc)"
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
        className="stage-grid-bg relative flex flex-1 items-center justify-center overflow-hidden p-5"
        style={{ cursor: isPanning ? "grabbing" : curStageIdx === 0 ? "default" : "crosshair" }}
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
        {/* Paper card hosting the untouched svglite SVG + synchronized overlay */}
        <div
          className="relative rounded-xl border bg-white"
          style={{
            width: `min(94%, calc(82vh * ${aspectRatio.toFixed(4)}))`,
            aspectRatio: `${viewBox.width} / ${viewBox.height}`,
            transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
            transformOrigin: "center center",
            transition: isPanning ? "none" : "transform 120ms ease-out",
            borderColor: "var(--border-subtle)",
            boxShadow: "var(--shadow-card)",
          }}
        >
          {/* Layer A: Original untouched SVG from svglite */}
          <div ref={svgHostRef} className="h-full w-full overflow-hidden rounded-xl" />

          {/* Layer B: Non-destructive semantic overlay in exact viewBox space */}
          {curStageIdx > 0 && (
            <svg
              viewBox={`${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`}
              className="pointer-events-none absolute inset-0 h-full w-full overflow-visible rounded-xl"
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

              {/* Stage 1+: Panel structural frames */}
              {curStageIdx >= 1 &&
                bundle.substrate.panels.map((p) => (
                  <g key={p.id}>
                    <rect
                      x={Math.min(p.x0, p.x1)}
                      y={Math.min(p.y0, p.y1)}
                      width={Math.abs(p.x1 - p.x0)}
                      height={Math.abs(p.y1 - p.y0)}
                      fill="none"
                      stroke="#2563eb"
                      strokeOpacity={curStageIdx === 1 ? 0.45 : 0.16}
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

              {/* Stage 2+: Ambient binding status rings on bound marks */}
              {curStageIdx >= 2 &&
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
                      strokeWidth={curStageIdx === 2 ? 1.25 : 0.7}
                      strokeOpacity={curStageIdx === 2 ? 0.72 : 0.28}
                    />
                  );
                })}

              {/* Stage 4+: Contextual meaning domain pins */}
              {curStageIdx >= 4 &&
                contextualRecords.map((rec) => {
                  const el = bundle.index.elementById.get(rec.resolvedTargets[0]);
                  if (!el) return null;
                  const c = elementCenter(el);
                  const panel = el.panel ? bundle.index.panelById.get(el.panel) : undefined;
                  const hasBehaviorOverlay =
                    curStageIdx >= 8 &&
                    bundle.operations.state.overlays.some((ov) => ov.targets.includes(el.id));
                  const label =
                    bundle.index.inferredRawByElement.get(el.id)?.rawKeyLabels[0] ??
                    rec.body.label ??
                    rec.body.type ??
                    "context";
                  const pillW = Math.min(130, label.length * 5.2 + 14);
                  const maxRight = panel ? Math.max(panel.x0, panel.x1) - 4 : viewBox.x + viewBox.width - 4;
                  const px = c.x + 10 + pillW > maxRight ? Math.max(viewBox.x + 4, c.x - pillW - 10) : c.x + 10;
                  const py = hasBehaviorOverlay ? c.y + 18 : c.y - 16;
                  return (
                    <g key={`ctx-${rec.id}`}>
                      <circle
                        cx={c.x}
                        cy={c.y}
                        r={8}
                        fill="none"
                        stroke="#7c3aed"
                        strokeWidth={1.5}
                        strokeDasharray="3 2"
                      />
                      <g transform={`translate(${px}, ${py})`}>
                        <rect
                          x="0"
                          y="-9"
                          width={pillW}
                          height="16"
                          rx="4"
                          fill="#ede9fe"
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

              {/* Stage 5+: Relation curved arcs */}
              {curStageIdx >= 5 &&
                relationArcs.map((arc, idx) => {
                  const p1 = elementCenter(arc.from);
                  const p2 = elementCenter(arc.to);
                  const mx = (p1.x + p2.x) / 2;
                  const bow = arc.pairIndex % 2 === 0 ? -(28 + arc.pairIndex * 16) : 34 + (arc.pairIndex - 1) * 16;
                  const my = (p1.y + p2.y) / 2 + bow;
                  const txt = arc.label.slice(0, 24);
                  const pillW = txt.length * 4.5 + 12;
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
                        x={mx - pillW / 2}
                        y={labelY - 10}
                        width={pillW}
                        height="13"
                        rx="3.5"
                        fill="#ffffff"
                        fillOpacity="0.92"
                        stroke={arc.verified ? "#93c5fd" : "#fcd34d"}
                        strokeWidth="0.7"
                      />
                      <text
                        x={mx}
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

              {/* Stage 6+: Claim check exception/group highlight halos */}
              {curStageIdx >= 6 &&
                highlightedGroup?.elementIds.map((eid) => {
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

              {/* Stage 7+: Narrative reading-order sequence badges */}
              {curStageIdx >= 7 && narrativeStops.length > 0 && (
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
                      strokeOpacity="0.7"
                    />
                  )}
                  {narrativeStops.map((s) => {
                    const c = elementCenter(s.element);
                    return (
                      <g key={`nar-${s.record.id}`} transform={`translate(${c.x - 12}, ${c.y - 12})`}>
                        <circle cx="0" cy="0" r="7.5" fill="#2563eb" />
                        <text
                          x="0"
                          y="3"
                          textAnchor="middle"
                          fontSize="8.5"
                          fontWeight="700"
                          fill="#ffffff"
                        >
                          {s.order}
                        </text>
                      </g>
                    );
                  })}
                </g>
              )}

              {/* Stage 8 (Behavior): Checked gloss-overlay callouts (leader / box / bracket / region) */}
              {curStageIdx >= 8 &&
                bundle.operations.state.overlays.map((ov, idx) => {
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
                      {ov.kind === "box" || ov.kind === "region" ? (
                        <rect
                          x={minX - 5}
                          y={minY - 5}
                          width={maxX - minX + 10}
                          height={maxY - minY + 10}
                          rx="4"
                          fill={color}
                          fillOpacity="0.09"
                          stroke={color}
                          strokeWidth="1.4"
                          strokeDasharray={ov.status === "speculative" ? "4 3" : undefined}
                        />
                      ) : (
                        <>
                          <circle cx={cx} cy={cy} r="7" fill="none" stroke={color} strokeWidth="1.8" />
                          <line
                            x1={cx}
                            y1={cy}
                            x2={tx < cx ? tx + labelW : tx}
                            y2={ty + 8}
                            stroke={color}
                            strokeWidth="1.2"
                            strokeDasharray={ov.status === "speculative" ? "3 2" : undefined}
                          />
                        </>
                      )}
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

              {/* Selected elements crisp blue focus rings */}
              {selectedElements.map((el) => {
                const pad = 3.5;
                const isPointLike = el.tag === "circle" || (el.x1 - el.x0 < 12 && el.y1 - el.y0 < 12);
                const c = elementCenter(el);
                return (
                  <g key={`sel-${el.id}`}>
                    {isPointLike ? (
                      <>
                        <circle
                          cx={c.x}
                          cy={c.y}
                          r={Math.max(7.5, (el.x1 - el.x0) / 2 + 4.5)}
                          fill="#2563eb"
                          fillOpacity="0.12"
                          stroke="#2563eb"
                          strokeWidth="2.2"
                        />
                        <circle
                          cx={c.x}
                          cy={c.y}
                          r={Math.max(11, (el.x1 - el.x0) / 2 + 8)}
                          fill="none"
                          stroke="#2563eb"
                          strokeOpacity="0.35"
                          strokeWidth="1"
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
                        strokeWidth="2"
                      />
                    )}
                  </g>
                );
              })}

              {/* Hovered element precision reticle */}
              {hoveredEl && (
                <g>
                  <rect
                    x={hoveredEl.x0 - 3}
                    y={hoveredEl.y0 - 3}
                    width={Math.max(6, hoveredEl.x1 - hoveredEl.x0 + 6)}
                    height={Math.max(6, hoveredEl.y1 - hoveredEl.y0 + 6)}
                    rx="3"
                    fill="none"
                    stroke="#0f172a"
                    strokeWidth="1.2"
                    strokeDasharray="2.5 2"
                  />
                </g>
              )}
            </svg>
          )}

          {/* Before / After Curtain Slider Handle */}
          {splitCompare && curStageIdx > 0 && (
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

          {/* Floating Safe Hover Tooltip (React textContent only — zero innerHTML) */}
          {hoveredEl && curStageIdx > 0 && (
            <div
              className="pointer-events-none absolute z-30 max-w-[260px] rounded-lg border px-2.5 py-2 text-[11px] shadow-lg"
              style={{
                left: `${Math.min(
                  74,
                  Math.max(4, (((hoveredEl.x0 + hoveredEl.x1) / 2 - viewBox.x) / viewBox.width) * 100 + 2)
                )}%`,
                top: `${Math.max(
                  2,
                  (((hoveredEl.y0 - viewBox.y) / viewBox.height) * 100) - 16
                )}%`,
                background: "var(--bg-surface)",
                borderColor: "var(--border-strong)",
                color: "var(--ink-primary)",
                boxShadow: "var(--shadow-float)",
              }}
            >
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
                <div className="mt-1 font-medium" style={{ color: "var(--ink-primary)" }}>
                  {hoveredTooltip}
                </div>
              ) : (
                <div className="mt-0.5 space-y-0.5 text-[10.5px]" style={{ color: "var(--ink-secondary)" }}>
                  {hoveredRaw && curStageIdx >= 3 && (
                    <div className="font-semibold" style={{ color: "var(--ink-primary)" }}>
                      {hoveredRaw.rawKeyLabels.join(", ")}{" "}
                      <span className="text-[9.5px] font-normal" style={{ color: "var(--ink-muted)" }}>
                        ({hoveredRaw.status})
                      </span>
                    </div>
                  )}
                  {hoveredBinding && curStageIdx >= 2 && (
                    <div className="font-mono-num">
                      {hoveredBinding.table}[row={hoveredBinding.row}] · dev{" "}
                      {hoveredBinding.dev?.toFixed(2) ?? "—"} pt
                    </div>
                  )}
                  {hoveredRole && (
                    <div>
                      role: <span className="font-medium">{hoveredRole.role ?? "—"}</span>
                      {hoveredRole.kind ? ` (${hoveredRole.kind})` : ""}
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Bottom Precision Coordinate & Status HUD */}
      <div
        className="flex flex-wrap items-center justify-between gap-2 border-t px-3 py-1 text-[11px]"
        style={{
          background: "var(--bg-surface)",
          borderColor: "var(--border-subtle)",
          color: "var(--ink-secondary)",
        }}
      >
        <div className="flex items-center gap-3 font-mono-num">
          <span className="inline-flex items-center gap-1">
            <MousePointerClick className="h-3 w-3" style={{ color: "var(--st-focus)" }} />
            {cursorSvg ? `SVG (${cursorSvg.x.toFixed(1)}, ${cursorSvg.y.toFixed(1)}) pt` : "Hover figure"}
          </span>
          {dataReadout && (
            <span style={{ color: "var(--st-verified)" }}>
              {dataReadout.panel.key ?? dataReadout.panel.id}
              {dataReadout.dataX !== null ? ` · x=${dataReadout.dataX.toFixed(2)}` : ""}
              {dataReadout.dataY !== null ? ` · y=${dataReadout.dataY.toFixed(2)}` : ""}
            </span>
          )}
        </div>

        <div className="flex items-center gap-3 text-[10.5px]" style={{ color: "var(--ink-muted)" }}>
          {hiddenLeafIds.length > 0 && (
            <span className="inline-flex items-center gap-1" style={{ color: "var(--st-warn)" }}>
              <Eye className="h-3 w-3" /> {hiddenLeafIds.length} leaf hidden
            </span>
          )}
          <span>Ctrl/⌘ + Scroll to zoom · Alt + Drag to pan · Click mark to inspect</span>
        </div>
      </div>
    </div>
  );
};
