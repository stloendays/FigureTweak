import csv
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.normpath(os.path.join(HERE, STYLE_DIR)))
import style as S  # noqa: E402  the paper's house style: Page and its colours
from style import Page  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

INK = getattr(S, "INK", "#1b1b1b")
MUTED = getattr(S, "MID", "#5f646c")
HIGHLIGHT = getattr(S, "RED", "#d9474f")
PALETTE = [c for c in (getattr(S, n, None) for n in ("RU", "FE", "AMB", "OS", "DARK_B", "DARK_G", "AMB_D", "OTHER",
                                                      "BLUE", "GREEN", "ORANGE"))
           if isinstance(c, str) and c.startswith("#")]
PALETTE = list(dict.fromkeys(PALETTE)) or ["#5677b5", "#6e9f60", "#e0913a", "#97abd4", "#304c86", "#467238"]
SMALL = plt.rcParams["xtick.labelsize"]          # annotation size: the paper's tick-label size


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


def chart(left=14.0, bottom=11.0, right=3.0, top=None):
    """The main axes, in mm from the page's edges, leaving room for the title."""
    top = (7.0 if TITLE else 3.0) if top is None else top
    return pg.ax(left, bottom, WIDTH_MM - left - right, HEIGHT_MM - bottom - top)


def finish(ax):
    if TITLE:
        pg.fig.text(1.0 / WIDTH_MM, 1 - 1.0 / HEIGHT_MM, TITLE, fontweight="bold", va="top", ha="left")
    pg.save(HERE, STEM)


T = read_table(DATA)
pg = Page(WIDTH_MM, HEIGHT_MM)
_fam = plt.rcParams["font.family"]                # set after Page, which applies the paper's fonts: Chinese text
plt.rcParams["font.family"] = list(_fam if isinstance(_fam, list) else [_fam]) + ["Microsoft YaHei", "SimHei"]
