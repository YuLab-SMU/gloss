#!/usr/bin/env python3
"""Self-check of the label workbench's server, on the guideline's worked
examples (hand-built figures; no bench figure and no annotator's labels are
read):

    python3 bench/labels/workbench/check.py

One annotator: the examples' labels, sent through the API as the page sends
them, must come back as the same label rows, splits included; an unfinished
or invalid state writes no label file; labels the workbench did not write are
not replaced.

Several annotators (--team): joining needs the invite code and a nickname no
one has; no one reads another's labels before their own are frozen; the
frozen labels stay the ones on file whatever is changed afterwards; the
agreement the page shows is the one computed here by hand and, where Rscript
is installed, the one bench/R/score-labels.R reports.
"""
import csv
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
EX = os.path.join(REPO, "bench", "labels", "examples")
PORT = 8799
ok = True
skipped = 0


def expect(what, cond):
    global ok
    print("%-86s %s" % (what, "OK" if cond else "FAILED"))
    ok = ok and bool(cond)


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


def call(path, body=None, token=None):
    """(HTTP status, parsed JSON) of a request to the server under test."""
    req = urllib.request.Request("http://127.0.0.1:%d%s" % (PORT, path),
                                 data=None if body is None else json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    if token:
        req.add_header("X-Workbench-Token", token)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        return e.code, json.load(e)


def post(fig, state, token=None):
    """Save as a page that has just loaded the figure does: with the revision the server holds."""
    if "rev" not in state:
        state = dict(state, rev=call("/api/figure/" + fig, token=token)[1]["state"].get("rev", 0))
    return call("/api/state/" + fig, state, token)[1]


def serve(*args):
    p = subprocess.Popen([sys.executable, os.path.join(HERE, "serve.py"), "--sheets", EX, "--port", str(PORT), "--no-open"] + list(args),
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    line = p.stdout.readline()
    return p, line


def stop(p):
    p.terminate()
    p.wait()
    p.stdout.close()


def kappa_by_hand(a_rows, b_rows):
    """Leaf-weighted Cohen's kappa on roles of two annotators' label rows of the same figures."""
    def elements(rs):
        out = {}
        for r in rs:
            n = int(r["n_elements"])
            for i in indices(r["elements"], n):
                out[(r["figure"], r["k"], i)] = (r["role"], 1 / n)
        return out
    a, b = elements(a_rows), elements(b_rows)
    assert set(a) == set(b)
    total = sum(w for _, w in a.values())
    po = sum(w for e, (r, w) in a.items() if b[e][0] == r) / total
    roles = {r for r, _ in a.values()} | {r for r, _ in b.values()}
    pe = sum((sum(w for r, w in a.values() if r == c) / total) * (sum(w for r, w in b.values() if r == c) / total) for c in roles)
    return (po - pe) / (1 - pe), po


# ---- one annotator -----------------------------------------------------------
out = tempfile.mkdtemp(prefix="wb-check-")
proc, line = serve("--out", out)
try:
    expect("the server starts on the examples", "label workbench" in line)
    expect("one annotator: no accounts, and the page is told so", call("/api/hello")[1]["team"] is False)
    cfg = call("/api/config")[1]
    expect("four figures, smallest first", [f["id"] for f in cfg["figures"]] == ["ex-base", "ex-box", "ex-heatmap", "ex-ggplot"])
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
    expect("time.csv lists the finished figures with their minutes", sorted((r["figure"], r["minutes"]) for r in t) == [("ex-box", "1.5"), ("ex-ggplot", "1.5"), ("ex-heatmap", "1.5")])
    fig = call("/api/figure/ex-base")[1]
    expect("a figure comes with its page, leaves, elements and saved state",
           "<svg" in fig["svg"] and len(fig["leaves"]) == 15 and len(fig["elements"]) == 90 and "1" in fig["state"]["labels"])
    ref = call("/api/reference")[1]
    expect("a figure being labelled is never its own reference, or an example of a kind", ref["figures"] == [] and ref["kinds"] == {} and ref["figure"] is None)
    # a page that loaded the figure before another page saved it holds old labels: its save is refused
    held = call("/api/figure/ex-box")[1]["state"]
    full = held["labels"]
    newer = dict(full, **{"1": {"role": "decoration", "kind": "other", "note": "changed in another page", "unsure": False}})
    s1, p1 = call("/api/state/ex-box", {"labels": newer, "seconds": 90, "rev": held.get("rev", 0)})
    s2, p2 = call("/api/state/ex-box", {"labels": dict(list(full.items())[:1]), "seconds": 90, "rev": held.get("rev", 0)})
    after = call("/api/figure/ex-box")[1]["state"]
    expect("a save from a page that holds an older revision is refused (409) and changes nothing",
           s1 == 200 and s2 == 409 and after["labels"] == newer and after.get("rev") == p1.get("rev") == held.get("rev", 0) + 1
           and len(rows(os.path.join(out, "ex-box.csv"))) == 22)
    expect("a save that names no revision is refused too",
           call("/api/state/ex-box", {"labels": full, "seconds": 90})[0] == 409 and call("/api/figure/ex-box")[1]["state"]["labels"] == newer)
    expect("one annotator: nothing of others to open or to see",
           fig["peers"] is None and call("/api/open/ex-base", {})[0] == 403 and call("/api/overview")[0] == 404
           and call("/api/join", {"nickname": "someone"})[0] == 404)
finally:
    stop(proc)
# labels from elsewhere are never written over; an untouched sheet copy is
other = tempfile.mkdtemp(prefix="wb-check-")
shutil.copy(os.path.join(EX, "labels", "ex-base.csv"), other)
shutil.copy(os.path.join(EX, "ex-heatmap.csv"), other)
proc, line = serve("--out", other)
proc.wait(timeout=10)
proc.stdout.close()
expect("labels the workbench did not write stop the server", proc.returncode != 0 and "did not write" in line)
expect("and are left as they were", rows(os.path.join(other, "ex-base.csv")) == rows(os.path.join(EX, "labels", "ex-base.csv")))
os.remove(os.path.join(other, "ex-base.csv"))
proc, line = serve("--out", other)
time.sleep(0.2)
stop(proc)
expect("an untouched copy of the empty sheet is replaced", "label workbench" in line and not os.path.exists(os.path.join(other, "ex-heatmap.csv")))
# the guideline's examples beside another figure: every leaf with its decided labels, every kind's examples
one = tempfile.mkdtemp(prefix="wb-check-")
for f in glob.glob(os.path.join(EX, "ex-base*")):
    shutil.copy(f, os.path.join(one, os.path.basename(f).replace("ex-base", "zz-base")))      # the same sheet as another figure
serve_one = lambda *args: subprocess.Popen([sys.executable, os.path.join(HERE, "serve.py"), "--sheets", one, "--examples", EX,
                                            "--out", os.path.join(one, "out"), "--port", str(PORT), "--no-open"] + list(args),
                                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
proc = serve_one()
proc.stdout.readline()
try:
    ref = call("/api/reference")[1]
    leaf = {(f["id"], l["k"]): l for f in ref["figures"] for l in f["leaves"]}
    expect("the reference: the examples, each leaf with its decided labels and its page",
           [(f["id"], len(f["leaves"])) for f in ref["figures"]] == [("ex-base", 15), ("ex-box", 22), ("ex-heatmap", 24), ("ex-ggplot", 68)]
           and all("<svg" in f["svg"] for f in ref["figures"]) and ref["figure"] == "ex-ggplot"
           and leaf[("ex-base", "5")]["labels"] == [{"elements": "1", "role": "annotation", "kind": "title"}, {"elements": "2-3", "role": "guide", "kind": "axis title"}])
    with open(os.path.join(REPO, "bench", "labels", "vocabulary.json"), encoding="utf-8") as f:
        voc = json.load(f)
    named = {r["role"] + " / " + k["kind"]: k.get("examples", []) for r in voc["roles"] for k in r["kinds"]}
    labelled = lambda name, e: any(l["role"] + " / " + l["kind"] == name for l in leaf[(e["figure"], e["k"])]["labels"])
    expect("the standard examples: 25 of the 28 kinds have some (all but the three `other`), each a leaf the examples label with that kind",
           len(named) == 28 and sum(bool(v) for v in named.values()) == 25 and sorted(k.split(" / ")[1] for k, v in named.items() if not v) == ["other"] * 3
           and {k: [(e["figure"], e["k"]) for e in v] for k, v in named.items() if v} == {k: [(e["figure"], e["k"]) for e in v] for k, v in ref["kinds"].items()}
           and all(labelled(k, e) for k, v in ref["kinds"].items() for e in v))
    part = ref["kinds"]["guide / axis line"][0]
    whole = ref["kinds"]["data / bar"][0]
    expect("a standard example that is part of a leaf comes with its elements and their box",
           part["index"] == [1] and part["box"] != leaf[("ex-base", "2")]["box"] and whole["index"] is None and whole["box"] == leaf[("ex-base", "12")]["box"])
    p = post("zz-base", {"labels": {"1": {"role": "data", "kind": "point", "note": "", "unsure": False, "ref": True}}, "seconds": 5})
    with open(os.path.join(one, "out", ".workbench", "zz-base.json"), encoding="utf-8") as f:
        st = json.load(f)
    expect("a figure's state says which workbench made it, and where the reference was open",
           st["workbench"] == 5 and st["labels"]["1"]["ref"] is True)
finally:
    stop(proc)
# an example the vocabulary names that the examples do not label so stops the server
wrong = json.loads(json.dumps(voc))
wrong["roles"][0]["kinds"][0]["examples"] = [{"figure": "ex-ggplot", "k": "2"}]          # data / point: a panel background
with open(os.path.join(one, "vocabulary.json"), "w", encoding="utf-8") as f:
    json.dump(wrong, f)
proc = serve_one("--vocabulary", os.path.join(one, "vocabulary.json"))
proc.wait(timeout=10)
said = proc.stdout.read()
proc.stdout.close()
expect("an example the vocabulary names that is not labelled so stops the server, with the reason",
       proc.returncode != 0 and "data / point: ex-ggplot k 2 is not labelled so" in said)
shutil.rmtree(one)
proc, line = serve("--out", other, "--host", "0.0.0.0")
proc.wait(timeout=10)
proc.stdout.close()
expect("without accounts the server does not listen beyond this machine", proc.returncode != 0 and "--team" in line)
shutil.rmtree(out)
shutil.rmtree(other)

# ---- several annotators ------------------------------------------------------
root = tempfile.mkdtemp(prefix="wb-team-")
os.mkdir(os.path.join(root, "key"))                  # labels made elsewhere: a read-only annotator
want = {}
for f in sorted(glob.glob(os.path.join(EX, "labels", "*.csv"))):
    shutil.copy(f, os.path.join(root, "key"))
    want[os.path.basename(f)[:-4]] = rows(f)
figs = ["ex-base", "ex-box", "ex-heatmap", "ex-ggplot"]
# leaves with elements, counted on the sheets: 15, 22, 24 and 68
n = {f: sum(int(r["n_elements"]) > 0 for r in rows(os.path.join(EX, f + ".csv"))) for f in figs}
expect("the examples have 15, 22, 24 and 68 leaves to label", [n[f] for f in figs] == [15, 22, 24, 68])
# the second annotator differs from the examples on one whole leaf of ex-base
differ = next(r for r in want["ex-base"] if r["elements"] == "all" and r["role"] == "guide")
other_rows = {f: [dict(r) for r in want[f]] for f in figs}
for r in other_rows["ex-base"]:
    if r["k"] == differ["k"]:
        r.update(role="decoration", kind="other")
proc, line = serve("--team", root, "--invite", "pass")
try:
    hello = call("/api/hello")[1]
    expect("team: the server says so, and that joining needs a code", "team" in line and hello["team"] and hello["invite"] and hello["reveal"] == "set")
    expect("team: nothing is served without an account",
           [call(p)[0] for p in ("/api/config", "/api/figure/ex-base", "/api/peers/ex-base", "/api/overview", "/api/reference")] == [401] * 5
           and call("/api/state/ex-base", {"labels": {}})[0] == 401 and call("/api/config", token="0" * 32)[0] == 401)
    expect("team: joining needs the invite code", call("/api/join", {"nickname": "小明", "invite": "wrong"})[0] == 403
           and call("/api/join", {"nickname": "小明"})[0] == 403)
    expect("team: a nickname is 2-16 letters, digits, _ or -; no path, no space",
           [call("/api/join", {"nickname": n, "invite": "pass"})[0] for n in ("a", "../x", "a b", ".team", "x" * 17, "a/b", "-ab", 5)] == [400] * 8)
    s1, j1 = call("/api/join", {"nickname": "小明", "invite": "pass"})
    s2, j2 = call("/api/join", {"nickname": "lab-cat", "invite": "pass"})
    expect("team: two annotators join, each with a token", s1 == 200 and s2 == 200 and j1["token"] != j2["token"] and j1["nickname"] == "小明")
    a, b = j1["token"], j2["token"]
    expect("team: a nickname in use is refused, whatever its case, a read-only annotator's too",
           [call("/api/join", {"nickname": n, "invite": "pass"})[0] for n in ("小明", "Lab-Cat", "KEY")] == [400] * 3)
    accounts = open(os.path.join(root, ".team", "accounts.json"), encoding="utf-8").read()
    expect("team: tokens are not stored, only their digests", a not in accounts and b not in accounts)
    # 小明 labels one figure as the examples do; lab-cat all four, one leaf differently
    p = post("ex-base", {"labels": state_of(want["ex-base"]), "seconds": 60}, a)
    expect("team: each annotator's labels go to a directory of their own",
           p["done"] and rows(os.path.join(root, "小明", "ex-base.csv")) == want["ex-base"] and not os.path.exists(os.path.join(root, "lab-cat", "ex-base.csv")))
    for f in figs:
        post(f, {"labels": state_of(other_rows[f]), "seconds": 60}, b)
    cfg_b = call("/api/config", token=b)[1]
    expect("team: the second annotator has finished the set", all(f["done"] and f["eligible"] and not f["locked"] for f in cfg_b["figures"]))
    # before anything is frozen, no one sees a label of anyone else
    fa, fb = call("/api/figure/ex-base", token=a)[1], call("/api/figure/ex-base", token=b)[1]
    oa = call("/api/overview", token=a)[1]
    expect("team: a figure's request gives only one's own labels, and no one else's before freezing",
           fa["peers"] is None and fb["peers"] is None and call("/api/peers/ex-base", token=a)[1]["peers"] is None
           and fa["state"]["labels"] == state_of(want["ex-base"]) and fb["state"]["labels"] == state_of(other_rows["ex-base"]))
    expect("team: progress is open to all: who labelled how much, and nothing about what",
           [(p["who"], p["figures_done"], p["labelled"]) for p in oa["people"]] == [("小明", 1, 15), ("lab-cat", 4, 15 + 22 + 24 + 68), ("key", 4, 15 + 22 + 24 + 68)]
           and oa["figures"] == [] and oa["pairs"] == [] and oa["disputed"] == []
           and not any(w in json.dumps(oa) for w in ("decoration", "guide", "axis")))
    expect("team: the others' labels do not open before one's whole set is labelled",
           call("/api/open/ex-base", {}, a)[0] == 403 and call("/api/peers/ex-base", token=a)[1]["peers"] is None)
    # lab-cat opens: their labels freeze, and they see everyone who finished the figure
    s, opened = call("/api/open/ex-base", {}, b)
    pe = opened["peers"]
    expect("team: opening freezes one's labels of the whole set", s == 200 and "independent" in opened["state"]
           and all(f["locked"] for f in call("/api/config", token=b)[1]["figures"]))
    expect("team: one then sees everyone who labelled the figure completely",
           pe["annotators"] == ["小明", "lab-cat", "key"]
           and call("/api/peers/ex-heatmap", token=b)[1]["peers"]["annotators"] == ["lab-cat", "key"])
    leaf = next(l for l in pe["leaves"] if l["k"] == differ["k"])
    rest = [l for l in pe["leaves"] if l["k"] != differ["k"]]
    expect("team: per leaf, who gave which label and how the roles split",
           leaf["n"] == 3 and leaf["share"] == 0.667 and leaf["roles"] == {"guide": 2.0, "decoration": 1.0}
           and [(x["who"], x["me"], x["parts"][0]["role"]) for x in leaf["answers"]] == [("小明", False, "guide"), ("lab-cat", True, "decoration"), ("key", False, "guide")]
           and all(l["share"] == 1 for l in rest) and len(rest) == 14)
    split = next(l for l in pe["leaves"] if l["k"] == "5")      # title(): main is annotation, the axis labels are guide
    expect("team: a leaf everyone splits the same way is agreed on, not disputed",
           split["share"] == 1 and split["share_kind"] == 1 and split["roles"] == {"annotation": 1.0, "guide": 2.0})
    ob = call("/api/overview", token=b)[1]
    pairs = {(p["a"], p["b"]): p for p in ob["pairs"]}
    k, agree = kappa_by_hand([r for f in figs for r in want[f]], [r for f in figs for r in other_rows[f]])
    k1, agree1 = kappa_by_hand(want["ex-base"], other_rows["ex-base"])
    expect("team: pairwise kappa on roles, leaf-weighted, is the one computed by hand (%.3f over 4 figures)" % k,
           set(pairs) == {("key", "lab-cat"), ("key", "小明"), ("lab-cat", "小明")}
           and pairs[("key", "lab-cat")]["kappa"] == round(k, 3) and pairs[("key", "lab-cat")]["agreement"] == round(agree, 3)
           and pairs[("key", "lab-cat")]["figures"] == 4 and 0.9 < k < 1
           and pairs[("key", "小明")]["kappa"] == 1 and pairs[("key", "小明")]["figures"] == 1
           and pairs[("lab-cat", "小明")]["kappa"] == round(k1, 3) and pairs[("lab-cat", "小明")]["figures"] == 1)
    expect("team: per figure, the leaves all agree on; the disputed leaves, the least agreed first",
           [(f["id"], f["annotators"], f["unanimous"], f["leaves"]) for f in ob["figures"]] == [("ex-base", 3, 14, 15), ("ex-box", 2, 22, 22), ("ex-heatmap", 2, 24, 24), ("ex-ggplot", 2, 68, 68)]
           and [(d["fig"], d["k"], d["share"]) for d in ob["disputed"]] == [("ex-base", differ["k"], 0.667)])
    rscript = shutil.which("Rscript")
    if rscript and subprocess.run([rscript, "-e", "library(jsonlite)"], capture_output=True).returncode == 0:
        r = subprocess.run([rscript, "bench/R/score-labels.R", "agree", os.path.join(root, "key"), os.path.join(root, "lab-cat"), EX],
                           cwd=REPO, capture_output=True, text=True)
        m = re.search(r"roles, leaf-weighted \(criterion, >= 0\.8\): kappa ([\d.]+), agreement ([\d.]+)", r.stdout)
        expect("team: and the one bench/R/score-labels.R reports on the two directories (%s)" % (m.group(1) if m else "no output"),
               m is not None and float(m.group(1)) == pairs[("key", "lab-cat")]["kappa"] and float(m.group(2)) == pairs[("key", "lab-cat")]["agreement"])
    else:
        skipped += 1
        print("%-86s SKIPPED (no Rscript with jsonlite here)" % "team: and the one bench/R/score-labels.R reports on the two directories")
    # what is changed after freezing is kept apart
    before = rows(os.path.join(root, "lab-cat", "ex-base.csv"))
    p = post("ex-base", {"labels": state_of(want["ex-base"]), "seconds": 600}, b)
    t = {r["figure"]: r["minutes"] for r in rows(os.path.join(root, "lab-cat", "time.csv"))}
    expect("team: a change after freezing leaves the labels on file and goes to revised/",
           rows(os.path.join(root, "lab-cat", "ex-base.csv")) == before == other_rows["ex-base"]
           and rows(os.path.join(root, "lab-cat", "revised", "ex-base.csv")) == want["ex-base"]
           and not os.path.exists(os.path.join(root, "lab-cat", "revised", "ex-heatmap.csv")))
    expect("team: and neither the agreement nor the time to label moves",
           call("/api/overview", token=b)[1]["pairs"] == ob["pairs"] and t["ex-base"] == "1.0" and p["seconds"] == 60)
    post("ex-base", {"labels": state_of(other_rows["ex-base"]), "seconds": 600}, b)
    expect("team: changed back, nothing is left in revised/", not os.path.exists(os.path.join(root, "lab-cat", "revised", "ex-base.csv")))
    part = dict(list(state_of(other_rows["ex-base"]).items())[:3])
    post("ex-base", {"labels": part, "seconds": 600}, b)
    expect("team: labels taken back after freezing do not take the file back",
           rows(os.path.join(root, "lab-cat", "ex-base.csv")) == other_rows["ex-base"]
           and call("/api/peers/ex-base", token=b)[1]["peers"]["annotators"] == ["小明", "lab-cat", "key"])
    expect("team: the first annotator, unfrozen, still sees no one's labels",
           call("/api/peers/ex-base", token=a)[1]["peers"] is None and call("/api/overview", token=a)[1]["pairs"] == [])
    expect("team: one cannot write for another, or without the token",
           call("/api/state/ex-base", {"labels": {"999": {}}}, a)[0] == 400 and call("/api/state/ex-base", {"labels": {}}, "f" * 32)[0] == 401
           and rows(os.path.join(root, "小明", "ex-base.csv")) == want["ex-base"])
finally:
    stop(proc)
proc, line = serve("--team", root, "--invite", "pass", "--reveal", "figure")
try:
    expect("team: accounts and frozen labels outlast a restart",
           call("/api/config", token=a)[0] == 200 and call("/api/config", token=b)[1]["figures"][0]["locked"])
    s, opened = call("/api/open/ex-base", {}, a)
    expect("team, --reveal figure: a finished figure opens, an unfinished one does not",
           s == 200 and opened["peers"]["annotators"] == ["小明", "lab-cat", "key"] and call("/api/open/ex-heatmap", {}, a)[0] == 403
           and [f["locked"] for f in call("/api/config", token=a)[1]["figures"]] == [True, False, False, False])
finally:
    stop(proc)
# labels made elsewhere that do not fit the sheets stop the server, with the reason
os.mkdir(os.path.join(root, "stale"))
bad = [dict(r) for r in want["ex-base"]]
bad[0]["n_elements"] = "99"
with open(os.path.join(root, "stale", "ex-base.csv"), "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(bad[0]), quoting=csv.QUOTE_ALL, lineterminator="\n")
    w.writeheader()
    w.writerows(bad)
proc = subprocess.run([sys.executable, os.path.join(HERE, "serve.py"), "--sheets", EX, "--port", str(PORT), "--team", root],
                      capture_output=True, text=True, timeout=20)
expect("team: labels made elsewhere that do not fit the sheets stop the server, with the reason",
       proc.returncode != 0 and "does not fit the sheet of ex-base" in proc.stderr and "the label says" in proc.stderr)
shutil.rmtree(root)
# a set that grows: figures added after someone froze their labels stay blind to them
# until they have labelled those too (the second batch, added to a running pilot)
grow = tempfile.mkdtemp(prefix="wb-check-")
gs, gt = os.path.join(grow, "sheets"), os.path.join(grow, "team")
os.makedirs(os.path.join(gt, "key"))
add = lambda name: [shutil.copy(f, os.path.join(gs, os.path.basename(f).replace("ex-base", name))) for f in glob.glob(os.path.join(EX, "ex-base*"))]
os.mkdir(gs)
add("aa-base")
shutil.copy(os.path.join(EX, "labels", "ex-base.csv"), os.path.join(gt, "key", "aa-base.csv"))
serve_grow = lambda: subprocess.Popen([sys.executable, os.path.join(HERE, "serve.py"), "--sheets", gs, "--examples", "", "--team", gt,
                                       "--invite", "pass", "--port", str(PORT), "--no-open"],
                                      stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
proc = serve_grow()
proc.stdout.readline()
try:
    g = call("/api/join", {"nickname": "early", "invite": "pass"})[1]["token"]
    post("aa-base", {"labels": state_of(want["ex-base"]), "seconds": 30}, g)
    s, opened = call("/api/open/aa-base", {}, g)
    first = s == 200 and opened["peers"]["annotators"] == ["early", "key"]
finally:
    stop(proc)
add("zz-base")
shutil.copy(os.path.join(EX, "labels", "ex-base.csv"), os.path.join(gt, "key", "zz-base.csv"))
proc = serve_grow()
proc.stdout.readline()
try:
    cfg_g = call("/api/config", token=g)[1]
    ov = call("/api/overview", token=g)[1]
    blind = (call("/api/figure/zz-base", token=g)[1]["peers"] is None and call("/api/peers/zz-base", token=g)[1]["peers"] is None
             and call("/api/open/zz-base", {}, g)[0] == 403 and [f["id"] for f in ov["figures"]] == ["aa-base"]
             and all(p["figures"] == 1 for p in ov["pairs"]))
    expect("a set that grows: the figure frozen before stays open, the added one is blind until it is labelled",
           first and [(f["id"], f["locked"], f["done"]) for f in cfg_g["figures"]] == [("aa-base", True, True), ("zz-base", False, False)]
           and call("/api/peers/aa-base", token=g)[1]["peers"]["annotators"] == ["early", "key"] and blind)
    post("zz-base", {"labels": state_of(want["ex-base"]), "seconds": 30}, g)
    s, opened = call("/api/open/zz-base", {}, g)
    expect("a set that grows: once the added figure is labelled it opens and freezes like the first",
           s == 200 and opened["peers"]["annotators"] == ["early", "key"] and "independent" in opened["state"]
           and [f["locked"] for f in call("/api/config", token=g)[1]["figures"]] == [True, True]
           and os.path.exists(os.path.join(gt, "early", "zz-base.csv")))
finally:
    stop(proc)
shutil.rmtree(grow)
if skipped:
    print("%d check(s) skipped" % skipped)
sys.exit(0 if ok else 1)
