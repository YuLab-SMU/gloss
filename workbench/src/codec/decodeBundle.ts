import {
  asArray,
  asRecord,
  asStringArray,
  bytesToBase64,
  bytesToUtf8,
  byteUnshuffle,
  inflateZlib,
  sha256Hex,
  unpackGlossPayload,
} from "./binary";
import { decodeDataFrame, decodeVectorPlain, dfToObjects, unprepJson } from "./df";
import type {
  DecodedColumn,
  DecodedDataFrame,
  DenseDescriptor,
  GlossAnchor,
  GlossAnchorResolution,
  GlossBindingElement,
  GlossBindingLeaf,
  GlossBundle,
  GlossCheck,
  GlossCheckGroup,
  GlossContextItem,
  GlossElement,
  GlossLayerEvent,
  GlossLayerState,
  GlossLeaf,
  GlossOperations,
  GlossOperationSpec,
  GlossPanel,
  GlossRecord,
  GlossRecordBody,
  GlossRoleElement,
  GlossRoleLeaf,
  GlossTable,
  GlossTableMeta,
  InferredRawMatch,
  IntegrityReport,
  SemanticStageId,
} from "./types";

const SUPPORTED_MAJOR_VERSION = 0;

/**
 * Extract `<script type="application/json" id="gloss-bundle">...</script>` from HTML or SVG text.
 */
export function extractEmbeddedPayload(text: string): {
  header: Record<string, unknown>;
  payload: string;
} | null {
  const match = text.match(/<script[^>]*id=["']gloss-bundle["'][^>]*>([\s\S]*?)<\/script>/i);
  if (!match) return null;
  const obj = JSON.parse(match[1]) as Record<string, unknown>;
  if (obj.format !== "gloss-bundle-embed" || typeof obj.payload !== "string") {
    return null;
  }
  return { header: obj, payload: obj.payload };
}

export function parseSvgViewBox(svgText: string): {
  x: number;
  y: number;
  width: number;
  height: number;
} {
  const vb = svgText.match(/viewBox=["']([^"']+)["']/i);
  if (vb) {
    const nums = vb[1]
      .trim()
      .split(/[\s,]+/)
      .map(Number);
    if (nums.length === 4 && nums.every(Number.isFinite)) {
      return { x: nums[0], y: nums[1], width: nums[2], height: nums[3] };
    }
  }
  const wm = svgText.match(/\bwidth=["']([\d.]+)(pt|px)?["']/i);
  const hm = svgText.match(/\bheight=["']([\d.]+)(pt|px)?["']/i);
  const w = wm ? Number(wm[1]) : 576;
  const h = hm ? Number(hm[1]) : 360;
  return { x: 0, y: 0, width: w, height: h };
}

/**
 * Decode `substrate/index.bin` matching `decode_dense_index()` in R/core-bundle.R:197-225.
 */
async function decodeDenseIndex(
  bytes: Uint8Array,
  descriptors: DenseDescriptor[]
): Promise<Map<string, GlossElement[]>> {
  const raw = await inflateZlib(bytes);
  const out = new Map<string, GlossElement[]>();
  let pos = 0;

  for (const d of descriptors) {
    const n = Number(d.n);
    const readCol = (k: number): Int32Array => {
      const start = pos + 4 * n * (k - 1);
      const unshuffled = byteUnshuffle(raw.subarray(start, start + 4 * n), 4);
      const view = new DataView(
        unshuffled.buffer,
        unshuffled.byteOffset,
        unshuffled.byteLength
      );
      const arr = new Int32Array(n);
      for (let i = 0; i < n; i += 1) {
        arr[i] = view.getInt32(i * 4, true);
      }
      return arr;
    };

    const x0 = readCol(1);
    const y0 = readCol(2);
    const w = readCol(3);
    const h = readCol(4);
    const tagIdx = readCol(5);
    const styleIdx = readCol(6);
    pos += 24 * n;

    const firstNum = Number(String(d.first_id).replace(/^e/, ""));
    const tags = asStringArray(d.tags);
    const stylesFill = d.styles?.fill ?? [];
    const stylesStroke = d.styles?.stroke ?? [];

    const els: GlossElement[] = new Array(n);
    for (let i = 0; i < n; i += 1) {
      const ti = tagIdx[i] - 1;
      const si = styleIdx[i] - 1;
      els[i] = {
        id: `e${firstNum + i}`,
        stable_id: null,
        leaf: d.leaf,
        tag: tags[ti] ?? "point",
        ordinal: i + 1,
        x0: x0[i] / 100,
        y0: y0[i] / 100,
        x1: (x0[i] + w[i]) / 100,
        y1: (y0[i] + h[i]) / 100,
        fill: stylesFill[si] ?? null,
        stroke: stylesStroke[si] ?? null,
        text: null,
        panel: null,
        dense: true,
      };
    }
    out.set(d.leaf, els);
  }
  return out;
}

function expandCompactedColumn(
  col: DecodedColumn,
  how: Record<string, unknown>,
  elements: GlossElement[],
  leaves: GlossLeaf[]
): DecodedColumn {
  const mode = String(how.as ?? "");
  if (mode === "index") {
    const ref = String(how.of ?? "elements");
    const ids = ref === "leaves" ? leaves.map((l) => l.id) : elements.map((e) => e.id);
    return {
      ...col,
      rType: "character",
      values: col.values.map((v) => {
        if (typeof v !== "number") return null;
        return ids[v - 1] ?? null;
      }),
    };
  }
  if (mode === "dict") {
    const levels = asStringArray(how.levels);
    return {
      ...col,
      rType: "character",
      values: col.values.map((v) => {
        if (typeof v !== "number") return null;
        return levels[v - 1] ?? null;
      }),
    };
  }
  if (mode === "scaled") {
    const scale = Number(how.scale ?? 1000);
    return {
      ...col,
      rType: "double",
      values: col.values.map((v) => (typeof v === "number" ? v / scale : null)),
    };
  }
  return col;
}

function normalizeCheck(raw: unknown): GlossCheck | null {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  const obj = raw as Record<string, unknown>;
  if (!obj.kind && !obj.status) return null;

  let groups: GlossCheckGroup[] = [];
  if (obj.groups && typeof obj.groups === "object") {
    if ("__df__" in (obj.groups as Record<string, unknown>)) {
      const df = unprepJson(obj.groups) as DecodedDataFrame;
      groups = dfToObjects<GlossCheckGroup>(df);
    } else if (Array.isArray(obj.groups)) {
      groups = obj.groups as GlossCheckGroup[];
    }
  }

  let reason: string | null = null;
  if (typeof obj.reason === "string" && obj.reason.trim()) {
    reason = obj.reason;
  }

  return {
    kind: String(obj.kind ?? "unknown"),
    status: String(obj.status ?? "refused"),
    passed: typeof obj.passed === "boolean" ? obj.passed : null,
    groups,
    reason,
    args: asRecord(obj.args),
    plugin: obj.plugin,
  };
}

function computeProjectionStatus(rec: {
  status: string;
  body: GlossRecordBody;
  check?: GlossCheck | null;
}): string {
  const origin = rec.body.provenance ?? rec.body.origin ?? null;
  if (origin === "speculative" || rec.status === "speculative") return "speculative";
  if (rec.check?.status === "partial") return "partial";
  if (rec.check?.status === "refused") return "uncheckable";
  return rec.status || "proposed";
}

function classifyWorkbenchStage(layer: string, body: GlossRecordBody): SemanticStageId {
  switch (layer) {
    case "structure":
      return "structure";
    case "binding":
      return "binding";
    case "meaning": {
      const isContextual =
        Boolean(body.source) ||
        Boolean(body.source_type) ||
        body.type === "domain_context" ||
        body.type === "domain_interpretation" ||
        body.type === "contextual_meaning" ||
        body.type === "external_context" ||
        body.provenance === "speculative";
      return isContextual ? "contextual" : "analytical";
    }
    case "relation":
      return "relation";
    case "claim":
      return "claim";
    case "narrative":
      return "narrative";
    case "behavior":
    case "overlay":
      return "behavior";
    default:
      return "contextual";
  }
}

function normalizeRecord(raw: Record<string, unknown>, fallbackLayer: string): GlossRecord {
  const layer = String(raw.layer ?? fallbackLayer);
  const body = asRecord(raw.body) as GlossRecordBody;
  const provRaw = asRecord(raw.provenance);
  const anchors = asArray<Record<string, unknown>>(raw.anchors).map((a) => ({
    selectors: asArray<Record<string, unknown>>(a?.selectors).map((s) => s as GlossAnchor["selectors"][number]),
  }));

  const resolutions: GlossAnchorResolution[] = asArray<Record<string, unknown>>(raw.resolution).map(
    (res) => ({
      status: String(res.status ?? "missing"),
      target: asStringArray(res.target),
      stable_target: asStringArray(res.stable_target),
      data_target: asStringArray(res.data_target),
      candidates: asStringArray(res.candidates),
      selector: res.selector as GlossAnchorResolution["selector"],
      reason: typeof res.reason === "string" ? res.reason : undefined,
    })
  );

  const resolvedTargets = Array.from(
    new Set(resolutions.flatMap((r) => r.target))
  );

  const check = normalizeCheck(raw.check);
  const status = String(raw.status ?? "proposed");
  const projectionStatus = computeProjectionStatus({ status, body, check });

  return {
    id: String(raw.id ?? ""),
    layer,
    anchors,
    body,
    provenance: {
      ...provRaw,
      by: String(provRaw.by ?? "unknown"),
      time: typeof provRaw.time === "string" ? provRaw.time : undefined,
    },
    created: typeof raw.created === "string" ? raw.created : (typeof provRaw.time === "string" ? provRaw.time : null),
    status,
    depends_on: asStringArray(raw.depends_on),
    supersedes: typeof raw.supersedes === "string" ? raw.supersedes : null,
    superseded_by: typeof raw.superseded_by === "string" ? raw.superseded_by : null,
    anchor_status: String(raw.anchor_status ?? "missing"),
    resolution: resolutions,
    check,
    resolvedTargets,
    projectionStatus,
    workbenchStage: classifyWorkbenchStage(layer, body),
  };
}

/**
 * Materialize an append-only JSONL event log matching `materialize_layer()` in R/core-record.R:312-346.
 */
function materializeLayer(layerName: string, rawJsonl: string): GlossLayerState {
  const lines = rawJsonl
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean);

  const events: GlossLayerEvent[] = [];
  const recordMap = new Map<string, GlossRecord>();

  lines.forEach((line, idx) => {
    const ev = JSON.parse(line) as Record<string, unknown>;
    const op = String(ev.op ?? ev.event ?? "add");
    const time = typeof ev.time === "string" ? ev.time : null;
    const targetId = typeof ev.target_id === "string" ? ev.target_id : typeof ev.id === "string" ? ev.id : null;
    const supersedes = typeof ev.supersedes === "string" ? ev.supersedes : null;

    let normalizedRec: GlossRecord | undefined;
    if (op === "add" || op === "revise") {
      const recRaw = (ev.record ?? ev) as Record<string, unknown>;
      if (recRaw && recRaw.id) {
        normalizedRec = normalizeRecord(recRaw, layerName);
        if (op === "revise" && supersedes && recordMap.has(supersedes)) {
          const prev = recordMap.get(supersedes)!;
          prev.status = "superseded";
          prev.superseded_by = normalizedRec.id;
          prev.projectionStatus = computeProjectionStatus(prev);
        }
        recordMap.set(normalizedRec.id, normalizedRec);
      }
    } else if (op === "retract" && targetId && recordMap.has(targetId)) {
      const rec = recordMap.get(targetId)!;
      rec.status = "retracted";
      rec.projectionStatus = computeProjectionStatus(rec);
    } else if ((op === "verify" || op === "rebase") && targetId && recordMap.has(targetId)) {
      const rec = recordMap.get(targetId)!;
      if (typeof ev.status === "string") rec.status = ev.status;
      if (ev.check) rec.check = normalizeCheck(ev.check);
      if (typeof ev.anchor_status === "string") rec.anchor_status = ev.anchor_status;
      if (ev.resolution) {
        const updated = normalizeRecord({ ...rec, resolution: ev.resolution }, layerName);
        rec.resolution = updated.resolution;
        rec.resolvedTargets = updated.resolvedTargets;
      }
      rec.projectionStatus = computeProjectionStatus(rec);
    } else if (op === "rewrite" && targetId && ev.record) {
      normalizedRec = normalizeRecord(ev.record as Record<string, unknown>, layerName);
      recordMap.set(targetId, normalizedRec);
    }

    events.push({
      layer: layerName,
      seq: idx + 1,
      op,
      time,
      target_id: targetId,
      supersedes,
      record: normalizedRec,
      raw: ev,
    });
  });

  return {
    name: layerName,
    events,
    records: Array.from(recordMap.values()),
    rawJsonl,
  };
}

function normalizeOperations(raw: unknown): GlossOperations {
  const obj = asRecord(raw);
  const specs: GlossOperationSpec[] = asArray<Record<string, unknown>>(obj.specs).map((s) => ({
    op: String(s.op ?? ""),
    targets: asStringArray(s.targets),
    from_targets: asStringArray(s.from_targets),
    to_targets: asStringArray(s.to_targets),
    style: typeof s.style === "string" ? s.style : undefined,
    value: typeof s.value === "string" ? s.value : undefined,
    text: typeof s.text === "string" ? s.text : undefined,
    kind: typeof s.kind === "string" ? s.kind : undefined,
    trigger: typeof s.trigger === "string" ? s.trigger : undefined,
    relation: typeof s.relation === "string" ? s.relation : undefined,
    basis: asStringArray(s.basis),
    basis_status: typeof s.basis_status === "string" ? s.basis_status : undefined,
    field: typeof s.field === "string" ? s.field : undefined,
  }));

  const stateRaw = asRecord(obj.state);
  const classesRaw = asRecord<unknown>(stateRaw.classes);
  const classes: Record<string, string[]> = {};
  for (const [k, v] of Object.entries(classesRaw)) classes[k] = asStringArray(v);

  const attrsRaw = asRecord<Record<string, unknown>>(stateRaw.attrs);
  const attrs: Record<string, Record<string, string>> = {};
  for (const [k, v] of Object.entries(attrsRaw)) {
    attrs[k] = {};
    for (const [ak, av] of Object.entries(asRecord(v))) attrs[k][ak] = String(av);
  }

  const stylesRaw = asRecord<Record<string, unknown>>(stateRaw.styles);
  const styles: Record<string, Record<string, string>> = {};
  for (const [k, v] of Object.entries(stylesRaw)) {
    styles[k] = {};
    for (const [sk, sv] of Object.entries(asRecord(v))) styles[k][sk] = String(sv);
  }

  const visibility: Record<string, boolean> = {};
  for (const [k, v] of Object.entries(asRecord(stateRaw.visibility))) visibility[k] = Boolean(v);

  const order: Record<string, string> = {};
  for (const [k, v] of Object.entries(asRecord(stateRaw.order))) order[k] = String(v);

  const tooltips: Record<string, string> = {};
  for (const [k, v] of Object.entries(asRecord(stateRaw.tooltips))) tooltips[k] = String(v);

  const overlays = asArray<Record<string, unknown>>(stateRaw.overlays).map((ov) => ({
    kind: String(ov.kind ?? "leader"),
    targets: asStringArray(ov.targets),
    text: String(ov.text ?? ""),
    basis: asStringArray(ov.basis),
    status: String(ov.status ?? "unverified"),
  }));

  const links = asArray<Record<string, unknown>>(stateRaw.links).map((lk) => ({
    from: String(lk.from ?? ""),
    to: String(lk.to ?? ""),
    relation: String(lk.relation ?? "related"),
  }));

  return {
    specs,
    enabled: asStringArray(obj.enabled),
    state: {
      classes,
      attrs,
      styles,
      visibility,
      order,
      overlays,
      links,
      tooltips,
      focus: asStringArray(stateRaw.focus),
    },
  };
}

/**
 * Infer a best-effort built_layer -> raw row correspondence when gloss hasn't persisted one yet.
 * Always tagged as "inferred" or "ambiguous", never presented as code-verified.
 */
function inferRawJoins(
  bindings: GlossBindingElement[],
  tables: Record<string, GlossTable>
): Map<string, InferredRawMatch> {
  const out = new Map<string, InferredRawMatch>();
  const rawTable = tables["raw"] ?? Object.values(tables).find((t) => t.meta.role === "raw");
  if (!rawTable?.data || rawTable.data.nrow === 0) return out;

  const rawDf = rawTable.data;
  const numericRawCols = rawDf.names.filter((nm) => {
    const t = rawDf.columns[nm]?.rType;
    return t === "double" || t === "integer";
  });

  // Pair aesthetic names (`x`, `y`) to referenced numeric columns of raw when possible
  const referencedNumeric = rawTable.meta.referenced.filter((nm) => numericRawCols.includes(nm));
  const candidatePairs: Array<[string, string]> = [];
  if (referencedNumeric.length >= 2) {
    candidatePairs.push([referencedNumeric[0], referencedNumeric[1]]);
    candidatePairs.push([referencedNumeric[1], referencedNumeric[0]]);
  }

  for (const b of bindings) {
    if (!b.table || !b.row || b.status === "unbound") continue;
    const built = tables[b.table];
    if (!built?.data) continue;
    const builtRowIdx = b.row - 1;
    if (builtRowIdx < 0 || builtRowIdx >= built.data.nrow) continue;

    // 1. Direct exact match if built table shares exact key columns with raw
    const rawKeyCols = rawTable.meta.key.filter((k) => k !== ".rownames" && built.data!.columns[k]);
    if (rawKeyCols.length > 0) {
      const hits: number[] = [];
      for (let r = 0; r < rawDf.nrow; r += 1) {
        const allEq = rawKeyCols.every(
          (k) => rawDf.columns[k].values[r] === built.data!.columns[k].values[builtRowIdx]
        );
        if (allEq) hits.push(r + 1);
      }
      if (hits.length > 0) {
        out.set(b.element, {
          rawTable: rawTable.meta.name,
          rawRows: hits,
          rawKeyLabels: hits.map((r) => rawKeyLabel(rawTable, r - 1)),
          status: hits.length === 1 ? "inferred" : "ambiguous",
          matchedColumns: rawKeyCols,
        });
        continue;
      }
    }

    // 2. Match built (x, y) against referenced numeric column pair in raw (e.g., wt & mpg in mtcars)
    const bx = built.data.columns["x"]?.values[builtRowIdx];
    const by = built.data.columns["y"]?.values[builtRowIdx];
    if (typeof bx === "number" && typeof by === "number" && candidatePairs.length > 0) {
      for (const [colX, colY] of candidatePairs) {
        const vx = rawDf.columns[colX]?.values;
        const vy = rawDf.columns[colY]?.values;
        if (!vx || !vy) continue;
        const hits: number[] = [];
        for (let r = 0; r < rawDf.nrow; r += 1) {
          const rx = vx[r];
          const ry = vy[r];
          if (
            typeof rx === "number" &&
            typeof ry === "number" &&
            Math.abs(rx - bx) < 1e-7 &&
            Math.abs(ry - by) < 1e-7
          ) {
            hits.push(r + 1);
          }
        }
        if (hits.length > 0) {
          out.set(b.element, {
            rawTable: rawTable.meta.name,
            rawRows: hits,
            rawKeyLabels: hits.map((r) => rawKeyLabel(rawTable, r - 1)),
            status: hits.length === 1 ? "inferred" : "ambiguous",
            matchedColumns: [`x≈${colX}`, `y≈${colY}`],
          });
          break;
        }
      }
    }
  }
  return out;
}

export function rawKeyLabel(table: GlossTable, rowIdx0: number): string {
  const df = table.data;
  if (!df) return `row ${rowIdx0 + 1}`;
  const keys = table.meta.key;
  if (keys.includes(".rownames") && df.rownames && df.rownames[rowIdx0]) {
    return df.rownames[rowIdx0];
  }
  const parts = keys
    .filter((k) => k !== ".rownames" && df.columns[k])
    .map((k) => `${k}=${String(df.columns[k].values[rowIdx0] ?? "NA")}`);
  return parts.length ? parts.join(" · ") : `row ${rowIdx0 + 1}`;
}

/**
 * Decode a complete gloss bundle from a virtual file map (unpacked single-file OR dropped `.gloss/` directory).
 */
export async function decodeFileMap(
  files: Map<string, Uint8Array>,
  sourceName: string,
  sourceKind: GlossBundle["sourceKind"] = "directory"
): Promise<GlossBundle> {
  const required = ["manifest.json", "substrate/scene.svg", "substrate/elements.json"];
  const missing = required.filter((k) => !files.has(k));
  if (missing.length > 0) {
    throw new Error(`Not a valid gloss bundle: missing ${missing.join(", ")}.`);
  }

  const manifestRaw = JSON.parse(bytesToUtf8(files.get("manifest.json")!)) as Record<string, unknown>;
  if (manifestRaw.format !== "gloss-bundle") {
    throw new Error(`Unsupported bundle format: ${String(manifestRaw.format)}.`);
  }
  const formatVersion = String(manifestRaw.format_version ?? "0.0.0");
  const major = Number(formatVersion.split(".")[0]);
  if (Number.isFinite(major) && major !== SUPPORTED_MAJOR_VERSION) {
    throw new Error(
      `Bundle format version ${formatVersion} (major ${major}) is not supported by this workbench (supports 0.x).`
    );
  }

  // 1. Verify SHA-256 hashes listed in manifest
  const manifestFiles = asArray<Record<string, unknown>>(manifestRaw.files);
  const mismatches: string[] = [];
  let checked = 0;
  let skipped = false;
  const fileStats: Array<{ path: string; bytes: number; sha256?: string }> = [];

  for (const mf of manifestFiles) {
    const path = String(mf.path ?? "");
    const expectedSha = typeof mf.sha256 === "string" ? mf.sha256 : undefined;
    const bytes = files.get(path);
    fileStats.push({ path, bytes: bytes?.byteLength ?? Number(mf.bytes ?? 0), sha256: expectedSha });
    if (!bytes) {
      mismatches.push(path);
      checked += 1;
      continue;
    }
    if (expectedSha) {
      const actualSha = await sha256Hex(bytes);
      if (actualSha === null) {
        skipped = true;
      } else {
        checked += 1;
        if (actualSha !== expectedSha) mismatches.push(path);
      }
    }
  }
  const integrity: IntegrityReport = {
    checked,
    passed: checked - mismatches.length,
    mismatches,
    skipped,
  };

  // 2. Decode metadata & plugins
  const metaRaw = asRecord(manifestRaw.meta);
  const meta: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(metaRaw)) {
    meta[k] = decodeVectorPlain(v);
  }
  const pluginsUnprepped = unprepJson(manifestRaw.plugins);
  const plugins =
    pluginsUnprepped && typeof pluginsUnprepped === "object" && "nrow" in (pluginsUnprepped as Record<string, unknown>)
      ? dfToObjects(pluginsUnprepped as DecodedDataFrame)
      : [];

  // 3. Decode substrate: elements, leaves, panels, rasters, dense index, scene SVG
  const elementsDoc = unprepJson(
    JSON.parse(bytesToUtf8(files.get("substrate/elements.json")!))
  ) as Record<string, unknown>;

  const leavesDf = elementsDoc.leaves as DecodedDataFrame;
  const leaves: GlossLeaf[] = leavesDf ? dfToObjects<GlossLeaf>(leavesDf) : [];
  const leafById = new Map<string, GlossLeaf>();
  leaves.forEach((l) => leafById.set(l.id, l));

  const panelsDf = elementsDoc.panels as DecodedDataFrame;
  const panels: GlossPanel[] = panelsDf ? dfToObjects<GlossPanel>(panelsDf) : [];
  const panelById = new Map<string, GlossPanel>();
  panels.forEach((p) => panelById.set(p.id, p));

  const sparseElementsDf = elementsDoc.elements as DecodedDataFrame;
  const sparseElements: GlossElement[] = sparseElementsDf
    ? dfToObjects<GlossElement>(sparseElementsDf)
    : [];

  const denseDescriptors: DenseDescriptor[] = asArray<Record<string, unknown>>(
    elementsDoc.dense
  ).map((d) => {
    const stylesDf = d.styles as DecodedDataFrame | Record<string, unknown>;
    let fill: Array<string | null> = [];
    let stroke: Array<string | null> = [];
    if (stylesDf && "columns" in stylesDf && (stylesDf as DecodedDataFrame).columns) {
      const sdf = stylesDf as DecodedDataFrame;
      fill = (sdf.columns.fill?.values ?? []) as Array<string | null>;
      stroke = (sdf.columns.stroke?.values ?? []) as Array<string | null>;
    }
    return {
      leaf: String(d.leaf ?? ""),
      n: Number(d.n ?? 0),
      first: Number(d.first ?? 1),
      first_id: String(d.first_id ?? "e1"),
      columns: asStringArray(d.columns),
      encoding: String(d.encoding ?? ""),
      unit: String(d.unit ?? "1/100 pt"),
      tags: asStringArray(d.tags),
      styles: { fill, stroke },
    };
  });

  let elements: GlossElement[] = sparseElements;
  if (denseDescriptors.length > 0 && files.has("substrate/index.bin")) {
    const denseMap = await decodeDenseIndex(files.get("substrate/index.bin")!, denseDescriptors);
    const nTotal = Number(elementsDoc.n_elements ?? sparseElements.length);
    const full = new Array<GlossElement>(nTotal);
    const elementRows = asArray<number>(elementsDoc.element_rows);
    elementRows.forEach((r1, i) => {
      if (sparseElements[i]) full[r1 - 1] = sparseElements[i];
    });
    for (const d of denseDescriptors) {
      const chunk = denseMap.get(d.leaf) ?? [];
      for (let i = 0; i < chunk.length; i += 1) {
        full[d.first - 1 + i] = chunk[i];
      }
    }
    elements = full.filter(Boolean);
  }

  // Attach panel id from each element's leaf for O(1) queries
  elements.forEach((el) => {
    if (!el.panel && el.leaf) {
      el.panel = leafById.get(el.leaf)?.panel ?? null;
    }
  });

  const rasters: Record<string, string> = {};
  for (const [path, bytes] of files.entries()) {
    const m = path.match(/^substrate\/raster\/(.+)\.png$/);
    if (m) {
      rasters[m[1]] = `data:image/png;base64,${bytesToBase64(bytes)}`;
    }
  }

  let sceneSvg = bytesToUtf8(files.get("substrate/scene.svg")!).replace(/^<\?xml[^>]*>\s*/i, "");
  for (const [leafId, uri] of Object.entries(rasters)) {
    sceneSvg = sceneSvg
      .replaceAll(`raster/${leafId}.png`, uri)
      .replaceAll(`gloss-raster:${leafId}`, uri);
  }
  const viewBox = parseSvgViewBox(sceneSvg);

  // 4. Decode tables (raw tables first so shared column refs resolve cleanly)
  const tablePaths = Array.from(files.keys()).filter((p) => /^substrate\/tables\/.+\.json$/.test(p));
  const parsedTables = tablePaths.map((p) => {
    const obj = JSON.parse(bytesToUtf8(files.get(p)!)) as Record<string, unknown>;
    const rawMeta = unprepJson(obj.table) as Record<string, unknown>;
    return { path: p, obj, rawMeta };
  });
  parsedTables.sort((a, b) => (a.rawMeta.role === "raw" ? 0 : 1) - (b.rawMeta.role === "raw" ? 0 : 1));

  const tables: Record<string, GlossTable> = {};
  for (const { obj, rawMeta } of parsedTables) {
    const name = String(rawMeta.name ?? "");
    let data: DecodedDataFrame | null = null;
    if (obj.columns) {
      data = decodeDataFrame(obj as unknown as Parameters<typeof decodeDataFrame>[0], (ref) => {
        const src = tables[ref.table]?.data;
        return src?.columns[ref.column] ?? null;
      });
    }
    const embedded = String(rawMeta.embedded ?? (data ? "all" : "none"));
    let status = String(rawMeta.status ?? "ok");
    if (!data) status = "missing_data";
    else if (embedded === "columns") status = "partial_data";

    const tMeta: GlossTableMeta = {
      name,
      role: String(rawMeta.role ?? "built"),
      layer: typeof rawMeta.layer === "number" ? rawMeta.layer : null,
      description: typeof rawMeta.description === "string" ? rawMeta.description : null,
      referenced: asStringArray(rawMeta.referenced),
      key: asStringArray(rawMeta.key),
      key_rule: typeof rawMeta.key_rule === "number" ? rawMeta.key_rule : null,
      key_basis: typeof rawMeta.key_basis === "string" ? rawMeta.key_basis : null,
      key_fragile: Boolean(rawMeta.key_fragile),
      status,
      embedded,
      dropped: asStringArray(rawMeta.dropped),
      not_stored: asStringArray(rawMeta.not_stored),
      nrow: data ? data.nrow : Number(rawMeta.nrow ?? 0),
      columnNames: data ? data.names : asStringArray(rawMeta.columns),
      summary: rawMeta.summary,
    };
    tables[name] = { meta: tMeta, data };
  }

  const manifestTableOrder = asStringArray(manifestRaw.tables);
  const tableOrder = manifestTableOrder.length
    ? manifestTableOrder.filter((n) => Boolean(tables[n]))
    : Object.keys(tables);

  // 5. Decode derived tables (bindings, roles, etc.) with compaction expansion
  const rawDerived: Record<string, Record<string, DecodedDataFrame>> = {};
  for (const [path, bytes] of files.entries()) {
    const m = path.match(/^substrate\/derived\/([^/]+)\/([^/]+)\.json$/);
    if (!m) continue;
    const [, dName, tName] = m;
    const parsed = JSON.parse(bytesToUtf8(bytes)) as Record<string, unknown>;
    const df = decodeDataFrame(parsed as unknown as Parameters<typeof decodeDataFrame>[0]);
    const derivedMeta = asRecord(parsed.derived);
    const compact = asRecord<Record<string, unknown>>(derivedMeta.compact);
    for (const [colName, how] of Object.entries(compact)) {
      if (df.columns[colName]) {
        df.columns[colName] = expandCompactedColumn(df.columns[colName], how, elements, leaves);
      }
    }
    if (!rawDerived[dName]) rawDerived[dName] = {};
    rawDerived[dName][tName] = df;
  }

  const bindingsElements = rawDerived.bindings?.elements
    ? dfToObjects<GlossBindingElement>(rawDerived.bindings.elements)
    : [];
  const bindingsLeaves = rawDerived.bindings?.leaves
    ? dfToObjects<GlossBindingLeaf>(rawDerived.bindings.leaves)
    : [];
  const rolesElements = rawDerived.roles?.elements
    ? dfToObjects<GlossRoleElement>(rawDerived.roles.elements)
    : [];
  const rolesLeaves = rawDerived.roles?.leaves
    ? dfToObjects<GlossRoleLeaf>(rawDerived.roles.leaves)
    : [];

  // 6. Decode context.json
  const context: Record<string, GlossContextItem> = {};
  if (files.has("context.json")) {
    const ctxRaw = unprepJson(JSON.parse(bytesToUtf8(files.get("context.json")!))) as Record<
      string,
      Record<string, unknown>
    >;
    for (const [k, v] of Object.entries(asRecord<Record<string, unknown>>(ctxRaw))) {
      context[k] = {
        item: String(v.item ?? k),
        plugin: String(v.plugin ?? k),
        version: String(v.version ?? "0.1.0"),
        found: Boolean(v.found),
        value: v.value ?? null,
        reason: typeof v.reason === "string" ? v.reason : null,
      };
    }
  }

  // 7. Decode and materialize layers/*.jsonl
  const layers: Record<string, GlossLayerState> = {};
  const allRecords: GlossRecord[] = [];
  for (const [path, bytes] of files.entries()) {
    const m = path.match(/^layers\/(.+)\.jsonl$/);
    if (!m) continue;
    const layerName = m[1];
    const state = materializeLayer(layerName, bytesToUtf8(bytes));
    layers[layerName] = state;
    allRecords.push(...state.records);
  }

  // 8. Decode projections/operations.json
  const operations = files.has("projections/operations.json")
    ? normalizeOperations(JSON.parse(bytesToUtf8(files.get("projections/operations.json")!)))
    : normalizeOperations({});

  // 9. Build O(1) lookup indices
  const elementById = new Map<string, GlossElement>();
  elements.forEach((e) => elementById.set(e.id, e));

  const bindingByElement = new Map<string, GlossBindingElement>();
  const elementsByTableRow = new Map<string, string[]>();
  bindingsElements.forEach((b) => {
    bindingByElement.set(b.element, b);
    if (b.table && b.row !== null && b.row !== undefined) {
      const k = `${b.table}:${b.row}`;
      const list = elementsByTableRow.get(k);
      if (list) list.push(b.element);
      else elementsByTableRow.set(k, [b.element]);
    }
  });

  const roleByElement = new Map<string, GlossRoleElement>();
  rolesElements.forEach((r) => roleByElement.set(r.element, r));

  const recordById = new Map<string, GlossRecord>();
  const recordsByElement = new Map<string, GlossRecord[]>();
  allRecords.forEach((rec) => {
    recordById.set(rec.id, rec);
    for (const eid of rec.resolvedTargets) {
      const list = recordsByElement.get(eid);
      if (list) list.push(rec);
      else recordsByElement.set(eid, [rec]);
    }
  });

  const inferredRawByElement = inferRawJoins(bindingsElements, tables);
  // Also index inferred raw rows so clicking a row in the `raw` AG Grid highlights its SVG elements!
  for (const [eid, match] of inferredRawByElement.entries()) {
    for (const r of match.rawRows) {
      const k = `${match.rawTable}:${r}`;
      const list = elementsByTableRow.get(k);
      if (list) {
        if (!list.includes(eid)) list.push(eid);
      } else {
        elementsByTableRow.set(k, [eid]);
      }
    }
  }

  return {
    sourceName,
    sourceKind,
    formatVersion,
    glossVersion: typeof manifestRaw.gloss_version === "string" ? manifestRaw.gloss_version : null,
    apiVersion: typeof manifestRaw.api_version === "string" ? manifestRaw.api_version : null,
    substrateId: typeof manifestRaw.substrate_id === "string" ? manifestRaw.substrate_id : null,
    engine: typeof manifestRaw.engine === "string" ? manifestRaw.engine : null,
    embed: typeof manifestRaw.embed === "string" ? manifestRaw.embed : null,
    meta,
    plugins,
    status: asRecord(manifestRaw.status),
    integrity,
    context,
    substrate: {
      sceneSvg,
      viewBox,
      leaves,
      elements,
      panels,
      rasters,
      denseDescriptors,
    },
    tables,
    tableOrder,
    derived: {
      bindingsElements,
      bindingsLeaves,
      rolesElements,
      rolesLeaves,
      rawDerived,
    },
    layers,
    records: allRecords,
    operations,
    index: {
      elementById,
      leafById,
      panelById,
      bindingByElement,
      roleByElement,
      recordsByElement,
      recordById,
      elementsByTableRow,
      inferredRawByElement,
    },
    files: fileStats,
  };
}

/**
 * Decode an embedded `<script type="application/json" id="gloss-bundle">` JSON string directly
 * (used by single-file workbench HTML without re-wrapping in a script tag).
 */
export async function decodeEmbeddedJsonText(
  jsonText: string,
  sourceName = "artifact.html"
): Promise<GlossBundle> {
  const obj = JSON.parse(jsonText) as Record<string, unknown>;
  if (obj.format !== "gloss-bundle-embed" || typeof obj.payload !== "string") {
    throw new Error(`${sourceName} has an invalid embedded gloss bundle header.`);
  }
  const files = await unpackGlossPayload(obj.payload);
  const kind = sourceName.toLowerCase().endsWith(".svg") ? "embedded-svg" : "embedded-html";
  return decodeFileMap(files, sourceName, kind);
}

/**
 * Decode an HTML or SVG artifact string.
 * If `<script id="gloss-bundle">` is present, decodes the full lossless bundle.
 * Otherwise, if `<svg ...>` is present, degrades transparently to Geometry-Only mode.
 */
export async function decodeArtifactText(
  text: string,
  sourceName = "artifact.html"
): Promise<GlossBundle> {
  const embedded = extractEmbeddedPayload(text);
  if (embedded) {
    const files = await unpackGlossPayload(embedded.payload);
    const kind = sourceName.toLowerCase().endsWith(".svg") ? "embedded-svg" : "embedded-html";
    return decodeFileMap(files, sourceName, kind);
  }

  const svgMatch = text.match(/<svg[\s>][\s\S]*<\/svg>/i);
  if (svgMatch) {
    const sceneSvg = svgMatch[0];
    const viewBox = parseSvgViewBox(sceneSvg);
    return {
      sourceName,
      sourceKind: "plain-svg",
      formatVersion: null,
      glossVersion: null,
      apiVersion: null,
      substrateId: null,
      engine: null,
      embed: null,
      meta: {},
      plugins: [],
      status: { restored: "geometry only: no embedded gloss bundle found" },
      integrity: { checked: 0, passed: 0, mismatches: [], skipped: true },
      context: {},
      substrate: {
        sceneSvg,
        viewBox,
        leaves: [],
        elements: [],
        panels: [],
        rasters: {},
        denseDescriptors: [],
      },
      tables: {},
      tableOrder: [],
      derived: {
        bindingsElements: [],
        bindingsLeaves: [],
        rolesElements: [],
        rolesLeaves: [],
        rawDerived: {},
      },
      layers: {},
      records: [],
      operations: normalizeOperations({}),
      index: {
        elementById: new Map(),
        leafById: new Map(),
        panelById: new Map(),
        bindingByElement: new Map(),
        roleByElement: new Map(),
        recordsByElement: new Map(),
        recordById: new Map(),
        elementsByTableRow: new Map(),
        inferredRawByElement: new Map(),
      },
      files: [],
    };
  }

  throw new Error(`${sourceName} contains neither an embedded gloss bundle nor an <svg> element.`);
}
