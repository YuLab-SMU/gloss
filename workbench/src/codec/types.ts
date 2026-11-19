export type SemanticStageId =
  | "raw"
  | "structure"
  | "binding"
  | "analytical"
  | "contextual"
  | "relation"
  | "claim"
  | "narrative"
  | "behavior";

export interface StageDefinition {
  id: SemanticStageId;
  index: number;
  label: string;
  shortLabel: string;
  zhLabel: string;
  description: string;
  sourceTrack: "substrate" | "in-figure" | "contextual" | "projection";
}

export const SEMANTIC_STAGES: StageDefinition[] = [
  {
    id: "raw",
    index: 0,
    label: "Raw SVG",
    shortLabel: "Raw",
    zhLabel: "原始图形",
    description: "Untouched graphics device SVG output with zero overlays.",
    sourceTrack: "substrate",
  },
  {
    id: "structure",
    index: 1,
    label: "Structure",
    shortLabel: "Structure",
    zhLabel: "结构层级",
    description: "Captured leaves, viewports, panels, element IDs and role classifications.",
    sourceTrack: "substrate",
  },
  {
    id: "binding",
    index: 2,
    label: "Binding",
    shortLabel: "Binding",
    zhLabel: "数据绑定",
    description: "Checked pairing from SVG elements to built data rows and raw row keys.",
    sourceTrack: "in-figure",
  },
  {
    id: "analytical",
    index: 3,
    label: "Analytical Meaning",
    shortLabel: "Analytical",
    zhLabel: "图内分析语义",
    description: "Data-grounded aesthetic mappings, groups, facets, and direct statistical summaries.",
    sourceTrack: "in-figure",
  },
  {
    id: "contextual",
    index: 4,
    label: "Contextual Meaning",
    shortLabel: "Contextual",
    zhLabel: "图外上下文语义",
    description: "External entity labels, variable units, domain interpretation, ontology & documentation.",
    sourceTrack: "contextual",
  },
  {
    id: "relation",
    index: 5,
    label: "Relation",
    shortLabel: "Relation",
    zhLabel: "图形关系",
    description: "Cross-element, legend-to-series, reference, and cross-panel relationships.",
    sourceTrack: "in-figure",
  },
  {
    id: "claim",
    index: 6,
    label: "Claim",
    shortLabel: "Claim",
    zhLabel: "核验声明",
    description: "Checkable claims executed against built data with group-level pass/exception evidence.",
    sourceTrack: "in-figure",
  },
  {
    id: "narrative",
    index: 7,
    label: "Narrative",
    shortLabel: "Narrative",
    zhLabel: "叙事与无障碍",
    description: "Audience-tailored reading sequence, alt-text, and WAI-ARIA navigation tree.",
    sourceTrack: "projection",
  },
  {
    id: "behavior",
    index: 8,
    label: "Behavior",
    shortLabel: "Behavior",
    zhLabel: "交互行为",
    description: "Active gloss operation vocabulary: tooltip, highlight, focus, overlay, link and select.",
    sourceTrack: "projection",
  },
];

export type RSpecialValue = "NA" | "NaN" | "Inf" | "-Inf";

export interface DecodedColumn {
  name: string;
  rType: string;
  values: Array<string | number | boolean | null | unknown>;
  /** Exact R special markers by row index (so NA vs NaN vs +/-Inf stay distinct). */
  specials: Map<number, RSpecialValue>;
  factorLevels?: string[];
  classes?: string[];
  attrs?: Record<string, unknown>;
}

export interface DecodedDataFrame {
  nrow: number;
  classes: string[];
  names: string[];
  rownames?: string[];
  columns: Record<string, DecodedColumn>;
  attrs?: Record<string, unknown>;
}

export interface GlossTableMeta {
  name: string;
  role: "raw" | "built" | "engine" | string;
  layer: number | null;
  description: string | null;
  referenced: string[];
  key: string[];
  key_rule: number | null;
  key_basis: string | null;
  key_fragile: boolean;
  status: "ok" | "partial_data" | "missing_data" | string;
  embedded: "all" | "columns" | "summary" | "none" | string;
  dropped: string[];
  not_stored: string[];
  nrow: number;
  columnNames: string[];
  summary?: unknown;
}

export interface GlossTable {
  meta: GlossTableMeta;
  data: DecodedDataFrame | null;
}

export interface GlossLeaf {
  id: string;
  name: string;
  path: string;
  class: string;
  vp: string;
  x0: number;
  y0: number;
  x1: number;
  y1: number;
  xscale0: number;
  xscale1: number;
  yscale0: number;
  yscale1: number;
  n_expected: number | null;
  n_drawn: number;
  status: string;
  bindable: boolean;
  dense: boolean;
  panel: string | null;
}

export interface GlossElement {
  id: string;
  stable_id: string | null;
  leaf: string | null;
  tag: string;
  ordinal: number;
  x0: number;
  y0: number;
  x1: number;
  y1: number;
  fill: string | null;
  stroke: string | null;
  text: string | null;
  panel: string | null;
  dense?: boolean;
}

export interface GlossPanel {
  id: string;
  key: string | null;
  vp: string | null;
  x0: number;
  y0: number;
  x1: number;
  y1: number;
  x_type: string | null;
  x_min: number | null;
  x_max: number | null;
  x_trans: string | null;
  y_type: string | null;
  y_min: number | null;
  y_max: number | null;
  y_trans: string | null;
  flipped: boolean;
}

export interface DenseDescriptor {
  leaf: string;
  n: number;
  first: number;
  first_id: string;
  columns: string[];
  encoding: string;
  unit: string;
  tags: string[];
  styles: { fill: Array<string | null>; stroke: Array<string | null> };
}

export interface GlossBindingElement {
  element: string;
  leaf: string | null;
  table: string | null;
  row: number | null;
  n_rows: number | null;
  status: "verified" | "ambiguous" | "failed" | "unbound" | string;
  dev: number | null;
}

export interface GlossBindingLeaf {
  leaf: string;
  table: string | null;
  mode: string | null;
  status: string;
  n_elements: number;
  n_rows: number | null;
  n_groups: number | null;
  verified: number;
  ambiguous: number;
  failed: number;
  max_dev: number | null;
  reason: string | null;
}

export interface GlossRoleElement {
  element: string;
  leaf: string | null;
  ordinal: number | null;
  role: string | null;
  kind: string | null;
  cue: string | null;
  rule: string | null;
  status: string | null;
  reason: string | null;
  flagged: boolean;
  flags: string | null;
}

export interface GlossRoleLeaf {
  leaf: string;
  n_elements: number;
  role: string | null;
  kind: string | null;
  status: string | null;
  rule: string | null;
  cue: string | null;
  reason: string | null;
  split: boolean;
  flagged: boolean;
  flags: string | null;
}

export interface GlossAnchorSelector {
  type: string;
  id?: string;
  table?: string;
  key?: Record<string, unknown>;
  leaf?: string;
  element?: string;
  role?: string;
  [k: string]: unknown;
}

export interface GlossAnchor {
  selectors: GlossAnchorSelector[];
}

export interface GlossAnchorResolution {
  status: "unique" | "ambiguous" | "missing" | string;
  target: string[];
  stable_target?: string[];
  data_target?: string[];
  candidates: string[];
  selector?: GlossAnchorSelector;
  reason?: string;
}

export interface GlossCheckGroup {
  group: string;
  n: number;
  estimate?: number | null;
  value?: unknown;
  left?: number | null;
  right?: number | null;
  passed: boolean | null;
  reason?: string | null;
  [k: string]: unknown;
}

export interface GlossCheck {
  kind: string;
  status: "verified" | "failed" | "partial" | "refused" | string;
  passed: boolean | null;
  groups: GlossCheckGroup[];
  reason: string | null;
  args: Record<string, unknown>;
  plugin?: unknown;
}

export interface GlossRecordBody {
  text?: string;
  description?: string;
  alt_text?: string;
  type?: string;
  provenance?: "direct" | "derived" | "speculative" | string;
  origin?: "direct" | "derived" | "speculative" | string;
  source?: string;
  source_type?: string;
  confidence?: number;
  evidence?: unknown;
  rationale?: string;
  check?: { kind: string; table?: string; args?: Record<string, unknown> };
  table?: string;
  trigger?: string;
  operation?: string;
  field?: string;
  from?: unknown;
  to?: unknown;
  role?: string;
  kind?: string;
  label?: string;
  [k: string]: unknown;
}

export interface GlossRecord {
  id: string;
  layer: string;
  anchors: GlossAnchor[];
  body: GlossRecordBody;
  provenance: {
    by: string;
    time?: string;
    stage?: string;
    model?: string;
    run_id?: string;
    prompt_version?: string;
    [k: string]: unknown;
  };
  created: string | null;
  status:
    | "proposed"
    | "verified"
    | "rejected"
    | "superseded"
    | "retracted"
    | "invalid"
    | "speculative"
    | string;
  depends_on: string[];
  supersedes?: string | null;
  superseded_by?: string | null;
  anchor_status: "unique" | "ambiguous" | "missing" | string;
  resolution: GlossAnchorResolution[];
  check?: GlossCheck | null;
  /** Resolved element IDs from resolution[].target (deduplicated). */
  resolvedTargets: string[];
  /** Computed projection status matching R's record_projection_status(). */
  projectionStatus: string;
  /** Which of the 9 workbench stages this record belongs to. */
  workbenchStage: SemanticStageId;
}

export interface GlossLayerEvent {
  layer: string;
  seq: number;
  op: "add" | "revise" | "retract" | "verify" | "rebase" | "rewrite" | string;
  time: string | null;
  target_id?: string | null;
  supersedes?: string | null;
  record?: GlossRecord;
  raw: Record<string, unknown>;
}

export interface GlossLayerState {
  name: string;
  events: GlossLayerEvent[];
  records: GlossRecord[];
  rawJsonl: string;
}

export interface GlossOperationSpec {
  op: string;
  targets: string[];
  from_targets: string[];
  to_targets: string[];
  style?: string;
  value?: string;
  text?: string;
  kind?: string;
  trigger?: string;
  relation?: string;
  basis: string[];
  basis_status?: string;
  field?: string;
}

export interface GlossOperations {
  specs: GlossOperationSpec[];
  enabled: string[];
  state: {
    classes: Record<string, string[]>;
    attrs: Record<string, Record<string, string>>;
    styles: Record<string, Record<string, string>>;
    visibility: Record<string, boolean>;
    order: Record<string, string>;
    overlays: Array<{
      kind: string;
      targets: string[];
      text: string;
      basis: string[];
      status: string;
    }>;
    links: Array<{ from: string; to: string; relation: string }>;
    tooltips: Record<string, string>;
    focus: string[];
  };
}

export interface GlossContextItem {
  item: string;
  plugin: string;
  version: string;
  found: boolean;
  value: unknown;
  reason: string | null;
}

export interface IntegrityReport {
  checked: number;
  passed: number;
  mismatches: string[];
  skipped: boolean;
}

export interface InferredRawMatch {
  rawTable: string;
  rawRows: number[];
  rawKeyLabels: string[];
  status: "inferred" | "ambiguous" | "none";
  matchedColumns: string[];
}

export interface GlossBundle {
  sourceName: string;
  sourceKind: "embedded-html" | "embedded-svg" | "directory" | "plain-svg";
  formatVersion: string | null;
  glossVersion: string | null;
  apiVersion: string | null;
  substrateId: string | null;
  engine: string | null;
  embed: string | null;
  meta: Record<string, unknown>;
  plugins: Array<Record<string, unknown>>;
  status: Record<string, unknown>;
  integrity: IntegrityReport;
  context: Record<string, GlossContextItem>;
  substrate: {
    sceneSvg: string;
    viewBox: { x: number; y: number; width: number; height: number };
    leaves: GlossLeaf[];
    elements: GlossElement[];
    panels: GlossPanel[];
    rasters: Record<string, string>; // leafId -> data URI
    denseDescriptors: DenseDescriptor[];
  };
  tables: Record<string, GlossTable>;
  tableOrder: string[];
  derived: {
    bindingsElements: GlossBindingElement[];
    bindingsLeaves: GlossBindingLeaf[];
    rolesElements: GlossRoleElement[];
    rolesLeaves: GlossRoleLeaf[];
    rawDerived: Record<string, Record<string, DecodedDataFrame>>;
  };
  layers: Record<string, GlossLayerState>;
  records: GlossRecord[];
  operations: GlossOperations;
  /** Fast O(1) lookup indices */
  index: {
    elementById: Map<string, GlossElement>;
    leafById: Map<string, GlossLeaf>;
    panelById: Map<string, GlossPanel>;
    bindingByElement: Map<string, GlossBindingElement>;
    roleByElement: Map<string, GlossRoleElement>;
    recordsByElement: Map<string, GlossRecord[]>;
    recordById: Map<string, GlossRecord>;
    elementsByTableRow: Map<string, string[]>; // `${table}:${row}` -> elementIds
    inferredRawByElement: Map<string, InferredRawMatch>;
  };
  /** Raw unpacked file stats for manifest inspection */
  files: Array<{ path: string; bytes: number; sha256?: string }>;
}
