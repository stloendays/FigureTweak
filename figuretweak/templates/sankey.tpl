# ---- settings ----
SOURCE = "from"           # one row per flow
TARGET = "to"
VALUE = "amount"
GAP = 0.04                # space between nodes in a column (share of the height)
SHOW_VALUES = True        # write each node's total under its name
# ---- draw ----
from matplotlib.patches import PathPatch, Rectangle  # noqa: E402
from matplotlib.path import Path  # noqa: E402
ax = chart(left=3.0, bottom=3.0, right=3.0)
src, tgt, val = column(SOURCE), column(TARGET), column(VALUE, "number")
links = [(src[i], tgt[i], val[i]) for i in range(len(val)) if val[i] > 0]
nodes = unique(src + tgt)
level = {k: 0 for k in nodes}
for _ in nodes:
    for a, b, _v in links:
        level[b] = max(level[b], level[a] + 1)
ncol = max(level.values()) + 1
size = {k: max(sum(v for a, _, v in links if a == k), sum(v for _, b, v in links if b == k)) for k in nodes}
cols = [[k for k in nodes if level[k] == c] for c in range(ncol)]
scale = min((1 - GAP * (len(c) - 1)) / sum(size[k] for k in c) for c in cols)
NW = 0.035
pos = {}
for c, members in enumerate(cols):
    x = c / max(ncol - 1, 1) * (1 - NW)
    used = sum(size[k] for k in members) * scale + GAP * (len(members) - 1)
    y = 0.5 + used / 2
    for k in members:
        pos[k] = (x, y - size[k] * scale, y)
        y -= size[k] * scale + GAP
colour = {k: PALETTE[i % len(PALETTE)] for i, k in enumerate(nodes)}
out_y = {k: pos[k][2] for k in nodes}
in_y = {k: pos[k][2] for k in nodes}
for a, b, v in sorted(links, key=lambda l: (pos[l[0]][2], pos[l[1]][2]), reverse=True):
    h = v * scale
    x0, x1 = pos[a][0] + NW, pos[b][0]
    t0, t1 = out_y[a], in_y[b]
    out_y[a] -= h
    in_y[b] -= h
    xm = (x0 + x1) / 2
    verts = [(x0, t0), (xm, t0), (xm, t1), (x1, t1), (x1, t1 - h), (xm, t1 - h), (xm, t0 - h), (x0, t0 - h), (x0, t0)]
    codes = [Path.MOVETO] + [Path.CURVE4] * 3 + [Path.LINETO] + [Path.CURVE4] * 3 + [Path.CLOSEPOLY]
    ax.add_patch(PathPatch(Path(verts, codes), facecolor=colour[a], alpha=0.35, edgecolor="none", zorder=1))
for k in nodes:
    x, y0, y1 = pos[k]
    ax.add_patch(Rectangle((x, y0), NW, y1 - y0, facecolor=colour[k], edgecolor="none", zorder=2))
    last = level[k] == ncol - 1
    ax.text(x - 0.01 if last else x + NW + 0.01, (y0 + y1) / 2,
            k + ("\n%g" % float("%.3g" % size[k]) if SHOW_VALUES else ""), ha="right" if last else "left",
            va="center", fontsize=SMALL, zorder=3)
ax.set_xlim(-0.02, 1.02)
ax.set_ylim(min(p[1] for p in pos.values()) - 0.02, max(p[2] for p in pos.values()) + 0.02)
ax.axis("off")
finish(ax)
