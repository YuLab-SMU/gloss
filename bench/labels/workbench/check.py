#!/usr/bin/env python3
"""Self-check of the label workbench's server, on the guideline's worked
examples (hand-built figures; no bench figure and no annotator's labels are
read):

    python3 bench/labels/workbench/check.py

The examples' labels, sent through the API as the page sends them, must come
back as the same label rows, splits included; an unfinished or invalid state
writes no label file; labels the workbench did not write are not replaced.
"""
import csv
import glob
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
EX = os.path.join(REPO, "bench", "labels", "examples")
PORT = 8799
ok = True


def expect(what, cond):
    global ok
    print("%-72s %s" % (what, "OK" if cond else "FAILED"))
    ok = ok and cond


def rows(path):
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def indices(spec, n):
    if spec == "all":
        return list(range(1, n + 1))
    out = []
    for part in spec.split(","):
        a = part.split("-")
        out += list(range(int(a[0]), int(a[-1]) + 1))
    return out


def state_of(label_rows):
    by_k = {}
    for r in label_rows:
        by_k.setdefault(r["k"], []).append(r)
    labels = {}
    for k, rs in by_k.items():
        n = int(rs[0]["n_elements"])
        lab = lambda r: {"role": r["role"], "kind": r["kind"], "note": r["note"], "unsure": False}
        if len(rs) == 1 and rs[0]["elements"] == "all":
            labels[k] = lab(rs[0])
        else:
            split = [None] * n
            for r in rs:
                for i in indices(r["elements"], n):
                    split[i - 1] = lab(r)
            labels[k] = {"split": split}
    return labels


def post(fig, state):
    req = urllib.request.Request("http://127.0.0.1:%d/api/state/%s" % (PORT, fig), data=json.dumps(state).encode(),
                                 headers={"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req))


def serve(out):
    p = subprocess.Popen([sys.executable, os.path.join(HERE, "serve.py"), "--sheets", EX, "--out", out,
                          "--port", str(PORT), "--no-open"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    line = p.stdout.readline()
    return p, line


out = tempfile.mkdtemp(prefix="wb-check-")
proc, line = serve(out)
try:
    expect("the server starts on the examples", "label workbench" in line)
    cfg = json.load(urllib.request.urlopen("http://127.0.0.1:%d/api/config" % PORT))
    expect("three figures, smallest first", [f["id"] for f in cfg["figures"]] == ["ex-base", "ex-heatmap", "ex-ggplot"])
    for f in sorted(glob.glob(os.path.join(EX, "labels", "*.csv"))):
        fig = os.path.basename(f)[:-4]
        want = rows(f)
        labels = state_of(want)
        part = dict(list(labels.items())[:2])
        p = post(fig, {"labels": part, "seconds": 3})
        expect("%s: an unfinished figure writes no label file" % fig,
               not p["done"] and not os.path.exists(os.path.join(out, fig + ".csv")))
        p = post(fig, {"labels": labels, "seconds": 90})
        got = rows(os.path.join(out, fig + ".csv")) if p["done"] else None
        expect("%s: %d label rows come back the same, splits included" % (fig, len(want)), got == want)
    bad = state_of(rows(os.path.join(EX, "labels", "ex-base.csv")))
    bad["1"] = {"role": "data", "kind": "tick"}
    p = post("ex-base", {"labels": bad, "seconds": 91})
    expect("a kind of another role is not a label: the file is taken back", not p["done"] and not os.path.exists(os.path.join(out, "ex-base.csv")))
    t = rows(os.path.join(out, "time.csv"))
    expect("time.csv lists the finished figures with their minutes", sorted((r["figure"], r["minutes"]) for r in t) == [("ex-ggplot", "1.5"), ("ex-heatmap", "1.5")])
    fig = json.load(urllib.request.urlopen("http://127.0.0.1:%d/api/figure/ex-base" % PORT))
    expect("a figure comes with its page, leaves, elements and saved state",
           "<svg" in fig["svg"] and len(fig["leaves"]) == 15 and len(fig["elements"]) == 90 and "1" in fig["state"]["labels"])
finally:
    proc.terminate()
    proc.wait()
# labels from elsewhere are never written over; an untouched sheet copy is
other = tempfile.mkdtemp(prefix="wb-check-")
shutil.copy(os.path.join(EX, "labels", "ex-base.csv"), other)
shutil.copy(os.path.join(EX, "ex-heatmap.csv"), other)
proc, line = serve(other)
proc.wait(timeout=10)
expect("labels the workbench did not write stop the server", proc.returncode != 0 and "did not write" in line)
expect("and are left as they were", rows(os.path.join(other, "ex-base.csv")) == rows(os.path.join(EX, "labels", "ex-base.csv")))
os.remove(os.path.join(other, "ex-base.csv"))
proc, line = serve(other)
time.sleep(0.2)
proc.terminate()
proc.wait()
expect("an untouched copy of the empty sheet is replaced", "label workbench" in line and not os.path.exists(os.path.join(other, "ex-heatmap.csv")))
shutil.rmtree(out)
shutil.rmtree(other)
sys.exit(0 if ok else 1)
