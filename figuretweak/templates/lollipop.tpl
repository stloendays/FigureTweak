# ---- settings ----
LABEL = "metal"           # one row per item
VALUE = "score"           # ranked value
DESCENDING = True         # largest at the top
TOP_N = 0                 # keep only the first N items, 0 for all
HIGHLIGHT_ITEM = "Co"     # one item drawn in the highlight colour, "" for none
XLABEL = "score"
SHOW_VALUES = True
# ---- draw ----
ax = chart(left=18.0)
lab, val = column(LABEL), column(VALUE, "number")
order = sorted(range(len(lab)), key=lambda i: val[i], reverse=DESCENDING)
if TOP_N:
    order = order[:TOP_N]
for k, i in enumerate(order):
    col = HIGHLIGHT if lab[i] == HIGHLIGHT_ITEM else PALETTE[0]
    ax.plot([0, val[i]], [k, k], color=col, lw=1.6, solid_capstyle="butt", zorder=2)
    ax.scatter([val[i]], [k], s=34, color=col, edgecolor=INK, linewidth=0.6, zorder=3)
    if SHOW_VALUES:
        ax.text(val[i], k, "   %.3g" % val[i], va="center", ha="left", fontsize=SMALL)
ax.set_yticks(range(len(order)), [lab[i] for i in order])
ax.invert_yaxis()
ax.set_xlim(0, np.nanmax(val[order]) * (1.22 if SHOW_VALUES else 1.06))
ax.set_xlabel(XLABEL)
finish(ax)
