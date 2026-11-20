import React, { useMemo, useState } from "react";
import {
  Activity,
  AlertTriangle,
  BookOpen,
  ChevronDown,
  ChevronRight,
  CircleDot,
  Crosshair,
  Database,
  Eye,
  EyeOff,
  Grid3x3,
  Image as ImageIcon,
  LayoutGrid,
  Link2,
  ListTree,
  Plus,
  RotateCcw,
  Search,
  ShieldCheck,
  SlidersHorizontal,
  Sparkles,
  Tag,
  Type,
  X,
} from "lucide-react";
import {
  buildOutlineTree,
  humanizeOutlineLabel,
  resolveNaturalFocus,
  type FocusScope,
  type OutlineIconKind,
  type OutlineNode,
  type OutlineViewMode,
} from "../../codec";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";

function NodeTypeIcon({ icon, swatch }: { icon: OutlineIconKind; swatch?: string | null }) {
  if (swatch && (icon === "group" || icon === "point")) {
    return (
      <span
        className="h-3 w-3 shrink-0 rounded-full border border-black/20 shadow-xs"
        style={{ background: swatch }}
      />
    );
  }
  const cls = "h-3.5 w-3.5 shrink-0";
  switch (icon) {
    case "figure":
    case "frame":
      return <LayoutGrid className={cls} style={{ color: "var(--ink-secondary)" }} />;
    case "data":
      return <Database className={cls} style={{ color: "var(--st-verified)" }} />;
    case "group":
      return <CircleDot className={cls} style={{ color: "var(--st-focus)" }} />;
    case "point":
      return <CircleDot className={cls} style={{ color: "var(--st-verified)" }} />;
    case "text":
      return <Type className={cls} style={{ color: "var(--ink-secondary)" }} />;
    case "image":
      return <ImageIcon className={cls} style={{ color: "var(--ink-secondary)" }} />;
    case "legend":
      return <Tag className={cls} style={{ color: "var(--ink-secondary)" }} />;
    case "axis":
      return <SlidersHorizontal className={cls} style={{ color: "var(--ink-muted)" }} />;
    case "grid":
      return <Grid3x3 className={cls} style={{ color: "var(--ink-muted)" }} />;
    case "claim":
      return <ShieldCheck className={cls} style={{ color: "var(--st-verified)" }} />;
    case "exception":
      return <AlertTriangle className={cls} style={{ color: "var(--st-warn)" }} />;
    case "context":
      return <Sparkles className={cls} style={{ color: "var(--st-contextual)" }} />;
    case "relation":
      return <Link2 className={cls} style={{ color: "var(--st-focus)" }} />;
    case "narrative":
      return <BookOpen className={cls} style={{ color: "var(--st-focus)" }} />;
    case "behavior":
      return <Activity className={cls} style={{ color: "var(--st-focus)" }} />;
    default:
      return <ListTree className={cls} style={{ color: "var(--ink-muted)" }} />;
  }
}

function filterTree(nodes: OutlineNode[], query: string): OutlineNode[] {
  if (!query) return nodes;
  const tokens = query.toLowerCase().split(/\s+/).filter(Boolean);
  const walk = (node: OutlineNode): OutlineNode | null => {
    const hay = `${node.label} ${node.subtitle ?? ""} ${node.elementIds.slice(0, 6).join(" ")}`.toLowerCase();
    const selfMatch = tokens.every((t) => hay.includes(t));
    const filteredChildren = node.children
      .map(walk)
      .filter((c): c is OutlineNode => Boolean(c));
    if (selfMatch || filteredChildren.length > 0) {
      return {
        ...node,
        defaultExpanded: true,
        children: selfMatch ? node.children : filteredChildren,
      };
    }
    return null;
  };
  return nodes.map(walk).filter((n): n is OutlineNode => Boolean(n));
}

export const OutlineTree: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const viewMode = useWorkbenchStore((s) => s.viewMode);
  const outlineMode = useWorkbenchStore((s) => s.outlineMode);
  const setOutlineMode = useWorkbenchStore((s) => s.setOutlineMode);
  const focusScope = useWorkbenchStore((s) => s.focusScope);
  const setFocusScope = useWorkbenchStore((s) => s.setFocusScope);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const selectedRecordId = useWorkbenchStore((s) => s.selectedRecordId);
  const selectElement = useWorkbenchStore((s) => s.selectElement);
  const selectRecord = useWorkbenchStore((s) => s.selectRecord);
  const setActiveStage = useWorkbenchStore((s) => s.setActiveStage);
  const hiddenElementIds = useWorkbenchStore((s) => s.hiddenElementIds);
  const toggleElementsVisibility = useWorkbenchStore((s) => s.toggleElementsVisibility);
  const resetVisibility = useWorkbenchStore((s) => s.resetVisibility);
  const setProposalModalOpen = useWorkbenchStore((s) => s.setProposalModalOpen);
  const setRightTab = useWorkbenchStore((s) => s.setRightTab);

  const [query, setQuery] = useState("");
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});

  const rawTree = useMemo(() => {
    if (!bundle) return [];
    return buildOutlineTree(bundle, viewMode === "reader" ? "reader" : outlineMode);
  }, [bundle, viewMode, outlineMode]);

  const visibleTree = useMemo(() => filterTree(rawTree, query.trim()), [rawTree, query]);

  const nlPreview = useMemo(() => {
    if (!bundle || !query.trim()) return null;
    return resolveNaturalFocus(bundle, query.trim());
  }, [bundle, query]);

  // Dynamic quick-focus chips: in Reader mode show ONLY real figure groups (no internal Exception/Data Layer jargon!)
  const quickChips = useMemo(() => {
    if (!bundle) return [] as FocusScope[];
    const chips: FocusScope[] = [];
    const dataTree = buildOutlineTree(bundle, "data");
    const allData = dataTree[0];

    if (viewMode !== "reader" && allData && allData.elementIds.length > 0) {
      chips.push({
        id: allData.id,
        label: "Data Layer",
        kind: "data",
        elementIds: allData.elementIds,
      });
    }
    const byGroup = allData?.children.find((c) => c.id === "data:by-group");
    if (byGroup) {
      const cleanGroups = byGroup.children.filter(
        (g) => !/^series\s+#/i.test(g.label) && !/^group\s+\d+$/i.test(g.label)
      );
      const chosen = viewMode === "reader" ? cleanGroups : (cleanGroups.length > 0 ? cleanGroups : byGroup.children);
      for (const g of chosen.slice(0, 4)) {
        chips.push({
          id: g.id,
          label: g.label.includes(" = ") ? g.label.split(" = ").slice(1).join(" = ") : g.label,
          kind: "group",
          swatch: g.swatch,
          elementIds: g.elementIds,
        });
      }
    }
    if (viewMode !== "reader") {
      const semTree = buildOutlineTree(bundle, "semantic");
      const findExceptions = (nodes: OutlineNode[]): OutlineNode[] =>
        nodes.flatMap((n) => [
          ...(n.icon === "exception" && n.id.startsWith("sem:exc:") ? [n] : []),
          ...findExceptions(n.children),
        ]);
      const excs = findExceptions(semTree);
      if (excs.length > 0) {
        chips.push({
          id: excs[0].id,
          label: "Exception",
          kind: "exception",
          elementIds: excs[0].elementIds,
          recordId: excs[0].recordId,
          isException: true,
        });
      }
    }
    return chips;
  }, [bundle, viewMode]);

  if (!bundle) return null;

  const hiddenSet = new Set(hiddenElementIds);
  const selectedSet = new Set(selectedElementIds);

  const isExpanded = (node: OutlineNode): boolean => {
    if (query.trim()) return true;
    if (node.id in expanded) return expanded[node.id];
    return Boolean(node.defaultExpanded);
  };

  const toggleExpand = (node: OutlineNode) => {
    setExpanded((prev) => ({ ...prev, [node.id]: !isExpanded(node) }));
  };

  const focusNode = (node: OutlineNode, autoZoom = false) => {
    if (node.id === "root:figure" || node.id === "grob:root") {
      setFocusScope(null);
      return;
    }
    if (node.stageHint && useWorkbenchStore.getState().activeStage === "raw") {
      setActiveStage(node.stageHint);
    }
    const scope: FocusScope = {
      id: node.id,
      label: node.label,
      kind: node.icon,
      elementIds: node.elementIds,
      recordId: node.recordId,
      swatch: node.swatch,
      isException: node.icon === "exception",
    };
    setFocusScope(scope, autoZoom);
    if (node.recordId) {
      setRightTab(node.icon === "exception" ? "records" : "chain");
    }
  };

  const handleRowClick = (node: OutlineNode) => {
    if (node.id === "root:figure" || node.id === "grob:root") {
      setFocusScope(null);
      return;
    }
    if (node.elementIds.length === 1 && !node.recordId) {
      // Single mark or text element: select directly (and clear multi-element group focus if outside)
      selectElement(node.elementIds[0]);
      if (node.stageHint && useWorkbenchStore.getState().activeStage === "raw") {
        setActiveStage(node.stageHint);
      }
      return;
    }
    if (node.recordId && node.icon !== "exception" && node.elementIds.length <= 2) {
      selectRecord(node.recordId);
      setFocusScope({
        id: node.id,
        label: node.label,
        kind: node.icon,
        elementIds: node.elementIds,
        recordId: node.recordId,
      });
      if (node.stageHint) setActiveStage(node.stageHint);
      return;
    }
    // Group / Panel / Data Layer / Exception / Chrome: Focus & isolate immediately!
    focusNode(node, false);
  };

  const renderNode = (node: OutlineNode, depth: number): React.ReactNode => {
    const hasKids = node.children.length > 0;
    const open = hasKids && isExpanded(node);
    const isFocused = focusScope?.id === node.id;
    const isSelectedSingle =
      !isFocused &&
      ((node.recordId && selectedRecordId === node.recordId) ||
        (node.elementIds.length === 1 && selectedSet.has(node.elementIds[0])));

    const isHidden =
      node.elementIds.length > 0 && node.elementIds.every((id) => hiddenSet.has(id));
    const isPartiallyHidden =
      !isHidden && node.elementIds.some((id) => hiddenSet.has(id));

    const display =
      viewMode === "reader" && !node.id.startsWith("reader:")
        ? humanizeOutlineLabel(node.id, node.label, node.subtitle, bundle)
        : { label: node.label, subtitle: node.subtitle };
    const indentPx = viewMode === "reader" ? 10 : 14;

    return (
      <div key={node.id} className="relative">
        <div
          className="group relative flex items-center gap-1 rounded-lg py-1 pr-1.5 transition-colors"
          style={{
            paddingLeft: `${depth * indentPx + 4}px`,
            background: isFocused
              ? "var(--st-focus-soft)"
              : isSelectedSingle
                ? "var(--bg-subtle)"
                : undefined,
            opacity: isHidden ? 0.45 : 1,
          }}
        >
          {/* Figma/BioRender subtle vertical indentation rail */}
          {depth > 0 && (
            <span
              className="pointer-events-none absolute bottom-0 top-0 w-[1px]"
              style={{
                left: `${depth * indentPx - 1}px`,
                background: "var(--border-subtle)",
              }}
            />
          )}

          {/* Expand / collapse chevron */}
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              if (hasKids) toggleExpand(node);
            }}
            className="flex h-4 w-4 shrink-0 items-center justify-center rounded hover:bg-black/5"
            style={{
              color: "var(--ink-muted)",
              visibility: hasKids ? "visible" : "hidden",
            }}
            aria-label={open ? "Collapse" : "Expand"}
          >
            {open ? <ChevronDown className="h-3 w-3" /> : <ChevronRight className="h-3 w-3" />}
          </button>

          {/* Main clickable node label */}
          <button
            type="button"
            onClick={() => handleRowClick(node)}
            onDoubleClick={() => focusNode(node, true)}
            title={`${display.label}${display.subtitle ? ` — ${display.subtitle}` : ""} (click to focus, double-click to zoom)`}
            className="flex min-w-0 flex-1 items-center gap-1.5 text-left"
          >
            <NodeTypeIcon icon={node.icon} swatch={node.swatch} />
            <div className="min-w-0 flex-1">
              <div
                className="truncate text-[11.5px] leading-tight"
                style={{
                  fontWeight: depth === 0 || isFocused ? 650 : 500,
                  color: isFocused ? "var(--st-focus)" : "var(--ink-primary)",
                }}
              >
                {display.label}
              </div>
              {display.subtitle && depth <= 2 && (
                <div
                  className="truncate text-[10px] leading-tight"
                  style={{ color: "var(--ink-muted)" }}
                >
                  {display.subtitle}
                </div>
              )}
            </div>
          </button>

          {/* Right-side design-tool action strip: hover-revealed focus/eye actions so labels stay clean and readable */}
          <div className="flex shrink-0 items-center gap-1">
            {node.id !== "root:figure" && node.id !== "grob:root" && node.elementIds.length > 0 && (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  if (isFocused) setFocusScope(null);
                  else focusNode(node, true);
                }}
                title={isFocused ? "Exit focus" : "Focus & zoom to this layer/group"}
                className={`h-5 w-5 items-center justify-center rounded ${
                  isFocused ? "flex" : "hidden group-hover:flex"
                }`}
                style={{
                  color: isFocused ? "var(--st-focus)" : "var(--ink-secondary)",
                  background: isFocused ? "var(--bg-surface)" : "transparent",
                }}
              >
                <Crosshair className="h-3 w-3" />
              </button>
            )}

            {/* Signature blue circular semantic annotation badge (echoing reference UI) */}
            {node.recordCount > 0 && (
              <span
                className="font-mono-num flex h-[17px] min-w-[17px] items-center justify-center rounded-full px-1 text-[9.5px] font-bold text-white"
                style={{
                  background: node.hasWarning ? "var(--st-warn)" : "var(--st-focus)",
                }}
                title={`${node.recordCount} note(s)`}
              >
                {node.recordCount}
              </span>
            )}

            {/* Eye visibility toggle (revealed on hover or when hidden, freeing ~24px for labels) */}
            {node.elementIds.length > 0 && (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  toggleElementsVisibility(node.elementIds);
                }}
                title={isHidden ? "Show elements" : "Hide elements on canvas"}
                className={`h-5 w-5 items-center justify-center rounded ${
                  isHidden || isPartiallyHidden ? "flex" : "hidden group-hover:flex"
                }`}
                style={{
                  color: isHidden
                    ? "var(--st-warn)"
                    : isPartiallyHidden
                      ? "var(--st-focus)"
                      : "var(--ink-muted)",
                }}
              >
                {isHidden ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
              </button>
            )}
          </div>
        </div>

        {open && (
          <div className="mt-0.5 space-y-0.5">
            {node.children.map((child) => renderNode(child, depth + 1))}
          </div>
        )}
      </div>
    );
  };

  const modeOptions: Array<[OutlineViewMode, string]> =
    viewMode === "reader"
      ? [
          ["semantic", "Outline"],
          ["data", "Data Groups"],
        ]
      : [
          ["semantic", "Outline"],
          ["data", "Data Groups"],
          ["grob", "SVG / Grob"],
        ];

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      {/* Search + Quick Group Filters (Mode tabs only in Technical Inspector!) */}
      <div className="space-y-2 border-b p-2" style={{ borderColor: "var(--border-subtle)" }}>
        {viewMode !== "reader" && (
          <div
            className="grid grid-cols-3 rounded-lg p-0.5 text-[10.5px] font-semibold"
            style={{ background: "var(--bg-canvas)", border: "1px solid var(--border-subtle)" }}
          >
            {modeOptions.map(([m, lbl]) => {
              const active = outlineMode === m;
              return (
                <button
                  key={m}
                  type="button"
                  onClick={() => setOutlineMode(m)}
                  className="rounded-md py-1 transition-colors"
                  style={{
                    background: active ? "var(--bg-surface)" : "transparent",
                    color: active ? "var(--st-focus)" : "var(--ink-secondary)",
                    boxShadow: active ? "0 1px 2px rgba(0,0,0,0.06)" : "none",
                  }}
                >
                  {lbl}
                </button>
              );
            })}
          </div>
        )}

        {/* Search Input */}
        <form
          onSubmit={(e) => {
            e.preventDefault();
            if (nlPreview) setFocusScope(nlPreview, true);
          }}
          className="flex items-center gap-1.5 rounded-lg border px-2 py-1"
          style={{ background: "var(--bg-canvas)", borderColor: "var(--border-subtle)" }}
        >
          <Search className="h-3.5 w-3.5 shrink-0" style={{ color: "var(--ink-muted)" }} />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={
              viewMode === "reader"
                ? "Search figure..."
                : "Focus: cyl 6, exception, Mazda, legend..."
            }
            className="w-full bg-transparent text-[11.5px] focus:outline-none"
            style={{ color: "var(--ink-primary)" }}
          />
          {query && (
            <button type="button" onClick={() => setQuery("")}>
              <X className="h-3 w-3" style={{ color: "var(--ink-muted)" }} />
            </button>
          )}
        </form>

        {/* Natural-language instant focus button when typing */}
        {nlPreview && (
          <button
            type="button"
            onClick={() => setFocusScope(nlPreview, true)}
            className="flex w-full items-center justify-between gap-2 rounded-lg border px-2.5 py-1.5 text-left text-[11px] font-semibold transition-colors hover:brightness-95"
            style={{
              background: "var(--st-focus-soft)",
              borderColor: "var(--st-focus)",
              color: "var(--st-focus)",
            }}
          >
            <span className="flex min-w-0 items-center gap-1.5">
              <Crosshair className="h-3.5 w-3.5 shrink-0" />
              <span className="truncate">Focus: {nlPreview.label}</span>
            </span>
            <span className="font-mono-num shrink-0 text-[10px]">
              {nlPreview.elementIds.length} el ↵
            </span>
          </button>
        )}

        {/* Quick Focus Chips */}
        {!query && quickChips.length > 0 && (
          <div className="flex flex-wrap gap-1">
            {quickChips.map((chip) => {
              const active = focusScope?.id === chip.id;
              return (
                <button
                  key={chip.id}
                  type="button"
                  onClick={() => setFocusScope(active ? null : chip, false)}
                  className="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[10px] font-medium transition-colors"
                  style={{
                    borderColor: active
                      ? "var(--st-focus)"
                      : chip.isException
                        ? "var(--st-warn)"
                        : "var(--border-subtle)",
                    background: active
                      ? "var(--st-focus-soft)"
                      : chip.isException
                        ? "var(--st-warn-soft)"
                        : "var(--bg-canvas)",
                    color: active
                      ? "var(--st-focus)"
                      : chip.isException
                        ? "var(--st-warn)"
                        : "var(--ink-secondary)",
                  }}
                >
                  {chip.swatch && (
                    <span
                      className="h-2 w-2 rounded-full"
                      style={{ background: chip.swatch }}
                    />
                  )}
                  <span>{chip.label}</span>
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Scrollable Design-Tool Outline Tree */}
      <div className="min-h-0 flex-1 overflow-y-auto px-1.5 py-2">
        {visibleTree.length === 0 ? (
          <div className="p-4 text-center text-xs" style={{ color: "var(--ink-muted)" }}>
            No matching layer, data group, or semantic note.
          </div>
        ) : (
          <div className="space-y-0.5">{visibleTree.map((n) => renderNode(n, 0))}</div>
        )}
      </div>

      {/* Footer Action Bar (echoing Figma/BioRender `+ Add element` footer!) */}
      <div
        className="space-y-1.5 border-t p-2"
        style={{ borderColor: "var(--border-subtle)", background: "var(--bg-canvas)" }}
      >
        {hiddenElementIds.length > 0 && (
          <button
            type="button"
            onClick={resetVisibility}
            className="flex w-full items-center justify-center gap-1.5 rounded-lg border py-1 text-[11px] font-medium hover:bg-[var(--bg-subtle)]"
            style={{ borderColor: "var(--st-warn)", color: "var(--st-warn)" }}
          >
            <RotateCcw className="h-3 w-3" />
            Show {hiddenElementIds.length} hidden element(s)
          </button>
        )}
        <button
          type="button"
          onClick={() => setProposalModalOpen(true)}
          className="flex w-full items-center justify-center gap-1.5 rounded-lg border py-1.5 text-xs font-semibold transition-colors hover:bg-[var(--bg-subtle)]"
          style={{
            background: "var(--bg-surface)",
            borderColor: "var(--border-strong)",
            color: "var(--ink-primary)",
          }}
        >
          <Plus className="h-3.5 w-3.5" style={{ color: "var(--st-focus)" }} />
          {viewMode === "reader" ? "Add note" : "Add semantic note / claim"}
        </button>
      </div>
    </div>
  );
};
