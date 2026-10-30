# ---- settings ----
LABEL = "item"            # one colour per row
VALUE = "share"
ROWS = 10
COLS = 10                 # ROWS x COLS squares in all
SHOW_PERCENT = True       # percentages in the key
# ---- draw ----
from matplotlib.collections import PatchCollection  # noqa: E402
from matplotlib.patches import Patch, Rectangle  # noqa: E402
ax = chart(left=3.0, bottom=3.0, right=30.0)
lab, v = column(LABEL), column(VALUE, "number")
n = ROWS * COLS
raw = v / np.nansum(v) * n
cnt = np.floor(raw).astype(int)
for i in np.argsort(-(raw - cnt))[: n - cnt.sum()]:
    cnt[i] += 1
cells, k = [], 0
for j, c in enumerate(cnt):
    sq = []
    for _ in range(c):
        r, col = divmod(k, COLS)
        sq.append(Rectangle((col, ROWS - 1 - r), 0.86, 0.86))
        k += 1
    if sq:
        ax.add_collection(PatchCollection(sq, facecolor=PALETTE[j % len(PALETTE)], edgecolor="none", label=lab[j]))
ax.set_xlim(-0.2, COLS + 0.06)
ax.set_ylim(-0.2, ROWS + 0.06)
ax.set_aspect("equal")
ax.axis("off")
ax.legend(handles=[Patch(color=PALETTE[j % len(PALETTE)],
                         label=lab[j] + ("  %.0f%%" % (100 * v[j] / np.nansum(v)) if SHOW_PERCENT else ""))
                   for j in range(len(lab))], loc="center left", bbox_to_anchor=(1.03, 0.5))
finish(ax)
