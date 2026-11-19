import type { GlossBundle, GlossRecord, SemanticStageId } from "./types";

function recordText(rec: GlossRecord): string {
  const txt = rec.body.text ?? rec.body.description ?? rec.body.alt_text ?? "";
  return typeof txt === "string" ? txt : String(txt);
}

function ariaRoleForTag(tag: string): string {
  return tag === "image" ? "img" : "graphics-symbol";
}

export function buildAriaProjection(bundle: GlossBundle): Record<string, unknown> {
  const caption =
    (bundle.context.doc?.value as Record<string, unknown> | null)?.caption ??
    bundle.sourceName ??
    "R figure";

  const panelChildren = bundle.substrate.panels.map((p) => {
    const els = bundle.substrate.elements.filter((e) => e.panel === p.id);
    return {
      role: "graphics-object",
      id: p.id,
      label: `panel ${p.key ?? p.id}`,
      children: els.map((e) => ({
        role: ariaRoleForTag(e.tag),
        id: e.id,
        label: e.text ?? e.tag,
        bbox: {
          x: e.x0,
          y: e.y0,
          width: +(e.x1 - e.x0).toFixed(2),
          height: +(e.y1 - e.y0).toFixed(2),
        },
      })),
    };
  });

  const activeRecords = bundle.records
    .filter((r) => !["rejected", "invalid", "retracted", "superseded"].includes(r.projectionStatus))
    .map((r) => ({
      id: r.id,
      layer: r.layer,
      status: r.projectionStatus,
      text: recordText(r),
      targets: r.resolvedTargets,
      by: r.provenance.by,
      created: r.created,
    }))
    .filter((x) => x.text.length > 0);

  return {
    role: "graphics-document",
    id: bundle.substrateId ?? "gloss-figure",
    label: caption,
    children: panelChildren,
    records: activeRecords,
  };
}

export function buildTextProjection(bundle: GlossBundle): string {
  const caption =
    String((bundle.context.doc?.value as Record<string, unknown> | null)?.caption ?? bundle.sourceName);
  const lines: string[] = [caption, ""];
  if (bundle.substrate.panels.length > 0) {
    lines.push(
      `Panels (${bundle.substrate.panels.length}): ${bundle.substrate.panels
        .map((p) => p.key ?? p.id)
        .join(", ")}.`
    );
  }
  const verifiedBindings = bundle.derived.bindingsElements.filter((b) => b.status === "verified").length;
  lines.push(
    `Substrate: ${bundle.substrate.elements.length} elements across ${bundle.substrate.leaves.length} leaves (${verifiedBindings} verified data bindings).`
  );

  const activeRecords = bundle.records.filter(
    (r) => !["rejected", "invalid", "retracted", "superseded"].includes(r.projectionStatus)
  );
  if (activeRecords.length > 0) {
    lines.push("", "Semantic records:");
    for (const r of activeRecords) {
      const txt = recordText(r);
      if (!txt) continue;
      lines.push(`- [${r.layer} · ${r.projectionStatus}] ${txt}`);
    }
  }
  return lines.join("\n");
}

export function buildWebAnnotationProjection(bundle: GlossBundle): Record<string, unknown> {
  const figId = bundle.substrateId ?? "gloss-figure";
  const items = bundle.records
    .filter((r) => recordText(r).length > 0)
    .map((r) => ({
      id: `#${r.id}`,
      type: "Annotation",
      motivation: r.projectionStatus === "rejected" ? "rejecting" : "commenting",
      body: {
        value: recordText(r),
        format: "text/plain",
        layer: r.layer,
        status: r.projectionStatus,
        ...(r.body.source ? { source: r.body.source } : {}),
        ...(r.body.source_type ? { source_type: r.body.source_type } : {}),
      },
      target: {
        source: figId,
        selector: r.resolvedTargets.map((id) => ({
          type: "FragmentSelector",
          conformsTo: "gloss-element",
          value: `element=${id}`,
        })),
      },
      creator: r.provenance.by,
      generator: "gloss",
      created: r.created,
    }));

  return {
    "@context": "http://www.w3.org/ns/anno.jsonld",
    type: "AnnotationPage",
    partOf: { id: figId },
    items,
  };
}

export interface StageStatusSummary {
  stage: SemanticStageId;
  populated: boolean;
  count: number;
  verifiedCount: number;
  warningCount: number; // ambiguous / partial / proposed
  failedCount: number; // rejected / failed / broken
}

export function computeStageStats(bundle: GlossBundle): Record<SemanticStageId, StageStatusSummary> {
  const byStage = (st: SemanticStageId) => bundle.records.filter((r) => r.workbenchStage === st);

  const countFromRecords = (st: SemanticStageId, extraBaseCount = 0): StageStatusSummary => {
    const recs = byStage(st);
    const verifiedCount = recs.filter((r) => r.projectionStatus === "verified").length;
    const failedCount = recs.filter(
      (r) =>
        r.projectionStatus === "rejected" ||
        r.projectionStatus === "invalid" ||
        r.anchor_status === "missing"
    ).length;
    const warningCount = recs.filter(
      (r) =>
        r.projectionStatus === "partial" ||
        r.projectionStatus === "proposed" ||
        r.projectionStatus === "speculative" ||
        r.anchor_status === "ambiguous"
    ).length;
    const count = recs.length + extraBaseCount;
    return { stage: st, populated: count > 0, count, verifiedCount, warningCount, failedCount };
  };

  const bEls = bundle.derived.bindingsElements;
  const verifiedBindings = bEls.filter((b) => b.status === "verified").length;
  const ambiguousBindings = bEls.filter((b) => b.status === "ambiguous").length;
  const failedBindings = bEls.filter((b) => b.status === "failed").length;

  const structureRecs = byStage("structure");
  const roleCount = bundle.derived.rolesElements.length + bundle.substrate.leaves.length;

  const contextItemsFound = Object.values(bundle.context).filter((c) => c.found).length;
  const contextualRecs = byStage("contextual");

  const behaviorRecs = byStage("behavior");
  const opCount = bundle.operations.specs.length;

  return {
    raw: {
      stage: "raw",
      populated: bundle.substrate.sceneSvg.length > 0,
      count: bundle.substrate.elements.length,
      verifiedCount: (bundle.meta.page as Record<string, unknown> | undefined)?.verdict === "equal" ? 1 : 0,
      warningCount: 0,
      failedCount: bundle.integrity.mismatches.length,
    },
    structure: {
      stage: "structure",
      populated: roleCount > 0 || structureRecs.length > 0,
      count: bundle.substrate.leaves.length,
      verifiedCount: bundle.derived.rolesElements.filter((r) => r.status === "classified").length,
      warningCount: bundle.derived.rolesElements.filter((r) => r.flagged).length,
      failedCount: 0,
    },
    binding: {
      stage: "binding",
      populated: bEls.length > 0 || byStage("binding").length > 0,
      count: bEls.length + byStage("binding").length,
      verifiedCount: verifiedBindings,
      warningCount: ambiguousBindings,
      failedCount: failedBindings,
    },
    analytical: countFromRecords("analytical", verifiedBindings > 0 ? bundle.tableOrder.length : 0),
    contextual: {
      ...countFromRecords("contextual"),
      populated: contextualRecs.length > 0 || contextItemsFound > 0,
      count: contextualRecs.length,
    },
    relation: countFromRecords("relation", bundle.operations.state.links.length),
    claim: countFromRecords("claim"),
    narrative: countFromRecords("narrative"),
    behavior: {
      stage: "behavior",
      populated: behaviorRecs.length > 0 || opCount > 0,
      count: behaviorRecs.length + opCount,
      verifiedCount: bundle.operations.state.overlays.filter((o) => o.status === "verified").length,
      warningCount: behaviorRecs.filter((r) => r.projectionStatus === "proposed").length,
      failedCount: 0,
    },
  };
}
