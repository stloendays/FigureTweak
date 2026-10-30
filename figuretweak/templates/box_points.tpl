# ---- settings ----
GROUP = "support"         # one box per group
VALUE = "TOF"             # the measurements (one row each)
XLABEL = ""
YLABEL = "TOF (s$^{-1}$)"
SHOW_POINTS = True
SHOW_MEAN = False         # also mark the mean
# ---- draw ----
ax = chart()
g, v = column(GROUP), column(VALUE, "number")
grps = unique(g)
data = [v[[i for i in range(len(g)) if g[i] == k]] for k in grps]
data = [d[~np.isnan(d)] for d in data]
bp = ax.boxplot(data, positions=range(len(grps)), widths=0.5, patch_artist=True, showfliers=not SHOW_POINTS,
                medianprops=dict(color=INK, lw=1.0), whiskerprops=dict(color=INK, lw=0.7),
                capprops=dict(color=INK, lw=0.7), boxprops=dict(edgecolor=INK, lw=0.7))
for j, box in enumerate(bp["boxes"]):
    box.set_facecolor(PALETTE[j % len(PALETTE)])
    box.set_alpha(0.55)
if SHOW_POINTS:
    for j, d in enumerate(data):
        jit = (np.random.default_rng(j).random(len(d)) - 0.5) * 0.3
        ax.scatter(j + jit, d, s=7, color=PALETTE[j % len(PALETTE)], edgecolor=INK, linewidth=0.4, zorder=3)
if SHOW_MEAN:
    ax.scatter(range(len(grps)), [d.mean() for d in data], marker="D", s=14, color="white", edgecolor=INK, zorder=4)
ax.set_xticks(range(len(grps)), grps)
ax.set_xlabel(XLABEL)
ax.set_ylabel(YLABEL)
finish(ax)
