#!/usr/bin/env python3
"""Zero-dependency bidirectional grounding bridge for gloss Asset Bundles.

Implements the open `gloss-focus` / `gloss-overlay` contract offline (without R):
1. `box-to-rows`: Converts an SVG point-space selection box `x0,y0,x1,y1` into
   matched elements, `built` rows, and bridged `raw` `_row_id`s (using element
   `built_row_id` / `group_id` bridges AND inverse panel coordinate projection
   so rasterized >10^4 dense layers are equally queryable).
2. `rows-to-overlay`: Converts `table` + `_row_id`s discovered by an agent into
   a `gloss-focus` JSON payload and an optional highlight/dimmed `overlay.svg`
   derived cleanly from `scene/scene.svg`.
"""

from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import json
import math
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)


def parse_num(val: str | None) -> float | None:
    if val is None:
        return None
    s = val.strip()
    if s in ("", "NA", "NaN", "null"):
        return None
    try:
        v = float(s)
        return v if math.isfinite(v) else None
    except ValueError:
        return None


def apply_axis_trans(val: float, trans: str | None) -> float | None:
    tr = (trans or "identity").strip().lower()
    if tr in ("identity", "linear", "discrete", "date", "time", ""):
        return val
    if tr in ("log-10", "log10"):
        return math.log10(val) if val > 0 else None
    if tr in ("log-2", "log2"):
        return math.log2(val) if val > 0 else None
    if tr in ("ln", "log", "log-e"):
        return math.log(val) if val > 0 else None
    if tr in ("sqrt", "square-root"):
        return math.sqrt(val) if val >= 0 else None
    if tr in ("reverse", "rev"):
        return -val
    return val


def panel_px_to_rendered(panel: dict, px: float, py: float) -> tuple[float, float] | None:
    bb = panel.get("bbox_pt")
    xd = panel.get("x_domain")
    yd = panel.get("y_domain")
    if not bb or not xd or not yd or len(bb) != 4 or len(xd) != 2 or len(yd) != 2:
        return None
    x0, y0, x1, y1 = [float(v) for v in bb]
    xd0, xd1 = float(xd[0]), float(xd[1])
    yd0, yd1 = float(yd[0]), float(yd[1])
    if x1 == x0 or y1 == y0:
        return None
    vx = xd0 + (px - x0) / (x1 - x0) * (xd1 - xd0)
    vy = yd0 + (y1 - py) / (y1 - y0) * (yd1 - yd0)
    if panel.get("flipped"):
        return (vy, vx)
    return (vx, vy)


def panel_rendered_to_px(panel: dict, x_ren: float, y_ren: float) -> tuple[float, float] | None:
    bb = panel.get("bbox_pt")
    xd = panel.get("x_domain")
    yd = panel.get("y_domain")
    if not bb or not xd or not yd or len(bb) != 4 or len(xd) != 2 or len(yd) != 2:
        return None
    x0, y0, x1, y1 = [float(v) for v in bb]
    xd0, xd1 = float(xd[0]), float(xd[1])
    yd0, yd1 = float(yd[0]), float(yd[1])
    if xd1 == xd0 or yd1 == yd0:
        return None
    vx, vy = (y_ren, x_ren) if panel.get("flipped") else (x_ren, y_ren)
    px = x0 + (vx - xd0) / (xd1 - xd0) * (x1 - x0)
    py = y1 - (vy - yd0) / (yd1 - yd0) * (y1 - y0)
    return (px, py)


def boxes_intersect(a: list[float], b: list[float]) -> bool:
    return (a[2] >= b[0]) and (a[0] <= b[2]) and (a[3] >= b[1]) and (a[1] <= b[3])


def load_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def load_group_index(bundle_dir: Path, built_tid: str) -> dict[str, list[int]]:
    gp = bundle_dir / "tables" / f"groups_{built_tid}.json"
    if not gp.exists():
        return {}
    raw = json.loads(gp.read_text(encoding="utf-8"))
    out: dict[str, list[int]] = {}
    for k, vals in raw.items():
        if isinstance(vals, list):
            out[str(k)] = [int(v) for v in vals]
        elif isinstance(vals, int):
            out[str(k)] = [vals]
    return out


def _quantile_r7(sorted_vals: list[float], p: float) -> float:
    n = len(sorted_vals)
    if n == 1:
        return sorted_vals[0]
    h = (n - 1) * p
    lo = int(math.floor(h))
    hi = min(n - 1, lo + 1)
    return sorted_vals[lo] + (h - lo) * (sorted_vals[hi] - sorted_vals[lo])


def _metric_deviation(sel_vals: list[float], grp_vals: list[float], col_name: str, raw_col: str | None = None) -> dict | None:
    if not sel_vals or not grp_vals:
        return None
    g_mean = sum(grp_vals) / len(grp_vals)
    g_sd = (
        math.sqrt(sum((v - g_mean) ** 2 for v in grp_vals) / (len(grp_vals) - 1))
        if len(grp_vals) >= 2
        else None
    )
    gs = sorted(grp_vals)
    ss = sorted(sel_vals)
    g_med = _quantile_r7(gs, 0.5)
    g_iqr = _quantile_r7(gs, 0.75) - _quantile_r7(gs, 0.25)
    max_z = max(abs(v - g_mean) / g_sd for v in sel_vals) if (g_sd and g_sd > 0) else None
    max_iqr = max(abs(v - g_med) / g_iqr for v in sel_vals) if g_iqr > 0 else None
    out: dict = {
        "column": col_name,
        "selected_mean": round(sum(sel_vals) / len(sel_vals), 6),
        "selected_median": round(_quantile_r7(ss, 0.5), 6),
        "group_mean": round(g_mean, 6),
        "group_sd": round(g_sd, 6) if g_sd is not None else None,
        "group_median": round(g_med, 6),
        "group_iqr": round(g_iqr, 6),
        "max_abs_z": round(max_z, 4) if max_z is not None else None,
        "max_iqr_multiple": round(max_iqr, 4) if max_iqr is not None else None,
    }
    if raw_col and raw_col != col_name:
        out["raw_column"] = raw_col
    return out


def compute_focus_context_summary(bundle_dir: Path, asset_map: dict, targets: list[dict]) -> dict:
    # 1. Resolve matched entities from asset_map["entities"]
    raw_rows_by_tid: dict[str, set[int]] = {}
    for t in targets:
        tid = t.get("table_id")
        if tid:
            raw_rows_by_tid.setdefault(tid, set()).update(int(r) for r in (t.get("row_ids") or []))

    csv_cache: dict[str, list[dict[str, str]]] = {}

    def get_csv(tid: str) -> list[dict[str, str]]:
        if tid not in csv_cache:
            csv_cache[tid] = load_csv(bundle_dir / "tables" / f"{tid}.csv")
        return csv_cache[tid]

    hit_entities: dict[str, dict] = {}
    for ent in asset_map.get("entities") or []:
        vals: set[str] = set()
        for b in ent.get("bindings") or []:
            if b.get("axis") != "row":
                continue
            btid = b.get("table_id")
            col = b.get("column")
            if not btid or not col or btid not in raw_rows_by_tid:
                continue
            rset = raw_rows_by_tid[btid]
            for row in get_csv(btid):
                rid_s = row.get("_row_id", "")
                if rid_s.isdigit() and int(rid_s) in rset:
                    v = (row.get(col) or "").strip()
                    if v and v != "NA":
                        vals.add(v)
        if vals:
            svals = sorted(vals)
            ek = ent["name"]
            if ek in hit_entities:
                ek = f"{ent.get('entity_role', 'entity')}:{ek}"
            hit_entities[ek] = {
                "entity_role": ent.get("entity_role"),
                "name": ent["name"],
                "n": len(svals),
                "values": svals,
            }

    # 2. Compute in-panel / in-group deviation summaries
    panel_by_id = {p["panel_id"]: p for p in asset_map.get("ir", {}).get("panels", [])}
    layer_by_id = {int(l["layer_id"]): l for l in asset_map.get("ir", {}).get("layers", []) if l.get("layer_id") is not None}
    comparisons: list[dict] = []

    for t in targets:
        btid = t.get("built_table")
        b_rids = set(int(r) for r in (t.get("built_row_ids") or []))
        if not btid or not b_rids:
            continue
        full_rows = get_csv(btid)
        if not full_rows:
            continue
        sel_rows = [r for r in full_rows if r.get("_row_id", "").isdigit() and int(r["_row_id"]) in b_rids]
        if not sel_rows:
            continue

        pid = t.get("panel_id")
        pan = panel_by_id.get(pid) if pid else None
        lyr = layer_by_id.get(int(t["layer_id"])) if t.get("layer_id") is not None else None
        has_group = len({r.get("group", "-1") for r in full_rows if r.get("group")}) > 1

        by_key: dict[tuple[str, str], list[dict[str, str]]] = {}
        for r in sel_rows:
            k = (r.get("PANEL", "1"), r.get("group", "-1") if has_group else "-1")
            by_key.setdefault(k, []).append(r)

        for (pv, gv), s_slice in by_key.items():
            f_slice = [
                r
                for r in full_rows
                if r.get("PANEL", "1") == pv and (not has_group or r.get("group", "-1") == gv)
            ]
            if not f_slice:
                continue
            metrics: dict[str, dict] = {}
            for ax in ("x", "y"):
                if pan and pan.get(f"{ax}_trans") == "discrete":
                    continue
                sv = [v for v in (parse_num(r.get(ax)) for r in s_slice) if v is not None]
                gv_nums = [v for v in (parse_num(r.get(ax)) for r in f_slice) if v is not None]
                raw_col = (lyr.get("aes") or {}).get(ax) if lyr else None
                m = _metric_deviation(sv, gv_nums, ax, raw_col=raw_col)
                if m:
                    metrics[ax] = m
            if metrics:
                comparisons.append(
                    {
                        "table_id": btid,
                        "raw_table": lyr.get("raw_table") if lyr else None,
                        "panel_id": pid,
                        "group": f"group_{gv}" if has_group else "_all",
                        "selected_n": len(s_slice),
                        "group_n": len(f_slice),
                        "metrics": metrics,
                    }
                )

    return {"entities": hit_entities, "comparisons": comparisons}


def box_to_rows(bundle_dir: Path, box: list[float], note: str | None = None) -> dict:
    bx = [min(box[0], box[2]), min(box[1], box[3]), max(box[0], box[2]), max(box[1], box[3])]
    asset_map = json.loads((bundle_dir / "asset-map.json").read_text(encoding="utf-8"))
    elements = (
        json.loads((bundle_dir / "scene" / "elements.json").read_text(encoding="utf-8"))
        if (bundle_dir / "scene" / "elements.json").exists()
        else []
    )
    leaves = (
        json.loads((bundle_dir / "scene" / "leaves.json").read_text(encoding="utf-8"))
        if (bundle_dir / "scene" / "leaves.json").exists()
        else []
    )

    leaf_by_id = {l["leaf_id"]: l for l in leaves}
    panel_by_id = {p["panel_id"]: p for p in asset_map.get("ir", {}).get("panels", [])}
    layer_by_id = {int(l["layer_id"]): l for l in asset_map.get("ir", {}).get("layers", []) if l.get("layer_id") is not None}

    matched_els_by_leaf: dict[str, list[dict]] = {}
    for el in elements:
        x0, y0, x1, y1 = el.get("bbox_x0"), el.get("bbox_y0"), el.get("bbox_x1"), el.get("bbox_y1")
        if None in (x0, y0, x1, y1):
            continue
        if boxes_intersect([float(x0), float(y0), float(x1), float(y1)], bx):
            lid = el.get("leaf_id")
            if lid:
                matched_els_by_leaf.setdefault(lid, []).append(el)

    targets: list[dict] = []
    for lin in asset_map.get("lineage", []):
        lid = lin.get("leaf_id")
        tid = lin.get("table_id")
        pid = lin.get("panel_id")
        layer_id = lin.get("layer_id")
        if not lid or not tid:
            continue

        leaf = leaf_by_id.get(lid, {})
        is_dense = bool(leaf.get("dense"))
        pan = panel_by_id.get(pid) if pid else None
        pbb = pan.get("bbox_pt") if pan else None
        panel_hits = bool(pbb and boxes_intersect([float(v) for v in pbb], bx))

        el_hits = matched_els_by_leaf.get(lid, [])
        if not el_hits and not (is_dense and panel_hits):
            continue

        built_rows = load_csv(bundle_dir / "tables" / f"{tid}.csv")
        built_by_rid = {
            int(r["_row_id"]): r for r in built_rows if r.get("_row_id", "").isdigit()
        }

        matched_brows: set[int] = set()
        matched_gids: set[str] = set()
        if not is_dense and el_hits:
            for el in el_hits:
                br = el.get("built_row_id")
                if br is not None:
                    matched_brows.add(int(br))
                gk = el.get("group_id")
                if gk:
                    matched_gids.add(str(gk))

        # Inverse-coordinate projection fallback (critical for rasterized dense layers)
        if not matched_brows and not matched_gids and pan and panel_hits and built_rows:
            qx0 = max(bx[0], float(pbb[0]))
            qy0 = max(bx[1], float(pbb[1]))
            qx1 = min(bx[2], float(pbb[2]))
            qy1 = min(bx[3], float(pbb[3]))
            c1 = panel_px_to_rendered(pan, qx0, qy0)
            c2 = panel_px_to_rendered(pan, qx1, qy1)
            if c1 and c2:
                rx_lo, rx_hi = min(c1[0], c2[0]), max(c1[0], c2[0])
                ry_lo, ry_hi = min(c1[1], c2[1]), max(c1[1], c2[1])
                pnum = None
                if pid and "P" in pid:
                    tail = pid.rsplit("P", 1)[-1]
                    if tail.isdigit():
                        pnum = int(tail)
                is_base = pan.get("coord") == "BaseGraphics"
                for r in built_rows:
                    if pnum is not None and "PANEL" in r and str(r["PANEL"]).isdigit():
                        if int(r["PANEL"]) != pnum:
                            continue
                    xv = parse_num(r.get("x"))
                    yv = parse_num(r.get("y"))
                    if xv is None or yv is None:
                        continue
                    if is_base:
                        xv = apply_axis_trans(xv, pan.get("x_trans"))
                        yv = apply_axis_trans(yv, pan.get("y_trans"))
                        if xv is None or yv is None:
                            continue
                    if rx_lo <= xv <= rx_hi and ry_lo <= yv <= ry_hi:
                        if r.get("_row_id", "").isdigit():
                            matched_brows.add(int(r["_row_id"]))

        if matched_gids and not matched_brows:
            for rid, r in built_by_rid.items():
                if r.get("_group_key") in matched_gids:
                    matched_brows.add(rid)

        if not matched_brows and not el_hits:
            continue

        # Bridge built rows -> raw_row_ids
        lyr = layer_by_id.get(int(layer_id)) if layer_id is not None else None
        raw_tid = lyr.get("raw_table") if lyr else None
        raw_rids: set[int] = set()
        gidx = load_group_index(bundle_dir, tid)
        for br in sorted(matched_brows):
            row = built_by_rid.get(br, {})
            rr = row.get("_raw_row_id", "")
            if rr.isdigit():
                raw_rids.add(int(rr))
            gk = row.get("_group_key", "")
            if gk and gk in gidx:
                raw_rids.update(gidx[gk])
        for gk in matched_gids:
            if gk in gidx:
                raw_rids.update(gidx[gk])

        target: dict = {
            "panel_id": pid,
            "leaf_id": lid,
            "layer_id": layer_id,
            "built_table": tid,
            "built_row_ids": sorted(matched_brows),
            "element_ids": [el["element_id"] for el in el_hits],
            "bbox_pt": [round(v, 3) for v in bx],
            "resolved_via": "inverse_coord_projection" if is_dense else "element_bridge",
        }
        if raw_tid:
            target["table_id"] = raw_tid
            target["row_ids"] = sorted(raw_rids)
        else:
            target["table_id"] = tid
            target["row_ids"] = sorted(matched_brows)
        targets.append(target)

    ctx_summary = compute_focus_context_summary(bundle_dir, asset_map, targets)
    payload: dict = {
        "format": "gloss-focus",
        "schema_version": asset_map.get("schema_version", "1.2.0"),
        "capture_id": asset_map.get("capture_id"),
        "kind": "selection",
        "author": "human",
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "query_box_pt": [round(v, 3) for v in bx],
        "targets": targets,
        "context_summary": ctx_summary,
    }
    if note:
        payload["note"] = note
    return payload


def rows_to_overlay(
    bundle_dir: Path,
    table_id: str,
    row_ids: list[int],
    note: str | None = None,
    svg_out: Path | None = None,
) -> dict:
    asset_map = json.loads((bundle_dir / "asset-map.json").read_text(encoding="utf-8"))
    elements = (
        json.loads((bundle_dir / "scene" / "elements.json").read_text(encoding="utf-8"))
        if (bundle_dir / "scene" / "elements.json").exists()
        else []
    )
    panel_by_id = {p["panel_id"]: p for p in asset_map.get("ir", {}).get("panels", [])}
    layers = asset_map.get("ir", {}).get("layers", [])
    lineage = asset_map.get("lineage", [])
    row_set = set(int(r) for r in row_ids)

    targets: list[dict] = []
    highlight_pts: list[tuple[float, float]] = []
    highlight_el_ids: set[str] = set()
    target_lids: set[str] = set()

    for lyr in layers:
        btid = lyr.get("built_table")
        rtid = lyr.get("raw_table")
        lid_num = lyr.get("layer_id")
        if table_id not in (btid, rtid) or not btid:
            continue

        built_rows = load_csv(bundle_dir / "tables" / f"{btid}.csv")
        gidx = load_group_index(bundle_dir, btid)

        matched_brows: set[int] = set()
        matched_gkeys: set[str] = set()
        if table_id == btid:
            matched_brows.update(row_set)
            for r in built_rows:
                if r.get("_row_id", "").isdigit() and int(r["_row_id"]) in row_set and r.get("_group_key"):
                    matched_gkeys.add(r["_group_key"])
        else:
            for r in built_rows:
                rr = r.get("_raw_row_id", "")
                if rr.isdigit() and int(rr) in row_set and r.get("_row_id", "").isdigit():
                    matched_brows.add(int(r["_row_id"]))
            for gk, rlist in gidx.items():
                if row_set.intersection(rlist):
                    matched_gkeys.add(gk)
            if matched_gkeys and not matched_brows:
                for r in built_rows:
                    if r.get("_group_key") in matched_gkeys and r.get("_row_id", "").isdigit():
                        matched_brows.add(int(r["_row_id"]))

        if not matched_brows and not matched_gkeys:
            continue

        layer_lins = [ln for ln in lineage if ln.get("layer_id") == lid_num]
        for ln in layer_lins:
            leaf_id = ln["leaf_id"]
            pid = ln.get("panel_id")
            pan = panel_by_id.get(pid) if pid else None

            el_hits = [
                el
                for el in elements
                if el.get("leaf_id") == leaf_id
                and (
                    (el.get("built_row_id") is not None and int(el["built_row_id"]) in matched_brows)
                    or (el.get("group_id") in matched_gkeys)
                )
            ]

            pts_here: list[tuple[float, float]] = []
            for el in el_hits:
                highlight_el_ids.add(el["element_id"])
                x0, y0, x1, y1 = el.get("bbox_x0"), el.get("bbox_y0"), el.get("bbox_x1"), el.get("bbox_y1")
                if None not in (x0, y0, x1, y1):
                    pts_here.append((0.5 * (float(x0) + float(x1)), 0.5 * (float(y0) + float(y1))))

            # Coordinate forward projection fallback for dense rasterized leaves
            if not pts_here and pan:
                pnum = None
                if pid and "P" in pid:
                    tail = pid.rsplit("P", 1)[-1]
                    if tail.isdigit():
                        pnum = int(tail)
                for r in built_rows:
                    if not (r.get("_row_id", "").isdigit() and int(r["_row_id"]) in matched_brows):
                        continue
                    if pnum is not None and "PANEL" in r and str(r["PANEL"]).isdigit() and int(r["PANEL"]) != pnum:
                        continue
                    xv, yv = parse_num(r.get("x")), parse_num(r.get("y"))
                    if xv is None or yv is None:
                        continue
                    pxpy = panel_rendered_to_px(pan, xv, yv)
                    if pxpy:
                        pts_here.append(pxpy)

            if not el_hits and not pts_here:
                continue

            target_lids.add(leaf_id)
            highlight_pts.extend(pts_here)
            xs = [p[0] for p in pts_here]
            ys = [p[1] for p in pts_here]
            bbox = [round(min(xs), 3), round(min(ys), 3), round(max(xs), 3), round(max(ys), 3)] if xs else None
            targets.append(
                {
                    "panel_id": pid,
                    "leaf_id": leaf_id,
                    "layer_id": lid_num,
                    "table_id": table_id,
                    "row_ids": sorted(row_set),
                    "built_table": btid,
                    "built_row_ids": sorted(matched_brows),
                    "element_ids": [el["element_id"] for el in el_hits],
                    "bbox_pt": bbox,
                }
            )

    focus_doc: dict = {
        "format": "gloss-focus",
        "schema_version": asset_map.get("schema_version", "1.2.0"),
        "capture_id": asset_map.get("capture_id"),
        "kind": "highlight",
        "author": "agent",
        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "targets": targets,
    }
    if note:
        focus_doc["note"] = note

    if svg_out is not None:
        render_highlight_overlay_svg(
            scene_svg_path=bundle_dir / "scene" / "scene.svg",
            svg_out=svg_out,
            target_lids=target_lids,
            highlight_pts=highlight_pts,
            note=note,
        )
        focus_doc["overlay_svg"] = str(svg_out)

    return focus_doc


def render_highlight_overlay_svg(
    scene_svg_path: Path,
    svg_out: Path,
    target_lids: set[str],
    highlight_pts: list[tuple[float, float]],
    note: str | None = None,
) -> None:
    tree = ET.parse(scene_svg_path)
    root = tree.getroot()

    # Dim target data leaf groups gently so overlay rings pop cleanly
    for g in root.iter(f"{{{SVG_NS}}}g"):
        lid = g.attrib.get("data-gloss-leaf")
        if lid in target_lids:
            g.attrib["opacity"] = "0.35"

    ov = ET.SubElement(root, f"{{{SVG_NS}}}g", {"id": "gloss-agent-overlay", "data-gloss-overlay": "true"})
    for px, py in highlight_pts:
        ET.SubElement(
            ov,
            f"{{{SVG_NS}}}circle",
            {
                "cx": f"{px:.2f}",
                "cy": f"{py:.2f}",
                "r": "5.50",
                "fill": "none",
                "stroke": "#D9480F",
                "stroke-width": "1.80",
            },
        )
    if note and highlight_pts:
        ax = sum(p[0] for p in highlight_pts) / len(highlight_pts)
        ay = min(p[1] for p in highlight_pts) - 12.0
        ay = max(14.0, ay)
        txt = ET.SubElement(
            ov,
            f"{{{SVG_NS}}}text",
            {
                "x": f"{ax:.2f}",
                "y": f"{ay:.2f}",
                "text-anchor": "middle",
                "fill": "#D9480F",
                "font-size": "9.5",
                "font-weight": "bold",
            },
        )
        txt.text = note

    svg_out.parent.mkdir(parents=True, exist_ok=True)
    tree.write(svg_out, encoding="utf-8", xml_declaration=True)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Bidirectional focus/overlay bridge for gloss bundles.")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_b2r = sub.add_parser("box-to-rows", help="Resolve SVG point box to built and raw row_ids.")
    p_b2r.add_argument("--bundle", required=True, type=Path)
    p_b2r.add_argument("--box", required=True, help="Comma-separated x0,y0,x1,y1 in SVG points")
    p_b2r.add_argument("--note", default=None)
    p_b2r.add_argument("--out", type=Path, default=None)

    p_r2o = sub.add_parser("rows-to-overlay", help="Resolve table row_ids to focus JSON and highlight overlay SVG.")
    p_r2o.add_argument("--bundle", required=True, type=Path)
    p_r2o.add_argument("--table", required=True, help="Table ID (e.g. raw or built_layer1)")
    p_r2o.add_argument("--rows", required=True, help="Comma-separated 1-based _row_id integers")
    p_r2o.add_argument("--note", default=None)
    p_r2o.add_argument("--focus-out", type=Path, default=None)
    p_r2o.add_argument("--svg-out", type=Path, default=None)

    args = parser.parse_args(argv)
    if args.cmd == "box-to-rows":
        coords = [float(x.strip()) for x in args.box.split(",")]
        if len(coords) != 4:
            parser.error("--box must have exactly 4 comma-separated numbers: x0,y0,x1,y1")
        res = box_to_rows(args.bundle, coords, note=args.note)
        if args.out is not None:
            args.out.parent.mkdir(parents=True, exist_ok=True)
            args.out.write_text(json.dumps(res, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(res, indent=2))
        return 0

    row_ids = [int(x.strip()) for x in args.rows.split(",") if x.strip()]
    res = rows_to_overlay(args.bundle, args.table, row_ids, note=args.note, svg_out=args.svg_out)
    if args.focus_out is not None:
        args.focus_out.parent.mkdir(parents=True, exist_ok=True)
        args.focus_out.write_text(json.dumps(res, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(res, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
