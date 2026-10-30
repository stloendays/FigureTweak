"""New figures from chart templates: pick a chart type, point it at a table, get an ordinary figure script.

A template (templates/<id>.tpl) is a settings block and the drawing code of one chart type; templates/common.tpl
holds what every chart shares (reading the table, the paper's style, the save that keeps the figure editable).
`make_script` puts the three together into make_<stem>.py, which reads <stem>_data.csv and draws on the paper's own
`Page` from its style.py. The script is the figure's source from then on: it can be edited like any other, and
the figure opens in the editor like any other.

This module needs no matplotlib (the hub runs without it); drawing happens in the paper's Python.
"""
import ast
import csv
import datetime
import io
import json
import os
import re
import shutil
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
TPL = os.path.join(HERE, "templates")
NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
STEM_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_]{0,40}$")


def catalog():
    return json.load(open(os.path.join(TPL, "catalog.json"), encoding="utf-8"))


def template(tid):
    t = next((t for t in catalog()["templates"] if t["id"] == tid), None)
    if t is None:
        raise ValueError("没有这个模板：%s" % tid)
    return t


def _sections(tid):
    src = open(os.path.join(TPL, tid + ".tpl"), encoding="utf-8").read()
    head, draw = src.split("# ---- draw ----\n", 1)
    return head.split("# ---- settings ----\n", 1)[1], draw


def defaults(tid):
    """The template's own settings, {name: value}, in file order."""
    out = {}
    for node in ast.parse(_sections(tid)[0]).body:
        if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name):
            out[node.targets[0].id] = ast.literal_eval(node.value)
    return out


def _settings_block(tid, values):
    """The settings section with the given values written in, comments kept."""
    lines = []
    for line in _sections(tid)[0].splitlines():
        m = re.match(r"^([A-Z_][A-Z0-9_]*) = (.*?)(\s+#.*)?$", line)
        if m and m.group(1) in values:
            first = "%s = %r" % (m.group(1), values[m.group(1)])
            line = first + (" " * max(1, 26 - len(first)) + m.group(3).strip() if m.group(3) else "")
        lines.append(line)
    return "\n".join(lines)


def make_script(tid, stem, data_name, style_dir, width_mm, height_mm, title, values):
    t = template(tid)
    common = open(os.path.join(TPL, "common.tpl"), encoding="utf-8").read()
    head = ('"""%s: %s\n\nMade from the FigureTweak chart template "%s" on %s. Edit the settings, or the drawing code '
            'below;\nthe figure stays editable in FigureTweak (hand edits live in %s.tweaks.json, the data in %s).\n"""\n'
            % (stem, t["name"], tid, datetime.date.today().isoformat(), stem, data_name))
    fig = ("# ---- figure ----\nSTEM = %r\nDATA = %r                 # the table this figure draws\n"
           "STYLE_DIR = %r              # folder holding style.py (the paper's Page) and tweak.py\n"
           "WIDTH_MM, HEIGHT_MM = %s, %s\nTITLE = %r\n"
           % (stem, data_name, style_dir, _num(width_mm), _num(height_mm), title))
    return (head + fig + "# ---- chart settings ----\n" + _settings_block(tid, values) + "\n# ---- shared ----\n"
            + common + "\n# ---- draw ----\n" + _sections(tid)[1])


def _assigns(code):
    out = {}
    for node in ast.parse(code).body:
        if not isinstance(node, ast.Assign):
            continue
        t, v = node.targets[0], ast.literal_eval(node.value)
        if isinstance(t, ast.Name):
            out[t.id] = v
        elif isinstance(t, ast.Tuple):
            out.update({e.id: x for e, x in zip(t.elts, v)})
    return out


def script_info(script):
    """What a script made from a template holds: {template, figure: {STEM, DATA, ...}, values}; None for others."""
    try:
        src = open(script, encoding="utf-8").read()
    except OSError:
        return None
    m = re.search(r'chart template "([a-z0-9_]+)"', src)
    if not m or "# ---- chart settings ----\n" not in src or "# ---- shared ----\n" not in src:
        return None
    fig = src.split("# ---- figure ----\n", 1)[1].split("# ---- chart settings ----\n", 1)[0]
    sets = src.split("# ---- chart settings ----\n", 1)[1].split("# ---- shared ----\n", 1)[0]
    return dict(template=m.group(1), figure=_assigns(fig), values=_assigns(sets))


def update_script(script, tid, values, figure=None):
    """Write new chart settings into a template script, keeping its drawing code; with another template, rebuild the
    script from that template around the same figure block (STEM, DATA, STYLE_DIR stay)."""
    info = script_info(script)
    fg = dict(info["figure"], **{k: v for k, v in (figure or {}).items() if k in ("WIDTH_MM", "HEIGHT_MM", "TITLE")})
    vals = dict(defaults(tid), **{k: v for k, v in values.items() if k in defaults(tid)})
    if tid != info["template"]:
        src = make_script(tid, fg["STEM"], fg["DATA"], fg["STYLE_DIR"], fg["WIDTH_MM"], fg["HEIGHT_MM"],
                          fg.get("TITLE", ""), vals)
    else:
        src = open(script, encoding="utf-8").read()
        head, rest = src.split("# ---- chart settings ----\n", 1)
        rest = rest.split("# ---- shared ----\n", 1)[1]
        head = re.sub(r"(?m)^WIDTH_MM, HEIGHT_MM = .*$", "WIDTH_MM, HEIGHT_MM = %s, %s"
                      % (_num(fg["WIDTH_MM"]), _num(fg["HEIGHT_MM"])), head)
        head = re.sub(r"(?m)^TITLE = .*$", lambda m: "TITLE = %r" % fg.get("TITLE", ""), head)
        src = head + "# ---- chart settings ----\n" + _settings_block(tid, vals) + "\n# ---- shared ----\n" + rest
    open(script, "w", encoding="utf-8").write(src)


def data_path(script):
    info = script_info(script)
    return os.path.join(os.path.dirname(script), info["figure"]["DATA"]) if info else None


DATA_EXT = (".csv", ".tsv", ".txt", ".xlsx", ".xls", ".json", ".dat")


def data_files(script):
    """Data files a figure script names in quotes and that exist (relative to the script or its folder's parent)."""
    try:
        src = open(script, encoding="utf-8").read()
    except OSError:
        return []
    out, here = [], os.path.dirname(script)
    for name in dict.fromkeys(re.findall(r"""["']([^"'\n]+?\.(?:csv|tsv|txt|xlsx|xls|json|dat))["']""", src, re.I)):
        for base in (here, os.path.dirname(here)):
            p = os.path.normpath(os.path.join(base, name))
            if os.path.isfile(p) and not p.endswith((".tweaks.json", ".tweak_keys.json")):
                out.append(p)
                break
    return out


def _num(v):
    v = float(v)
    return repr(int(v)) if v == int(v) else repr(v)


# ---- tables --------------------------------------------------------------------------------------------------------

def parse_table(text):
    """A pasted or loaded table: comma, tab or semicolon separated, first row = column names."""
    text = text.replace("\r\n", "\n").replace("\r", "\n").lstrip("﻿")
    first = next((l for l in text.split("\n") if l.strip()), "")
    delim = max(",\t;", key=first.count) if first else ","
    rows = [r for r in csv.reader(io.StringIO(text), delimiter=delim) if any(c.strip() for c in r)]
    if len(rows) < 2:
        raise ValueError("表格至少要有一行列名和一行数据")
    head = [h.strip() or "col%d" % (i + 1) for i, h in enumerate(rows[0])]
    if len(set(head)) != len(head):
        raise ValueError("列名有重复：" + ", ".join(h for h in head if head.count(h) > 1))
    body = [[(r[i].strip() if i < len(r) else "") for i in range(len(head))] for r in rows[1:]]
    numeric = []
    for i in range(len(head)):
        vals = [r[i] for r in body if r[i] != ""]
        ok = 0
        for v in vals:
            try:
                float(v.replace(",", "").replace("−", "-"))
                ok += 1
            except ValueError:
                pass
        numeric.append(bool(vals) and ok == len(vals))
    return dict(columns=head, rows=body, numeric=numeric)


def read_data_file(path):
    """A .csv/.tsv/.txt table as text (UTF-8, or GBK as Excel on a Chinese Windows writes it)."""
    raw = open(path, "rb").read()
    for enc in ("utf-8-sig", "gbk", "latin-1"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("utf-8", "replace")


def write_csv(table, path):
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(table["columns"])
        w.writerows(table["rows"])


def sample(tid):
    return open(os.path.join(TPL, "samples", tid + ".csv"), encoding="utf-8").read()


# ---- where a new figure goes ---------------------------------------------------------------------------------------

def style_home(roots):
    """The folder holding the paper's hooked style.py (the one with the most figure folders beside it), or None."""
    import onboard
    best = None
    for r in roots:
        for path, state in onboard.page_modules(r):
            if state != "hooked":
                continue
            d = os.path.dirname(path)
            n = sum(1 for x in os.listdir(d) if os.path.isdir(os.path.join(d, x)))
            if best is None or n > best[1]:
                best = (d, n)
    return best[0] if best else None


def create(roots, tid, stem, table, values, width_mm, height_mm, title, python):
    """Write make_<stem>.py and <stem>_data.csv in a new folder of the paper and render it; returns (folder, log)."""
    if not STEM_RE.match(stem or ""):
        raise ValueError("图名只能用英文字母、数字和下划线，并以字母开头（例如 FigS7、Fig_cost）")
    home = style_home(roots)
    base = home or roots[0]
    folder = os.path.join(base, stem.lower())
    if os.path.exists(folder):
        raise ValueError("已有同名文件夹：%s，换一个图名" % folder)
    os.makedirs(folder)
    if home:
        style_dir = ".."
    else:                                              # a paper without a Page: bring the house style along
        shutil.copy(os.path.join(TPL, "ft_style.py"), os.path.join(folder, "style.py"))
        shutil.copy(os.path.join(HERE, "tweak.py"), os.path.join(folder, "tweak.py"))
        style_dir = "."
    data_name = stem + "_data.csv"
    write_csv(table, os.path.join(folder, data_name))
    script = os.path.join(folder, "make_%s.py" % stem.lower())
    open(script, "w", encoding="utf-8").write(
        make_script(tid, stem, data_name, style_dir, width_mm, height_mm, title, values))
    return folder, render(script, python)


def render(script, python):
    r = subprocess.run([python, os.path.basename(script)], cwd=os.path.dirname(script), capture_output=True,
                       text=True, encoding="utf-8", errors="replace", creationflags=NO_WINDOW, timeout=600)
    out = (r.stdout + r.stderr).strip().splitlines()
    return ("OK" if r.returncode == 0 else "ERROR %d" % r.returncode) + "\n" + "\n".join(out[-15:])
