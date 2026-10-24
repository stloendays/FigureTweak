"""Make a paper's figures editable in one step: hook tweak.apply into its Page.save, render every figure, and prove the
figures did not change.

The figure scripts the editor understands draw on a `Page` (a matplotlib figure laid out in millimetres) and finish
with `pg.save(HERE, stem)`. Onboarding a folder:

1. finds each module that defines `class Page` with a `save(self, here, stem...)` method and inserts the two lines
   that call `tweak.apply` (plus `rerun_args=None`); a literal white facecolor becomes the figure's own, so a
   background set in the editor holds;
2. puts `tweak.py` next to each of those modules;
3. reruns every script that saves through such a Page, with the interpreter the user picked, and compares each PNG
   that existed before with the new one, pixel by pixel;
4. writes `figure_labels.json` (Fig1 -> "Fig. 1", FigS2 -> "Supplementary Fig. 2", EDFig3 -> "Extended Data Fig. 3")
   unless the paper already has one.

Scripts that call `savefig` directly, and a Page whose save method has another shape, are listed for a hand edit.
"""
import glob
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
SKIP_DIRS = {".git", "node_modules", ".venv", "venv", "env", "__pycache__", "site-packages", ".ipynb_checkpoints",
             "build", "dist", ".cache"}
SAVE_RE = re.compile(r"^(?P<ind>[ \t]+)def save\(self,\s*(?P<here>\w+),\s*(?P<stem>\w+)(?P<rest>[^)]*)\)\s*:[^\n]*\n",
                     re.M)
HOOK = ("{ind}import tweak                            # hand adjustments from <stem>.tweaks.json (figure editor)\n"
        "{ind}tweak.apply(self.fig, {here}, {stem}, rerun_args)\n")
NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)


def py_files(folder):
    for d, ds, fs in os.walk(folder):
        ds[:] = [x for x in ds if x not in SKIP_DIRS and not x.startswith(".") and not x.endswith("_env")]
        for f in fs:
            if f.endswith(".py"):
                yield os.path.join(d, f)


def read(p):
    with open(p, encoding="utf-8", errors="replace") as f:
        return f.read()


def page_modules(folder):
    """[(path, state)] of modules defining class Page with a save method: state 'hooked', 'plain' or 'other'."""
    out = []
    for p in py_files(folder):
        s = read(p)
        if not re.search(r"^class Page\b", s, re.M):
            continue
        body = s[re.search(r"^class Page\b", s, re.M).start():]
        if "tweak.apply" in body:
            out.append((p, "hooked"))
        elif SAVE_RE.search(body):
            out.append((p, "plain"))
        else:
            out.append((p, "other"))
    return out


def uses_page(src, mods):
    for m in mods:
        if re.search(r"\b%s\.Page\(" % m, src):
            return True
        for imp in re.finditer(r"^from\s+%s\s+import\s+(\([^)]*\)|[^\n]*)" % m, src, re.M):
            if re.search(r"\bPage\b", imp.group(1)):
                return True
    return False


def scripts(folder, mods):
    """Figure scripts: they build a Page from one of the page modules and save it; others that call savefig."""
    names = {os.path.splitext(os.path.basename(p))[0] for p, _ in mods}
    files = {p: read(p) for p in py_files(folder) if not any(os.path.samefile(p, m) for m, _ in mods)}
    grew = True
    while grew:                                       # modules that re-export Page (from style import Page / *)
        grew = False
        for p, s in files.items():
            n = os.path.splitext(os.path.basename(p))[0]
            if n not in names and ".save(" not in s and (uses_page(s, names) or any(
                    re.search(r"^from\s+%s\s+import\s+\*" % m, s, re.M) for m in names)):
                names.add(n)
                grew = True
    paged, plain = [], []
    for p, s in files.items():
        if uses_page(s, names) and ".save(" in s:
            paged.append(p)
        elif "savefig(" in s and "tweak.apply" not in s:
            plain.append(p)
    return sorted(paged), sorted(plain)


def interpreters(folder, extra=None):
    """Python interpreters worth offering, best first: the one already recorded by an editable figure in this
    folder, the project's own virtual environment, then whatever is on PATH."""
    found = []
    for kp in glob.glob(os.path.join(folder, "**", "*.tweak_keys.json"), recursive=True)[:20]:
        try:
            py = json.load(open(kp, encoding="utf-8")).get("meta", {}).get("python")
        except (OSError, ValueError):
            py = None
        if py:
            found.append(py)
    d = os.path.abspath(folder)
    for _ in range(4):
        for v in (".venv", "venv", "env"):
            found.append(os.path.join(d, v, "Scripts", "python.exe"))
        d = os.path.dirname(d)
    for exe in ("python.exe", "python3.exe"):
        w = shutil.which(exe)
        if w and "WindowsApps" not in w:
            found.append(w)
    found += extra or []
    if not getattr(sys, "frozen", False):
        found.append(sys.executable.replace("pythonw.exe", "python.exe"))
    out = []
    for p in found:
        if p and os.path.exists(p) and os.path.normcase(p) not in {os.path.normcase(x) for x in out}:
            out.append(p)
    return out


def guess_label(stem):
    m = re.match(r"(?i)^(?:ed|extendeddata)fig_?(\d+)", stem)
    if m:
        return "Extended Data Fig. %s" % m.group(1)
    m = re.match(r"(?i)^(?:fig|figure)_?s_?(\d+)", stem)
    if m:
        return "Supplementary Fig. %s" % m.group(1)
    m = re.match(r"(?i)^(?:fig|figure)_?(\d+)", stem)
    if m:
        return "Fig. %s" % m.group(1)
    return stem


def label_key(stem):
    m = re.match(r"(?i)^(ed|extendeddata)?(fig|figure)_?(s)?_?(\d+)", stem)
    if not m:
        return (9, 0, stem)
    group = 2 if m.group(1) else 1 if m.group(3) else 0
    return (group, int(m.group(4)), stem)


def analyze(folder, python=None):
    folder = os.path.abspath(folder)
    mods = page_modules(folder)
    paged, plain = scripts(folder, mods)
    fonts = []
    for p, _ in mods:
        m = re.search(r"""["']svg\.fonttype["']\s*:\s*["'](\w+)["']""", read(p))
        if not m or m.group(1) != "none":
            fonts.append(p)
    pys = interpreters(folder, [python] if python else None)
    return dict(folder=folder.replace("\\", "/"),
                modules=[dict(path=p.replace("\\", "/"), state=s) for p, s in mods],
                scripts=[p.replace("\\", "/") for p in paged], manual=[p.replace("\\", "/") for p in plain],
                text_as_paths=[p.replace("\\", "/") for p in fonts], pythons=pys, python=python or (pys[0] if pys else ""),
                labels=os.path.exists(os.path.join(folder, "figure_labels.json")))


def in_git(path):
    d = os.path.dirname(os.path.abspath(path))
    while True:
        if os.path.exists(os.path.join(d, ".git")):
            return True
        up = os.path.dirname(d)
        if up == d:
            return False
        d = up


def hook_module(path):
    """Insert the tweak.apply call into Page.save; returns a message."""
    s = read(path)
    start = re.search(r"^class Page\b", s, re.M).start()
    m = SAVE_RE.search(s, start)
    if not m:
        return "跳过（save 方法的写法不认识，需要手动接入）"
    rest = m.group("rest")
    if "rerun_args" not in rest:
        rest += ", rerun_args=None"
    head = "%sdef save(self, %s, %s%s):\n" % (m.group("ind"), m.group("here"), m.group("stem"), rest)
    ind = m.group("ind")
    body_start = m.end()
    nxt = re.compile(r"^%s(?:def |@|class )|^\S" % re.escape(ind), re.M).search(s, body_start)
    body = s[body_start:nxt.start() if nxt else len(s)]
    doc = re.match(r'(\s*(?:"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\')[^\n]*\n)', body)
    pre, body = (doc.group(1), body[doc.end():]) if doc else ("", body)
    body = re.sub(r"""facecolor\s*=\s*["'](?:white|w|#fff|#ffffff)["']""", "facecolor=self.fig.get_facecolor()", body)
    first = re.search(r"^([ \t]+)\S", body, re.M)
    new = s[:m.start()] + head + pre + HOOK.format(ind=first.group(1) if first else ind * 2, here=m.group("here"), stem=m.group("stem")) + body + \
        (s[nxt.start():] if nxt else "")
    if not in_git(path):
        shutil.copy2(path, path + ".bak-" + time.strftime("%Y%m%d-%H%M%S"))
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(new)
    return "已接入"


def png_digest(p):
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    with Image.open(p) as im:
        im = im.convert("RGBA")
        return im.size, hashlib.sha1(im.tobytes()).hexdigest()


def snapshot(d):
    out = {}
    for p in glob.glob(os.path.join(d, "*.png")):
        try:
            out[p] = png_digest(p)
        except Exception:
            pass
    return out


def render(script, python, timeout=900):
    d = os.path.dirname(script)
    before = snapshot(d)
    t = time.time()
    try:
        r = subprocess.run([python, os.path.basename(script)], cwd=d, capture_output=True, text=True,
                           encoding="utf-8", errors="replace", timeout=timeout, creationflags=NO_WINDOW,
                           env=dict(os.environ, PYTHONIOENCODING="utf-8", MPLBACKEND="Agg"))
        ok, tail = r.returncode == 0, (r.stdout + r.stderr).strip().splitlines()[-6:]
    except subprocess.TimeoutExpired:
        ok, tail = False, ["超过 %d 秒没有结束" % timeout]
    after = snapshot(d)
    changed = [os.path.basename(p) for p in before if p in after and after[p] != before[p]]
    same = [os.path.basename(p) for p in before if p in after and after[p] == before[p]]
    keys = [p.replace("\\", "/") for p in glob.glob(os.path.join(d, "*.tweak_keys.json"))
            if os.path.getmtime(p) >= t - 1]
    return dict(script=script.replace("\\", "/"), ok=ok, seconds=round(time.time() - t, 1), log=tail,
                changed=changed, same=same, keys=keys)


def write_labels(folder):
    path = os.path.join(folder, "figure_labels.json")
    if os.path.exists(path):
        return None
    stems = sorted({os.path.basename(p)[:-len(".tweak_keys.json")]
                    for p in glob.glob(os.path.join(folder, "**", "*.tweak_keys.json"), recursive=True)
                    if not any(s in p for s in (os.sep + ".git" + os.sep,))}, key=label_key)
    if not stems:
        return None
    with open(path, "w", encoding="utf-8") as f:
        json.dump({s: guess_label(s) for s in stems}, f, ensure_ascii=False, indent=1)
    return path.replace("\\", "/")


def run(folder, python, job):
    """Onboard folder; job is a dict the caller polls: step, done, total, log, result."""
    def log(s):
        job["log"].append(s)
    try:
        plan = analyze(folder, python)
        if not python or not os.path.exists(python):
            raise RuntimeError("没有找到可用的 Python 解释器（需要装有 matplotlib 的那个）")
        job["step"] = "接入 Page.save"
        mods = []
        for m in plan["modules"]:
            p = m["path"]
            msg = "已接入（之前就有）" if m["state"] == "hooked" else hook_module(p) if m["state"] == "plain" \
                else "跳过（save 方法的写法不认识，需要手动接入）"
            dst = os.path.join(os.path.dirname(p), "tweak.py")
            src = os.path.join(HERE, "tweak.py")
            if "跳过" not in msg and (not os.path.exists(dst) or read(dst).find("def apply(fig, here, stem, rerun_args") < 0):
                shutil.copy2(src, dst)
                msg += "，已放入 tweak.py"
            mods.append(dict(path=p, msg=msg))
            log("%s: %s" % (p, msg))
        job["step"] = "重新出图"
        job["total"] = len(plan["scripts"])
        results = []

        def one(s):
            r = render(s, python)
            job["done"] += 1
            log("%s %s  %.0fs%s" % ("OK " if r["ok"] else "失败", s, r["seconds"],
                                     ("  图有变化: " + ", ".join(r["changed"])) if r["changed"] else ""))
            return r
        with ThreadPoolExecutor(max_workers=3) as ex:
            results = list(ex.map(one, plan["scripts"]))
        job["step"] = "写图号"
        labels = write_labels(folder)
        if labels:
            log("已生成 " + labels + "（可在里面改成论文里的图号）")
        job["result"] = dict(plan=plan, modules=mods, renders=results, labels=labels,
                             n_ok=sum(r["ok"] for r in results), n_changed=sum(bool(r["changed"]) for r in results),
                             n_keys=len({k for r in results for k in r["keys"]}))
    except Exception as e:  # noqa: BLE001  shown in the page
        job["error"] = str(e)
        log("出错: %s" % e)
    finally:
        job["step"] = "完成"
        job["finished"] = True


if __name__ == "__main__":
    print(json.dumps(analyze(sys.argv[1]), ensure_ascii=False, indent=1))
