import csv
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
INSET = "FIG" in globals()                         # inserted into another figure by the editor (FIG, BOX given)
if INSET:
    S = sys.modules.get("style") or type("NoStyle", (), {})   # that figure's style module, already loaded
    OX, OY, WIDTH_MM, HEIGHT_MM = BOX              # the box this chart fills, mm from the figure's bottom-left
    PAGE_W, PAGE_H = (float(v) * 25.4 for v in FIG.get_size_inches())
else:
    sys.path.insert(0, os.path.normpath(os.path.join(HERE, STYLE_DIR)))
    import style as S  # noqa: E402  the paper's house style: Page and its colours
    from style import Page  # noqa: E402
    OX = OY = 0.0
    PAGE_W, PAGE_H = WIDTH_MM, HEIGHT_MM
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.font_manager import FontProperties  # noqa: E402

INK = getattr(S, "INK", "#1b1b1b")
MUTED = getattr(S, "MID", "#5f646c")
HIGHLIGHT = getattr(S, "RED", "#d9474f")
PALETTE = [c for c in (getattr(S, n, None) for n in ("RU", "FE", "AMB", "OS", "DARK_B", "DARK_G", "AMB_D", "OTHER",
                                                      "BLUE", "GREEN", "ORANGE"))
           if isinstance(c, str) and c.startswith("#")]
PALETTE = list(dict.fromkeys(PALETTE)) or ["#5677b5", "#6e9f60", "#e0913a", "#97abd4", "#304c86", "#467238"]


def read_table(path):
    """The data file as {column: [text, ...]}; comma, tab or semicolon separated, first row = column names."""
    with open(os.path.join(HERE, path), encoding="utf-8-sig", newline="") as f:
        text = f.read()
    delim = max(",\t;", key=lambda d: text.split("\n", 1)[0].count(d))
    rows = [r for r in csv.reader(text.splitlines(), delimiter=delim) if any(c.strip() for c in r)]
    head = [h.strip() for h in rows[0]]
    return {h: [r[i].strip() if i < len(r) else "" for r in rows[1:]] for i, h in enumerate(head)}


def numbers(values):
    """Text cells as floats; empty or non-numeric cells become NaN."""
    out = []
    for v in values:
        try:
            out.append(float(str(v).replace(",", "").replace("−", "-")))
        except ValueError:
            out.append(math.nan)
    return np.array(out, dtype=float)


def unique(values):
    return list(dict.fromkeys(v for v in values if v != ""))


def column(name, kind="text"):
    """A column of the data, or None when the setting is left empty."""
    if not name:
        return None
    if name not in T:
        raise SystemExit("column %r is not in %s (columns: %s)" % (name, DATA, ", ".join(T)))
    return numbers(T[name]) if kind == "number" else T[name]


def box_ax(left, bottom, w, h, **kw):
    """An axes at (left, bottom, w, h) mm inside the chart's box."""
    return pg.fig.add_axes([(OX + left) / PAGE_W, (OY + bottom) / PAGE_H, w / PAGE_W, h / PAGE_H], **kw)


def chart(left=14.0, bottom=11.0, right=3.0, top=None):
    """The main axes, in mm from the box's edges, leaving room for the title."""
    top = (7.0 if TITLE else 3.0) if top is None else top
    return box_ax(left, bottom, WIDTH_MM - left - right, HEIGHT_MM - bottom - top)


def polar_chart(left=6.0, bottom=6.0, right=6.0, top=None):
    """A polar axes (radar, rose), in mm from the box's edges."""
    top = (10.0 if TITLE else 6.0) if top is None else top
    return box_ax(left, bottom, WIDTH_MM - left - right, HEIGHT_MM - bottom - top, projection="polar")


def numeric_columns(names=""):
    """The columns in a comma-separated list, or every column that holds only numbers."""
    if names.strip():
        cols = [c.strip() for c in names.split(",") if c.strip()]
        for c in cols:
            column(c)
        return cols
    return [c for c in T if T[c] and not np.isnan(numbers(T[c])).any()]


def kde(d, grid, bw=0.0):
    """Gaussian kernel density of the values d on grid (Scott's bandwidth unless bw > 0)."""
    d = d[~np.isnan(d)]
    h = bw or (1.06 * np.std(d, ddof=1) * len(d) ** -0.2 if len(d) > 1 else 0) or 1.0
    z = (grid[:, None] - d[None, :]) / h
    return np.exp(-0.5 * z * z).sum(1) / (len(d) * h * np.sqrt(2 * np.pi))


def finish(ax):
    if TITLE:
        pg.fig.text((OX + 1.0) / PAGE_W, (OY + HEIGHT_MM - 1.0) / PAGE_H, TITLE, fontweight="bold", va="top", ha="left")
    if not INSET:
        pg.save(HERE, STEM)


class _Inset:
    fig = FIG if INSET else None


T = read_table(DATA)
pg = _Inset() if INSET else Page(WIDTH_MM, HEIGHT_MM)
_fam = plt.rcParams["font.family"]                # set after Page, which applies the paper's fonts: Chinese text
if "Microsoft YaHei" not in _fam:
    plt.rcParams["font.family"] = list(_fam if isinstance(_fam, list) else [_fam]) + ["Microsoft YaHei", "SimHei"]
SMALL = FontProperties(size=plt.rcParams["xtick.labelsize"]).get_size_in_points()   # annotations: tick-label size
