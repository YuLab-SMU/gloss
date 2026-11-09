# ADR-0005: Bundle format v0

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Yonghe Xia
- **Related:** [design: 一个文件就能带走整份图包](../design.qmd), [plan/2026-11-09-m0-substrate.md](../../plan/2026-11-09-m0-substrate.md), [dev log](../../dev_logs/2026-11-09-m0-substrate.md)

## Context

The design fixes the bundle's directory layout and asks for a single HTML or SVG file that embeds the whole bundle, with a lossless conversion between the two, and a 10^5-point scatter under 3 MB as a single file. It leaves the encodings open. These choices are expensive to change once bundles exist in the wild.

## Decision

**The directory and the single file carry the same files byte for byte; tables are column-oriented JSON with exact types; large numeric columns and dense-leaf geometry are binary, byte-shuffled, and compressed once.**

- **Files.** `manifest.json`, `context.json`, `substrate/scene.svg`, `substrate/elements.json`, `substrate/tables/<name>.json`, and for dense leaves `substrate/index.bin` and `substrate/raster/<leaf>.png`. `layers/` and `projections/` are created empty until M2 and M3. The manifest lists every other file with its byte length and SHA-256; reading reports mismatches in `status$integrity`. Writing is deterministic: the same figure gives the same bytes.
- **Single file.** Files are packed as `[u32 path length][path][u32 content length][content]`, sorted by path, compressed with zlib and base64-encoded into `<script type="application/json" id="gloss-bundle">`. zlib is what browsers can inflate natively (`DecompressionStream("deflate")`).
- **Exact values.** Every vector is stored with its type and attributes (factor levels, `Date`, `POSIXct` and its time zone, `ordered`). Doubles are written with the shortest of 15 or 17 significant digits that parses back to the same value, always with a decimal point; NaN and ±Inf are listed by position. Non-automatic row names are kept.
- **Large columns.** Numeric columns with at least 10,000 values are stored as little-endian binary, byte-plane shuffled (all first bytes, then all second bytes, as in Blosc and HDF5), in base64. This is exact, NA payloads included.
- **Dense leaves.** Leaves with at least `dense` (default 10,000) non-text elements are drawn alone on a transparent PNG device from the same grob and appear in the scene as one `<image>`; their element geometry goes to `index.bin` as int32 columns in 1/100 pt (x0, y0, width, height, tag code, style code), byte-shuffled per column, zlib-compressed.
- **Shared columns.** A column of a built or engine table that is identical to an embedded raw-table column is stored as a reference to it, after an `identical()` check.
- **Embedding.** `gl_write(embed = )`: `default` (built and engine tables, plus raw columns referenced by aesthetics, facets or the key), `all`, `summary` (per-column summaries), `none` (no column summaries in the context either).

## Alternatives considered

- **Decimal JSON for all numbers.** Readable, but random doubles cost about 10% more after compression; the 10^5-point file was 2.99 MiB, with no margin. Small tables stay decimal.
- **jsonlite's `digits = NA`.** Not lossless: it writes 15 significant digits.
- **xz or brotli.** Better ratios, but browsers cannot inflate them natively.
- **A tar archive or JSON of base64 strings inside the payload.** Tar is more to parse in the browser runtime; base64 inside base64 wastes a third.

## Consequences

### Positive

- Directory → HTML → directory and directory → SVG → directory are byte-identical, and `gl_read(gl_write(fig))` is identical to `fig` (tests in `test-bundle.R`).
- A 10^5-point scatter with default embedding is 2.65 MiB as a single HTML file; plain svglite gives 8.3 MB for the same plot.

### Negative / accepted tradeoffs

- Large numeric columns and `index.bin` are not human-readable in the directory form.
- Geometry is kept to 1/100 pt, the precision svglite writes.

### Follow-ups

- The browser runtime (M3) needs a reader for this format; the encodings above were picked so that it is a few dozen lines with typed arrays.
- `format_version` is 0.1.0; readers refuse a different major version.
