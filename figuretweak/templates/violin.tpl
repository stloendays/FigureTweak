# ---- settings ----
GROUP = "support"         # one violin per group
VALUE = "TOF"             # the measurements (one row each)
XLABEL = ""
YLABEL = "TOF (s$^{-1}$)"
SHOW_BOX = True           # a slim box (quartiles) and the median inside each violin
# ---- draw ----
ax = chart()
g, v = column(GROUP), column(VALUE, "number")
grps = unique(g)
data = [v[[i for i in range(len(g)) if g[i] == k]] for k in grps]
data = [d[~np.isnan(d)] for d in data]
vp = ax.violinplot(data, positions=range(len(grps)), widths=0.75, showextrema=False)
for j, body in enumerate(vp["bodies"]):
    body.set_facecolor(PALETTE[j % len(PALETTE)])
    body.set_edgecolor(INK)
    body.set_linewidth(0.6)
    body.set_alpha(0.75)
if SHOW_BOX:
    for j, d in enumerate(data):
        q1, med, q3 = np.percentile(d, [25, 50, 75])
        ax.plot([j, j], [q1, q3], color=INK, lw=3.0, solid_capstyle="butt", zorder=3)
        ax.scatter([j], [med], s=10, color="white", edgecolor=INK, linewidth=0.5, zorder=4)
ax.set_xticks(range(len(grps)), grps)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
finish(ax)
