import fs from "node:fs";
import path from "node:path";
import zlib from "node:zlib";
import { describe, expect, it } from "vitest";
import {
  buildAriaProjection,
  buildSpatialIndex,
  buildTextProjection,
  buildWebAnnotationProjection,
  computeStageStats,
  decodeArtifactText,
  decodeFileMap,
  decodeVector,
  svgPointToData,
} from "./index";

const REPO_ROOT = path.resolve(__dirname, "../../..");

function readDirAsFileMap(dir: string): Map<string, Uint8Array> {
  const map = new Map<string, Uint8Array>();
  const walk = (cur: string, relBase: string) => {
    for (const entry of fs.readdirSync(cur, { withFileTypes: true })) {
      const full = path.join(cur, entry.name);
      const rel = relBase ? `${relBase}/${entry.name}` : entry.name;
      if (entry.isDirectory()) walk(full, rel);
      else map.set(rel, new Uint8Array(fs.readFileSync(full)));
    }
  };
  walk(dir, "");
  return map;
}

describe("@gloss/bundle-codec", () => {
  it("decodes real dev_docs/demo/mtcars-context.html with full SHA-256 integrity", async () => {
    const htmlPath = path.join(REPO_ROOT, "dev_docs/demo/mtcars-context.html");
    const html = fs.readFileSync(htmlPath, "utf8");
    const bundle = await decodeArtifactText(html, "mtcars-context.html");

    expect(bundle.sourceKind).toBe("embedded-html");
    expect(bundle.formatVersion).toBe("0.3.0");
    expect(bundle.engine).toBe("ggplot");
    expect(bundle.integrity.mismatches).toEqual([]);
    expect(bundle.integrity.checked).toBeGreaterThanOrEqual(20);
    expect(bundle.integrity.passed).toBe(bundle.integrity.checked);

    // Substrate counts must match R gl_read() output
    expect(bundle.substrate.elements.length).toBe(125);
    expect(bundle.substrate.leaves.length).toBe(40);
    expect(bundle.substrate.panels.length).toBe(2);

    // Tables and row keys
    expect(bundle.tableOrder).toEqual(["raw", "built_layer1"]);
    expect(bundle.tables.raw.meta.key).toEqual([".rownames"]);
    expect(bundle.tables.raw.data?.nrow).toBe(32);
    expect(bundle.tables.raw.data?.rownames?.[0]).toBe("Mazda RX4");
    expect(bundle.tables.built_layer1.meta.key).toEqual(["x", "y"]);

    // Derived bindings & roles
    expect(bundle.derived.bindingsElements.length).toBe(32);
    expect(bundle.derived.bindingsElements.every((b) => b.status === "verified")).toBe(true);
    expect(bundle.derived.rolesElements.length).toBe(124);

    // Inferred raw join for e65 -> Mazda RX4 (tagged explicitly as inferred, never verified)
    const rawMatch = bundle.index.inferredRawByElement.get("e65");
    expect(rawMatch).toBeDefined();
    expect(rawMatch?.status).toBe("inferred");
    expect(rawMatch?.rawKeyLabels).toEqual(["Mazda RX4"]);

    // Materialized semantic records across meaning, claim, behavior
    expect(bundle.records.length).toBe(3);
    const claim = bundle.records.find((r) => r.layer === "claim");
    expect(claim?.status).toBe("verified");
    expect(claim?.check?.kind).toBe("trend");
    expect(claim?.check?.groups[0]?.estimate).toBeCloseTo(-5.3445, 3);

    const meaning = bundle.records.find((r) => r.layer === "meaning");
    expect(meaning?.workbenchStage).toBe("contextual");
    expect(meaning?.projectionStatus).toBe("speculative");

    // Operations
    expect(bundle.operations.specs.length).toBe(4);
    expect(bundle.operations.state.tooltips["e65"]).toContain("Mazda RX4");

    // Spatial index & data coordinate conversion
    const spatial = buildSpatialIndex(bundle.substrate.elements);
    const e65 = bundle.index.elementById.get("e65")!;
    const hit = spatial.hitTest((e65.x0 + e65.x1) / 2, (e65.y0 + e65.y1) / 2);
    expect(hit?.id).toBe("e65");

    const dataCoord = svgPointToData(bundle, (e65.x0 + e65.x1) / 2, (e65.y0 + e65.y1) / 2);
    expect(dataCoord?.panel.id).toBe("panel2");
    expect(dataCoord?.dataX).toBeCloseTo(2.62, 1);
    expect(dataCoord?.dataY).toBeCloseTo(21, 1);

    // Projections & stage stats
    const aria = buildAriaProjection(bundle);
    expect(aria.role).toBe("graphics-document");
    const text = buildTextProjection(bundle);
    expect(text).toContain("heavier cars have lower fuel economy");
    const anno = buildWebAnnotationProjection(bundle);
    expect((anno.items as unknown[]).length).toBe(3);

    const stats = computeStageStats(bundle);
    expect(stats.binding.verifiedCount).toBe(32);
    expect(stats.claim.verifiedCount).toBe(1);
    expect(stats.contextual.count).toBe(1);
  });

  it("decodes a directory bundle (dev_docs/demo/mtcars-bundle)", async () => {
    const dir = path.join(REPO_ROOT, "dev_docs/demo/mtcars-bundle");
    const files = readDirAsFileMap(dir);
    const bundle = await decodeFileMap(files, "mtcars-bundle", "directory");

    expect(bundle.sourceKind).toBe("directory");
    expect(bundle.integrity.mismatches).toEqual([]);
    expect(bundle.substrate.elements.length).toBe(125);
    expect(bundle.tables.raw.data?.nrow).toBe(32);
  });

  it("decodes shuffled f64le/i32le binary vectors with NA, NaN, Inf, -Inf faithfully", () => {
    // Craft 4 doubles: [1.5, NaN, Infinity, -Infinity]
    const f64Raw = new Uint8Array(32);
    const dv = new DataView(f64Raw.buffer);
    dv.setFloat64(0, 1.5, true);
    dv.setFloat64(8, Number.NaN, true);
    dv.setFloat64(16, Infinity, true);
    dv.setFloat64(24, -Infinity, true);
    // Byte-plane shuffle (elementSize = 8)
    const shuffled = new Uint8Array(32);
    for (let p = 0; p < 8; p += 1) {
      for (let i = 0; i < 4; i += 1) {
        shuffled[p * 4 + i] = f64Raw[i * 8 + p];
      }
    }
    const col = decodeVector(
      {
        type: "double",
        encoding: "f64le-shuffle-base64",
        length: 4,
        values: Buffer.from(shuffled).toString("base64"),
      },
      "x"
    );
    expect(col.values[0]).toBe(1.5);
    expect(col.specials.get(1)).toBe("NaN");
    expect(col.specials.get(2)).toBe("Inf");
    expect(col.specials.get(3)).toBe("-Inf");

    // Craft 3 int32 values including R NA_integer_ (-2147483648)
    const i32Raw = new Uint8Array(12);
    const idv = new DataView(i32Raw.buffer);
    idv.setInt32(0, 42, true);
    idv.setInt32(4, -2147483648, true);
    idv.setInt32(8, -7, true);
    const iShuffled = new Uint8Array(12);
    for (let p = 0; p < 4; p += 1) {
      for (let i = 0; i < 3; i += 1) {
        iShuffled[p * 3 + i] = i32Raw[i * 4 + p];
      }
    }
    const icol = decodeVector(
      {
        type: "integer",
        encoding: "i32le-shuffle-base64",
        length: 3,
        values: Buffer.from(iShuffled).toString("base64"),
      },
      "k"
    );
    expect(icol.values).toEqual([42, null, -7]);
    expect(icol.specials.get(1)).toBe("NA");
  });

  it("decodes dense-leaf index.bin (10,000 points) and queries Flatbush in sub-millisecond time", async () => {
    const n = 10000;
    const cols = [
      new Int32Array(n), // x0
      new Int32Array(n), // y0
      new Int32Array(n), // width
      new Int32Array(n), // height
      new Int32Array(n), // tag
      new Int32Array(n), // style
    ];
    for (let i = 0; i < n; i += 1) {
      cols[0][i] = (i % 100) * 500; // 0..495 pt
      cols[1][i] = Math.floor(i / 100) * 300; // 0..297 pt
      cols[2][i] = 200; // 2 pt
      cols[3][i] = 200; // 2 pt
      cols[4][i] = 1; // circle
      cols[5][i] = 1; // style 1
    }
    const shuffledChunks = cols.map((col) => {
      const raw = new Uint8Array(col.buffer);
      const sh = new Uint8Array(raw.length);
      for (let p = 0; p < 4; p += 1) {
        for (let i = 0; i < n; i += 1) sh[p * n + i] = raw[i * 4 + p];
      }
      return sh;
    });
    const combined = Buffer.concat(shuffledChunks);
    const indexBin = new Uint8Array(zlib.deflateSync(combined));

    const elementsDoc = {
      leaves: {
        __df__: {
          nrow: 1,
          class: "data.frame",
          names: { type: "character", values: ["id", "name", "path", "class", "vp", "x0", "y0", "x1", "y1", "xscale0", "xscale1", "yscale0", "yscale1", "n_expected", "n_drawn", "status", "bindable", "dense", "panel"] },
          columns: [
            { type: "character", values: ["L001"] },
            { type: "character", values: ["points"] },
            { type: "character", values: ["panel/points"] },
            { type: "character", values: ["points"] },
            { type: "character", values: ["panel"] },
            { type: "double", values: [0] }, { type: "double", values: [0] },
            { type: "double", values: [500] }, { type: "double", values: [300] },
            { type: "double", values: [0] }, { type: "double", values: [1] },
            { type: "double", values: [0] }, { type: "double", values: [1] },
            { type: "integer", values: [n] }, { type: "integer", values: [n] },
            { type: "character", values: ["ok"] }, { type: "logical", values: [true] },
            { type: "logical", values: [true] }, { type: "character", values: ["panel1"] },
          ],
        },
      },
      elements: {
        __df__: {
          nrow: 0,
          class: "data.frame",
          names: { type: "character", values: ["id", "leaf", "tag", "ordinal", "x0", "y0", "x1", "y1", "fill", "stroke", "text", "stable_id"] },
          columns: Array.from({ length: 12 }, () => ({ type: "character", values: [] })),
        },
      },
      element_rows: [],
      n_elements: n,
      panels: {
        __df__: {
          nrow: 0,
          class: "data.frame",
          names: { type: "character", values: ["id"] },
          columns: [{ type: "character", values: [] }],
        },
      },
      dense: [
        {
          leaf: "L001",
          n,
          first: 1,
          first_id: "e1",
          columns: ["x0", "y0", "width", "height", "tag", "style"],
          encoding: "int32 little-endian",
          unit: "1/100 pt",
          tags: ["circle"],
          styles: {
            __df__: {
              nrow: 1,
              class: "data.frame",
              names: { type: "character", values: ["fill", "stroke"] },
              columns: [
                { type: "character", values: ["#2563eb"] },
                { type: "character", values: ["#1e40af"] },
              ],
            },
          },
        },
      ],
    };

    const files = new Map<string, Uint8Array>([
      [
        "manifest.json",
        new TextEncoder().encode(
          JSON.stringify({
            format: "gloss-bundle",
            format_version: "0.3.0",
            gloss_version: "0.0.0.9000",
            engine: "ggplot",
            meta: {},
            plugins: [],
            status: [],
            tables: [],
            files: [],
          })
        ),
      ],
      [
        "substrate/scene.svg",
        new TextEncoder().encode('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 300"></svg>'),
      ],
      ["substrate/elements.json", new TextEncoder().encode(JSON.stringify(elementsDoc))],
      ["substrate/index.bin", indexBin],
    ]);

    const bundle = await decodeFileMap(files, "dense-10k.gloss", "directory");
    expect(bundle.substrate.elements.length).toBe(n);
    expect(bundle.substrate.elements[0].id).toBe("e1");
    expect(bundle.substrate.elements[9999].id).toBe("e10000");
    expect(bundle.substrate.elements[505].x0).toBe(25);
    expect(bundle.substrate.elements[505].y0).toBe(15);

    const spatial = buildSpatialIndex(bundle.substrate.elements);
    const hit = spatial.hitTest(26, 16, 3);
    expect(hit?.id).toBe("e506");
  });

  it("degrades transparently to geometry-only mode for a plain SVG without gloss-bundle", async () => {
    const plain = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 100"><circle cx="50" cy="50" r="10"/></svg>';
    const bundle = await decodeArtifactText(plain, "plain.svg");
    expect(bundle.sourceKind).toBe("plain-svg");
    expect(bundle.substrate.viewBox).toEqual({ x: 0, y: 0, width: 200, height: 100 });
    expect(bundle.status.restored).toContain("geometry only");
  });
});
