import { asArray, asRecord, asStringArray, base64ToBytes, byteUnshuffle } from "./binary";
import type { DecodedColumn, DecodedDataFrame, RSpecialValue } from "./types";

const R_NA_INT32 = -2147483648; // 0x80000000
const R_NA_REAL_LOW = 1954; // R's canonical NA_real_ NaN payload

interface RawEncodedVector {
  type?: string;
  encoding?: string;
  length?: number;
  values?: unknown;
  specials?: Record<string, unknown>;
  attrs?: Record<string, RawEncodedVector>;
  names?: RawEncodedVector;
  ref?: { table: string; column: string };
}

interface RawEncodedDf {
  nrow: number;
  class?: string | string[];
  names: RawEncodedVector;
  rownames?: RawEncodedVector;
  columns: RawEncodedVector[];
  attrs?: Record<string, RawEncodedVector>;
}

/**
 * Decode an R vector stored by `encode_vector()` in R/core-codec.R.
 */
export function decodeVector(enc: RawEncodedVector, name = ""): DecodedColumn {
  const rType = enc.type ?? "unknown";
  const specials = new Map<number, RSpecialValue>();
  let values: Array<string | number | boolean | null | unknown> = [];

  if (enc.encoding === "f64le-shuffle-base64" || enc.encoding === "i32le-shuffle-base64") {
    const n = Number(enc.length ?? 0);
    const size = enc.encoding === "f64le-shuffle-base64" ? 8 : 4;
    const raw = byteUnshuffle(base64ToBytes(String(enc.values ?? "")), size);
    const view = new DataView(raw.buffer, raw.byteOffset, raw.byteLength);
    values = new Array(n);
    if (size === 8) {
      for (let i = 0; i < n; i += 1) {
        const offset = i * 8;
        const v = view.getFloat64(offset, true);
        if (Number.isNaN(v)) {
          const low = view.getUint32(offset, true);
          values[i] = null;
          specials.set(i, low === R_NA_REAL_LOW ? "NA" : "NaN");
        } else if (v === Infinity) {
          values[i] = Infinity;
          specials.set(i, "Inf");
        } else if (v === -Infinity) {
          values[i] = -Infinity;
          specials.set(i, "-Inf");
        } else {
          values[i] = v;
        }
      }
    } else {
      for (let i = 0; i < n; i += 1) {
        const v = view.getInt32(i * 4, true);
        if (v === R_NA_INT32) {
          values[i] = null;
          specials.set(i, "NA");
        } else {
          values[i] = v;
        }
      }
    }
  } else if (rType === "double") {
    const rawVals = asArray<number | null>(enc.values);
    values = rawVals.map((v, i) => {
      if (v === null || v === undefined) {
        specials.set(i, "NA");
        return null;
      }
      return Number(v);
    });
    const sp = asRecord<unknown>(enc.specials);
    for (const key of ["NaN", "Inf", "-Inf"] as const) {
      const indices = asArray<number>(sp[key]);
      for (const idx1 of indices) {
        const idx0 = Number(idx1) - 1; // R is 1-based
        if (idx0 >= 0 && idx0 < values.length) {
          specials.set(idx0, key);
          values[idx0] = key === "NaN" ? null : key === "Inf" ? Infinity : -Infinity;
        }
      }
    }
  } else if (rType === "integer") {
    const rawVals = asArray<number | null>(enc.values);
    values = rawVals.map((v, i) => {
      if (v === null || v === undefined) {
        specials.set(i, "NA");
        return null;
      }
      return Math.trunc(Number(v));
    });
  } else if (rType === "logical") {
    const rawVals = asArray<boolean | null>(enc.values);
    values = rawVals.map((v, i) => {
      if (v === null || v === undefined) {
        specials.set(i, "NA");
        return null;
      }
      return Boolean(v);
    });
  } else if (rType === "character") {
    const rawVals = asArray<string | null>(enc.values);
    values = rawVals.map((v, i) => {
      if (v === null || v === undefined) {
        specials.set(i, "NA");
        return null;
      }
      return String(v);
    });
  } else if (rType === "list") {
    const rawVals = asArray<RawEncodedVector | null>(enc.values);
    values = rawVals.map((el) => {
      if (el === null || el === undefined) return null;
      if (typeof el === "object" && "type" in el) {
        const sub = decodeVector(el);
        return sub.values.length === 1 ? sub.values[0] : sub.values;
      }
      return el;
    });
  } else {
    values = asArray<unknown>(enc.values);
  }

  let factorLevels: string[] | undefined;
  let classes: string[] | undefined;
  let attrs: Record<string, unknown> | undefined;

  if (enc.attrs && typeof enc.attrs === "object" && !Array.isArray(enc.attrs)) {
    attrs = {};
    for (const [k, v] of Object.entries(enc.attrs)) {
      const decoded = decodeVector(v, k);
      attrs[k] = decoded.values;
      if (k === "levels") {
        factorLevels = decoded.values.map((s) => (s === null ? "" : String(s)));
      } else if (k === "class") {
        classes = decoded.values.map((s) => String(s));
      }
    }
  }

  // If this is an R factor, map 1-based integer codes to factor level strings for display
  if (factorLevels && classes?.includes("factor") && rType === "integer") {
    values = values.map((v, i) => {
      if (v === null || typeof v !== "number") {
        specials.set(i, "NA");
        return null;
      }
      const lbl = factorLevels![v - 1];
      return lbl !== undefined ? lbl : String(v);
    });
  }

  return {
    name,
    rType: classes?.includes("factor") ? "factor" : rType,
    values,
    specials,
    factorLevels,
    classes,
    attrs,
  };
}

export function decodeVectorPlain(enc: unknown): unknown {
  if (!enc || typeof enc !== "object" || Array.isArray(enc)) return enc;
  const obj = enc as RawEncodedVector;
  if (!obj.type) return enc;
  if (obj.type === "list") {
    const vals = obj.values;
    if (vals && typeof vals === "object" && !Array.isArray(vals)) {
      const out: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(vals as Record<string, unknown>)) {
        out[k] = decodeVectorPlain(v);
      }
      return out;
    }
    const arr = asArray<unknown>(vals).map(decodeVectorPlain);
    if (obj.names) {
      const nms = asStringArray(decodeVector(obj.names).values);
      const out: Record<string, unknown> = {};
      nms.forEach((nm, idx) => {
        out[nm] = arr[idx];
      });
      return out;
    }
    return arr;
  }
  const col = decodeVector(obj);
  if (obj.names) {
    const nms = asStringArray(decodeVector(obj.names).values);
    const out: Record<string, unknown> = {};
    nms.forEach((nm, idx) => {
      out[nm] = col.values[idx];
    });
    return out;
  }
  return col.values.length === 1 ? col.values[0] : col.values;
}

/**
 * Decode an R data.frame encoded by `encode_df()` in R/core-codec.R.
 */
export function decodeDataFrame(
  raw: RawEncodedDf,
  resolveRef?: (ref: { table: string; column: string }) => DecodedColumn | null
): DecodedDataFrame {
  const names = decodeVector(raw.names).values.map((s) => String(s));
  const nrow = Number(raw.nrow ?? 0);
  const classes = asStringArray(raw.class ?? "data.frame");
  const rownames = raw.rownames
    ? decodeVector(raw.rownames).values.map((s) => String(s))
    : undefined;

  const columns: Record<string, DecodedColumn> = {};
  const rawCols = asArray<RawEncodedVector>(raw.columns);
  names.forEach((colName, idx) => {
    const spec = rawCols[idx];
    if (!spec) return;
    if (spec.ref && resolveRef) {
      const resolved = resolveRef(spec.ref);
      if (resolved) {
        columns[colName] = { ...resolved, name: colName };
        return;
      }
    }
    columns[colName] = decodeVector(spec, colName);
  });

  return { nrow, classes, names, rownames, columns };
}

/** Convert a DecodedDataFrame to an array of plain JS row objects (for small/medium tables). */
export function dfToObjects<T = Record<string, unknown>>(
  df: DecodedDataFrame
): T[] {
  const out: T[] = new Array(df.nrow);
  for (let i = 0; i < df.nrow; i += 1) {
    const row: Record<string, unknown> = {};
    for (const nm of df.names) {
      row[nm] = df.columns[nm]?.values[i] ?? null;
    }
    if (df.rownames) {
      row[".rownames"] = df.rownames[i];
    }
    out[i] = row as T;
  }
  return out;
}

/**
 * Recursively expand `{ __df__: ... }` objects produced by R's `json_prep()`.
 */
export function unprepJson(value: unknown): unknown {
  if (value === null || value === undefined || typeof value !== "object") {
    return value;
  }
  if (Array.isArray(value)) {
    return value.map(unprepJson);
  }
  const obj = value as Record<string, unknown>;
  const keys = Object.keys(obj);
  if (keys.length === 1 && keys[0] === "__df__") {
    return decodeDataFrame(obj.__df__ as RawEncodedDf);
  }
  const out: Record<string, unknown> = {};
  for (const k of keys) {
    out[k] = unprepJson(obj[k]);
  }
  return out;
}
