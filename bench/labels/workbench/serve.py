#!/usr/bin/env python3
"""Label workbench: label the leaves of bench figures in the browser.

One annotator, on this machine:

    python3 bench/labels/workbench/serve.py                     # the pilot, annotator "owner"
    python3 bench/labels/workbench/serve.py --out bench/labels/pilot/<annotator>

Several annotators, on a shared machine:

    python3 serve.py --team <labels root> --sheets <sheets> --figures <figures> \\
        --vocabulary <vocabulary.json> --host 0.0.0.0 --invite <code>

Each annotator joins with the invite code, picks a nickname no one else has
and labels into <labels root>/<nickname>/. A directory under the root that
holds label files but belongs to no account is a read-only annotator (labels
made elsewhere).

Independence. An annotator sees no one else's labels until their own are
final: --reveal set (default) opens the others' labels once every figure is
labelled, --reveal figure once that figure is. Opening them is the
annotator's own act; it freezes their labels of those figures as their
*independent* labels: <id>.csv holds those from then on, and what they
change afterwards is kept apart, in revised/<id>.csv. What an annotator who
has opened a figure sees, and the statistics, cover everyone who has labelled
that figure completely, as their <id>.csv stands. Progress (who labelled how
much) is visible at any time.

The server reads only the label sheets (bench/R/label-sheet.R), the figures'
code, the vocabulary and the guideline's worked examples (--examples: hand-built
figures with their decided labels, shown beside each role and kind and as
reference for leaves of the same class; never examples of a figure being
labelled). It shows no rule output and
no label of another annotator before one's own are frozen, and runs no figure
code. Python's standard library only.

What it writes, per annotator directory:
  <id>.csv           the labels of a figure, in the format bench/R/score-labels.R
                     checks, written once every leaf with elements is labelled
                     (and removed again if a label is taken back before the
                     labels are frozen);
  revised/<id>.csv   the labels as changed after seeing the others', when they differ;
  time.csv           active minutes per finished figure, from the page's timer
                     (time with the tab hidden, or more than 60 s after the
                     last key or click, is not counted);
  .workbench/<id>.json   the session's state, so that work can be resumed.
"""
import argparse
import copy
import csv
import datetime
import hashlib
import http.server
import json
import os
import re
import secrets
import sys
import threading
import urllib.parse
import webbrowser

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
# What the page offers the annotator. 1: outline, loupe, dimming. 2 (2026-11-11):
# also fill and stroke read from the page, painting, isolating, hiding and moving
# a leaf, its place in the drawing order, the guideline's examples of its class.
# 3 (2026-11-11): also each role and kind shown in the guideline's worked
# examples, beside the option. Kept with each figure's state, so that labels can
# be told apart by the aids they were made with. 4 (2026-11-11): a guide in the
# page; the page drawn with a margin, so that outlines at its edge show.
# 5 (2026-11-11): a fourth worked example (ex-box), so that data / box and
# reference / reference area have a standard example too.
WORKBENCH = 5
MAX_BODY = 20 * 1024 * 1024
MAX_ANNOTATORS = 200
NICKNAME = re.compile(r"^[\w-]{2,16}$")
LOCK = threading.RLock()


def read_csv(path):
    with open(path, newline="", encoding="utf-8") as f:
        r = csv.DictReader(f)
        return r.fieldnames, list(r)


def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def now():
    return datetime.datetime.now().isoformat(timespec="seconds")


def shown(path):
    """A path as the page and the messages show it: relative inside the repository."""
    rel = os.path.relpath(path, REPO)
    return path if rel.startswith("..") else rel


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


def indices(spec, n):
    """"all", "3", "1-4,7" -> element indices of a leaf of n."""
    if spec == "all":
        return list(range(1, n + 1))
    out = []
    for part in spec.split(","):
        a = part.split("-")
        out += list(range(int(a[0]), int(a[-1]) + 1))
    return out


class Sheets:
    """The figures to label: their leaf tables, pages and code; the vocabulary."""

    def __init__(self, sheets, figures, vocabulary):
        self.dir, self.figures = sheets, figures
        with open(vocabulary, encoding="utf-8") as f:
            self.vocabulary = json.load(f)
        self.kinds = {r["role"]: [k["kind"] for k in r["kinds"]] for r in self.vocabulary["roles"]}
        ids = [f[:-4] for f in sorted(os.listdir(sheets))
               if f.endswith(".csv") and not f.endswith("-elements.csv") and f != "index.csv" and not f.startswith(".")]
        missing = [i for i in ids if not os.path.exists(os.path.join(sheets, i + ".svg"))]
        if missing:
            sys.exit("no page for %s in %s: draw the sheets first (Rscript bench/R/label-sheet.R draw <run dir> %s)"
                     % (", ".join(missing[:5]), sheets, sheets))
        self.header, self.rows = {}, {}
        for i in ids:
            self.header[i], self.rows[i] = read_csv(os.path.join(sheets, i + ".csv"))
        # the smallest figure first: the easy ones teach the keys
        self.ids = sorted(ids, key=lambda i: len(self.leaves(i)))

    def leaves(self, fig):
        return [r for r in self.rows[fig] if int(r["n_elements"]) > 0]

    def valid(self, lab):
        return (isinstance(lab, dict) and lab.get("role") in self.kinds
                and lab.get("kind") in self.kinds[lab["role"]])

    @staticmethod
    def note(lab):
        text = re.sub(r"[\r\n\t]+", " ", str(lab.get("note") or "")).strip()[:300]
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
        if not isinstance(parts, list) or len(parts) != n or not all(self.valid(p) for p in parts):
            return None
        groups = {}
        for i, p in enumerate(parts, start=1):
            groups.setdefault((p["role"], p["kind"], self.note(p)), []).append(i)
        if len(groups) == 1:
            (role, kind, note), _ = next(iter(groups.items()))
            return [dict(row, elements="all", role=role, kind=kind, note=note)]
        return [dict(row, elements=ranges(idx), role=role, kind=kind, note=note)
                for (role, kind, note), idx in sorted(groups.items(), key=lambda g: g[1][0])]

    def label_rows(self, fig, labels):
        """(label rows of the leaves labelled so far, number of leaves labelled, complete?)"""
        out, done = [], 0
        leaves = self.leaves(fig)
        for r in leaves:
            lr = self.leaf_rows(r, labels.get(r["k"]))
            if lr is not None:
                out.extend(lr)
                done += 1
        return out, done, done == len(leaves)

    def resolve(self, fig, rows, source):
        """Label rows made elsewhere, on this sheet's leaves; stops with the reasons if they do not fit."""
        at = {(r["key"], r["occurrence"]): r for r in self.rows[fig]}
        out, seen, problems = [], {}, []
        for line, r in enumerate(rows, start=2):
            s = at.get((r.get("key"), r.get("occurrence")))
            if s is None:
                problems.append("line %d: key '%s' #%s resolves to no leaf" % (line, r.get("key"), r.get("occurrence")))
                continue
            n = int(s["n_elements"])
            if n == 0:
                continue
            if r.get("class") != s["class"] or r.get("n_elements") != s["n_elements"]:
                problems.append("line %d: leaf k %s is %s with %s elements, the label says %s with %s"
                                % (line, s["k"], s["class"], s["n_elements"], r.get("class"), r.get("n_elements")))
                continue
            if not self.valid(r):
                problems.append("line %d: %s / %s is not in the vocabulary" % (line, r.get("role"), r.get("kind")))
                continue
            try:
                idx = indices(r["elements"], n)
            except (KeyError, ValueError):
                idx = []
            if not idx or min(idx) < 1 or max(idx) > n:
                problems.append("line %d: elements '%s' of a leaf of %d" % (line, r.get("elements"), n))
                continue
            seen.setdefault(s["k"], []).extend(idx)
            out.append(dict(s, elements=r["elements"], role=r["role"], kind=r["kind"], note=r.get("note") or ""))
        for s in self.leaves(fig):
            if sorted(seen.get(s["k"], [])) != list(range(1, int(s["n_elements"]) + 1)):
                problems.append("leaf k %s (%s): its elements are not labelled exactly once" % (s["k"], s["class"]))
        if problems:
            sys.exit("%s does not fit the sheet of %s:\n  %s" % (shown(source), fig, "\n  ".join(problems[:20])))
        return out

    def payload(self, fig):
        _, els = read_csv(os.path.join(self.dir, fig + "-elements.csv"))
        with open(os.path.join(self.dir, fig + ".svg"), encoding="utf-8") as f:
            svg = f.read()
        code_file = os.path.join(self.figures, fig, "code.R")
        code = open(code_file, encoding="utf-8").read() if os.path.exists(code_file) else ""
        box = lambda r: [num(r["x0"]), num(r["y0"]), num(r["x1"]), num(r["y1"])]
        return {
            "id": fig, "svg": svg, "code": code,
            "leaves": [{"k": r["k"], "leaf": r["leaf"], "class": r["class"], "n": int(r["n_elements"]),
                        "tags": r["tags"], "text": r["text"], "fill": r["fill"], "stroke": r["stroke"],
                        "path": r["path"], "box": box(r)} for r in self.rows[fig]],
            "elements": [{"k": e["k"], "index": int(e["index"]), "tag": e["tag"], "text": e["text"],
                          "fill": e["fill"], "stroke": e["stroke"], "box": box(e)} for e in els],
        }


def reference(examples, sheets, figures, vocabulary):
    """The guideline's worked examples, for the page: each example figure's page
    and, per leaf, its decided labels (`figures`); per role and kind, the leaves
    the vocabulary names as its examples (`kinds`); the figure that shows the
    roles (`figure`). A figure that is itself being labelled is never given.
    An example the vocabulary names that is not labelled so stops the server."""
    empty = {"figures": [], "kinds": {}, "figure": None}
    labels = os.path.join(examples, "labels") if examples else ""
    if not os.path.isdir(labels):
        return empty
    ex = Sheets(examples, figures, vocabulary)
    out, rows = dict(empty, figures=[], kinds={}), {}
    for fig in ex.ids:
        file = os.path.join(labels, fig + ".csv")
        if fig in sheets.ids or not os.path.exists(file):
            continue
        rows[fig] = ex.resolve(fig, read_csv(file)[1], file)
        by_k = {}
        for r in rows[fig]:
            by_k.setdefault(r["k"], []).append({"elements": r["elements"], "role": r["role"], "kind": r["kind"]})
        with open(os.path.join(examples, fig + ".svg"), encoding="utf-8") as f:
            svg = f.read()
        out["figures"].append({"id": fig, "svg": svg,
                               "leaves": [{"k": r["k"], "leaf": r["leaf"], "class": r["class"], "n": int(r["n_elements"]), "text": r["text"],
                                           "box": [num(r["x0"]), num(r["y0"]), num(r["x1"]), num(r["y1"])], "labels": by_k[r["k"]]}
                                          for r in ex.leaves(fig)]})
    if ex.vocabulary.get("example_figure") in rows:
        out["figure"] = ex.vocabulary["example_figure"]
    problems = []
    for role in ex.vocabulary["roles"]:
        for kind in role["kinds"]:
            name = role["role"] + " / " + kind["kind"]
            for e in kind.get("examples", []):
                fig, k = e.get("figure"), str(e.get("k"))
                if fig in sheets.ids:
                    continue                      # being labelled: not an example here
                leaf = next((r for r in ex.leaves(fig) if r["k"] == k), None) if fig in rows else None
                if leaf is None:
                    problems.append("%s: %s k %s is not a labelled leaf of the examples" % (name, fig, k))
                    continue
                n = int(leaf["n_elements"])
                have = sorted(i for r in rows[fig] if r["k"] == k and r["role"] == role["role"] and r["kind"] == kind["kind"]
                              for i in indices(r["elements"], n))
                try:
                    want = sorted(indices(e["elements"], n)) if e.get("elements") else have
                except ValueError:
                    want = []
                if not want or not set(want) <= set(have):
                    problems.append("%s: %s k %s%s is not labelled so in %s" % (name, fig, k, " elements " + e["elements"] if e.get("elements") else "",
                                                                             shown(os.path.join(labels, fig + ".csv"))))
                    continue
                box = [num(leaf[c]) for c in ("x0", "y0", "x1", "y1")]
                if len(want) < n:
                    els = [x for x in read_csv(os.path.join(examples, fig + "-elements.csv"))[1] if x["k"] == k and int(x["index"]) in want]
                    b = [[num(x[c]) for x in els] for c in ("x0", "y0", "x1", "y1")]
                    if els and all(v is not None for c in b for v in c):
                        box = [min(b[0]), min(b[1]), max(b[2]), max(b[3])]
                out["kinds"].setdefault(name, []).append({"figure": fig, "k": k, "leaf": leaf["leaf"], "text": leaf["text"], "box": box,
                                                          "index": want if len(want) < n else None})
    if problems:
        sys.exit("the vocabulary's examples do not fit %s:\n  %s" % (shown(examples), "\n  ".join(problems)))
    return out


class Annotator:
    """One annotator's directory of labels. `made` holds the label rows of an
    annotator whose labels were made elsewhere ({figure: rows}); such an
    annotator is read-only."""

    def __init__(self, sheets, out, name, made=None):
        self.sheets, self.out, self.name, self.made = sheets, out, name, made
        self.readonly = made is not None
        self.state_dir = os.path.join(out, ".workbench")
        if not self.readonly:
            os.makedirs(self.state_dir, exist_ok=True)

    def state_file(self, fig):
        return os.path.join(self.state_dir, fig + ".json")

    def state(self, fig):
        try:
            with open(self.state_file(fig), encoding="utf-8") as f:
                return json.load(f)
        except FileNotFoundError:
            return {"labels": {}, "seconds": 0}

    def locked(self, fig):
        return fig in self.made if self.readonly else "independent" in self.state(fig)

    def independent_rows(self, fig):
        """The label rows agreement is computed from (what <id>.csv holds), or None while the figure is unfinished."""
        if self.readonly:
            return self.made.get(fig)
        st = self.state(fig)
        rows, _, complete = self.sheets.label_rows(fig, st.get("independent", st["labels"]))
        return rows if complete else None

    def progress(self, fig, st=None):
        n = len(self.sheets.leaves(fig))
        if self.readonly:
            done = fig in self.made
            return {"id": fig, "leaves": n, "labelled": n if done else 0, "done": done, "seconds": 0, "locked": done}
        st = st or self.state(fig)
        _, done, complete = self.sheets.label_rows(fig, st["labels"])
        return {"id": fig, "leaves": n, "labelled": done, "done": complete,
                "seconds": st.get("seconds", 0), "locked": "independent" in st, "workbench": st.get("workbench", 1)}

    def write_state(self, fig, st):
        st["saved"] = now()
        tmp = self.state_file(fig) + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(st, f, ensure_ascii=False, indent=1)
        os.replace(tmp, self.state_file(fig))

    def write_labels(self, path, fig, rows):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path + ".tmp", "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=self.sheets.header[fig], quoting=csv.QUOTE_ALL, lineterminator="\n")
            w.writeheader()
            w.writerows(rows)
        os.replace(path + ".tmp", path)

    def write_outputs(self, fig, st):
        target = os.path.join(self.out, fig + ".csv")
        revised = os.path.join(self.out, "revised", fig + ".csv")
        rows, _, complete = self.sheets.label_rows(fig, st.get("independent", st["labels"]))
        if complete:
            self.write_labels(target, fig, rows)
        elif os.path.exists(target):
            os.remove(target)
        now_rows, _, now_complete = self.sheets.label_rows(fig, st["labels"])
        if "independent" in st and now_complete and now_rows != rows:
            self.write_labels(revised, fig, now_rows)
        elif os.path.exists(revised):
            os.remove(revised)
        self.write_time()
        return shown(target) if complete else None

    def save(self, fig, posted):
        labels = posted.get("labels")
        if not isinstance(labels, dict):
            raise ValueError("no labels")
        known = {r["k"] for r in self.sheets.leaves(fig)}
        if set(labels) - known:
            raise ValueError("labels for leaves the sheet does not have: %s" % sorted(set(labels) - known)[:5])
        with LOCK:
            st = self.state(fig)
            # A page sends all the labels it holds. One that loaded the figure before
            # another page saved it would write its older ones over the newer: each
            # save names the revision the page holds, and only the latest is taken.
            rev = int(st.get("rev") or 0)
            if posted.get("rev") != rev:
                raise Stale("这张图在别的页面（或别的设备）上改过，这个页面里的是旧的")
            st.update(figure=fig, guideline=self.sheets.vocabulary["guideline"], workbench=WORKBENCH, labels=labels,
                      cursor=posted.get("cursor"), rev=rev + 1)
            # the timer stops once the labels are frozen: time.csv is the time to label
            if "independent" not in st:
                st["seconds"] = max(int(posted.get("seconds") or 0), int(st.get("seconds") or 0))
            self.write_state(fig, st)
            file = self.write_outputs(fig, st)
        return dict(self.progress(fig, st), file=file, rev=st["rev"])

    def lock(self, figs):
        """Freeze the labels of finished figures as the independent ones."""
        with LOCK:
            for fig in figs:
                st = self.state(fig)
                if "independent" in st or not self.sheets.label_rows(fig, st["labels"])[2]:
                    continue
                st["independent"] = copy.deepcopy(st["labels"])
                st["frozen"] = now()
                self.write_state(fig, st)
                self.write_outputs(fig, st)

    def write_time(self):
        with open(os.path.join(self.out, "time.csv"), "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f, quoting=csv.QUOTE_ALL, lineterminator="\n")
            w.writerow(["figure", "minutes", "guideline", "note"])
            for fig in self.sheets.ids:
                p = self.progress(fig)
                if p["done"] or p["locked"]:
                    w.writerow([fig, "%.1f" % (p["seconds"] / 60), self.sheets.vocabulary["guideline"],
                                "label workbench %s timer: %d s active (tab hidden or idle over 60 s not counted)"
                                % (p["workbench"], p["seconds"])])


class Stale(Exception):
    """A save from a page that did not load the figure's latest labels."""


def kappa(pairs):
    """Weighted Cohen's kappa and agreement of [(a, b, weight)], as kappa_w() of score-labels.R."""
    total = sum(w for _, _, w in pairs)
    if not total:
        return None, None
    po = sum(w for a, b, w in pairs if a == b) / total
    pa, pb = {}, {}
    for a, b, w in pairs:
        pa[a] = pa.get(a, 0) + w / total
        pb[b] = pb.get(b, 0) + w / total
    pe = sum(pa[c] * pb.get(c, 0) for c in pa)
    return ((po - pe) / (1 - pe) if pe < 1 else None), po


class Workbench:
    """Who labels where, and what each may see."""

    def __init__(self, sheets, out=None, team=None, reveal="set", invite=None, examples=None):
        self.sheets, self.reveal, self.invite = sheets, reveal, invite
        self.examples = examples or {"figures": [], "kinds": {}, "figure": None}
        self.team = team is not None
        if not self.team:
            self.single = Annotator(sheets, out, os.path.basename(os.path.normpath(out)))
            # Never write over labels this workbench did not make. An untouched
            # copy of the empty sheet holds no labels and is replaced.
            for i in sheets.ids:
                mine = os.path.join(out, i + ".csv")
                if os.path.exists(mine) and not os.path.exists(self.single.state_file(i)):
                    with open(mine, "rb") as a, open(os.path.join(sheets.dir, i + ".csv"), "rb") as b:
                        if a.read() == b.read():
                            os.remove(mine)
                            continue
                    sys.exit("%s holds labels the workbench did not write; choose another --out, or move the file away" % mine)
            return
        self.root = team
        self.meta = os.path.join(team, ".team")
        os.makedirs(self.meta, exist_ok=True)
        self.accounts_file = os.path.join(self.meta, "accounts.json")
        try:
            with open(self.accounts_file, encoding="utf-8") as f:
                self.accounts = json.load(f)
        except FileNotFoundError:
            self.accounts = {}
        self.made = {}
        for d in sorted(os.listdir(team)):
            p = os.path.join(team, d)
            if d.startswith(".") or not os.path.isdir(p) or d in self.accounts:
                continue
            files = [(i, os.path.join(p, i + ".csv")) for i in sheets.ids if os.path.exists(os.path.join(p, i + ".csv"))]
            if files:
                self.made[d] = {i: sheets.resolve(i, read_csv(f)[1], f) for i, f in files}

    # ---- accounts -----------------------------------------------------------
    @staticmethod
    def digest(token):
        return hashlib.sha256(token.encode("utf-8")).hexdigest()

    def annotators(self):
        return ([Annotator(self.sheets, os.path.join(self.root, n), n) for n in list(self.accounts)]
                + [Annotator(self.sheets, os.path.join(self.root, n), n, made=m) for n, m in self.made.items()])

    def join(self, nickname, invite, token=None):
        nickname = (nickname or "").strip()
        if self.invite and not secrets.compare_digest(str(invite or ""), self.invite):
            raise PermissionError("邀请码不对")
        if not NICKNAME.match(nickname) or nickname.startswith("-"):
            raise ValueError("昵称要 2–16 个字，可以用汉字、字母、数字、下划线和短横线")
        with LOCK:
            taken = {n.lower(): n for n in list(self.accounts) + os.listdir(self.root)}
            if nickname.lower() in taken:
                acc = self.accounts.get(taken[nickname.lower()])
                if acc and token and secrets.compare_digest(self.digest(token), acc["token"]):
                    return taken[nickname.lower()], token
                raise ValueError("昵称“%s”已经有人用了，换一个" % nickname)
            if len(self.accounts) >= MAX_ANNOTATORS:
                raise ValueError("人数已满")
            token = secrets.token_hex(16)
            self.accounts[nickname] = {"token": self.digest(token), "joined": now()}
            tmp = self.accounts_file + ".tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(self.accounts, f, ensure_ascii=False, indent=1)
            os.replace(tmp, self.accounts_file)
            Annotator(self.sheets, os.path.join(self.root, nickname), nickname)
        return nickname, token

    def auth(self, token):
        if not self.team:
            return self.single
        if token:
            d = self.digest(token)
            for name, acc in list(self.accounts.items()):
                if secrets.compare_digest(d, acc["token"]):
                    return Annotator(self.sheets, os.path.join(self.root, name), name)
        return None

    # ---- what an annotator may see ------------------------------------------
    def eligible(self, a, fig):
        """May `a` open the others' labels of `fig` now?"""
        if not self.team:
            return False
        if self.reveal == "figure":
            return a.progress(fig)["done"]
        return all(a.progress(i)["done"] for i in self.sheets.ids)

    def open_labels(self, a, fig):
        if not self.eligible(a, fig):
            raise PermissionError("先标完" + ("这张图" if self.reveal == "figure" else "全部的图"))
        a.lock([fig] if self.reveal == "figure" else self.sheets.ids)

    def elements_of(self, fig, rows):
        """{k: [(role, kind), ...] per element} of a figure's label rows."""
        n = {r["k"]: int(r["n_elements"]) for r in self.sheets.leaves(fig)}
        out = {k: [None] * m for k, m in n.items()}
        for r in rows:
            if r["k"] in out:
                for i in indices(r["elements"], n[r["k"]]):
                    out[r["k"]][i - 1] = (r["role"], r["kind"])
        return out

    def final(self, fig):
        """[(annotator, label rows)] of those who have labelled `fig` completely."""
        out = []
        for b in self.annotators():
            rows = b.independent_rows(fig)
            if rows is not None:
                out.append((b, rows))
        return out

    def peers(self, a, fig):
        """Per leaf: who gave which label, how the roles split (in annotators), and the share of
        annotators who give an element its most common role, averaged over the leaf's elements.
        Only for a figure `a` has frozen."""
        if not self.team or not a.locked(fig):
            return None
        final = self.final(fig)
        maps = [(b, self.elements_of(fig, rows)) for b, rows in final]
        leaves = []
        for r in self.sheets.leaves(fig):
            k, roles, answers = r["k"], {}, []
            for (b, rows), (_, m) in zip(final, maps):
                els = m[k]
                for e in els:
                    roles[e[0]] = roles.get(e[0], 0) + 1 / len(els)
                answers.append({"who": b.name, "me": b.name == a.name,
                                "parts": [{"elements": x["elements"], "role": x["role"], "kind": x["kind"], "note": x["note"]}
                                          for x in rows if x["k"] == k]})
            # agreement is element by element: a leaf everyone splits the same way is agreed on
            n, m = len(final), int(r["n_elements"])
            most = lambda pick: sum(max(pick(e).values()) for e in range(m)) / (m * n) if n else None
            count = lambda vals: {v: vals.count(v) for v in vals}
            share = most(lambda e: count([mp[k][e][0] for _, mp in maps]))
            share_kind = most(lambda e: count([mp[k][e] for _, mp in maps]))
            leaves.append({"k": k, "n": n, "answers": answers,
                           "roles": {x: round(v, 3) for x, v in roles.items()},
                           "share": None if share is None else round(share, 3),
                           "share_kind": None if share_kind is None else round(share_kind, 3)})
        return {"annotators": [b.name for b, _ in final], "leaves": leaves}

    def overview(self, a):
        people = []
        for b in self.annotators():
            ps = [b.progress(i) for i in self.sheets.ids]
            people.append({"who": b.name, "me": b.name == a.name, "readonly": b.readonly,
                           "figures": len(ps), "figures_done": sum(p["done"] for p in ps),
                           "leaves": sum(p["leaves"] for p in ps), "labelled": sum(p["labelled"] for p in ps)})
        out = {"reveal": self.reveal, "people": people, "figures": [], "pairs": [], "disputed": []}
        mine = [i for i in self.sheets.ids if a.locked(i)]
        pooled = {}
        for fig in mine:
            final = self.final(fig)
            maps = {b.name: self.elements_of(fig, rows) for b, rows in final}
            names = sorted(maps)
            leaves = self.sheets.leaves(fig)
            agree = []
            for x in range(len(names)):
                for y in range(x + 1, len(names)):
                    pr = [(ea, eb, 1 / len(maps[names[x]][r["k"]]))
                          for r in leaves for ea, eb in zip(maps[names[x]][r["k"]], maps[names[y]][r["k"]]) if ea and eb]
                    pooled.setdefault((names[x], names[y]), {"figures": 0, "pairs": []})
                    pooled[(names[x], names[y])]["figures"] += 1
                    pooled[(names[x], names[y])]["pairs"] += pr
                    agree.append(kappa([(p[0][0], p[1][0], p[2]) for p in pr])[1])
            p = self.peers(a, fig)
            out["figures"].append({"id": fig, "annotators": len(names), "leaves": len(leaves),
                                   "unanimous": sum(1 for l in p["leaves"] if l["share"] == 1),
                                   "agreement": round(sum(agree) / len(agree), 3) if agree else None})
            rows = {r["k"]: r for r in leaves}
            for l in p["leaves"]:
                if l["n"] > 1 and l["share"] is not None and l["share"] < 1:
                    out["disputed"].append({"fig": fig, "k": l["k"], "class": rows[l["k"]]["class"],
                                            "text": rows[l["k"]]["text"], "share": l["share"], "roles": l["roles"], "n": l["n"]})
        for (x, y), v in sorted(pooled.items()):
            k_role, a_role = kappa([(p[0][0], p[1][0], p[2]) for p in v["pairs"]])
            k_kind, a_kind = kappa([(p[0], p[1], p[2]) for p in v["pairs"]])
            r3 = lambda z: None if z is None else round(z, 3)
            out["pairs"].append({"a": x, "b": y, "figures": v["figures"], "kappa": r3(k_role), "agreement": r3(a_role),
                                 "kappa_kind": r3(k_kind), "agreement_kind": r3(a_kind)})
        out["disputed"] = sorted(out["disputed"], key=lambda d: d["share"])[:40]
        return out

    def config(self, a):
        figures = [a.progress(i) for i in self.sheets.ids]
        for f in figures:
            f["eligible"] = self.eligible(a, f["id"])
        return {"annotator": a.name, "out": shown(a.out), "team": self.team, "reveal": self.reveal if self.team else None,
                "vocabulary": self.sheets.vocabulary, "figures": figures,
                "people": len(self.annotators()) if self.team else 1}


def handler(wb):
    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def send(self, code, body, ctype="application/json; charset=utf-8"):
            data = body if isinstance(body, bytes) else json.dumps(body, ensure_ascii=False).encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            self.wfile.write(data)

        def who(self):
            return wb.auth(self.headers.get("X-Workbench-Token"))

        def figure_id(self, prefix):
            fig = urllib.parse.urlsplit(self.path).path[len(prefix):]
            return fig if fig in wb.sheets.ids else None

        def body(self):
            n = int(self.headers.get("Content-Length") or 0)
            if n < 0 or n > MAX_BODY:
                raise ValueError("bad request size")
            posted = json.loads(self.rfile.read(n).decode("utf-8")) if n else {}
            if not isinstance(posted, dict):
                raise ValueError("not an object")
            return posted

        def do_GET(self):
            path = urllib.parse.urlsplit(self.path).path
            if path in ("/", "/index.html"):
                with open(os.path.join(HERE, "index.html"), "rb") as f:
                    return self.send(200, f.read(), "text/html; charset=utf-8")
            if path == "/api/hello":
                return self.send(200, {"team": wb.team, "reveal": wb.reveal if wb.team else None,
                                       "invite": bool(wb.team and wb.invite), "figures": len(wb.sheets.ids)})
            a = self.who()
            if a is None:
                return self.send(401, {"error": "先加入"})
            if path == "/api/config":
                return self.send(200, wb.config(a))
            if path == "/api/reference":
                return self.send(200, wb.examples)
            if path == "/api/overview" and wb.team:
                return self.send(200, wb.overview(a))
            for prefix in ("/api/figure/", "/api/peers/"):
                if path.startswith(prefix):
                    fig = self.figure_id(prefix)
                    if not fig:
                        break
                    if prefix == "/api/peers/":
                        return self.send(200, {"peers": wb.peers(a, fig)})
                    return self.send(200, dict(wb.sheets.payload(fig), state=a.state(fig),
                                               eligible=wb.eligible(a, fig), peers=wb.peers(a, fig)))
            self.send(404, {"error": "not found"})

        def do_POST(self):
            path = urllib.parse.urlsplit(self.path).path
            try:
                b = self.body()
                if path == "/api/join" and wb.team:
                    name, token = wb.join(b.get("nickname"), b.get("invite"), b.get("token"))
                    return self.send(200, {"nickname": name, "token": token})
                a = self.who()
                if a is None:
                    return self.send(401, {"error": "先加入"})
                for prefix in ("/api/state/", "/api/open/"):
                    if path.startswith(prefix):
                        fig = self.figure_id(prefix)
                        if not fig:
                            break
                        if prefix == "/api/open/":
                            wb.open_labels(a, fig)
                            return self.send(200, {"peers": wb.peers(a, fig), "state": a.state(fig)})
                        return self.send(200, dict(a.save(fig, b), eligible=wb.eligible(a, fig)))
                self.send(404, {"error": "not found"})
            except PermissionError as e:
                self.send(403, {"error": str(e)})
            except Stale as e:
                self.send(409, {"error": str(e)})
            except (ValueError, KeyError, TypeError, AttributeError) as e:
                self.send(400, {"error": str(e)})
    return Handler


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--sheets", default=os.path.join(REPO, "bench", "labels", "pilot", "sheets"))
    ap.add_argument("--out", default=os.path.join(REPO, "bench", "labels", "pilot", "owner"),
                    help="one annotator's labels directory")
    ap.add_argument("--team", help="several annotators: the root of their labels directories")
    ap.add_argument("--reveal", choices=["set", "figure"], default="set",
                    help="team: when an annotator may open the others' labels (default: after the whole set)")
    ap.add_argument("--invite", help="team: the code needed to join (default: a random one, printed)")
    ap.add_argument("--figures", default=os.path.join(REPO, "bench", "figures"))
    ap.add_argument("--vocabulary", default=os.path.join(REPO, "bench", "labels", "vocabulary.json"))
    ap.add_argument("--examples", default=os.path.join(REPO, "bench", "labels", "examples"),
                    help="the guideline's worked examples, shown as reference ('' for none)")
    ap.add_argument("--host", default="127.0.0.1", help="address to listen on (0.0.0.0: every interface)")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--no-open", action="store_true", help="do not open the browser")
    a = ap.parse_args()
    sheets = Sheets(os.path.abspath(a.sheets), os.path.abspath(a.figures), a.vocabulary)
    examples = reference(os.path.abspath(a.examples) if a.examples else "", sheets, os.path.abspath(a.figures), a.vocabulary)
    if a.team:
        os.makedirs(a.team, exist_ok=True)
        wb = Workbench(sheets, team=os.path.abspath(a.team), reveal=a.reveal, invite=a.invite or secrets.token_urlsafe(6),
                       examples=examples)
    else:
        if a.host != "127.0.0.1":
            sys.exit("--host needs --team: one annotator's workbench has no accounts, so it listens on this machine only")
        os.makedirs(a.out, exist_ok=True)
        wb = Workbench(sheets, out=os.path.abspath(a.out), examples=examples)
    server = None
    for port in range(a.port, a.port + 20):
        try:
            server = http.server.ThreadingHTTPServer((a.host, port), handler(wb))
            break
        except OSError:
            continue
    if server is None:
        sys.exit("no free port from %d" % a.port)
    url = "http://%s:%d/" % ("127.0.0.1" if a.host in ("127.0.0.1", "0.0.0.0") else a.host, server.server_address[1])
    if a.team:
        print("label workbench (team): %s?invite=%s  (%d figures; labels under %s; others' labels open after the %s; port %d on %s; Ctrl-C stops it)"
              % (url, wb.invite, len(sheets.ids), shown(wb.root), "whole set" if a.reveal == "set" else "figure",
                 server.server_address[1], a.host), flush=True)
    else:
        print("label workbench: %s  (%d figures; labels go to %s; Ctrl-C stops it)"
              % (url, len(sheets.ids), shown(wb.single.out)), flush=True)
    if not a.no_open and not a.team:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped; state and finished labels are saved")


if __name__ == "__main__":
    main()
