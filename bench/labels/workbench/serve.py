#!/usr/bin/env python3
"""Label workbench: label the leaves of bench figures in the browser.

    python3 bench/labels/workbench/serve.py                     # the pilot, annotator "owner"
    python3 bench/labels/workbench/serve.py --out bench/labels/pilot/<annotator>
    python3 bench/labels/workbench/serve.py --sheets <sheets dir> --out <labels dir>

It serves one page on 127.0.0.1 and reads only the label sheets
(bench/R/label-sheet.R), the figures' code and the vocabulary; it never
reads another annotator's labels and shows no rule output. It runs no
figure code. Python's standard library only.

What it writes, all under --out:
  <id>.csv          the labels of a figure, in the format bench/R/score-labels.R
                    checks, written once every leaf with elements is labelled
                    (and removed again if a label is taken back);
  time.csv          active minutes per finished figure, from the page's timer
                    (time with the tab hidden, or more than 60 s after the
                    last key or click, is not counted);
  .workbench/<id>.json   the session's state, so that work can be resumed.
"""
import argparse
import csv
import datetime
import http.server
import json
import os
import re
import sys
import webbrowser

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
MAX_BODY = 20 * 1024 * 1024


def read_csv(path):
    with open(path, newline="", encoding="utf-8") as f:
        r = csv.DictReader(f)
        return r.fieldnames, list(r)


def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def ranges(idx):
    """[1, 2, 3, 7] -> "1-3,7" (the `elements` syntax of the guideline)."""
    idx = sorted(idx)
    out, start, prev = [], idx[0], idx[0]
    for i in idx[1:] + [None]:
        if i is not None and i == prev + 1:
            prev = i
            continue
        out.append(str(start) if start == prev else "%d-%d" % (start, prev))
        if i is not None:
            start = prev = i
    return ",".join(out)


class Bench:
    def __init__(self, sheets, out, figures, vocabulary):
        self.sheets, self.out, self.figures = sheets, out, figures
        with open(vocabulary, encoding="utf-8") as f:
            self.vocabulary = json.load(f)
        self.kinds = {r["role"]: [k["kind"] for k in r["kinds"]] for r in self.vocabulary["roles"]}
        self.state_dir = os.path.join(out, ".workbench")
        ids = [f[:-4] for f in sorted(os.listdir(sheets))
               if f.endswith(".csv") and not f.endswith("-elements.csv") and f != "index.csv"]
        # the smallest figure first: the easy ones teach the keys
        size = {i: sum(1 for r in read_csv(os.path.join(sheets, i + ".csv"))[1] if int(r["n_elements"]) > 0) for i in ids}
        self.ids = sorted(ids, key=lambda i: size[i])
        missing = [i for i in ids if not os.path.exists(os.path.join(sheets, i + ".svg"))]
        if missing:
            sys.exit("no page for %s in %s: draw the sheets first (Rscript bench/R/label-sheet.R draw <run dir> %s)"
                     % (", ".join(missing[:5]), sheets, sheets))
        os.makedirs(self.state_dir, exist_ok=True)
        # Never write over labels this workbench did not make. An untouched
        # copy of the empty sheet holds no labels and is replaced.
        for i in ids:
            mine = os.path.join(out, i + ".csv")
            if os.path.exists(mine) and not os.path.exists(self.state_file(i)):
                with open(mine, "rb") as a, open(os.path.join(sheets, i + ".csv"), "rb") as b:
                    if a.read() == b.read():
                        os.remove(mine)
                        continue
                sys.exit("%s holds labels the workbench did not write; choose another --out, or move the file away" % mine)

    def state_file(self, fig):
        return os.path.join(self.state_dir, fig + ".json")

    def sheet(self, fig):
        return read_csv(os.path.join(self.sheets, fig + ".csv"))

    def state(self, fig):
        try:
            with open(self.state_file(fig), encoding="utf-8") as f:
                return json.load(f)
        except FileNotFoundError:
            return {"labels": {}, "seconds": 0}

    def progress(self, fig, state=None):
        state = state or self.state(fig)
        rows = [r for r in self.sheet(fig)[1] if int(r["n_elements"]) > 0]
        done = sum(1 for r in rows if self.leaf_rows(r, state["labels"].get(r["k"])) is not None)
        return {"id": fig, "leaves": len(rows), "labelled": done, "done": done == len(rows),
                "seconds": state.get("seconds", 0)}

    def valid(self, lab):
        return (isinstance(lab, dict) and lab.get("role") in self.kinds
                and lab.get("kind") in self.kinds[lab["role"]])

    @staticmethod
    def note(lab):
        text = re.sub(r"[\r\n\t]+", " ", str(lab.get("note") or "")).strip()
        if lab.get("unsure"):
            return ("unsure: " + text) if text else "unsure"
        return text

    def leaf_rows(self, row, lab):
        """The label rows of one leaf, or None while it is not fully labelled."""
        if lab is None:
            return None
        n = int(row["n_elements"])
        if "split" not in lab:
            if not self.valid(lab):
                return None
            return [dict(row, elements="all", role=lab["role"], kind=lab["kind"], note=self.note(lab))]
        parts = lab["split"]
        if len(parts) != n or not all(self.valid(p) for p in parts):
            return None
        groups = {}
        for i, p in enumerate(parts, start=1):
            groups.setdefault((p["role"], p["kind"], self.note(p)), []).append(i)
        if len(groups) == 1:
            (role, kind, note), _ = next(iter(groups.items()))
            return [dict(row, elements="all", role=role, kind=kind, note=note)]
        return [dict(row, elements=ranges(idx), role=role, kind=kind, note=note)
                for (role, kind, note), idx in sorted(groups.items(), key=lambda g: g[1][0])]

    def save(self, fig, state):
        labels = state.get("labels")
        if not isinstance(labels, dict):
            raise ValueError("no labels")
        header, rows = self.sheet(fig)
        known = {r["k"] for r in rows if int(r["n_elements"]) > 0}
        if set(labels) - known:
            raise ValueError("labels for leaves the sheet does not have: %s" % sorted(set(labels) - known)[:5])
        state = {"figure": fig, "guideline": self.vocabulary["guideline"], "labels": labels,
                 "seconds": int(state.get("seconds") or 0), "cursor": state.get("cursor"),
                 "saved": datetime.datetime.now().isoformat(timespec="seconds")}
        tmp = self.state_file(fig) + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(state, f, ensure_ascii=False, indent=1)
        os.replace(tmp, self.state_file(fig))
        out_rows = []
        complete = True
        for r in rows:
            if int(r["n_elements"]) == 0:
                continue
            lr = self.leaf_rows(r, labels.get(r["k"]))
            if lr is None:
                complete = False
                break
            out_rows.extend(lr)
        target = os.path.join(self.out, fig + ".csv")
        if complete:
            with open(target + ".tmp", "w", newline="", encoding="utf-8") as f:
                w = csv.DictWriter(f, fieldnames=header, quoting=csv.QUOTE_ALL, lineterminator="\n")
                w.writeheader()
                w.writerows(out_rows)
            os.replace(target + ".tmp", target)
        elif os.path.exists(target):
            os.remove(target)
        self.write_time()
        return dict(self.progress(fig, state), file=shown(target) if complete else None)

    def write_time(self):
        with open(os.path.join(self.out, "time.csv"), "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f, quoting=csv.QUOTE_ALL, lineterminator="\n")
            w.writerow(["figure", "minutes", "guideline", "note"])
            for fig in self.ids:
                p = self.progress(fig)
                if p["done"]:
                    w.writerow([fig, "%.1f" % (p["seconds"] / 60), self.vocabulary["guideline"],
                                "label workbench timer: %d s active (tab hidden or idle over 60 s not counted)" % p["seconds"]])

    def figure(self, fig):
        _, rows = self.sheet(fig)
        _, els = read_csv(os.path.join(self.sheets, fig + "-elements.csv"))
        with open(os.path.join(self.sheets, fig + ".svg"), encoding="utf-8") as f:
            svg = f.read()
        code_file = os.path.join(self.figures, fig, "code.R")
        code = open(code_file, encoding="utf-8").read() if os.path.exists(code_file) else ""
        box = lambda r: [num(r["x0"]), num(r["y0"]), num(r["x1"]), num(r["y1"])]
        return {
            "id": fig, "svg": svg, "code": code, "state": self.state(fig),
            "leaves": [{"k": r["k"], "leaf": r["leaf"], "class": r["class"], "n": int(r["n_elements"]),
                        "tags": r["tags"], "text": r["text"], "fill": r["fill"], "stroke": r["stroke"],
                        "path": r["path"], "box": box(r)} for r in rows],
            "elements": [{"k": e["k"], "index": int(e["index"]), "tag": e["tag"], "text": e["text"],
                          "fill": e["fill"], "stroke": e["stroke"], "box": box(e)} for e in els],
        }

    def config(self):
        return {"annotator": os.path.basename(os.path.normpath(self.out)),
                "out": shown(self.out), "sheets": shown(self.sheets),
                "vocabulary": self.vocabulary, "figures": [self.progress(i) for i in self.ids]}


def handler(bench):
    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def send(self, code, body, ctype="application/json; charset=utf-8"):
            data = body if isinstance(body, bytes) else json.dumps(body, ensure_ascii=False).encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

        def figure_id(self, prefix):
            fig = self.path.split("?")[0][len(prefix):]
            return fig if fig in bench.ids else None

        def do_GET(self):
            path = self.path.split("?")[0]
            if path in ("/", "/index.html"):
                with open(os.path.join(HERE, "index.html"), "rb") as f:
                    return self.send(200, f.read(), "text/html; charset=utf-8")
            if path == "/api/config":
                return self.send(200, bench.config())
            if path.startswith("/api/figure/"):
                fig = self.figure_id("/api/figure/")
                return self.send(200, bench.figure(fig)) if fig else self.send(404, {"error": "no such figure"})
            self.send(404, {"error": "not found"})

        def do_POST(self):
            fig = self.figure_id("/api/state/") if self.path.startswith("/api/state/") else None
            if not fig:
                return self.send(404, {"error": "not found"})
            n = int(self.headers.get("Content-Length") or 0)
            if n <= 0 or n > MAX_BODY:
                return self.send(400, {"error": "bad request size"})
            try:
                self.send(200, bench.save(fig, json.loads(self.rfile.read(n).decode("utf-8"))))
            except (ValueError, KeyError, TypeError) as e:
                self.send(400, {"error": str(e)})
    return Handler


def shown(path):
    """A path as the page and the messages show it: relative inside the repository."""
    rel = os.path.relpath(path, REPO)
    return path if rel.startswith("..") else rel


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--sheets", default=os.path.join(REPO, "bench", "labels", "pilot", "sheets"))
    ap.add_argument("--out", default=os.path.join(REPO, "bench", "labels", "pilot", "owner"))
    ap.add_argument("--figures", default=os.path.join(REPO, "bench", "figures"))
    ap.add_argument("--vocabulary", default=os.path.join(REPO, "bench", "labels", "vocabulary.json"))
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--no-open", action="store_true", help="do not open the browser")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    bench = Bench(os.path.abspath(a.sheets), os.path.abspath(a.out), os.path.abspath(a.figures), a.vocabulary)
    server = None
    for port in range(a.port, a.port + 20):
        try:
            server = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler(bench))
            break
        except OSError:
            continue
    if server is None:
        sys.exit("no free port from %d" % a.port)
    url = "http://127.0.0.1:%d/" % server.server_address[1]
    print("label workbench: %s  (%d figures; labels go to %s; Ctrl-C stops it)"
          % (url, len(bench.ids), shown(bench.out)), flush=True)
    if not a.no_open:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped; state and finished labels are saved")


if __name__ == "__main__":
    main()
