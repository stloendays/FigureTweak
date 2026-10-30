# ---- settings ----
LABEL = "catalyst"        # one row per item
A = "before"              # first value (open circle)
B = "after"               # second value (filled circle)
A_NAME = "before"
B_NAME = "after"
XLABEL = "yield (%)"
SORT_BY_CHANGE = True     # largest change at the top
# ---- draw ----
ax = chart(left=18.0, top=8.0)
lab, a, b = column(LABEL), column(A, "number"), column(B, "number")
order = list(range(len(lab)))
if SORT_BY_CHANGE:
    order = sorted(order, key=lambda i: b[i] - a[i], reverse=True)
for k, i in enumerate(order):
    up = b[i] >= a[i]
    ax.plot([a[i], b[i]], [k, k], color=PALETTE[1] if up else HIGHLIGHT, lw=1.6, solid_capstyle="butt", zorder=2)
ax.scatter(a[order], range(len(order)), s=30, facecolor="white", edgecolor=INK, linewidth=0.7, zorder=3, label=A_NAME)
ax.scatter(b[order], range(len(order)), s=30, color=PALETTE[0], edgecolor=INK, linewidth=0.6, zorder=4, label=B_NAME)
ax.set_yticks(range(len(order)), [lab[i] for i in order])
ax.invert_yaxis()
ax.margins(x=0.1, y=0.12)
ax.set_xlabel(XLABEL)
ax.legend(loc="lower center", bbox_to_anchor=(0.5, 1.0), ncol=2, handletextpad=0.2, borderaxespad=0.2)
finish(ax)
