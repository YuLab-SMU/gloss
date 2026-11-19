import React, { useEffect, useMemo } from "react";
import { Command } from "cmdk";
import { Columns2, Crosshair, Layers, Moon, Search, Sparkles, Sun, Target } from "lucide-react";
import { buildOutlineTree, SEMANTIC_STAGES, type OutlineNode } from "../codec";
import { useWorkbenchStore } from "../store/useWorkbenchStore";

export const CommandPalette: React.FC = () => {
  const open = useWorkbenchStore((s) => s.commandOpen);
  const setOpen = useWorkbenchStore((s) => s.setCommandOpen);
  const bundle = useWorkbenchStore((s) => s.bundle);
  const setActiveStage = useWorkbenchStore((s) => s.setActiveStage);
  const selectElement = useWorkbenchStore((s) => s.selectElement);
  const selectRecord = useWorkbenchStore((s) => s.selectRecord);
  const setFocusScope = useWorkbenchStore((s) => s.setFocusScope);
  const toggleTheme = useWorkbenchStore((s) => s.toggleTheme);
  const theme = useWorkbenchStore((s) => s.theme);
  const splitCompare = useWorkbenchStore((s) => s.splitCompare);
  const setSplitCompare = useWorkbenchStore((s) => s.setSplitCompare);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setOpen(!useWorkbenchStore.getState().commandOpen);
      } else if (e.key === "Escape" && useWorkbenchStore.getState().commandOpen) {
        setOpen(false);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [setOpen]);

  const focusTargets = useMemo(() => {
    if (!bundle) return [] as OutlineNode[];
    const dataTree = buildOutlineTree(bundle, "data");
    const semTree = buildOutlineTree(bundle, "semantic");
    const walk = (nodes: OutlineNode[]): OutlineNode[] =>
      nodes.flatMap((n) => [n, ...walk(n.children)]);
    const seen = new Set<string>();
    return [...walk(dataTree), ...walk(semTree)]
      .filter((n) => {
        if (n.elementIds.length === 0 || n.id === "root:figure" || n.icon === "point") return false;
        const k = `${n.label}:${n.elementIds.length}`;
        if (seen.has(k)) return false;
        seen.add(k);
        return true;
      })
      .slice(0, 28);
  }, [bundle]);

  if (!open) return null;

  const entities = bundle
    ? Array.from(bundle.index.inferredRawByElement.entries()).slice(0, 60)
    : [];

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center bg-black/45 pt-[12vh] backdrop-blur-[1px]"
      onClick={() => setOpen(false)}
    >
      <div
        className="w-full max-w-xl overflow-hidden rounded-2xl border shadow-2xl"
        style={{
          background: "var(--bg-surface)",
          borderColor: "var(--border-strong)",
          boxShadow: "var(--shadow-float)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <Command label="gloss Workbench Command Palette">
          <div
            className="flex items-center gap-2 border-b px-4 py-3"
            style={{ borderColor: "var(--border-subtle)" }}
          >
            <Search className="h-4 w-4" style={{ color: "var(--ink-muted)" }} />
            <Command.Input
              autoFocus
              placeholder="Jump to stage, element (e65), entity (Mazda RX4), or record..."
              className="w-full bg-transparent text-sm focus:outline-none"
              style={{ color: "var(--ink-primary)" }}
            />
            <kbd
              className="font-mono-num rounded border px-1.5 py-0.5 text-[10px]"
              style={{ borderColor: "var(--border-subtle)", color: "var(--ink-muted)" }}
            >
              ESC
            </kbd>
          </div>

          <Command.List className="max-h-[360px] overflow-y-auto p-2 text-xs">
            <Command.Empty className="py-8 text-center text-xs" style={{ color: "var(--ink-muted)" }}>
              No matching stage, element, entity, or record.
            </Command.Empty>

            {focusTargets.length > 0 && (
              <Command.Group heading="Focus Layer, Group or Semantic Scope" className="mb-2">
                {focusTargets.map((n) => (
                  <Command.Item
                    key={n.id}
                    value={`focus ${n.label} ${n.subtitle ?? ""}`}
                    onSelect={() => {
                      setFocusScope(
                        {
                          id: n.id,
                          label: n.label,
                          kind: n.icon,
                          elementIds: n.elementIds,
                          recordId: n.recordId,
                          swatch: n.swatch,
                          isException: n.icon === "exception",
                        },
                        true
                      );
                      setOpen(false);
                    }}
                    className="flex cursor-pointer items-center justify-between gap-2 rounded-lg px-3 py-2 aria-selected:bg-[var(--st-focus-soft)]"
                  >
                    <span className="flex min-w-0 items-center gap-2">
                      {n.swatch ? (
                        <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: n.swatch }} />
                      ) : (
                        <Crosshair className="h-3.5 w-3.5 shrink-0" style={{ color: "var(--st-focus)" }} />
                      )}
                      <span className="truncate font-medium" style={{ color: "var(--ink-primary)" }}>
                        {n.label}
                      </span>
                    </span>
                    <span className="font-mono-num shrink-0 text-[10px]" style={{ color: "var(--ink-muted)" }}>
                      {n.elementIds.length} el
                    </span>
                  </Command.Item>
                ))}
              </Command.Group>
            )}

            <Command.Group heading="Semantic Stages" className="mb-2">
              {SEMANTIC_STAGES.map((st) => (
                <Command.Item
                  key={st.id}
                  value={`stage ${st.label} ${st.zhLabel}`}
                  onSelect={() => {
                    setActiveStage(st.id);
                    setOpen(false);
                  }}
                  className="flex cursor-pointer items-center justify-between rounded-lg px-3 py-2 aria-selected:bg-[var(--st-focus-soft)]"
                >
                  <span className="flex items-center gap-2 font-medium" style={{ color: "var(--ink-primary)" }}>
                    <Layers className="h-3.5 w-3.5" style={{ color: "var(--st-focus)" }} />
                    {st.index + 1}. {st.label}
                  </span>
                  <span style={{ color: "var(--ink-muted)" }}>{st.zhLabel}</span>
                </Command.Item>
              ))}
            </Command.Group>

            {entities.length > 0 && (
              <Command.Group heading="Bound Marks & Entities" className="mb-2">
                {entities.map(([eid, match]) => (
                  <Command.Item
                    key={eid}
                    value={`${eid} ${match.rawKeyLabels.join(" ")}`}
                    onSelect={() => {
                      selectElement(eid);
                      setOpen(false);
                    }}
                    className="flex cursor-pointer items-center justify-between rounded-lg px-3 py-2 aria-selected:bg-[var(--st-focus-soft)]"
                  >
                    <span className="flex items-center gap-2">
                      <Target className="h-3.5 w-3.5" style={{ color: "var(--st-verified)" }} />
                      <span className="font-mono-num font-semibold" style={{ color: "var(--st-focus)" }}>
                        {eid}
                      </span>
                      <span style={{ color: "var(--ink-primary)" }}>
                        {match.rawKeyLabels.join(", ")}
                      </span>
                    </span>
                    <span className="font-mono-num text-[10px]" style={{ color: "var(--ink-muted)" }}>
                      {match.rawTable}[{match.rawRows.join(",")}]
                    </span>
                  </Command.Item>
                ))}
              </Command.Group>
            )}

            {bundle && bundle.records.length > 0 && (
              <Command.Group heading="Semantic Records" className="mb-2">
                {bundle.records.map((rec) => (
                  <Command.Item
                    key={rec.id}
                    value={`${rec.id} ${rec.layer} ${rec.body.text ?? ""}`}
                    onSelect={() => {
                      selectRecord(rec.id);
                      setOpen(false);
                    }}
                    className="flex cursor-pointer items-center justify-between gap-2 rounded-lg px-3 py-2 aria-selected:bg-[var(--st-focus-soft)]"
                  >
                    <span className="flex min-w-0 items-center gap-2">
                      <Sparkles className="h-3.5 w-3.5 shrink-0" style={{ color: "var(--st-contextual)" }} />
                      <span className="truncate" style={{ color: "var(--ink-primary)" }}>
                        {rec.body.text ?? rec.body.description ?? rec.id}
                      </span>
                    </span>
                    <span className="font-mono-num shrink-0 text-[10px]" style={{ color: "var(--ink-muted)" }}>
                      {rec.layer} · {rec.projectionStatus}
                    </span>
                  </Command.Item>
                ))}
              </Command.Group>
            )}

            <Command.Group heading="Workspace Actions">
              <Command.Item
                value="toggle theme paper obsidian dark light"
                onSelect={() => {
                  toggleTheme();
                  setOpen(false);
                }}
                className="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 aria-selected:bg-[var(--st-focus-soft)]"
              >
                {theme === "paper" ? <Moon className="h-3.5 w-3.5" /> : <Sun className="h-3.5 w-3.5" />}
                <span>Switch to {theme === "paper" ? "Obsidian Lab (Dark)" : "Paper Studio (Light)"}</span>
              </Command.Item>
              <Command.Item
                value="toggle before after split compare raw svg"
                onSelect={() => {
                  setSplitCompare(!splitCompare);
                  setOpen(false);
                }}
                className="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 aria-selected:bg-[var(--st-focus-soft)]"
              >
                <Columns2 className="h-3.5 w-3.5" />
                <span>{splitCompare ? "Exit" : "Enter"} Raw SVG Curtain Comparison</span>
              </Command.Item>
            </Command.Group>
          </Command.List>
        </Command>
      </div>
    </div>
  );
};
