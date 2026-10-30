# ---- settings ----
LABEL = "band"            # one row of bars per label, the first at the top
LEFT = "route_a"          # bars to the left
RIGHT = "route_b"         # bars to the right
LEFT_NAME = "Route A"
RIGHT_NAME = "Route B"
XLABEL = "share (%)"
SHOW_VALUES = False
# ---- draw ----
from matplotlib.ticker import FuncFormatter  # noqa: E402
ax = chart(left=20.0, top=9.0 if TITLE else 6.0)
lab, a, b = column(LABEL), column(LEFT, "number"), column(RIGHT, "number")
y = np.arange(len(lab))[::-1]
ax.barh(y, -a, height=0.7, color=PALETTE[0], zorder=2, label=LEFT_NAME)
ax.barh(y, b, height=0.7, color=PALETTE[1 % len(PALETTE)], zorder=2, label=RIGHT_NAME)
m = np.nanmax(np.r_[a, b]) or 1.0
if SHOW_VALUES:
    for yi, va, vb in zip(y, a, b):
        ax.text(-va - m * 0.02, yi, "%g" % va, ha="right", va="center", fontsize=SMALL)
        ax.text(vb + m * 0.02, yi, "%g" % vb, ha="left", va="center", fontsize=SMALL)
ax.axvline(0, color=INK, lw=0.7, zorder=3)
ax.set_xlim(-m * 1.2, m * 1.2)
ax.xaxis.set_major_formatter(FuncFormatter(lambda v, pos: "%g" % abs(v)))
ax.set_yticks(y, lab)
ax.tick_params(axis="y", length=0)
ax.text(0.25, 1.02, LEFT_NAME, transform=ax.transAxes, ha="center", va="bottom", fontweight="bold", color=PALETTE[0])
ax.text(0.75, 1.02, RIGHT_NAME, transform=ax.transAxes, ha="center", va="bottom", fontweight="bold",
        color=PALETTE[1 % len(PALETTE)])
ax.set_xlabel(XLABEL)
finish(ax)
