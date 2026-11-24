#!/usr/bin/env python3
"""Zero-dependency statistical profiler and claim auditor for gloss Asset Bundles.

Reads `manifest.json`, `asset-map.json`, `omitted.json`, `tables/schema.json`,
and `tables/*.csv` inside a `.gloss/` directory to:
1. Verify SHA-256 digests of every staged file in `manifest.json`.
2. Surface row/column/table exclusions recorded in `omitted.json`.
3. Compute exact numeric & group-by summaries (`n`, `mean`, `sd`, `min`, `q25`,
   `median`, `q75`, `iqr`, `max`) and `stat_role` interval bounds.
4. Optionally evaluate structured quantitative claims (`--claims claims.json`).
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import statistics
import sys


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def quantile_type7(sorted_vals: list[float], p: float) -> float:
    """R default quantile(type = 7) linear interpolation."""
    n = len(sorted_vals)
    if n == 0:
        return float("nan")
    if n == 1:
        return sorted_vals[0]
    idx = p * (n - 1)
    lo = int(math.floor(idx))
    hi = int(math.ceil(idx))
    frac = idx - lo
    return sorted_vals[lo] + frac * (sorted_vals[hi] - sorted_vals[lo])


def summarize_numbers(vals: list[float]) -> dict | None:
    finite = sorted(v for v in vals if math.isfinite(v))
    if not finite:
        return None
    n = len(finite)
    q25 = quantile_type7(finite, 0.25)
    med = quantile_type7(finite, 0.50)
    q75 = quantile_type7(finite, 0.75)
    return {
        "n": n,
        "mean": round(statistics.fmean(finite), 6),
        "sd": round(statistics.stdev(finite), 6) if n >= 2 else 0.0,
        "min": round(finite[0], 6),
        "q25": round(q25, 6),
        "median": round(med, 6),
        "q75": round(q75, 6),
        "iqr": round(q75 - q25, 6),
        "max": round(finite[-1], 6),
    }


def load_csv_rows(csv_path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with csv_path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        cols = list(reader.fieldnames or [])
        rows = list(reader)
    return cols, rows


def parse_num(val: str | None) -> float | None:
    if val is None:
        return None
    s = val.strip()
    if s in ("", "NA", "NaN", "null"):
        return None
    if s in ("Inf", "+Inf"):
        return float("inf")
    if s == "-Inf":
        return float("-inf")
    try:
        return float(s)
    except ValueError:
        return None


def verify_manifest(bundle_dir: Path) -> dict:
    mpath = bundle_dir / "manifest.json"
    if not mpath.exists():
        return {"valid": False, "checked_files": 0, "mismatches": [{"reason": "missing_manifest"}]}
    manifest = json.loads(mpath.read_text(encoding="utf-8"))
    mismatches: list[dict] = []
    files = manifest.get("files", [])
    for entry in files:
        rel = entry["path"]
        fp = bundle_dir / rel
        if not fp.exists():
            mismatches.append({"path": rel, "reason": "missing_file"})
            continue
        actual_sha = sha256_file(fp)
        if actual_sha != entry.get("sha256"):
            mismatches.append(
                {"path": rel, "reason": "sha256_mismatch", "expected": entry.get("sha256"), "actual": actual_sha}
            )
    return {
        "valid": len(mismatches) == 0,
        "checked_files": len(files),
        "mismatches": mismatches,
    }


def profile_table(
    tid: str,
    csv_path: Path,
    schema_entry: dict,
) -> dict:
    cols, rows = load_csv_rows(csv_path)
    col_specs = {c["name"]: c for c in schema_entry.get("columns", [])}

    numeric_cols: dict[str, list[float]] = {}
    group_candidates: list[str] = []
    stat_role_columns: dict[str, dict] = {}

    for col in cols:
        if col == "_row_id":
            continue
        spec = col_specs.get(col, {})
        ctype = spec.get("type", "")
        srole = spec.get("stat_role")

        if ctype in ("integer", "double") or srole:
            parsed = [v for v in (parse_num(r.get(col)) for r in rows) if v is not None]
            if parsed:
                numeric_cols[col] = parsed
                summary = summarize_numbers(parsed)
                if srole and summary:
                    stat_role_columns[col] = {"stat_role": srole, **summary}

        if ctype in ("factor", "ordered_factor", "character", "logical") or col in ("PANEL", "group"):
            vals = [r.get(col, "") for r in rows if r.get(col, "") != ""]
            distinct = sorted(set(vals))
            if 1 < len(distinct) <= 12:
                group_candidates.append(col)

    col_summaries = {
        col: s for col, vals in numeric_cols.items() if (s := summarize_numbers(vals)) is not None
    }

    group_summaries: dict[str, dict] = {}
    for gcol in group_candidates[:4]:
        by_grp: dict[str, list[dict[str, str]]] = {}
        for r in rows:
            gv = r.get(gcol, "")
            by_grp.setdefault(gv, []).append(r)
        grp_out: dict[str, dict] = {}
        for gv, grows in sorted(by_grp.items()):
            metrics: dict[str, dict] = {}
            for ncol in list(numeric_cols.keys())[:8]:
                if ncol == gcol:
                    continue
                gvals = [v for v in (parse_num(gr.get(ncol)) for gr in grows) if v is not None]
                ms = summarize_numbers(gvals)
                if ms:
                    metrics[ncol] = {
                        "n": ms["n"],
                        "mean": ms["mean"],
                        "median": ms["median"],
                        "min": ms["min"],
                        "max": ms["max"],
                    }
            grp_out[gv] = {"n_rows": len(grows), "metrics": metrics}
        group_summaries[gcol] = grp_out

    return {
        "table_id": tid,
        "role": schema_entry.get("role", "raw"),
        "nrow": len(rows),
        "columns": cols,
        "numeric_summaries": col_summaries,
        "stat_role_summaries": stat_role_columns,
        "group_summaries": group_summaries,
    }


def evaluate_claims(
    claims: list[dict],
    bundle_dir: Path,
    omitted_entries: list[dict],
) -> list[dict]:
    results: list[dict] = []
    omitted_by_table = {
        o.get("id"): o for o in omitted_entries if o.get("kind") in ("table", "table_rows", "table_columns")
    }

    table_cache: dict[str, list[dict[str, str]]] = {}

    def get_rows(tid: str) -> list[dict[str, str]] | None:
        if tid in table_cache:
            return table_cache[tid]
        p = bundle_dir / "tables" / f"{tid}.csv"
        if not p.exists():
            return None
        _, rws = load_csv_rows(p)
        table_cache[tid] = rws
        return rws

    for cl in claims:
        cid = cl.get("id", "claim")
        tid = cl.get("table", "raw")
        op = cl.get("op", "nrow")
        expected = float(cl["expected"])
        tol = float(cl.get("tol", 1e-6))
        where = cl.get("where") or {}

        rows = get_rows(tid)
        if rows is None:
            results.append(
                {
                    "id": cid,
                    "statement": cl.get("statement", ""),
                    "status": "UNVERIFIABLE_FROM_BUNDLE",
                    "reason": f"Table '{tid}.csv' not available in bundle",
                    "omission_note": omitted_by_table.get(tid),
                }
            )
            continue

        matched = [
            r for r in rows if all(str(r.get(k, "")) == str(v) for k, v in where.items())
        ]

        observed: float | None = None
        if op in ("nrow", "count"):
            observed = float(len(matched))
        else:
            col = cl.get("column", "")
            vals = [v for v in (parse_num(r.get(col)) for r in matched) if v is not None and math.isfinite(v)]
            if vals:
                svals = sorted(vals)
                if op == "mean":
                    observed = statistics.fmean(svals)
                elif op == "median":
                    observed = quantile_type7(svals, 0.50)
                elif op == "min":
                    observed = svals[0]
                elif op == "max":
                    observed = svals[-1]
                elif op == "iqr":
                    observed = quantile_type7(svals, 0.75) - quantile_type7(svals, 0.25)
                elif op == "sum":
                    observed = math.fsum(svals)

        if observed is None:
            results.append(
                {
                    "id": cid,
                    "statement": cl.get("statement", ""),
                    "status": "UNVERIFIABLE_FROM_BUNDLE",
                    "reason": "No finite matching observations found",
                }
            )
            continue

        diff = abs(observed - expected)
        if diff <= tol + 1e-12:
            verdict = "PASS"
        elif tol > 0 and diff <= 2.0 * tol + 1e-12:
            verdict = "ROUNDING_DRIFT"
        else:
            verdict = "FAIL"

        results.append(
            {
                "id": cid,
                "statement": cl.get("statement", ""),
                "status": verdict,
                "table": tid,
                "op": op,
                "where": where,
                "expected": expected,
                "observed": round(observed, 6),
                "abs_diff": round(diff, 6),
                "tol": tol,
                "matched_row_ids": [int(r["_row_id"]) for r in matched[:20] if "_row_id" in r and r["_row_id"].isdigit()],
                "omission_warning": omitted_by_table.get(tid),
            }
        )

    return results


def audit_bundle(bundle_dir: Path, claims_path: Path | None = None) -> dict:
    integrity = verify_manifest(bundle_dir)
    asset_map = json.loads((bundle_dir / "asset-map.json").read_text(encoding="utf-8"))
    omitted_doc = (
        json.loads((bundle_dir / "omitted.json").read_text(encoding="utf-8"))
        if (bundle_dir / "omitted.json").exists()
        else {"omitted": []}
    )
    schema_doc = (
        json.loads((bundle_dir / "tables" / "schema.json").read_text(encoding="utf-8"))
        if (bundle_dir / "tables" / "schema.json").exists()
        else {"tables": {}}
    )

    table_profiles: dict[str, dict] = {}
    for tid, s_ent in schema_doc.get("tables", {}).items():
        csv_p = bundle_dir / "tables" / f"{tid}.csv"
        if csv_p.exists():
            table_profiles[tid] = profile_table(tid, csv_p, s_ent)
        else:
            table_profiles[tid] = {
                "table_id": tid,
                "role": s_ent.get("role", "raw"),
                "format": s_ent.get("format", "parquet"),
                "path": s_ent.get("path"),
                "nrow": s_ent.get("nrow"),
                "note": "Non-CSV table format; query via DuckDB/pyarrow/nanoparquet.",
            }

    scales_summary = [
        {
            "aesthetic": s.get("aesthetic"),
            "field": s.get("field"),
            "scale_type": s.get("scale_type"),
            "trans": s.get("trans"),
            "domain": s.get("domain"),
            "n_mapped_levels": len(s.get("map", [])),
        }
        for s in asset_map.get("ir", {}).get("scales", [])
    ]

    claim_results: list[dict] = []
    if claims_path is not None:
        claims_data = json.loads(claims_path.read_text(encoding="utf-8"))
        claim_results = evaluate_claims(claims_data, bundle_dir, omitted_doc.get("omitted", []))

    has_fail = (not integrity["valid"]) or any(c["status"] == "FAIL" for c in claim_results)
    return {
        "status": "FAIL" if has_fail else "PASS",
        "capture_id": asset_map.get("capture_id"),
        "engine": asset_map.get("page", {}).get("engine"),
        "manifest_integrity": integrity,
        "omissions": omitted_doc.get("omitted", []),
        "panels": asset_map.get("ir", {}).get("panels", []),
        "scales": scales_summary,
        "tables": table_profiles,
        "claim_results": claim_results,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Profile a .gloss bundle and audit quantitative claims.")
    parser.add_argument("--bundle", required=True, type=Path, help="Path to .gloss bundle directory")
    parser.add_argument("--claims", type=Path, default=None, help="Optional JSON file of quantitative claims")
    args = parser.parse_args(argv)

    report = audit_bundle(args.bundle, args.claims)
    print(json.dumps(report, indent=2))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
