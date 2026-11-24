#!/usr/bin/env python3
"""Zero-dependency declarative Visual Patch applier for gloss-svg-refine.

Compiles a concise `gloss-visual-patch` JSON specification into a derived
publication SVG from an immutable `.gloss/` Asset Bundle, automatically:
1. Enforcing leaf/element `edit_policy` locks (blocking movement of
   `geometry_locked` data marks).
2. Translating movable labels (`translate_label`) along with their paired
   `label_box` and `leader_line` endpoints (`scene.label_links`) while
   warning on `clip_bbox_pt` overflow.
3. Remapping discrete palette colors (`remap_scale_palette`) atomically across
   both data marks and item-level `ir.guides.entries[].items[].swatch_elements`.
4. Repositioning guides (`move_guide`), normalizing typography
   (`set_typography`), and anchoring data-driven callouts (`add_callout`).
5. Emitting `derived-manifest.json` and running `verify_svg_fidelity.py`.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import verify_svg_fidelity as vsf  # noqa: E402

SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)

PRIM_TAGS = {"circle", "rect", "line", "polyline", "polygon", "path", "text", "image"}
STYLE_PROP_RE = re.compile(r"([A-Za-z-]+)\s*:\s*([^;]+)")


def local_tag(elem: ET.Element) -> str:
    t = elem.tag
    return t.split("}", 1)[1] if "}" in t else t


def parse_style(raw: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for m in STYLE_PROP_RE.finditer(raw or ""):
        out[m.group(1).strip()] = m.group(2).strip()
    return out


def format_style(style_map: dict[str, str]) -> str:
    return "; ".join(f"{k}: {v}" for k, v in style_map.items()) + (";" if style_map else "")


def set_style_prop(elem: ET.Element, prop: str, value: str) -> None:
    st = parse_style(elem.attrib.get("style", ""))
    if prop in st or "style" in elem.attrib:
        st[prop] = value
        elem.attrib["style"] = format_style(st)
        if prop in elem.attrib:
            elem.attrib[prop] = value
    else:
        elem.attrib[prop] = value


def get_style_prop(elem: ET.Element, prop: str) -> str | None:
    st = parse_style(elem.attrib.get("style", ""))
    if prop in st:
        return st[prop]
    return elem.attrib.get(prop)


def index_svg_primitives(root: ET.Element) -> tuple[dict[str, ET.Element], dict[str, ET.Element], dict[str, list[ET.Element]]]:
    """Build element_id -> Element, leaf_id -> <g>, and leaf_id -> [Element] maps
    using the exact same traversal order as R `parse_svg_elements()`."""
    el_by_id: dict[str, ET.Element] = {}
    g_by_leaf: dict[str, ET.Element] = {}
    els_by_leaf: dict[str, list[ET.Element]] = {}
    seq = 0

    def walk(node: ET.Element, in_skip: bool, cur_leaf: str | None) -> None:
        nonlocal seq
        tag = local_tag(node)
        skip = in_skip or tag in {"defs", "clipPath", "mask", "pattern"}
        leaf = cur_leaf
        if not skip and tag == "g" and "data-gloss-leaf" in node.attrib:
            leaf = node.attrib["data-gloss-leaf"]
            g_by_leaf.setdefault(leaf, node)
        if not skip and tag in PRIM_TAGS:
            seq += 1
            eid = f"E{seq:04d}"
            el_by_id[eid] = node
            if leaf is not None:
                els_by_leaf.setdefault(leaf, []).append(node)
        for ch in node:
            walk(ch, skip, leaf)

    walk(root, False, None)
    return el_by_id, g_by_leaf, els_by_leaf


def translate_primitive(elem: ET.Element, dx: float, dy: float) -> None:
    tag = local_tag(elem)
    if tag == "text":
        tr = elem.attrib.get("transform", "")
        m = re.search(r"translate\(\s*([-+0-9.eE]+)[\s,]+([-+0-9.eE]+)\s*\)", tr)
        if m:
            nx = float(m.group(1)) + dx
            ny = float(m.group(2)) + dy
            elem.attrib["transform"] = (
                tr[: m.start()] + f"translate({nx:.2f},{ny:.2f})" + tr[m.end() :]
            )
            return
        if "x" in elem.attrib or "y" in elem.attrib:
            x = float(elem.attrib.get("x", "0")) + dx
            y = float(elem.attrib.get("y", "0")) + dy
            elem.attrib["x"] = f"{x:.2f}"
            elem.attrib["y"] = f"{y:.2f}"
            return
    if tag in ("rect", "image"):
        x = float(elem.attrib.get("x", "0")) + dx
        y = float(elem.attrib.get("y", "0")) + dy
        elem.attrib["x"] = f"{x:.2f}"
        elem.attrib["y"] = f"{y:.2f}"
        return
    if tag == "polygon" or tag == "polyline":
        pts = elem.attrib.get("points", "").strip()
        nums = [float(v) for v in re.findall(r"[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?", pts)]
        pairs = []
        for i in range(0, len(nums) - 1, 2):
            pairs.append(f"{nums[i] + dx:.2f},{nums[i + 1] + dy:.2f}")
        elem.attrib["points"] = " ".join(pairs)
        return
    if tag == "line":
        for k, d in (("x1", dx), ("y1", dy), ("x2", dx), ("y2", dy)):
            elem.attrib[k] = f"{float(elem.attrib.get(k, '0')) + d:.2f}"
        return
    # Generic transform fallback
    prev = elem.attrib.get("transform", "").strip()
    elem.attrib["transform"] = f"translate({dx:.2f},{dy:.2f}) {prev}".strip()


def update_leader_endpoint(elem: ET.Element, anchor_pt: list[float], dx: float, dy: float) -> None:
    """Keep the endpoint closest to `anchor_pt` locked and shift the label-side endpoint."""
    tag = local_tag(elem)
    ax, ay = float(anchor_pt[0]), float(anchor_pt[1])
    if tag == "line":
        x1, y1 = float(elem.attrib.get("x1", "0")), float(elem.attrib.get("y1", "0"))
        x2, y2 = float(elem.attrib.get("x2", "0")), float(elem.attrib.get("y2", "0"))
        d1 = math.hypot(x1 - ax, y1 - ay)
        d2 = math.hypot(x2 - ax, y2 - ay)
        if d1 <= d2:
            elem.attrib["x2"] = f"{x2 + dx:.2f}"
            elem.attrib["y2"] = f"{y2 + dy:.2f}"
        else:
            elem.attrib["x1"] = f"{x1 + dx:.2f}"
            elem.attrib["y1"] = f"{y1 + dy:.2f}"
    elif tag == "polyline":
        nums = [float(v) for v in re.findall(r"[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?", elem.attrib.get("points", ""))]
        if len(nums) >= 4:
            d_start = math.hypot(nums[0] - ax, nums[1] - ay)
            d_end = math.hypot(nums[-2] - ax, nums[-1] - ay)
            if d_start <= d_end:
                nums[-2] += dx
                nums[-1] += dy
            else:
                nums[0] += dx
                nums[1] += dy
            pairs = [f"{nums[i]:.2f},{nums[i + 1]:.2f}" for i in range(0, len(nums) - 1, 2)]
            elem.attrib["points"] = " ".join(pairs)


def panel_rendered_to_px(panel: dict, x_ren: float, y_ren: float) -> tuple[float, float] | None:
    bb = panel.get("bbox_pt")
    xd = panel.get("x_domain")
    yd = panel.get("y_domain")
    if not bb or not xd or not yd:
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


def apply_visual_patch(
    bundle_dir: Path,
    patch_doc: dict,
    derived_svg: Path,
    manifest_out: Path | None = None,
    tol_pt: float = 0.05,
) -> dict:
    asset_map = json.loads((bundle_dir / "asset-map.json").read_text(encoding="utf-8"))
    leaves = json.loads((bundle_dir / "scene" / "leaves.json").read_text(encoding="utf-8"))
    elements_meta = (
        json.loads((bundle_dir / "scene" / "elements.json").read_text(encoding="utf-8"))
        if (bundle_dir / "scene" / "elements.json").exists()
        else []
    )

    leaf_by_id = {l["leaf_id"]: l for l in leaves}
    el_meta_by_id = {e["element_id"]: e for e in elements_meta}
    panel_by_id = {p["panel_id"]: p for p in asset_map.get("ir", {}).get("panels", [])}
    label_links = {
        lk["label_element_id"]: lk for lk in asset_map.get("scene", {}).get("label_links", []) if lk.get("label_element_id")
    }

    tree = ET.parse(bundle_dir / "scene" / "scene.svg")
    root = tree.getroot()
    el_by_id, g_by_leaf, els_by_leaf = index_svg_primitives(root)

    warnings: list[dict] = []
    applied_ops: list[dict] = []
    moved_any_label = False

    ops = patch_doc.get("operations", [])
    for op in ops:
        kind = op.get("kind")

        if kind == "translate_label":
            eid = op["element_id"]
            dx = float(op.get("dx", 0.0))
            dy = float(op.get("dy", 0.0))
            if eid not in el_by_id:
                raise ValueError(f"translate_label: unknown element_id '{eid}'")
            emeta = el_meta_by_id.get(eid, {})
            lid = emeta.get("leaf_id")
            lmeta = leaf_by_id.get(lid, {}) if lid else {}
            policy = lmeta.get("edit_policy")
            if policy == "geometry_locked":
                raise PermissionError(
                    f"Refused to translate element '{eid}' in leaf '{lid}': edit_policy is 'geometry_locked'."
                )

            translate_primitive(el_by_id[eid], dx, dy)
            moved_any_label = True

            # Check clip box overflow
            cbox = lmeta.get("clip_bbox_pt")
            if cbox and None not in (emeta.get("bbox_x0"), emeta.get("bbox_y0"), emeta.get("bbox_x1"), emeta.get("bbox_y1")):
                nx0, ny0 = float(emeta["bbox_x0"]) + dx, float(emeta["bbox_y0"]) + dy
                nx1, ny1 = float(emeta["bbox_x1"]) + dx, float(emeta["bbox_y1"]) + dy
                if nx0 < cbox[0] or ny0 < cbox[1] or nx1 > cbox[2] or ny1 > cbox[3]:
                    warnings.append(
                        {
                            "kind": "clip_overflow_warning",
                            "element_id": eid,
                            "leaf_id": lid,
                            "clip_bbox_pt": cbox,
                        }
                    )

            # Automatically translate paired label box & stretch leader line endpoint
            lk = label_links.get(eid)
            leader_updated = False
            if lk:
                bid = lk.get("box_element_id")
                if bid and bid in el_by_id:
                    translate_primitive(el_by_id[bid], dx, dy)
                s_id = lk.get("leader_element_id")
                if s_id and s_id in el_by_id and lk.get("anchor_pt"):
                    update_leader_endpoint(el_by_id[s_id], lk["anchor_pt"], dx, dy)
                    leader_updated = True

            applied_ops.append(
                {
                    "kind": "translate_label",
                    "element_id": eid,
                    "dx": dx,
                    "dy": dy,
                    "leader_updated": leader_updated,
                }
            )

        elif kind == "remap_scale_palette":
            aesthetic = op.get("aesthetic", "colour")
            mapping = {str(k): str(v) for k, v in (op.get("mapping") or {}).items()}
            # Find old hex -> new hex from ir.scales
            old_to_new: dict[str, str] = {}
            for sc in asset_map.get("ir", {}).get("scales", []):
                if sc.get("aesthetic") != aesthetic:
                    continue
                for m in sc.get("map", []):
                    dom = str(m.get("domain", ""))
                    lbl = str(m.get("label", dom))
                    old_val = str(m.get("value", "")).upper()
                    new_val = mapping.get(dom) or mapping.get(lbl)
                    if old_val.startswith("#") and new_val:
                        old_to_new[old_val] = new_val

            # 1. Update data leaves
            data_lids = [ln["leaf_id"] for ln in asset_map.get("lineage", []) if ln.get("layer_id") is not None]
            n_data_updated = 0
            for lid in data_lids:
                for el in els_by_leaf.get(lid, []):
                    for prop in ("fill", "stroke"):
                        cur = (get_style_prop(el, prop) or "").upper()
                        if cur in old_to_new:
                            set_style_prop(el, prop, old_to_new[cur])
                            n_data_updated += 1

            # 2. Update item-level legend swatches via ir.guides.entries (exact, zero color-collision!)
            n_guide_updated = 0
            guides = asset_map.get("ir", {}).get("guides") or {}
            entries = guides.get("entries") or []
            matched_guide_items = False
            for ent in entries:
                ent_aes = ent.get("aesthetics") or []
                if ent_aes and aesthetic not in ent_aes:
                    continue
                for item in ent.get("items", []):
                    dom = str(item.get("domain", ""))
                    lbl = str(item.get("label", dom))
                    new_hex = mapping.get(dom) or mapping.get(lbl)
                    if not new_hex:
                        continue
                    for sw_id in item.get("swatch_elements", []):
                        sw_el = el_by_id.get(sw_id)
                        if sw_el is None:
                            continue
                        matched_guide_items = True
                        for prop in ("fill", "stroke"):
                            cur = (get_style_prop(sw_el, prop) or "").upper()
                            if cur in old_to_new:
                                set_style_prop(sw_el, prop, new_hex)
                                n_guide_updated += 1

            # Fallback for bundles without item-level guides (Schema v1.0)
            if not matched_guide_items:
                for lf in leaves:
                    if str(lf.get("layout_slot", "")).startswith("guide-box"):
                        for el in els_by_leaf.get(lf["leaf_id"], []):
                            for prop in ("fill", "stroke"):
                                cur = (get_style_prop(el, prop) or "").upper()
                                if cur in old_to_new:
                                    set_style_prop(el, prop, old_to_new[cur])
                                    n_guide_updated += 1

            applied_ops.append(
                {
                    "kind": "remap_scale_palette",
                    "aesthetic": aesthetic,
                    "n_data_updated": n_data_updated,
                    "n_guide_updated": n_guide_updated,
                }
            )

        elif kind == "move_guide":
            dx = float(op.get("dx", 0.0))
            dy = float(op.get("dy", 0.0))
            target_lids = list(op.get("leaf_ids") or [])
            gid = op.get("guide_id")
            if gid and not target_lids:
                for ent in (asset_map.get("ir", {}).get("guides") or {}).get("entries", []):
                    if ent.get("guide_id") == gid:
                        target_lids = list(ent.get("leaf_ids") or [])
                        break
            if not target_lids:
                target_lids = list((asset_map.get("ir", {}).get("guides") or {}).get("leaf_ids") or [])
            for lid in target_lids:
                gnode = g_by_leaf.get(lid)
                if gnode is not None:
                    prev = gnode.attrib.get("transform", "").strip()
                    gnode.attrib["transform"] = f"translate({dx:.2f},{dy:.2f}) {prev}".strip()
            applied_ops.append({"kind": "move_guide", "n_leaves": len(target_lids), "dx": dx, "dy": dy})

        elif kind == "set_typography":
            roles = set(op.get("roles") or [])
            ff = op.get("font_family")
            fs_abs = op.get("font_size")
            fs_scale = op.get("font_size_scale")
            n_changed = 0
            for eid, el in el_by_id.items():
                if local_tag(el) != "text":
                    continue
                lid = el_meta_by_id.get(eid, {}).get("leaf_id")
                role = leaf_by_id.get(lid, {}).get("semantic_role", "") if lid else ""
                if roles and role not in roles:
                    continue
                if ff:
                    set_style_prop(el, "font-family", ff)
                if fs_abs is not None:
                    set_style_prop(el, "font-size", f"{float(fs_abs):.2f}px")
                elif fs_scale is not None:
                    cur_fs = vsf.parse_float(get_style_prop(el, "font-size"), 10.0)
                    set_style_prop(el, "font-size", f"{cur_fs * float(fs_scale):.2f}px")
                n_changed += 1
            applied_ops.append({"kind": "set_typography", "font_family": ff, "n_changed": n_changed})

        elif kind == "add_callout":
            pid = op.get("panel_id", "P1")
            text = str(op["text"])
            off = op.get("offset_pt") or [24.0, -24.0]
            pan = panel_by_id.get(pid)
            anchor: tuple[float, float] | None = None

            if "anchor_pt" in op:
                anchor = (float(op["anchor_pt"][0]), float(op["anchor_pt"][1]))
            elif "raw_row_id" in op:
                rr = int(op["raw_row_id"])
                # Resolve raw_row_id -> element center or projected built coordinate
                for lyr in asset_map.get("ir", {}).get("layers", []):
                    btid = lyr.get("built_table")
                    if not btid:
                        continue
                    csv_p = bundle_dir / "tables" / f"{btid}.csv"
                    if not csv_p.exists():
                        continue
                    with csv_p.open("r", encoding="utf-8", newline="") as f:
                        for row in csv.DictReader(f):
                            if row.get("_raw_row_id", "").isdigit() and int(row["_raw_row_id"]) == rr:
                                if pan and row.get("x") and row.get("y"):
                                    anchor = panel_rendered_to_px(pan, float(row["x"]), float(row["y"]))
                                    break
                    if anchor:
                        break
            elif "data_xy" in op and pan:
                anchor = panel_rendered_to_px(pan, float(op["data_xy"][0]), float(op["data_xy"][1]))

            if anchor is None:
                raise ValueError(f"add_callout: could not resolve anchor position for op {op}")

            tx, ty = anchor[0] + float(off[0]), anchor[1] + float(off[1])
            cg = ET.SubElement(root, f"{{{SVG_NS}}}g", {"data-gloss-callout": "true"})
            ET.SubElement(
                cg,
                f"{{{SVG_NS}}}line",
                {
                    "x1": f"{anchor[0]:.2f}",
                    "y1": f"{anchor[1]:.2f}",
                    "x2": f"{tx:.2f}",
                    "y2": f"{ty:.2f}",
                    "stroke": "#333333",
                    "stroke-width": "0.85",
                },
            )
            t_el = ET.SubElement(
                cg,
                f"{{{SVG_NS}}}text",
                {
                    "x": f"{tx:.2f}",
                    "y": f"{ty - 2.0:.2f}",
                    "fill": "#111111",
                    "font-size": "9.0",
                    "text-anchor": "start" if float(off[0]) >= 0 else "end",
                },
            )
            t_el.text = text
            applied_ops.append({"kind": "add_callout", "panel_id": pid, "text": text, "anchor_pt": [round(anchor[0], 2), round(anchor[1], 2)]})

        else:
            raise ValueError(f"Unsupported patch operation kind: {kind!r}")

    derived_svg.parent.mkdir(parents=True, exist_ok=True)
    tree.write(derived_svg, encoding="utf-8", xml_declaration=True)

    m_out = manifest_out or derived_svg.with_suffix(".manifest.json")
    fidelity = vsf.verify_fidelity(
        bundle_dir=bundle_dir,
        derived_svg=derived_svg,
        write_manifest_path=m_out,
        operations_json=json.dumps(applied_ops),
        tol_pt=tol_pt,
        allow_label_move=moved_any_label,
    )

    return {
        "status": fidelity["status"],
        "derived_svg": str(derived_svg),
        "derived_manifest": str(m_out),
        "applied_operations": applied_ops,
        "warnings": warnings,
        "fidelity": fidelity,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Apply a declarative gloss-visual-patch JSON to a .gloss bundle.")
    parser.add_argument("--bundle", required=True, type=Path)
    parser.add_argument("--patch", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--manifest", type=Path, default=None)
    parser.add_argument("--tol-pt", type=float, default=0.05)
    args = parser.parse_args(argv)

    patch_doc = json.loads(args.patch.read_text(encoding="utf-8"))
    report = apply_visual_patch(
        bundle_dir=args.bundle,
        patch_doc=patch_doc,
        derived_svg=args.out,
        manifest_out=args.manifest,
        tol_pt=args.tol_pt,
    )
    print(json.dumps(report, indent=2))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
