#!/usr/bin/env python3
"""Zero-dependency shared workspace manager for read-only gloss Asset Bundles.

Maintains a mutable companion directory `<figure>.gloss.work/` beside the
immutable `<figure>.gloss/` compiler snapshot so humans, Workbench UIs, and
multiple AI agents (gloss-audit, gloss-svg-refine, gloss-report) share durable
focus selections, anchored review threads, decisions, and derived patches
across sessions without mutating a single byte of the source bundle.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys


def now_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def init_workspace(bundle_dir: Path, work_dir: Path | None = None) -> dict:
    wdir = work_dir or Path(f"{bundle_dir}.work")
    mpath = bundle_dir / "manifest.json"
    if not mpath.exists():
        raise FileNotFoundError(f"Source bundle missing manifest.json: {bundle_dir}")
    manifest = json.loads(mpath.read_text(encoding="utf-8"))

    wdir.mkdir(parents=True, exist_ok=True)
    (wdir / "patches").mkdir(exist_ok=True)
    (wdir / "derived").mkdir(exist_ok=True)

    meta = {
        "format": "gloss-workspace",
        "schema_version": "1.1.0",
        "source_bundle": str(bundle_dir.resolve()),
        "source_capture_id": manifest.get("capture_id"),
        "source_manifest_sha256": sha256_file(mpath),
        "created_at": now_utc(),
    }
    (wdir / "workspace.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")

    threads_p = wdir / "threads.json"
    if not threads_p.exists():
        threads_p.write_text(
            json.dumps(
                {
                    "format": "gloss-threads",
                    "schema_version": "1.1.0",
                    "capture_id": manifest.get("capture_id"),
                    "threads": [],
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
    return {"workspace_dir": str(wdir), **meta}


def add_thread(
    work_dir: Path,
    author: str,
    summary: str,
    kind: str = "audit_issue",
    panel_id: str | None = None,
    leaf_id: str | None = None,
    table_id: str | None = None,
    row_ids: list[int] | None = None,
    claim_id: str | None = None,
) -> dict:
    threads_p = work_dir / "threads.json"
    if threads_p.exists():
        doc = json.loads(threads_p.read_text(encoding="utf-8"))
    else:
        wmeta = (
            json.loads((work_dir / "workspace.json").read_text(encoding="utf-8"))
            if (work_dir / "workspace.json").exists()
            else {}
        )
        doc = {
            "format": "gloss-threads",
            "schema_version": "1.1.0",
            "capture_id": wmeta.get("source_capture_id"),
            "threads": [],
        }

    existing = doc.get("threads", [])
    tid = f"T{len(existing) + 1:03d}"
    entry = {
        "thread_id": tid,
        "kind": kind,
        "status": "open",
        "author": author,
        "created_at": now_utc(),
        "anchor": {
            "panel_id": panel_id,
            "leaf_id": leaf_id,
            "table_id": table_id,
            "row_ids": row_ids or [],
            "claim_id": claim_id,
        },
        "summary": summary,
        "history": [],
    }
    existing.append(entry)
    doc["threads"] = existing
    work_dir.mkdir(parents=True, exist_ok=True)
    threads_p.write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")
    return entry


def resolve_thread(work_dir: Path, thread_id: str, status: str, resolution: str, author: str = "human") -> dict:
    threads_p = work_dir / "threads.json"
    doc = json.loads(threads_p.read_text(encoding="utf-8"))
    for th in doc.get("threads", []):
        if th.get("thread_id") == thread_id:
            th["status"] = status
            th["resolved_at"] = now_utc()
            th["resolution"] = resolution
            th.setdefault("history", []).append(
                {"at": now_utc(), "author": author, "status": status, "note": resolution}
            )
            threads_p.write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")
            return th
    raise KeyError(f"Unknown thread_id: {thread_id}")


def summarize_workspace(work_dir: Path) -> dict:
    meta = (
        json.loads((work_dir / "workspace.json").read_text(encoding="utf-8"))
        if (work_dir / "workspace.json").exists()
        else {}
    )
    threads_doc = (
        json.loads((work_dir / "threads.json").read_text(encoding="utf-8"))
        if (work_dir / "threads.json").exists()
        else {"threads": []}
    )
    threads = threads_doc.get("threads", [])
    by_status: dict[str, int] = {}
    for th in threads:
        st = th.get("status", "open")
        by_status[st] = by_status.get(st, 0) + 1

    patches = sorted(p.name for p in (work_dir / "patches").glob("*.json")) if (work_dir / "patches").exists() else []
    derived = sorted(p.name for p in (work_dir / "derived").iterdir()) if (work_dir / "derived").exists() else []
    return {
        "workspace_dir": str(work_dir),
        "source_capture_id": meta.get("source_capture_id"),
        "has_focus": (work_dir / "focus.json").exists(),
        "n_threads": len(threads),
        "threads_by_status": by_status,
        "patches": patches,
        "derived": derived,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Manage a companion .gloss.work/ shared workspace.")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_init = sub.add_parser("init")
    p_init.add_argument("--bundle", required=True, type=Path)
    p_init.add_argument("--work-dir", type=Path, default=None)

    p_add = sub.add_parser("add-thread")
    p_add.add_argument("--work-dir", required=True, type=Path)
    p_add.add_argument("--author", choices=["human", "agent"], default="agent")
    p_add.add_argument("--kind", default="audit_issue")
    p_add.add_argument("--panel", default=None)
    p_add.add_argument("--leaf", default=None)
    p_add.add_argument("--table", default=None)
    p_add.add_argument("--rows", default="")
    p_add.add_argument("--claim-id", default=None)
    p_add.add_argument("--summary", required=True)

    p_res = sub.add_parser("resolve-thread")
    p_res.add_argument("--work-dir", required=True, type=Path)
    p_res.add_argument("--thread-id", required=True)
    p_res.add_argument("--status", choices=["accepted", "dismissed", "recompute_requested", "resolved"], required=True)
    p_res.add_argument("--resolution", required=True)
    p_res.add_argument("--author", choices=["human", "agent"], default="human")

    p_sum = sub.add_parser("summary")
    p_sum.add_argument("--work-dir", required=True, type=Path)

    args = parser.parse_args(argv)
    if args.cmd == "init":
        print(json.dumps(init_workspace(args.bundle, args.work_dir), indent=2))
    elif args.cmd == "add-thread":
        rids = [int(x.strip()) for x in args.rows.split(",") if x.strip()] if args.rows else []
        print(
            json.dumps(
                add_thread(
                    args.work_dir,
                    author=args.author,
                    summary=args.summary,
                    kind=args.kind,
                    panel_id=args.panel,
                    leaf_id=args.leaf,
                    table_id=args.table,
                    row_ids=rids,
                    claim_id=args.claim_id,
                ),
                indent=2,
            )
        )
    elif args.cmd == "resolve-thread":
        print(
            json.dumps(
                resolve_thread(args.work_dir, args.thread_id, args.status, args.resolution, author=args.author),
                indent=2,
            )
        )
    elif args.cmd == "summary":
        print(json.dumps(summarize_workspace(args.work_dir), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
