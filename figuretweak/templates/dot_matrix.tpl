# ---- settings ----
ROW = "reaction"          # rows of the grid
COL = "catalyst"          # columns of the grid
SIZE = "yield"            # dot area
COLOR = "selectivity"     # dot colour, "" for one colour
CMAP = "viridis"
SIZE_TITLE = "yield (%)"
COLORBAR_LABEL = "selectivity (%)"
MAX_AREA = 120.0          # area of the largest dot (pt$^2$)
# ---- draw ----
from matplotlib.lines import Line2D  # noqa: E402
ax = chart(left=22.0, bottom=14.0, right=24.0)
r, c, z = column(ROW), column(COL), column(SIZE, "number")
rows, cols = unique(r), unique(c)
xi = np.array([cols.index(v) for v in c])
yi = np.array([rows.index(v) for v in r])
zmax = np.nanmax(z) or 1.0
kw = dict(c=column(COLOR, "number"), cmap=CMAP) if COLOR else dict(color=PALETTE[0])
sc = ax.scatter(xi, yi, s=z / zmax * MAX_AREA, edgecolor=INK, linewidths=0.3, zorder=3, **kw)
ax.set_xticks(range(len(cols)), cols, rotation=40, ha="right", rotation_mode="anchor")
ax.set_yticks(range(len(rows)), rows)
ax.set_xlim(-0.6, len(cols) - 0.4)
ax.set_ylim(len(rows) - 0.4, -0.6)
ax.grid(color="#e2e2e2", lw=0.4)
ax.set_axisbelow(True)
pos = ax.get_position()
if COLOR:
    cax = pg.fig.add_axes([pos.x1 + 2.0 / PAGE_W, pos.y0 + pos.height * 0.55, 2.2 / PAGE_W, pos.height * 0.45])
    cb = pg.fig.colorbar(sc, cax=cax)
    cb.outline.set_linewidth(0.6)
    cb.set_label(COLORBAR_LABEL)
ref = [float("%.2g" % (zmax * f)) for f in (0.25, 0.5, 1.0)]
pg.fig.legend(handles=[Line2D([], [], ls="none", marker="o", markersize=np.sqrt(v / zmax * MAX_AREA), mfc="none",
                              mec=INK, mew=0.6, label="%g" % v) for v in ref],
              title=SIZE_TITLE, loc="lower left", bbox_to_anchor=(pos.x1 + 0.5 / PAGE_W, pos.y0),
              labelspacing=0.9, handletextpad=0.8)
finish(ax)
