/**
 * Low-level binary helpers matching R/core-bundle.R and R/core-codec.R (ADR-0005).
 * Runs natively in modern browsers and Node 18+ with zero external compression deps.
 */

export function asArray<T>(x: unknown): T[] {
  if (x === null || x === undefined) return [];
  return Array.isArray(x) ? (x as T[]) : [x as T];
}

export function asStringArray(x: unknown): string[] {
  return asArray<unknown>(x)
    .filter((v) => v !== null && v !== undefined)
    .map((v) => String(v));
}

export function asRecord<T = unknown>(x: unknown): Record<string, T> {
  if (!x || typeof x !== "object" || Array.isArray(x)) return {};
  return x as Record<string, T>;
}

export function base64ToBytes(b64: string): Uint8Array {
  const clean = b64.replace(/[\r\n\s]/g, "");
  if (typeof Buffer !== "undefined") {
    const buf = Buffer.from(clean, "base64");
    return new Uint8Array(buf.buffer, buf.byteOffset, buf.byteLength);
  }
  const binary = atob(clean);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    out[i] = binary.charCodeAt(i);
  }
  return out;
}

export function bytesToBase64(bytes: Uint8Array): string {
  if (typeof Buffer !== "undefined") {
    return Buffer.from(bytes.buffer, bytes.byteOffset, bytes.byteLength).toString("base64");
  }
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

export function bytesToUtf8(bytes: Uint8Array): string {
  return new TextDecoder("utf-8").decode(bytes);
}

/**
 * Inflate an RFC 1950 zlib stream (produced by R's `memCompress(..., type = "gzip")`).
 * Uses native `DecompressionStream("deflate")` in browsers and Node 18+.
 */
export async function inflateZlib(compressed: Uint8Array): Promise<Uint8Array> {
  if (typeof DecompressionStream !== "undefined") {
    const ds = new DecompressionStream("deflate");
    const writer = ds.writable.getWriter();
    // Write a copy backed by a standard ArrayBuffer to satisfy strict TS BodyInit/BufferSource typing
    const copy = new Uint8Array(compressed.byteLength);
    copy.set(compressed);
    const writePromise = writer.write(copy).then(() => writer.close());
    const reader = ds.readable.getReader();
    const chunks: Uint8Array[] = [];
    let total = 0;
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      if (value) {
        chunks.push(value);
        total += value.byteLength;
      }
    }
    await writePromise;
    const out = new Uint8Array(total);
    let offset = 0;
    for (const c of chunks) {
      out.set(c, offset);
      offset += c.byteLength;
    }
    return out;
  }
  throw new Error(
    "This browser does not support native DecompressionStream('deflate') required to decode gloss bundles."
  );
}

export async function sha256Hex(bytes: Uint8Array): Promise<string | null> {
  if (typeof crypto !== "undefined" && crypto.subtle) {
    const copy = new Uint8Array(bytes.byteLength);
    copy.set(bytes);
    const digest = await crypto.subtle.digest("SHA-256", copy);
    const arr = new Uint8Array(digest);
    let hex = "";
    for (let i = 0; i < arr.length; i += 1) {
      hex += arr[i].toString(16).padStart(2, "0");
    }
    return hex;
  }
  return null;
}

/**
 * Inverse of R's `byte_shuffle(bytes, size)` in R/core-codec.R:
 * In R: matrix(bytes, nrow = size) transposed puts all byte-0s first, then byte-1s, ...
 * Unshuffling interleaves plane p (offset p * n) back into byte p of element i.
 */
export function byteUnshuffle(shuffled: Uint8Array, elementSize: number): Uint8Array {
  const n = Math.floor(shuffled.byteLength / elementSize);
  const out = new Uint8Array(n * elementSize);
  for (let p = 0; p < elementSize; p += 1) {
    const planeOffset = p * n;
    for (let i = 0; i < n; i += 1) {
      out[i * elementSize + p] = shuffled[planeOffset + i];
    }
  }
  return out;
}

/**
 * Unpack `[u32-BE pathLen][utf8 path][u32-BE contentLen][bytes]...`
 * matching `unpack_files()` in R/core-bundle.R:559-571.
 */
export async function unpackGlossPayload(payloadB64: string): Promise<Map<string, Uint8Array>> {
  const compressed = base64ToBytes(payloadB64);
  const raw = await inflateZlib(compressed);
  const view = new DataView(raw.buffer, raw.byteOffset, raw.byteLength);
  const decoder = new TextDecoder("utf-8");
  const files = new Map<string, Uint8Array>();

  let pos = 0;
  const total = raw.byteLength;
  while (pos < total) {
    if (pos + 4 > total) throw new Error("Truncated gloss bundle: missing path length.");
    const lp = view.getUint32(pos, false);
    pos += 4;
    if (pos + lp > total) throw new Error("Truncated gloss bundle: path exceeds payload.");
    const name = decoder.decode(raw.subarray(pos, pos + lp));
    pos += lp;
    if (pos + 4 > total) throw new Error(`Truncated gloss bundle: missing body length for ${name}.`);
    const lb = view.getUint32(pos, false);
    pos += 4;
    if (pos + lb > total) throw new Error(`Truncated gloss bundle: body exceeds payload for ${name}.`);
    files.set(name, raw.slice(pos, pos + lb));
    pos += lb;
  }
  return files;
}
