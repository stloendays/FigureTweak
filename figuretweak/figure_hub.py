"""FigureTweak (论文调图) start page: pick a paper (and a version of it), then edit its figures in the browser.

Scans the folders in the paper registry (see registry()) plus any added from the page for figures saved through
tweak.apply (*.tweak_keys.json), groups them by paper -- a git repository, whose worktrees are its versions -- and
serves a start page with thumbnails. Choosing a figure opens figure_tweak.html, the editor figure_tweak.py serves,
with a paper switcher added to its header. Edits, renders and the consistency check are figure_tweak.py's own.
A folder whose figures are not editable yet is onboarded from the page (onboard.py).

    FigureTweak.exe [folder] [--figure <stem or label>] [--port 8766] [--no-window]
    pythonw figure_hub.py [folder | --paper <folder>] ...
    dropping a folder on the exe or its shortcut opens that paper, or offers to onboard it

A second launch reuses the running server and only opens a window. The server stops a little after its last window
closes, or after ten minutes without any window.
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import threading
import time
import webbrowser
from http.server import ThreadingHTTPServer
from urllib.parse import parse_qs, quote, urlsplit
from urllib.request import Request, urlopen

HERE = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))     # the exe unpacks its files here
sys.path.insert(0, HERE)
import chart_templates as ct  # noqa: E402
import figure_tweak as ft  # noqa: E402
import onboard  # noqa: E402

__version__ = "1.4.0"
STATE_DIR = os.path.join(os.environ.get("LOCALAPPDATA") or os.path.expanduser("~"), "figure_hub")
# The paper registry: folders to scan and display names. The first that exists wins: the user's own file, a
# figure-studio skill's projects/figure_papers.json next to this folder, then the default shipped with the program.
REGISTRIES = [os.path.join(STATE_DIR, "papers.json"),
              os.path.join(os.path.dirname(HERE), "projects", "figure_papers.json"),
              os.path.join(HERE, "figure_papers.json")]
CONFIG = os.path.join(STATE_DIR, "config.json")          # added folders, last figure opened, preferred browser
CACHE = os.path.join(STATE_DIR, "scan.json")             # last scan, shown at once while a new one runs
THUMBS = os.path.join(STATE_DIR, "thumbs")
CACHE_VERSION = 2                                        # bump when the scan's record of a figure changes
PRUNE = {".git", "node_modules", ".venv", "venv", "__pycache__", "site-packages", "ml_env", "Lib", ".cache",
         ".ipynb_checkpoints", "$RECYCLE.BIN"}
MAX_DEPTH = 7
FIG_WORDS = ("fig", "plot", "graph", "chart", "图")
BROWSERS = [r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
            r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
            r"C:\Program Files\Google\Chrome\Application\chrome.exe",
            os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe")]


def norm(p):
    return os.path.normcase(os.path.abspath(p))


def disp(p):
    return os.path.abspath(p).replace("\\", "/")


def hid(s):
    return hashlib.sha1(norm(s).encode("utf-8")).hexdigest()[:12]


def load_json(p, default):
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def save_json(p, obj):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p + ".tmp", "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)
    os.replace(p + ".tmp", p)


def registry():
    """(folders to scan, {main checkout: {name, subtitle}}); names set on the page override the registry's."""
    reg = next((load_json(p, {}) for p in REGISTRIES if os.path.exists(p)), {})
    cfg = load_json(CONFIG, {})
    base = [os.path.expanduser(os.path.expandvars(r)) for r in reg.get("scan_roots", [])]
    roots = base + [r for r in cfg.get("extra_roots", []) if r not in base]
    names = {norm(k): v for k, v in reg.get("papers", {}).items()}
    for k, v in cfg.get("names", {}).items():
        names[norm(k)] = dict(names.get(norm(k), {}), **v)
    return roots, names


# ---- discovery ---------------------------------------------------------------------------------------------------
def head_branch(gitdir):
    try:
        with open(os.path.join(gitdir, "HEAD"), encoding="utf-8") as f:
            h = f.read().strip()
    except OSError:
        return ""
    return h[16:] if h.startswith("ref: refs/heads/") else "detached " + h[:7]


def git_info(start):
    """(worktree top, main checkout, branch) of the repository holding start, read from .git without running git;
    None outside a repository."""
    d = os.path.abspath(start)
    while True:
        g = os.path.join(d, ".git")
        if os.path.isdir(g):
            return d, d, head_branch(g)
        if os.path.isfile(g):
            with open(g, encoding="utf-8") as f:
                line = f.read().strip()
            if line.startswith("gitdir:"):
                gd = os.path.normpath(os.path.join(d, line[7:].strip()))
                common = gd
                cf = os.path.join(gd, "commondir")
                if os.path.exists(cf):
                    with open(cf, encoding="utf-8") as f:
                        common = os.path.normpath(os.path.join(gd, f.read().strip()))
                main = os.path.dirname(common) if os.path.basename(common) == ".git" else common
                return d, main, head_branch(gd)
        up = os.path.dirname(d)
        if up == d:
            return None
        d = up


def figure_root(keys_dir, top):
    """The folder figure_tweak would get as --root: the nearest one holding figure_labels.json, else the first folder
    below the worktree top (figures/), so its figures are listed together and checked for consistency together."""
    d = keys_dir
    while True:
        if os.path.exists(os.path.join(d, "figure_labels.json")):
            return d
        up = os.path.dirname(d)
        if norm(d) == norm(top) or up == d:
            break
        d = up
    first = os.path.relpath(keys_dir, top).split(os.sep)[0]
    return top if first in (".", "") else os.path.join(top, first)


def figgy(name):
    n = name.lower()
    return any(w in n for w in FIG_WORDS)


def walk_keys(folders):
    """Every *.tweak_keys.json under folders. Inside a repository only paths with a figure-ish folder (figures/,
    figures_composite/, fig3/ ...) are followed past two levels: a paper's provenance and data trees are large."""
    hits = []
    for root in folders:
        if not os.path.isdir(root):
            continue
        base = os.path.abspath(root).rstrip("\\/").count(os.sep)
        tops = {}                                       # folder -> (repository top, a figure folder seen since)
        for d, ds, fs in os.walk(os.path.abspath(root)):
            if ".git" in ds or ".git" in fs:
                top, seen = d, False
            else:
                top, seen = tops.get(os.path.dirname(d), (None, False))
            if d.count(os.sep) - base >= MAX_DEPTH:
                ds[:] = []
            keep = []
            for x in ds:
                if x in PRUNE or x.startswith(".") or x.endswith("_env"):
                    continue
                s = seen or figgy(x)
                if top and not s and os.path.join(d, x).count(os.sep) - top.count(os.sep) >= 3:
                    continue
                keep.append(x)
                tops[os.path.join(d, x)] = (top, s)
            ds[:] = keep
            hits += [(root, os.path.join(d, f)) for f in fs if f.endswith(".tweak_keys.json")]
    return hits


GENERIC = {"figures", "figure", "figs", "fig", "composite", "figures_composite", "plots", "analysis", "paper"}


def plain_top(keys_dir, root):
    """Outside git: the nearest folder (up to the scanned one) holding tweak.py or figure_labels.json, else the
    folder right below the scanned one; a generic name (figures/) moves up to the folder that names the paper."""
    d, top = keys_dir, None
    while True:
        if any(os.path.exists(os.path.join(d, f)) for f in ("tweak.py", "figure_labels.json")):
            top = d
            break
        if norm(d) == norm(root) or os.path.dirname(d) == d:
            break
        d = os.path.dirname(d)
    if top is None:
        first = os.path.relpath(keys_dir, root).split(os.sep)[0]
        top = root if first in (".", "") else os.path.join(root, first)
    return top


def paper_name(main):
    b = os.path.basename(main.rstrip("\\/"))
    return os.path.basename(os.path.dirname(main.rstrip("\\/"))) if b.lower() in GENERIC else b


def n_tweaks(keys_path, stem):
    t = load_json(os.path.join(os.path.dirname(keys_path), stem + ".tweaks.json"), {})
    return len(t) if isinstance(t, dict) else 0


def scan(folders):
    """Papers holding editable figures under folders, newest first; each with its versions, newest first."""
    _, names = registry()
    papers = {}
    for root, kp in walk_keys(folders):
        kd = os.path.dirname(kp)
        gi = git_info(kd)
        if gi is None:                                  # not in git: the figures package (tweak.py, labels) is the paper
            top = plain_top(kd, root)
            gi = (top, top, "")
        top, main, branch = gi
        p = papers.setdefault(norm(main), {"main": disp(main), "versions": {}})
        v = p["versions"].setdefault(norm(top), {"top": disp(top), "branch": branch, "roots": set()})
        v["roots"].add(disp(figure_root(kd, top)))
    out = []
    for key, p in papers.items():
        meta = names.get(key, {})
        vers = []
        for v in p["versions"].values():
            figs = []
            for fid, label, keys in ft.discover(sorted(v["roots"])):
                stem = ft.stem_of(keys)
                png = os.path.join(os.path.dirname(keys), stem + ".png")
                mt = max(os.path.getmtime(x) for x in (keys, png) if os.path.exists(x))
                figs.append(dict(id=hid(keys), fid=fid, stem=stem, label=label, keys=disp(keys), mtime=mt,
                                 edits=n_tweaks(keys, stem)))
            if figs:
                vers.append(dict(id=hid(v["top"]), top=v["top"], name=os.path.basename(v["top"]), branch=v["branch"],
                                 roots=sorted(v["roots"]), figs=figs, mtime=max(f["mtime"] for f in figs),
                                 main=norm(v["top"]) == key))
        if vers:
            vers.sort(key=lambda v: -v["mtime"])
            out.append(dict(id=hid(p["main"]), main=p["main"], name=meta.get("name") or paper_name(p["main"]),
                            subtitle=meta.get("subtitle", ""), versions=vers, mtime=vers[0]["mtime"]))
    out.sort(key=lambda p: -p["mtime"])
    return out


# ---- server state ------------------------------------------------------------------------------------------------
def index(st, papers):
    vermap, figmap = {}, {}
    for p in papers:
        for v in p["versions"]:
            vermap[v["id"]] = dict(v, paper=p["name"], paper_id=p["id"])
            for f in v["figs"]:
                figmap[f["id"]] = (f["fid"], f["keys"], v["id"])
    return vermap, figmap


def set_papers(st, papers, scan_time):
    vermap, figmap = index(st, papers)
    with st["hub"]:
        st["papers"], st["vermap"], st["figmap"], st["scan_time"] = papers, vermap, figmap, scan_time


def rescan(st):
    with st["hub"]:
        if st["scanning"]:
            return
        st["scanning"] = True
    try:
        papers = scan(registry()[0])
        set_papers(st, papers, time.time())
        save_json(CACHE, {"version": CACHE_VERSION, "time": st["scan_time"], "papers": papers})
    finally:
        st["scanning"] = False


def add_scanned(st, folder):
    """Scan just one folder (a paper passed on the command line) and merge it into the list; returns its versions."""
    found = scan([folder])
    with st["hub"]:
        papers = [p for p in st["papers"] if p["id"] not in {q["id"] for q in found}] + found
    set_papers(st, papers, st["scan_time"])
    return [v for p in found for v in p["versions"]]


def open_figure(st, vid, fig_id=None, want=None):
    v = st["vermap"].get(vid)
    if not v:
        return "这个版本已不存在，请刷新"
    roots = [r for r in v["roots"] if os.path.isdir(r)]
    figs = ft.discover(roots)
    if not figs:
        return "这个版本里没有可编辑的图了，请刷新"
    fid = figs[0][0]
    if fig_id in st["figmap"] and any(s == st["figmap"][fig_id][0] for s, _, _ in figs):
        fid = st["figmap"][fig_id][0]
    elif want:
        try:
            fid = ft.resolve(figs, want)
        except SystemExit:
            pass
    with st["lock"]:
        st["root"], st["figs"] = roots, figs
        st["fig"] = ft.Fig(fid, next(p for s, _, p in figs if s == fid))
        st["version"] = v
    cfg = load_json(CONFIG, {})
    cfg["last"] = dict(version=vid, top=v["top"], fig=fid, paper=v["paper"], branch=v["branch"], time=time.time())
    save_json(CONFIG, cfg)
    return ""


def open_path(st, folder, want=None):
    """Open the paper version holding folder (any folder inside a worktree); returns an error message or ''."""
    if not os.path.isdir(folder):
        return "文件夹不存在：" + folder
    gi = git_info(folder)
    vers = add_scanned(st, gi[0] if gi else folder)
    top = norm(gi[0]) if gi else norm(folder)
    hit = [v for v in vers if norm(v["top"]) == top] or vers
    return open_figure(st, hit[0]["id"], want=want) if hit else "这个文件夹里没有可编辑的图"


def dialog(kind, title, initial=None):
    """A native folder or file picker on top of the page; returns '' when cancelled."""
    import tkinter
    from tkinter import filedialog
    tk = tkinter.Tk()
    tk.withdraw()
    tk.attributes("-topmost", True)
    if kind == "folder":
        path = filedialog.askdirectory(title=title, mustexist=True, initialdir=initial or None)
    elif kind == "data":
        path = filedialog.askopenfilename(title=title, initialdir=initial or None,
                                          filetypes=[("表格（CSV、TSV、TXT）", "*.csv *.tsv *.txt"), ("所有文件", "*.*")])
    else:
        path = filedialog.askopenfilename(title=title, initialdir=initial or None,
                                          filetypes=[("python.exe", "python*.exe"), ("所有文件", "*.*")])
    tk.destroy()
    return path or ""


def ensure_root(folder):
    """Keep folder in the scan from now on unless a scanned folder already holds it."""
    if any(norm(folder).startswith(norm(r).rstrip("\\/") + os.sep) or norm(folder) == norm(r)
           for r in registry()[0]):
        return
    cfg = load_json(CONFIG, {})
    cfg.setdefault("extra_roots", []).append(disp(folder))
    save_json(CONFIG, cfg)


def start_onboard(st, folder, python):
    job = dict(folder=disp(folder), python=python, step="准备", done=0, total=0, log=[], finished=False,
               started=time.time())
    st["job"] = job

    def go():
        onboard.run(folder, python, job)
        if not job.get("error"):
            ensure_root(folder)
            cfg = load_json(CONFIG, {})
            cfg["python"] = python
            save_json(CONFIG, cfg)
            add_scanned(st, git_info(folder)[0] if git_info(folder) else folder)
    threading.Thread(target=go, daemon=True).start()
    return job


def thumb(keys_path, stem):
    """(path, content type) of a small PNG of the figure, made once per render and cached."""
    d = os.path.dirname(keys_path)
    png = os.path.join(d, stem + ".png")
    if not os.path.exists(png):
        svg = os.path.join(d, stem + ".svg")
        return (svg, "image/svg+xml") if os.path.exists(svg) else (None, None)
    out = os.path.join(THUMBS, hashlib.sha1((norm(png) + str(os.stat(png).st_mtime_ns)).encode()).hexdigest()[:16]
                       + ".png")
    if not os.path.exists(out):
        try:
            from PIL import Image
            Image.MAX_IMAGE_PIXELS = None
            os.makedirs(THUMBS, exist_ok=True)
            with Image.open(png) as im:
                im = im.convert("RGBA")
                im.thumbnail((720, 720))
                bg = Image.new("RGB", im.size, "white")
                bg.paste(im, mask=im.split()[-1])
                bg.save(out + ".tmp.png", optimize=True)
            os.replace(out + ".tmp.png", out)
        except Exception:
            return png, "image/png"
    return out, "image/png"


# ---- new figures from chart templates (chart_templates.py) ----------------------------------------------------------

def paper_python(v):
    """The interpreter that draws this paper's figures: the one its figures were last rendered with, else the one
    chosen at onboarding, else any found."""
    cands = onboard.interpreters(v["roots"][0] if v["roots"] else v["top"])
    py = load_json(CONFIG, {}).get("python")
    return cands[0] if cands else (py if py and os.path.exists(py) else "")


def template_job(st, req, preview):
    """Render a template with the user's table: into a scratch folder (preview, returns the PNG) or as a new figure
    of the paper (returns the figure's stem)."""
    v = st["vermap"].get(req.get("version"))
    if not v:
        raise ValueError("先在左侧选一篇论文")
    roots = [r for r in v["roots"] if os.path.isdir(r)] or [v["top"]]
    python = paper_python(v)
    if not python:
        raise ValueError("没有找到装有 matplotlib 的 Python：先用「接入新论文」接入这篇论文")
    tid, table = req["template"], dict(columns=req["table"]["columns"], rows=req["table"]["rows"])
    size = [float(req.get("width") or 89), float(req.get("height") or 62)]
    if not preview:
        stem = (req.get("stem") or "").strip()
        folder, log = ct.create(roots, tid, stem, table, req.get("values", {}), size[0], size[1],
                                req.get("title", ""), python)
        if not log.startswith("OK"):
            return dict(ok=False, error="出图失败，脚本已留在 " + folder + "，可以改好后再出图", log=log)
        if (req.get("label") or "").strip():           # the manuscript's number for the new figure
            lp = os.path.join(roots[0], "figure_labels.json")
            labels = load_json(lp, {})
            labels[stem] = req["label"].strip()
            with open(lp, "w", encoding="utf-8") as f:
                json.dump(labels, f, ensure_ascii=False, indent=1)
        add_scanned(st, v["top"])
        err = open_figure(st, v["id"], want=stem)
        return dict(ok=not err, error=err, folder=folder, log=log)
    import base64
    import shutil
    import tempfile
    home = st.setdefault("style_home", {}).get(v["id"], "?")
    if home == "?":
        home = st["style_home"][v["id"]] = ct.style_home(roots)
    d = tempfile.mkdtemp(prefix="ft_preview_")
    try:
        if not home:
            shutil.copy(os.path.join(HERE, "templates", "ft_style.py"), os.path.join(d, "style.py"))
            shutil.copy(os.path.join(HERE, "tweak.py"), os.path.join(d, "tweak.py"))
        ct.write_csv(table, os.path.join(d, "Preview_data.csv"))
        script = os.path.join(d, "make_preview.py")
        with open(script, "w", encoding="utf-8") as f:
            f.write(ct.make_script(tid, "Preview", "Preview_data.csv", home or ".", size[0], size[1],
                                   req.get("title", ""), req.get("values", {})))
        log = ct.render(script, python)
        png = os.path.join(d, "Preview.png")
        if not log.startswith("OK") or not os.path.exists(png):
            return dict(ok=False, log=log)
        return dict(ok=True, png=base64.b64encode(open(png, "rb").read()).decode(), log=log,
                    style="论文自己的 style.py" if home else "内置样式（这篇论文没有 Page）")
    finally:
        shutil.rmtree(d, ignore_errors=True)


def make_handler(st):
    Base = ft.make_handler(st)

    class H(Base):
        def page(self, name, inject=False):
            html = open(os.path.join(HERE, name), encoding="utf-8").read()
            if inject:
                html = html.replace("</body>", '<script src="/hub/inject.js"></script>\n</body>', 1)
            self.send(html, "text/html; charset=utf-8")

        def redirect(self, to):
            self.send_response(302)
            self.send_header("Location", to)
            self.send_header("Content-Length", "0")
            self.end_headers()

        def current(self):
            v = st.get("version")
            f = st.get("fig")
            if not v or not f:
                return None
            return dict(version=v["id"], paper=v["paper"], paper_id=v["paper_id"], branch=v["branch"],
                        name=v["name"], top=v["top"], fig=f.id)

        def do_GET(self):
            u = urlsplit(self.path)
            q = parse_qs(u.query)
            if u.path == "/":
                return self.page("figure_hub.html")
            if u.path == "/edit":
                return self.page("figure_tweak.html", inject=True) if st["fig"] else self.redirect("/")
            if u.path == "/hub/inject.js":
                return self.send(open(os.path.join(HERE, "figure_hub_inject.js"), encoding="utf-8").read(),
                                 "text/javascript; charset=utf-8")
            if u.path == "/hub/ping":
                return self.send(json.dumps({"app": "figure_hub", "pid": os.getpid()}))
            if u.path == "/hub/papers":
                if q.get("rescan"):
                    threading.Thread(target=rescan, args=(st,), daemon=True).start()
                    time.sleep(0.05)
                cfg = load_json(CONFIG, {})
                return self.send(json.dumps(dict(papers=st["papers"], scanning=st["scanning"],
                                                 scan_time=st["scan_time"], current=self.current(),
                                                 last=cfg.get("last"), roots=registry()[0], version=__version__),
                                            ensure_ascii=False))
            if u.path == "/hub/templates":
                cat = ct.catalog()
                for t in cat["templates"]:
                    t["defaults"] = ct.defaults(t["id"])
                return self.send(json.dumps(cat, ensure_ascii=False))
            if u.path == "/hub/template_thumb":
                p = os.path.join(HERE, "templates", "thumbs", os.path.basename((q.get("id") or [""])[0]) + ".png")
                if not os.path.exists(p):
                    return self.send("no image", "text/plain", 404)
                return self.send(open(p, "rb").read(), "image/png")
            if u.path == "/hub/template_sample":
                tid = os.path.basename((q.get("id") or [""])[0])
                return self.send(json.dumps(dict(ct.parse_table(ct.sample(tid)), name="示例数据（%s）" % tid),
                                            ensure_ascii=False))
            if u.path == "/hub/onboard/job":
                return self.send(json.dumps(st.get("job") or {}, ensure_ascii=False))
            if u.path == "/hub/thumb":
                hit = st["figmap"].get((q.get("id") or [""])[0])
                path, ctype = thumb(hit[1], ft.stem_of(hit[1])) if hit else (None, None)
                if not path:
                    return self.send("no image", "text/plain", 404)
                return self.send(open(path, "rb").read(), ctype)
            if st["fig"] is None:                         # editor calls before a paper is chosen
                return self.send(json.dumps({"error": "no paper open"}), code=409)
            return super().do_GET()

        def do_POST(self):
            u = urlsplit(self.path)
            if not u.path.startswith("/hub/"):
                if st["fig"] is None:
                    return self.send(json.dumps({"log": "ERROR\n还没有打开论文"}, ensure_ascii=False), code=409)
                return super().do_POST()
            n = int(self.headers.get("Content-Length", 0))
            try:
                req = json.loads(self.rfile.read(n).decode("utf-8") or "{}")
            except ValueError:
                req = {}
            if u.path == "/hub/beat":
                st["beat"] = time.time()
                return self.send("{}")
            if u.path == "/hub/bye":
                st["bye"] = time.time()
                return self.send("{}")
            if u.path == "/hub/open":
                err = open_figure(st, req.get("version"), req.get("fig"))
                return self.send(json.dumps({"ok": not err, "error": err}, ensure_ascii=False))
            if u.path == "/hub/open_path":
                err = open_path(st, req.get("paper", ""), req.get("figure"))
                return self.send(json.dumps({"ok": not err, "error": err}, ensure_ascii=False))
            if u.path == "/hub/reveal":
                v = st["vermap"].get(req.get("version"))
                target = v and (v["roots"][0] if v["roots"] else v["top"])
                if target and os.path.isdir(target):
                    os.startfile(target)
                return self.send("{}")
            if u.path == "/hub/onboard/analyze":
                path = req.get("path") or dialog("folder", "选择论文的图所在文件夹（含 style.py 和各图脚本）")
                if not path:
                    return self.send(json.dumps({"ok": False}))
                if not os.path.isdir(path):
                    return self.send(json.dumps({"ok": False, "error": "文件夹不存在：" + path}, ensure_ascii=False))
                plan = onboard.analyze(path, load_json(CONFIG, {}).get("python"))
                return self.send(json.dumps(dict(plan, ok=True), ensure_ascii=False))
            if u.path == "/hub/onboard/start":
                job = st.get("job")
                if job and not job.get("finished"):
                    return self.send(json.dumps({"ok": False, "error": "已有一个接入任务在运行"}, ensure_ascii=False))
                start_onboard(st, req["path"], req.get("python", ""))
                return self.send(json.dumps({"ok": True}))
            if u.path == "/hub/table":                # a data table: picked, a path, or pasted text
                try:
                    path = req.get("path") or (dialog("data", "选择数据表（CSV / TSV，第一行是列名）") if req.get("pick")
                                               else "")
                    if req.get("pick") and not path:
                        return self.send(json.dumps({"ok": False}))
                    text = ct.read_data_file(path) if path else req.get("text", "")
                    t = ct.parse_table(text)
                except (OSError, ValueError) as e:
                    return self.send(json.dumps({"ok": False, "error": str(e)}, ensure_ascii=False))
                return self.send(json.dumps(dict(t, ok=True, name=os.path.basename(path) if path else "粘贴的表格"),
                                            ensure_ascii=False))
            if u.path in ("/hub/template_preview", "/hub/template_create"):
                try:
                    out = template_job(st, req, u.path.endswith("preview"))
                except (OSError, ValueError, KeyError, subprocess.SubprocessError) as e:
                    out = {"ok": False, "error": str(e)}
                return self.send(json.dumps(out, ensure_ascii=False))
            if u.path == "/hub/pick_python":
                path = dialog("file", "选择装有 matplotlib 的 python.exe")
                return self.send(json.dumps({"path": path.replace("/", "\\")}, ensure_ascii=False))
            if u.path == "/hub/rename":
                cfg = load_json(CONFIG, {})
                cfg.setdefault("names", {})[req["main"]] = {"name": req.get("name", "").strip(),
                                                           "subtitle": req.get("subtitle", "").strip()}
                save_json(CONFIG, cfg)
                for p in st["papers"]:
                    if p["main"] == req["main"]:
                        p["name"] = req.get("name", "").strip() or paper_name(p["main"])
                        p["subtitle"] = req.get("subtitle", "").strip()
                set_papers(st, st["papers"], st["scan_time"])
                return self.send("{}")
            if u.path == "/hub/add_folder":
                path = req.get("path") or dialog("folder", "选择要加入扫描的文件夹（论文仓库或其上级）")
                if not path:
                    return self.send(json.dumps({"ok": False}))
                if not os.path.isdir(path):
                    return self.send(json.dumps({"ok": False, "error": "文件夹不存在：" + path}, ensure_ascii=False))
                cfg = load_json(CONFIG, {})
                roots = cfg.setdefault("extra_roots", [])
                if disp(path) not in roots and disp(path) not in registry()[0]:
                    roots.append(disp(path))
                    save_json(CONFIG, cfg)
                threading.Thread(target=rescan, args=(st,), daemon=True).start()
                return self.send(json.dumps({"ok": True, "path": disp(path)}, ensure_ascii=False))
            if u.path == "/hub/quit":
                self.send("{}")
                threading.Thread(target=st["server"].shutdown, daemon=True).start()
                return
            return self.send("not found", "text/plain", 404)
    return H


def watchdog(st):
    """Stop once the last window has said goodbye and not come back, or after ten minutes without any window."""
    tick = time.time()
    while True:
        time.sleep(5)
        now = time.time()
        if now - tick > 60:                             # the machine slept: give open windows time to beat again
            st["beat"], st["bye"] = now, None
        tick = now
        busy = st.get("job") and not st["job"].get("finished")
        if not busy and ((st["bye"] and st["beat"] < st["bye"] and now - st["bye"] > 60) or now - st["beat"] > 600):
            st["server"].shutdown()
            return


def open_window(url):
    pref = load_json(CONFIG, {}).get("browser")
    for exe in ([pref] if pref else []) + BROWSERS:
        if exe and os.path.exists(exe):
            subprocess.Popen([exe, "--app=" + url, "--window-size=1680,1020", "--new-window"],
                             creationflags=getattr(subprocess, "DETACHED_PROCESS", 0))
            return
    webbrowser.open(url)


def call(url, body=None, timeout=1.5):
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = Request(url, data=data, headers={"Content-Type": "application/json"})
    with urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


def main():
    ap = argparse.ArgumentParser(prog="FigureTweak")
    ap.add_argument("folder", nargs="?", help="a paper's folder (dropped on the exe): open it, or offer to onboard it")
    ap.add_argument("--paper", help="folder of a paper (repository, worktree or its figures folder) to open directly")
    ap.add_argument("--figure", help="stem or label of the figure to open with --paper")
    ap.add_argument("--port", type=int, default=8766)
    ap.add_argument("--no-window", action="store_true")
    ap.add_argument("--version", action="version", version=__version__)
    a = ap.parse_args()
    a.paper = a.paper or a.folder
    base = "http://127.0.0.1:%d" % a.port
    onboard_url = lambda: "/?onboard=" + quote(os.path.abspath(a.paper))  # noqa: E731

    try:                                                   # already running: hand over and just open a window
        if call(base + "/hub/ping").get("app") == "figure_hub":
            path = "/"
            if a.paper:
                r = call(base + "/hub/open_path", {"paper": os.path.abspath(a.paper), "figure": a.figure}, timeout=60)
                path = "/edit" if r.get("ok") else onboard_url() if os.path.isdir(a.paper) else "/"
            if not a.no_window:
                open_window(base + path)
            return
    except OSError:
        pass

    st = {"root": [], "figs": [], "fig": None, "version": None, "lock": threading.Lock(), "hub": threading.Lock(),
          "papers": [], "vermap": {}, "figmap": {}, "scan_time": 0, "scanning": False,
          "beat": time.time(), "bye": None}
    cache = load_json(CACHE, {})
    if cache.get("version") == CACHE_VERSION:          # a cache written by an older figure_hub is rebuilt by the scan
        set_papers(st, cache.get("papers", []), cache.get("time", 0))
    path = "/"
    if a.paper:
        path = "/edit" if not open_path(st, a.paper, a.figure) else onboard_url() if os.path.isdir(a.paper) else "/"
    srv = ThreadingHTTPServer(("127.0.0.1", a.port), make_handler(st))
    st["server"] = srv
    threading.Thread(target=rescan, args=(st,), daemon=True).start()
    threading.Thread(target=watchdog, args=(st,), daemon=True).start()
    print("figure hub at %s%s  -- Ctrl+C to stop" % (base, path))
    if not a.no_window:
        open_window(base + path)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
