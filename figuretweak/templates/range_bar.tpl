# ---- settings ----
LABEL = "catalyst"        # one bar per row
LOW = "t_low"             # start of the range
HIGH = "t_high"           # end of the range
MARK = "t_best"           # a marked value inside the range (e.g. the optimum), "" for none
SORT = True               # sort by the start of the range
XLABEL = "temperature (K)"
SHOW_VALUES = True
# ---- draw ----
ax = chart(left=20.0, right=8.0)
lab, lo, hi = column(LABEL), column(LOW, "number"), column(HIGH, "number")
mk = column(MARK, "number") if MARK else None
o = sorted(range(len(lab)), key=lambda i: lo[i], reverse=True) if SORT else list(range(len(lab)))[::-1]
y = np.arange(len(o))
span = np.nanmax(hi) - np.nanmin(lo)
ax.barh(y, hi[o] - lo[o], left=lo[o], height=0.55, color=PALETTE[0], alpha=0.85, zorder=2)
if mk is not None:
    ax.scatter(mk[o], y, marker="D", s=14, color=HIGHLIGHT, edgecolor="white", linewidths=0.5, zorder=3)
if SHOW_VALUES:
    for yi, i in zip(y, o):
        ax.text(lo[i] - span * 0.01, yi, "%g" % lo[i], ha="right", va="center", fontsize=SMALL * 0.9)
        ax.text(hi[i] + span * 0.01, yi, "%g" % hi[i], ha="left", va="center", fontsize=SMALL * 0.9)
ax.set_yticks(y, [lab[i] for i in o])
ax.tick_params(axis="y", length=0)
ax.set_ylim(-0.6, len(o) - 0.4)
ax.set_xlim(np.nanmin(lo) - span * 0.14, np.nanmax(hi) + span * 0.14)
ax.set_xlabel(XLABEL)
finish(ax)
