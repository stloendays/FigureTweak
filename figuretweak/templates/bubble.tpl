# ---- settings ----
X = "cost"                # x values
Y = "activity"            # y values
SIZE = "capacity"         # bubble area follows this column
GROUP = "type"            # colour by group, "" for one colour
LABEL = "name"            # write this column next to each bubble, "" for none
XLABEL = "cost (a.u.)"
YLABEL = "activity (a.u.)"
SIZE_TITLE = "capacity"   # title of the bubble-size key
MAX_AREA = 260.0          # area of the largest bubble (pt$^2$)
# ---- draw ----
from matplotlib.lines import Line2D  # noqa: E402
ax = chart(right=22.0)
x, y, z = column(X, "number"), column(Y, "number"), column(SIZE, "number")
g = column(GROUP) if GROUP else ["all"] * len(x)
lab = column(LABEL) if LABEL else None
zmax = np.nanmax(z) or 1.0
area = z / zmax * MAX_AREA
for j, k in enumerate(unique(g)):
    idx = [i for i in range(len(x)) if g[i] == k]
    ax.scatter(x[idx], y[idx], s=area[idx], color=PALETTE[j % len(PALETTE)], alpha=0.75, edgecolor=INK,
               linewidths=0.4, label=k if GROUP else None, zorder=3)
if lab:
    for i in range(len(x)):
        ax.annotate(lab[i], (x[i], y[i]), xytext=(np.sqrt(area[i]) / 2 + 1.5, 0), textcoords="offset points",
                    va="center", fontsize=SMALL)
ax.margins(x=0.16, y=0.12)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
if GROUP:
    ax.legend(loc="upper left")
ref = [float("%.2g" % (zmax * f)) for f in (0.25, 0.5, 1.0)]
keys = [Line2D([], [], ls="none", marker="o", markersize=np.sqrt(r / zmax * MAX_AREA), mfc="none", mec=INK,
               mew=0.6, label="%g" % r) for r in ref]
pos = ax.get_position()
pg.fig.legend(handles=keys, title=SIZE_TITLE, loc="center left", bbox_to_anchor=(pos.x1 + 1.5 / WIDTH_MM, 0.5),
              labelspacing=1.3, borderpad=0.6, handletextpad=1.0)
finish(ax)
