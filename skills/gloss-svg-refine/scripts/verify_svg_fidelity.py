#!/usr/bin/env python3
"""Zero-dependency SVG geometry & cryptographic lineage verifier for gloss-svg-refine.

Verifies that a derived publication SVG:
1. Preserves an unmodified source `.gloss/` bundle (`manifest.json` + `scene/scene.svg`).
2. Records (or validates) `parent_manifest_sha256` and `parent_scene_sha256` in
   `derived-manifest.json`.
3. Keeps every non-label data leaf's primitive count, tag sequence, and geometric
   bounding box (`cx`/`cy`/`x`/`y`/`d`/`points` + ancestor `<g transform>`) within
   `--tol-pt` points of `scene/scene.svg`.
4. Preserves exact text strings on data-label and axis-tick leaves.
5. Keeps legend (`guide-box*`) key colors synchronized when a discrete palette is
   remapped on data leaves.
"""

from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

PRIM_TAGS = {"circle", "rect", "line", "polyline", "polygon", "path", "text", "image"}
LABEL_GEOMS = {
    "GeomText",
    "GeomLabel",
    "GeomTextRepel",
    "GeomLabelRepel",
}
NUM_RE = re.compile(r"[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")
PATH_TOK_RE = re.compile(r"[A-Za-z]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")
STYLE_PROP_RE = re.compile(r"([A-Za-z-]+)\s*:\s*([^;]+)")
TRANSLATE_RE = re.compile(r"translate\(\s*([-+0-9.eE]+)(?:[\s,]+([-+0-9.eE]+))?\s*\)")
SCALE_RE = re.compile(r"scale\(\s*([-+0-9.eE]+)(?:[\s,]+([-+0-9.eE]+))?\s*\)")
ROTATE_RE = re.compile(r"rotate\(\s*([-+0-9.eE]+)")
MATRIX_RE = re.compile(
    r"matrix\(\s*([-+0-9.eE]+)[\s,]+([-+0-9.eE]+)[\s,]+([-+0-9.eE]+)[\s,]+"
    r"([-+0-9.eE]+)[\s,]+([-+0-9.eE]+)[\s,]+([-+0-9.eE]+)\s*\)"
)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def local_tag(elem: ET.Element) -> str:
    t = elem.tag
    return t.split("}", 1)[1] if "}" in t else t


def parse_style(elem: ET.Element) -> dict[str, str]:
    out: dict[str, str] = {}
    raw = elem.attrib.get("style", "")
    for m in STYLE_PROP_RE.finditer(raw):
        out[m.group(1).strip()] = m.group(2).strip()
    return out


def get_prop(elem: ET.Element, name: str) -> str | None:
    st = parse_style(elem)
    if name in st:
        return st[name]
    return elem.attrib.get(name)


def parse_float(val: str | None, default: float = 0.0) -> float:
    if val is None:
        return default
    s = val.strip()
    if s.endswith("px") or s.endswith("pt"):
        s = s[:-2]
    try:
        return float(s)
    except ValueError:
        return default


def parse_transform_matrix(transform_str: str | None) -> tuple[float, float, float, float, float, float]:
    """Return 2D affine (a, b, c, d, e, f) for x' = a*x + c*y + e, y' = b*x + d*y + f."""
    if not transform_str:
        return (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)

    a, b, c, d, e, f = 1.0, 0.0, 0.0, 1.0, 0.0, 0.0

    def compose(
        m1: tuple[float, float, float, float, float, float],
        m2: tuple[float, float, float, float, float, float],
    ) -> tuple[float, float, float, float, float, float]:
        a1, b1, c1, d1, e1, f1 = m1
        a2, b2, c2, d2, e2, f2 = m2
        return (
            a1 * a2 + c1 * b2,
            b1 * a2 + d1 * b2,
            a1 * c2 + c1 * d2,
            b1 * c2 + d1 * d2,
            a1 * e2 + c1 * f2 + e1,
            b1 * e2 + d1 * f2 + f1,
        )

    cur = (a, b, c, d, e, f)
    for m in MATRIX_RE.finditer(transform_str):
        vals = tuple(float(m.group(i)) for i in range(1, 7))
        cur = compose(cur, vals)  # type: ignore[arg-type]
    for m in TRANSLATE_RE.finditer(transform_str):
        tx = float(m.group(1))
        ty = float(m.group(2)) if m.group(2) is not None else 0.0
        cur = compose(cur, (1.0, 0.0, 0.0, 1.0, tx, ty))
    for m in SCALE_RE.finditer(transform_str):
        sx = float(m.group(1))
        sy = float(m.group(2)) if m.group(2) is not None else sx
        cur = compose(cur, (sx, 0.0, 0.0, sy, 0.0, 0.0))
    for m in ROTATE_RE.finditer(transform_str):
        rad = math.radians(float(m.group(1)))
        cs, sn = math.cos(rad), math.sin(rad)
        cur = compose(cur, (cs, sn, -sn, cs, 0.0, 0.0))
    return cur


def apply_affine_to_box(
    box: tuple[float, float, float, float] | None,
    mat: tuple[float, float, float, float, float, float],
) -> tuple[float, float, float, float] | None:
    if box is None:
        return None
    x0, y0, x1, y1 = box
    a, b, c, d, e, f = mat
    corners = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
    xs = [a * x + c * y + e for x, y in corners]
    ys = [b * x + d * y + f for x, y in corners]
    return (min(xs), min(ys), max(xs), max(ys))


def parse_path_bbox(d_attr: str | None) -> tuple[float, float, float, float] | None:
    if not d_attr:
        return None
    toks = PATH_TOK_RE.findall(d_attr)
    if not toks:
        return None

    is_cmd = [len(t) == 1 and t.isalpha() for t in toks]
    n = len(toks)
    cx = cy = sx = sy = 0.0
    xs: list[float] = []
    ys: list[float] = []
    cmd = ""
    i = 0

    def take(k: int) -> list[float] | None:
        if i + k > n or any(is_cmd[i : i + k]):
            return None
        return [float(toks[j]) for j in range(i, i + k)]

    while i < n:
        if is_cmd[i]:
            cmd = toks[i]
            i += 1
            if cmd in ("Z", "z"):
                cx, cy = sx, sy
                continue
        if not cmd or i >= n or is_cmd[i]:
            continue
        up = cmd.upper()
        rel = cmd != up
        if up in ("M", "L", "T"):
            v = take(2)
            if v is None:
                break
            i += 2
            cx = cx + v[0] if rel else v[0]
            cy = cy + v[1] if rel else v[1]
            xs.append(cx)
            ys.append(cy)
            if up == "M":
                sx, sy = cx, cy
                cmd = "l" if rel else "L"
        elif up == "H":
            v = take(1)
            if v is None:
                break
            i += 1
            cx = cx + v[0] if rel else v[0]
            xs.append(cx)
            ys.append(cy)
        elif up == "V":
            v = take(1)
            if v is None:
                break
            i += 1
            cy = cy + v[0] if rel else v[0]
            xs.append(cx)
            ys.append(cy)
        elif up == "C":
            v = take(6)
            if v is None:
                break
            i += 6
            px = [cx + v[k] if rel else v[k] for k in (0, 2, 4)]
            py = [cy + v[k] if rel else v[k] for k in (1, 3, 5)]
            xs.extend(px)
            ys.extend(py)
            cx, cy = px[2], py[2]
        elif up in ("S", "Q"):
            v = take(4)
            if v is None:
                break
            i += 4
            px = [cx + v[k] if rel else v[k] for k in (0, 2)]
            py = [cy + v[k] if rel else v[k] for k in (1, 3)]
            xs.extend(px)
            ys.extend(py)
            cx, cy = px[1], py[1]
        elif up == "A":
            v = take(7)
            if v is None:
                break
            i += 7
            cx = cx + v[5] if rel else v[5]
            cy = cy + v[6] if rel else v[6]
            xs.append(cx)
            ys.append(cy)
        else:
            i += 1

    if not xs or not ys:
        return None
    return (min(xs), min(ys), max(xs), max(ys))


def primitive_local_bbox(elem: ET.Element, tag: str) -> tuple[float, float, float, float] | None:
    if tag == "circle":
        cx = parse_float(elem.attrib.get("cx"))
        cy = parse_float(elem.attrib.get("cy"))
        r = parse_float(elem.attrib.get("r"))
        return (cx - r, cy - r, cx + r, cy + r)
    if tag in ("rect", "image"):
        w_raw = elem.attrib.get("width", "0")
        if "%" in w_raw:
            return None
        x = parse_float(elem.attrib.get("x"))
        y = parse_float(elem.attrib.get("y"))
        w = parse_float(w_raw)
        h = parse_float(elem.attrib.get("height"))
        return (min(x, x + w), min(y, y + h), max(x, x + w), max(y, y + h))
    if tag == "line":
        x1 = parse_float(elem.attrib.get("x1"))
        y1 = parse_float(elem.attrib.get("y1"))
        x2 = parse_float(elem.attrib.get("x2"))
        y2 = parse_float(elem.attrib.get("y2"))
        return (min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2))
    if tag in ("polyline", "polygon"):
        nums = [float(v) for v in NUM_RE.findall(elem.attrib.get("points", ""))]
        if len(nums) < 2:
            return None
        xs = nums[0::2]
        ys = nums[1::2]
        return (min(xs), min(ys), max(xs), max(ys))
    if tag == "path":
        return parse_path_bbox(elem.attrib.get("d"))
    if tag == "text":
        x = parse_float(elem.attrib.get("x"))
        y = parse_float(elem.attrib.get("y"))
        return (x, y, x, y)
    return None


def index_svg_leaves(svg_path: Path) -> dict[str, list[dict]]:
    tree = ET.parse(svg_path)
    root = tree.getroot()
    leaves: dict[str, list[dict]] = {}

    def walk(
        node: ET.Element,
        cur_leaf: str | None,
        in_defs: bool,
        ctm: tuple[float, float, float, float, float, float],
    ) -> None:
        tag = local_tag(node)
        if tag in ("defs", "clipPath", "mask", "pattern"):
            in_defs = True

        local_m = parse_transform_matrix(node.attrib.get("transform"))
        a1, b1, c1, d1, e1, f1 = ctm
        a2, b2, c2, d2, e2, f2 = local_m
        next_ctm = (
            a1 * a2 + c1 * b2,
            b1 * a2 + d1 * b2,
            a1 * c2 + c1 * d2,
            b1 * c2 + d1 * d2,
            a1 * e2 + c1 * f2 + e1,
            b1 * e2 + d1 * f2 + f1,
        )

        lid = node.attrib.get("data-gloss-leaf")
        if lid is None and tag == "g":
            gid = node.attrib.get("id", "")
            if re.match(r"^L\d+$", gid):
                lid = gid
        if lid is not None and not in_defs:
            cur_leaf = lid
            leaves.setdefault(lid, [])

        if not in_defs and cur_leaf is not None and tag in PRIM_TAGS:
            raw_box = primitive_local_bbox(node, tag)
            world_box = apply_affine_to_box(raw_box, next_ctm)
            leaves[cur_leaf].append(
                {
                    "tag": tag,
                    "bbox": world_box,
                    "text": "".join(node.itertext()),
                    "fill": get_prop(node, "fill"),
                    "stroke": get_prop(node, "stroke"),
                }
            )

        for child in node:
            walk(child, cur_leaf, in_defs, next_ctm)

    walk(root, None, False, (1.0, 0.0, 0.0, 1.0, 0.0, 0.0))
    return leaves


def verify_fidelity(
    bundle_dir: Path,
    derived_svg: Path,
    derived_manifest_path: Path | None = None,
    write_manifest_path: Path | None = None,
    operations_json: str = "[]",
    tol_pt: float = 0.05,
    allow_label_move: bool = False,
) -> dict:
    violations: list[dict] = []

    manifest_path = bundle_dir / "manifest.json"
    asset_map_path = bundle_dir / "asset-map.json"
    scene_svg_path = bundle_dir / "scene" / "scene.svg"
    leaves_json_path = bundle_dir / "scene" / "leaves.json"

    for req in (manifest_path, asset_map_path, scene_svg_path, derived_svg):
        if not req.exists():
            return {
                "status": "FAIL",
                "violations": [{"kind": "missing_file", "path": str(req)}],
            }

    asset_map = json.loads(asset_map_path.read_text(encoding="utf-8"))
    parent_manifest_sha = sha256_file(manifest_path)
    actual_scene_sha = sha256_file(scene_svg_path)
    expected_scene_sha = asset_map.get("scene", {}).get("scene_svg", {}).get("sha256")
    if expected_scene_sha and actual_scene_sha != expected_scene_sha:
        violations.append(
            {
                "kind": "source_scene_mutated",
                "expected_sha256": expected_scene_sha,
                "actual_sha256": actual_scene_sha,
            }
        )

    derived_sha = sha256_file(derived_svg)
    derived_bytes = derived_svg.stat().st_size

    if write_manifest_path is not None:
        ops = json.loads(operations_json)
        manifest_payload = {
            "format": "gloss-derived-svg",
            "schema_version": asset_map.get("schema_version", "1.0.0"),
            "capture_id": asset_map.get("capture_id"),
            "parent_manifest_sha256": parent_manifest_sha,
            "parent_scene_sha256": actual_scene_sha,
            "derived_svg": {
                "path": derived_svg.name,
                "bytes": derived_bytes,
                "sha256": derived_sha,
            },
            "operations": ops,
            "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        write_manifest_path.parent.mkdir(parents=True, exist_ok=True)
        write_manifest_path.write_text(json.dumps(manifest_payload, indent=2) + "\n", encoding="utf-8")
        derived_manifest_path = write_manifest_path

    if derived_manifest_path is not None:
        if not derived_manifest_path.exists():
            violations.append({"kind": "missing_derived_manifest", "path": str(derived_manifest_path)})
        else:
            dm = json.loads(derived_manifest_path.read_text(encoding="utf-8"))
            if dm.get("parent_manifest_sha256") != parent_manifest_sha:
                violations.append(
                    {
                        "kind": "manifest_lineage_mismatch",
                        "field": "parent_manifest_sha256",
                        "expected": parent_manifest_sha,
                        "observed": dm.get("parent_manifest_sha256"),
                    }
                )
            if dm.get("parent_scene_sha256") and dm.get("parent_scene_sha256") != actual_scene_sha:
                violations.append(
                    {
                        "kind": "manifest_lineage_mismatch",
                        "field": "parent_scene_sha256",
                        "expected": actual_scene_sha,
                        "observed": dm.get("parent_scene_sha256"),
                    }
                )
            d_svg_meta = dm.get("derived_svg", {})
            if d_svg_meta.get("sha256") != derived_sha:
                violations.append(
                    {
                        "kind": "derived_digest_mismatch",
                        "expected": derived_sha,
                        "observed": d_svg_meta.get("sha256"),
                    }
                )

    layers_by_id = {
        int(lyr["layer_id"]): lyr
        for lyr in asset_map.get("ir", {}).get("layers", [])
        if lyr.get("layer_id") is not None
    }
    leaves_meta = {}
    if leaves_json_path.exists():
        for lf in json.loads(leaves_json_path.read_text(encoding="utf-8")):
            leaves_meta[lf["leaf_id"]] = lf

    orig_leaves = index_svg_leaves(scene_svg_path)
    der_leaves = index_svg_leaves(derived_svg)

    checked_data_leaves = 0
    checked_primitives = 0
    checked_texts = 0
    color_remaps: dict[str, set[str]] = {}

    for lin in asset_map.get("lineage", []):
        lid = lin["leaf_id"]
        layer_id = lin.get("layer_id")
        slot = str(lin.get("layout_slot") or leaves_meta.get(lid, {}).get("layout_slot") or "")

        if layer_id is not None:
            geom = str(layers_by_id.get(int(layer_id), {}).get("geom", ""))
            sem_role = str(lin.get("semantic_role") or leaves_meta.get(lid, {}).get("semantic_role") or "")
            edit_pol = str(lin.get("edit_policy") or leaves_meta.get(lid, {}).get("edit_policy") or "")
            is_label_layer = (
                sem_role in ("data_label", "leader_line")
                or edit_pol == "movable"
                or (not sem_role and geom in LABEL_GEOMS)
            )

            if lid not in der_leaves:
                violations.append({"kind": "missing_data_leaf", "leaf_id": lid, "geom": geom})
                continue

            o_prims = orig_leaves.get(lid, [])
            d_prims = der_leaves.get(lid, [])

            if is_label_layer and allow_label_move:
                o_txts = Counter(p["text"] for p in o_prims if p["tag"] == "text" and p["text"].strip())
                d_txts = Counter(p["text"] for p in d_prims if p["tag"] == "text" and p["text"].strip())
                checked_texts += sum(o_txts.values())
                if o_txts != d_txts:
                    violations.append(
                        {
                            "kind": "text_mismatch",
                            "leaf_id": lid,
                            "expected": dict(o_txts),
                            "observed": dict(d_txts),
                        }
                    )
                continue

            checked_data_leaves += 1
            if len(o_prims) != len(d_prims):
                violations.append(
                    {
                        "kind": "primitive_count_mismatch",
                        "leaf_id": lid,
                        "expected": len(o_prims),
                        "observed": len(d_prims),
                    }
                )
                continue

            for idx, (op, dp) in enumerate(zip(o_prims, d_prims)):
                checked_primitives += 1
                if op["tag"] != dp["tag"]:
                    violations.append(
                        {
                            "kind": "primitive_tag_mismatch",
                            "leaf_id": lid,
                            "ordinal": idx + 1,
                            "expected": op["tag"],
                            "observed": dp["tag"],
                        }
                    )
                    continue

                if op["tag"] == "text" and op["text"] != dp["text"]:
                    violations.append(
                        {
                            "kind": "text_mismatch",
                            "leaf_id": lid,
                            "ordinal": idx + 1,
                            "expected": op["text"],
                            "observed": dp["text"],
                        }
                    )

                ob, db = op["bbox"], dp["bbox"]
                if ob is not None and db is not None:
                    ocx, ocy = (ob[0] + ob[2]) / 2.0, (ob[1] + ob[3]) / 2.0
                    dcx, dcy = (db[0] + db[2]) / 2.0, (db[1] + db[3]) / 2.0
                    ow, oh = ob[2] - ob[0], ob[3] - ob[1]
                    dw, dh = db[2] - db[0], db[3] - db[1]
                    max_delta = max(abs(ocx - dcx), abs(ocy - dcy), abs(ow - dw), abs(oh - dh))
                    if max_delta > tol_pt:
                        violations.append(
                            {
                                "kind": "geometry_drift",
                                "leaf_id": lid,
                                "ordinal": idx + 1,
                                "tag": op["tag"],
                                "max_delta_pt": round(max_delta, 4),
                                "tol_pt": tol_pt,
                                "expected_bbox": [round(v, 3) for v in ob],
                                "observed_bbox": [round(v, 3) for v in db],
                            }
                        )

                for prop in ("fill", "stroke"):
                    ov, dv = op.get(prop), dp.get(prop)
                    if ov and dv and ov != "none" and dv != "none":
                        color_remaps.setdefault(ov.upper(), set()).add(dv.upper())

        elif slot.startswith("axis"):
            # Axis tick numeric/category strings must never be altered silently
            o_prims = orig_leaves.get(lid, [])
            d_prims = der_leaves.get(lid, [])
            o_txts = Counter(p["text"].strip() for p in o_prims if p["tag"] == "text" and p["text"].strip())
            if o_txts:
                if lid not in der_leaves:
                    violations.append({"kind": "missing_axis_text_leaf", "leaf_id": lid})
                else:
                    d_txts = Counter(
                        p["text"].strip() for p in d_prims if p["tag"] == "text" and p["text"].strip()
                    )
                    checked_texts += sum(o_txts.values())
                    if o_txts != d_txts:
                        violations.append(
                            {
                                "kind": "text_mismatch",
                                "leaf_id": lid,
                                "role": "axis_ticks",
                                "expected": dict(o_txts),
                                "observed": dict(d_txts),
                            }
                        )

    # Verify discrete scale palette consistency across data leaves & guide-box legend keys
    scale_colors = {
        str(m.get("value", "")).upper()
        for sc in asset_map.get("ir", {}).get("scales", [])
        for m in sc.get("map", [])
        if str(m.get("value", "")).startswith("#")
    }
    remapped_scale_colors: dict[str, set[str]] = {}
    for oc, dcs in color_remaps.items():
        if oc not in scale_colors:
            continue
        non_self = {dc for dc in dcs if dc != oc}
        if not non_self:
            continue
        remapped_scale_colors[oc] = non_self
        if len(dcs) > 1:
            violations.append(
                {
                    "kind": "inconsistent_scale_color",
                    "original_color": oc,
                    "observed_colors": sorted(dcs),
                }
            )

    if remapped_scale_colors:
        for lin in asset_map.get("lineage", []):
            lid = lin["leaf_id"]
            slot = str(lin.get("layout_slot") or leaves_meta.get(lid, {}).get("layout_slot") or "")
            if not slot.startswith("guide-box") or lid not in der_leaves:
                continue
            for dp in der_leaves[lid]:
                for prop in ("fill", "stroke"):
                    dv = (dp.get(prop) or "").upper()
                    if dv in remapped_scale_colors:
                        violations.append(
                            {
                                "kind": "stale_legend_color",
                                "leaf_id": lid,
                                "property": prop,
                                "stale_color": dv,
                                "expected_remapped_color": sorted(remapped_scale_colors[dv]),
                            }
                        )

    return {
        "status": "PASS" if not violations else "FAIL",
        "capture_id": asset_map.get("capture_id"),
        "parent_manifest_sha256": parent_manifest_sha,
        "derived_svg_sha256": derived_sha,
        "checked_data_leaves": checked_data_leaves,
        "checked_primitives": checked_primitives,
        "checked_texts": checked_texts,
        "tol_pt": tol_pt,
        "violations": violations,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Verify geometric and cryptographic fidelity of a derived SVG.")
    parser.add_argument("--bundle", required=True, type=Path, help="Path to source .gloss bundle directory")
    parser.add_argument("--derived", required=True, type=Path, help="Path to derived SVG file")
    parser.add_argument("--derived-manifest", type=Path, default=None, help="Existing derived-manifest.json to verify")
    parser.add_argument("--write-manifest", type=Path, default=None, help="Write compliant derived-manifest.json to path")
    parser.add_argument("--operations", type=str, default="[]", help="JSON array of refinement operations for manifest")
    parser.add_argument("--tol-pt", type=float, default=0.05, help="Maximum geometric drift tolerance in points")
    parser.add_argument("--allow-label-move", action="store_true", help="Allow nudging GeomText/GeomLabel coordinates")
    args = parser.parse_args(argv)

    report = verify_fidelity(
        bundle_dir=args.bundle,
        derived_svg=args.derived,
        derived_manifest_path=args.derived_manifest,
        write_manifest_path=args.write_manifest,
        operations_json=args.operations,
        tol_pt=args.tol_pt,
        allow_label_move=args.allow_label_move,
    )
    print(json.dumps(report, indent=2))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
