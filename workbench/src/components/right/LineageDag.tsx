import React, { useMemo } from "react";
import {
  Background,
  Controls,
  Handle,
  Position,
  ReactFlow,
  type Edge,
  type Node,
  type NodeProps,
} from "@xyflow/react";
import { useWorkbenchStore } from "../../store/useWorkbenchStore";

interface LineageNodeData extends Record<string, unknown> {
  badge: string;
  title: string;
  subtitle?: string;
  status?: string;
  accent: string;
  recordId?: string;
  elementId?: string;
}

const LineageCardNode: React.FC<NodeProps<Node<LineageNodeData>>> = ({ data }) => {
  return (
    <div
      className="min-w-[205px] max-w-[240px] rounded-lg border px-3 py-2 text-left shadow-sm"
      style={{
        background: "var(--bg-surface)",
        borderColor: data.accent,
        borderLeftWidth: "3.5px",
      }}
    >
      <Handle type="target" position={Position.Top} style={{ background: data.accent, width: 6, height: 6 }} />
      <div className="flex items-center justify-between gap-2">
        <span
          className="text-[9.5px] font-bold uppercase tracking-wider"
          style={{ color: data.accent }}
        >
          {data.badge}
        </span>
        {data.status && (
          <span
            className="font-mono-num rounded px-1.5 py-0 text-[9px] font-semibold"
            style={{ background: "var(--bg-subtle)", color: "var(--ink-secondary)" }}
          >
            {data.status}
          </span>
        )}
      </div>
      <div
        className="mt-0.5 truncate text-[11.5px] font-semibold"
        style={{ color: "var(--ink-primary)" }}
        title={data.title}
      >
        {data.title}
      </div>
      {data.subtitle && (
        <div
          className="mt-0.5 line-clamp-2 text-[10px]"
          style={{ color: "var(--ink-secondary)" }}
          title={data.subtitle}
        >
          {data.subtitle}
        </div>
      )}
      <Handle type="source" position={Position.Bottom} style={{ background: data.accent, width: 6, height: 6 }} />
    </div>
  );
};

const nodeTypes = { lineageCard: LineageCardNode };

function statusAccent(status?: string): string {
  switch (status) {
    case "verified":
    case "classified":
      return "var(--st-verified)";
    case "partial":
    case "ambiguous":
    case "proposed":
    case "inferred":
      return "var(--st-warn)";
    case "failed":
    case "rejected":
    case "missing":
      return "var(--st-fail)";
    case "speculative":
      return "var(--st-contextual)";
    default:
      return "var(--st-focus)";
  }
}

export const LineageDag: React.FC = () => {
  const bundle = useWorkbenchStore((s) => s.bundle);
  const selectedElementIds = useWorkbenchStore((s) => s.selectedElementIds);
  const selectRecord = useWorkbenchStore((s) => s.selectRecord);
  const selectElement = useWorkbenchStore((s) => s.selectElement);

  const primaryId = selectedElementIds[0] ?? null;

  const { nodes, edges } = useMemo(() => {
    if (!bundle) return { nodes: [] as Node<LineageNodeData>[], edges: [] as Edge[] };

    const ns: Node<LineageNodeData>[] = [];
    const es: Edge[] = [];
    let y = 16;
    const stepY = 86;

    if (primaryId) {
      const el = bundle.index.elementById.get(primaryId);
      const binding = bundle.index.bindingByElement.get(primaryId);
      const rawMatch = bundle.index.inferredRawByElement.get(primaryId);
      const role = bundle.index.roleByElement.get(primaryId);
      const recs = bundle.index.recordsByElement.get(primaryId) ?? [];

      // 1. Raw table row (if inferred)
      if (rawMatch) {
        ns.push({
          id: "node-raw",
          type: "lineageCard",
          position: { x: 24, y },
          data: {
            badge: `Raw Table · ${rawMatch.rawTable}`,
            title: rawMatch.rawKeyLabels.join(", "),
            subtitle: `row ${rawMatch.rawRows.join(", ")} · matched via ${rawMatch.matchedColumns.join(", ")}`,
            status: rawMatch.status,
            accent: "var(--st-warn)",
          },
        });
        y += stepY;
      }

      // 2. Built layer binding
      if (binding && binding.table) {
        ns.push({
          id: "node-built",
          type: "lineageCard",
          position: { x: 24, y },
          data: {
            badge: `Checked Binding · ${binding.table}`,
            title: `${binding.table}[row = ${binding.row}]`,
            subtitle: `dev ${binding.dev?.toFixed(3) ?? "—"} pt · leaf ${binding.leaf ?? "—"}`,
            status: binding.status,
            accent: statusAccent(binding.status),
          },
        });
        if (rawMatch) {
          es.push({
            id: "e-raw-built",
            source: "node-raw",
            target: "node-built",
            style: { stroke: "var(--st-warn)", strokeDasharray: "4 3" },
          });
        }
        y += stepY;
      }

      // 3. SVG Element Substrate
      if (el) {
        ns.push({
          id: "node-el",
          type: "lineageCard",
          position: { x: 24, y },
          data: {
            badge: `SVG Substrate · ${el.panel ?? "chrome"}`,
            title: `${el.tag}#${el.id}`,
            subtitle: role
              ? `role: ${role.role ?? "—"} (${role.kind ?? "—"}) · rule: ${role.rule ?? "—"}`
              : `leaf ${el.leaf ?? "—"}`,
            status: role?.status ?? "captured",
            accent: "var(--st-focus)",
            elementId: el.id,
          },
        });
        if (binding && binding.table) {
          es.push({
            id: "e-built-el",
            source: "node-built",
            target: "node-el",
            animated: binding.status === "verified",
            style: { stroke: statusAccent(binding.status), strokeWidth: 2 },
          });
        }
        y += stepY;
      }

      // 4. Anchored Semantic Records
      recs.forEach((rec, idx) => {
        const nid = `node-rec-${rec.id}`;
        ns.push({
          id: nid,
          type: "lineageCard",
          position: { x: 24 + (idx % 2) * 18, y },
          data: {
            badge: `${rec.layer} · ${rec.workbenchStage}`,
            title: (rec.body.text ?? rec.body.description ?? rec.body.type ?? rec.id).slice(0, 64),
            subtitle: [
              `by ${rec.provenance.by}`,
              rec.body.source ? `src: ${rec.body.source}` : null,
              rec.check ? `check:${rec.check.kind}=${rec.check.status}` : null,
            ]
              .filter(Boolean)
              .join(" · "),
            status: rec.projectionStatus,
            accent: statusAccent(rec.projectionStatus),
            recordId: rec.id,
          },
        });
        if (rec.depends_on.length > 0) {
          for (const dep of rec.depends_on) {
            if (recs.some((r) => r.id === dep)) {
              es.push({
                id: `e-dep-${dep}-${rec.id}`,
                source: `node-rec-${dep}`,
                target: nid,
                style: { stroke: "var(--st-focus)", strokeWidth: 1.5 },
              });
            }
          }
        } else if (el) {
          es.push({
            id: `e-el-${rec.id}`,
            source: "node-el",
            target: nid,
            animated: rec.projectionStatus === "verified",
            style: { stroke: statusAccent(rec.projectionStatus) },
          });
        }
        y += stepY;
      });

      // 5. Attached Operations
      const ops = bundle.operations.specs.filter((op) => op.targets.includes(primaryId));
      if (ops.length > 0) {
        ns.push({
          id: "node-ops",
          type: "lineageCard",
          position: { x: 24, y },
          data: {
            badge: "Behavior Operations",
            title: ops.map((o) => o.op).join(" + "),
            subtitle: ops.find((o) => o.text)?.text ?? `${ops.length} materialised operation(s)`,
            status: "active",
            accent: "var(--st-focus)",
          },
        });
        const parentNode = recs.length > 0 ? `node-rec-${recs[recs.length - 1].id}` : "node-el";
        es.push({
          id: "e-to-ops",
          source: parentNode,
          target: "node-ops",
          style: { stroke: "var(--st-focus)" },
        });
      }
    } else {
      // Figure-level lineage overview
      ns.push({
        id: "fig-root",
        type: "lineageCard",
        position: { x: 24, y },
        data: {
          badge: `Figure Substrate · ${bundle.engine ?? "svg"}`,
          title: bundle.sourceName,
          subtitle: `${bundle.substrate.elements.length} elements · ${bundle.derived.bindingsElements.length} bindings`,
          status: bundle.integrity.mismatches.length === 0 ? "verified" : "failed",
          accent: "var(--st-focus)",
        },
      });
      y += stepY;

      bundle.records.slice(0, 12).forEach((rec) => {
        const nid = `node-rec-${rec.id}`;
        ns.push({
          id: nid,
          type: "lineageCard",
          position: { x: 24, y },
          data: {
            badge: `${rec.layer} · ${rec.resolvedTargets.join(",") || "figure"}`,
            title: (rec.body.text ?? rec.body.description ?? rec.id).slice(0, 64),
            subtitle: `by ${rec.provenance.by}${rec.check ? ` · ${rec.check.kind}:${rec.check.status}` : ""}`,
            status: rec.projectionStatus,
            accent: statusAccent(rec.projectionStatus),
            recordId: rec.id,
          },
        });
        es.push({
          id: `e-fig-${rec.id}`,
          source: "fig-root",
          target: nid,
          animated: rec.projectionStatus === "verified",
          style: { stroke: statusAccent(rec.projectionStatus) },
        });
        y += stepY;
      });
    }

    return { nodes: ns, edges: es };
  }, [bundle, primaryId]);

  if (!bundle) return null;

  return (
    <div className="h-full w-full">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        nodeTypes={nodeTypes}
        fitView
        fitViewOptions={{ padding: 0.18 }}
        proOptions={{ hideAttribution: true }}
        onNodeClick={(_e, node) => {
          if (node.data.recordId) selectRecord(node.data.recordId);
          else if (node.data.elementId) selectElement(node.data.elementId);
        }}
      >
        <Background gap={16} size={1} color="var(--border-subtle)" />
        <Controls showInteractive={false} />
      </ReactFlow>
    </div>
  );
};
