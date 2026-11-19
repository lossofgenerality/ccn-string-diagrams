"""
figreader: read string diagrams from the vector drawings of a PDF page.
CCN String Diagrams · By Dara O Shayda and Noor Hoshino (星野ヌール)
© Computational Classnotes · CC BY-NC-SA 4.0

The figures of Turaev & Virelizier are vector graphics: strands are line segments, boxes are rectangles,
caps and cups are Bézier curves, arrows are small filled triangles, and every label is real text with a
position. figreader takes those drawing instructions (with PyMuPDF) and rebuilds each diagram as a
layered form LD[src, {{a, B[name, ins, outs]}, ...}], the data structure of the CCN String Diagrams code.

Pipeline for one page:
  1. primitives: vertical segments, boxes, arcs (caps, cups), arrow heads, text spans
  2. figures: cluster the primitives that touch; join clusters separated only by '=' into one equation
  3. per diagram: cut strands at boxes, attach segment ends to box edges and arc ends, follow strands
  4. labels: each colour label goes to the nearest strand end; each box label is the text inside it
  5. layers: sweep the boxes and arcs from the bottom of the picture to the top, keeping the list of
     strands that cross the current height; each box replaces its inputs by its outputs
Usage:  python3 figreader.py book.pdf PAGE [PAGE ...]   (pages counted from 1, as in the PDF)
"""
import sys, json, math
import pymupdf as fitz

EPS = 1.6          # points: how close two ends must be to touch
LABEL_R = 14.0     # points: how far a colour label may sit from its strand

def merge_text(spans):
    """Join spans left to right; a smaller span sitting low after a larger one is a subscript,
    one sitting high is a superscript (∗, ′, −1)."""
    if not spans: return ""
    spans = sorted(spans, key=lambda s: s["x0"])
    base = max(s["size"] for s in spans)
    out, mode = "", None
    for s in spans:
        t = s["text"].replace(" ", "")
        if not t: continue
        small = s["size"] < 0.85 * base
        if t in ("∨", "∨"):
            out += "∨"; mode = None; continue
        if small and s["y1"] > spans[0]["y1"] - 0.5 and s["y0"] > min(x["y0"] for x in spans) + 1:
            out += ("_" if mode != "sub" else "") + t; mode = "sub"
        elif small and t in ("∗", "*", "′", "−1", "−", "1"):
            out += {"∗": "*", "−": "⁻", "1": "¹" if mode == "sup" else "1"}.get(t, t); mode = "sup"
        else:
            out += t; mode = None
    out = out.replace("∗", "*").replace("−1", "⁻¹").replace("⁻1", "⁻¹")
    if "_" in out:
        head, sub = out.split("_", 1)
        if len(sub) > 1 and not sub.startswith("{"): out = head + "_{" + sub + "}"
    return out

def bez(p0, p1, p2, p3, n=16):
    return [((1-t)**3*p0[0] + 3*(1-t)**2*t*p1[0] + 3*(1-t)*t*t*p2[0] + t**3*p3[0],
             (1-t)**3*p0[1] + 3*(1-t)**2*t*p1[1] + 3*(1-t)*t*t*p2[1] + t**3*p3[1]) for t in [k / n for k in range(n + 1)]]

def P(pt): return (pt.x, pt.y)

class Page:
    """The primitives of one PDF page: stroked paths as polylines, boxes, arrow heads and text spans."""
    def __init__(self, doc, pno):
        self.pno = pno
        pg = doc[pno - 1]
        self.paths, self.boxes, self.heads, self.texts = [], [], [], []
        for d in pg.get_drawings():
            w, fill, r = d.get("width") or 0, d.get("fill"), d["rect"]
            if fill is not None and r.width < 6.5 and r.height < 6.5 and (r.width > 0.5 or r.height > 0.5):
                self.heads.append([P(it[1]) for it in d["items"]]); continue
            if w < 0.3: continue
            chain = []
            def flush():
                if len(chain) > 1: self.paths.append(list(chain))
                chain.clear()
            for it in d["items"]:
                if it[0] == "re":
                    flush(); b = it[1]
                    if b.width > 3 and b.height > 3: self.boxes.append({"x0": b.x0, "y0": b.y0, "x1": b.x1, "y1": b.y1})
                    continue
                if it[0] == "l":
                    a, b = P(it[1]), P(it[2]); m = max(2, int(math.dist(a, b) / 0.5))
                    pts = [(a[0] + (b[0] - a[0]) * k / m, a[1] + (b[1] - a[1]) * k / m) for k in range(m + 1)]
                else:
                    pts = bez(P(it[1]), P(it[2]), P(it[3]), P(it[4]))
                if chain and math.dist(chain[-1], pts[0]) > 0.3: flush()
                chain.extend(pts if not chain else pts[1:])
            flush()
        for b in pg.get_text("dict")["blocks"]:
            for l in b.get("lines", []):
                for s in l["spans"]:
                    if s["text"].strip():
                        x0, y0, x1, y1 = s["bbox"]
                        self.texts.append({"text": s["text"].strip(), "x0": x0, "y0": y0, "x1": x1, "y1": y1, "size": s["size"]})
        self.boxes = dedupe_boxes(self.boxes)
        # drop paths that are just the edges of a box drawn as lines
        self.paths = [p for p in self.paths if not (len(p) == 2 and abs(p[0][1] - p[1][1]) < 0.3)]

def dedupe_boxes(bs):
    out = []
    for b in bs:
        if not any(abs(b["x0"] - c["x0"]) < 0.5 and abs(b["y0"] - c["y0"]) < 0.5 and abs(b["x1"] - c["x1"]) < 0.5 for c in out):
            out.append(b)
    return out

def bbox_of(kind, item):
    if kind == "path":
        return (min(p[0] for p in item), min(p[1] for p in item), max(p[0] for p in item), max(p[1] for p in item))
    return (item["x0"], item["y0"], item["x1"], item["y1"])

def clusters(page):
    """Group paths and boxes that touch (within EPS) into connected pictures."""
    items = [("path", p) for p in page.paths] + [("box", b) for b in page.boxes]
    n = len(items); parent = list(range(n))
    def find(i):
        while parent[i] != i: parent[i] = parent[parent[i]]; i = parent[i]
        return i
    bbs = [bbox_of(*it) for it in items]
    for i in range(n):
        for j in range(i + 1, n):
            a, b = bbs[i], bbs[j]
            if a[0] - EPS <= b[2] and b[0] - EPS <= a[2] and a[1] - EPS <= b[3] and b[1] - EPS <= a[3]:
                parent[find(i)] = find(j)
    groups = {}
    for i in range(n): groups.setdefault(find(i), []).append(items[i])
    out = []
    for g in groups.values():
        bb = [bbox_of(*x) for x in g]
        box = (min(b[0] for b in bb), min(b[1] for b in bb), max(b[2] for b in bb), max(b[3] for b in bb))
        if box[3] - box[1] < 8 or not any(k == "path" for k, _ in g): continue
        out.append({"items": g, "bbox": box})
    return out

# ---------- one diagram ----------
def inside(pt, b, m=0.4):
    return b["x0"] + m < pt[0] < b["x1"] - m and b["y0"] + m < pt[1] < b["y1"] - m

def split_monotone(pts):
    """Split a polyline at its turning points in y. Returns pieces and the turns between them:
    'cap' where the path turns at a top point, 'cup' at a bottom point."""
    pieces, turns, cur, sign = [], [], [pts[0]], 0
    for q in pts[1:]:
        dy = q[1] - cur[-1][1]
        s = 0 if abs(dy) < 0.02 else (1 if dy > 0 else -1)
        if s and sign and s != sign:
            pieces.append(cur); turns.append("cup" if sign > 0 else "cap"); cur = [cur[-1]]
        if s: sign = s
        cur.append(q)
    pieces.append(cur)
    return pieces, turns

class Piece:
    def __init__(self, pts, path, k):
        self.pts, self.path, self.k = pts, path, k
        lo = max(pts, key=lambda p: p[1]); hi = min(pts, key=lambda p: p[1])
        self.bot, self.top = lo, hi
        self.below = self.above = None
        self.label = None; self.along = None
    def x_at(self, y):
        ps = sorted(self.pts, key=lambda p: p[1])
        if y <= ps[0][1]: return ps[0][0]
        if y >= ps[-1][1]: return ps[-1][0]
        for a, b in zip(ps, ps[1:]):
            if a[1] <= y <= b[1]:
                return a[0] if b[1] == a[1] else a[0] + (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1])
        return ps[-1][0]
    def dist(self, pt):
        return min(math.dist(pt, p) for p in self.pts)
    def up_in_path(self):
        """True when going along the path (increasing index) moves up the page."""
        return self.pts[-1][1] < self.pts[0][1]

def read_diagram(page, cl):
    boxes = [dict(x, kind="box", ins=[], outs=[]) for k, x in cl["items"] if k == "box"]
    paths = [x for k, x in cl["items"] if k == "path"]
    pieces, nodes = [], list(boxes)
    for pid, pth in enumerate(paths):
        # cut the path where it runs behind a box
        parts, cur = [], []
        for p in pth:
            if any(inside(p, b) for b in boxes):
                if len(cur) > 1: parts.append(cur)
                cur = []
            else:
                cur.append(p)
        if len(cur) > 1: parts.append(cur)
        for part in parts:
            ps, turns = split_monotone(part)
            made = [Piece(q, (pid, id(part)), k) for k, q in enumerate(ps) if abs(max(p[1] for p in q) - min(p[1] for p in q)) > 0.3]
            if len(made) != len(ps):                       # a flat piece was dropped: rebuild turns
                ps2, turns2 = [], []
                for k, q in enumerate(ps):
                    if abs(max(p[1] for p in q) - min(p[1] for p in q)) > 0.3: ps2.append(q)
                turns = turns[:len(made) - 1]
            for k, t in enumerate(turns[:len(made) - 1]):
                a, b = made[k], made[k + 1]
                apex = a.pts[-1]
                left, right = sorted([a, b], key=lambda pc: pc.x_at(apex[1] + (2 if t == "cap" else -2)))
                node = {"kind": t, "x0": min(left.pts[-1][0], apex[0]) - 0.01, "x1": apex[0], "apex": apex, "ins": [], "outs": [], "y1": apex[1], "y0": apex[1]}
                if t == "cap": node["ins"] = [left, right]; left.above = right.above = node
                else: node["outs"] = [left, right]; left.below = right.below = node
                node["x0"] = min(left.x_at(apex[1]), right.x_at(apex[1]))
                nodes.append(node)
            pieces += made
    # attach free piece ends to box edges
    for pc in pieces:
        for b in boxes:
            if pc.below is None and b["x0"] - 0.6 < pc.bot[0] < b["x1"] + 0.6 and abs(pc.bot[1] - b["y0"]) < EPS:
                pc.below = b; b["outs"].append(pc)
            if pc.above is None and b["x0"] - 0.6 < pc.top[0] < b["x1"] + 0.6 and abs(pc.top[1] - b["y1"]) < EPS:
                pc.above = b; b["ins"].append(pc)
    # join pieces that continue each other straight through a gap (a line drawn in two strokes)
    # arrows: the tip is the vertex farthest from the others, the notch the one nearest to them;
    # an arrow runs along its path when (tip − notch) points the way the path's points go
    for h in page.heads:
        if len(h) < 3: continue
        vs = []
        for v in h:
            if all(math.dist(v, w) > 0.2 for w in vs): vs.append(v)
        if len(vs) < 3: continue
        c1, c2 = max(((u, w) for i, u in enumerate(vs) for w in vs[i + 1:]), key=lambda uw: math.dist(*uw))
        mid = ((c1[0] + c2[0]) / 2, (c1[1] + c2[1]) / 2)
        rest = [v for v in vs if v is not c1 and v is not c2] or [mid]
        tip = max(rest, key=lambda v: math.dist(v, mid)); notch = mid
        cen = (sum(p[0] for p in h) / len(h), sum(p[1] for p in h) / len(h))
        pc = min(pieces, key=lambda q: q.dist(cen), default=None)
        if pc is None or pc.dist(cen) > 3: continue
        i = min(range(len(pc.pts)), key=lambda k: math.dist(pc.pts[k], cen))
        a, b = pc.pts[max(i - 1, 0)], pc.pts[min(i + 1, len(pc.pts) - 1)]
        t = (b[0] - a[0], b[1] - a[1]); d = (tip[0] - notch[0], tip[1] - notch[1])
        pc.along = (t[0] * d[0] + t[1] * d[1]) > 0
    # labels
    x0, y0, x1, y1 = cl["bbox"]
    tx = [t for t in page.texts if x0 - LABEL_R <= t["x0"] <= x1 + LABEL_R and y0 - 9 <= t["y0"] <= y1 + 3]
    inbox = {id(b): [] for b in boxes}
    free = []
    for t in tx:
        c = ((t["x0"] + t["x1"]) / 2, (t["y0"] + t["y1"]) / 2)
        host = next((b for b in boxes if b["x0"] <= c[0] <= b["x1"] and b["y0"] <= c[1] <= b["y1"]), None)
        if host: inbox[id(host)].append(t)
        elif t["text"].strip(" .") not in ("=", ",", "and", "or", ""): free.append(t)
    for b in boxes: b["name"] = merge_text(inbox[id(b)])
    free.sort(key=lambda t: t["x0"])
    words = []
    for t in free:
        w = next((w for w in words if abs(w[-1]["y1"] - t["y1"]) < 3.5 and -1.5 <= t["x0"] - w[-1]["x1"] < 2.5), None)
        if w is not None: w.append(t)
        else: words.append([t])
    for w in words:
        wx0, wx1 = w[0]["x0"], max(t["x1"] for t in w); wy0, wy1 = min(t["y0"] for t in w), max(t["y1"] for t in w)
        best, bd = None, LABEL_R
        for pc in pieces:
            for cand in ((wx0, (wy0 + wy1) / 2), (wx0, wy1), (wx0, wy0), (wx1, (wy0 + wy1) / 2), (wx1, wy1), (wx1, wy0)):
                d = pc.dist(cand)
                if d < bd: best, bd = pc, d
        if best is not None and best.label is None: best.label = merge_text(w)
    colour_pieces(pieces)
    return pieces, nodes

def star(c): return c[:-1] if c.endswith("*") else c + "*"

def colour_pieces(pieces):
    """§2.1.3: an arc coloured X and oriented downward contributes X, oriented upward X*. A label gives the
    colour of its whole strand (one path); an arrow anywhere on the path gives the orientation of every piece
    of it, because the pieces follow the path in order."""
    bypath = {}
    for pc in pieces: bypath.setdefault(pc.path, []).append(pc)
    for pcs in bypath.values():
        base = next((q.label for q in pcs if q.label), None)
        along = next((q.along for q in pcs if q.along is not None), None)
        for q in pcs:
            if base is None: q.colour = "?"
            elif along is None: q.colour = base
            else: q.colour = base if q.up_in_path() != along else star(base)

def layered(page, pieces, nodes):
    """Sweep bottom to top. Returns (src, layers, error) with layers [[a, name, ins, outs], ...]."""
    current = sorted([p for p in pieces if p.below is None], key=lambda p: p.bot[0])
    src = [p.colour for p in current]
    def key(n):
        return -(n["y1"] if n["kind"] == "box" else n["apex"][1])
    pending = sorted(nodes, key=lambda n: (round(key(n), 0), n["x0"]))
    layers = []
    while pending:
        for n in pending:
            ins = n["ins"] if n["kind"] == "cap" else sorted(n["ins"], key=lambda p: p.top[0])
            idx = [i for i, c in enumerate(current) if any(c is q for q in ins)]
            if len(idx) == len(ins) and (not idx or idx == list(range(idx[0], idx[0] + len(idx)))):
                y = n["apex"][1] if n["kind"] != "box" else n["y1"]
                a = idx[0] if idx else sum(1 for c in current if c.x_at(y) < n["x0"])
                outs = n["outs"] if n["kind"] == "cup" else sorted(n["outs"], key=lambda p: p.bot[0])
                ic, oc = [p.colour for p in ins], [p.colour for p in outs]
                layers.append([a, node_name(n, ic, oc), ic, oc])
                current = current[:a] + outs + current[a + len(ins):]
                pending.remove(n); break
        else:
            return src, layers, "stuck: no box or arc whose input strands are side by side"
    return src, layers, None

def node_name(n, ic, oc):
    if n["kind"] == "box": return n["name"] or "?"
    legs = ic if n["kind"] == "cap" else oc
    if "?" in legs: return ("ev" if n["kind"] == "cap" else "coev") + "_?"
    l, r = legs
    if n["kind"] == "cap":     # ev_X : X* ⊗ X → 𝟙,  ẽv_X : X ⊗ X* → 𝟙
        return "ev_" + r if l.endswith("*") and not r.endswith("*") else "ev~_" + l if r.endswith("*") else "ev_" + r
    return "coev_" + l if r.endswith("*") and not l.endswith("*") else "coev~_" + r if l.endswith("*") else "coev_" + l

SEPS = ("=", "and", "or", ",", ".", ";")

def read_page(doc, pno):
    """Pictures on a row are split into sides by the separators between them: '=' joins two sides of one
    equation; 'and', 'or', ',' end it. Pictures between two separators are one side (f and g in f ⊗ g)."""
    page = Page(doc, pno)
    cls = clusters(page)
    # rows: clusters whose vertical ranges overlap
    rows = []
    for cl in sorted(cls, key=lambda c: c["bbox"][1]):  # noqa
        for r in rows:
            if cl["bbox"][1] < r["y1"] - 4 and cl["bbox"][3] > r["y0"] + 4:
                r["cls"].append(cl); r["y0"] = min(r["y0"], cl["bbox"][1]); r["y1"] = max(r["y1"], cl["bbox"][3]); break
        else:
            rows.append({"cls": [cl], "y0": cl["bbox"][1], "y1": cl["bbox"][3]})
    out = []
    for r in rows:
        x0 = min(c["bbox"][0] for c in r["cls"]); x1 = max(c["bbox"][2] for c in r["cls"])
        seps = [t for t in page.texts if t["text"].strip(" .") in ("=", "and", "or", ",") and r["y0"] - 2 <= (t["y0"] + t["y1"]) / 2 <= r["y1"] + 2 and x0 < t["x0"] < x1
                and not any(c["bbox"][0] < (t["x0"] + t["x1"]) / 2 < c["bbox"][2] for c in r["cls"])]
        events = sorted([("pic", c["bbox"][0], c) for c in r["cls"]] + [("sep", t["x0"], t) for t in seps], key=lambda e: e[1])
        eq, side = [], []
        def close_side():
            if side:
                merged = {"items": [i for c in side for i in c["items"]], "bbox": (min(c["bbox"][0] for c in side), min(c["bbox"][1] for c in side), max(c["bbox"][2] for c in side), max(c["bbox"][3] for c in side))}
                pieces, nodes = read_diagram(page, merged)
                src, layers, err = layered(page, pieces, nodes)
                eq.append({"bbox": [round(v, 1) for v in merged["bbox"]], "src": src, "ls": layers, "error": err})
        for kind, _, obj in events:
            if kind == "pic":
                if side and obj["bbox"][0] - max(c["bbox"][2] for c in side) > 22:     # a wide gap with no sign: a new equation
                    close_side(); side = []
                    if eq: out.append({"page": pno, "sides": eq})
                    eq = []
                side.append(obj)
            else:
                close_side(); side = []
                if obj["text"].strip(" .") != "=":
                    if eq: out.append({"page": pno, "sides": eq})
                    eq = []
        close_side()
        if eq: out.append({"page": pno, "sides": eq})
    return out

if __name__ == "__main__":
    doc = fitz.open(sys.argv[1])
    out = []
    for pno in map(int, sys.argv[2:]):
        out += read_page(doc, pno)
    json.dump(out, sys.stdout, ensure_ascii=False, indent=1)
