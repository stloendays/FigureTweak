# ---- settings ----
LABEL = "item"            # one rectangle per row
VALUE = "cost"            # rectangle area
GROUP = "stage"           # colour by group, "" = one colour per item
SHOW_VALUES = True
VALUE_FORMAT = "%.0f"
# ---- draw ----
from matplotlib.patches import Rectangle  # noqa: E402
L, B, R, TOP = 3.0, 3.0, 3.0, (7.0 if TITLE else 3.0)
ax = chart(left=L, bottom=B, right=R, top=TOP)
aw, ah = WIDTH_MM - L - R, HEIGHT_MM - B - TOP
lab, v = column(LABEL), column(VALUE, "number")
g = column(GROUP) if GROUP else lab
o = sorted([i for i in range(len(v)) if v[i] > 0], key=lambda i: -v[i])


def _worst(row, side):
    s = sum(row)
    return max(max(side * side * r / (s * s), s * s / (side * side * r)) for r in row)


def squarify(areas, x0, y0, w, h):
    """Rectangles (x, y, w, h) with the given areas filling the box, as square as possible (Bruls et al.)."""
    out, areas = [], list(areas)
    while areas:
        side = min(w, h)
        row = [areas.pop(0)]
        while areas and _worst(row + [areas[0]], side) <= _worst(row, side):
            row.append(areas.pop(0))
        s = sum(row)
        if w >= h:
            cw, yy = s / h, y0 + h
            for r in row:
                out.append((x0, yy - r / cw, cw, r / cw))
                yy -= r / cw
            x0, w = x0 + cw, w - cw
        else:
            rh, xx = s / w, x0
            for r in row:
                out.append((xx, y0 + h - rh, r / rh, rh))
                xx += r / rh
            h -= rh
    return out


groups = unique([g[i] for i in o])
rects = squarify([v[i] / np.nansum(v[o]) * aw * ah for i in o], 0, 0, aw, ah)
for i, (rx, ry, rw, rh) in zip(o, rects):
    ax.add_patch(Rectangle((rx, ry), rw, rh, facecolor=PALETTE[groups.index(g[i]) % len(PALETTE)], edgecolor="white",
                           linewidth=1.2))
    if rw > 9 and rh > 5:
        ax.text(rx + 1.0, ry + rh - 1.0, lab[i] + ("\n" + VALUE_FORMAT % v[i] if SHOW_VALUES else ""), ha="left",
                va="top", color="white", fontweight="bold", fontsize=SMALL)
ax.set_xlim(0, aw)
ax.set_ylim(0, ah)
ax.axis("off")
finish(ax)
