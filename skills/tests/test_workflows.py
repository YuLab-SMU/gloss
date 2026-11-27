#!/usr/bin/env python3
"""End-to-end cross-language tests for Stage 2 gloss skills & Python verifiers.

Exercises the complete R -> `.gloss/` Asset Bundle -> Python workflow pipeline:
1. Exports a real multi-layer ggplot2 figure (`mtcars` boxplot + points + mean_se
   errorbars + text labels + explicit R source) via `Rscript`.
2. Tests `gloss-svg-refine` (`verify_svg_fidelity.py`):
   - PASS on compliant typography restyling, synchronized palette remapping
     (data marks + legend keys), title nudge, and `GeomText` label nudging with
     `--allow-label-move` + `--write-manifest`.
   - FAIL on moving a `<circle>` data point (`geometry_drift`).
   - FAIL on sneaking a `<g transform="translate(...)">` onto a data leaf.
   - FAIL on altering an axis tick numeric string (`text_mismatch`).
   - FAIL on leaving legend key colors stale after remapping data colors (`stale_legend_color`).
   - FAIL on tampered `parent_manifest_sha256` (`manifest_lineage_mismatch`).
3. Tests `gloss-audit` (`audit_bundle.py`):
   - Verifies `manifest.json` SHA-256 integrity, `stat_role` summaries, and
     grouped metrics.
   - Evaluates a batch of true quantitative claims (`PASS`) and catches a
     contradictory caption claim (`FAIL`).
"""

from __future__ import annotations

import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

REPO_ROOT = Path(__file__).resolve().parents[2]
VERIFY_SCRIPT = REPO_ROOT / "skills" / "gloss-svg-refine" / "scripts" / "verify_svg_fidelity.py"
PATCH_SCRIPT = REPO_ROOT / "skills" / "gloss-svg-refine" / "scripts" / "apply_visual_patch.py"
AUDIT_SCRIPT = REPO_ROOT / "skills" / "gloss-audit" / "scripts" / "audit_bundle.py"
FOCUS_SCRIPT = REPO_ROOT / "skills" / "gloss" / "scripts" / "focus_bridge.py"
WORKSPACE_SCRIPT = REPO_ROOT / "skills" / "gloss" / "scripts" / "workspace_state.py"


class TestGlossDownstreamWorkflows(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._tmpdir = tempfile.TemporaryDirectory(prefix="gloss_py_wf_")
        cls.workdir = Path(cls._tmpdir.name)
        cls.bundle_dir = cls.workdir / "mtcars.gloss"
        cls.src_script = cls.workdir / "plot_mtcars.R"
        cls.src_script.write_text(
            "# Study figure script\np <- ggplot(mtcars, aes(factor(cyl), mpg, colour = factor(cyl))) + geom_boxplot()\n",
            encoding="utf-8",
        )

        r_code = f"""
        pkgload::load_all({json.dumps(str(REPO_ROOT))}, quiet = TRUE)
        df <- datasets::mtcars
        df$car_id <- rownames(df)
        lbl_df <- df[c(1, 20), , drop = FALSE]
        p <- ggplot2::ggplot(df, ggplot2::aes(factor(cyl), mpg, colour = factor(cyl))) +
          ggplot2::geom_boxplot(alpha = 0.35) +
          ggplot2::geom_point(size = 2) +
          ggplot2::stat_summary(fun.data = ggplot2::mean_se, geom = "errorbar", width = 0.2) +
          ggplot2::geom_text(data = lbl_df, ggplot2::aes(label = car_id), vjust = -0.8) +
          ggplot2::scale_colour_manual(values = c("4" = "#E64B35", "6" = "#4DBBD5", "8" = "#00A087")) +
          ggplot2::labs(title = "Fuel Economy by Cylinder Group", colour = "Cyl")
        cap <- gloss(p, sources = list(code = {json.dumps(str(cls.src_script))}), width = 7, height = 5)
        gl_asset_bundle(cap, path = {json.dumps(str(cls.bundle_dir))})
        """
        proc = subprocess.run(
            ["Rscript", "-e", r_code],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"R bundle fixture failed:\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._tmpdir.cleanup()

    def run_cli(self, script: Path, *args: str) -> tuple[int, dict]:
        proc = subprocess.run(
            [sys.executable, str(script), *args],
            capture_output=True,
            text=True,
            check=False,
        )
        try:
            payload = json.loads(proc.stdout)
        except json.JSONDecodeError as exc:
            raise AssertionError(
                f"CLI did not emit valid JSON (rc={proc.returncode}):\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}"
            ) from exc
        return proc.returncode, payload

    def test_svg_refine_compliant_derivation_passes(self) -> None:
        scene_svg = (self.bundle_dir / "scene" / "scene.svg").read_text(encoding="utf-8")
        asset_map = json.loads((self.bundle_dir / "asset-map.json").read_text(encoding="utf-8"))

        # Find the GeomText layer leaf ID so we can nudge its <text> position safely
        label_layer_ids = {
            lyr["layer_id"]
            for lyr in asset_map["ir"]["layers"]
            if lyr["geom"] == "GeomText"
        }
        label_leaf_ids = {
            lin["leaf_id"]
            for lin in asset_map["lineage"]
            if lin.get("layer_id") in label_layer_ids
        }
        self.assertTrue(len(label_leaf_ids) >= 1)

        # 1. Restyle font-family globally + remap #E64B35 -> #0072B2 across BOTH data & legend
        refined_txt = scene_svg.replace("Arial", "Helvetica").replace("#E64B35", "#0072B2")
        root = ET.fromstring(refined_txt)
        for g in root.iter():
            if g.attrib.get("data-gloss-leaf") in label_leaf_ids:
                for child in g:
                    if child.tag.endswith("text") and "y" in child.attrib:
                        child.attrib["y"] = f"{float(child.attrib['y']) - 4.0:.2f}"

        derived_dir = self.workdir / "derived_ok"
        derived_dir.mkdir(exist_ok=True)
        pub_svg = derived_dir / "mtcars-pub.svg"
        d_manifest = derived_dir / "derived-manifest.json"
        ET.ElementTree(root).write(pub_svg, encoding="utf-8", xml_declaration=True)

        rc, report = self.run_cli(
            VERIFY_SCRIPT,
            "--bundle",
            str(self.bundle_dir),
            "--derived",
            str(pub_svg),
            "--write-manifest",
            str(d_manifest),
            "--allow-label-move",
            "--operations",
            json.dumps([{"kind": "palette_remap", "from": "#E64B35", "to": "#0072B2"}]),
        )
        self.assertEqual(rc, 0, msg=json.dumps(report, indent=2))
        self.assertEqual(report["status"], "PASS")
        self.assertGreater(report["checked_data_leaves"], 0)
        self.assertGreater(report["checked_primitives"], 30)
        self.assertTrue(d_manifest.exists())

        dm = json.loads(d_manifest.read_text(encoding="utf-8"))
        self.assertEqual(dm["format"], "gloss-derived-svg")
        self.assertEqual(dm["parent_manifest_sha256"], report["parent_manifest_sha256"])

    def test_svg_refine_catches_data_point_drift_group_transform_text_and_stale_legend(self) -> None:
        scene_svg = (self.bundle_dir / "scene" / "scene.svg").read_text(encoding="utf-8")
        asset_map = json.loads((self.bundle_dir / "asset-map.json").read_text(encoding="utf-8"))

        point_layer_ids = {
            lyr["layer_id"] for lyr in asset_map["ir"]["layers"] if lyr["geom"] == "GeomPoint"
        }
        point_leaf = next(
            lin["leaf_id"] for lin in asset_map["lineage"] if lin.get("layer_id") in point_layer_ids
        )

        # Case A: Move a single <circle> cx by +2.5pt -> MUST FAIL with geometry_drift
        root_a = ET.fromstring(scene_svg)
        for g in root_a.iter():
            if g.attrib.get("data-gloss-leaf") == point_leaf:
                first_circle = next(c for c in g if c.tag.endswith("circle"))
                first_circle.attrib["cx"] = f"{float(first_circle.attrib['cx']) + 2.5:.2f}"
                break
        bad_point_svg = self.workdir / "bad_point.svg"
        ET.ElementTree(root_a).write(bad_point_svg, encoding="utf-8", xml_declaration=True)
        rc_a, rep_a = self.run_cli(
            VERIFY_SCRIPT, "--bundle", str(self.bundle_dir), "--derived", str(bad_point_svg)
        )
        self.assertEqual(rc_a, 1)
        self.assertTrue(any(v["kind"] == "geometry_drift" for v in rep_a["violations"]))

        # Case B: Sneak a group transform="translate(5, 0)" onto the point leaf <g> -> MUST FAIL
        root_b = ET.fromstring(scene_svg)
        for g in root_b.iter():
            if g.attrib.get("data-gloss-leaf") == point_leaf:
                g.attrib["transform"] = "translate(5, 0)"
                break
        bad_tr_svg = self.workdir / "bad_transform.svg"
        ET.ElementTree(root_b).write(bad_tr_svg, encoding="utf-8", xml_declaration=True)
        rc_b, rep_b = self.run_cli(
            VERIFY_SCRIPT, "--bundle", str(self.bundle_dir), "--derived", str(bad_tr_svg)
        )
        self.assertEqual(rc_b, 1)
        self.assertTrue(any(v["kind"] == "geometry_drift" for v in rep_b["violations"]))

        # Case C: Alter an axis tick label ("20" -> "29") -> MUST FAIL with text_mismatch
        bad_axis_txt = re.sub(r">20</text>", ">29</text>", scene_svg, count=1)
        bad_axis_svg = self.workdir / "bad_axis.svg"
        bad_axis_svg.write_text(bad_axis_txt, encoding="utf-8")
        rc_c, rep_c = self.run_cli(
            VERIFY_SCRIPT, "--bundle", str(self.bundle_dir), "--derived", str(bad_axis_svg)
        )
        self.assertEqual(rc_c, 1)
        self.assertTrue(any(v["kind"] == "text_mismatch" for v in rep_c["violations"]))

        # Case D: Remap color on data leaf ONLY, leaving guide-box legend stale -> MUST FAIL
        root_d = ET.fromstring(scene_svg)
        for g in root_d.iter():
            if g.attrib.get("data-gloss-leaf") == point_leaf:
                for c in g.iter():
                    if "style" in c.attrib:
                        c.attrib["style"] = c.attrib["style"].replace("#E64B35", "#0072B2")
        bad_leg_svg = self.workdir / "bad_legend.svg"
        ET.ElementTree(root_d).write(bad_leg_svg, encoding="utf-8", xml_declaration=True)
        rc_d, rep_d = self.run_cli(
            VERIFY_SCRIPT, "--bundle", str(self.bundle_dir), "--derived", str(bad_leg_svg)
        )
        self.assertEqual(rc_d, 1)
        self.assertTrue(any(v["kind"] == "stale_legend_color" for v in rep_d["violations"]))

        # Case E: Tampered parent_manifest_sha256 in derived-manifest.json -> MUST FAIL
        bad_dm = self.workdir / "bad-derived-manifest.json"
        bad_dm.write_text(
            json.dumps(
                {
                    "format": "gloss-derived-svg",
                    "parent_manifest_sha256": "0" * 64,
                    "derived_svg": {"path": "scene.svg", "sha256": "0" * 64},
                }
            ),
            encoding="utf-8",
        )
        rc_e, rep_e = self.run_cli(
            VERIFY_SCRIPT,
            "--bundle",
            str(self.bundle_dir),
            "--derived",
            str(self.bundle_dir / "scene" / "scene.svg"),
            "--derived-manifest",
            str(bad_dm),
        )
        self.assertEqual(rc_e, 1)
        self.assertTrue(any(v["kind"] == "manifest_lineage_mismatch" for v in rep_e["violations"]))

    def test_audit_bundle_profiles_stats_and_verifies_claims(self) -> None:
        true_claims = [
            {"id": "C1", "statement": "n = 32 cars", "table": "raw", "op": "nrow", "expected": 32, "tol": 0},
            {
                "id": "C2",
                "statement": "4-cyl mean mpg is 26.66",
                "table": "raw",
                "column": "mpg",
                "where": {"cyl": "4"},
                "op": "mean",
                "expected": 26.66,
                "tol": 0.01,
            },
            {
                "id": "C3",
                "statement": "8-cyl median mpg is 15.2",
                "table": "raw",
                "column": "mpg",
                "where": {"cyl": "8"},
                "op": "median",
                "expected": 15.2,
                "tol": 0.01,
            },
        ]
        claims_ok_path = self.workdir / "claims_ok.json"
        claims_ok_path.write_text(json.dumps(true_claims), encoding="utf-8")

        rc_ok, rep_ok = self.run_cli(
            AUDIT_SCRIPT, "--bundle", str(self.bundle_dir), "--claims", str(claims_ok_path)
        )
        self.assertEqual(rc_ok, 0, msg=json.dumps(rep_ok, indent=2))
        self.assertTrue(rep_ok["manifest_integrity"]["valid"])
        self.assertIn("middle", rep_ok["tables"]["built_layer1"]["stat_role_summaries"])
        self.assertEqual(
            rep_ok["tables"]["built_layer1"]["stat_role_summaries"]["middle"]["stat_role"],
            "median",
        )
        self.assertTrue(all(c["status"] == "PASS" for c in rep_ok["claim_results"]))

        # Contradictory claim in manuscript caption -> MUST exit 1 with FAIL verdict
        bad_claims = true_claims + [
            {
                "id": "C4_WRONG",
                "statement": "4-cyl mean mpg is 31.5 (false claim)",
                "table": "raw",
                "column": "mpg",
                "where": {"cyl": "4"},
                "op": "mean",
                "expected": 31.5,
                "tol": 0.1,
            }
        ]
        claims_bad_path = self.workdir / "claims_bad.json"
        claims_bad_path.write_text(json.dumps(bad_claims), encoding="utf-8")
        rc_bad, rep_bad = self.run_cli(
            AUDIT_SCRIPT, "--bundle", str(self.bundle_dir), "--claims", str(claims_bad_path)
        )
        self.assertEqual(rc_bad, 1)
        c4 = next(c for c in rep_bad["claim_results"] if c["id"] == "C4_WRONG")
        self.assertEqual(c4["status"], "FAIL")
        self.assertAlmostEqual(c4["observed"], 26.663636, places=4)

        # Verify Schema v1.1 layer params (mean_se) are surfaced in audit report
        lyr3 = next(l for l in rep_ok["layers"] if l["layer_id"] == 3)
        self.assertEqual(lyr3["params"].get("fun.data"), "mean_se")

    def test_v11_declarative_visual_patch_focus_bridge_and_shared_workspace(self) -> None:
        # 1. Verify Schema v1.1 perception split (texts.json + preview.png)
        self.assertTrue((self.bundle_dir / "scene" / "texts.json").exists())
        self.assertTrue((self.bundle_dir / "assets" / "preview.png").exists())
        texts = json.loads((self.bundle_dir / "scene" / "texts.json").read_text(encoding="utf-8"))
        self.assertTrue(any(t["text"] == "Fuel Economy by Cylinder Group" for t in texts))

        # 2. Initialize companion .gloss.work/ shared workspace without mutating source bundle
        work_dir = self.workdir / "mtcars.gloss.work"
        rc_w, w_meta = self.run_cli(WORKSPACE_SCRIPT, "init", "--bundle", str(self.bundle_dir), "--work-dir", str(work_dir))
        self.assertEqual(rc_w, 0)
        self.assertTrue((work_dir / "workspace.json").exists())

        # 3. Bidirectional Focus/Overlay bridge (rows-to-overlay -> box-to-rows roundtrip)
        focus_out = work_dir / "focus.json"
        ov_svg = work_dir / "derived" / "highlight-overlay.svg"
        rc_r2o, r2o = self.run_cli(
            FOCUS_SCRIPT,
            "rows-to-overlay",
            "--bundle",
            str(self.bundle_dir),
            "--table",
            "raw",
            "--rows",
            "1,20",
            "--note",
            "Highlighted cars",
            "--focus-out",
            str(focus_out),
            "--svg-out",
            str(ov_svg),
        )
        self.assertEqual(rc_r2o, 0, msg=json.dumps(r2o, indent=2))
        self.assertEqual(r2o["format"], "gloss-focus")
        self.assertTrue(len(r2o["targets"]) >= 1)
        self.assertTrue(ov_svg.exists())
        self.assertIn("gloss-agent-overlay", ov_svg.read_text(encoding="utf-8"))

        # Brush around the first matched point target box -> box-to-rows recovers raw rows
        pt_target = next(t for t in r2o["targets"] if t["built_table"] == "built_layer2" and t.get("bbox_pt"))
        bb = pt_target["bbox_pt"]
        qbox = f"{bb[0]-2},{bb[1]-2},{bb[2]+2},{bb[3]+2}"
        rc_b2r, b2r = self.run_cli(FOCUS_SCRIPT, "box-to-rows", "--bundle", str(self.bundle_dir), "--box", qbox)
        self.assertEqual(rc_b2r, 0)
        pt_b2r = next(t for t in b2r["targets"] if t["built_table"] == "built_layer2")
        self.assertTrue({1, 20}.issubset(set(pt_b2r["row_ids"])))

        # 4. Declarative Visual Patch applier (palette remap + typography + movable label + callout)
        lbl_text = next(t for t in texts if t["semantic_role"] == "data_label")
        patch_doc = {
            "format": "gloss-visual-patch",
            "schema_version": "1.1.0",
            "operations": [
                {"kind": "set_typography", "font_family": "Helvetica", "roles": ["plot_title", "axis_title"]},
                {"kind": "remap_scale_palette", "aesthetic": "colour", "mapping": {"4": "#0072B2", "8": "#D55E00"}},
                {"kind": "translate_label", "element_id": lbl_text["element_id"], "dx": 5.0, "dy": -4.0},
                {"kind": "add_callout", "panel_id": "P1", "raw_row_id": 20, "text": "Toyota Corolla", "offset_pt": [18, -14]},
            ],
        }
        patch_path = work_dir / "patches" / "pub-v1.json"
        patch_path.write_text(json.dumps(patch_doc, indent=2), encoding="utf-8")
        out_svg = work_dir / "derived" / "mtcars-patched.svg"
        out_mf = work_dir / "derived" / "mtcars-patched-manifest.json"
        rc_p, rep_p = self.run_cli(
            PATCH_SCRIPT,
            "--bundle",
            str(self.bundle_dir),
            "--patch",
            str(patch_path),
            "--out",
            str(out_svg),
            "--manifest",
            str(out_mf),
        )
        self.assertEqual(rc_p, 0, msg=json.dumps(rep_p, indent=2))
        self.assertEqual(rep_p["status"], "PASS")
        self.assertIn("Toyota Corolla", out_svg.read_text(encoding="utf-8"))

        # Patch applier MUST refuse translating a geometry_locked data mark element
        elements = json.loads((self.bundle_dir / "scene" / "elements.json").read_text(encoding="utf-8"))
        locked_pt = next(e for e in elements if e.get("part_role") == "point")
        bad_patch = work_dir / "patches" / "illegal.json"
        bad_patch.write_text(
            json.dumps({"operations": [{"kind": "translate_label", "element_id": locked_pt["element_id"], "dx": 10, "dy": 0}]}),
            encoding="utf-8",
        )
        bad_proc = subprocess.run(
            [sys.executable, str(PATCH_SCRIPT), "--bundle", str(self.bundle_dir), "--patch", str(bad_patch), "--out", str(work_dir / "derived" / "nope.svg")],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(bad_proc.returncode, 0)
        self.assertIn("geometry_locked", bad_proc.stderr)

        # 5. Audit silent drops + emit threads + human resolution in .gloss.work/threads.json
        drop_bundle = self.workdir / "drops.gloss"
        r_drop = f"""
        pkgload::load_all({json.dumps(str(REPO_ROOT))}, quiet = TRUE)
        df <- data.frame(x = c(1, 2, NA, 50, 999), y = c(2, 4, 6, 8, 10))
        p <- ggplot2::ggplot(df, ggplot2::aes(x, y)) + ggplot2::geom_point() + ggplot2::scale_x_continuous(limits = c(0, 100))
        cap <- suppressWarnings(gloss(p))
        gl_asset_bundle(cap, path = {json.dumps(str(drop_bundle))})
        """
        self.assertEqual(subprocess.run(["Rscript", "-e", r_drop], cwd=REPO_ROOT, check=False).returncode, 0)
        threads_file = work_dir / "threads.json"
        rc_au, rep_au = self.run_cli(AUDIT_SCRIPT, "--bundle", str(drop_bundle), "--emit-threads", str(threads_file))
        self.assertEqual(rc_au, 0)
        self.assertEqual(len(rep_au["silent_drop_warnings"]), 1)
        self.assertEqual(rep_au["silent_drop_warnings"][0]["dropped_raw_row_ids"], [3, 5])

        rc_res, resolved = self.run_cli(
            WORKSPACE_SCRIPT,
            "resolve-thread",
            "--work-dir",
            str(work_dir),
            "--thread-id",
            "T001",
            "--status",
            "accepted",
            "--resolution",
            "Document 2 dropped rows in caption",
        )
        self.assertEqual(rc_res, 0)
        self.assertEqual(resolved["status"], "accepted")

    def test_v12_contracts_tokens_entities_and_context_summary(self) -> None:
        v12_bundle = self.workdir / "v12_study.gloss"
        r_v12 = f"""
        pkgload::load_all({json.dumps(str(REPO_ROOT))}, quiet = TRUE)
        full_df <- data.frame(
          patient_id = sprintf("P%03d", 1:12),
          arm = rep(c("Ctrl", "Treat"), each = 6L),
          qc = c(rep(TRUE, 5L), FALSE, rep(TRUE, 5L), FALSE),
          x = c(1:6, 1:6),
          y = c(10, 11, 10.5, 10.8, 36.0, 10, 20, 21, 20.4, 20.9, 21.1, 20),
          stringsAsFactors = FALSE
        )
        df <- subset(full_df, qc)
        p <- ggplot2::ggplot(df, ggplot2::aes(.data$x, .data$y, colour = .data$arm)) +
          ggplot2::geom_point(size = 2.8) +
          ggplot2::geom_hline(yintercept = 15, colour = "#E64B35") +
          ggplot2::scale_colour_manual(values = c("Ctrl" = "#E64B35", "Treat" = "#4DBBD5")) +
          ggplot2::labs(title = "Study Biomarker\\nCohort Comparison")
        cap <- gloss(p, entities = c(subject = "patient_id"), upstream = list(data = full_df, note = "qc == TRUE"))
        gl_asset_bundle(cap, path = {json.dumps(str(v12_bundle))})
        """
        proc = subprocess.run(["Rscript", "-e", r_v12], cwd=REPO_ROOT, capture_output=True, text=True, check=False)
        self.assertEqual(proc.returncode, 0, msg=proc.stderr)

        asset_map = json.loads((v12_bundle / "asset-map.json").read_text(encoding="utf-8"))
        self.assertEqual(asset_map["package_version"], "0.2.0")
        self.assertEqual(asset_map["schema_version"], "1.2.0")
        self.assertIn("role_contracts", asset_map["scene"])
        self.assertEqual(asset_map["ir"]["data_funnel"]["n_upstream_excluded"], 2)
        self.assertTrue(any(e["entity_role"] == "subject" and e["name"] == "patient_id" for e in asset_map["entities"]))

        # K5: Multiline title merged into a single text_block_id in texts.json
        texts = json.loads((v12_bundle / "scene" / "texts.json").read_text(encoding="utf-8"))
        titles = [t for t in texts if t["semantic_role"] == "plot_title"]
        self.assertEqual(len(titles), 2)
        self.assertEqual(titles[0]["text_block_id"], titles[1]["text_block_id"])
        self.assertEqual(titles[0]["block_text"], "Study Biomarker\nCohort Comparison")

        # K3 + K4: Contract-driven verifier allows uniform circle radius shrink (r=1.5),
        # axis tick 45-deg rotation, AND token-aware palette remap leaving un-tokenized hline #E64B35 alone!
        scene_svg = (v12_bundle / "scene" / "scene.svg").read_text(encoding="utf-8")
        root = ET.fromstring(scene_svg)
        pt_leaf = next(ln["leaf_id"] for ln in asset_map["lineage"] if ln.get("layer_id") == 1)
        tick_leaves = {ln["leaf_id"] for ln in asset_map["lineage"] if ln.get("semantic_role") == "axis_tick"}
        guide_leaves = set((asset_map["ir"].get("guides") or {}).get("leaf_ids") or [])

        for g in root.iter():
            lid = g.attrib.get("data-gloss-leaf")
            if lid == pt_leaf:
                for ch in g.iter():
                    if ch.tag.endswith("circle"):
                        ch.attrib["r"] = "1.50"
                        if "style" in ch.attrib:
                            ch.attrib["style"] = ch.attrib["style"].replace("#E64B35", "#0072B2")
            elif lid in guide_leaves:
                for ch in g.iter():
                    if "style" in ch.attrib:
                        ch.attrib["style"] = ch.attrib["style"].replace("#E64B35", "#0072B2")
            elif lid in tick_leaves:
                for ch in g.iter():
                    if ch.tag.endswith("text"):
                        ch.attrib["transform"] = "rotate(-45)"

        ok_svg = self.workdir / "v12_contract_ok.svg"
        ET.ElementTree(root).write(ok_svg, encoding="utf-8", xml_declaration=True)
        rc_ok, rep_ok = self.run_cli(VERIFY_SCRIPT, "--bundle", str(v12_bundle), "--derived", str(ok_svg))
        self.assertEqual(rc_ok, 0, msg=json.dumps(rep_ok, indent=2))
        self.assertEqual(rep_ok["status"], "PASS")

        # K6: focus_bridge.py box-to-rows returns matched patient_id entity & statistical context_summary
        pan_bb = asset_map["ir"]["panels"][0]["bbox_pt"]
        qbox = f"{pan_bb[0]},{pan_bb[1]},{pan_bb[2]},{pan_bb[1] + 0.25 * (pan_bb[3] - pan_bb[1])}"
        rc_b, rep_b = self.run_cli(FOCUS_SCRIPT, "box-to-rows", "--bundle", str(v12_bundle), "--box", qbox)
        self.assertEqual(rc_b, 0, msg=json.dumps(rep_b, indent=2))
        self.assertEqual(rep_b["schema_version"], "1.2.0")
        cs = rep_b["context_summary"]
        self.assertEqual(cs["entities"]["patient_id"]["values"], ["P005"])
        self.assertGreater(cs["comparisons"][0]["metrics"]["y"]["max_abs_z"], 1.5)


if __name__ == "__main__":
    unittest.main(verbosity=2)
